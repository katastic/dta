


enum STATE{	WALKING, JUMPING, LANDING, ATTACKING}

/*

the problem with horses
	while we can have NPC horses. if we give players horses then now there's two game modes. 
		- Fast running on a horse and you have to jump off to fight. [travel horses now its just a hassle]
		- Can fight while on horse in which case you'll never NOT use horses again [always horses makes non-horses a permenant early game transition]

TODO - 
	add diagonal detection
	also decide whether diagonal should be proper sqrt(2) or classic wrong faster.

dudes
	- animation handler, script files.
	- more FSM stuff
	- are items separate from sprites? Then we'll need an anchor point for each sprite cell
		for the sword location and (if applicable) rotation angle
	
map
	- tileset/texture atlas parser
	- map editor

particles
	- sword attack


player finite state machine! DRAW THIS THING.

	walking - free movement
	jumping - in air jumping
		- Can jumping be interrupted???
	
	landing - delay after hitting ground 'blade landing'
	
	stunned - can't move. (also can't be hurt?)
			<-- I think in Secret of Mana, you get hit for a moment, immortal. But then you are still immortal for another second or two while walking/attacking.
				- so the key here is INVULERABILITY_TIMER gets set upon being STUNNED (edge trigger) but keeps ticking down after STUN_TIMER runs out. So 
				invulnerability is not tied to state transitions out.
	attacking?
		- "windup animation for attack"  Animation: yes. Otherwise ??? (ala can it be canceled)

	casting?
		- in secret of mana casting has a windup animation but also you can't be hit but... hits attacks can be queued up on you
			ANIMATION: yes. Whether it controls immortality or anything is a ???.
		- more or less just attack 
	
	parry?
		- can we parry? (I think in SoM if both attacks hit at same time they don't subtract stamina and both get attackers attacks get reset)
		- parry could be a very short stun duration with no invulnerability
		
	dodge/roll? [more or less a jump with different animation?]
		-
		-



JUMPING -> LANDING -> WALKING -> JUMPING



*/

interface animState
	{
	void enter();
	void trigger();
	void exit();
	}

class attackingState : animState
	{
	void enter(){}
	void trigger(){}
	void exit(){}
	}



import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.conv;
import std.random;
import std.stdio;

import std.string;

import g;
import helper;
import viewport;
import map;

class item : drawable_object_t
	{
	bool isInside = false; //or isHidden? Not always the same though...
	int team;
	
	this(uint _team, float _x, float _y, float _vx, float _vy, ALLEGRO_BITMAP* b)
		{
		x = _x;
		y = _y;
		vx = _vx;
		vy = _vy;
		
		writeln("ITEM EXISTS BTW at ", x, " ", y);
		super(b);
		}
		
	override void draw(viewport_t v)
		{
		if(!isInside)
			{
			super.draw(v);
			}
		}
		
	override void onTick()
		{
		if(!isInside)
			{
			x += vx;
			y += vy;
			vx *= .99; 
			vy *= .99; 
			}
		}
	}

class treasure_chest : drawable_object_t
	{
	int team;
	bool isOpen = false;
	bool isOpening = false; // so you can't open it while opening it.
	int state_delay = 0;
	item[] itemsInside;

	//fixme
	this(uint _team, float _x, float _y, float _xv, float _yv)
		{
		writeln("i'm existing.");
		super(g.chest_bmp);
		team = _team; 
		x = _x; 
		y = _y;
		vx = _xv;
		vy = _yv;
		}
		
	void onHit(unit_t by)
		{
		isOpening = true;
		writeln("[Treasure Chest] OPENING");
		state_delay = 60;		
		}
	
	override void onTick()
		{		
		import std.math;
		if(isOpening)
			{
			state_delay--;
			if(state_delay == 0)
				{
				isOpen = true;
				isOpening = false;
				
				writeln("OPENED");
				bmp = g.chest_open_bmp;
				foreach(i; itemsInside)
					{
					writeln("item pop");
					i.isInside = false;
					i.x = x;
					i.y = y;
					
					float vel = 1.0f;
					float angle = uniform!"[]"(0, 2*PI);
					
					i.vx = cos(angle)*vel;
					i.vy = sin(angle)*vel;
					}
				itemsInside = [];
				}
			}
		}

	void onUse(unit_t user)
		{
		if(isOpen == false)
			{
			state_delay = 60;
			isOpening = true;
			}
		}
	}

