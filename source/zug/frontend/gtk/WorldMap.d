module zug.frontend.gtk.WorldMap;


import gtk.DrawingArea;
import gtk.ScrolledWindow;
import gdk.Pixbuf;
import cairo.Context;
import cairo.ImageSurface;
import gdk.Cairo;
import cairo.Surface;

import zug.pixmap_util;
import zug.matrix;

///DEBUG
import std.stdio: writeln;

//source https://gtkdcoding.com/2019/09/10/0069-textview-and-textbuffer.html
class WorldMapContainer : ScrolledWindow
{
    import gtk.Widget;

	WorldMap world_map;
	
	this()
	{
		world_map = new WorldMap();
		this.add(world_map);
	}
	
}


class WorldMap : DrawingArea
{
    import std.conv: to;

    import glib.Timeout;
    import cairo.Context;
    import gtk.Widget;

	Pixbuf pixel_buff;
    Timeout _timeout;
	int number = 1;
	int fps = 1000 / 24; // 24 frames per second

    this() {
		immutable int seed = 12_345_678;
		immutable size_t height = 720;
		immutable size_t width = 1280;

		Matrix!int raw_data = build_noise_map(width, height, seed);
		
		// duplicate the original pixels into r,g,b values + 0 for alpha
		// Matrix!(DataPoint!ubyte) point_data = raw_data.data.apply_filter!(DataPoint!ubyte)(a => DataPoint(a,a,a,0)) ;
		this.pixel_buff = raw_data.to_pixbuf();
		addOnDraw(&onDraw);
	} 
	

	bool onDraw(Scoped!Context context, Widget w) {
		import std.stdio: writeln;

		writeln("drawing");
		context.setSourcePixbuf(pixel_buff, 0,0);
		context.paint();
		return true;
	}

	/// how to show image
	// bool onDraw(Scoped!Context context, Widget w) {
	// 	import zug.pixmap_util;
	// 	Pixbuf pixbuf = new Pixbuf("/home/emil/safedelete/canvas.png");
	// 	context.setSourcePixbuf(pixbuf, 0,0);
	// 	context.paint();
	// 	return true;
	// }

	/// how to animate stuff
	bool onDraw(Scoped!Context context, Widget w) {
		if(_timeout is null) {
			_timeout = new Timeout(fps, &onFrameElapsed, false);
		}
		
		context.selectFontFace("Arial", CairoFontSlant.NORMAL, CairoFontWeight.NORMAL);
		context.setFontSize(35);
		context.setSourceRgb(0.0, 0.0, 1.0);
		context.moveTo(150, 150); // bottom right corner
		
		if(number > 24) {// number range: 1 - 24
			number = 1;
		}

		context.showText(number.to!string());
		number++;

		return(true);
	} 


	bool onFrameElapsed()
	{
		queueDraw();
		return(true);
	} 
}

///
Matrix!int build_noise_map(size_t width, size_t height, int seed) {
	import std.math: sqrt;

	// size_t final_length = height*width;

	size_t elevation_layer_height = 5; 
	size_t elevation_layer_width = 5;
	size_t noise_layer_height = 300;
	size_t noise_layer_width = 300;

    int[] data = random_array!int(elevation_layer_height*elevation_layer_width, 0, 128, seed);
	writeln(data.length);
    Matrix!int random_mask = Matrix!int( random_array!int(noise_layer_height*noise_layer_width, 0, 128, seed), noise_layer_width);
	writeln(random_mask.data_length);
    size_t window_size = 4;
	float stretch_height_coeficient = cast(float)height/cast(float)noise_layer_height;
	float stretch_width_coeficient = cast(float)width/cast(float)noise_layer_width;
	writeln("stretch: height: ", stretch_height_coeficient, " width: ", stretch_width_coeficient);
    return Matrix!int(data, elevation_layer_width)
		.stretch_bilinear(60,60)
		.add(random_mask)
		.moving_average!(int,int)(window_size, &shaper_circle!int, &moving_average_simple_calculator!(int, int))
		.stretch_bilinear(stretch_width_coeficient, stretch_height_coeficient)
		// .stretch_bilinear(height, width);
		;
}


Pixbuf to_pixbuf(Matrix!int matrix) {
    import std.conv : to;
	import std.algorithm: map;
	import std.array: array;
	import std.stdio: writeln;
	import std.array: join;
	char[] points = matrix.data.map!(a => cast(char[]) [a, a, a, 255]).array.join;
	// writeln("points: ", points);
	// Matrix!(DataPoint!int) points_matrix = Matrix!(DataPoint!int)(points, matrix.width);

    return new Pixbuf(
            points,
            GdkColorspace.RGB,
            true, // has alpha
            8, // color depth
            matrix.width.to!int, 
			matrix.height.to!int,
            (matrix.width * 4).to!int, // rowstride: how many bytes is the length of a row of RGBA pixels
            null, null // cleanup functions
    );
}