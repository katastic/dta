/*
	-> TO TEST: benchmark blood decal maps of various sizes vs drawing.
		Also benchmark write performance (adding a new blood spot)
		 - one benefit of blits is they can move if necessary 
		 but will that ever be necessary? For static decals like blood
		 we can likely benefit from one gigantic (or subsectioned) 
		 blood maps.

	-> Basic tiled and lightmap lighting?

	-> THERE IS some allegro bullshit
		-> al_draw_bitmap ALWAYS calls al_draw_tinted_bitmap
		which calls _draw_tinted_rotated_scaled_bitmap_region 

		https://github.com/liballeg/allegro5/blob/aeb6c4f4f81773b45c249bfec055c5351d184617/src/bitmap_draw.c#L62
		https://github.com/liballeg/allegro5/blob/c9bc8d5dd787395f25c2de1a84cd986dbcd453e3/src/opengl/ogl_bitmap.c#L295

		It may really be faster for us to clip natively before 
		going into the insane callstack that is allegro.
		
		worst case, do this magical thing called a BENCHMARK.

	DRAW QUESTION:
		Do we want to draw layers IN ORDER? That is, objects have to be drawn
		in order too?

			OOOH. draw tiles like the same layer but only split for blood and other 'floor' 
			decals whereas sprites are still on top.

*/

// GLOBAL CONSTANTS
// =============================================================================
immutable bool DEBUG_NO_BACKGROUND = true; /// No graphical background so we draw a solid clear color.

// =============================================================================

import std.stdio;
import std.conv;
import std.string;
import std.format;
import std.random;
import std.algorithm;
import std.traits; // EnumMembers
//thread yielding?
//-------------------------------------------
//import core.thread; //for yield... maybe?
//extern (C) int pthread_yield(); //does this ... work? No errors yet I can't tell if it changes anything...
//------------------------------

pragma(lib, "dallegro5ldc");

version(ALLEGRO_NO_PRAGMA_LIB)
{

}else{
	pragma(lib, "allegro");
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
}

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helper;
import objects;
import viewport;
import g;

alias BITMAP=ALLEGRO_BITMAP;

//ALLEGRO_CONFIG* 		cfg;  //whats this used for?
ALLEGRO_DISPLAY* 		al_display;
ALLEGRO_EVENT_QUEUE* 	queue;
ALLEGRO_TIMER* 			fps_timer;
ALLEGRO_TIMER* 			screencap_timer;
display_t display;

//=============================================================================

//https://www.allegro.cc/manual/5/keyboard.html
//	(instead of individual KEYS touching ANY OBJECT METHOD. Because what if we 
// 		change objects? We have to FIND all keys associated with that object and 
// 		change them.)
alias ALLEGRO_KEY = ubyte;
struct keyset_t
		{
		object_t obj;
		ALLEGRO_KEY [ __traits(allMembers, keys_label).length] key;
		// If we support MOUSE clicks, we could simply attach a MOUSE in here 
		// and have it forward to the object's click_on() method.
		// But again, that kills the idea of multiplayer.
		}
		
enum keys_label
	{
	ERROR = 0,
	UP_KEY,
	DOWN_KEY,
	LEFT_KEY,
	RIGHT_KEY,
	FIRE_UP_KEY,
	FIRE_DOWN_KEY,
	FIRE_LEFT_KEY,
	FIRE_RIGHT_KEY,
	ACTION_KEY
	}

