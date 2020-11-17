/*

module zug.frontend.gtk.AnimatedDrawingArea;

import gtk.DrawingArea;
import zug.matrix;
import gdk.Pixbuf;

class WorldMap : DrawingArea
{
    import std.conv: to;

    import glib.Timeout;
    import cairo.Context;
    import gtk.Widget;

	Matrix!int raw_data;
	Pixbuf[2][16] tiles;

	Pixbuf rendered_map;

	int tile_size = 20;
	immutable size_t width = 64;
	immutable size_t height = 36;

    Timeout _timeout;
	int number = 1;
	int fps = 1000 / 30; // 30 frames per second

    this() {
		immutable int seed = 12_345_678;
		this.raw_data = generate_random_map_data(this.width, this.height, seed);
		writeln("generated random map data");
		this.tiles = init_tiles(this.tile_size);
		this.rendered_map = pre_render_map(this.raw_data, this.tile_size);
		writeln("initialized tiles");
		import std.traits;
		addOnDraw(&onDraw);
	} 
	
	bool onDraw(Scoped!Context context, Widget widget) {
		import std.stdio: writeln;
		if(_timeout is null) {
			_timeout = new Timeout(fps, &onFrameElapsed, false);
		}
		
		if(number > 24) {// number range: 1 - 24
			number = 1;
		}
		number++;

		writeln("drawing ");
		context.setSourcePixbuf(this.rendered_map, 0, 0);
		context.paint();
		return(true);
	} 


	bool onFrameElapsed()
	{
		queueDraw();
		return(true);
	} 
}

*/