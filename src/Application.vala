namespace Archives {
	public static Utils.Settings settings;
	public static Application app;
	public static bool is_flatpak = false;
	public class Application : Adw.Application {
		public ArchivesWindow main_window { get; set; }
		public bool overview_open { get; set; default=false; }
		public Utils.MushroomSoupServer server;
		public signal void toast (string title, uint timeout = 5);

		string[] loaded_files = {};
		public string? get_loaded_file_location (int file_no) {
			if (file_no < 0 || file_no >= loaded_files.length) return null;
			return loaded_files[file_no];
		}

		public int add_loaded_file_location (string path) {
			int file_pos = -1;
			for (int i = 0; i < loaded_files.length; i++) {
				if (loaded_files[i] == path) {
					file_pos = i;
					break;
				}
			}

			if (file_pos == -1) {
				loaded_files += path;
				return loaded_files.length - 1;
			}

			return file_pos;
		}

		public Application () {
			Object (
				application_id: "dev.geopjr.Archives",
				flags: ApplicationFlags.DEFAULT_FLAGS
			);
		}

		string troubleshooting = "os: %s %s\nprefix: %s\nflatpak: %s\nversion: %s (%s)\ngtk: %u.%u.%u (%d.%d.%d)\nlibadwaita: %u.%u.%u (%d.%d.%d)\nlibsoup: %u.%u.%u (%d.%d.%d)".printf ( // vala-lint=line-length
			GLib.Environment.get_os_info ("NAME"), GLib.Environment.get_os_info ("VERSION"),
			Build.PREFIX,
			Archives.is_flatpak.to_string (),
			Build.VERSION, Build.PROFILE,
			Gtk.get_major_version (), Gtk.get_minor_version (), Gtk.get_micro_version (),
			Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION,
			Adw.get_major_version (), Adw.get_minor_version (), Adw.get_micro_version (),
			Adw.MAJOR_VERSION, Adw.MINOR_VERSION, Adw.MICRO_VERSION,
			Soup.get_major_version (), Soup.get_minor_version (), Soup.get_micro_version (),
			Soup.MAJOR_VERSION, Soup.MINOR_VERSION, Soup.MICRO_VERSION
		);

		public static int main (string[] args) {
			is_flatpak = GLib.Environment.get_variable ("FLATPAK_ID") != null
			|| GLib.File.new_for_path ("/.flatpak-info").query_exists ();

			Intl.setlocale (LocaleCategory.ALL, "");
			Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
			Intl.textdomain (Build.GETTEXT_PACKAGE);

			GLib.Environment.unset_variable ("GTK_THEME");

			app = new Application ();
			return app.run (args);
		}

		construct {
			ActionEntry[] action_entries = {
				{ "open-preferences", this.open_preferences },
				{ "about", this.on_about_action },
				{ "quit", this.quit }
			};
			this.add_action_entries (action_entries, this);
			this.set_accels_for_action ("app.open-preferences", {"<primary>comma"});
			this.set_accels_for_action ("app.quit", {"<primary>q"});
			this.set_accels_for_action ("window.close", {"<primary>W"});
			this.set_accels_for_action ("app.about", {"F1"});

			this.server = new Utils.MushroomSoupServer ();
		}

		protected void open_preferences () {
			(new Dialogs.Preferences ()).present (this.main_window);
		}

		protected override void startup () {
			base.startup ();
			var lines = troubleshooting.split ("\n");
			foreach (unowned string line in lines) {
				debug (line);
			}
			Adw.init ();
			settings = new Utils.Settings ();
		}

		[GtkTemplate (ui = "/dev/geopjr/Archives/ui/applicationwindow.ui")]
		public class ArchivesWindow : Adw.ApplicationWindow {
			[GtkChild] unowned Adw.TabOverview tab_overview;
			[GtkChild] unowned Adw.TabView tab_view;

			construct {
				settings.bind ("window-w", this, "default-width", SettingsBindFlags.DEFAULT);
				settings.bind ("window-h", this, "default-height", SettingsBindFlags.DEFAULT);
				settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

				this.tab_overview.bind_property ("open", app, "overview-open", BindingFlags.SYNC_CREATE);
				ActionEntry[] action_entries = {
					{ "show-tabs", this.show_tabs }
				};
				this.add_action_entries (action_entries, this);

				on_tab_create ();
				tab_overview.create_tab.connect (on_tab_create);
			}

			private void show_tabs () {
				tab_overview.open = true;
			}

			private unowned Adw.TabPage on_tab_create () {
				var tab = new Widgets.OverviewTab (tab_view);
				unowned Adw.TabPage tab_page = tab_view.append (tab);

				tab.bind_property ("working", tab_page, "loading", BindingFlags.SYNC_CREATE);
				tab.bind_property ("title", tab_page, "title", BindingFlags.SYNC_CREATE);
				tab.bind_property ("keyword", tab_page, "keyword", BindingFlags.SYNC_CREATE);

				return tab_page;
			}
		}

		public override void activate () {
			base.activate ();
			if (this.main_window == null) {
				this.main_window = new ArchivesWindow () {
					application = this
				};
			}
			this.main_window.present ();
			settings.delay ();
		}

		protected override void shutdown () {
			settings.apply ();
			base.shutdown ();
		}

		private void on_about_action () {
			var dialog = new Adw.AboutDialog () {
				application_icon = Build.DOMAIN,
				application_name = Build.NAME,
				version = Build.VERSION,
				issue_url = Build.ISSUES_WEBSITE,
				support_url = Build.SUPPORT_WEBSITE,
				license_type = Gtk.License.AGPL_3_0_ONLY,
				copyright = "© 2024 Evangelos \"GeopJr\" Paterakis",
				developer_name = "Evangelos \"GeopJr\" Paterakis",
				debug_info = troubleshooting,
				debug_info_filename = @"$(Build.NAME).txt",
				// translators: Name <email@domain.com> or Name https://website.example
				translator_credits = _("translator-credits")
			};
			dialog.add_link (_("Donate"), Build.DONATE_WEBSITE);
			dialog.add_legal_section ("SingleFile", "© Gildas Lormeau", Gtk.License.AGPL_3_0, null);
			dialog.add_legal_section ("ReplayWeb.page", "© Webrecorder Software", Gtk.License.AGPL_3_0, null);
			dialog.add_legal_section ("Ruffle", "© Ruffle LLC", Gtk.License.MIT_X11, null);
			dialog.add_credit_section (_("Libraries"), {
				"SingleFile https://github.com/gildas-lormeau/SingleFile",
				"ReplayWeb.page https://github.com/webrecorder/replayweb.page",
				"Ruffle https://ruffle.rs/"
			});
			dialog.present (this.main_window);

			GLib.Idle.add (() => {
				var style = Utils.Celebrate.get_celebration_css_class (new GLib.DateTime.now ());
				if (style != "")
					dialog.add_css_class (style);
				return GLib.Source.REMOVE;
			});
		}
	}
}
