package gameObjects.educator;

/**
	Port do stage/mecanicas do mod PARALLAX (Codename Engine -> Forever Engine).
	Substitui o script `educatorStage.hx` original: monta o cenario, troca os 4 personagens do oponente,
	executa os eventos do chart (assets/songs/expulsion/events.json), os efeitos por beat e o minigame de matematica.

	AJUSTES RAPIDOS: posicoes em DAD_X/DAD_Y/BF_X/BF_Y (as originais dependem de um XML de stage que o mod nao traz,
	entao foram estimadas) e qualidade dos efeitos em `quality` (0 sem shaders, 1 so rajadas curtas, 2 completo).
**/
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.Character;
import haxe.Json;
import meta.data.*;
import meta.state.PlayState;
import openfl.display.Shader;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;

using StringTools;

class EducatorStage
{
	// ---- ajustes ----
	public static inline var DAD_X:Float = 150;
	public static inline var DAD_Y:Float = 210;
	public static inline var BF_X:Float = 770;
	public static inline var BF_Y:Float = 400;
	static inline var CAM_X:Float = 270;
	static inline var CAM_Y:Float = 325;

	/** 0 = sem shaders | 1 = so rajadas curtas (padrao, mais leve) | 2 = completo (glitch permanente + quadro-negro) **/
	public static var quality:Int = 1;

	// perguntas do minigame: [formato, texto1, texto2, resposta]. formato 1: t1+resp | 2: resp+t1 | 3: t1+resp+t2 | 4: t1+resp (2 digitos)
	static var QUESTIONS:Array<Array<Dynamic>> = [
		[1, '20 / 5 = ', '', '4'], [1, '4 * 2 = ', '', '8'], [1, '9, 8, 7, 6, ', '', '5'], [1, '12 / (2 * 3) = ', '', '2'],
		[4, '9 * 2 - 5 = ', '', '13'], [1, '50 / 10 + 3 = ', '', '8'], [1, '(25 * 2) / 10 = ', '', '5'], [1, '60 / 20 = ', '', '3'],
		[1, '13 - 7 = ', '', '6'], [1, '1, 3, 5, ', '', '7'], [1, '2 * 2 = ', '', '4'], [4, '8 + 7 = ', '', '15'],
		[1, '3 * 3 = ', '', '9'], [2, ' * 3 = 12', '', '4'], [1, 'what comes after 3? ', '', '4'], [1, 'what comes before 10? ', '', '9'],
		[1, 'what comes before 5? ', '', '4'], [3, '4 + ', ' = 6', '2'], [2, ' * 11 = 88', '', '8'], [4, '9 * 2 = ', '', '18'],
		[4, '3 * 7 = ', '', '21'], [4, '6 * 6 = ', '', '36'], [4, '5 * 2 = ', '', '10'], [4, '30 * 3 = ', '', '90'],
		[4, '5 * 6 = ', '', '30']
	];

	var ps:PlayState;
	var downscroll:Bool;
	var time:Float = 0;

	// cameras
	var camDoor:FlxCamera;
	var camBoard:FlxCamera;

	// sprites
	var bg:FlxSprite; // schoolhouse / transition / dark
	var bgMeat:FlxSprite;
	var door:FlxSprite;
	var wall1:FlxSprite;
	var wall2:FlxSprite;
	var hud:FlxSprite;
	var blackboard:FlxSprite;
	var mathTxt:FlxText;
	var iconBF:FlxSprite;
	var xMarks:Array<FlxSprite> = [];
	var fadeIn:FlxSprite;
	var fadeGame:FlxSprite;

	// personagens do oponente: 0 fake, 1 trans, 2 fake-glitch, 3 real
	var chars:Array<Character> = [];
	var trail:FlxTrail;

	// eventos do chart
	var events:Array<Dynamic> = [];
	var evIndex:Int = 0;

	// estado do stage
	var evil:Bool = false;
	var sideToSide:Bool = false;
	var camZoomInterval:Int = 1;
	var camZoomAmount:Float = 0;
	var strumsShown:Bool = false;

