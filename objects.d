
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

class monster_t : unit_t
	{
	this(float _x, float _y, float  _vx, float _vy)
		{
		super(2, _x, _y, _vx, _vy, g.goblin_bmp);
		}

	override void on_tick()
		{
		super.on_tick();
		x += vx;
		y += vy;

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
	
	bool is_player_controlled=false;
	
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

	override void on_tick()
		{
		}
	}




enum STATE{	WALKING, JUMPING, LANDING

}

class dwarf_t : unit_t
	{
	STATE state = STATE.WALKING;
	int state_delay=0;
		
	this(float _x, float _y, float _xv, float _yv, ALLEGRO_BITMAP* b)
		{
		super(1, _x, _y, _xv, _yv, b);
		}

	override void draw(viewport_t v)
		{
		super.draw(v);
		string text;
		
/*		if(state == STATE.WALKING) text = __traits(identifier, state);
		if(state == STATE.JUMPING) text = __traits(identifier, state);
		if(state == STATE.LANDING) text = __traits(identifier, state);
	*/
		text = to!string(state);
		
			al_draw_text(g.font, 
				ALLEGRO_COLOR(0, 0, 0, 1), 
				x, 
				y, 
				ALLEGRO_ALIGN_CENTER, 
				text.toStringz());
		

		}

			
	override void on_tick()
		{		
//		super.on_tick();
		
		if(state == STATE.WALKING)
			{
			x += vx;
			y += vy;
			}
			
		if(state == STATE.JUMPING)
			{
			x += vx*2;
			y += vy*2;
			state_delay++;
			if(state_delay == 60) 
				{
				state_delay = 0;
				state = STATE.LANDING;
				writeln("switching to STATE.LANDING");
				}
			}
			
		if(state == STATE.LANDING)
			{
			state_delay++;
			if(state_delay == 30) 
				{
				state_delay = 0;
				state = STATE.WALKING;
				writeln("switching to STATE.WALKING");
				}
			}
			
		}

	override void up(){ vx = 0; vy = -1;}
	override void down() { vx = 0; vy = 1;}
	override void left() { vx = -1; vy = 0;}
	override void right() { vx = 1; vy = 0;}

		
	override void action_attack()
		{
		}
	override void action_jump()
		{
		if(state == STATE.WALKING)
			{
			state = STATE.JUMPING;
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
	override void on_tick()
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
		
	override void on_tick()
		{
		super.on_tick(); // check if we're alive

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
		
	override void on_tick()
		{
		super.on_tick(); // check if we're alive

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
	void on_tick()
		{
		}

	void on_collision(object_t other_obj)
		{
		}	
	}	
