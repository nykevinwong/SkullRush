package ;
import enet.ENet;
import flash.utils.Timer;
import flixel.addons.effects.FlxTrail;
import flixel.addons.weapon.FlxBullet;
import flixel.addons.weapon.FlxWeapon;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxPoint;
import flixel.util.FlxRect;
import flixel.util.FlxTimer;
import flixel.util.FlxVelocity;
import haxe.Serializer;
import haxe.Unserializer;
import networkobj.NWeapon;
import ext.FlxWeaponExt;
import ext.FlxTrailExt;
import ext.FlxTextExt;

/**
 * ...
 * @author Ohmnivore
 */
class PlayerBase extends FlxSprite
{
	//public static inline var jumpHeight:Int = 190;
	//public static inline var gravity:Int = 400;
	//public static inline var speedX:Int = 400;
	//public static inline var maxSpeedX:Int = 150;
	//public static inline var dragX:Int = 400;
	
	public static inline var jumpHeight:Int = 380;
	public static inline var gravity:Int = 800;
	public static inline var speedX:Int = 800;
	public static inline var maxSpeedX:Int = 200;
	public static inline var dragX:Int = 800;
	
	public var graphicKey:String;
	public var name:String;
	public var team:Int;
	
	public var a:Float;
	public var isRight:Bool;
	public var move_right:Bool;
	public var move_left:Bool;
	public var move_jump:Bool;
	public var shoot:Bool;
	public var ceilingwalk:Bool;
	public var dash_left:Bool;
	public var dash_right:Bool;
	public var dash_down:Bool;
	public var current_weap:Int;
	
	private var weap_change_timer:FlxTimer;
	private var canChange:Bool = true;
	public var grantedWeps:Map<Int, Bool>;
	
	private var _arr:Array<Dynamic>;
	public var cannon:FlxWeaponExt;
	private var trail:FlxTrailExt;
	
	private var gun:FlxSprite;
	public var guns:FlxGroup;
	public var guns_arr:Array<FlxWeaponExt>;
	private var gun_offset:FlxPoint;
	
	private var healthBar:FlxBar;
	public var header:FlxTextExt;
	
	private var last_shot:FlxWeaponExt;
	
	public function new(Id:Int, Name:String, X:Int, Y:Int)
	{
		super(X, Y);
		ID = Id;
		a = 1;
		isRight = true;
		move_right = false;
		move_left = false;
		move_jump = false;
		shoot = false;
		ceilingwalk = false;
		current_weap = -1;
		_arr = [];
		grantedWeps = new Map<Int, Bool>();
		grantedWeps.set(1, true);
		
		weap_change_timer = new FlxTimer(0.3, setChange);
		
		graphicKey = "assets/images/playerblue.png";
		loadGraphic(Assets.getImg("assets/images/playerblue.png"), true, 24, 24);
		loadAnims();
		
		#if CLIENT
		gun = new FlxSprite(0, 0, Assets.getImg("assets/images/gun.png"));
		gun.loadGraphic(Assets.getImg("assets/images/gun.png"));
		Reg.state.over_players.add(gun);
		guns_arr = [];
		guns = new FlxGroup();
		Reg.state.over_players.add(guns);
		NWeapon.setUpWeapons(this);
		#else
		guns_arr = [];
		guns = new FlxGroup();
		Reg.state.over_players.add(guns);
		NWeapon.setUpWeapons(this);
		#end
		gun_offset = new FlxPoint();
		
		health = 100;
		healthBar = new FlxBar(8, 26, FlxBar.FILL_LEFT_TO_RIGHT, 38, 6, this, "health", 0, 100, true);
		healthBar.trackParent(-6, -7);
		healthBar.createFilledBar(0xFFFF0000, 0xFF09FF00, true, 0xff000000);
		Reg.state.over_players.add(healthBar);
		
		name = Name;
		team = 0;
		//teamcolor = 0xff00A8C2;
		
		header = new FlxTextExt(0, 0, 200, name, 8, false);
		//header.setBorderStyle(FlxText.BORDER_OUTLINE, 0xff000000);
		Reg.state.over_players.add(header);
		header.color = 0xff00A8C2;
		
		drag.x = PlayerBase.dragX;
		maxVelocity.x = PlayerBase.maxSpeedX;
		maxVelocity.y = 500;
		
		cannon = new FlxWeaponExt("launcher", this, FlxBullet, 0);
		cannon.makePixelBullet(4, 4, 4, FlxColor.CYAN);
		cannon.setBulletSpeed(255);
		var bounds:FlxRect = Reg.state.collidemap.getBounds();
		bounds.x -= FlxG.width / 2;
		bounds.width += FlxG.width;
		bounds.y -= FlxG.height / 2;
		bounds.height += FlxG.height;
		cannon.setBulletBounds(bounds);
		cannon.setFireRate(1200);
		cannon.setBulletOffset(12, 12);
		cannon.setBulletInheritance(0.5, 0.5);
		
		trail = new FlxTrailExt(this, Assets.getImg("assets/images/trail.png"), 7, 2, 0.4, 0.08);
		trail.setTrailOffset(4, 4);
		
		Reg.state.under_players.add(trail);
		Reg.state.bullets.add(cannon.group);
		Reg.state.players.add(this);
		
		last_shot = cannon;
	}
	
