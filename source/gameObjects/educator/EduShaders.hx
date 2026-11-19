package gameObjects.educator;

import flixel.FlxG;
import openfl.display.GraphicsShader;
import openfl.display.Shader;
import openfl.utils.Assets;

using StringTools;

/** utilitarios compartilhados pelas telas do Parallax: shaders do mod como filtros de camera e o cursor "Schoolhouse" **/
class EduShaders
{
	/** carrega assets/shaders/<nome>.frag (os .frag do mod usam flixel_texture2D, que aqui vira texture2D) **/
	public static function load(name:String):Shader
	{
		var src:String = Assets.getText('assets/shaders/' + name + '.frag');
		src = src.replace('flixel_texture2D', 'texture2D');
		return fromSource(src);
	}

	/** GraphicsShader (e nao o Shader puro) traz o vertex shader padrao: sem ele `shader.data` fica vazio e o filtro nao desenha **/
	public static function fromSource(src:String):Shader
	{
		return new GraphicsShader('', src, true);
	}

	/** 0 = sem shaders | 1 = so rajadas curtas (padrao) | 2 = completo (mesma opcao do EducatorStage) **/
	public static function quality():Int
	{
		var q:Dynamic = FlxG.save.data.eduQuality;
		return (q != null) ? Std.int(q) : EducatorStage.quality;
	}

	/** true = notas do mod (pixel EDUCATOR_Notes); false = skin normal da Forever **/
	public static function modNotes():Bool
	{
		var n:Dynamic = FlxG.save.data.eduNotes;
		return n != false;
	}

	public static function cursorEnabled():Bool
	{
		var c:Dynamic = FlxG.save.data.eduCursor;
		return c == true;
	}
}
