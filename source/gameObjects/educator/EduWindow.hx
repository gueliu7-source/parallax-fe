package gameObjects.educator;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.app.Application;
import lime.system.System;

/**
	Animacoes da janela do sistema usadas pelo mod original (warning.hx / title.hx):
	a janela desce para fora da tela ao sair do aviso e "pula" do centro ao entrar no titulo.
	Tudo e cosmetico: se algo falhar (ex.: tela cheia), simplesmente nao anima.
**/
class EduWindow
{
	public static inline var W:Int = 960;
	public static inline var H:Int = 720;

	static function screenSize():{w:Int, h:Int}
	{
		try
		{
			var d = System.getDisplay(0);
			if (d != null)
				return {w: d.currentMode.width, h: d.currentMode.height};
		}
		catch (e:Dynamic) {}
		return {w: 1920, h: 1080};
	}

	public static function windowed()
	{
		try
		{
			Application.current.window.fullscreen = false;
		}
		catch (e:Dynamic) {}
	}

	public static function center()
	{
		try
		{
			var win = Application.current.window;
			var s = screenSize();
			win.x = Std.int((s.w - win.width) / 2);
			win.y = Std.int((s.h - win.height) / 2);
		}
		catch (e:Dynamic) {}
	}

	/** desce a janela para fora da tela (2 s, comeca apos 1 s) e chama `done` **/
	public static function slideOffscreen(done:Void->Void)
	{
		var win = null;
		var y0 = 0;
		var s = screenSize();
		try
		{
			win = Application.current.window;
			y0 = win.y;
		}
		catch (e:Dynamic) {}
		if (win == null)
		{
			done();
			return;
		}
		FlxTween.num(0, 1, 2, {
			ease: FlxEase.backInOut,
			startDelay: 1,
			onComplete: function(_) done()
		}, function(v:Float)
		{
			win.y = Std.int(y0 + v * (s.h + 1000));
		});
	}

	/** a janela comeca 1x1 no centro e cresce ate 960x720 em 0,32 s **/
	public static function popIn()
	{
		var win = null;
		try
		{
			win = Application.current.window;
		}
		catch (e:Dynamic) {}
		if (win == null)
			return;
		windowed();
		win.resize(1, 1);
		center();
		FlxTween.num(0, 1, 0.32, {ease: FlxEase.backOut, onComplete: function(_)
		{
			win.resize(W, H);
			center();
		}}, function(v:Float)
		{
			win.resize(Std.int(Math.max(1, 1 + (W - 1) * v)), Std.int(Math.max(1, 1 + (H - 1) * v)));
			center();
		});
	}
}
