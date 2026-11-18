package meta.subState;

/**
	Game over do PARALLAX (port de data/scripts/educatorGameOver.hx da Codename Engine):
	moldura do HUD, icone do BF "derrotado" e a placa "game over" pulsando ao ritmo da musica (100 BPM).
**/
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import meta.MusicBeat.MusicBeatSubState;
import meta.state.*;
import meta.state.menus.*;

class EducatorGameOverSubstate extends MusicBeatSubState
{
	var cam:FlxCamera;
	var hud:FlxSprite;
	var iconBF:FlxSprite;
	var gameover:FlxSprite;
	var press:Bool = true;
	var pulseTimer:FlxTimer;

	public function new(evilHud:Bool)
	{
		super();
		FlxG.autoPause = true;

		FlxG.sound.play(Paths.sound('gameOverSFX'), 0.75);

		cam = new FlxCamera();
		cam.bgColor = 0x00000000;
		FlxG.cameras.add(cam);

		hud = new FlxSprite(0, 0);
		hud.frames = Paths.getSparrowAtlas('ui/educator/educator-gui-trans');
		hud.animation.addByPrefix('normal', 'educator GUI1', 1, false);
		hud.animation.addByPrefix('evil', 'educator GUI7', 1, false);
		hud.animation.play(evilHud ? 'evil' : 'normal');
		hud.antialiasing = false;
		hud.screenCenter();
		hud.setGraphicSize(1280, 960);
		add(hud);

		iconBF = new FlxSprite(785, 786);
		iconBF.frames = Paths.getSparrowAtlas('ui/educator/bfIcon');
		iconBF.animation.addByPrefix('idle', 'default', 1, false);
		iconBF.animation.addByPrefix('defeat', 'defeat', 1, false);
		iconBF.animation.play('defeat');
		iconBF.antialiasing = false;
		add(iconBF);

		gameover = new FlxSprite(805, 780);
		gameover.frames = Paths.getSparrowAtlas('bgs/educator/gameover-edu');
		gameover.animation.addByPrefix('idle', 'gameover', 4, true);
		gameover.animation.play('idle');
		gameover.screenCenter();
		gameover.antialiasing = false;
		gameover.alpha = 0;
		add(gameover);

		FlxTween.tween(gameover, {alpha: 1}, 1, {
			ease: FlxEase.quadInOut,
			onComplete: function(_)
			{
				if (!press)
					return;
				FlxG.sound.playMusic(Paths.music('educator/eduover'), 1, true);
				// 100 BPM: a placa pulsa a cada 2 beats (1,2 s), comecando no beat 1 (0,6 s)
				new FlxTimer().start(0.6, function(_)
				{
					pulse();
					pulseTimer = new FlxTimer().start(1.2, function(_) pulse(), 0);
				});
			}
		});

		cameras = [cam];
	}

	function pulse()
	{
		if (!press)
			return;
		gameover.scale.set(1.25, 1.25);
		FlxTween.tween(gameover.scale, {x: 1, y: 1}, 1, {ease: FlxEase.quartOut});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (press && controls.ACCEPT)
			endBullshit();

		if (press && controls.BACK)
		{
			press = false;
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			Main.switchState(this, new meta.state.parallax.ParallaxTitleState());
		}
	}

	function endBullshit():Void
	{
		press = false;
		if (pulseTimer != null)
			pulseTimer.cancel();
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}
		FlxG.sound.play(Paths.sound('educator/eduoverenter'), 1);
		FlxTween.tween(gameover, {alpha: 0}, 3, {ease: FlxEase.quadInOut});
		new FlxTimer().start(3, function(_)
		{
			Main.switchState(this, new PlayState());
		});
	}
}