bool initialize()
	{
	if (!al_init())
		{
		auto ver 		= al_get_allegro_version();
		auto major 		= ver >> 24;
		auto minor 		= (ver >> 16) & 255;
		auto revision 	= (ver >> 8) & 255;
		auto release 	= ver & 255;

		writefln(
"The system Allegro version (%s.%s.%s.%s) does not match the version of this binding (%s.%s.%s.%s)",
			major, minor, revision, release,
			ALLEGRO_VERSION, ALLEGRO_SUB_VERSION, ALLEGRO_WIP_VERSION, ALLEGRO_RELEASE_NUMBER);

		assert(0, "The system Allegro version does not match the version of this binding!"); //why
		}
	
static if (false) // MULTISAMPLING. Not sure if helpful.
	{
	with (ALLEGRO_DISPLAY_OPTIONS)
		{
		al_set_new_display_option(ALLEGRO_SAMPLE_BUFFERS, 1, ALLEGRO_REQUIRE);
		al_set_new_display_option(ALLEGRO_SAMPLES, 8, ALLEGRO_REQUIRE);
		}
	}

	al_display 	= al_create_display(g.SCREEN_W, g.SCREEN_H);
	queue		= al_create_event_queue();

	if (!al_install_keyboard())      assert(0, "al_install_keyboard failed!");
	if (!al_install_mouse())         assert(0, "al_install_mouse failed!");
	if (!al_init_image_addon())      assert(0, "al_init_image_addon failed!");
	if (!al_init_font_addon())       assert(0, "al_init_font_addon failed!");
	if (!al_init_ttf_addon())        assert(0, "al_init_ttf_addon failed!");
	if (!al_init_primitives_addon()) assert(0, "al_init_primitives_addon failed!");

	al_register_event_source(queue, al_get_display_event_source(al_display));
	al_register_event_source(queue, al_get_keyboard_event_source());
	al_register_event_source(queue, al_get_mouse_event_source());
	
	with(ALLEGRO_BLEND_MODE)
		{
		al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA, ALLEGRO_INVERSE_ALPHA);
		}
				
	// load animations/etc
	// --------------------------------------------------------
	load_resources();

	// SETUP world
	// --------------------------------------------------------
	world = new world_t;

	// SETUP players
	// --------------------------------------------------------
	
	// SETUP viewports
	// --------------------------------------------------------
	viewports[0] = new viewport_t;
	viewports[0].x = 0;
	viewports[0].y = 0;
//	viewports[0].w  = g.SCREEN_W/2;// - 1;
	viewports[0].w  = g.SCREEN_W;// - 1;
	viewports[0].h = g.SCREEN_H;
	viewports[0].ox = 0;
	viewports[0].oy = 0;
		

	dwarf_t p = cast(dwarf_t)(g.world.units[0]); 
	guis[0] = new gui_t(p);
	guis[0].x = 50;
	guis[0].y = 200;
	
/*
	viewports[1] = new viewport_t;
	viewports[1].x = g.SCREEN_W/2;
	viewports[1].y = 0;
	viewports[1].w  = g.SCREEN_W/2;//[ - 1;
	viewports[1].h = g.SCREEN_H;
	viewports[1].ox = 0;
	viewports[1].oy = 0;
*/
	world.map.load();

	assert(viewports[0] !is null);
	
	// FPS Handling
	// --------------------------------------------------------
	fps_timer 		= al_create_timer(1.0f);
	screencap_timer = al_create_timer(10.0f);
	al_register_event_source(queue, al_get_timer_event_source(fps_timer));
	al_register_event_source(queue, al_get_timer_event_source(screencap_timer));
	al_start_timer(fps_timer);
	al_start_timer(screencap_timer);
	
	return 0;
	}
	