	private function setChange(T:FlxTimer):Void
	{
		canChange = true;
	}
	
	override public function draw():Void
	{
		setFollow();
		
		super.draw();
	}
	
	override public function update():Void 
	{
		updateGuns();
		
		updateAnims();
		
		super.update();
	}
	
	override public function destroy():Void 
	{
		//super.destroy();
	}
	
	override public function kill():Void 
	{
		Reg.state.under_players.remove(trail, true);
		Reg.state.bullets.remove(cannon.group, true);
		Reg.state.players.remove(this, true);
		Reg.state.over_players.remove(header, true);
		Reg.state.over_players.remove(healthBar, true);
		Reg.state.over_players.remove(gun, true);
		Reg.state.over_players.remove(guns, true);
		
		gun.kill();
		guns.kill();
		header.kill();
		healthBar.kill();
		cannon.group.kill();
		super.kill();
	}
	
	//public function killForReal():Void 
	//{
		//Reg.state.under_players.remove(trail, true);
		//Reg.state.bullets.remove(cannon.group, true);
		//Reg.state.players.remove(this, true);
		//Reg.state.over_players.remove(header, true);
		//Reg.state.over_players.remove(healthBar, true);
		//Reg.state.over_players.remove(gun, true);
		//
		//gun.kill();
		//header.kill();
		//healthBar.kill();
		//cannon = null;
		//super.kill();
		//
		//super.destroy();
	//}
	
	//public function addToState():Void
	//{
		//Reg.state.under_players.add(trail);
		//Reg.state.bullets.add(cannon.group);
		//Reg.state.players.add(this);
		//Reg.state.over_players.add(header);
		//Reg.state.over_players.add(healthBar);
		//Reg.state.over_players.add(gun);
	//}
	
	public function hide():Void
	{
		visible = false;
		header.visible = false;
		healthBar.visible = false;
		gun.visible = false;
		guns.visible = false;
		trail.visible = false;
	}
	
	public function show():Void
	{
		visible = true;
		header.visible = true;
		healthBar.visible = true;
		gun.visible = true;
		guns.visible = true;
		trail.visible = true;
	}
	
	public function loadAnims():Void
	{
		setFacingFlip(FlxObject.RIGHT, false, false);
		setFacingFlip(FlxObject.LEFT, true, false);
		
		animation.add("walking", [0, 1, 2, 3, 4, 5], 12, true);
		animation.add("i_walking", [5, 4, 3, 2, 1, 0], 12, true);
		animation.add("idle", [0], 12, false);
		
		animation.add("rwalking", [6, 7, 8, 9, 10, 11], 12, true);
		animation.add("ri_walking", [11, 10, 9, 8, 7, 6], 12, true);
		animation.add("ridle", [6], 12, false);
		
		animation.add("ledgeidle", [12], 12, false);
	}
	
	public function setColor(Color:Int, Asset:String):Void
	{
		header.color = Color;
		graphicKey = Asset;
		loadGraphic(Assets.getImg(graphicKey), true, 24, 24);
		this.flipX = true;
		loadAnims();
	}
	
	public function fire():Void
	{
		cannon.fireFromAngle(Std.int(a));
		
		last_shot = cannon;
		
		gun_offset = FlxAngle.rotatePoint(4, 0, 0, 0, a);
		FlxTween.tween(gun_offset, { x: 0, y:0 }, 0.30);
	}
	
