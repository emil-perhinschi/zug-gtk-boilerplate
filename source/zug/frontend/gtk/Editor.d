module zug.frontend.gtk.Editor;

// private import gsv.SourceMark;
// private import gsv.SourceStyleScheme;
// private import gsv.SourceUndoManagerIF;

import gsv.SourceView;
import gtk.ScrolledWindow;

//source https://gtkdcoding.com/2019/09/10/0069-textview-and-textbuffer.html
class Editor : ScrolledWindow
{
	MySourceView source_view;
	
	this(string file_path = "")
	{
		super();
		
		source_view = new MySourceView(file_path);
		add(source_view);
		
	}

    string get_current_content() {
        return this.source_view.source_buffer.getText();
    }
	
}


class MySourceView : SourceView
{
    import gsv.SourceBuffer;
    import gsv.SourceLanguageManager;
    import gsv.SourceLanguage;

	SourceBuffer source_buffer;
    string file_path = "";
	string content = "";
	
	this( string file_path = "")
	{
        // I'm confused from where is readText taken, so static so I know
        static import std.file;

		super();
		this.source_buffer = this.getBuffer();
        if (file_path != "") {
            this.content = std.file.readText(file_path);
            import std.stdio: writeln;
            writeln(this.content);
            this.source_buffer.setText(this.content);
            this.file_path = file_path;
        } else {
		    this.source_buffer.setText(this.content);
        }

        this.setShowLineNumbers(false);
        this.setInsertSpacesInsteadOfTabs(true);
        this.setTabWidth(4);
        this.setHighlightCurrentLine(false);

        SourceLanguageManager slm = new SourceLanguageManager();
        SourceLanguage source_language = slm.getLanguage("d");

        if ( source_language !is null )
        {
            this.source_buffer.setLanguage(source_language);
            this.source_buffer.setHighlightSyntax(true);
        }

        //sourceView.modifyFont("Courier", 9);
        // this.setRightMarginPosition(72);
        // this.setShowRightMargin(true);
        this.setAutoIndent(true);
	}

}
