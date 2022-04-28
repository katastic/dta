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

alias KEY_UP = ALLEGRO_KEY_UP; // should we do these? By time we write them out we've already done more work than just writing them.
alias KEY_DOWN = ALLEGRO_KEY_DOWN; // i'll leave them coded as an open question for later
alias KEY_LEFT = ALLEGRO_KEY_LEFT; 
alias KEY_RIGHT = ALLEGRO_KEY_RIGHT; 

alias COLOR = ALLEGRO_COLOR;
alias BITMAP = ALLEGRO_BITMAP;
alias tile=ubyte;
alias dir=direction;

struct pair
	{
	float x;
	float y;

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

/*
import std.typecons;

// https://dlang.org/library/std/typecons/typedef.html
//  Unlike the alias feature, Typedef ensures the two types are
//  not considered as equals. 
alias sPair = Typedef!(pair, pair.init, "screen"); // screen pair?
alias wPair = Typedef!(pair, pair.init, "world"); // world pair?
alias vPair = Typedef!(pair, pair.init, "viewport"); // viewport pair?

//alias s2v = screenToViewport;
alias v2s = viewportToScreen;
sPair viewportToScreen(vPair s, viewport_t v)
	{
	return cast(sPair)pair(s.x - v.ox + v.x, s.y - v.oy + v.y);
	} //but what if our functions want only the x or y? Is there a template way?

void test1()
	{
//	pair v4 = pair(1f, 2f); // works fine
	vPair v5 = vPair(pair(1f, 2f));
	return;
	}*/

struct meta_t
	{
	bool isPassable;
	bool isSlowing;
	bool isLiquid;
	bool isPainful; // lava  
	}
	
meta_t path = {true, false, false, false};
meta_t solid = {false, false, false, false};
meta_t water = {false, false, true, false};
meta_t lava  = {false, false, true, true};

struct atlas_t
	{
	bool isHidden=false;
//	meta_t*	[] meta;
	meta_t	[16*25] meta;
	BITMAP* [] data;
	alias data this;
	BITMAP* atl;
	int w=16;
	int h=25;



	// Editing the metadata functions
	// ---------------------------------------------------------------
	int currentCursor=0;
	void changeCursor(int relValue)
		{
		if( (cast(short)currentCursor + relValue >= 0) 
			&& 
			currentCursor + relValue <= g.atlas.data.length)
			{
			currentCursor += relValue;
			writeln(currentCursor.stringof, " = ", currentCursor);
			}			
		}
		
	void toggleIsPassable()
		{
		writeln("Toggling isPassable for ", currentCursor, " = ", meta[currentCursor].isPassable);
		meta[currentCursor].isPassable = !meta[currentCursor].isPassable;		
		}
		
	//https://forum.dlang.org/post/t3ljgm$16du$1@digitalmars.com
	//big 'ol wtf case.
	void rawWriteValue(T)(File file, T value)
		{
		file.rawWrite((&value)[0..1]);
		}

	void saveMeta(string path="meta.map")
		{
		auto f = File(path, "w");
		rawWriteValue(f, meta);
		//https://forum.dlang.org/post/mailman.113.1330209587.24984.digitalmars-d-learn@puremagic.com
		writeln("SAVING META MAP");
		}

	void loadMeta(string path="meta.map")
		{
		writeln("LOADING META MAP");
		auto read = File(path).rawRead(meta[]);
		}

	// -----------------------------------------------------------------------

	BITMAP* canvas;
	void drawAtlas(float x, float y)
		{
		assert(canvas !is null);
		al_set_target_bitmap(canvas);
		al_draw_filled_rectangle(0, 0, 0 + atl.w-1, 0 + atl.h-1, ALLEGRO_COLOR(.7,.7,.7,.7));
		al_draw_bitmap(atl, 0, 0, 0);

		{
		int idx = 0;
		int i = 0;
		int j = 0;
		
		do{
			if(i >= atl.w/32)
				{
				i=0;
				j++;
				}
			if(j >= atl.h/32)break;
			if(idx >= w*h-1)break;

			if(g.atlas.meta[idx].isPassable == false)
				{
				draw_target_dot(0 + i*32, 0 + j*32);
				}
			i++;
			idx++;
			}while(true);
		}

		{
		int idx = 0;
		float x2 = 0;
		float y2 = 0;
		
		do{
			if(idx == currentCursor)break;
			idx++;
			x2+=32;
			if(x2 >= atl.w)
				{
				x2 = 0;
				y2 += 32;
				}
			}while(true);
		al_draw_rectangle(0 + x2, 0 + y2, 0 + x2 + 31, 0 + y2 + 31, ALLEGRO_COLOR(1,0,0,1), 3);
		}
		
		al_reset_target();
		immutable float SCALE = 0.75;
		al_draw_scaled_bitmap2(canvas, x, y, SCALE, SCALE);
		
		}

	void load(string filepath)
		{
		writeln("loading atlas at ", filepath);
		atl = al_load_bitmap(filepath.toStringz());
		assert(atl != null, "ATLAS " ~ filepath ~ " NOT FOUND/LOADABLE");
		
		int width = atl.w;
		int height = atl.h;
		
		assert(width % 32 == 0, "ATLAS ISNT 32-byte ALIGNED. ZEUS IS FURIOUS."); 
		
		// TODO FIX. consider making a sub-bitmap based one
		// so we're not constantly changing textures while drawing
		// (one for each layer would work.)
		
		int z = 0;
		for(int j = 0; j < h; j++) //note: order important
		for(int i = 0; i < w; i++)
			{
			writeln("i, j, z = ", i, " ", j, " ", z);
			BITMAP* b = al_create_sub_bitmap(atl, 32*i, 32*j, 32, 32);
			assert(b != null);
			data ~= b;
			
			if(z == 1 || z == 9)
				{
				meta_t m;
				m.isPassable = false;
				meta[z] = m;
				}else{
				meta_t m;
				m.isPassable = true;
				meta[z] = m;
				}
			z++;
			}
		writeln("meta.length = ", meta.length);
		writeln("data.length = ", data.length);

		if(canvas) // just in case this gets called twice
			{
			al_destroy_bitmap(canvas); 
			}
		canvas = al_create_bitmap(atl.w, atl.h);
		assert(canvas !is null);
		}
	}

atlas_t atlas;

struct blood_t
	{
	int x=0, y=0;
	int lifetime=100;
	int bloodtype=0; // or use bmp
	int rotation=0;
	bool deleteMe=false;
	}  
	// ideally we sort this by bloodtype to reduce contextswitches
	// we could use a pointer to bmp but that would be slower?
	// -> DONT FORGET we can do a full decal map if necessary and just paint to it.
	// writing will be slower, RAM much higher, but one flat draw call each time.
	// -> could split into multiple subsector maps so only the smaller sector is being
	// updated (where blood is happening) to reduce bus transfers. If we only update
	// the important area of the bitmap it's not so bad except allegro likely keeps
	// the memory copy, and then does a full blit (not dirty rectangles) of the entire
	// map back to VRAM. So the bigger the atlas, the bigger the transfer even for a 
	// single pixel. We can benchmark this to see speeds for a 256x256 vs 2048x2048, etc
	// -> The fact we're drawing HUNDREDS of these adds up to a significant amount of
	// our current draw time (like 11% and we're not doing much!) on my netbook
/*
	welp it's like infinitely faster it seems to do one draw call
	
	HOWEVER, what about the WRITE SPEED. how many WRITES per frame can we do
	before it gets slower to simply DRAW them all?
	
	HOWEVER HOWEVER, most decals are NOT MOVING. So a constant "stream of blood" (ahah) 
	is okay as long as it doesn't exceed a certain amount per second. The total amount
	doesn't matter so eventually, with time, the static method will ALWAYS exceed the
	live method. 
	
	Quick test: 15 constant additions of blood have no discernable impact on framerate!
		"PEOPLE ARE ICE SKATING ON A RIVER OF BLOOD OUT HERE."
*/
class static_blood_handler_t
	{
	BITMAP* data;
	BITMAP*[4][4] chunks; //lmfao pun
	
	this(ref map_t m)
		{
		data = al_create_bitmap(m.w*32, m.h*32); //ideally power of 2? TEST THAT.
	// WORKS
	//	al_set_target_bitmap(data);
	//	al_clear_to_color(COLOR(1,0,1,1));
	//	al_set_target_backbuffer(al_get_current_display()); // is there an Allegro function that already does this?
		assert(data != null);
		}
	
	void add(float x, float y)
		{
		al_set_target_bitmap(data);
		al_draw_centered_bitmap(g.blood_bmp, x, y, uniform!"[]"(0,3));
		al_reset_target();
		}
		
	void draw(viewport_t v)
		{
		al_draw_bitmap(data, 0 - v.ox + v.x, 0 - v.oy + v.y, 0);
		}
	}

class blood_handler_t
	{
	blood_t[] data;

	this()
		{
		// 20000 = 16 FPS with al_draw_bitmap 		
		// 20000 = 16 FPS with al_tinted_draw_bitmap 		
		// 20000 = 33 FPS with isInsideScreen() with 7905 drawn
		// 20000 = 33 FPS with isWideInsideScreen() with 8041 drawn
		
		// 10000 (4000 drawn) = 52 FPS with isWideInsideScreen
		
		// Hell, we could even AUTOMATICALLY reduce max draw counts
		// of particles when game framerate gets below TARGET_FRAMERATE
		// though we have to be careful not to eliminate important ones.
		// for example, we could skip every other particle because likewise
		// particles tend to spawn together so everything gets halved. However,
		// dropping HALF will be a sudden drop. Dropping every 4th and rising 
		// from there might work.
		
		immutable int STARTING_BLOOD = 5000;
		for(int i = 0; i < STARTING_BLOOD; i++)
			{
			float w = 50; //g.world.map.w
			float h = 50;
			
			float x1 = uniform!"[]"(0, 32*(w-1));
			float y1 = uniform!"[]"(0, 32*(h-1));
			add(x1, y1);
			}
		}

	void add(float x, float y)
		{
		blood_t b = blood_t(cast(int)x, cast(int)y, 100, 0, uniform!"[]"(0, 4), false);
		data ~= b;
		}
	
	void draw(viewport_t v)
		{
		COLOR c = COLOR(1,1,1,.9);
		foreach(b; data)
			{
			if(b.bloodtype == 0 && isWideInsideScreen(b.x - v.ox + v.x, b.y - v.oy + v.y, g.blood_bmp, v))
				{
				al_draw_tinted_bitmap(
					g.blood_bmp, c,
					b.x - v.ox + v.x - g.blood_bmp.w/2, 
					b.y - v.oy + v.y - g.blood_bmp.h/2, 
					b.rotation);
					// if we're gonna spam TONS of these and barely even use any tinting, we might as well just use straight non-transparent draw calls
					
/*				al_draw_tinted_bitmap(
					g.blood_bmp,
					ALLEGRO_COLOR(1.0, 1.0, 1.0, 0.9),
					b.x - v.ox + v.x - g.blood_bmp.w/2, 
					b.y - v.oy + v.y - g.blood_bmp.h/2, 
					b.rotation);*/
				stats.number_of_drawn_particles++;
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
		
		if(!g.atlas.isHidden)g.atlas.drawAtlas( g.SCREEN_W - g.atlas.atl.w, 140);
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
	g.atlas.load("./data/atlas.png");
		
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

