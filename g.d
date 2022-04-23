import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.stdio;
import std.conv;
import std.random;
import std.algorithm : remove;

import helper;
import objects;
import viewport;
import map;

struct blood_t
	{
	int x=0, y=0;
	int lifetime=100;
	int bloodtype=0; // or use bmp
	bool deleteMe=false;
	} 
	// ideally we sort this by bloodtype to reduce contextswitches
	// we could use a pointer to bmp but that would be slower?

class blood_handler_t
	{
	blood_t[] data;

	void add(float x, float y)
		{
		blood_t b = blood_t(cast(int)x, cast(int)y, 100, 0, false);
		data ~= b;
		}
	
	void draw(viewport_t v)
		{
		foreach(b; data)
			{
			assert(g.blood_bmp != null);
			if(b.bloodtype == 0)
				{
				al_draw_bitmap(g.blood_bmp,
					b.x - v.ox + v.x - g.blood_bmp.w/2, 
					b.y - v.oy + v.y - g.blood_bmp.h/2, 
					0);
				}
			}
		}
		
	void onTick()
		{
		foreach(b; data)
			{
			b.lifetime--;
			if(b.lifetime < 0)b.deleteMe = true;
			}
		}
	}


class gui_t
	{
	float x=0, y=0;
	dwarf_t p;
	int flicker_cooldown = 20;
	
	this(ref dwarf_t _p)
		{
		p = _p;
		}
		
	void onTick()
		{
		if(flicker_cooldown)flicker_cooldown--;
		}
		
	void setFlicker()
		{
		flicker_cooldown = 20;
		}
	
	//onTick() {}
	void draw(viewport_t v)
		{
		assert(g.sword_bmp != null);
		if(!p.hasSword)
			{
			float x2 = x - v.ox + v.x - g.sword_bmp.w/2;
			float y2 = y - v.oy + v.y - g.sword_bmp.h/2;
				
			if(flicker_cooldown)
				al_draw_scaled_bitmap(g.sword_bmp,
				   0, 0, g.sword_bmp.w, g.sword_bmp.h,
				   x2 - 10, y2 - 10, g.sword_bmp.w + 20, g.sword_bmp.h + 20, 0);

			al_draw_tinted_bitmap(g.sword_bmp,
				ALLEGRO_COLOR(1.0, 0.5, 0.5, 1.0),
				x - v.ox + v.x - g.sword_bmp.w/2, 
				y - v.oy + v.y - g.sword_bmp.h/2, 
				0);			

		}else{
			al_draw_bitmap(g.sword_bmp,
				x - v.ox + v.x - g.sword_bmp.w/2, 
				y - v.oy + v.y - g.sword_bmp.h/2, 
				0);			
		}
		}
	}

world_t world;
viewport_t [2] viewports;
gui_t[2] guis; //todo: combine into viewports

alias tile=ubyte;
alias dir=direction;

enum direction { down, up, left, right, upleft, upright, downright, downleft} // do we support diagonals. 
// everyone supports at least down. [for signs]
// then UDLR
// then UDLR + diags

class tile_t
	{
	ALLEGRO_BITMAP* bmp;/// sprite
	bool is_passable;	/// blocks passage

	bool is_diggable;	/// self-explainatory
	bool is_liquid;		/// blockable/swimmable/drownable?
	bool is_lava;		/// kills you when touching
	bool is_money;		/// $$$$$$$$$$$$
	int worth;			/// $$$$$$$$$$$$$ when mining
	// fun fact: sentinal value is when money=0 also means is_money=false. 
	// two different ideas/concepts in one variable.
	
	@disable this();	
		//{
	//	assert(false, "dick."); //is there really no language construct for properly 
		// disabling default constructors due to .init bullcrap?
		//}
	
	this(ALLEGRO_BITMAP* _bmp, bool passable, bool diggable, bool liquid, bool lava, bool money, int _worth)
		{
		bmp = _bmp;
		is_passable = passable;
		is_diggable = diggable;
		is_liquid = liquid;
		is_lava = lava;
		is_money = money;
		worth = _worth ;
		}	
	}

struct player_t
	{
	int money=1000; //we might have team based money accounts. doesn't matter yet.
	int deaths=0;
	}

