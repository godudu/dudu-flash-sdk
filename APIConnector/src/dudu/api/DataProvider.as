package dudu.api
{
	import dudu.APIConnector;
	import dudu.MD5;
	import dudu.serialization.json.JSON;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	/**
	 * Класс, непосредственно занимающийся отправкой и обработкой запросов
	 */
	public class DataProvider
	{
		private var req_num:uint = 0;
		private var _api_secret:String;
		private var _api_sid:String;
		private var _api_url:String;
		private var _api_id:Number;
		private var _viewer_id:Number;
		
		private var requests:Array = [];
		
		public function DataProvider(api_url:String, api_id:Number, api_sid:String, api_secret:String, viewer_id:Number)
		{
			_api_secret = api_secret;
			_api_sid = api_sid;
			_api_url = api_url;
			_api_id = api_id;
			_viewer_id = viewer_id;
		}
		
		/**
		 * Создавние запроса к серверу
		 * @param	method метод апи
		 * @param	params параметры
		 */
		public function request(method:String, params:Object = null):uint
		{
			var onComplete:Function, onError:Function;
			if (params == null)
			{
				params = new Object();
			}
			
			params.onComplete = params.onComplete ? params.onComplete : null; // TODO: don't forget to make global options!
			params.onError = params.onError ? params.onError : null;
			req_num++;
			_sendRequest(method, params);
			return req_num;
		}
		
		public function cancelRequest(request_id:uint):void
		{
			for (var i:uint = 0; i < requests.length; i++)
			{
				if (requests[i].req_id == request_id)
				{
					var loader:URLLoader = requests[i].loader;
					loader.close();
					var params:Object = requests[i].params;
					requests.splice(i, 1);
					break;
				}
			}
		}
		
		private function _sendRequest(method:String, params:Object):void
		{
			log('sendRequest: ', req_num);
			
			var request_params:Object = {method: method};
			request_params.api_id = _api_id;
			request_params.format = "JSON";
			request_params.v = "3.0";
			
			if (params.params)
			{
				for (var i:String in params.params)
				{
					request_params[i] = params.params[i];
				}
			}
			
			var variables:URLVariables = new URLVariables();
			for (var item:String in request_params)
			{
				if (request_params[item] is Array)
				{
					variables[item + '[]'] = request_params[item];
				}
				else
				{
					variables[item] = request_params[item];
				}
			}
			variables['sig'] = _generate_signature(request_params);
			variables['sid'] = _api_sid;
			
			var request:URLRequest = new URLRequest();
			request.url = _api_url;
			request.method = URLRequestMethod.POST;
			request.data = variables;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
			
			loader.addEventListener(Event.COMPLETE, onComplete);
			
			requests.push({'loader': loader, 'params': params, 'req_id': req_num});
			
			try
			{
				loader.load(request);
			}
			catch (error:Error)
			{
				log('error');
				params.onError(error);
				return;
			}
			log('sended');
		}
		
		private function onHTTPStatus(e:HTTPStatusEvent):void 
		{
			log('HTTP STATUS: ', e.status);
		}
		
		/**
		 * Generates signature
		 */
		private function getParamsByLoader(loader:URLLoader):Object
		{
			for (var i:uint = 0; i < requests.length; i++)
			{
				if (requests[i].loader == loader)
				{
					var params:Object = requests[i].params;
					requests.splice(i, 1);
					return params;
				}
			}
			
			return null;
		}
		
		private function onSecurityError(e:SecurityErrorEvent):void
		{
			var loader:URLLoader = URLLoader(e.target);
			var params:Object = getParamsByLoader(loader);
			
			if (params.onError)
			{
				params.onError('Security error');
			}
			killURLLoader(loader);
		}
		
		private function onIOError(e:IOErrorEvent):void
		{
			var loader:URLLoader = URLLoader(e.target);
			var params:Object = getParamsByLoader(loader);
			if (params.onError)
			{
				params.onError('IO error');
			}
			killURLLoader(loader);
		}
		
		private function onComplete(e:Event):void
		{
			log('on complete');
			var loader:URLLoader = URLLoader(e.target);
			log(loader.data);
			var params:Object = getParamsByLoader(loader);
			var data:Object = JSON.decode(loader.data);
			
			if (data.error && params.onError)
			{
				params.onError(data.error);
			}
			else if (params.onComplete && data.result)
			{
				params.onComplete(data.result);
			}
			
			killURLLoader(loader);
		}
		
		private function _generate_signature(request_params:Object):String
		{
			var sort_arr:Array = [];
			for (var key:String in request_params)
			{
				sort_arr.push(key + "=" + request_params[key]);
			}
			sort_arr.sort();
			
			// making signature
			var sign:String = "";
			for (key in sort_arr)
			{
				sign += sort_arr[key];
			}
			if (_viewer_id > 0)
				sign = _viewer_id.toString() + sign;
			sign += _api_secret;
			
			log('sign:', sign);
			
			return MD5.encrypt(sign);
		}
		
		private function killURLLoader(loader:URLLoader):void
		{
			loader.removeEventListener(Event.COMPLETE, onComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader = null;
		}
		
		private function log(... args):void
		{
			if (APIConnector.log)
			{
				trace(args.join(" "));
			}
		}
	}

}