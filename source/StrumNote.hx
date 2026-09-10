package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = 'VS_strumline';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	function hasFramePrefix(p:String):Bool {
		if(p == null || p == '' || frames == null || frames.frames == null) return false;
		for(fr in frames.frames) {
			if(fr != null && fr.name != null && fr.name.startsWith(p)) return true;
		}
		return false;
	}

	function addAnimProbe(name:String, cands:Array<String>, rate:Int = 30, looped:Bool = true):Void {
		for(p in cands) {
			if(hasFramePrefix(p)) {
				animation.addByPrefix(name, p, rate, looped);
				return;
			}
		}
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);

			// v50 的 atlas 是经典命名(arrowLEFT0000 / left press0000 / left confirm0000)，
			// 原代码只认 V-Slice 命名(staticLeft/pressLeft/confirmLeft)，
			// 一个都匹配不到时一个动画都不会注册 -> curAnim 恒为 null ->
			// 精灵只画第 0 帧(arrowDOWN0000) -> 4 个键全变成相同的下箭头。
			// 这里两套命名都探测，确保一定注册上。
			var idx:Int = Std.int(Math.abs(noteData)) % 4;
			var dirUp:Array<String> = ['Left', 'Down', 'Up', 'Right'];
			var dirLow:Array<String> = ['left', 'down', 'up', 'right'];
			var d:String = dirUp[idx];
			var dl:String = dirLow[idx];

			addAnimProbe('purple', ['staticLeft', 'arrowLEFT']);
			addAnimProbe('blue', ['staticDown', 'arrowDOWN']);
			addAnimProbe('green', ['staticUp', 'arrowUP']);
			addAnimProbe('red', ['staticRight', 'arrowRIGHT']);

			addAnimProbe('static', ['static' + d, 'arrow' + d.toUpperCase(), dl]);
			addAnimProbe('pressed', ['press' + d, dl + ' press'], 24, false);
			addAnimProbe('confirm', ['confirm' + d, dl + ' confirm'], 24, false);

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim != null && animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		//}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if (noteData > -1 && noteData < ClientPrefs.arrowHSV.length)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
			}

			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}
}
