package;

/**
 * V-Slice API compatibility shim for Psych Engine.
 * Maps common V-Slice modding APIs to PE equivalents so .hxc mod scripts
 * written for V-Slice can run with reduced functionality.
 * Loaded via HScript interp variables (see FunkinLua.hx HScript class).
 */
#if hscript
class VSliceShim
{
	/**
	 * Register V-Slice shim functions into an HScript interp.
	 * Call from HScript constructor.
	 */
	public static function register(interp:hscript.Interp):Void
	{
		// V-Slice uses Conductor.instance (singleton) - PE uses static Conductor
		// Provide instance proxy
		interp.variables.set('vSliceVersion', '0.8.0-shim');

		// Common V-Slice playback API used by scripts
		interp.variables.set('addToPlayState', function(obj:Dynamic, ?zIndex:Int = -1):Void
		{
			if(PlayState.instance != null) PlayState.instance.add(obj);
		});

		interp.variables.set('removeFromPlayState', function(obj:Dynamic):Void
		{
			if(PlayState.instance != null) PlayState.instance.remove(obj);
		});

		// V-Slice: setSongTime / seek (PE songTime is private; use playState hook)
		interp.variables.set('setSongTime', function(ms:Float):Void
		{
			// songTime is private in PE - expose via PlayState.instance if accessible
			var ps:Dynamic = PlayState.instance;
			if(ps != null && Reflect.hasField(ps, 'songTime'))
			{
				Reflect.setField(ps, 'songTime', ms);
			}
		});

		// V-Slice: song position getter
		interp.variables.set('getSongPosition', function():Float
		{
			return Conductor.songPosition;
		});

		// V-Slice: screen shake etc.
		interp.variables.set('shakeCamera', function(?intensity:Float = 0.005, ?duration:Float = 0.2):Void
		{
			if(PlayState.instance != null)
			{
				PlayState.instance.camGame.shake(intensity, duration);
				PlayState.instance.camHUD.shake(intensity, duration);
			}
		});

		// V-Slice: health manipulation
		interp.variables.set('setHealth', function(v:Float):Void
		{
			if(PlayState.instance != null) PlayState.instance.health = v;
		});
		interp.variables.set('getHealth', function():Float
		{
			return PlayState.instance != null ? PlayState.instance.health : 0;
		});

		// V-Slice: score
		interp.variables.set('setScore', function(v:Int):Void
		{
			if(PlayState.instance != null) PlayState.instance.songScore = v;
		});
		interp.variables.set('getScore', function():Int
		{
			return PlayState.instance != null ? PlayState.instance.songScore : 0;
		});

		// V-Slice: combo
		interp.variables.set('setCombo', function(v:Int):Void
		{
			if(PlayState.instance != null) PlayState.instance.combo = v;
		});

		// V-Slice: miss count
		interp.variables.set('setMisses', function(v:Int):Void
		{
			if(PlayState.instance != null) PlayState.instance.songMisses = v;
		});

		// V-Slice: strumline helpers
		interp.variables.set('getPlayerStrum', function(i:Int):Dynamic
		{
			if(PlayState.instance != null && PlayState.instance.playerStrums != null
				&& i < PlayState.instance.playerStrums.length)
				return PlayState.instance.playerStrums.members[i];
			return null;
		});

		// V-Slice: subtitles (no-op in PE)
		interp.variables.set('addSubtitle', function(text:String, time:Float, dur:Float):Void
		{
			// not supported in PE - no-op
		});

		// V-Slice: disable/enable player keys (maps to strumsBlocked)
		interp.variables.set('disableKeys', function(v:Bool):Void
		{
			if(PlayState.instance != null && PlayState.instance.strumsBlocked != null)
			{
				for (i in 0...4)
				{
					PlayState.instance.strumsBlocked[i] = v;
				}
			}
		});

		// V-Slice: icon helpers
		interp.variables.set('setIconP1', function(name:String):Void
		{
			if(PlayState.instance != null && PlayState.instance.iconP1 != null)
				PlayState.instance.iconP1.changeIcon(name);
		});
		interp.variables.set('setIconP2', function(name:String):Void
		{
			if(PlayState.instance != null && PlayState.instance.iconP2 != null)
				PlayState.instance.iconP2.changeIcon(name);
		});

		// V-Slice: camera focus on character
		interp.variables.set('focusCamera', function(?char:Int = 0):Void
		{
			// PE default camera follow logic handles this
		});
	}
}
#end
