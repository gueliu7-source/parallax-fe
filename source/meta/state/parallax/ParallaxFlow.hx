package meta.state.parallax;

import flixel.FlxState;
import meta.state.menus.*;

/** Decide para onde voltar depois de uma musica: titulo do Parallax (se foi iniciada por ele) ou Freeplay/Story (menus da Forever). **/
class ParallaxFlow
{
	public static var launchedFromTitle:Bool = false;

	public static function afterSong(story:Bool):FlxState
	{
		if (launchedFromTitle)
			return new ParallaxTitleState();
		if (story)
			return new StoryMenuState();
		return new FreeplayState();
	}
}