	// minigame
	var mathEnabled:Bool = true;
	var mathTime:Bool = false;
	var question:Array<Dynamic> = null;
	var answer:String = '_';
	var answer2:String = '_';
	var slot:Int = 0;
	var locked:Bool = false;
	var wrongAnswers:Int = 0;
	var gameOverTriggered:Bool = false;

	// shaders (filtros de camera)
	var compression:Shader;
	var glitchShader:Shader;
	var dadGlitch:Shader;
	var bwShader:Shader;
	var fCompression:ShaderFilter;
	var fSchool:ShaderFilter;
	var fDad:ShaderFilter;
	var fBW:ShaderFilter;
	var compOn:Bool = false;
	var schoolGlitchOn:Bool = false;
	var dadGlitchOn:Bool = false;
	var bwOn:Bool = false;
	var compAmount:Float = 0.01;
	var dadProb:Float = 0;
	var schoolProb:Float = 0.02;
	var boardFilterOn:Bool = false;
	var boardShader:Shader;

	public function new(ps:PlayState)
	{
		this.ps = ps;
		downscroll = Init.trueSettings.get('Downscroll');
		var q = FlxG.save.data.eduQuality;
		if (q != null)
			quality = q;
		if (FlxG.save.data.eduMath == false)
			mathEnabled = false;

		loadEvents();
		buildCameras();
		buildWorld();
		buildHud();
		buildCharacters();
		buildShaders();
		hideUi();
	}

	// ------------------------------------------------------------------ montagem

	function loadEvents()
	{
		try
		{
			var raw = Assets.getText('assets/songs/expulsion/events.json');
			events = Json.parse(raw);
			events.sort(function(a, b) return Std.int(a.time - b.time));
		}
		catch (e:Dynamic)
		{
			trace('EducatorStage: nao consegui ler events.json: ' + e);
		}
	}

	function buildCameras()
	{
		camDoor = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		camDoor.zoom = 0.5;
		camDoor.y += 40;
		camDoor.bgColor = 0x00000000;
		FlxG.cameras.add(camDoor);
		// camDoor desenha logo acima da camGame e abaixo do HUD
		FlxG.cameras.list.remove(camDoor);
		FlxG.cameras.list.insert(FlxG.cameras.list.indexOf(PlayState.camGame) + 1, camDoor);

		if (quality >= 2)
		{
			camBoard = new FlxCamera(0, 0, FlxG.width, FlxG.height);
			camBoard.bgColor = 0x00000000;
			FlxG.cameras.add(camBoard);
		}
	}

	function place(obj:flixel.FlxBasic, behind:flixel.FlxBasic = null)
	{
		var idx = behind != null ? ps.members.indexOf(behind) : -1;
		if (idx >= 0)
			ps.insert(idx, obj);
		else
			ps.add(obj);
	}

	function solid(w:Float, h:Float):FlxSprite
	{
		// 1x1 esticado: evita uma textura de 4000x4000 (64 MB) so para um fade preto
		var s = new FlxSprite(-700, -850).makeGraphic(1, 1, FlxColor.BLACK);
		s.origin.set(0, 0);
		s.scale.set(w, h);
		return s;
	}

