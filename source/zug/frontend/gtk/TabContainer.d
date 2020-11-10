module zug.frontend.gtk.TabContainer;

import gtk.Notebook;
import gsv.SourceView;
import gtk.Label;

import zug.frontend.gtk.Editor;

//DEBUG
import std.stdio: writeln;

class TabContainer : Notebook
{
	PositionType tabPosition = PositionType.TOP;

	Editor[] tabs;
	
	this()
	{
		super();
		setTabPos(tabPosition);

        Label tab_label = new Label("Untitled");
		Editor editor = new Editor();
        editor.source_view.source_buffer = editor.source_view.getBuffer();
        editor.source_view.source_buffer.setText(" placeholder text ");
		this.appendPage(editor, tab_label);
        // TODO: if there is a list of tabs saved use it to load, else show default tab
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

