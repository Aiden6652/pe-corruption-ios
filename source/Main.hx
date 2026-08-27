package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.system.scaleModes.RatioScaleMode;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;

#if desktop
import Discord.DiscordClient;
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

// mobile asset bootstrap (copy embedded assets -> writable Documents on first launch)
#if (ios || android)
import sys.FileSystem;
import sys.io.File;
import openfl.text.TextField;
#end

using StringTools;

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: true // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

    SUtil.gameCrashCheck();
		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		#if (ios || android)
		bootstrapThenStart();
		#else
		setupGame();
		#end
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}
	
			// iOS: skip doTheCheck() - it requires assets/mods extracted to Documents
		// (Android-only behavior), which never happens on iOS -> instant exit + black screen
		#if !ios
		SUtil.doTheCheck();
		#end
	
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		// flixel 5.0.0 removed the zoom arg from FlxGame; default scaleMode is
		// RatioScaleMode(false) = letterbox (keeps black bars). Match the old
		// zoom behavior: fill the whole screen, cropping the overflow.
		#if (flixel >= "5.0.0")
		FlxG.scaleMode = new RatioScaleMode(true);
		#end

		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}


		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if desktop
		if (!DiscordClient.isInitialized) {
			DiscordClient.initialize();
			Application.current.window.onClose.add(function() {
				DiscordClient.shutdown();
			});
		}
		#end
	}

	#if (ios || android)
	// Copy embedded engine assets out of the read-only bundle into the writable
	// Documents folder so the rest of the engine can read them via FileSystem
	// (exactly like the original iOS port expects). Done in chunks across frames
	// so the screen shows progress instead of freezing. Runs once (flag file).
	private var _bootList:Array<String> = null;
	private var _bootIdx:Int = 0;
	private var _bootText:TextField = null;

	private function bootstrapThenStart():Void
	{
		var done:String = SUtil.getSavePath() + 'assets/.bootstrap_done';
		if (FileSystem.exists(done))
		{
			setupGame();
			return;
		}

		_bootText = new TextField();
		_bootText.width = Lib.current.stage.stageWidth;
		_bootText.height = Lib.current.stage.stageHeight;
		_bootText.text = "首次启动：正在解压 Corruption 资源...\n(This only happens once, please wait a few minutes)";
		_bootText.textColor = 0xffffff;
		_bootText.size = 28;
		_bootText.multiline = true;
		Lib.current.addChild(_bootText);

		_bootList = Assets.list();
		_bootIdx = 0;
		Lib.current.addEventListener(Event.ENTER_FRAME, stepBootstrap);
	}

	private function stepBootstrap(?e:Event):Void
	{
		var dest:String = SUtil.getSavePath(); // documentsDirectory + trailing '/'
		var batch:Int = 30;
		var count:Int = 0;

		while (_bootIdx < _bootList.length && count < batch)
		{
			var name:String = _bootList[_bootIdx++];
			count++;

			// asset names may be library-scoped like "songs:assets/songs/x.ogg"
			var path:String = name;
			var ci:Int = path.indexOf(':');
			if (ci >= 0)
				path = path.substring(ci + 1);
			if (!path.startsWith('assets/'))
				continue;

			var out:String = dest + path;
			try
			{
				if (FileSystem.exists(out))
					continue;
				var bytes = Assets.getBytes(name);
				if (bytes == null)
					continue;
				var dir:String = out.substring(0, out.lastIndexOf('/'));
				if (dir.length > 0 && !FileSystem.exists(dir))
					FileSystem.createDirectory(dir);
				File.saveBytes(out, bytes);
			}
			catch (err:Dynamic)
			{
				Sys.println('bootstrap skip ' + name + ': ' + err);
			}
		}

		if (_bootText != null)
			_bootText.text = "Preparing assets... (" + _bootIdx + "/" + _bootList.length + ")";

		if (_bootIdx >= _bootList.length)
		{
			Lib.current.removeEventListener(Event.ENTER_FRAME, stepBootstrap);
			try
			{
				File.saveContent(dest + 'assets/.bootstrap_done', Date.now().toString());
			}
			catch (e2:Dynamic) {}
			if (_bootText != null)
			{
				Lib.current.removeChild(_bootText);
				_bootText = null;
			}
			setupGame();
		}
	}
	#end

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	public static function onCrash(e:UncaughtErrorEvent):Void
		{
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);
			var dateNow:String = Date.now().toString();
			dateNow = StringTools.replace(dateNow, " ", "_");
			dateNow = StringTools.replace(dateNow, ":", "'");
	
			var path:String = "crash/" + "crash_" + dateNow + ".txt";
			var errMsg:String = "";
	
			for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case FilePos(s, file, line, column):
						errMsg += file + " (line " + line + ")\n";
					default:
						Sys.println(stackItem);
				}
			}
	
			errMsg += e.error;
	
		if (!FileSystem.exists(SUtil.getSavePath() + "crash"))
			FileSystem.createDirectory(SUtil.getSavePath() + "crash");

		File.saveContent(SUtil.getSavePath() + path, errMsg + "\n");
	
			Sys.println(errMsg);
			Sys.println("Crash dump saved in " + Path.normalize(path));
			Sys.println("Making a simple alert ...");
	
			FlxG.switchState(new CrashState());
		}
	#end
}
