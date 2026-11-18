package meta.state.parallax;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.util.FlxColor;
import gameObjects.educator.EduCursor;
import gameObjects.educator.EduShaders;
import meta.MusicBeat.MusicBeatState;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;

/** Creditos do Parallax (port de data/states/parallax/credits.hx). Roda com a roda do mouse ou as setas. **/
class ParallaxCreditsState extends MusicBeatState
{
	var camBG:FlxCamera;
	var camTxt:FlxCamera;
	var hint:FlxText;
	var credits:FlxText;
	var fish:Shader;
	var time:Float = 0;

	static var TEXT:String = "
CREDITS

DIRECTORS
RightburstU - hasnt touched the mod in months LMFAOO
KrystalKlean - there i am gary! there i am!

MUSICIANS
Dangen - composed the first section of expulsion (ty goat)
NexusVGM - composed the instrumental for the second section of expulsion
RightburstU - composed the vocals for the second section of expulsion
KrystalKlean - look gary there i am again!

ARTISTS
John9Doe - made the sprites and backgrounds for expulsion (high key carried the art portion of this song ty)
Eva - created the most beautiful logo ive ever seen in my life tysm
YaBoiJak - animated said beautiful logo and created the `press enter` sprite in the main screen
Slushy Anime - created the bf model used in expulsion

CHARTERS
JDogg - charted expulsion

CODERS
iilas - main coder (locked in so hard over the past 2 months tysm!!)
nex - secondary coder (helped with alot of issues i had, couldnt of done it without you)
Fusion - coder (Hiii!!, I added a bunch of cool events in expulsion and fixed some bugs, i hope you like it!!)

VOICE ACTORS
Morgue - voiced educators voice lines and created the second form chromatic

SPECIAL THANKS
Prism - created the original schoolhouse model used as a base for the sprites (i cant find their twitter anymore but i still gotta credit them!)
Sega - thanks for making sonic schoolhouse it blue screened my pc when i opened it signed rightburst
and last but not least,
YOU! - thank you SO MUCH for playing! i will try my best to get more of this mod out but life is very busy so it'll be out when its out!!

-KrystalKlean
";

	override function create()
	{
		super.create();
		camBG = new FlxCamera();
		camTxt = new FlxCamera();
		camTxt.bgColor = 0x00000000;
		FlxG.cameras.reset(camBG);
		FlxG.cameras.add(camTxt);
		FlxCamera.defaultCameras = [camTxt];

		var bg = new FlxSprite().makeGraphic(1, 1, FlxColor.fromRGB(17, 5, 33));
		bg.origin.set(0, 0);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.cameras = [camBG];
		add(bg);

		var checker = new FlxBackdrop(Paths.image('menus/title/checkerBoard'));
		checker.screenCenter();
		checker.scale.set(0.7, 0.7);
		checker.velocity.set(20, -20);
		checker.cameras = [camBG];
		add(checker);

		if (EduShaders.quality() > 0)
		{
			try
			{
				fish = EduShaders.load('fishEye');
				fish.data.Size.value = [0.5];
				fish.data.iTime.value = [0.0];
				camBG.setFilters([new ShaderFilter(fish)]);
			}
			catch (e:Dynamic)
			{
				trace('creditos: fishEye desativado (' + e + ')');
				fish = null;
			}
		}

		hint = new FlxText(0, 20, FlxG.width - 40, 'use the mouse wheel', 30);
		hint.setFormat(Paths.font('vcr.ttf'), 30, FlxColor.WHITE, RIGHT);
		FlxTween.tween(hint, {alpha: 0}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
		add(hint);

		credits = new FlxText(0, 50, FlxG.width, TEXT, 30);
		credits.setFormat(Paths.font('vcr.ttf'), 30, FlxColor.WHITE, CENTER);
		add(credits);

		EduCursor.attach(this);
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		time += elapsed;
		if (fish != null)
			fish.data.iTime.value = [time];

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancel'), 1);
			Main.switchState(this, new ParallaxTitleState());
		}

		var move:Float = FlxG.mouse.wheel * 30;
		if (FlxG.keys.pressed.DOWN)
			move -= 400 * elapsed;
		if (FlxG.keys.pressed.UP)
			move += 400 * elapsed;
		if (move != 0)
		{
			hint.visible = false;
			credits.y += move;
		}
		// limites: o texto inteiro tem cerca de 1700 px de altura
		var minY:Float = -(credits.height - FlxG.height + 100);
		if (credits.y < minY)
			credits.y = minY;
		if (credits.y > 50)
			credits.y = 50;
	}
}
