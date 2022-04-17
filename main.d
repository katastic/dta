/*

		

	Look at bosses from METAL SLUG etc





	maps are mostly hand made. maybe we can cookie-cutter them like Diablo. 
	We could add "themes" / mutators to existing map areas. 
		Long path + [Undead] modifier + [High level] modifier
		
	weather effects? not just pretty. like magica: 
		- RAIN has modifiers
			- Platemail lower resist to lightning (both natural and magic)
		- snow?


	Moves:
		- Walk
		- Sprint
		- Dodge 
		- Jump/Leap forward (dodge when not pressing a direction is also jump?)
		- Block
		- Attack [different attack types?]
		- Cast magic
		- Use item
		- Use inventory

		-> Do we have STAMINA? Secret of Mana charge up attacks? Or reducing stamina like more 
		modern games
		-> Can you HOLD attack to do something different than pressing? (like SOM)



	[magic]
		 in SoM each magic type has a "mana spirit" and a series of spells associated with that spirit. kind a neat way
		 to do it other than the tried-and-old "light/dark/fire/water/lightning" by putting a face on that spirit.


	We could basically be fighting all the KNIGHTS of King Arthur as well as MERLIN (and his associates/underlings)
	
		https://en.wikipedia.org/wiki/Knights_of_the_Round_Table
		holy shit theres TONS OF THESE GUYS
			Lancelot - Uses lance?
			
-->		KILL THE LADY OF THE LAKE.
		
	[KNIGHTS OF THE ROUND]
		Yvain - has a pet LION
		

	[ENEMY attacks]
		- Standard: 
			- Stabbing spear
			- Swinging sword
			- Vertical hammer [basically same as spear but no long zone].
			- Shield bash [no to light damage, pushes you back, maybe stuns]
			- Charges up to do one of these ^	
	
		- Think [Vampire Survivors] but the enemy has the weapons]
		- TOUCH: Touching the enemy does damage
		- THORNS: Attacking the enemy with melee does damage
		- AURA: Getting within a radius does damage.
		- WAVE: Wave of fire, wave of rocks, whatever. Straight line wave attack.
		- CIRCLE: radiating circle that spins out.
		- METEOR: A blast hits the ground in a random spot, like a meteor
		- BEAM:  long beams from the enemy or outside the enemy
		- OFF-SCREEN-BASED a wave/line that goes from the outside of the world inward [left of screen to right].
		- floor damage: (like meteor) but could last longer / permenant. Like the sections of Eye boss in Heroes of hammerwatch.
		- Big "run away" boss that is eating. Screen wide, inside a canyon.
	
		- At one point you GO INSIDE A DUNE WORM and fight through the other things its eaten (like other guys/knights/enemies)
		- Boss that runs at you. Whether it's a RAM or a lanceelot horse.
		- Bosses that are mobile and jump away into distinct sections.
		- Send "spikes" from the ground upward [see meteor]
		- Bosses that raise undead
		- BIG BOSSES that have TARGETABLE LIMBS [just like SOM, SOE, CTrigger] for different strategies
			- healer drones
			- maybe not make a single meta the only meta ['always target the drones first']
		- Large mechanical device boss [dwarven?]
		- Dragon(s)
		- A tiny rabbit
		- "sadness" [earthbound] "I'm attacking the darkness!"
		
		- MULTI WEAPON boss puzzles (better make weapon swapping easy then! L/R on controller)
			- e.g. "use whip to get on top of mechanical boss, then use spear weapon to attack through armor plate"
			- Support putting only specific weapons on the quick bar (even if you have more)
				- that is: ready the 3 weapons you care about while still carrying the rest.
	
		- buddies with special attacks:
			- Birds that just attack
			- Birds that flock during an attack phase and then swarm at the player from one side
			 to another.
		

		- Arrows. Slightly/heavily magically enhanced tracking arrows.


		- A line extends out and rotates (Binding of Isaac 'It Lives!')
		- See [Heroes of Hammerwatch] bosses/enemies

	[weapons]
		- sword [+ shield]
		- two handed sword [longer reach more damage, harder block, slower]
		- whip? boomerang? bow?
		- magic? Make magic available for everyone so there's no 'mage' class. Just paladins. Warriors with small amounts of magic.
		- robinhoodian quartar staff?

	[armor]
		- wear robes to reduce water damage to armor? 
		- change robes to hide identity from [[COPS]]?
		- benefits of light vs heavy armor? Easier dodge for more blocking?

	[attack caravans]
		- dudes outside
		- new guys spilling out (and/or reinforcements offscreen if you take too long)
		- miniboss 'hero' with magic attacks

	[attack other things?]
		[travelling merchants that aren't caravans?]
		[tiers of caravans based on defenses]
		- 1 dude alone [occasionally a rare/legendary, miniboss dude walking by himself. DARE YE TEMPT FATE?]
		- 2 dudes
		- 3 dudes
		- 4 dudes
		- 5 dudes
		- 1 wagon alone
		- 1 wagon + X footmen
		- 1 wagon + X mounted knights
		- 2 wagons + ???
		The more wagons you hit, the more the POLICE (I mean sheriffs guards) will be after you!

		
	defend caravans? annoying? can you send your own caravans to do stuff? can rival players attack them?
		- RIVAL gangs. not just coop but verses?
		
	 - we could have "pets" that help fight but if you have say a dog, people will have their dog die.
	 - also units don't die but go unconscious so you're not starting leveling your dudes everytime
	 - 	also if we're talking VERSES gameplay, we don't want the game to be a "grind to outlevel the
	 enemy because the first time you lose then the other player has more XP/resources forever
	  and its over."


	Secret of Mana
	Chrono Trigger
		- Most level data is either a level warp [house, map edge trigger],
			a solid, or passable terrain plus a list of enemies (that respawn if offscreen)
		- occasional script triggers [just simple lua stuff for us]
		
		- units walking around, for towns:
			- isFriendly/isNeutral = true;
			- hasScript = true; 
			- runs luascript for onUse/onTalk();  and optionally onAttack();
		
		- MAP LAYERS
			- ground
			- tree / overhang layer
		
		- Sellers/dealers (the cat dude)
		- Houses
		

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
ALLEGRO_TIMER *fps_timer;
ALLEGRO_TIMER *screencap_timer;
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

	al_display = al_create_display(g.SCREEN_W, g.SCREEN_H);
	queue	= al_create_event_queue();

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
/*
	viewports[1] = new viewport_t;
	viewports[1].x = g.SCREEN_W/2;
	viewports[1].y = 0;
	viewports[1].w  = g.SCREEN_W/2;//[ - 1;
	viewports[1].h = g.SCREEN_H;
	viewports[1].ox = 0;
	viewports[1].oy = 0;
*/
	assert(viewports[0] !is null);
	
	// FPS Handling
	// --------------------------------------------------------
	fps_timer = al_create_timer(1.0f);
	screencap_timer = al_create_timer(7.5f);
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
			al_clear_to_color(ALLEGRO_COLOR(.7, .7, .7, 1));
		
		world.draw(viewports[0]);
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

