package meta.state.parallax;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.text.FlxText.FlxTextBorderStyle;
import meta.state.PlayState;
import meta.state.menus.*;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.educator.EduCursor;
import gameObjects.educator.EduShaders;
import gameObjects.educator.EduWindow;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;

/**
	Titulo do Parallax (port de data/states/parallax/title.hx): intro com piscadas, logo que gira, "press enter"
	e menu play / options / credits. Atlases reduzidos (tools/repack_atlas.py): logo e press-enter a 50%.
**/
class ParallaxTitleState extends MusicBeatState
{
	static var introDone:Bool = false; // depois da primeira vez, volta direto ao menu

	var camBG:FlxCamera;
	var camFG:FlxCamera;
	var bgItems:FlxGroup;
	var menuItems:FlxGroup;
	var logo:FlxSprite;
	var menuTxt:FlxSprite;
	var blackThing:FlxSprite;
	var logoTween:FlxTween = null;

	var heat:Shader;
	var time:Float = 0;
	var num:Float = 0;

	var options:Array<String> = ['play', 'freeplay', 'story mode', 'options', 'credits'];
	var curSelected:Int = 0;

	var intro:Bool = true;
	var press:Bool = false;
	var select:Bool = false;
	var circleLogo:Bool = true;
	var beatBounce:Bool = true;
	var leaving:Bool = false;

	// posicao do centro do logo (o original posicionava o canto do frame de 3099x1922 a -700,-650)
	static inline var LOGO_CX:Float = 849.5;
	static inline var LOGO_CY:Float = 311;

	override function create()
	{
		super.create();
		camBG = new FlxCamera();
		camFG = new FlxCamera();
		camFG.bgColor = 0x00000000;
		FlxG.cameras.reset(camBG);
		FlxG.cameras.add(camFG);
		FlxCamera.defaultCameras = [camFG];

		bgItems = new FlxGroup();
		add(bgItems);

		var bg = new FlxSprite().loadGraphic(Paths.image('menus/title/bg'));
		bg.screenCenter();
		bg.scale.set(0.7, 0.7);
		bg.cameras = [camBG];
		bgItems.add(bg);

		var checker = new FlxBackdrop(Paths.image('menus/title/checkerBoard'));
		checker.screenCenter();
		checker.scale.set(0.7, 0.7);
		checker.velocity.set(20, -20);
		checker.cameras = [camBG];
		bgItems.add(checker);

		var glitch = new FlxSprite().loadGraphic(Paths.image('menus/title/glitch'));
		glitch.screenCenter();
		glitch.scale.set(0.7, 0.7);
		glitch.cameras = [camBG];
		bgItems.add(glitch);
		bgItems.visible = false;

		if (EduShaders.quality() > 0)
		{
			try
			{
				heat = EduShaders.load('heatShader');
				heat.data.iTime.value = [0.0];
				camBG.setFilters([new ShaderFilter(heat)]);
			}
			catch (e:Dynamic)
			{
				trace('titulo: heatShader desativado (' + e + ')');
				heat = null;
			}
		}

		logo = new FlxSprite();
		logo.frames = Paths.getSparrowAtlas('menus/title/ParalaxlogoSmall');
		logo.animation.addByPrefix('idle', 'logoidle', 32, true);
		logo.animation.addByPrefix('enter', 'logoenter', 24, false);
		logo.animation.play('idle');
		logo.antialiasing = true;
		logo.scale.set(1.3, 1.3); // atlas a 50%: 0.65 * 2
		add(logo);

		menuTxt = new FlxSprite();
		menuTxt.frames = Paths.getSparrowAtlas('menus/title/pressenterSmall');
		menuTxt.animation.addByPrefix('idle', 'peinstance', 30, true);
		menuTxt.animation.addByPrefix('enter', 'peEnter', 30, false);
		menuTxt.animation.play('idle');
		menuTxt.antialiasing = true;
		menuTxt.scale.set(1.2, 1.2);
		menuTxt.screenCenter();
		menuTxt.y += 685;
		menuTxt.x += 50;
		FlxTween.tween(menuTxt, {alpha: 0.75}, 0.75, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
		add(menuTxt);

		menuItems = new FlxGroup();
		add(menuItems);
		for (i in 0...options.length)
		{
			var t = new FlxText(0, FlxG.height + 200, 0, options[i], 50); // fora da tela (o original usava 900, que cabia em 720)
			t.setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE);
			t.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
			t.borderSize = 2;
			t.borderColor = 0xff000000;
			t.x = (FlxG.width - t.width) / 2;
			t.ID = i;
			menuItems.add(t);
		}

		blackThing = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		blackThing.origin.set(0, 0);
		blackThing.scale.set(FlxG.width, FlxG.height);
		blackThing.alpha = 0;
		add(blackThing);

		Conductor.changeBPM(110);
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);