	function buildWorld()
	{
		FlxG.autoPause = true;
		PlayState.defaultCamZoom = 1;

		// cenario (atlas reduzido a 50%: ver tools/optimize_schoolhouse.py). scale 2 devolve o tamanho original.
		bg = new FlxSprite(-350, -100);
		bg.frames = Paths.getSparrowAtlas('bgs/educator/SchoolhouseA');
		bg.animation.addByPrefix('idle', 'schoolhouse', 6);
		bg.animation.addByPrefix('transition', 'transition', 6);
		bg.animation.addByPrefix('dark', 'dark', 6);
		bg.animation.play('idle');
		bg.origin.set(0, 0);
		bg.scale.set(2, 2);
		bg.scrollFactor.set(0.87, 1);
		bg.antialiasing = false;
		bg.cameras = [camDoor];

		bgMeat = new FlxSprite(-640, -250);
		bgMeat.frames = Paths.getSparrowAtlas('bgs/educator/SchoolhouseB');
		bgMeat.animation.addByPrefix('meat', 'meat', 7);
		bgMeat.animation.play('meat');
		bgMeat.origin.set(0, 0);
		bgMeat.scale.set(2, 2);
		bgMeat.scrollFactor.set(0.87, 1);
		bgMeat.antialiasing = false;
		bgMeat.visible = false;
		bgMeat.cameras = [PlayState.camGame];

		door = new FlxSprite(575, 300);
		door.frames = Paths.getSparrowAtlas('bgs/educator/theFUCKINGdoor');
		door.animation.addByPrefix('open', 'doorOpen', 4, false);
		door.animation.frameIndex = 0;
		door.antialiasing = false;
		door.scale.set(5, 5);
		door.cameras = [camDoor];

		wall1 = new FlxSprite(-448, 195).loadGraphic(Paths.image('bgs/educator/wall'));
		wall1.antialiasing = false;
		wall1.scale.set(5, 5);
		wall1.cameras = [camDoor];
		wall2 = new FlxSprite(1471, 190).loadGraphic(Paths.image('bgs/educator/wall'));
		wall2.antialiasing = false;
		wall2.scale.set(5, 5);
		wall2.cameras = [camDoor];

		// tudo isso fica atras dos personagens
		place(bg, PlayState.gf);
		place(bgMeat, PlayState.gf);
		place(door, PlayState.gf);
		place(wall1, PlayState.gf);
		place(wall2, PlayState.gf);

		fadeIn = solid(4000, 4000);
		fadeIn.cameras = [camDoor];
		fadeIn.alpha = 0.0001;
		fadeGame = solid(4000, 4000);
		fadeGame.cameras = [PlayState.camGame];
		fadeGame.alpha = 1;
		ps.add(fadeIn);
		ps.add(fadeGame);

		PlayState.gf.visible = false; // o stage nao tem GF
	}

	function buildHud()
	{
		hud = new FlxSprite(0, 0);
		hud.frames = Paths.getSparrowAtlas('ui/educator/educator-gui-trans');
		hud.animation.addByPrefix('normal', 'educator GUI1', 1, false);
		hud.animation.addByPrefix('evil', 'educator GUI', 10, false);
		hud.animation.play('normal');
		hud.antialiasing = false;
		hud.screenCenter();
		hud.setGraphicSize(1280, 960);
		hud.cameras = [PlayState.camHUD];
		hud.y += 120;
		ps.insert(0, hud);

		for (i in 0...3)
		{
			var x = new FlxSprite(1040).loadGraphic(Paths.image('ui/educator/X'));
			x.cameras = [PlayState.camHUD];
			x.scale.set(1.1, 1.1);
			x.y = downscroll ? 40 : 850;
			x.x = 1040 + 75 * i;
			x.alpha = 0;
			ps.add(x);
			xMarks.push(x);
		}

		blackboard = new FlxSprite(0, 0);
		blackboard.frames = Paths.getSparrowAtlas('ui/educator/Blackboard');
		blackboard.animation.addByPrefix('normal', 'normal', 1, false);
		blackboard.animation.addByPrefix('evil', 'evil', 1, false);
		blackboard.animation.play('normal');
		blackboard.screenCenter();
		blackboard.y += downscroll ? 730 : -500;
		blackboard.cameras = [camBoard != null ? camBoard : PlayState.camHUD];
		blackboard.scale.set(2, 2);
		ps.insert(0, blackboard);

		iconBF = new FlxSprite(785, 786);
		iconBF.frames = Paths.getSparrowAtlas('ui/educator/bfIcon');
		iconBF.animation.addByPrefix('idle', 'default', 1, false);
		iconBF.animation.addByPrefix('defeat', 'defeat', 1, false);
		iconBF.animation.play('idle');
		iconBF.antialiasing = false;
		if (downscroll)
			iconBF.y = 0;
		iconBF.cameras = [PlayState.camHUD];
		ps.insert(2, iconBF);

		mathTxt = new FlxText(0, 450, FlxG.width, '', 25);
		mathTxt.setFormat(Paths.font('schoolhouse.TTF'), 42, FlxColor.WHITE, CENTER);
		mathTxt.alpha = 0;
		mathTxt.cameras = [camBoard != null ? camBoard : PlayState.camHUD];
		ps.insert(1, mathTxt);
	}

