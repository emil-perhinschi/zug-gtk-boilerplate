module zug.frontend.gtk.mainWindow;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gdk.Event;
import gtk.Button;
import gtk.Menu;
import gtk.MenuBar;
import gtk.MenuItem;
import gtk.Box;
import std.typecons;
import gsv.SourceView;
import gtk.ScrolledWindow;
import gtk.TextBuffer;

class AppMainWindow : MainWindow
{
    string title = "Test main window";
    Box mainViewport;
    ScrolledTextWindow editor_window;
    this() 
    {
        super(title);
        setDefaultSize(500, 300);
        addOnDestroy( (Widget w) => this.quitApp() );

        Box mainBox = new Box(Orientation.VERTICAL, 10);         
        this.add(mainBox);

        buildMenus(mainBox);
        

        this.mainViewport = new Box(Orientation.VERTICAL, 10);
        bool expand = true;
        bool fill = true;
        uint padding = 0;
        mainBox.packStart(this.mainViewport, expand, fill, padding);

        this.editor_window = new ScrolledTextWindow();
	this.mainViewport.packStart(editor_window, expand, fill, padding); 

        Button button = new Button("Show size");
        button.addOnClicked(delegate void(Button b) { this.showSize(b); });
        mainBox.add(button);


        sayHi();
        showAll();
    }

    void buildMenus(Box mainBox) {

        MenuBar menuBar = new MenuBar();
        mainBox.packStart(menuBar, false, false, 0);

        // _File menu
        MenuItem fileMenuHeader = new MenuItem("_File", true);// true: shortcuts enabled
        menuBar.append(fileMenuHeader);

        Menu fileMenu = new Menu();
        fileMenuHeader.setSubmenu(fileMenu);

        MenuItem itemLoad = new MenuItem("_Load", true); 
        itemLoad.addOnActivate( (MenuItem m) => sayHi("load ..." ) );
        fileMenu.append(itemLoad);

        MenuItem itemSave = new MenuItem("_Save", true); // true: shortcuts enabled
        itemSave.addOnActivate( (MenuItem m) => sayHi("save ..." ) );
        fileMenu.append(itemSave);

        MenuItem itemConfiguration = new MenuItem("_Configuration", true); // true: shortcuts enabled
        itemConfiguration.addOnActivate( (MenuItem m) => sayHi("configuration ..." ) );
        fileMenu.append(itemConfiguration);

        MenuItem itemExit = new MenuItem("E_xit", true); // true: shortcuts enabled
        itemExit.addOnActivate( (MenuItem m) => this.quitApp() );
        fileMenu.append(itemExit);

        // _View menu
        MenuItem viewMenuHeader = new MenuItem("_View", true);
        menuBar.append(viewMenuHeader);

        Menu viewMenu = new Menu();
        viewMenuHeader.setSubmenu(viewMenu);

        MenuItem itemWorldMap = new MenuItem("_World", true);
        itemWorldMap.addOnActivate( (MenuItem m) => sayHi("world ...") );
        viewMenu.append(itemWorldMap); 

        // _Help menu
        MenuItem helpMenuHeader = new MenuItem("H_elp",  true);
        menuBar.append(helpMenuHeader);

        Menu helpMenu = new Menu();
        helpMenuHeader.setSubmenu(helpMenu);

        MenuItem itemHelp = new MenuItem("_Help", true);
        itemHelp.addOnActivate( (MenuItem m) => sayHi("help ...") );
        helpMenu.append(itemHelp);

        MenuItem itemAbout = new MenuItem("_About", true);
        itemAbout.addOnActivate( (MenuItem m) => this.showAboutDialog() );
        helpMenu.append(itemAbout);
    } 

    void showAboutDialog() {
        import gtk.AboutDialog;

        auto aboutDialog = new AboutDialog();
        aboutDialog.setTransientFor(this);
        aboutDialog.setAuthors([ "Emil Nicolaie Perhinschi"]);
        aboutDialog.setLicense("BSL-1.0 (Boost Software Licence)");
        aboutDialog.run();
        aboutDialog.destroy();
    }

    void showHelp() {

    }

    void showReports() {

    }

    void showSize(Button b)
    {
        import std.stdio: writefln;
        import std.format;

        int x, y;
        this.getSize(x,y);
        writefln("x is %d and y is %d", x, y);         
        b.setLabel(format!"x is %d and y is %d"(x, y));
    }

    void quitApp()
    {
        import std.stdio: writeln;
        writeln("exitting normally ... bye!");
        Main.quit();
    }

}

void sayHi(string message) 
{
    import std.stdio: writefln;
    writefln("saying %s", message);
}

void sayHi() 
{
    import std.stdio: writeln;

    string message = "sayHi works";
    writeln(message);
}

struct ItemData {
    string label;
    void delegate (MenuItem i) action;
}


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
            this.sourceBuffer.setLanguage(dLang);
            this.sourceBuffer.setHighlightSyntax(true);
        }

        //sourceView.modifyFont("Courier", 9);
        this.setRightMarginPosition(72);
        this.setShowRightMargin(true);
        this.setAutoIndent(true);

	} // this()

} // class MyTextView