class world_t
	{			
	dwarf_t[] dwarves; //and monsters? and any active objects?
	monster_t[] monsters; 
	object_t[] objects; // other stuff
	unit_t[] units;
	treasure_chest[] chests;
	item[] items;
	structure_t[] structures;
	map_t map;
	tree[] trees;
	blood_handler_t blood;

	this()
		{
		map = new map_t;
		blood = new blood_handler_t;
		units ~= new dwarf_t(120, 120, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5), g.stone_bmp);
		monsters ~= new monster_t(220, 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220, 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220, 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220, 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));	
		monsters ~= new boss_t(420, 320, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));	
	
		structures ~= new monster_structure_t(500, 200);
		
		trees ~= new tree(200, 200, 0, 0, g.tree_bmp);
		trees ~= new tree(232, 200, 0, 0, g.tree_bmp);
		trees ~= new tree(200, 232, 0, 0, g.tree_bmp);
		trees ~= new tree(232, 232, 0, 0, g.tree_bmp);
		trees ~= new tree(264, 200, 0, 0, g.tree_bmp);
		trees ~= new tree(264, 232, 0, 0, g.tree_bmp);
		
		int x = 300;
		int y = 300;
		chests ~= new treasure_chest(0, x, y, 0, 0);
			{
			item i = new item(0,x,y,uniform!"[]"(-.5,.5),uniform!"[]"(-.5,.5), g.sword_bmp);
			chests[0].itemsInside ~= i; 
			items ~= i;
			
			item i2 = new item(0,x,y,uniform!"[]"(-.5,.5),uniform!"[]"(-.5,.5), g.carrot_bmp);
			chests[0].itemsInside ~= i2; 
			items ~= i2;

			item i3 = new item(0,x,y,uniform!"[]"(-.5,.5),uniform!"[]"(-.5,.5), g.potion_bmp);
			chests[0].itemsInside ~= i3; 
			items ~= i3;
			}
		}

	void draw(viewport_t v)
		{
		map.draw(v, false);
		
		void draw(T)(ref T obj)
			{
			foreach(o; obj)
				{
				o.draw(v);
				}
			}
		
		void drawStat(T, U)(ref T obj, ref U stat)
			{
			foreach(o; obj)
				{
				stat++;
				o.draw(v);
				}
			}
		
		drawStat(units, stats.number_of_drawn_objects);
		
/*		foreach(u; units)
			{
			stats.number_of_drawn_objects++;
			u.draw(v);
			}*/
/*		foreach(d; dwarves)
			{
			stats.number_of_drawn_dwarves++;
			d.draw(v);
			}
*/
		draw(monsters);		
		drawStat(structures, stats.number_of_drawn_structures);
	
/*		foreach(s; structures)
			{
			stats.number_of_drawn_structures++;
			s.draw(v);
			}*/
			
		blood.draw(v);
		draw(chests);
		draw(items);
		draw(trees);
		
		
/*		
		foreach(c; chests)
			{
//			stats.number_of_drawn_structures++;
			c.draw(v);
			}
		foreach(i; items)
			{
//			stats.number_of_drawn_structures++;
			i.draw(v);
			}*/
			
		map.draw(v, true);
		}
		
	void logic()
		{
		unit_t p = units[0]; // player
			
		p.isPlayerControlled  = true;

		if(key_w_down)p.up();
		if(key_s_down)p.down();
		if(key_a_down)p.left();
		if(key_d_down)p.right();
		
		if(key_q_down)p.actionAttack();
		if(key_e_down)p.actionUse();
		if(key_f_down)p.actionSprint();

		if(key_space_down)p.actionJump();

		map.logic();
		
		void tick(T)(ref T obj)
			{
			foreach(o; obj)
				{
				o.onTick();
				}
			}
			
		tick(units);
//		tick(objects);
//		tick(dwarves);
		tick(monsters);
		tick(structures);
		tick(chests);
		tick(items);
		tick(trees);

		//prune ready-to-delete entries
		void prune(T)(ref T obj)
			{
			for (size_t i = obj.length ; i-- > 0 ; )
				{
				if(obj[i].delete_me)obj = obj.remove(i); continue;
				}
			//see https://forum.dlang.org/post/sagacsjdtwzankyvclxn@forum.dlang.org
			}
		prune(units);
		prune(objects);
		prune(dwarves);
		prune(monsters);
		prune(structures);
		prune(chests);
		prune(items);
		prune(trees);
		}
	}