	function buildCharacters()
	{
		chars.push(PlayState.dadOpponent); // educatorFake (vem do chart: player2)
		var names = ['educatorTrans', 'educatorFakeGlitch', 'educatorReal'];
		for (n in names)
		{
			var c = new Character(DAD_X, DAD_Y, n);
			c.visible = false;
			place(c, PlayState.boyfriend);
			chars.push(c);
		}
		// o personagem dos sing-anims e o que esta visivel; durante a transicao (trans) as notas vao para o fake escondido
		for (c in chars)
		{
			c.x = DAD_X;
		}
		chars[0].y = DAD_Y;
		chars[3].y = DAD_Y - 13; // educatorReal tem y menor no XML original
		chars[1].y = DAD_Y;
		chars[2].y = DAD_Y;

		PlayState.boyfriend.x = BF_X;
		PlayState.boyfriend.y = BF_Y;

		var tl = quality >= 2 ? 6 : 3;
		trail = new FlxTrail(chars[3], null, tl, 24, 0.35, 0.069);
	}

	function loadShader(name:String):Shader
	{
		var src:String = Assets.getText('assets/shaders/' + name + '.frag');
		src = src.replace('flixel_texture2D', 'texture2D');
		var s = new Shader();
		s.glFragmentSource = src;
		return s;
	}

	function buildShaders()
	{
		if (quality <= 0)
			return;
		try
		{
			compression = loadShader('compression');
			compression.data.glitchAmount.value = [0.01];
			compression.data.iTime.value = [0.0];
			glitchShader = loadShader('glitch');
			glitchShader.data.prob.value = [0.0];
			dadGlitch = loadShader('glitch');
			dadGlitch.data.prob.value = [0.0];
			// "preto e branco": versao propria e simples (o BlackWhite.frag original usa macros do FlxShader)
			bwShader = new Shader();
			bwShader.glFragmentSource = '#pragma header\nvoid main() { vec4 c = texture2D(bitmap, openfl_TextureCoordv); float g = step(0.45, dot(c.rgb, vec3(0.299, 0.587, 0.114))); gl_FragColor = vec4(vec3(g) * c.a, c.a); }';
			fCompression = new ShaderFilter(compression);
			fSchool = new ShaderFilter(glitchShader);
			fDad = new ShaderFilter(dadGlitch);
			fBW = new ShaderFilter(bwShader);
			if (quality >= 2)
			{
				boardShader = loadShader('compression');
				boardShader.data.glitchAmount.value = [0.25];
				boardShader.data.iTime.value = [0.0];
			}
		}
		catch (e:Dynamic)
		{
			trace('EducatorStage: shaders desativados (' + e + ')');
			quality = 0;
		}
	}

	function hideUi()
	{
		// HUD original do Forever sai: o stage tem o proprio
		var h = PlayState.uiHUD;
		h.healthBar.visible = false;
		h.healthBarBG.visible = false;
		h.iconP1.visible = false;
		h.iconP2.visible = false;
		// strums so aparecem no beat 28
		for (sl in PlayState.strumLines)
			for (r in sl.receptors)
				r.visible = false;
	}

	// ------------------------------------------------------------------ filtros de camera

	function refreshFilters()
	{
		if (quality <= 0)
			return;
		var f:Array<BitmapFilter> = [];
		if (quality >= 2 && schoolGlitchOn)
			f.push(fSchool);
		if (dadGlitchOn)
			f.push(fDad);
		if (bwOn)
			f.push(fBW);
		if (compOn)
			f.push(fCompression);
		PlayState.camGame.setFilters(f);
	}

