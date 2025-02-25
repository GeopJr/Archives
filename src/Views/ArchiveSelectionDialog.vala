public class Archives.Views.ArchiveSelectionDialog : Adw.Dialog {
	const int CON = 4;

	private class ArchiveRow : Gtk.ListBoxRow {
		public string url { get; set; }
		public bool archived { get; set; default = false; }
		public bool active { get { return check_box.active; } }
		public bool hide_checkbox { set { check_box.visible = !value; } }
		public signal void toggled ();

		Views.ArchivePage? page = null;
		Gtk.CheckButton check_box;
		Widgets.ProgressBin progress_bin;
		public ArchiveRow (string url) {
			this.add_css_class ("archive-row");
			this.url = url;
			this.overflow = Gtk.Overflow.HIDDEN;

			var action_row = new Adw.ActionRow () {
				title = url
			};

			progress_bin = new Widgets.ProgressBin ();
			progress_bin.child = action_row;

			check_box = new Gtk.CheckButton () {
				css_classes = {"selection-mode"},
				active = true,
				valign = Gtk.Align.CENTER
			};
			check_box.toggled.connect (on_toggled);
			action_row.add_prefix (check_box);
			action_row.activated.connect (on_activated);

			this.child = progress_bin;
		}

		private void on_toggled () {
			toggled ();
		}

		private void on_activated () {
			check_box.active = !check_box.active;
		}

		public void archive () {
			if (page != null) return;

			page = new Views.ArchivePage (this.url);
			page.loaded.connect (on_page_loaded);
			page.bind_property ("progress", progress_bin, "progress", BindingFlags.SYNC_CREATE);
		}

		private void on_page_loaded () {
			archive_real.begin ();
		}

		private async void archive_real () {
			yield this.page.archive ();
			this.archived = true;
		}
	}

	Gtk.Button close_button;
	Gtk.Button archive_all_button;
	Gtk.ListBox listbox;
	construct {
		this.title = _("Archive Selected Links");
		this.content_width = 400;
		this.content_height = 600;
		this.can_close = false;

		var toolbar_view = new Adw.ToolbarView ();
		var headerbar = new Adw.HeaderBar () {
			show_start_title_buttons = false,
			show_end_title_buttons = false
		};
		listbox = new Gtk.ListBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = {"boxed-list"},
			margin_top = margin_bottom = 4
		};
		var scrolledwindow = new Gtk.ScrolledWindow () {
			child = new Adw.Clamp () {
				child = listbox,
				tightening_threshold = 100,
				valign = Gtk.Align.START
			},
			vexpand = true,
			hexpand = true
		};

		close_button = new Gtk.Button.with_label (_("Cancel"));
		close_button.clicked.connect (on_close);
		archive_all_button = new Gtk.Button.with_label (_("Archive")) {
			css_classes = { "suggested-action" }
		};
		archive_all_button.clicked.connect (on_archive);

		headerbar.pack_start (close_button);
		headerbar.pack_end (archive_all_button);

		toolbar_view.add_top_bar (headerbar);
		toolbar_view.set_content (scrolledwindow);

		this.child = toolbar_view;
	}

	ArchiveRow[] archive_rows = {};
	public ArchiveSelectionDialog (string[] selection_links) {
		foreach (string url in selection_links) {
			var row = new ArchiveRow (url);
			row.toggled.connect (on_active_changed);
			row.notify["archived"].connect (on_archived);
			listbox.append (row);
			archive_rows += row;
		}
	}

	ArchiveRow[] active_rows = {};
	private void on_archive () {
		close_button.sensitive = false;
		archive_all_button.sensitive = false;
		listbox.can_target = false;

		foreach (var row in archive_rows) {
			if (row.active) {
				active_rows += row;
				row.hide_checkbox = true;
			} else {
				listbox.remove (row);
			}
		}
		archive_rows = {};

		archive_selected_rows ();
	}

	int archive_index = 0;
	int total_archiving = 0;
	private void archive_selected_rows () {
		if (total_archiving > CON) return;

		int max = int.min (active_rows.length, archive_index + CON);
		for (int i = archive_index; i < max; i++) {
			total_archiving += 1;
			active_rows[i].archive ();
			archive_index += 1;
		}
	}

	private void on_archived () {
		total_archiving -= 1;

		if (total_archiving == 0 && archive_index >= active_rows.length) {
			on_close ();
		} else {
			archive_selected_rows ();
		}
	}

	private void on_close () {
		this.force_close ();
	}

	private void on_active_changed () {
		bool any_active = false;
		foreach (var row in archive_rows) {
			if (row.active) {
				any_active = true;
				break;
			}
		}

		archive_all_button.sensitive = any_active;
	}
}
