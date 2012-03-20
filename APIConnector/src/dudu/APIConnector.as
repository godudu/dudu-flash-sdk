package dudu
{
	import dudu.api.DataProvider;
	import dudu.events.APIConnectorEvent;
	import flash.events.EventDispatcher;
	
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	/**
	 * Class for working with Dudu Api and JS-methods
	 */
	public class APIConnector extends EventDispatcher
	{
		private var dp:DataProvider;
		
		private var receivingLC:LocalConnection;
		private var sendindLC:LocalConnection;
		private var connectionName:String;
		private var connected:Boolean = false;
		private var js_requests:Array = [];
		public static var log:Boolean;
		
		public function APIConnector(flashvars:Object, local_connection_on:Boolean = true, debug_log:Boolean = false) 
		{
			log = debug_log;
			dp = new DataProvider(flashvars.api_url, flashvars.api_id, flashvars.sid, flashvars.secret, flashvars.viewer_id);
			
			if(local_connection_on){
				connectionName = flashvars.lc_name;
				initLocalConnection();
			}
		}
		
		/**
		 * Make API Request
		 * @param	method method name (for example, friends.get)
		 * @param	params request params
		 * @param	onComplete complete callback
		 * @param	onError error callback
		 * @return  request id
		 */
		public function api(method: String, params: Object, onComplete:Function = null, onError:Function = null):uint {
			var options: Object = new Object();
				options['params'] = params;
				options['onComplete'] = onComplete;
				options['onError'] = onError;
			return dp.request(method, options);
		}
		
		/**
		 * Cancel request 
		 * @param	request_id id of request
		 */
		public function cancelRequest(request_id:uint):void {
			dp.cancelRequest(request_id);
		}
		
		/**
		 * Call JS method
		 * @param	method_name method name
		 * @param	params methid params
		 */
		public function callMethod(method_name:String, params:Object = null):void {
			switch(method_name) {
				case 'showInviteFriendsWindow':
					showInviteFriendsWindow();
					break;
				case 'showPaymentWindow':
					showPaymentWindow(params.value);
					break;
				case 'publishToWall':
					publishToWall(params.message, params.photo_id);
					break;
				case 'changeAvatar':
					changeAvatar(params.image_id);
					break;
				case 'setPageTitle':
					setPageTitle(params.title);
					break;
			}
		}
		
		
		// Working with js-wrapper using local connection
		private function initLocalConnection():void {
			sendindLC = new LocalConnection();
			sendindLC.allowDomain('*');
			
			receivingLC = new LocalConnection();
			receivingLC.allowDomain('*');
			receivingLC.client = {
				pingConnection:pingConnection,
				onBalanceChange:onBalanceChange,
				onPaymentCancel:onPaymentCancel,
				onPaymentSuccess:onPaymentSuccess,
				onPaymentFail:onPaymentFail
			}
			

			receivingLC.connect('app_' + connectionName);

			sendindLC.addEventListener(StatusEvent.STATUS, onInitStatus);
			sendindLC.send('js_' + connectionName, 'pingConnection');
		}
		
		private function pingConnection():void
		{
			if (connected)
				return;
			
			trace('pingConnection');
			connected = true;
			// send all requests from array
		}
		
		private function onInitStatus(e:StatusEvent):void
		{
			e.target.removeEventListener(e.type, onInitStatus);
			if (e.level == "status")
			{
				pingConnection();
				trace('connected');
			}else {
				trace('not loaded');
			}
		}
		
		
		// JS-Wrapper callbacks
		private function onBalanceChange(value:Number):void 
		{
			var event:APIConnectorEvent = new APIConnectorEvent(APIConnectorEvent.BAL_CHANGED);
				event.data = { value:value };
			this.dispatchEvent(event);
		}
		
		private function onPaymentCancel():void {
			var event:APIConnectorEvent = new APIConnectorEvent(APIConnectorEvent.PAY_CANCEL);
			this.dispatchEvent(event);
		}
		
		private function onPaymentSuccess():void {
			var event:APIConnectorEvent = new APIConnectorEvent(APIConnectorEvent.PAY_SUCCESS);
			this.dispatchEvent(event);
		}
		
		private function onPaymentFail():void {
			var event:APIConnectorEvent = new APIConnectorEvent(APIConnectorEvent.PAY_FAIL);
			this.dispatchEvent(event);
		}
		
		
		
		// JS-Wrapper call
		private function showInviteFriendsWindow():void {
			sendindLC.send('js_' + connectionName, 'showInviteFriendsWindow');
		}
		
		private function showPaymentWindow(value:Number = 0):void {
			sendindLC.send('js_' + connectionName, 'showPaymentWindow', value);
		}
		
		private function publishToWall(message:String, photo_id:Number):void {
			sendindLC.send('js_' + connectionName, 'publishToWall', message, photo_id);
		}
		
		private function changeAvatar(image_id:Number):void {
			sendindLC.send('js_' + connectionName, 'changeAvatar', image_id);
		}
		
		private function setPageTitle(title:String):void {
			sendindLC.send('js_' + connectionName, 'setPageTitle', title);
		}
	}
}