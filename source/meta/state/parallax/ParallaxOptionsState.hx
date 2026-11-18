package meta.state.parallax;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameObjects.educator.EduCursor;
import gameObjects.educator.EduShaders;
import meta.MusicBeat.MusicBeatState;

/**
	Opcoes do Parallax. Equivalem a data/config/options.xml do mod (Math Mechanics, Schoolhouse Cursor)
	mais a qualidade dos efeitos (para chegar aos 30 FPS em PCs fracos). Ficam salvas no save do jogo.
**/
class ParallaxOptionsState extends MusicBeatState
{
	var items:Array<FlxText> = [];
	var cur:Int = 0;
	static var QUALITY_NAMES:Array<String> = ['OFF (fastest)', 'LOW (default)', 'FULL'];

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

		var title = new FlxText(0, 120, FlxG.width, 'Parallax Options', 60);
		title.setFormat(Paths.font('vcr.ttf'), 60, FlxColor.WHITE, CENTER);
		add(title);

		var hint = new FlxText(0, FlxG.height - 80, FlxG.width, 'UP/DOWN: select   ENTER or LEFT/RIGHT: change   BACK: return', 26);
		hint.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.GRAY, CENTER);
		add(hint);

		for (i in 0...4)
		{
			var t = new FlxText(0, 330 + i * 85, FlxG.width, '', 44);
			t.setFormat(Paths.font('vcr.ttf'), 44, FlxColor.WHITE, CENTER);
			add(t);
			items.push(t);
		}
		refresh();
		EduCursor.attach(this);
	}

	function mathOn():Bool
	{
		var m:Dynamic = FlxG.save.data.eduMath;
		return m != false;
	}

	function quality():Int
	{
		return EduShaders.quality();
	}

	function refresh()
	{
		items[0].text = 'Math Mechanics: ' + (mathOn() ? 'ON' : 'OFF');
		items[1].text = 'Schoolhouse Cursor: ' + (EduShaders.cursorEnabled() ? 'ON' : 'OFF');
		items[2].text = 'Effects: ' + QUALITY_NAMES[Std.int(Math.max(0, Math.min(2, quality())))];
		items[3].text = 'Back';
		for (i in 0...items.length)
			items[i].color = (i == cur) ? FlxColor.RED : FlxColor.WHITE;
	}

	function change(dir:Int)
	{
		switch (cur)
		{
			case 0:
				FlxG.save.data.eduMath = !mathOn();
			case 1:
				FlxG.save.data.eduCursor = !EduShaders.cursorEnabled();
				FlxG.mouse.visible = !EduShaders.cursorEnabled();
			case 2:
				FlxG.save.data.eduQuality = (quality() + dir + 3) % 3;
			case 3:
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