// CONSTANTS
//=============================================================================
//struct globals_t
//	{
	player_t[2] players;
		
	ALLEGRO_FONT* 	font;
	
	ALLEGRO_BITMAP* dude_up_bmp;
	ALLEGRO_BITMAP* dude_down_bmp;
	ALLEGRO_BITMAP* dude_left_bmp;
	ALLEGRO_BITMAP* dude_right_bmp;
	
	ALLEGRO_BITMAP* chest_bmp;
	ALLEGRO_BITMAP* chest_open_bmp;

	ALLEGRO_BITMAP* dwarf_bmp;
	ALLEGRO_BITMAP* goblin_bmp;
	ALLEGRO_BITMAP* boss_bmp;

	ALLEGRO_BITMAP* fountain_bmp;
	
	ALLEGRO_BITMAP* tree_bmp;

	ALLEGRO_BITMAP* wall_bmp;
	ALLEGRO_BITMAP* grass_bmp;
	ALLEGRO_BITMAP* lava_bmp;
	ALLEGRO_BITMAP* water_bmp;
	
	ALLEGRO_BITMAP* wood_bmp;
	ALLEGRO_BITMAP* stone_bmp;
	ALLEGRO_BITMAP* reinforced_wall_bmp;
	
	ALLEGRO_BITMAP* sword_bmp;
	ALLEGRO_BITMAP* carrot_bmp;
	ALLEGRO_BITMAP* potion_bmp;
	
	ALLEGRO_BITMAP* blood_bmp;

	int SCREEN_W = 1200;
	int SCREEN_H = 600;
//	}
//globals_t g;

import std.format;
void load_resources()	
	{
	g.font = al_load_font("./data/DejaVuSans.ttf", 18, 0);

	g.dude_up_bmp  	= getBitmap("./data/dude_up.png");
	g.dude_down_bmp  	= getBitmap("./data/dude_down.png");
	g.dude_left_bmp  	= getBitmap("./data/dude_left.png");
	g.dude_right_bmp  	= getBitmap("./data/dude_right.png");
	
	g.sword_bmp  		= getBitmap("./data/sword.png");
	g.carrot_bmp  		= getBitmap("./data/carrot.png");
	g.potion_bmp  		= getBitmap("./data/potion.png");
	
	g.chest_bmp  		= getBitmap("./data/chest.png");
	g.chest_open_bmp  	= getBitmap("./data/chest_open.png");

	g.dwarf_bmp  	= getBitmap("./data/dwarf.png");
	g.goblin_bmp  	= getBitmap("./data/goblin.png");
	g.boss_bmp  	= getBitmap("./data/boss.png");

	g.wall_bmp  	= getBitmap("./data/wall.png");
	g.grass_bmp  	= getBitmap("./data/grass.png");
	g.lava_bmp  	= getBitmap("./data/lava.png");
	g.water_bmp  	= getBitmap("./data/water.png");
	g.fountain_bmp  = getBitmap("./data/fountain.png");
	g.wood_bmp  	= getBitmap("./data/wood.png");
	g.stone_bmp  	= getBitmap("./data/brick.png");
	
	g.tree_bmp  	= getBitmap("./data/tree.png");
	
	g.blood_bmp  	= getBitmap("./data/blood.png");
	
	g.reinforced_wall_bmp  	= getBitmap("./data/reinforced_wall.png");	
	}

ALLEGRO_BITMAP* getBitmap(string path)
	{
	import std.string : toStringz;
	ALLEGRO_BITMAP* bmp = al_load_bitmap(toStringz(path));
	assert(bmp != null, format("ERROR: Failed to load bitmap [%s]!", path));
	return bmp;
	}

struct statistics_t
	{
	ulong number_of_drawn_particles=0;
	ulong number_of_drawn_objects=0;
	ulong number_of_drawn_structures=0;
	ulong number_of_drawn_dwarves=0;
	ulong number_of_drawn_background_tiles=0;
	ulong fps=0;
	ulong frames_passed=0;
	}

statistics_t stats;

int mouse_x = 0; //cached, obviously. for helper routines.
int mouse_y = 0;
int mouse_lmb = 0;
int mouse_in_window = 0;
bool key_w_down = false;
bool key_s_down = false;
bool key_a_down = false;
bool key_d_down = false;
bool key_q_down = false;
bool key_e_down = false;
bool key_f_down = false;
bool key_space_down = false;
