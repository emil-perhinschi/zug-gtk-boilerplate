import std.stdio;
import zug.frontend.gtk.AppMainWindow;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Button;

void main(string[] args)
{
	Main.init(args);
	AppMainWindow testRigWindow = new AppMainWindow();

	// give control over to the gtkD .
	Main.run();
	
} // main()



