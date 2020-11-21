module zug.frontend.gtk.WorldMap;


import gtk.DrawingArea;

import gdk.Pixbuf;
import cairo.Context;
import cairo.ImageSurface;
import gdk.Cairo;
import cairo.Surface;
import gtk.Box;

import zug.pixmap_util;
import zug.matrix;

///DEBUG
import std.stdio: writeln;

class WorldData {
    CartesianMatrix!int data;
    this(CartesianMatrix!int data ) { this.data = data; }

    this(int width, int height, int seed) {
        Matrix!int raw_heightmap = generate_random_map_data(width, height, seed);
        this.data = CartesianMatrix!int(raw_heightmap.data, width, Offset(width/2, height/2));
    }

    Matrix!int get(long top_x, long top_y, size_t width, size_t height) {
        return this.data.window(CartesianCoordinates(top_x, top_y), width, height);
    }
}

//source https://gtkdcoding.com/2019/09/10/0069-textview-and-textbuffer.html
class WorldMapContainer : Box
{
    // import gtk.Widget;

	WorldMap world_map;
    WorldData world_data;

	this()
	{
        import gtk.VPaned;
        import gtk.Entry;
        import gtk.Label;

        super(Orientation.HORIZONTAL, 5);

        Box map_box = new Box(Orientation.HORIZONTAL, 5);
        map_box.setBorderWidth(5);
        
        // this.packStart(map_box, true, true, 0);
        this.packStart(map_box, true, true, 0);

		this.world_data = new WorldData(300,300, 123_456_789);

        // world_map.setSizeRequest(1200,720);
        Box controls_box = new Box(Orientation.VERTICAL,0);
        controls_box.setBorderWidth(2);
        controls_box.setSizeRequest(300,700);
        Box entry_box = new Box(Orientation.HORIZONTAL, 0);
        Label label = new Label("width");
        Entry entry = new Entry();
        entry.setText("this is an entry");
        entry_box.packStart(label, false, false, 0);
        entry_box.packEnd(entry, true, true, 0);
        controls_box.packStart(entry_box, false, false, 0);
        this.world_map = new WorldMap(this.world_data.get(0,0, 64,36));
		map_box.packStart(this.world_map, true, true, 5);
        map_box.packStart(controls_box, false, true, 5);
	}
	
}



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

    this(Matrix!int raw_data) {
		immutable int seed = 12_345_678;
		this.raw_data = raw_data;
		writeln("generated random map data");
		this.tiles = init_tiles(this.tile_size);
		this.rendered_map = pre_render_map(this.raw_data, this.tile_size);
		writeln("initialized tiles");
		addOnDraw(&onDraw);
	} 
	
	bool onDraw(Scoped!Context context, Widget widget) {
		import std.stdio: writeln;
	
		if(number > 24) {// number range: 1 - 24
			number = 1;
		}
		number++;

		writeln("drawing ");
		context.setSourcePixbuf(this.rendered_map, 0, 0);
		context.paint();
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
    size_t elevation_width = width/2;
    size_t elevation_height = height/2;
	Matrix!int elevation = Matrix!int(elevation_width, elevation_height);
	int mountains_no = 3;
	int added_mountains = 0;
	while (added_mountains <= mountains_no) {
		// should not be too close to the edge
		int distance_to_edge = 3;

		size_t x = uniform(distance_to_edge, elevation_width - distance_to_edge, rnd);
		size_t y = uniform(distance_to_edge, elevation_height - distance_to_edge, rnd);
		
        int value = uniform(128,255, rnd);
        debug writeln("mountain coordinates x: ", x, ", y: ", y, ", value: ", value);
		elevation.set(x,y,value);
		added_mountains++;
	}

    Matrix!int random_mask = Matrix!int( random_array!int(elevation_width*elevation_height, 0, 15, seed), elevation_width);
	int smoothing_window_size = 4;
	return elevation
        .add(random_mask)
        .stretch_bilinear(2,2)
        .moving_average!(int,int)(smoothing_window_size, &shaper_circle!int, &moving_average_simple_calculator!(int, int))
		.normalize!int(0,15);
}

// TODO make the edges be water and randomize a bit so they're not square

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