class monster_t : unit_t
	{
	this(float _x, float _y, float  _vx, float _vy)
		{
		super(2, _x, _y, _vx, _vy, g.goblin_bmp);
		}

	bool isBeingHit=false;

	void onHit(unit_t by, float damage)
		{
		import std.math;
		isBeingHit=true;

		float angle = atan2(by.y - y, by.x - x);
		float vel = 2.0f;
		
		vx = -cos(angle)*vel;
		vy = -sin(angle)*vel;
		writeln(angle, ",", vel, ",", vx, ",", vy);
		hp -= damage;
		}

	override void onTick()
		{
		if(!isBeingHit && percent(1) )
			{			
			import std.math;
			float angle = atan2(g.world.units[0].y - y, g.world.units[0].x - x);
			float vel = 1.0f;
						
			vx = cos(angle)*vel;
			vy = sin(angle)*vel;
			}
			
		import std.math;
		super.onTick();

		attemptMoveRel(vx, vy);

		if(isBeingHit)
			{
			vx *= .99;
			vy *= .99;
			if(abs(vx) < .2 && abs(vy) < .2)
				{vx = 0; vy = 0; isBeingHit = false;}  
			}

		if(x < 0 || y < 0)delete_me = true;
		if(x > (world.map.w-1)*32)delete_me = true;
		if(y > (world.map.h-1)*32)delete_me = true;
		
		int i = cast(int) x/32;
		int j = cast(int) y/32;

		if(world.map.data[i][j] == 3) //if water, take damage
			{
			hp -= 5;
			}

		}
	}

class unit_t : drawable_object_t 
	{
	immutable float maxHP=100.0; /// Maximum health points
	float hp=maxHP; /// Current health points
	float ap=0; /// armor points (reduced on hits then armor breaks)
	float armor=0; /// flat reduction (or percentage) on damages, haven't decided.
	float weapon_damage=50; 
	bool has_weapon=false;
	bool is_attacking=false;
	bool is_running=false;
	uint team=0;
	
	void attemptMoveRel(float dx, float dy)
		{
		float cx = x + dx;
		float cy = y + dy;
		if(cx > 0 && cy > 0 && cx < 50*32 && cy < 50*32)
			{
			tile t = g.world.map.data[cast(int)cx/32][cast(int)cy/32];
			if(t == 0 || t == 3 || t == 4 || t == 5)
				{
				x = cx;
				y = cy;
				}
//			writeln(t);
			}
		}

	
	
	
	
	bool is_player_controlled=false;
	
	void action_use(){}
	
	void search_and_attack_nearby_enemy() /// first one we find. ALSO STRUCTURES!
		{
		is_attacking = false;
		foreach(u; world.units)  // le oof algorithm complexity
			{
			assert(u.team != 0);
			if(u.team != team)
				{
				if( to!int(u.x/32) == to!int(x/32) && (to!int(u.y/32) == to!int(y/32)) )
					{
					attack(u);
					is_attacking=true;
					break;
					}
				}
			}
			
		// <-- At this point, if we've failed to find any valid units, we search structures
			
		// Optimization-wise, it'd be nice of we only scanned structures first so we can bail out
		// early. (does that make sense? it's late) but we need to gameplay wise, attack PEOPLE on 
		// a tile before we bother with structures otherwise a structure cannot defend itself! 
		// (at least not on the tile its on)
		
		foreach(s; world.structures)
			{
			assert(s.team != 0);
			if(team != s.team)
			if(to!int(s.x/32) == to!int(x/32) && (to!int(s.y/32) == to!int(y/32)))
				{
				attack_structure(s);
				is_attacking=true;
				break;
				}
			}
		}
	
	void attack_structure(structure_t s)
		{
		s.on_attack(this, weapon_damage);
		}

	void attack(unit_t u)
		{
		u.on_attack(this, weapon_damage);
		}
		
	void on_attack(unit_t from, float amount) /// I've been attacked!
		{
		hp -= amount;
		}

	this(uint _team, float _x, float _y, float _xv, float _yv, ALLEGRO_BITMAP* b)
		{
		super(b);
		team = _team; 
		x = _x; 
		y = _y;
		vx = _xv;
		vy = _yv;
		}

	override void draw(viewport_t v)
		{
		al_draw_tinted_bitmap(bmp,
			ALLEGRO_COLOR(1.0, 0.5, 0.5, 1.0),
			x - v.ox + v.x - bmp.w/2, 
			y - v.oy + v.y - bmp.h/2, 
			0);			
		
		draw_hp_bar(x, y, v, hp, 100);		
		}

	override void onTick()
		{
		}
	}

