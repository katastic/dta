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

immutable int TILE_W=32;
immutable int TILE_H=TILE_W;
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

/// thought bubble handler
class bubble_handler
	{
	bubble[] bubbles;
	
	void spawn(string text, float _x, float _y, int lifetime)
		{
		bubble b;
		b.text = text;
		b.x = _x;
		b.y = _y;
		b.lifetime = lifetime;
		
		bubbles ~= b;
		}
	
	void drawBubble(bubble b, viewport_t v)
		{
		float cx = b.x - v.ox + v.x; // topleft x,y
		float cy = b.y - v.oy + v.y;
		float w = 100;
		float h = 64;
		float r = 5;
		
		al_draw_filled_rounded_rectangle(
			cx, cy,
			cx + w, cy + h,
			r, r, COLOR(1,1,1,0.7));
			
		al_draw_text(g.font, COLOR(0,0,0,1.0), cx + r, cx + r, 0, b.text.toStringz);
		
		// todo: smooth fade out 
		// if(lifetime < 10) ...
		}
	
	void draw(viewport_t v)
		{
		foreach(b; bubbles)
			{
			drawBubble(b, v);
			}
		}
	
	void onTick()
		{
		foreach(b; bubbles)
			{
			b.lifetime--;
			if(b.lifetime >= 0)b.isDead = true;
			}
		for(size_t i = bubbles.length ; i-- > 0 ; )
			{
			if(bubbles[i].isDead)bubbles = bubbles.remove(i); continue;
			}
		}
	}

struct light
	{
	float x=684;
	float y=245;
	COLOR color;
	}
	
light[2] lights;

