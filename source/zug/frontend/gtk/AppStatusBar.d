module zug.frontend.gtk.AppStatusBar;

import gtk.Statusbar;

class AppStatusBar : Statusbar {
    uint context_id;
    string context_description = "this is a bare status";

    this() {
        import std.stdio: writeln;

        this.context_id = this.getContextId(this.context_description);
        this.setBorderWidth(10);
        this.setSpacing(0);
    }

}