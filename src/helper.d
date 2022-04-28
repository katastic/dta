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

bool isInsideScreen(float x, float y, viewport_t v) /// For bitmap culling. Is this point inside the screen?
	{
	if(x > 0 && x < v.w && y > 0 && y < v.h)
		{return true;} else{ return false;}
	}

bool isWideInsideScreen(float x, float y, ALLEGRO_BITMAP* b, viewport_t v) /// Same as above but includes a bitmaps width/height instead of a single point
	{
	if(x >= -b.w/2 && x - b.w/2 < v.w && y - b.h/2 >= -b.w/2 && y < v.h)
		{return true;} else{ return false;} //fixme
	}

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
	float _x = x;
	float _y = y - 10;
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

// can't remember the best name for this. How about clampToMax? <-----
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

// <------------ Duplicates??
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

/// Same as al_draw_bitmap but center the sprite
/// we can also chop off the last item.
/// we could also throw an assert!null in here but maybe not for performance reasons.
void al_draw_centered_bitmap(ALLEGRO_BITMAP* b, float x, float y, int flags=0)
	{
	al_draw_bitmap(b, x - b.w/2, y - b.h/2, flags);
	}
	
/// Set texture target back to normal (the screen)
void al_reset_target() 
	{
	al_set_target_backbuffer(al_get_current_display());
	}
	
void al_draw_scaled_bitmap2(ALLEGRO_BITMAP *bitmap, float x, float y, float scaleX, float scaleY, int flags=0)
	{
	al_draw_scaled_bitmap(bitmap, 0, 0, bitmap.w, bitmap.h, x, y, bitmap.w * scaleX, bitmap.w * scaleY, flags);
	}


// you know, we could do some sort of scoped lambda like thing that auto resets the target
/*
	DAllegro might already have that somewhere...
	
	foo();
	al_target(my_bitmap)
		{
		al_clear_to_color(...);
		al_draw_filled_rectangle(...);
		} // calls al_reset_target at end
	bar();

	al_target would be a class
		this

*/
//ALLEGRO_BITMAP* target, 

void al_target2(ALLEGRO_BITMAP* target, scope void delegate() func)
	{
	al_set_target_bitmap(target);
	func();
	al_reset_target();
	}
	
import std.stdio;
void test2()
	{
	ALLEGRO_BITMAP* bmp;
	al_target2(bmp, { al_draw_pixel(5, 5, ALLEGRO_COLOR(1,1,1,1)); });
	}

struct al_target()
	{
	this(ALLEGRO_BITMAP* target)
		{
		al_set_target(target);
		}
		
		//wheres the middle???
		
	~this()
		{
		al_reset_target();
		}
	}

/// Print variablename = value
/// usage because of D oddness:    
/// writeval(var.stringof, var);
void writeval(T)(string x, T y) 
	{
	writeln(x, " = ", y);
	}