class dwarf_t : unit_t
	{
	STATE state = STATE.WALKING;
	int state_delay=0;
	item[] myInventory;
	bool hasSword = false;
	int direction=0;

	this(float _x, float _y, float _xv, float _yv, ALLEGRO_BITMAP* b)
		{
		super(1, _x, _y, _xv, _yv, b);
		}

	override void draw(viewport_t v)
		{
		super.draw(v);
		string text;

		text = to!string(state);
		
		al_draw_text(g.font, 
			ALLEGRO_COLOR(0, 0, 0, 1), 
			x, 
			y, 
			ALLEGRO_ALIGN_CENTER, 
			text.toStringz());
		}
	
	int use_cooldown = 0;

	override void action_use() //does this need some sort of delay / anim delay / cooldown
		{
		if(use_cooldown == 0)
			{
			use_cooldown = 20;
			}else{
			writeln("use [cooldown] not ready!");
			return;
			}
		
		foreach(i; g.world.chests)
			{
			if(i.x < x + 16 && i.x > x - 16)
			if(i.x < x + 16 && i.x > x - 16)
			if(i.y < y + 16 && i.y > y - 16)
				{
				writeln("I'm opening a chest");
				i.onHit(this);
				return; 
				}
			}

		foreach(i; g.world.items)
			{
			if(i.isInside == false)
				if(i.x < x + 16 && i.x > x - 16)
				if(i.x < x + 16 && i.x > x - 16)
				if(i.y < y + 16 && i.y > y - 16)
					{
					writeln("I'm picking up an item");
					pickUp(i);
					return;
					//break; // lets only pick up one item at a time if it's for a USE key. [if it's "walk over" we'll pick up all of them--assuming we have room)
					// eventually: Clause for 'inventory too full'
					}
			}
			
		}

	override void onTick()
		{		
		if(use_cooldown > 0)use_cooldown--;
//		super.onTick();
		switch(state)
			{
			case STATE.WALKING:
//			x += vx;
//			y += vy;
			break;
			
			case STATE.JUMPING:
			x += vx;
			y += vy;
			state_delay++;
			if(state_delay == 35) 
				{
				state_delay = 0;
				state = STATE.LANDING;
				writeln("switching to STATE.LANDING");
				}
			break;
			
			case STATE.LANDING: 	// Note: Our current jump is VELOCITY not DISTANCE based. Faster = further. Not faster to get same distance.
			state_delay++;
			if(state_delay == 20) 
				{
				state_delay = 0;
				state = STATE.WALKING;
				writeln("switching to STATE.WALKING");
				}
			break;
			case STATE.ATTACKING:
			state_delay++;
			if(state_delay == 20)
				{
				state_delay = 0;
				// DO ATTACK ON SPOT
				
				state = STATE.WALKING;
				writeln("switching to STATE.WALKING");
				
				
				if(hasSword)
					{
					writeln("ATTACKED with sword.");
					}else{
					writeln("NO sword.");
					return;
					}
				
				foreach(i; g.world.monsters)
					{
					if(i.x < x + 16 && i.x > x - 16)
					if(i.x < x + 16 && i.x > x - 16)
					if(i.y < y + 16 && i.y > y - 16)
						{
						writeln("I hit someone");
						i.onHit(this, 10);
						return; 
						}
					}
				}
			break;		
			
			default:
			assert(0, "invalid state!"); 
			break;
			}
			
		}
		
	immutable float RUN_SPEED = 2.0f; 
	immutable float JUMP_SPEED = 4.0f; 

	override void up(){ if(state == STATE.WALKING){ direction=0; attemptMoveRel(0, -RUN_SPEED); bmp = g.dude_up_bmp;}}
	override void down() { if(state == STATE.WALKING){ direction=1; attemptMoveRel(0, RUN_SPEED); bmp = g.dude_down_bmp;}}
	override void left() { if(state == STATE.WALKING){ direction=2; attemptMoveRel(-RUN_SPEED,0); bmp = g.dude_left_bmp;}}
	override void right() { if(state == STATE.WALKING){ direction=3; attemptMoveRel(RUN_SPEED,0); bmp = g.dude_right_bmp;}}

	void pickUp(ref item i)
		{
		i.isInside = true;
		writeln("I picked ", i ," up. ", i);
		myInventory ~= i;
		if(i.bmp == g.sword_bmp)
			{
			hasSword = true;
			}
		}

	override void action_attack()
		{
		if(state == STATE.WALKING && hasSword)
			{
			state = STATE.ATTACKING;
			writeln("switching to STATE.ATTACKING");
			}
		
		}
	override void action_jump()
		{
		if(state == STATE.WALKING)
			{
			state = STATE.JUMPING;
			if(direction == 0){vx = 0; vy = -JUMP_SPEED;}
			if(direction == 1){vx = 0; vy =  JUMP_SPEED;}
			if(direction == 2){vx = -JUMP_SPEED; vy = 0;}
			if(direction == 3){vx =  JUMP_SPEED; vy = 0;}
			writeln("switching to STATE.JUMPING");
			}
		}
	
	}
	