struct bubble
	{
	string text;
	float x=0, y=0;
	float vx=0, vy=0;
	int lifetime=0;
	bool isDead=false;
	}

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
	static_blood_handler_t blood2;

	this()
		{
		map = new map_t;
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

		testGraph = new intrinsic_graph!float(units[0].x, COLOR(1,0,0,1));
//		testGraph.dataSource = &units[0].x;
		
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
		
		testGraph.draw(v);
		}
		
	void logic()
		{
		assert(testGraph !is null);
		testGraph.onTick();
		unit_t p = units[0]; // player
		viewports[0].ox = units[0].x - viewports[0].w/2;
		viewports[0].oy = units[0].y - viewports[0].h/2;

		p.isPlayerControlled = true;

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

/// al_draw_line_segment for pairs
void al_draw_line_segment(pair[] pairs, COLOR color, float thickness)
	{
	assert(pairs.length > 1);
	pair lp = pairs[0]; // initial p, also previous p ("last p")
	foreach(ref p; pairs)
		{
		al_draw_line(p.x, p.y, lp.x, lp.y, color, thickness);
		lp = p;
		}
	}
	
/// al_draw_line_segment for raw integers floats POD arrays
void al_draw_line_segment(T)(T[] x, T[] y, COLOR color, float thickness)
	{
	assert(x.length > 1);
	assert(y.length > 1);
	assert(x.length == y.length);

	for(int i = 1; i < x.length; i++) // note i = 1
		{
		al_draw_line(x[i], y[i], x[i-1], y[i-1], color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_line_segment(T)(T[] y, COLOR color, float thickness)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		al_draw_line(i, y[i], i-1, y[i-1], color, thickness);
		}
	}

/// al_draw_line_segment 1D
void al_draw_scaled_line_segment(T)(pair xycoord, T[] y, float yScale, COLOR color, float thickness)
	{
	assert(y.length > 1);

	for(int i = 1; i < y.length; i++) // note i = 1
		{
		al_draw_line(
			xycoord.x + i, 
			xycoord.y + y[i]*yScale, 
			xycoord.x + i-1, 
			xycoord.y + y[i-1]*yScale, 
			color, thickness);
		}
	}

void testerror()
	{
	import std.algorithm;
	float [] arr;
	float value = arr.maxElement;
	}

// what if we want timestamps? Have two identical buffers, one with X
// and one with (T)ime? (not to be confused with T below)
class circular_buffer(T, size_t size)
	{
	float[size] data; 
 	int index=0;
	bool isFull=false;
	int maxSize=size;
	
	/* note:
	if 'data' is a static array it causes all kinds of extra problems
	 because static arrays aren't ranges so magic things like maxElement
	 fail.
	 
	but it's its dynamic, now its on the heap. We're only allocating once
	but it's still kinda bullshit.
	
	but then we have to "manage" an expanding array even though its not
	going to expand so the appender has to deal with the case of growing
	until it hits max size. which is also bullshit.
	*/
    
    T maxElement()
		{
		T maxSoFar = to!T(-99999999);
		for(int i = 0; i < size; i++)
			{
			if(data[i] > maxSoFar)maxSoFar = data[i]; 
			}
		return maxSoFar;
		}

    T opApply(scope T delegate(ref T) dg)
		{ //https://dlang.org/spec/statement.html#foreach-statement
        foreach (e; data)
			{
            T result = dg(e);
            if (result)
                return result;
			}
        return 0;
		}
		
	void addNext(T t)
		{
		index++;
		if(index == data.length)
			{
			index = 0; isFull = true;
			}
		data[index] = t;
		}
	}

intrinsic_graph!float testGraph;

/// Graph that attempts to automatically poll a value every frame
/// is instrinsic the right name?
/// We also want a variant that gets manually fed values
/// This one also will (if maxTimeRemembered != 0) not reset the "zoom" or y-scaling
/// for a certain amount of time after the 
///
/// Not sure if time remembered should be in terms of individual frames, or, 
/// in terms of "buffers" full. Because a longer buffer, with same frames, will
/// last a shorter length and so what's right for one buffer, could be not enough
/// for a larger one.
///
/// Also warning: Make sure any timing considerations don't expect DRAWING to be
/// lined up 1-to-1 with LOGIC. Draw calls may be duplicated with no new data, or 
/// skipped during slowdowns.

class intrinsic_graph(T)
	{
	float x=0,y=300;
	int w=400, h=100;
	COLOR color;
	BITMAP* buffer;
	T* dataSource; // where we auto grab the data every frame
	circular_buffer!(T, 400) dataBuffer; //how do we invoke the constructor?

	// private data
 	private T max=-9999; //READONLY cache of max value.
 	private float scaleFactor=1.00; //READONLY set by draw() every frame.
 	private int maxTimeRemembered=600; // how many frames do we remember a previous maximum. 0 for always update.
 	private T previousMaximum=0;
	private int howLongAgoWasMaxSet=0;
 	
	this(ref T _dataSource, COLOR _color)
		{
		dataBuffer = new circular_buffer!(T, 400);
		dataSource = &_dataSource;
		color = _color;
		}

	void draw(viewport_t v)
		{
		al_draw_filled_rectangle(x, y, x + w, y + h, COLOR(1,1,1,.75));

		float tempMax = max;
		howLongAgoWasMaxSet++;
		if(tempMax < previousMaximum && howLongAgoWasMaxSet <= maxTimeRemembered)
			{
			tempMax = previousMaximum;
			}else{
			previousMaximum = tempMax;
			howLongAgoWasMaxSet = 0;
			}
		float scaleFactor=h/tempMax;
		al_draw_scaled_line_segment(pair(this), dataBuffer.data, scaleFactor, color, 1.0f);

		al_draw_text(g.font, COLOR(0,0,0,1), x, y, 0, "0");
		al_draw_text(g.font, COLOR(0,0,0,1), x, y+h-g.font.h, 0, format("%s",max).toStringz);
		}
		
	void onTick()
		{
		max = dataBuffer.maxElement; // note: we only really need to scan if [howLongAgoWasMaxSet] indicates a time we'd scan
		dataBuffer.addNext(*dataSource);
		}
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

