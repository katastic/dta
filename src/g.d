import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.stdio;
import std.conv;
import std.string;
import std.random;
import std.algorithm : remove;

import helper;
import objects;
import viewport;
import map;
import gui : gui_t;
import blood;
import atlas;

bool selectLayer=false; //which layer for mouse map editing is selected

alias KEY_UP = ALLEGRO_KEY_UP; // should we do these? By time we write them out we've already done more work than just writing them.
alias KEY_DOWN = ALLEGRO_KEY_DOWN; // i'll leave them coded as an open question for later
alias KEY_LEFT = ALLEGRO_KEY_LEFT; 
alias KEY_RIGHT = ALLEGRO_KEY_RIGHT; 

alias COLOR = ALLEGRO_COLOR;
alias BITMAP = ALLEGRO_BITMAP;
alias FONT = ALLEGRO_FONT;
alias tile=ushort;
alias dir=direction;

struct light
	{
	float x=684;
	float y=245;
	COLOR color;
	}
	
light[1] lights;

struct particle
	{
	float x=0, y=0;
	float vx=0, vy=0;
	int lifetime=0;
	bool isDead=false;
	}

class leaf_handler : particle_handler
	{
	}

class particle_handler
	{
	particle[] data;
	
	void draw(viewport_t v)
		{
		// what about accumulation buffer particle systems like static blood decal
		foreach(p; data)
			{
			
			}
		}
	
	void onTick()
		{
		foreach(p; data)
			{
			p.x += p.vx;
			p.y += p.vy;
			}
		}
	}

class weather_t
	{
	void draw(viewport_t v)
		{
		}
	
	void onTick()
		{
		}
	}

struct ipair
	{
	int x;
	int y;
	this(int _x, int _y) //needed?
		{
		x = _x;
		y = _y;
		}
	}

struct pair
	{
	float x;
	float y;
	
	this(T)(T t) //give it an object
		{
		x = t.x;
		y = t.y;
		}
	
	this(int _x, int _y)
		{
		x = to!float(_x);
		y = to!float(_y);
		}

	this(float _x, float _y)
		{
		x = _x;
		y = _y;
		}
	this(double _x, double _y)
		{
		x = _x;
		y = _y;
		}
	}

atlas_t atlas1;
atlas_t atlas2;
world_t world;
viewport_t [2] viewports;
gui_t[2] guis; //todo: combine into viewports

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
	//blood_handler_t blood;
	static_blood_handler_t blood2;

	this()
		{
		//atlas.loadMeta(); // NOTE THIS IS GLOBAL not inside world class
			
		map = new map_t;
		//blood = new blood_handler_t();
		blood2 = new static_blood_handler_t(map);
		
		units ~= new dwarf_t(680, 360, 0, 0, g.stone_bmp);
		monsters ~= new monster_t(220 + uniform!"[]"(-100, 100), 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220 + uniform!"[]"(-100, 100), 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220 + uniform!"[]"(-100, 100), 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220 + uniform!"[]"(-100, 100), 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new monster_t(220 + uniform!"[]"(-100, 100), 220, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));
		monsters ~= new boss_t(420, 320, uniform!"[]"(-.5, .5), uniform!"[]"(-.5, .5));	
	
		structures ~= new monster_structure_t(500, 200);
		structures ~= new monster_structure_t(600, 200);
		structures ~= new monster_structure_t(700, 200);
		structures ~= new monster_structure_t(800, 200);
		
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
		
		map.draw(v, false);
//		blood.draw(v);
		blood2.draw(v);
		drawStat(units, stats.number_of_drawn_dwarves);
		drawStat(monsters, stats.number_of_drawn_dwarves);		
		drawStat(structures, stats.number_of_drawn_structures);
		
		drawStat(chests, stats.number_of_drawn_objects);
		drawStat(items, stats.number_of_drawn_objects);
		drawStat(trees, stats.number_of_drawn_objects);

		map.draw(v, true);
		
		if(!g.atlas1.isHidden)
			{
			if(g.selectLayer)
				g.atlas1.drawAtlas( g.SCREEN_W - g.atlas1.atl.w, 140);
			else
				g.atlas2.drawAtlas( g.SCREEN_W - g.atlas2.atl.w, 140);
			}
		// g.SCREEN_H - g.atlas.atl.h);
		}
		
	void logic()
		{
		unit_t p = units[0]; // player
			
		viewports[0].ox = units[0].x - viewports[0].w/2;
		viewports[0].oy = units[0].y - viewports[0].h/2;

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

	int SCREEN_W = 1360;
	int SCREEN_H = 720;
//	}
//globals_t g;

import std.format;
void loadResources()	
	{
	g.atlas1.load("./data/atlas.png");
	g.atlas1.loadMeta();
	g.atlas2.load("./data/atlas2.png");
	g.atlas2.loadMeta();
		
	g.font = getFont("./data/DejaVuSans.ttf", 18);

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

struct statistics_t
	{
	// per frame statistics
	ulong number_of_drawn_particles=0;
	ulong number_of_drawn_objects=0;
	ulong number_of_drawn_structures=0;
	ulong number_of_drawn_dwarves=0;
	ulong number_of_drawn_background_tiles=0;
	
	ulong fps=0;
	ulong frames_passed=0;
	
	void reset()
		{ // note we do NOT reset fps/frames_passed here as they are cumulative or handled elsewhere.
		number_of_drawn_particles = 0;
		number_of_drawn_objects = 0;
		number_of_drawn_structures = 0;
		number_of_drawn_dwarves = 0;
		number_of_drawn_background_tiles = 0;
		}
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