class drawable_object_t : object_t
	{
	ALLEGRO_BITMAP* bmp;
	
	@disable this(); // SWEET. <-THIS (no relation) means the compiler checks to make
	// sure we call super() from child classes!!!!!
	
	this(ALLEGRO_BITMAP* _bmp) 
		{
		bmp = _bmp;
		}
	
	void draw(viewport_t v)
		{
		al_draw_bitmap(bmp, 
			x - v.ox + v.x - bmp.w/2, 
			y - v.oy + v.y - bmp.h/2, 
			0);
		}
	}	

class structure_t : drawable_object_t
	{
	immutable float maxHP=500.0;
	float hp=maxHP;
	int level=1; //ala upgrade level
	int team=0;
	int direction=0;
	
	this(float x, float y, ALLEGRO_BITMAP* b)
		{
		super(b);
		writeln("we MADE a structure. @ ", x, " ", y);
		g.players[0].money -= 250;
		this.x = x;
		this.y = y;	
		}

	override void draw(viewport_t v)
		{
		super.draw(v);
		draw_hp_bar(x, y, v, hp, maxHP);		
		}

	void on_attack(unit_t u, float weapon_damage)
		{
		hp -= weapon_damage;
		}

	immutable int countdown_rate = 30; // 60 fps, 60 ticks = 1 second
	int countdown = countdown_rate; // I don't like putting variables in the middle of classes but I ALSO don't like throwing 1-function-only variables at the top like the entire class uses them.
	override void onTick()
		{
		if(hp <= 0)delete_me = true;
			
		if(
			world.map.data[cast(int)x/32][cast(int)y/32] == 0 || 
			world.map.data[cast(int)x/32][cast(int)y/32] == 4 ||
			world.map.data[cast(int)x/32][cast(int)y/32] == 5 
			) 
			{
			//
			}else{
			hp -= 5; // this goes at like 60 FPS!
			}
		}
	}

	
class dwarf_structure_t : structure_t
	{
	this(float x, float y)
		{
		super(x, y, g.fountain_bmp);
		team = 1;
		}
		
	override void onTick()
		{
		super.onTick(); // check if we're alive

		// Spawn dudes at rate
		countdown--;
		if(countdown == 0)
			{
			auto d = new dwarf_t(x, y, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5), g.dwarf_bmp);
			world.units ~= d;
			countdown = countdown_rate;
			}			
		}
	}

class monster_structure_t : structure_t
	{
	this(float x, float y)
		{
		super(x, y, g.fountain_bmp);
		team = 2;
		}
		
	override void onTick()
		{
		super.onTick(); // check if we're alive

		// Spawn dudes at rate
		countdown--;
		if(countdown == 0)
			{
			auto d = new monster_t(x, y, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
			world.units ~= d;
			countdown = countdown_rate;
			}			
		}
	}

class object_t
	{
	public:
	bool		delete_me = false;
	
	float 		x, y; 	/// Objects are centered at X/Y (not top-left) so we can easily follow other objects.
	float		vx, vy; /// Velocities.
	float		w, h;   /// width, height (does this make sense in here instead of drawable_object_t)

//	int direction; // see enum
//	float		angle; // instead of x_vel, y_vel?
//	float		vel;
//	int			w2, h2; //cached half width/height

// why would the NON drawable object have a draw call???
//	void draw(viewport_t v)
	//	{
		//}

	// if this gets called implicity through SUPER, AFTER later code changes it, we reset back to defaults!
	// we have to be CAREFUL to make sure the call order for super is DEFINED and respected.
	this()
		{
		x = 0;
		y = 0;
		vx = 0;
		vy = 0;
		}

	this(float _x, float _y, float _vx, float _vy)
		{
		x = _x;
		y = _y;
		vx = _vx;
		vy = _vy;
		}
		
	// INPUTS (do we support mouse input?)
	// ------------------------------------------
	void up(){ y-= 10;}
	void down(){y+= 10;}
	void left(){x-= 10;}
	void right(){x+= 10;}
	void action(){}
	void action_attack()
		{
		}
	void action_jump()
		{
		}
	void action_dodge()
		{
		}
	void click_at(float relative_x, float relative_y){} //maybe? relative to object coordinate.
	
	// EVENTS
	// ------------------------------------------
	void onTick()
		{
		}

	void on_collision(object_t other_obj)
		{
		}	
	}	
