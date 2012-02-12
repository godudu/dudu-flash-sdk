package dudu.events 
{
	import flash.events.Event;
	/**
	 * ...
	 * @author Mikhailovas@gmail.com
	 */
	public class APIConnectorEvent extends Event
	{
		private var _data:Object;
		
		/** Event dispatched when balance changes **/
		public static const BAL_CHANGED:String = "onBalanceChanged";
		/** Event dispatched when payment canceled **/
		public static const PAY_CANCEL:String = "onPaymentCanceled";
		/** Event dispatched when payment succeeded **/
		public static const PAY_SUCCESS:String = "onPaymentSuccess";
		/** Event dispatched when payment failed **/
		public static const PAY_FAIL:String = "onPaymentFailed";
		
		
		public function APIConnectorEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public function get data():Object 
		{
			return _data;
		}
		
		public function set data(value:Object):void 
		{
			_data = value;
		}
		
	}

}