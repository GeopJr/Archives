public class Archives.Views.ArchivePage : Views.WebViewPage {
	public signal void change_class (string css_class, bool remove);
	public bool can_archive { get; private set; default=false; }
	string last_css_class = "";
	bool bundle_loaded_for_url = false;

	~ArchivePage () {
		debug ("Destroying ArchivePage");
		remove_last_css_class ();
	}

	construct {
		this.webview.load_uri ("https://start.duckduckgo.com/?k5=1&kay=b&kpsb=-1&kbg=-1&kbd=-1&kp=-2&k1=-1&kak=-1&kax=-1&kaq=-1&kap=-1&kao=-1&kau=-1");
		this.has_navigation_bar = true;
		this.webview.notify["uri"].connect (on_uri_change);
	}

	private void remove_last_css_class () {
		if (last_css_class != "") {
			change_class (last_css_class, true);
			last_css_class = "";
		}
	}

	protected void on_uri_change () {
		remove_last_css_class ();
		last_css_class = Utils.Egg.get_css_class (this.webview.uri);
		if (last_css_class == "") return;
		change_class (last_css_class, false);
	}

	protected override void on_load_changed (WebKit.LoadEvent load_event) {
		base.on_load_changed (load_event);
		this.can_archive = load_event == WebKit.LoadEvent.FINISHED;
		if (load_event == WebKit.LoadEvent.FINISHED) bundle_loaded_for_url = false;
	}

	public async void archive () {
		debug (@"Archiving $(this.webview.uri)");
		this.can_archive = false;
		this.progress = 0.0;
		this.webview.sensitive = false;

		try {
			InputStream input_stream;
			DataInputStream data_stream;

			if (!bundle_loaded_for_url) {
				input_stream = GLib.resources_open_stream (
					"/dev/geopjr/Archives/single-filez-bundle.js",
					ResourceLookupFlags.NONE
				);

				data_stream = new DataInputStream (input_stream);
				yield webview.evaluate_javascript (
					yield data_stream.read_upto_async ("\0", 1, GLib.Priority.DEFAULT, null, null),
					-1,
					null,
					null,
					null
				);
				debug (@"Finished loading single-filez-bundle.js for $(this.webview.uri)");
				bundle_loaded_for_url = true;
			}

			string singlefile_settings = settings.to_single_file_js ();
			yield webview.evaluate_javascript (
				singlefile_settings,
				-1,
				null,
				null,
				null
			);
			debug (@"Finished loading settings: $singlefile_settings");

			this.progress = 0.25;
			input_stream = GLib.resources_open_stream (
				"/dev/geopjr/Archives/single-filez-capture.js",
				ResourceLookupFlags.NONE
			);

			Json.Parser parser = new Json.Parser ();
			data_stream = new DataInputStream (input_stream);
			parser.load_from_data (
				(yield webview.call_async_javascript_function (
					yield data_stream.read_upto_async ("\0", 1, GLib.Priority.DEFAULT, null, null),
					-1,
					null,
					null,
					null,
					null
				)).to_string ()
			);
			debug (@"Finished loading single-filez-capture.js for $(this.webview.uri)");

			this.progress = 0.5;
			Json.Node node = parser.get_root ();
			var chooser = new Gtk.FileDialog () {
				title = _("Save Archive"),
				modal = true,
				initial_name = node.get_object ().get_string_member ("filename")
			};

			try {
				var file = yield chooser.save (app.main_window, null);
				if (file != null) {
					this.progress = 0.75;
					debug (@"Picked save location for $(this.webview.uri)");

					uint8[] bytes = {};
					var arr = node.get_object ().get_array_member ("content");
					arr.foreach_element ((array, i, node) => {
						bytes += (uint8) node.get_int ();
					});
					FileOutputStream stream = file.replace (null, false, FileCreateFlags.PRIVATE);
					stream.write_all (bytes, null);
					debug (@"Saved $(this.webview.uri)");
					this.progress = 1.0;
				}
			} catch (Error e) {
				// User dismissing the dialog also ends here so don't make it sound like
				// it's an error
				warning (@"Couldn't get the result of FileDialog for attachment: $(e.message)");
			}
		} catch (Error e) {
			critical (@"Error while archiving $(this.webview.uri): $(e.message)");
			app.toast (e.message, 5);
		}

		this.webview.sensitive = true;
		this.progress = 0.0;
		this.can_archive = true;
		debug (@"Finished archiving $(this.webview.uri)");
	}
}