	function tweenGlitch(from:Float, to:Float, dur:Float, ?done:Void->Void)
	{
		FlxTween.num(from, to, dur, {
			onComplete: function(_)
			{
				if (done != null)
					done();
			}
		}, function(v:Float)
		{
			dadProb = v;
		});
	}

	/** rajada de glitch no oponente: sobe a 1.25 e desce para `rest` (0 = apaga o filtro). **/
	function glitchBurst(upTime:Float, rest:Float)
	{
		if (quality <= 0)
			return;
		dadGlitchOn = true;
		refreshFilters();
		tweenGlitch(0, 1.25, upTime, function()
		{
			tweenGlitch(1.25, rest, 0.15, function()
			{
				if (rest <= 0)
				{
					dadGlitchOn = false;
					refreshFilters();
				}
			});
		});
	}

	function setBW(on:Bool)
	{
		if (quality <= 0)
			return;
		bwOn = on;
		refreshFilters();
	}

	// ------------------------------------------------------------------ loop

	public function update(elapsed:Float)
	{
		time += elapsed;

		// eventos do chart
		while (evIndex < events.length && Conductor.songPosition >= events[evIndex].time)
		{
			runEvent(events[evIndex]);
			evIndex++;
		}

		// tempo dos shaders
		if (quality > 0)
		{
			if (compOn)
			{
				compression.data.iTime.value = [time];
				compression.data.glitchAmount.value = [compAmount];
			}
			if (dadGlitchOn)
			{
				dadGlitch.data.time.value = [time];
				dadGlitch.data.prob.value = [dadProb];
			}
			if (schoolGlitchOn && quality >= 2)
			{
				glitchShader.data.time.value = [time];
				glitchShader.data.prob.value = [schoolProb];
			}
			if (boardFilterOn && boardShader != null)
				boardShader.data.iTime.value = [time];
		}

		// erros do minigame
		for (i in 0...3)
			if (wrongAnswers > i)
				xMarks[i].alpha = 1;
		if (wrongAnswers >= 4 && !gameOverTriggered)
		{
			gameOverTriggered = true;
			PlayState.health = 0;
		}

		iconBF.animation.play(PlayState.health < 0.5 ? 'defeat' : 'idle');

		if (mathTime)
			updateMathInput();
		updateMathText();
	}

	/** chamado pelo PlayState depois de ele posicionar a camera: o stage fixa a camera e so a "empurra" nos sing-anims **/
	public function postUpdate(elapsed:Float)
	{
		var dx:Float = 0;
		var dy:Float = 0;
		var anim = PlayState.dadOpponent.animation.curAnim;
		var ang:Float = 0;
		if (anim != null)
		{
			var n = anim.name;
			if (n.startsWith('singLEFT'))
			{
				dx = -20;
				ang = -2;
			}
			else if (n.startsWith('singRIGHT'))
			{
				dx = 20;
				ang = 2;
			}
			else if (n.startsWith('singUP'))
				dy = -20;
			else if (n.startsWith('singDOWN'))
				dy = 20;
		}
		ps.camFollow.setPosition(CAM_X + dx, CAM_Y + dy);
		PlayState.forceZoom[2] = sideToSide ? ang : 0;
	}

	/** o oponente acertou uma nota: no modo "evil" drena a vida **/
	public function onDadHit()
	{
		if (!evil)
			return;
		if (PlayState.health > 0.22)
			PlayState.health -= 0.02;
	}

	// ------------------------------------------------------------------ eventos do chart

	function runEvent(e:Dynamic)
	{
		var p:Array<Dynamic> = e.params;
		switch (e.name)
		{
			case 'HScript Call':
				call(Std.string(p[0]));
			case 'Camera Flash':
				var secs = Std.parseFloat(Std.string(p[2])) * Conductor.stepCrochet / 1000;
				FlxG.camera.flash(FlxColor.fromInt(Std.int(p[1])), secs);
			case 'Add Camera Zoom':
				FlxG.camera.zoom += Std.parseFloat(Std.string(p[0]));
			default: // 'Camera Movement': a camera e fixa neste stage
		}
	}

