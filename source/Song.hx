package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if(rawJson == null) {
			#if sys
			// 收集候选路径逐个尝试（大小写/难度回退），全程 try-catch，绝不向调用方抛异常
			var pathsToTry:Array<String> = [];
			pathsToTry.push(SUtil.getPath() + Paths.json(formattedFolder + '/' + formattedSong));
			// Corruption 文件名/目录保留原始大小写（如 Blood-Moon/Blood-Moon-canon.json）
			pathsToTry.push(SUtil.getPath() + Paths.json(folder + '/' + jsonInput));
			var knownDiffs:Array<String> = ['hard','canon','safe','normal','easy','erect','nightmare'];
			var baseName:String = formattedSong;
			var suffix:String = '';
			for(d in knownDiffs) {
				if(formattedSong.endsWith('-' + d)) {
					baseName = formattedSong.substring(0, formattedSong.length - d.length - 1);
					suffix = d;
					break;
				}
			}
			if(suffix != '') {
				for(d2 in knownDiffs) {
					if(d2 == suffix) continue;
					pathsToTry.push(SUtil.getPath() + Paths.json(formattedFolder + '/' + baseName + '-' + d2));
					pathsToTry.push(SUtil.getPath() + Paths.json(folder + '/' + baseName + '-' + d2));
				}
				pathsToTry.push(SUtil.getPath() + Paths.json(formattedFolder + '/' + baseName));
				pathsToTry.push(SUtil.getPath() + Paths.json(folder + '/' + baseName));
			}
			for(c in pathsToTry) {
				if(c == null) continue;
				try {
					if(FileSystem.exists(c)) {
						rawJson = File.getContent(c).trim();
						break;
					}
				} catch(e:Dynamic) {
					trace('Song.loadFromJson: 读取失败已跳过: ' + c);
				}
			}
			if(rawJson == null) {
				trace('Song.loadFromJson: 谱面缺失，已用空谱面兜底: ' + formattedFolder + '/' + formattedSong);
				rawJson = '{"song":{"notes":[],"bpm":100,"player1":"bf","player2":"dad","song":"' + formattedSong + '"}}';
			}
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
