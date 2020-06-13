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

class AppMainWindow : MainWindow
{
    string title = "Test main window";

    this() 
    {
        super(title);
        setDefaultSize(500, 300);
        addOnDestroy( (Widget w) => this.quitApp() );

        Box mainBox = new Box(Orientation.VERTICAL, 10);         
        this.add(mainBox);

        MenuBar menuBar = new MenuBar();
        mainBox.packStart(menuBar, false, false, 0);

        MenuItem fileMenuHeader = new MenuItem("File");
        menuBar.append(fileMenuHeader);

        Button button = new Button("Show size");
        button.addOnClicked(delegate void(Button b) { this.showSize(b); });
        mainBox.add(button);

        Menu fileMenu = new Menu();
        fileMenuHeader.setSubmenu(fileMenu);

        MenuItem fileMenuSave = new MenuItem("Save");
        fileMenuSave.addOnActivate( (MenuItem i) => this.sayHi("save ...") );
        fileMenu.append(fileMenuSave);

        MenuItem fileMenuLoad = new MenuItem("Load");
        fileMenuLoad.addOnActivate( (MenuItem i ) => this.sayHi("load ...") );
        fileMenu.append(fileMenuLoad);

        MenuItem fileMenuExit = new MenuItem("Exit");
        fileMenuExit.addOnActivate( (MenuItem i) => this.quitApp );
        fileMenu.append(fileMenuExit);


        sayHi();
        showAll();
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

        string exitMessage = "exitting normally ... bye";
        writeln(exitMessage);
        Main.quit();
        
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
}
