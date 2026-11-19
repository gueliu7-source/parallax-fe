package meta.state.parallax;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameObjects.educator.EduCursor;
import gameObjects.educator.EduShaders;
import meta.MusicBeat.MusicBeatState;
import meta.state.menus.OptionsMenuState;

/**
	Opcoes do Parallax: as do mod original (Math Mechanics, Schoolhouse Cursor), a troca de notas (mod / padrao),
	a qualidade dos efeitos (para chegar aos 30 FPS em PCs fracos) e um atalho para as opcoes completas da engine
	(Preferences, Controls, Note Skin, Downscroll...). Tudo e salvo no save do jogo.
**/
class ParallaxOptionsState extends MusicBeatState
{
	var items:Array<FlxText> = [];
	var desc:FlxText;
	var cur:Int = 0;

	static var QUALITY_NAMES:Array<String> = ['OFF (fastest)', 'LOW (default)', 'FULL'];
	static var DESCRIPTIONS:Array<String> = [
		'Turns the math questions during the song on or off.',
		'MOD = the pixel notes from Parallax. DEFAULT = the engine note skin (change it in Game Settings).',
		'Shows the Schoolhouse mouse cursor in the menus.',
		'Shader effects. If the game runs under 30 FPS, set this to OFF.',
		'Preferences, controls (keybinds), note skin, downscroll and everything else from the engine.',
		'Go back to the title screen.'
	];
	static inline var COUNT:Int = 6;

	override function create()
	{
		super.create();
		var bg = new FlxSprite().makeGraphic(1, 1, FlxColor.fromRGB(17, 5, 33));
		bg.origin.set(0, 0);
		bg.scale.set(FlxG.width, FlxG.height);
		add(bg);

		var checker = new FlxBackdrop(Paths.image('menus/title/checkerBoard'));
		checker.screenCenter();
		checker.scale.set(0.7, 0.7);
		checker.velocity.set(20, -20);
		add(checker);

		var title = new FlxText(0, 90, FlxG.width, 'Parallax Options', 60);
		title.setFormat(Paths.font('vcr.ttf'), 60, FlxColor.WHITE, CENTER);
		add(title);

		for (i in 0...COUNT)
		{
			var t = new FlxText(0, 250 + i * 80, FlxG.width, '', 44);
			t.setFormat(Paths.font('vcr.ttf'), 44, FlxColor.WHITE, CENTER);
			add(t);
			items.push(t);
		}

		desc = new FlxText(40, FlxG.height - 170, FlxG.width - 80, '', 28);
		desc.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.fromRGB(200, 180, 255), CENTER);
		add(desc);

		var hint = new FlxText(0, FlxG.height - 70, FlxG.width, 'UP/DOWN: select    ENTER or LEFT/RIGHT: change    BACK: return', 24);
		hint.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.GRAY, CENTER);
		add(hint);

		refresh();
		EduCursor.attach(this);
	}

	function mathOn():Bool
	{
		var m:Dynamic = FlxG.save.data.eduMath;
		return m != false;
	}

	function refresh()
	{
		items[0].text = 'Math Mechanics: ' + (mathOn() ? 'ON' : 'OFF');
		items[1].text = 'Notes: ' + (EduShaders.modNotes() ? 'MOD (pixel)' : 'DEFAULT');
		items[2].text = 'Schoolhouse Cursor: ' + (EduShaders.cursorEnabled() ? 'ON' : 'OFF');
		items[3].text = 'Effects: ' + QUALITY_NAMES[Std.int(Math.max(0, Math.min(2, EduShaders.quality())))];
		items[4].text = 'Game Settings >';
		items[5].text = 'Back';
		for (i in 0...items.length)
			items[i].color = (i == cur) ? FlxColor.RED : FlxColor.WHITE;
		desc.text = DESCRIPTIONS[cur];
	}

	function change(dir:Int)
	{
		switch (cur)
		{
			case 0:
				FlxG.save.data.eduMath = !mathOn();
			case 1:
				FlxG.save.data.eduNotes = !EduShaders.modNotes();
			case 2:
				FlxG.save.data.eduCursor = !EduShaders.cursorEnabled();
				FlxG.mouse.visible = !EduShaders.cursorEnabled();
			case 3:
				FlxG.save.data.eduQuality = (EduShaders.quality() + dir + 3) % 3;
			case 4:
				FlxG.save.flush();
				OptionsMenuState.fromParallax = true;
				Main.switchState(this, new OptionsMenuState());
				return;
			case 5:
				FlxG.save.flush();
				Main.switchState(this, new ParallaxTitleState());
				return;
		}
		FlxG.save.flush();
		FlxG.sound.play(Paths.sound('select'), 1);
		refresh();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.UP_P)
			cur = (cur + items.length - 1) % items.length;
		if (controls.DOWN_P)
			cur = (cur + 1) % items.length;
		if (controls.UP_P || controls.DOWN_P)
			refresh();

		if (controls.ACCEPT || controls.RIGHT_P)
			change(1);
		else if (controls.LEFT_P)
			change(-1);

		if (controls.BACK)
		{
			FlxG.save.flush();
			FlxG.sound.play(Paths.sound('cancel'), 1);
			Main.switchState(this, new ParallaxTitleState());
		}
	}
}