	function call(fn:String)
	{
		switch (fn)
		{
			case 'startCutscene':
				door.animation.play('open');
			case 'midCutscene':
				midCutscene();
			case 'reveal':
				FlxTween.tween(fadeGame, {alpha: 0}, 1.35, {ease: FlxEase.cubeIn});
			case 'math':
				math();
			case 'bgTransition':
				bgTransition();
			case 'veryCoolSuperTransition':
				FlxTween.tween(FlxG.camera, {zoom: 1.2}, 4.1, {
					ease: FlxEase.cubeIn,
					onComplete: function(_)
					{
						PlayState.defaultCamZoom = 1.2;
						fadeGame.alpha = 1;
					}
				});
			case 'glitch':
				glitchTransition();
			case 'meatBG':
				meatBG();
		}
	}

	function midCutscene()
	{
		FlxTween.tween(fadeIn, {alpha: 1}, 2, {ease: FlxEase.cubeIn});
		FlxTween.tween(camDoor, {zoom: 1.4}, 2, {
			ease: FlxEase.cubeIn,
			onComplete: function(_)
			{
				camDoor.alpha = 0;
				bg.cameras = [PlayState.camGame];
				bg.x = -640;
				bg.y = -250;
			}
		});
	}

	function bgTransition()
	{
		bg.animation.play('transition');
		FlxTween.tween(FlxG.camera, {zoom: 1.2}, 2, {
			ease: FlxEase.cubeIn,
			onComplete: function(_)
			{
				PlayState.defaultCamZoom = 1;
				FlxG.camera.flash(FlxColor.WHITE, 1);
				bg.animation.play('dark');
				blackboard.color = 0x615a5a;
				mathTxt.color = 0x615a5a;
				if (quality >= 2 && camBoard != null && boardShader != null)
				{
					boardShader.data.glitchAmount.value = [0.25];
					camBoard.setFilters([new ShaderFilter(boardShader)]);
					boardFilterOn = true;
				}
			}
		});
	}

	function glitchTransition()
	{
		hud.animation.play('evil');
		if (quality > 0)
		{
			compOn = true;
			compAmount = 0;
			refreshFilters();
		}
		FlxTween.num(0, 3.25, 1.25, {
			onComplete: function(_)
			{
				compOn = false;
				refreshFilters();
				blackboard.color = 0xffffff;
				mathTxt.color = 0xffffff;
				if (boardShader != null)
					boardShader.data.glitchAmount.value = [0.32];
			}
		}, function(v:Float)
		{
			compAmount = v;
		});
	}

	function meatBG()
	{
		evil = true;
		blackboard.animation.play('evil');
		blackboard.y += downscroll ? 45 : -35;
		blackboard.x -= 50;
		mathTxt.color = 0xDF2D2D;
		fadeGame.alpha = 0;
		PlayState.defaultCamZoom = 0.9;
		bg.visible = false;
		bgMeat.visible = true;
	}

	function endSequence()
	{
		FlxG.camera.shake(0.009, 2.75);
		if (quality > 0)
		{
			compOn = true;
			compAmount = 0;
			refreshFilters();
		}
		FlxTween.num(0, 3, 2.75, {
			onComplete: function(_)
			{
				fadeGame.alpha = 1;
			}
		}, function(v:Float)
		{
			compAmount = v;
		});
		FlxTween.tween(FlxG.camera, {zoom: 0.85}, 2.75, {ease: FlxEase.quadInOut});
	}

	// ------------------------------------------------------------------ steps / beats

	public function stepHit(curStep:Int)
	{
		// troca de personagem: as notas continuam indo para o personagem "cantor" (o trans so toca a animacao dele)
		if (curStep == 1272)
		{
			chars[0].visible = false;
			chars[1].visible = true;
			chars[1].playAnim('trans', true);
		}
		if (curStep == 1280)
		{
			chars[1].visible = false;
			chars[2].visible = true;
			setSinger(2);
		}
		if (curStep == 1952)
		{
			chars[2].visible = false;
			chars[3].visible = true;
			setSinger(3);
		}
	}