	private function updateGuns():Void
	{
		if (health > 0)
		{
			if (isRight)
			{
				gun.angle = a;
				gun.facing = FlxObject.RIGHT;
				gun.flipY = false;
				facing = FlxObject.RIGHT;
			}
			else
			{
				gun.angle = a;
				gun.facing = FlxObject.LEFT;
				gun.flipY = true;
				facing = FlxObject.LEFT;
			}
		}
	}
	
	private function updateAnims():Void
	{
		if (!ceilingwalk)
		{
			//if (isTouching(FlxObject.ANY))
			//{
				//if (facing == FlxObject.RIGHT && move_right) { animation.play("walking"); }
				//if (facing == FlxObject.LEFT && move_left) { animation.play("walking"); }
				//if (facing == FlxObject.RIGHT && move_left) { animation.play("i_walking"); }
				//if (facing == FlxObject.LEFT && move_right) { animation.play("i_walking"); }
				//else if (!move_left && !move_right) { animation.play("idle"); }
			//}
			//
			//else
			//{
				//animation.play("idle");
			//}
			if (isTouching(FlxObject.ANY))
			{
				if (facing == FlxObject.RIGHT && velocity.x > 0) { animation.play("walking"); }
				if (facing == FlxObject.LEFT && velocity.x < 0) { animation.play("walking"); }
				if (facing == FlxObject.RIGHT && velocity.x < 0) { animation.play("i_walking"); }
				if (facing == FlxObject.LEFT && velocity.x > 0) { animation.play("i_walking"); }
				else if (velocity.x == 0) { animation.play("idle"); }
			}
			
			else
			{
				animation.play("idle");
			}
		}
		
		else
		{
			if (isTouching(FlxObject.ANY))
			{
				if (facing == FlxObject.RIGHT && velocity.x > 0) { animation.play("rwalking"); }
				if (facing == FlxObject.LEFT && velocity.x < 0) { animation.play("rwalking"); }
				if (facing == FlxObject.RIGHT && velocity.x < 0) { animation.play("ri_walking"); }
				if (facing == FlxObject.LEFT && velocity.x > 0) { animation.play("ri_walking"); }
				else if (velocity.x == 0) { animation.play("ridle"); }
			}
			
			else
			{
				animation.play("ridle");
			}
		}
	}
	
	private function setFollow():Void
	{
		header.y = y - header.height - 4;
		header.x = x - (header.width - width) / 2;
		
		gun.x = (x + width/2 - gun.width / 2) * 0.53 + gun.x * 0.47 - gun_offset.x;
		gun.y = (y + height/2 - gun.height / 2 + 2) * 0.53 + gun.y * 0.47 - gun_offset.y;
	}
	
	public function setGun(GunID:Int, Force:Bool = false):Void
	{
		if (Std.is(GunID, Int))
		{
			if (grantedWeps.exists(GunID))
			{
				if (grantedWeps.get(GunID) == true)
				{
					var g:FlxWeaponExt = guns_arr[GunID - 1];
					if (g != null)
					{
						if (Force || canChange)
						{
							if (gun != null)
								gun.visible = false;
							g.gun.visible = true;
							gun = g.gun;
							cannon = g;
							
							current_weap = GunID;
							
							//weap_change_timer.reset(0.3);
							//weap_change_timer = new FlxTimer(0.3);
							canChange = false;
							weap_change_timer.reset(0.3);
							
						}
					}
				}
			}
		}
	}
	
	public function s_serialize():String
	{
		_arr.splice(0, _arr.length);
		
		_arr.push(ID);
		_arr.push(x);
		_arr.push(y);
		_arr.push(a);
		_arr.push(isRight);
		_arr.push(shoot);
		_arr.push(health);
		
		_arr.push(velocity.x);
		_arr.push(velocity.y);
		
		_arr.push(dash_left);
		_arr.push(dash_right);
		_arr.push(current_weap);
		
		_arr.push(cannon.nextFire - FlxG.game.ticks);
		_arr.push(last_shot.template.slot - 1);
		
		return Serializer.run(_arr);
	}
	
	public function lerp(v0:Float, v1:Float, t:Float):Float
	{
		return (1 - t) * v0 + t * v1;
	}
	
	public function c_unserialize(Arr:Array<Dynamic>):Void
	{
		
	}
	
	public function c_serialize():String
	{
		return "";
	}
	
	public function s_unserialize(S:String):Void
	{
		
	}
}