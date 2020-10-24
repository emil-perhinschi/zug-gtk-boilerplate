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
import gtk.Statusbar;

import zug.frontend.gtk.Editor;
import zug.frontend.gtk.TabContainer;

// DEBUG
import std.stdio: writeln;

class AppMainWindow : MainWindow
{
    import zug.frontend.gtk.AppStatusBar;

    string title = "Test main window";
    MenuBar menu_bar;
    Box main_box;

    TabContainer tab_container;
    AppStatusBar status_bar;
    this() 
    {
        super(title);

        bool expand = true;
        bool fill = true;
        uint padding = 0;  

        setDefaultSize(500, 300);
        addOnDestroy( (Widget w) => this.quitApp() );

        this.main_box = new Box(Orientation.VERTICAL, 0);         
        this.add(main_box);

        this.menu_bar = buildMenus(main_box);
        main_box.packStart(this.menu_bar, false, false, 0);

        // this.editor_window = new ScrolledTextWindow();
        this.tab_container = new TabContainer();
	    this.main_box.packStart(this.tab_container, expand, fill, padding); 
        this.status_bar = new AppStatusBar();
        this.main_box.packStart(this.status_bar, false, fill, padding);
        this.status_bar.push(this.status_bar.context_id, "some status");
        writeln( this.status_bar.Box );
        
        sayHi();
        this.showAll();
    }

    MenuBar buildMenus(Box mainBox) {

        MenuBar menu_bar = new MenuBar();

        // _File menu
        MenuItem file_menu_header = new MenuItem("_File", true);// true: shortcuts enabled
        menu_bar.append(file_menu_header);

        Menu file_menu = new Menu();
        file_menu_header.setSubmenu(file_menu);

        MenuItem item_load = new MenuItem("_Load", true); 
        item_load.addOnActivate( (MenuItem m) => load_file(this, m ) );
        file_menu.append(item_load);

        MenuItem item_save = new MenuItem("_Save", true); // true: shortcuts enabled
        item_save.addOnActivate( (MenuItem m) => save_file(this, m) );
        file_menu.append(item_save);

        MenuItem item_configuration = new MenuItem("_Configuration", true); // true: shortcuts enabled
        item_configuration.addOnActivate( (MenuItem m) => sayHi("configuration ..." ) );
        file_menu.append(item_configuration);

        MenuItem item_exit = new MenuItem("E_xit", true); // true: shortcuts enabled
        item_exit.addOnActivate( (MenuItem m) => this.quitApp() );
        file_menu.append(item_exit);

        // _View menu
        MenuItem view_menu_header = new MenuItem("_View", true);
        menu_bar.append(view_menu_header);

        Menu view_menu = new Menu();
        view_menu_header.setSubmenu(view_menu);

        MenuItem item_world_map = new MenuItem("_World", true);
        item_world_map.addOnActivate( (MenuItem m) => sayHi("world ...") );
        view_menu.append(item_world_map); 

        // _Help menu
        MenuItem help_menu_header = new MenuItem("H_elp",  true);
        menu_bar.append(help_menu_header);

        Menu help_menu = new Menu();
        help_menu_header.setSubmenu(help_menu);

        MenuItem item_help = new MenuItem("_Help", true);
        item_help.addOnActivate( (MenuItem m) => sayHi("help ...") );
        help_menu.append(item_help);

        MenuItem item_about = new MenuItem("_About", true);
        item_about.addOnActivate( (MenuItem m) => this.showAboutDialog() );
        help_menu.append(item_about);
        return menu_bar;
    } 

    void showAboutDialog() {
        import gtk.AboutDialog;

        auto aboutDialog = new AboutDialog();
        aboutDialog.setTransientFor(this);
        aboutDialog.setAuthors([ "Emil Nicolaie Perhinschi" ]);
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

void load_file(AppMainWindow app_window, MenuItem menu_item) {
    import gtk.FileChooserDialog;
    import std.path: baseName;

    string filename;

    FileChooserAction action = FileChooserAction.OPEN;
	FileChooserDialog dialog = new FileChooserDialog("Open a File", app_window, action, null, null);
	int response = dialog.run();   
    if(response == ResponseType.OK) {
        filename = dialog.getFilename();
        writeln("File name: ", filename);
        string base_file_name = filename.baseName;
        ulong last_char = base_file_name.length >= 10 ? 10 : base_file_name.length;
        app_window.tab_container.add_new_code_tab(base_file_name[0..last_char], filename);
        app_window.tab_container.showAll();
    } else {
        writeln("cancelled.");
    }

    dialog.destroy();
    // app_window.tab_container.show
}

void save_file(AppMainWindow app_window, MenuItem menu_item) {

}