struct display_t
	{
	void start_frame()	
		{
		stats.number_of_drawn_objects=0;
		stats.number_of_drawn_dwarves=0;
		stats.number_of_drawn_background_tiles=0;
		stats.number_of_drawn_particles=0;
		stats.number_of_drawn_structures=0;
		
		reset_clipping(); //why would we need this? One possible is below! To clear to color the whole screen!
		al_clear_to_color(ALLEGRO_COLOR(.2,.2,.2,1)); //only needed if we aren't drawing a background
		}
		
	void end_frame()
		{	
		al_flip_display();
		}

	void draw_frame()
		{
		start_frame();
		//------------------

		draw2();

		//------------------
		end_frame();
		}

	void reset_clipping()
		{
		al_set_clipping_rectangle(0, 0, g.SCREEN_W-1, g.SCREEN_H-1);
		}
		
	void draw2()
		{
		
	static if(true) //draw left viewport
		{
		al_set_clipping_rectangle(
			viewports[0].x, 
			viewports[0].y, 
			viewports[0].x + viewports[0].w ,  //-1
			viewports[0].y + viewports[0].h); //-1
		
		static if(DEBUG_NO_BACKGROUND)
			al_clear_to_color(ALLEGRO_COLOR(.05, .05, .05, 1));
		
		world.draw(viewports[0]);
		guis[0].onTick();
		guis[0].draw(viewports[0]);
		}

	static if(false) //draw right viewport
		{
		al_set_clipping_rectangle(
			viewports[1].x, 
			viewports[1].y, 
			viewports[1].x + viewports[1].w  - 1, 
			viewports[1].y + viewports[1].h - 1);

		static if(DEBUG_NO_BACKGROUND)
			al_clear_to_color(ALLEGRO_COLOR(.8,.7,.7, 1));

		world.draw(viewports[1]);
		}
		
		//Viewport separator
	static if(false)
		{
		al_draw_line(
			g.SCREEN_W/2 + 0.5, 
			0 + 0.5, 
			g.SCREEN_W/2 + 0.5, 
			g.SCREEN_H + 0.5,
			al_map_rgb(0,0,0), 
			10);
		}
		
		// Draw FPS and other text
		display.reset_clipping();

		al_draw_filled_rounded_rectangle(16, 32, 64+650, 105+32, 8, 8, ALLEGRO_COLOR(.7, .7, .7, .7));

if(stats.fps != 0)	
		al_draw_textf(g.font, ALLEGRO_COLOR(0, 0, 0, 1), 20, text_helper(false), ALLEGRO_ALIGN_LEFT, "fps[%d] objrate[%d]", stats.fps, 
					(stats.number_of_drawn_objects +
					stats.number_of_drawn_dwarves + 
					stats.number_of_drawn_background_tiles + 
					stats.number_of_drawn_objects + 
					stats.number_of_drawn_particles + 
					stats.number_of_drawn_structures) * stats.fps ); 
					// total draws multiplied by fps. how many objects per second we can do.
					// should be approx constant for a cpu once you have enough objects and, are 
					// no longer limited by screen VSYNC.
					
			al_draw_textf(g.font, ALLEGRO_COLOR(0, 0, 0, 1), 20, text_helper(false), ALLEGRO_ALIGN_LEFT, "mouse [%d, %d][%d]", mouse_x, mouse_y, mouse_lmb);			
			al_draw_textf(g.font, ALLEGRO_COLOR(0, 0, 0, 1), 20, text_helper(false), ALLEGRO_ALIGN_LEFT, "money [%d] deaths [%d]", g.players[0].money, g.players[0].deaths);
			al_draw_textf(g.font, ALLEGRO_COLOR(0, 0, 0, 1), 20, text_helper(false), ALLEGRO_ALIGN_LEFT, 
				"drawn: objects [%d] dwarves [%d] structs [%d] bg_tiles [%d] particles [%d]", 
				stats.number_of_drawn_objects, 
				stats.number_of_drawn_dwarves, 
				stats.number_of_drawn_structures, 
				stats.number_of_drawn_background_tiles, 
				stats.number_of_drawn_particles);
			
		text_helper(true);  //reset
		
		// DRAW MOUSE PIXEL HELPER/FINDER
		draw_target_dot(mouse_x, mouse_y);
//		draw_target_dot(target.x, target.y);

		int val = -1;
		int mouse_xi = (mouse_x + cast(int)viewports[0].ox + cast(int)viewports[0].x)/32;
		int mouse_yi = (mouse_y + cast(int)viewports[0].oy + cast(int)viewports[0].x)/32;
		if(mouse_xi >= 0 && mouse_yi >= 0
			&& mouse_xi < 50 && mouse_yi < 50)
			{
			val = g.world.map.data[mouse_xi][mouse_yi];
			}
			
		al_draw_textf(
			g.font, 
			ALLEGRO_COLOR(0, 0, 0, 1), 
			mouse_x, 
			mouse_y - 30, 
			ALLEGRO_ALIGN_CENTER, "mouse [%d, %d] = %d", mouse_x, mouse_y, val);
		}
	}