		EduCursor.attach(this);

		if (introDone)
		{
			intro = false;
			select = true;
			circleLogo = false;
			beatBounce = false;
			logo.visible = false;
			menuTxt.visible = false;
			bgItems.visible = true;
			for (i in 0...options.length)
				(cast menuItems.members[i] : FlxSprite).y = menuY(i);
		}
		introDone = true;
	}

	function menuY(i:Int):Float
	{
		return FlxG.height / 2 - 75 + i * 85;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		num += elapsed * 30;
		time += elapsed;
		if (heat != null)
			heat.data.iTime.value = [time];

		if (circleLogo)
		{
			logo.x = LOGO_CX + FlxMath.fastCos(num / 15) * 20 - logo.width / 2;
			logo.y = LOGO_CY + FlxMath.fastSin(num / 15) * 20 - logo.height / 2;
		}

		if (press && controls.ACCEPT)
		{
			press = false;
			circleLogo = false;
			beatBounce = false;
			FlxG.sound.play(Paths.sound('select'), 1);
			FlxFlicker.flicker(menuTxt, 0.85, 0.07, false);
			FlxTween.tween(logo, {y: logo.y + 1500}, 1.5, {
				ease: FlxEase.backInOut,
				startDelay: 0.5,
				onComplete: function(_)
				{
					logo.visible = false;
					showMenu();
				}
			});
		}

		if (select && !leaving)
			updateMenu();
	}

	function showMenu()
	{
		for (i in 0...options.length)
		{
			FlxTween.tween(menuItems.members[i], {y: menuY(i)}, 2, {
				ease: FlxEase.quartOut,
				onComplete: function(_)
				{
					select = true;
				}
			});
		}
	}

	function updateMenu()
	{
		// mouse (como no original) + teclado
		for (m in menuItems.members)
		{
			var s:FlxSprite = cast m;
			if (FlxG.mouse.overlaps(s) && FlxG.mouse.justMoved)
				curSelected = s.ID;
		}
		if (controls.UP_P)
			curSelected = (curSelected + options.length - 1) % options.length;
		if (controls.DOWN_P)
			curSelected = (curSelected + 1) % options.length;

		var clicked = false;
		for (m in menuItems.members)
		{
			var s:FlxSprite = cast m;
			s.color = (s.ID == curSelected) ? FlxColor.RED : FlxColor.WHITE;
			if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(s))
			{
				curSelected = s.ID;
				clicked = true;
			}
		}
		if (clicked || controls.ACCEPT)
			choose(options[curSelected]);
	}

	function choose(opt:String)
	{
		FlxG.sound.play(Paths.sound('select'), 1);
		leaving = true;
		switch (opt)
		{
			case 'play':
				if (FlxG.sound.music != null)
					FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);
				FlxTween.tween(blackThing, {alpha: 1}, 0.5, {
					onComplete: function(_)
					{
						startSong();
					}
				});
			case 'freeplay':
				Main.switchState(this, new FreeplayState());
			case 'story mode':
				Main.switchState(this, new StoryMenuState());
			case 'options':
				Main.switchState(this, new ParallaxOptionsState());
			case 'credits':
				Main.switchState(this, new ParallaxCreditsState());
		}
	}

	function startSong()
	{
		PlayState.SONG = Song.loadFromJson('expulsion-hard', 'expulsion');
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = 2;
		PlayState.storyWeek = 0;
		ParallaxFlow.launchedFromTitle = true;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		Main.switchState(this, new PlayState());
	}

	override function stepHit()
	{
		super.stepHit();
		if (!intro)
			return;
		switch (curStep)
		{
			case 1:
				EduWindow.popIn();
			case 5 | 7:
				bgItems.visible = true;
			case 6 | 8:
				bgItems.visible = false;
			case 9:
				FlxG.autoPause = true;
				logo.animation.play('enter');
				logo.animation.finishCallback = function(_) logo.animation.play('idle');
				bgItems.visible = true;
				FlxTween.tween(menuTxt, {y: menuTxt.y - 325}, 1.75, {
					ease: FlxEase.backInOut,
					startDelay: 0.5,
					onComplete: function(_)
					{
						press = true;
						intro = false;
					}
				});
				camFG.flash(FlxColor.WHITE, 1.25);
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (!logo.visible)
			return;
		if (logoTween != null)
			logoTween.cancel();
		if (beatBounce)
			logo.scale.set(1.45, 1.45); // 0.725 * 2
		logoTween = FlxTween.tween(logo.scale, {x: 1.3, y: 1.3}, 1, {ease: FlxEase.quartOut});
	}
}
