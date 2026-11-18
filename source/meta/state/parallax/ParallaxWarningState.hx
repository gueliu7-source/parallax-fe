package meta.state.parallax;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.educator.EduWindow;
import meta.MusicBeat.MusicBeatState;
import meta.data.font.Alphabet;

/** Tela de aviso do Parallax (port de data/states/parallax/warning.hx). Primeira tela do jogo. **/
class ParallaxWarningState extends MusicBeatState
{
	var press:Bool = true;

	override function create()
	{
		super.create();
		FlxG.mouse.visible = false;
		FlxG.autoPause = false;
		EduWindow.windowed();

		var title = new Alphabet(0, 0, 'WARNING', true);
		title.x = (FlxG.width - title.width) / 2;
		title.y = FlxG.height / 2 - 140;
		add(title);

		var y = title.y + 80;
		var t0 = line('This is, if it wasnt obvious, a', y, FlxColor.WHITE);
		t0.x -= 50;
		var demo = line('demo!', y, FlxColor.RED);
		demo.x = t0.x + 350;

		y = title.y + 135;
		line('If you notice any bugs please reach out to me at `krystalklean` on discord, i will try my best to fix them <3', y, FlxColor.WHITE);
		y += 80;
		line('(Sorry this took a whole year i promise there will be more where this came from, mods take time XP)', y, FlxColor.WHITE);
		y += 120;
		line('Press ENTER to continue', y, FlxColor.WHITE);
	}

	function line(text:String, y:Float, color:FlxColor):FlxText
	{
		var t = new FlxText(0, y, FlxG.width, text, 30);
		t.setFormat(Paths.font('vcr.ttf'), 30, color, CENTER);
		add(t);
		return t;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!press)
			return;

		if (controls.ACCEPT || controls.BACK)
		{
			press = false;
			FlxG.sound.play(Paths.sound('select'), 1);
			FlxG.camera.flash(FlxColor.WHITE, 1, function()
			{
				FlxG.camera.fade(FlxColor.BLACK, 0.75, false);
			});
			var go = function()
			{
				Main.switchState(this, new ParallaxTitleState());
			};
			if (controls.ACCEPT)
				EduWindow.slideOffscreen(go); // como no original: a janela desce para fora da tela
			else
				new FlxTimer().start(3, function(_) go()); // BACK: pula a animacao (para quem tem problema com a janela)
		}
	}
}