	function setSinger(i:Int)
	{
		PlayState.dadOpponent = chars[i];
		PlayState.strumLines.members[0].character = chars[i];
	}

	function zoomTween(from:Float, to:Float, dur:Float)
	{
		FlxTween.num(from, to, dur, {ease: FlxEase.quadInOut}, function(v:Float)
		{
			FlxG.camera.zoom = PlayState.defaultCamZoom = v;
		});
	}

	public function beatHit(curBeat:Int)
	{
		if (!Init.trueSettings.get('Reduced Movements') && FlxG.camera.zoom < 1.35 && curBeat % camZoomInterval == 0)
			FlxG.camera.zoom += 0.015 * camZoomAmount;

		var z = function(v:Float) PlayState.defaultCamZoom = v;
		var flash = function(c:Int, s:Float) FlxG.camera.flash(c, s);

		switch (curBeat)
		{
			case 28:
				showStrums();
			case 30:
				z(1.2);
			case 32:
				flash(0xffffff, 1);
				z(1.0);
			case 94:
				z(1.2);
			case 96:
				flash(0xffffff, 1);
				z(1.0);
			case 158:
				z(1.2);
			case 160:
				bg.color = 0xb6a1a0a0;
				chars[0].color = 0xb6d3d0d0;
				flash(0xffffff, 1);
				z(1.0);
			case 192:
				bg.color = 0xffffff;
				chars[0].color = 0xffffff;
				flash(0xffffff, 1);
				z(1.1);
			case 288:
				z(1.0);
			case 382:
				FlxG.camera.zoom = PlayState.defaultCamZoom = 1.1;
			case 383:
				FlxG.camera.zoom = PlayState.defaultCamZoom = 1.3;
			case 384:
				flash(0xffffff, 1);
				FlxG.camera.zoom = PlayState.defaultCamZoom = 1.0;
				camZoomAmount = 2;
			case 464:
				camZoomAmount = 0;
			case 559:
				camZoomAmount = 2;
			case 560:
				flash(0xda0b0b, 0.65);
				zoomTween(1.0, 0.8, 0.45);
			case 623:
				FlxTween.tween(FlxG.camera, {zoom: 1.0}, 0.45, {ease: FlxEase.quadInOut, onComplete: function(_) z(0.8)});
			case 624:
				if (quality >= 2)
				{
					schoolGlitchOn = true;
					refreshFilters();
				}
				flash(0xda0b0b, 0.65);
			case 686:
				camZoomAmount = 0;
			case 687:
				FlxTween.tween(FlxG.camera, {zoom: 1.0}, 0.45, {ease: FlxEase.quadInOut, onComplete: function(_) z(1.0)});
			case 688:
				FlxG.camera.shake(0.009, 0.2);
				sideToSide = true;
				FlxG.camera.zoom = PlayState.defaultCamZoom = 1.0;
			case 690:
				glitchBurst(0.64, 0);
			case 698 | 702 | 769 | 777:
				glitchBurst(0.064, 0);
			case 723:
				setBW(true);
				z(1.3);
				FlxG.camera.shake(0.02, 0.4);
			case 724:
				setBW(false);
				z(1);
			case 736:
				setBW(true);
				z(1.3);
				FlxG.camera.shake(0.02, 1.5);
			case 740:
				setBW(false);
				z(1);
			case 815:
				camZoomAmount = 2;
			case 816:
				flash(0xda0b0b, 0.65);
				glitchBurst(0.064, 0.05);
				schoolProb = 0.05;
				ps.insert(ps.members.indexOf(chars[3]), trail);
				zoomTween(1.0, 0.8, 0.45);
			case 898 | 953 | 956 | 972:
				glitchBurst(0.064, 0.05);
			case 944:
				z(0.9);
				camZoomInterval = 2;
			case 976:
				camZoomAmount = 0;
				trail.destroy();
				endSequence();
		}
	}

