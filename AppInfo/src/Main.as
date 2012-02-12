package  
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author Mikhailovas@gmail.com
	 */
	public class Main extends Sprite
	{
		
		public function Main() 
		{
			stage.scaleMode = 'noScale';
			stage.align = 'TL';
			
			var _txt:TextField = new TextField();
				_txt.width = 500;
				_txt.height = 500;
			addChild(_txt);
			
			_txt.text = 'Flashvars:\n\n';
			
			var fv:Object = loaderInfo.parameters;
			_txt.appendText('var flashvars:Object = this.loaderInfo.parameters;\nif (!flashvars.lc_name)\n{');
			
			for (var item:String in fv) {
				trace(typeof(fv[item]));
				var value:String = (typeof(fv[item]) == 'string')?('"'+fv[item]+'"'):fv[item];
				_txt.appendText( '	flashvars.' + item + '='+value+';\n');
			}
			_txt.appendText('}');
			var tf:TextFormat = new TextFormat('Tahoma', 14);
			_txt.setTextFormat(tf);
		}
		
	}

}