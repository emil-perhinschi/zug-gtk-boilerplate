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

	Matrix!int raw_data;
	Pixbuf[][] tiles;
	Pixbuf background;
	int tile_size = 40;
	immutable size_t width = 32;
	immutable size_t height = 18;

    Timeout _timeout;
	int number = 1;
	int fps = 1000 / 3; // 12 frames per second

    this() {
		immutable int seed = 12_345_678;
		this.raw_data = generate_random_map_data(this.width, this.height, seed);
		writeln("generated random map data");
		this.tiles = init_tiles(this.tile_size);
		writeln("initialized tiles");
		this.background = new Pixbuf(
			GdkColorspace.RGB, // GdkColorspace colorspace
			true, // bool hasAlpha
			8,  // int bitsPerSample
			this.tile_size, // int width
			this.tile_size  // int height
		);
		this.background.fill(0x0000ffff);
		addOnDraw(&onDraw);
	} 
	

	/// how to show image
	// bool onDraw(Scoped!Context context, Widget w) {
	// 	import zug.pixmap_util;
	// 	Pixbuf pixbuf = new Pixbuf("temp/assets/static/sprites//home/emil/safedelete/canvas.png");
	// 	context.setSourcePixbuf(pixbuf, 0,0);
	// 	context.paint();
	// 	return true;
	// }

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
		for (size_t y = 0; y < this.height; y++) {
			for (size_t x = 0; x < this.width; x++) {
				int value = this.raw_data.get(x,y);
				Pixbuf tile = this.tiles[value][0].copy();
				Pixbuf tile_background = this.background.copy();
				writeln("back width: ", tile_background.getWidth);
				writeln("tile width: ", tile.getWidth);
				tile.composite(
					tile_background, //Pixbuf dest
					0, 0, // int destX, int destY,
					this.tile_size, // int destWidth
					this.tile_size, // int destHeight
					0, 0, // double offsetX, double offsetY
					1, 1, // double scaleX, double scaleY
					GdkInterpType.NEAREST, // GdkInterpType interpType
					255 // int overallAlpha
				);
				context.setSourcePixbuf(tile_background, x*this.tile_size, y*this.tile_size);
				context.paint();
			}
		}
		
		
		return(true);
	} 


	bool onFrameElapsed()
	{
		queueDraw();
		return(true);
	} 
}

/// width and height in tiles, size of tile in pixels
Matrix!int generate_random_map_data(size_t width, size_t height, int seed) {
	import std.random: Random, unpredictableSeed, uniform;
	auto rnd = Random(seed);

	/* TODO later
	  - draw empty canvas
	  - create several regions of random sizes (TODO: and shapes ) in random positions
	  - create elevation lines in each region
	  - add the regoins to the empty canvas
	  - create a noise layer
	  - add the noise layer to the empty canvas
	*/
	Matrix!int elevation = Matrix!int(width, height);
	int mountains_no = 5;
	int added_mountains = 0;
	while (added_mountains <= mountains_no) {
		// check if too close to the edge
		int distance_to_edge = 5;

		size_t x = uniform(0,width, rnd);
		if (
			x < distance_to_edge 
			|| x > width - distance_to_edge 
		) { continue; }

		size_t y = uniform(0,height, rnd);
		if (
			y < distance_to_edge 
			|| y > height - distance_to_edge
		) { continue; }

		int value = uniform(128,255, rnd);
		elevation.set(x,y,value);

		added_mountains++;
	}

    Matrix!int random_mask = Matrix!int( random_array!int(width*height, 0, 64, seed), width);
	int smoothing_window_size = 4;
	return elevation.add(random_mask)
		.moving_average!(int,int)(smoothing_window_size, &shaper_circle!int, &moving_average_simple_calculator!(int, int))
		.normalize(0,8);
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


Pixbuf[][] init_tiles(int tile_size) {
    import gdk.Pixbuf;

	Pixbuf sea = new Pixbuf(GdkColorspace.RGB,true, 8, 20,20);
	sea.fill(0x17577eff);
	Pixbuf unseen_sea = new Pixbuf(GdkColorspace.RGB,true, 8, 20,20);
	unseen_sea.fill(0x3380ffff);

    Pixbuf[][] tiles = [
		[
			sea,
			unseen_sea
		],
        [ 
            new Pixbuf("temp/assets/static/sprites/swamp_1_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/swamp_1.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/swamp_2_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/swamp_2.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/swamp_3_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/swamp_3.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/forest_1_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/forest_1.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/forest_2_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/forest_2.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/forest_3_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/forest_3.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/lowlands_forest_topdown_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/lowlands_forest_topdown.png",tile_size, tile_size, true)
        ],
        [
            new Pixbuf("temp/assets/static/sprites/lowlands_forest_topdown_tileable_dark.png",tile_size, tile_size, true),
            new Pixbuf("temp/assets/static/sprites/lowlands_forest_topdown_tileable.png",tile_size, tile_size, true)
        ]
    ];
	return tiles;
}


// const map_palette_init = [
//     [ 23,  87, 126], //"#17577e"
//     [ 61, 108,  66], //"#3d6c42"
//     [ 63, 110,  66], //"#3f6e42"
//     [ 71, 115,  64], //"#477340"
//     [ 82, 123,  62], //"#527b3e"
//     [ 97, 133,  59], //"#61853b"
//     [114, 144,  56], //"#729038"
//     [143, 164,  51], //"#8fa433"
//     [175, 186,  45], //"#afba2d"
//     [184, 192,  43], //"#b8c02b"
//     [169, 166,  42], //"#a9a62a"
//     [141, 115,  41], //"#8d7329"
//     [117,  71,  39], //"#754727"
//     [107,  53,  39], //"#6b3527"
//     [131,  86,  74], //"#83564a"
//     [195, 173, 167]  //"#c3ada7"
// ]