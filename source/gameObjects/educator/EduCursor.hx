package gameObjects.educator;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

/** cursor "Schoolhouse" do mod: segue o mouse e troca de quadro ao clicar. Opcional (menu de opcoes). **/
class EduCursor extends FlxSprite
{
	public function new()
	{
		super();
		frames = Paths.getSparrowAtlas('ui/educator/cursor');
		animation.addByPrefix('idle', 'idle', 1, false);
		animation.addByPrefix('select', 'select', 1, false);
		animation.play('idle');
		antialiasing = false;
		scale.set(1.2, 1.2);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		setPosition(FlxG.mouse.screenX, FlxG.mouse.screenY);
		animation.play(FlxG.mouse.pressed ? 'select' : 'idle');
	}

	/** adiciona o cursor ao estado (em camera propria, sempre por cima) se a opcao estiver ligada **/
	public static function attach(state:FlxState):Void
	{
		FlxG.mouse.visible = true;
		if (!EduShaders.cursorEnabled())
			return;
		FlxG.mouse.visible = false;
		var cam = new FlxCamera();
		cam.bgColor = 0x00000000;
		FlxG.cameras.add(cam);
		var c = new EduCursor();
		c.cameras = [cam];
		state.add(c);
	}
}
