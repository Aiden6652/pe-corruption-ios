package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class CrashState extends MusicBeatState
{
	override function create()
	{
		super.create();

		// 纯黑底，不依赖任何图片资源（原来加载 Paths.image('crash')，资源缺失时这里会二次崩溃）
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		add(bg);

		var title:FlxText = new FlxText(12, 10, FlxG.width - 24, "CRASH - SCREENSHOT THIS SCREEN", 24);
		title.scrollFactor.set();
		title.color = FlxColor.RED;
		add(title);

		// 用 flixel 内置字体（nokiafc22），保证一定渲染得出来
		var errorMessage:FlxText = new FlxText(12, 52, FlxG.width - 24, Std.string(SUtil.errMsg), 18);
		errorMessage.scrollFactor.set();
		errorMessage.color = FlxColor.WHITE;
		errorMessage.wordWrap = true;
		add(errorMessage);

	}

	override function update(elapsed:Float)
	{
		
		super.update(elapsed);
	}
}
