import g;
import map;
import viewport;
import helper;

import allegro5.allegro;
import allegro5.allegro_image;

import std.random;

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
