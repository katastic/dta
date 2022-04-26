/*
0 Grass
1 Wall/Ground
2 Water
3 Lava
4 Wood Road
5 Stone Road
6 REINFORCED WALL
*/

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.conv;
import std.random;

import helper;
import g;
import viewport;

class map_t
	{
	immutable uint w = 50;
	immutable uint h = 50;

	tile[w][h] data;
	
	this()
		{
		for(int i = 0; i < w; i++)
		for(int j = 0; j < h; j++)
			{
			if(percent(5))
				{
				data[i][j] = 9;
				}
			}
			
		for(ubyte i = 0; i < w; i++)
			{
			data[i][0] = i;
			}
		}
	
	void draw(viewport_t v, bool drawTopLayer) // so inefficient but it'll work for now.
		{
		long signed_start_i = cast(long) ((v.ox)/32.0)-1; //need signed to allow for negative
		long signed_start_j = cast(long) ((v.oy)/32.0)-1;
		uint start_i=0;
		uint start_j=0;
		uint end_i = cast(uint) ((v.w + v.ox + v.x)/32.0)+1; // v.ox should be negative shouldn't it??sd
		uint end_j = cast(uint) ((v.h + v.oy + v.y)/32.0)+1;

		if(signed_start_i < 0){start_i = 0;}else{start_i = to!uint(signed_start_i);}
		if(signed_start_j < 0){start_j = 0;}else{start_j = to!uint(signed_start_j);}
		if(end_i > w-1)end_i = w-1;
		if(end_j > h-1)end_j = h-1;
				
//		writeln("start:", start_i, "/", start_j, " offset", v.ox, "/" , v.oy, " = end: ", end_i, "/",end_j);				
		for(uint i = cast(uint) start_i; i < end_i; i++)
		for(uint j = cast(uint) start_j; j < end_j; j++)
			{
			if(data[i][j] == 0 && !drawTopLayer)
				{
				al_draw_bitmap(g.grass_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			if(data[i][j] == 1 && drawTopLayer)
				{
				al_draw_bitmap(g.wall_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			if(data[i][j] == 2 && drawTopLayer)
				{
				al_draw_bitmap(g.water_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			if(data[i][j] == 3 && !drawTopLayer)
				{
				al_draw_bitmap(g.lava_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			if(data[i][j] == 4 && !drawTopLayer)
				{
				al_draw_bitmap(g.wood_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			if(data[i][j] == 5 && !drawTopLayer)
				{
				al_draw_bitmap(g.stone_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			if(data[i][j] == 6 && drawTopLayer)
				{
				al_draw_bitmap(g.reinforced_wall_bmp, v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
				}
			stats.number_of_drawn_background_tiles++;
			}
		}

	void draw2(viewport_t v, bool drawTopLayer)
		{
		long signed_start_i = cast(long) ((v.ox)/32.0)-1; //need signed to allow for negative
		long signed_start_j = cast(long) ((v.oy)/32.0)-1;
		uint start_i=0;
		uint start_j=0;
		uint end_i = cast(uint) ((v.w + v.ox + v.x)/32.0)+1; // v.ox should be negative shouldn't it??sd
		uint end_j = cast(uint) ((v.h + v.oy + v.y)/32.0)+1;

		if(signed_start_i < 0){start_i = 0;}else{start_i = to!uint(signed_start_i);}
		if(signed_start_j < 0){start_j = 0;}else{start_j = to!uint(signed_start_j);}
		if(end_i > w-1)end_i = w-1;
		if(end_j > h-1)end_j = h-1;
				
//		writeln("start:", start_i, "/", start_j, " offset", v.ox, "/" , v.oy, " = end: ", end_i, "/",end_j);				
		for(uint i = cast(uint) start_i; i < end_i; i++)
		for(uint j = cast(uint) start_j; j < end_j; j++)
			{
			ubyte index = data[i][j];
			assert(index >= 0);
			al_draw_bitmap(g.atlas[index], v.x + i*32.0 - v.ox, v.y + j*32.0 - v.oy, 0);
			stats.number_of_drawn_background_tiles++;
			}
		}

	int frames_passed=0;
	
	void logic()
		{
		return;
//		if(frames_passed > 60){fluid_logic(); frames_passed=0;}
//		frames_passed++;
		}
		
	void fluid_logic() /// Called at different tick rate
		{
		auto old = data.dup;
		
		// NOTE, due to the order of precedence, lava "wins" against water if there's an available tile.
			
		// ideally we need to double-buffer/page flip the MAP
		// so we can make DECISIONS based on last frames map, and its EFFECTS apply 
		// the NEW frames map. Otherwise, we risk mutating WHILE we iterating and 
		// having changes cascade / explode.
		
		// note we're currently DUPLICATING the map every frame as opposed to flipping
		// so this is allocating every frame instead of swapping between two buffers (read: SLOW)

		/// spread fluid of [TYPE] out one tile into grass		
		void spread(ubyte TYPE)
			{
			for(int i = 0; i < w; i++)
				for(int j = 0; j < h; j++)
					{
					if(old[i][j] == TYPE)
						{
						if(i > 0 && old[i-1][j] == 0)
							{
							data[i-1][j] = TYPE;
							}
						if(j > 0 && old[i][j-1] == 0)
							{
							data[i][j-1] = TYPE;
							}
						if(i < w-1 && old[i+1][j] == 0)
							{
							data[i+1][j] = TYPE;
							}
						if(j < h-1 && old[i][j+1] == 0)
							{
							data[i][j+1] = TYPE;
							}
						}
					}
			}

		/// spread fluid of [TYPE] out one tile into grass, and occasionally "burn" wood bridges
		void spread_and_burn(ubyte TYPE) 
			{
			for(int i = 0; i < w; i++)
				for(int j = 0; j < h; j++)
					{
					if(old[i][j] == TYPE)
						{
						// Spread into grass:
						if(i > 0 && old[i-1][j] == 0)
							{
							data[i-1][j] = TYPE;
							}
						if(j > 0 && old[i][j-1] == 0)
							{
							data[i][j-1] = TYPE;
							}
						if(i < w-1 && old[i+1][j] == 0)
							{
							data[i+1][j] = TYPE;
							}
						if(j < h-1 && old[i][j+1] == 0)
							{
							data[i][j+1] = TYPE;
							}

						// Spread into wood (4):
						immutable float chance = 5.0; 
						//NOTE. THIS only fires off ONCE A SECOND. So it's 1/60th of the normal tick rate for percentages for the objects!
						if(i > 0 && old[i-1][j] == 4 && percent(chance))
							{
							data[i-1][j] = TYPE;
							}
						if(j > 0 && old[i][j-1] == 4 && percent(chance))
							{
							data[i][j-1] = TYPE;
							}
						if(i < w-1 && old[i+1][j] == 4 && percent(chance))
							{
							data[i+1][j] = TYPE;
							}
						if(j < h-1 && old[i][j+1] == 4 && percent(chance))
							{
							data[i][j+1] = TYPE;
							}
						}
					}
			}
			
		spread(2);
		spread_and_burn(3);	
		}
	}	