	function showStrums()
	{
		if (strumsShown)
			return;
		strumsShown = true;
		for (sl in PlayState.strumLines)
		{
			var i = 0;
			for (r in sl.receptors)
			{
				r.alpha = 0.001;
				r.visible = true;
				FlxTween.tween(r, {alpha: 1}, 0.5, {ease: FlxEase.linear, startDelay: i * 0.333});
				i++;
			}
		}
	}

	// ------------------------------------------------------------------ minigame de matematica

	function math()
	{
		if (!mathEnabled)
			return;
		answer = '_';
		answer2 = '_';
		slot = 0;
		locked = false;
		question = QUESTIONS[FlxG.random.int(0, QUESTIONS.length - 1)];
		var target = blackboard.y + (downscroll ? -620 : 620);
		FlxTween.tween(blackboard, {y: target}, 1, {
			ease: FlxEase.backInOut,
			onComplete: function(_)
			{
				FlxTween.tween(mathTxt, {alpha: 1}, 0.25, {ease: FlxEase.quadInOut});
				startQuestion();
			}
		});
	}

	function startQuestion()
	{
		mathTime = true;
		ps.canPause = false;
		FlxG.autoPause = false;
		new FlxTimer().start(5, function(_)
		{
			mathTime = false;
			var correct = (question[0] == 4) ? (answer + answer2 == question[3]) : (answer == question[3]);
			if (correct)
				FlxG.sound.play(Paths.sound(evil ? 'educator/yeahevil' : 'educator/yeah'), evil ? 1 : 0.65);
			else
				wrongAnswers++;
			FlxTween.tween(mathTxt, {alpha: 0}, 0.5, {
				ease: FlxEase.quadInOut,
				onComplete: function(_)
				{
					FlxTween.tween(blackboard, {y: blackboard.y + (downscroll ? 620 : -620)}, 0.5, {
						ease: FlxEase.backIn,
						onComplete: function(_)
						{
							ps.canPause = true;
							FlxG.autoPause = true;
						}
					});
				}
			});
		});
	}

	static var DIGITS:Array<Array<FlxKey>> = [
		[FlxKey.ZERO, FlxKey.NUMPADZERO], [FlxKey.ONE, FlxKey.NUMPADONE], [FlxKey.TWO, FlxKey.NUMPADTWO], [FlxKey.THREE, FlxKey.NUMPADTHREE],
		[FlxKey.FOUR, FlxKey.NUMPADFOUR], [FlxKey.FIVE, FlxKey.NUMPADFIVE], [FlxKey.SIX, FlxKey.NUMPADSIX], [FlxKey.SEVEN, FlxKey.NUMPADSEVEN],
		[FlxKey.EIGHT, FlxKey.NUMPADEIGHT], [FlxKey.NINE, FlxKey.NUMPADNINE]
	];

	function updateMathInput()
	{
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			answer = '_';
			answer2 = '_';
			slot = 0;
			locked = false;
			return;
		}
		if (locked)
			return;
		for (d in 0...10)
		{
			if (FlxG.keys.anyJustPressed(DIGITS[d]))
			{
				if (slot == 0)
					answer = Std.string(d);
				else
					answer2 = Std.string(d);
				if (question[0] == 4 && slot == 0)
					slot = 1;
				else
					locked = true;
				break;
			}
		}
	}

	function updateMathText()
	{
		if (question == null)
			return;
		var t1:String = question[1];
		var t2:String = question[2];
		switch (question[0])
		{
			case 1:
				mathTxt.text = t1 + answer;
			case 2:
				mathTxt.text = answer + t1;
			case 3:
				mathTxt.text = t1 + answer + t2;
			case 4:
				mathTxt.text = t1 + answer + answer2;
		}
	}

	public function destroy()
	{
		FlxG.autoPause = true;
		PlayState.camGame.setFilters([]);
	}
}
