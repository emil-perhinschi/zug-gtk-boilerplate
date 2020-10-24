module zug.frontend.gtk.EditorView;

// private import gsv.SourceMark;
// private import gsv.SourceStyleScheme;
// private import gsv.SourceUndoManagerIF;

import gsv.SourceView;
import gtk.ScrolledWindow;

//source https://gtkdcoding.com/2019/09/10/0069-textview-and-textbuffer.html
class ScrolledTextWindow : ScrolledWindow
{
	MySourceView mySourceView;
	
	this()
	{
		super();
		
		mySourceView = new MySourceView();
		add(mySourceView);
		
	} // this()
	
} // class ScrolledTextWindow


class MySourceView : SourceView
{
    import gsv.SourceBuffer;
    import gsv.SourceLanguageManager;
    import gsv.SourceLanguage;

	SourceBuffer sourceBuffer;
	string content = "I take exception to your code.";
	
	this()
	{
		super();
		this.sourceBuffer = getBuffer();
		this.sourceBuffer.setText(content);
        this.setShowLineNumbers(true);
        this.setInsertSpacesInsteadOfTabs(true);
        this.setTabWidth(4);
        this.setHighlightCurrentLine(true);

        SourceLanguageManager slm = new SourceLanguageManager();
        SourceLanguage source_language = slm.getLanguage("perl");

        if ( source_language !is null )
        {
            import std.stdio: writefln;
            this.sourceBuffer.setLanguage(source_language);
            this.sourceBuffer.setHighlightSyntax(true);
        }

        //sourceView.modifyFont("Courier", 9);
        this.setRightMarginPosition(72);
        this.setShowRightMargin(true);
        this.setAutoIndent(true);

	}

}