void logic()
	{
	world.logic();
	}

void execute()
	{
	ALLEGRO_EVENT event;
		
	bool isKey(ALLEGRO_KEY key)
		{
		// captures: event.keyboard.keycode
		return (event.keyboard.keycode == key);
		}

	void isKeySet(ALLEGRO_KEY key, ref bool setKey)
		{
		// captures: event.keyboard.keycode
		if(event.keyboard.keycode == key)
			{
			setKey = true;
			}
		}
	void isKeyRel(ALLEGRO_KEY key, ref bool setKey)
		{
		// captures: event.keyboard.keycode
		if(event.keyboard.keycode == key)
			{
			setKey = false;
			}
		}
		
	bool exit = false;
	while(!exit)
		{
		while(al_get_next_event(queue, &event))
			{
			switch(event.type)
				{
				case ALLEGRO_EVENT_DISPLAY_CLOSE:
					{
					exit = true;
					break;
					}
				case ALLEGRO_EVENT_KEY_DOWN:
					{
					isKeySet(ALLEGRO_KEY_ESCAPE, exit);

					isKeySet(ALLEGRO_KEY_SPACE, key_space_down);
					isKeySet(ALLEGRO_KEY_Q, key_q_down);
					isKeySet(ALLEGRO_KEY_E, key_e_down);
					isKeySet(ALLEGRO_KEY_W, key_w_down);
					isKeySet(ALLEGRO_KEY_S, key_s_down);
					isKeySet(ALLEGRO_KEY_A, key_a_down);
					isKeySet(ALLEGRO_KEY_D, key_d_down);
					isKeySet(ALLEGRO_KEY_F, key_f_down);
					
					isKeySet(ALLEGRO_KEY_N, g.atlas.isHidden);
					isKeyRel(ALLEGRO_KEY_M, g.atlas.isHidden);
					
					void mouseSetTile(ALLEGRO_KEY key, ubyte mapValue)
						{
						if(event.keyboard.keycode == key)
							{
							int i = cast(int)((mouse_x + viewports[0].ox)/32);
							int j = cast(int)((mouse_y + viewports[0].oy)/32);
							if(i >= 0 && j >= 0 && i < 50 && j < 50)g.world.map.data[i][j] = mapValue;
							}
						}

					void mouseChangeTile(ALLEGRO_KEY key, byte relMapValue)
						{
						if(event.keyboard.keycode == key)
							{
							int i = cast(int)((mouse_x + viewports[0].ox)/32);
							int j = cast(int)((mouse_y + viewports[0].oy)/32);
							if(i >= 0 && j >= 0 && i < 50 && j < 50)
								{
								if(cast(short)g.world.map.data[i][j] + cast(short)relMapValue >= 0
								 &&
								 g.world.map.data[i][j] <= g.atlas.data.length
								 )
									g.world.map.data[i][j] += relMapValue;
								}
							}
						}
						
					void mouseChangeCursorTile(ALLEGRO_KEY key, int relValue)
						{
						if(event.keyboard.keycode == key)
							{
							int i = cast(int)((mouse_x + viewports[0].ox)/32);
							int j = cast(int)((mouse_y + viewports[0].oy)/32);
							if(i >= 0 && j >= 0 && i < 50 && j < 50)
								{
								g.atlas.changeCursor(relValue);
								}
							}
						}

					mouseSetTile(ALLEGRO_KEY_1, 0);
					mouseSetTile(ALLEGRO_KEY_2, 1);
					mouseSetTile(ALLEGRO_KEY_3, 2);
					mouseSetTile(ALLEGRO_KEY_4, 3);
					mouseSetTile(ALLEGRO_KEY_5, 4);
					mouseSetTile(ALLEGRO_KEY_6, 5);
					mouseSetTile(ALLEGRO_KEY_7, 6);
					mouseSetTile(ALLEGRO_KEY_8, 7);
					mouseChangeCursorTile(ALLEGRO_KEY_LEFT, -1);
					mouseChangeCursorTile(ALLEGRO_KEY_RIGHT, 1);
					mouseChangeCursorTile(ALLEGRO_KEY_UP, -g.atlas.atl.w/32);
					mouseChangeCursorTile(ALLEGRO_KEY_DOWN, g.atlas.atl.w/32);

					if(event.keyboard.keycode == ALLEGRO_KEY_O)
						{
						g.atlas.saveMeta();
						}	
				
					if(event.keyboard.keycode == ALLEGRO_KEY_P)
						{
						g.atlas.loadMeta();
						}

					if(event.keyboard.keycode == ALLEGRO_KEY_B)
						{
						g.atlas.toggleIsPassable();
						}
					
					break;
					}
					
				case ALLEGRO_EVENT_KEY_UP:				
					{
					isKeyRel(ALLEGRO_KEY_SPACE, key_space_down);
					isKeyRel(ALLEGRO_KEY_Q, key_q_down);
					isKeyRel(ALLEGRO_KEY_E, key_e_down);
					isKeyRel(ALLEGRO_KEY_W, key_w_down);
					isKeyRel(ALLEGRO_KEY_S, key_s_down);
					isKeyRel(ALLEGRO_KEY_A, key_a_down);
					isKeyRel(ALLEGRO_KEY_D, key_d_down);
					isKeyRel(ALLEGRO_KEY_F, key_f_down);

					break;
					}

				case ALLEGRO_EVENT_MOUSE_AXES:
					{
					mouse_x = event.mouse.x;
					mouse_y = event.mouse.y;
					mouse_in_window = true;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
					{
					writeln("mouse enters window");
					mouse_in_window = true;
					break;
					}
				
				case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
					{
					writeln("mouse left window");
					mouse_in_window = false;
					break;
					}

				case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
					{
					long px = to!long(mouse_x + viewports[0].ox + viewports[0].x)/32;
					long py = to!long(mouse_y + viewports[0].oy + viewports[0].y)/32;
					writeln(viewports[0].ox, ",", viewports[0].oy);
					writeln("mouse click at coordinate[", mouse_x, ",", mouse_y, "] and tile [", px, ",", py, "]");
					if(px < 0 || py < 0)break;
					
					if(event.mouse.button == 1)
						{
						mouse_lmb = true;
						world.map.data[px][py] = cast(ubyte)g.atlas.currentCursor;
						}
					if(event.mouse.button == 2)
						{
//						mouse_lmb = true;
//						world.map.data[px][py] = 1;
						}
					break;
					}
				
				case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
					{
					mouse_lmb = false;
					break;
					}
				
				case ALLEGRO_EVENT_TIMER:
					{
					if(event.timer.source == screencap_timer)
						{
						writeln("saving screenshot [screen.png]");
						al_save_bitmap("screen.png", al_get_backbuffer(al_display));	
						al_stop_timer(screencap_timer);
						}						
					if(event.timer.source == fps_timer) //ONCE per second
						{
						stats.fps = stats.frames_passed;
						stats.frames_passed = 0;
						}
					break;
					}
				default:
				}
			}

		logic();
		display.draw_frame();
		stats.frames_passed++;
//		Fiber.yield();  // THIS SEGFAULTS. I don't think this does what I thought.
//		pthread_yield(); //doesn't seem to change anything useful here. Are we already VSYNC limited to 60 FPS?
		}
	}

void shutdown() 
	{
		
	}

//=============================================================================
int main(string [] args)
	{
	writeln("args length = ", args.length);
	foreach(size_t i, string arg; args)
		{
		writeln("[",i, "] ", arg);
		}
		
	if(args.length > 2)
		{
		g.SCREEN_W = to!int(args[1]);
		g.SCREEN_H = to!int(args[2]);
		writeln("New resolution is ", g.SCREEN_W, "x", g.SCREEN_H);
		}

	return al_run_allegro(
		{
		initialize();
		execute();
		shutdown();
		return 0;
		} );
	}