if(stats.fps != 0)			al_draw_textf(g.font, ALLEGRO_COLOR(0, 0, 0, 1), 20, text_helper(false), ALLEGRO_ALIGN_LEFT, "fps[%d] objrate[%d]", stats.fps, 
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
		al_draw_textf(g.font, ALLEGRO_COLOR(0, 0, 0, 1), mouse_x, mouse_y - 30, ALLEGRO_ALIGN_CENTER, "mouse [%d, %d]", mouse_x, mouse_y);
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
					isKeySet(ALLEGRO_KEY_SPACE, key_space_down);
					isKeySet(ALLEGRO_KEY_Q, key_q_down);
					isKeySet(ALLEGRO_KEY_W, key_w_down);
					isKeySet(ALLEGRO_KEY_S, key_s_down);
					isKeySet(ALLEGRO_KEY_A, key_a_down);
					isKeySet(ALLEGRO_KEY_D, key_d_down);

					isKeySet(ALLEGRO_KEY_ESCAPE, exit);
					break;
					}
					
				case ALLEGRO_EVENT_KEY_UP:				
					{
					isKeyRel(ALLEGRO_KEY_SPACE, key_space_down);
					isKeyRel(ALLEGRO_KEY_Q, key_q_down);
					isKeyRel(ALLEGRO_KEY_W, key_w_down);
					isKeyRel(ALLEGRO_KEY_S, key_s_down);
					isKeyRel(ALLEGRO_KEY_A, key_a_down);
					isKeyRel(ALLEGRO_KEY_D, key_d_down);

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
					ulong px = to!ulong(mouse_x + viewports[0].ox)/32;
					ulong py = to!ulong(mouse_y + viewports[0].oy)/32;
					if(event.mouse.button == 1)
						{
						mouse_lmb = true;
//						world.map.data[px][py] = 0;
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

						// do something once per second.

						// n/t
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