Pixbuf pre_render_map(Matrix!int raw_data, int tile_size) {
	import gdk.Pixbuf;

	Pixbuf[2][16] tiles = init_tiles(tile_size);
	int width = cast(int) raw_data.width * tile_size;
	int height = cast(int) raw_data.height * tile_size;
	Pixbuf rendered_map = new Pixbuf(GdkColorspace.RGB, true, 8, width, height);

	for (int y = 0; y < raw_data.height; y++) {
		for (int x = 0; x < raw_data.width; x++) {
			int value = raw_data.get(x,y);
			Pixbuf tile = tiles[value][1];
			int dest_x = x * tile_size;
			int dest_y = y * tile_size;
			tile.copyArea(0, 0, tile_size, tile_size, rendered_map, dest_x, dest_y);
		}
	}
	return rendered_map;
}


Pixbuf[2][16] init_tiles(int tile_size) {
    import gdk.Pixbuf;

	// Pixbuf sea = new Pixbuf(GdkColorspace.RGB,true, 8, 20,20);
	// sea.fill(0x17577eff);
	// Pixbuf unseen_sea = new Pixbuf(GdkColorspace.RGB,true, 8, 20,20);
	// unseen_sea.fill(0x3380ffff);

    Pixbuf[][] tiles = [ [],
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
        ], [],[],[],[],[],[],[],[]
    ];

	auto palette = map_palette_init(tile_size);
	Pixbuf[2][16] tiles_with_background;
	for (size_t i = 0; i < palette.length; i++) {
		writeln("i is: ", i, " length is : ", tiles[i].length);
		if (tiles[i].length == 2) { // tiles[] element looks like expected
			// copy because composite below changes it
			Pixbuf foreground_tile = tiles[i][1].copy;
			Pixbuf background_tile = palette[i];
			// the result is "dest" 
			foreground_tile.composite(
				background_tile, //Pixbuf dest
				0, 0, // int destX, int destY,
				tile_size, // int destWidth
				tile_size, // int destHeight
				0, 0, // double offsetX, double offsetY
				1, 1, // double scaleX, double scaleY
				GdkInterpType.NEAREST, // GdkInterpType interpType
				255 // int overallAlpha
			);

			tiles_with_background[i][0] = background_tile.copy;
			tiles_with_background[i][1] = background_tile.copy;
		} else { // no more tiles, only backgrounds 
			tiles_with_background[i][0] = palette[i].copy;
			tiles_with_background[i][1] = palette[i].copy;
		}
	}

	return tiles_with_background;
}

Pixbuf[16] map_palette_init(int tile_size) {
	import std.algorithm: map;
	import std.array: array;
	import gdk.Pixbuf;

	uint[] colors = [
		0x17577eff, //     [ 23,  87, 126],
		0x3d6c42ff, //     [ 61, 108,  66],
		0x3f6e42ff, //     [ 63, 110,  66],
		0x477340ff, //     [ 71, 115,  64],
		0x527b3eff, //     [ 82, 123,  62],
		0x61853bff, //     [ 97, 133,  59],
		0x729038ff, //     [114, 144,  56],
		0x8fa433ff, //     [143, 164,  51],
		0xafba2dff, //     [175, 186,  45],
		0xb8c02bff, //     [184, 192,  43],
		0xa9a62aff, //     [169, 166,  42],
		0x8d7329ff, //     [141, 115,  41],
		0x754727ff, //     [117,  71,  39],
		0x6b3527ff, //     [107,  53,  39],
		0x83564aff, //     [131,  86,  74],
		0xc3ada7ff //     [195, 173, 167] 
	];

	Pixbuf[16] palette = colors.map!( rgba => make_pixbuf_from_rgba(rgba, tile_size) ).array;
	return palette;
}

Pixbuf make_pixbuf_from_rgba(uint rgba, int tile_size) {
	import gdk.Pixbuf;

	bool has_alpha = true;
	int bits_per_sample = 8;
	Pixbuf pixbuf = new Pixbuf( GdkColorspace.RGB, has_alpha, bits_per_sample, tile_size, tile_size );
	pixbuf.fill(rgba);
	return pixbuf;
}