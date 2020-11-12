module zug.frontend.gtk.TabContainer;

import gtk.Notebook;
import gsv.SourceView;
import gtk.Label;

import zug.frontend.gtk.Editor;
import zug.frontend.gtk.WorldMap;

//DEBUG
import std.stdio: writeln;

class TabContainer : Notebook
{
    import gtk.ScrolledWindow;

	PositionType tabPosition = PositionType.TOP;

	// ScrolledWindow[] tabs;
	
	this()
	{
		super();
		setTabPos(tabPosition);

        WorldMapContainer world_map_container = new WorldMapContainer();
        this.appendPage(world_map_container, new Label("World Map"));
        // TODO: if there is a list of tabs saved use it to load, else show default tab

        Label tab_label = new Label("Untitled");
		Editor editor = new Editor();
        editor.source_view.source_buffer = editor.source_view.getBuffer();
        editor.source_view.source_buffer.setText(" placeholder text ");
		this.appendPage(editor, tab_label);
     
    }

    void add_new_code_tab(string label,  string file_path) {
        import std.file: readText;

        writeln(" adding new tab");

		Label tab_label = new Label(label);
		Editor editor = new Editor(file_path);
		editor.showAll();

        auto new_tab_index = this.appendPage(editor, tab_label);
        
        writeln("currrrrrrrrrrrrrrrrrrrrrent page: ", this.getCurrentPage());
        this.setCurrentPage(new_tab_index);
    }
}

