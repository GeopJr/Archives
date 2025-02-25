public class Archives.Widgets.FindBar : Adw.Bin {
	Gtk.Button prev_btn;
	Gtk.Button next_btn;
	Gtk.SearchBar search_bar;
	Gtk.SearchEntry search_entry;
	construct {
		this.hexpand = true;
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

		search_entry = new Gtk.SearchEntry () {
			placeholder_text = _("Type to search…"),
			input_purpose = Gtk.InputPurpose.FREE_FORM,
			input_hints = Gtk.InputHints.NONE,
			activates_default = true
		};
		search_entry.activate.connect (on_activate);

		search_bar = new Gtk.SearchBar () {
			search_mode_enabled = false,
			show_close_button = true
		};

		prev_btn = new Gtk.Button.from_icon_name ("go-up-symbolic") {
			tooltip_text = _("Find previous occurrence of the search string"),
			sensitive = false
		};
		prev_btn.clicked.connect (on_search_prev);
		box.append (prev_btn);
		box.append (search_entry);

		next_btn = new Gtk.Button.from_icon_name ("go-down-symbolic") {
			tooltip_text = _("Find next occurrence of the search string"),
			sensitive = false
		};
		next_btn.clicked.connect (on_search_next);
		box.append (next_btn);

		search_bar.child = new Adw.Clamp () {
			child = box,
			maximum_size = 300
		};
		search_bar.connect_entry (search_entry);

		this.child = search_bar;
	}

	private void on_activate () {
		search ();
	}

	public new bool grab_focus () {
		return this.search_entry.grab_focus ();
	}

	WebKit.FindController find_controller;
	public FindBar (WebKit.FindController find_controller) {
		this.find_controller = find_controller;
		this.find_controller.failed_to_find_text.connect (on_failed);
	}

	private void on_search_next () {
		search ();
	}

	private void on_search_prev () {
		search (true);
	}

	private void search (bool backwards = false) {
		if (search_entry.has_css_class ("error")) search_entry.remove_css_class ("error");

		var options = WebKit.FindOptions.CASE_INSENSITIVE;
		if (backwards) options |= WebKit.FindOptions.BACKWARDS;

		next_btn.sensitive = prev_btn.sensitive = true;
		find_controller.search (search_entry.text, options, uint.MAX);
	}

	private void on_failed () {
		if (search_entry.has_css_class ("error")) return;

		next_btn.sensitive = prev_btn.sensitive = false;
		search_entry.add_css_class ("error");
	}

	public void toggle () {
		search_bar.search_mode_enabled = !search_bar.search_mode_enabled;
	}
}
