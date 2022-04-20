import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import std.random;
import std.conv;

import viewport;

// Graphical helper functions
//=============================================================================

/*
//inline this? or template...
void draw_target_dot(xy_pair xy)
	{
	draw_target_dot(xy.x, xy.y);
	}
*/
void draw_target_dot(float x, float y)
	{
	draw_target_dot(to!(int)(x), to!(int)(y));
	}

void draw_target_dot(int x, int y)
	{
	al_draw_pixel(x + 0.5, y + 0.5, al_map_rgb(0,1,0));

	immutable r = 2; //radius
	al_draw_rectangle(x - r + 0.5f, y - r + 0.5f, x + r + 0.5f, y + r + 0.5f, al_map_rgb(0,1,0), 1);
	}

/// For each call, this increments and returns a new Y coordinate for lower text.
int text_helper(bool do_reset)
	{
	static int number_of_entries = -1;
	
	number_of_entries++;
	immutable int text_height = 20;
	immutable int starting_height = 20;
	
	if(do_reset)number_of_entries = 0;
	
	return starting_height + text_height*number_of_entries;
	}


void draw_hp_bar(float x, float y, viewport_t v, float hp, float max)
	{
	float _x = x - v.ox + v.x;
	float _y = y - v.oy + v.y - 10;
	float _hp = hp/max*20.0;

	if(hp != max)
		al_draw_filled_rectangle(
			_x - 20/2, 
			_y, 
			_x + _hp/2, 
			_y + 5, 
			ALLEGRO_COLOR(1, 0, 0, 0.70));
	}



// Helper functions
//=============================================================================

bool percent(float chance)
	{
	return uniform!"[]"(0.0, 100.0) < chance;
	}

// can't remember the best name for this.
void clampUpper(T)(ref T val, T max)
	{
	if(val > max)
		{
		val = max;
		}
	}	

void clampLower(T)(ref T val, T min)
	{
	if(val < min)
		{
		val = min;
		}
	}	

void clampBoth(T)(ref T val, T min, T max)
	{
	if(val < min)
		{
		val = min;
		}
	if(val > max)
		{
		val = max;
		}
	}	

/// UFCS - Helper functions 
/// see https://www.allegro.cc/manual/5/al_get_font_line_height

/// Font Height = Ascent + Descent
int h(const ALLEGRO_FONT *f)
	{
	return al_get_font_line_height(f);
	}

/// Font Ascent
int a(const ALLEGRO_FONT *f)
	{
	return al_get_font_ascent(f);
	}

/// Font Descent
int d(const ALLEGRO_FONT *f)
	{
	return al_get_font_descent(f);
	}

//helper functions using universal function call syntax.
/// Return BITMAP width
int w(ALLEGRO_BITMAP *b)
	{
	return al_get_bitmap_width(b);
	}
	
/// Return BITMAP height
int h(ALLEGRO_BITMAP *b)
	{
	return al_get_bitmap_height(b);
	}

void cap(T)(ref T val, T low, T high)
	{
	if(val < low){val = low; return;}
	if(val > high){val = high; return;}
	}

// Cap and return value.
// better name for this? 
pure T cap_ret(T)(T val, T low, T high)
	{
	if(val < low){val = low; return val;}
	if(val > high){val = high; return val;}
	return val;
	}
