public class Archives.Views.ArchivePage : Views.WebViewPage {
	public signal void change_class (string css_class, bool remove);
	public bool can_archive { get; private set; default=false; }
	string last_css_class = "";
	bool bundle_loaded_for_url = false;

	~ArchivePage () {
		debug ("Destroying ArchivePage");
		remove_last_css_class ();
	}

	WebKit.ContextMenuItem as_cm;
	WebKit.ContextMenuItem aa_cm;
	GLib.SimpleAction al_action;
	construct {
		this.has_navigation_bar = true;
		this.webview.notify["uri"].connect (on_uri_change);

		var as_action = new GLib.SimpleAction ("archive-selection", null);
		as_action.activate.connect (on_archive_selection);
		as_cm = new WebKit.ContextMenuItem.from_gaction (as_action, _("Archive All Selected Links"), null);

		var aa_action = new GLib.SimpleAction ("archive-all", null);
		aa_action.activate.connect (on_archive_all);
		aa_cm = new WebKit.ContextMenuItem.from_gaction (aa_action, _("Archive All Links"), null);

		al_action = new GLib.SimpleAction ("archive-selected-link", VariantType.STRING);
		al_action.activate.connect (on_archive_selected_link);

		this.webview.web_context.set_cache_model (settings.cache ? WebKit.CacheModel.WEB_BROWSER : WebKit.CacheModel.DOCUMENT_VIEWER);
		this.add_findbar ();
	}

	public ArchivePage (string uri = "https://start.duckduckgo.com/?k5=1&kay=b&kpsb=-1&kbg=-1&kbd=-1&kp=-2&k1=-1&kak=-1&kax=-1&kaq=-1&kap=-1&kao=-1&kau=-1") {
		this.webview.load_uri (uri);
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

	public signal void loaded ();
	protected override void on_load_changed (WebKit.LoadEvent load_event) {
		base.on_load_changed (load_event);
		this.can_archive = load_event == WebKit.LoadEvent.FINISHED;
		if (load_event == WebKit.LoadEvent.FINISHED) {
			bundle_loaded_for_url = false;
			loaded ();
		}
	}

	public async void archive (GLib.File? folder = null) {
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

			string initial_name = node.get_object ().get_string_member ("filename");
			var chooser = new Gtk.FileDialog () {
				title = _("Save Archive"),
				modal = true,
				initial_name = initial_name
			};

			try {
				var file = folder == null
					? yield chooser.save (app.main_window, null)
					: GLib.File.new_for_path (GLib.Path.build_filename (folder.get_path (), initial_name));
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

	protected override bool on_context_menu (WebKit.ContextMenu context_menu, WebKit.HitTestResult hit_test_result) {
		if (hit_test_result.context_is_selection ()) {
			context_menu.append (as_cm);
		} else if (hit_test_result.context_is_link ()) {
			string url = hit_test_result.link_uri.strip ();
			if (url.length > 0 && url.down ().has_prefix ("http")) {
				var al_cm = new WebKit.ContextMenuItem.from_gaction (al_action, _("Archive Link"), new Variant.string (url));
				context_menu.append (al_cm);
			}
		} else if (
			!hit_test_result.context_is_editable ()
			&& !hit_test_result.context_is_image ()
			&& !hit_test_result.context_is_media ()
			&& !hit_test_result.context_is_scrollbar ()
		) {
			context_menu.append (aa_cm);
		}

		return base.on_context_menu (context_menu, hit_test_result);
	}

	private void on_archive_all () {
		string script = """
			const links = [...document.querySelectorAll('a')].map(x => x.href);
			return JSON.stringify(Array.from(new Set(links.filter (x => x && x.toLowerCase().startsWith("http")))));
		""";
		this.webview.call_async_javascript_function.begin (
			script,
			-1,
			null,
			null,
			null,
			null,
			(obj, res) => {
				string[] selection_links = {};
				try {
					Json.Parser parser = new Json.Parser ();
					parser.load_from_data (this.webview.call_async_javascript_function.end (res).to_string ());

					var arr = parser.get_root ().get_array ();
					arr.foreach_element ((array, i, node) => {
						string found_url = node.get_string ();
						if (found_url != this.webview.uri)
							selection_links += found_url;
					});
				} catch (Error e) {
					string msg = _(@"Couldn't retrieve links from page: $(e.message)");
					critical (msg);
					app.toast (msg, 5);
				}

				if (selection_links.length == 0) {
					app.toast (_("No links found in selection."));
				} else {
					app.show_link_selection_dialog (selection_links);
				}
			}
		);
	}

	private void on_archive_selected_link (GLib.SimpleAction action, GLib.Variant? value) {
		if (value == null) return;

		app.show_link_selection_dialog ({value.get_string ()});
	}

	private void on_archive_selection () {
		// https://github.com/gildas-lormeau/SingleFile/blob/bad106638d82ea3a742f190ef3f4c350bac6ace0/src/ui/content/content-ui.js#L159C30-L195
		string script = """
			let selectionFound;
			const links = [];
			const selection = getSelection();
			for (let indexRange = 0; indexRange < selection.rangeCount; indexRange++) {
				let range = selection.getRangeAt(indexRange);
				if (range && range.commonAncestorContainer) {
					const treeWalker = document.createTreeWalker(range.commonAncestorContainer);
					let rangeSelectionFound = false;
					let finished = false;
					while (!finished) {
						if (rangeSelectionFound || treeWalker.currentNode == range.startContainer || treeWalker.currentNode == range.endContainer) {
							rangeSelectionFound = true;
							if (range.startContainer != range.endContainer || range.startOffset != range.endOffset) {
								selectionFound = true;
								if (treeWalker.currentNode.tagName == "A" && treeWalker.currentNode.href) {
									links.push(treeWalker.currentNode.href.trim());
								}
							}
						}
						if (treeWalker.currentNode == range.endContainer) {
							finished = true;
						} else {
							treeWalker.nextNode();
						}
					}
					if (selectionFound && treeWalker.currentNode == range.endContainer && treeWalker.currentNode.querySelectorAll) {
						treeWalker.currentNode.querySelectorAll("*").forEach(descendantElement => {
							if (descendantElement.tagName == "A" && descendantElement.href) {
								links.push(treeWalker.currentNode.href.trim());
							}
						});
					}
				}
			}
			return JSON.stringify(Array.from(new Set(links.filter (x => x && x.toLowerCase().startsWith("http")))));
		""";
		this.webview.call_async_javascript_function.begin (
			script,
			-1,
			null,
			null,
			null,
			null,
			(obj, res) => {
				string[] selection_links = {};
				try {
					Json.Parser parser = new Json.Parser ();
					parser.load_from_data (this.webview.call_async_javascript_function.end (res).to_string ());

					var arr = parser.get_root ().get_array ();
					arr.foreach_element ((array, i, node) => {
						string found_url = node.get_string ();
						if (found_url != this.webview.uri)
							selection_links += found_url;
					});
				} catch (Error e) {
					string msg = _(@"Couldn't retrieve links from selection: $(e.message)");
					critical (msg);
					app.toast (msg, 5);
				}

				if (selection_links.length == 0) {
					app.toast (_("No links found in selection."));
				} else {
					app.show_link_selection_dialog (selection_links);
				}
			}
		);
	}
}
