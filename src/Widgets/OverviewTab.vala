[GtkTemplate (ui = "/dev/geopjr/Archives/ui/overviewtab.ui")]
public class Archives.Widgets.OverviewTab : Adw.Bin {
	~OverviewTab () {
		debug ("Destroying OverviewTab");
	}

	public OverviewTab (Adw.TabView tabview) {
		tab_button.view = tabview;
	}

	public bool reveal_bottom_bar {
		get {
			return toolbarview.reveal_bottom_bars && content_page != null && content_page.has_navigation_bar;
		}

		set {
			toolbarview.reveal_bottom_bars = value && content_page != null && content_page.has_navigation_bar;
		}
	}

	public bool working { get; private set; default=false; }
	public string title { get; protected set; default=_("Archives"); }
	public string keyword { get; private set; default=""; }

	Archives.Views.WebViewPage? content_page = null;
	[GtkChild] unowned Adw.StatusPage status_page;
	[GtkChild] unowned Gtk.Button forward_button;
	[GtkChild] unowned Gtk.Button back_button;
	[GtkChild] unowned Gtk.SearchEntry search_entry;
	[GtkChild] unowned Gtk.Stack stack;
	[GtkChild] unowned Adw.ToolbarView toolbarview;
	[GtkChild] unowned Adw.WindowTitle title_widget;
	[GtkChild] unowned Adw.TabButton tab_button;
	[GtkChild] unowned Gtk.Button archive_button;
	[GtkChild] unowned Gtk.Button home_button;
	[GtkChild] unowned Adw.ToastOverlay toastoverlay;
	construct {
		app.bind_property ("overview-open", toolbarview, "reveal-top-bars", BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		app.bind_property ("overview-open", this, "reveal-bottom-bar", BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		stack.notify["visible-child-name"].connect (on_visible_child_name_changed);

		title_widget.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
		status_page.icon_name = Build.DOMAIN;
		app.toast.connect (add_toast);
	}

	private void add_toast (string content, uint timeout = 5) {
		toastoverlay.add_toast (new Adw.Toast (content) {
			timeout = timeout
		});
	}

	[GtkCallback] private void archive_page () {
		if (content_page == null || content_page as Views.ArchivePage == null) return;
		var archive_page = content_page as Views.ArchivePage;
		this.working = true;
		this.back_button.sensitive =
		this.forward_button.sensitive =
		this.search_entry.sensitive = false;
		archive_page.archive.begin ((obj, res) => {
			archive_page.archive.end (res);
			this.working = false;
			this.back_button.sensitive = content_page.can_go_back;
			this.forward_button.sensitive = content_page.can_go_forward;
			this.search_entry.sensitive = true;
		});
	}

	[GtkCallback] private void go_home () {
		stack.visible_child_name = "home";
		if (content_page != null) stack.remove (content_page);
		content_page = null;
		archive_button.visible = false;
		this.title =
		title_widget.title = _("Archives");
		title_widget.subtitle = "";
		this.keyword = "";
		this.remove_css_class ("archive-window");
		foreach (string class_name in this.css_classes) {
			if (class_name.has_prefix ("egg-")) this.remove_css_class (class_name);
		}
	}

	private void on_visible_child_name_changed () {
		this.reveal_bottom_bar =
		home_button.visible = stack.visible_child_name != "home";
	}

	[GtkCallback] private void on_search_activate () {
		if (content_page == null) return;
		content_page.load_uri (search_entry.text);
	}

	[GtkCallback] private void on_open_file () {
		Gtk.FileFilter filter = new Gtk.FileFilter () {
			name = _("All Supported Files")
		};

		filter.add_mime_type ("application/vnd.adobe.flash.movie");
		//  filter.add_mime_type ("application/x-openzim");
		filter.add_mime_type ("application/gzip");
		filter.add_mime_type ("application/zip");
		filter.add_mime_type ("text/html");
		filter.add_suffix ("har");

		var chooser = new Gtk.FileDialog () {
			title = _("Open"),
			modal = true,
			default_filter = filter
		};

		chooser.open.begin (app.main_window, null, (obj, res) => {
			try {
				var file = chooser.open.end (res);
				string path = file.get_path ();
				string basename = GLib.Path.get_basename (path);
				this.keyword = basename;

				string ext;
				switch (guess_file_type (basename, out ext)) {
					case OpenFileType.SWF:
						open_swf (app.add_loaded_file_location (path), ext);
						title_widget.title = @"$basename - Ruffle";
						break;
					case OpenFileType.REPLAY:
						open_replay (app.add_loaded_file_location (path), ext);
						title_widget.title = @"$basename - ReplayWeb.page";
						break;
					case OpenFileType.HTML:
						open_html (path);
						break;
					default:
						this.keyword = "";
						break;
				}
			} catch (Error e) {
				// User dismissing the dialog also ends here so don't make it sound like
				// it's an error
				warning (@"Couldn't get the result of FileDialog for ProfileEdit: $(e.message)");
			}
		});
	}

	enum OpenFileType {
		SWF,
		REPLAY,
		HTML,
		//  ZIM,
		OTHER
	}

	private OpenFileType guess_file_type (string basename, out string ext) {
		string mime = GLib.ContentType.guess (basename, null, null);

		ext = ""; // Some tools need the ext to determine the mimetype
		switch (mime) {
			case "text/html":
				ext = ".html";
				return OpenFileType.HTML;
			case "application/vnd.adobe.flash.movie":
				ext = ".swf";
				return OpenFileType.SWF;
			//  case "application/x-openzim":
			//  	return OpenFileType.ZIM;
			default:
				int index_of_dot = basename.index_of_char ('.');
				if (index_of_dot == -1) return OpenFileType.OTHER;

				ext = basename.down ().slice (index_of_dot, basename.length);
				switch (ext) {
					case ".warc.gz":
					case ".warc":
					case ".wacz":
					case ".har":
					//  case ".cdx":
					//  case ".cdxj":
						return OpenFileType.REPLAY;
					case ".swf":
						return OpenFileType.SWF;
					case ".html":
						return OpenFileType.HTML;
					default:
						return OpenFileType.OTHER;
				}
		}
	}

	private void open_swf (int file_pos, string ext) {
		if (content_page != null) stack.remove (content_page);

		content_page = new Views.RufflePage (file_pos, ext);
		stack.add_named (content_page, "content");
		stack.visible_child_name = "content";
	}

	private void open_replay (int file_pos, string ext) {
		if (content_page != null) stack.remove (content_page);

		content_page = new Views.ReplayPage (file_pos, ext);
		stack.add_named (content_page, "content");
		stack.visible_child_name = "content";
	}

	[GtkCallback] private void open_archive_view () {
		if (content_page != null) stack.remove (content_page);

		content_page = new Views.ArchivePage ();
		stack.add_named (content_page, "content");
		stack.visible_child_name = "content";
		archive_button.visible = true;
		this.reveal_bottom_bar = true;

		content_page.bind_property ("can-archive", archive_button, "sensitive", BindingFlags.SYNC_CREATE);
		content_page.bind_property ("title", title_widget, "title", BindingFlags.SYNC_CREATE);
		//  content_page.bind_property ("subtitle", title_widget, "subtitle", BindingFlags.SYNC_CREATE);
		content_page.bind_property ("subtitle", search_entry, "text", BindingFlags.SYNC_CREATE);

		content_page.bind_property ("can-go-forward", forward_button, "sensitive", BindingFlags.SYNC_CREATE);
		content_page.bind_property ("can-go-back", back_button, "sensitive", BindingFlags.SYNC_CREATE);

		forward_button.clicked.connect (content_page.go_forward);
		back_button.clicked.connect (content_page.go_back);

		this.keyword = "archive";
		this.add_css_class ("archive-window");
		((Views.ArchivePage) content_page).change_class.connect (on_archive_class_change);
	}

	private void on_archive_class_change (string class_name, bool remove = false) {
		if (remove) {
			this.remove_css_class (class_name);
		} else {
			this.add_css_class (class_name);
		}
	}

	private void open_html (string path) {
		if (content_page != null) stack.remove (content_page);

		content_page = new Views.HtmlPage (@"file://$(GLib.Uri.escape_string (path, "/"))");
		stack.add_named (content_page, "content");
		stack.visible_child_name = "content";
		this.reveal_bottom_bar = true;

		content_page.bind_property ("title", title_widget, "title", BindingFlags.SYNC_CREATE);
		content_page.bind_property ("subtitle", search_entry, "text", BindingFlags.SYNC_CREATE);

		content_page.bind_property ("can-go-forward", forward_button, "sensitive", BindingFlags.SYNC_CREATE);
		content_page.bind_property ("can-go-back", back_button, "sensitive", BindingFlags.SYNC_CREATE);

		forward_button.clicked.connect (content_page.go_forward);
		back_button.clicked.connect (content_page.go_back);
	}
}
