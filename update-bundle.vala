// https://github.com/gildas-lormeau/SingleFile-MV3/commits/main/
const string SINGLEFILE_COMMIT_HASH = "849709c2a675054577217efa0d50e7b9e197823e";
// https://github.com/ruffle-rs/ruffle/releases
const string RUFFLE_URL = "nightly-2025-07-01/ruffle-nightly-2025_07_01-web-selfhosted.zip";
// https://github.com/webrecorder/replayweb.page/tree/gh-pages
const string REPLAY_COMMIT_HASH = "4f22f525c82cce6f8754ead51c66849b09794571";
// https://github.com/kiwix/kiwix-js/commits/gh-pages/
const string KIWIX_HASH = "380f5e3df7a05f0f957021867495c6305b98e7c9";

const string GRESOURCE = "./data/gresource.xml";
const string PARENT = "./data/vendored";
const string FILENAME_BUNDLE = "single-filez-bundle.js";
const string FILENAME_CAPTURE = "single-filez-capture.js";
const string[] SINGLEFILE_FILES = {
  "lib/single-file.js",
  "lib/single-file-bootstrap.js",
  "lib/single-file-hooks-frames.js",
};
const string[] ALLOWED_TYPES = {
	".wasm",
	".js",
	".cjs",
	".mjs"
};
const string[] REPLAY_FILES = {
	"ui.js",
	"sw.js",
	"adblock/adblock.gz",
};
const string[] DISALLOWED_TYPES = {
	".md",
	".txt",
	".map"
};

#if OFFLINE
	const string OFFLINE_FOLDER = "./offline";
#endif

enum Service {
	SINGLEFILE,
	REPLAY;
}

string get_gh_url (string file_name, Service service = Service.SINGLEFILE) {
	switch (service) {
		case Service.SINGLEFILE:
			return @"https://raw.githubusercontent.com/gildas-lormeau/SingleFile-MV3/$SINGLEFILE_COMMIT_HASH/$file_name";
		case Service.REPLAY:
			return @"https://raw.githubusercontent.com/webrecorder/replayweb.page/$REPLAY_COMMIT_HASH/$file_name";
		default:
			assert_not_reached ();
	}
}

void main () {
	#if OFFLINE
		message ("Offline mode");
	#elif USE_LIBSOUP
		message ("Libsoup mode");
	#endif

	try {
		message (@"Creating $PARENT…");
		File file_parent = File.new_for_path (PARENT);
		if (!file_parent.query_exists ()) file_parent.make_directory_with_parents ();
		message (@"Created $PARENT");

		message ("Fetching single-file-zip.min.js…");

		uint8[] contents;
		#if USE_LIBSOUP
			contents = soup_fetch (get_gh_url ("lib/single-file-zip.min.js"));
		#else
			#if OFFLINE
				File zip_file_remote = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, "single-file-zip.min.js"));
			#else
				File zip_file_remote = File.new_for_uri (get_gh_url ("lib/single-file-zip.min.js"));
			#endif
			zip_file_remote.load_contents (null, out contents, null);
		#endif
		message ("Fetched single-file-zip.min.js");

		message (@"Creating $FILENAME_CAPTURE…");

		string capture_script = """
			return JSON.stringify(await singlefile.getPageData({
				...singlefile_archives_settings,
				zipScript: %s
			}))
		""".printf ((new JSC.Value.string (new JSC.Context (), ((string) contents))).to_json (0));

		File capture_file = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, FILENAME_CAPTURE));
		if (capture_file.query_exists ()) capture_file.delete ();

		FileIOStream iostream = capture_file.replace_readwrite (null, false, FileCreateFlags.NONE);
		OutputStream ostream = iostream.output_stream;
		DataOutputStream dostream = new DataOutputStream (ostream);
		dostream.put_string (capture_script);
		capture_script = "";
		message (@"Created $FILENAME_CAPTURE");

		message (@"Creating $FILENAME_BUNDLE…");
		File bundle_file = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, FILENAME_BUNDLE));
		if (bundle_file.query_exists ()) bundle_file.delete ();

		FileIOStream stream = bundle_file.create_readwrite (FileCreateFlags.PRIVATE);
		DataOutputStream dos = new DataOutputStream (stream.output_stream);
		dos.put_string ("let _singleFileDefine; if (typeof define !== 'undefined') { _singleFileDefine = define; define = null }");

		foreach (string file_name in SINGLEFILE_FILES) {
			message (@"Fetching $file_name…");
			#if USE_LIBSOUP
				dos.write_all (soup_fetch (get_gh_url (file_name)), null, null);
			#else
				#if OFFLINE
					File file_remote = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, GLib.Path.get_basename (file_name)));
				#else
					string url = get_gh_url (file_name);
					File file_remote = File.new_for_uri (url);
				#endif

				dos.splice (file_remote.read (), GLib.OutputStreamSpliceFlags.CLOSE_SOURCE);
			#endif
			dos.put_string ("\n");
			message (@"Fetched $file_name");
		}
		dos.put_string ((string) contents);
		dos.put_string ("\n");
		contents = {};

		dos.put_string ("""
			const singlefile_archives_default_settings = {
				removeHiddenElements: false,
				removeUnusedStyles: true,
				removeUnusedFonts: true,
				removeSavedDate: false,
				removeFrames: false,
				compressHTML: true,
				compressCSS: false,
				loadDeferredImages: true,
				loadDeferredImagesMaxIdleTime: 1500,
				loadDeferredImagesBlockCookies: false,
				loadDeferredImagesBlockStorage: false,
				loadDeferredImagesKeepZoomLevel: false,
				loadDeferredImagesDispatchScrollEvent: false,
				compressContent: true,
				selfExtractingArchive: true,
				filenameTemplate: "%if-empty<{page-title}|No title> ({date-locale} {time-locale}).zip.html",
				infobarTemplate: "",
				includeInfobar: false,
				filenameMaxLength: 192,
				filenameMaxLengthUnit: "bytes",
				filenameReplacedCharacters: ["~", "+", "\\\\", "?", "%", "*", ":", "|", "\"", "<", ">", "\x00-\x1f", "\x7F"],
				filenameReplacementCharacter: "_",
				maxResourceSizeEnabled: false,
				maxResourceSize: 10,
				backgroundSave: true,
				removeAlternativeFonts: true,
				removeAlternativeMedias: true,
				// removeAlternativeImages: true,
				saveRawPage: false,
				resolveFragmentIdentifierURLs: false,
				userScriptEnabled: false,
				saveFavicon: true,
				includeBOM: false,
				insertMetaCSP: true,
				insertMetaNoIndex: false,
				password: "",
				insertSingleFileComment: true,
				blockImages: false,
				blockStylesheets: false,
				blockFonts: false,
				blockScripts: false,
				blockVideos: false,
				blockAudios: false,
			}
			let singlefile_archives_settings = {...singlefile_archives_default_settings}

			if (_singleFileDefine) { define = _singleFileDefine; _singleFileDefine = null }
			(function initSingleFile() {
				singlefile.init({
					fetch: (url, options) => {
						return new Promise(function (resolve, reject) {
							const xhrRequest = new XMLHttpRequest();
							xhrRequest.withCredentials = true;
							xhrRequest.responseType = "arraybuffer";
							xhrRequest.onerror = event => reject(new Error(event.detail));
							xhrRequest.onabort = () => reject(new Error("aborted"));
							xhrRequest.onreadystatechange = () => {
								if (xhrRequest.readyState == XMLHttpRequest.DONE) {
									resolve({
										arrayBuffer: async () => xhrRequest.response || new ArrayBuffer(),
										headers: { get: headerName => xhrRequest.getResponseHeader(headerName) },
										status: xhrRequest.status
									});
								}
							};
							xhrRequest.open("GET", url, true);
							if (options.headers) {
								for (const entry of Object.entries(options.headers)) {
									xhrRequest.setRequestHeader(entry[0], entry[1]);
								}
							}
							xhrRequest.send();
						});
					}
				});
			})();
		""");

		if (dos.has_pending ()) dos.flush ();
		message (@"Created $FILENAME_CAPTURE");

		// Ruffle
		string[] to_add_to_gresource;
		process_ruffle (out to_add_to_gresource);

		// ReplayWeb.page
		process_replayweb ();

		// Kiwix
		string[] to_add_to_gresource_kiwix;
		process_kiwix (out to_add_to_gresource_kiwix);

		// Gresource
		message ("Generating gresources…");
		File gresource = File.new_for_path (@"$GRESOURCE.in");
		gresource.load_contents (null, out contents, null);

		File gresource_out = File.new_for_path (GRESOURCE);
		if (gresource_out.query_exists ()) gresource_out.delete ();

		string gresource_snippet = "";
		foreach (string file_path in to_add_to_gresource) {
			gresource_snippet += @"<file alias=\"ruffle/$file_path\">vendored/ruffle/$file_path</file>\n";
		}

		string gresource_kiwix_snippet = "";
		foreach (string file_path in to_add_to_gresource_kiwix) {
			gresource_kiwix_snippet += @"<file alias=\"$file_path\">vendored/kiwix/$file_path</file>\n";
		}

		FileIOStream gresource_iostream = gresource_out.replace_readwrite (null, false, FileCreateFlags.NONE);
		OutputStream gresource_ostream = gresource_iostream.output_stream;
		DataOutputStream gresource_dostream = new DataOutputStream (gresource_ostream);
		gresource_dostream.put_string (((string) contents).printf (gresource_snippet, gresource_kiwix_snippet));
		message ("Generated gresources");
	} catch (Error e) {
		critical (e.message);
	}
}

void process_ruffle (out string[] to_add_to_gresource) throws GLib.Error {
	string[] to_add_to_gresource_temp = {};

	#if OFFLINE
		message (@"Moving Ruffle…");
		File ruffle_vendored = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle"));
		if (!ruffle_vendored.query_exists ()) ruffle_vendored.make_directory_with_parents ();

		string ruffle_dir_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, "ruffle");
		Dir ruffle_dir = Dir.open (ruffle_dir_path, 0);
		string? name = null;
		while ((name = ruffle_dir.read_name ()) != null) {
			string name_down = name.down ();
			int index_of_dot = name_down.last_index_of_char ('.');

			if (name_down.slice (index_of_dot, name_down.length) in ALLOWED_TYPES) {
				if (name_down != "ruffle.js")
				to_add_to_gresource_temp += name;

				ruffle_vendored = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle", name));
				var ruffle_source = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, ruffle_dir_path, name));
				ruffle_source.copy (ruffle_vendored, FileCopyFlags.OVERWRITE, null);
			}
		}
		message (@"Moved Ruffle");
	#else
		message ("Fetching Ruffle…");
		string ruffle_location = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle.zip");
		string ruffle_out = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle");

		File ruffle_zip = File.new_for_path (ruffle_location);
		#if USE_LIBSOUP
			FileOutputStream os = ruffle_zip.create (FileCreateFlags.PRIVATE);
			os.write_all (soup_fetch (@"https://github.com/ruffle-rs/ruffle/releases/download/$RUFFLE_URL"), null, null);
			os.close ();
		#else
			File ruffle_file = File.new_for_uri (@"https://github.com/ruffle-rs/ruffle/releases/download/$RUFFLE_URL");
			ruffle_file.copy (ruffle_zip, FileCopyFlags.OVERWRITE);
		#endif
		message ("Fetched Ruffle");

		File ruffle_out_file = File.new_for_path (ruffle_out);
		if (!ruffle_out_file.query_exists ()) ruffle_out_file.make_directory_with_parents ();

		message ("Extracting ruffle.zip…");
		Archive.Read archive = new Archive.Read ();
		archive.support_format_zip ();

		Archive.WriteDisk extractor = new Archive.WriteDisk ();
		extractor.set_options (Archive.ExtractFlags.ACL | Archive.ExtractFlags.FFLAGS);
		extractor.set_standard_lookup ();

		if (archive.open_filename (ruffle_location, 10240) != Archive.Result.OK) {
			critical ("Error opening %s: %s (%d)", ruffle_location, archive.error_string (), archive.errno ());
			return;
		}

		string prev_dir = GLib.Environment.get_current_dir ();
		Posix.chdir (ruffle_out);

		unowned Archive.Entry entry;
		Archive.Result last_result;
		while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {
			string entry_path = entry.pathname ();
			int index_of_dot = entry_path.last_index_of_char ('.');
			if (
				index_of_dot == -1
				|| !(entry_path.down ().slice (index_of_dot, entry_path.length) in ALLOWED_TYPES)
				|| extractor.write_header (entry) != Archive.Result.OK
			) continue;

			if (entry_path != "ruffle.js")
				to_add_to_gresource_temp += entry_path;

			unowned uint8[] buffer = null;
			Archive.int64_t offset;
			while (archive.read_data_block (out buffer, out offset) == Archive.Result.OK) {
				if (extractor.write_data_block (buffer, offset) != Archive.Result.OK) {
					break;
				}
			}
		}

		if (last_result != Archive.Result.EOF) {
			critical ("Error: %s (%d)", archive.error_string (), archive.errno ());
			return;
		}

		Posix.chdir (prev_dir);
		File.new_for_path (ruffle_location).delete ();
		message ("Extracted ruffle.zip");
	#endif

	to_add_to_gresource = to_add_to_gresource_temp;
}

void process_replayweb () throws GLib.Error {
	#if !OFFLINE
		message ("Fetching ReplayWeb.page…");
		foreach (string file_name in REPLAY_FILES) {
			message (@"Fetching $file_name…");
			File file_local = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, file_name));
			GLib.DirUtils.create_with_parents (GLib.Path.get_dirname (file_local.get_path ()), 0775);

			#if USE_LIBSOUP
				FileOutputStream os = file_local.create (FileCreateFlags.PRIVATE);
				os.write_all (soup_fetch (get_gh_url (file_name, Service.REPLAY)), null, null);
				os.close ();
			#else
				File file_remote = File.new_for_uri (get_gh_url (file_name, Service.REPLAY));
				file_remote.copy (file_local, FileCopyFlags.OVERWRITE);
			#endif
			message (@"Fetched $file_name");
		}
		message ("Fetched ReplayWeb.page");
	#endif
}

void process_kiwix (out string[] to_add_to_gresource_kiwix) throws GLib.Error {
	string[] to_add_to_gresource_kiwix_temp = {};

	#if OFFLINE
		message (@"Moving Kiwix…");
		File kiwix_vendored = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix"));
		if (!kiwix_vendored.query_exists ()) kiwix_vendored.make_directory_with_parents ();

		string kiwix_dir_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, "kiwix", @"kiwix-js-$KIWIX_HASH", "dist");
		if (!File.new_for_path (kiwix_dir_path).query_exists ()) {
			// Flatpak removes the annoying middle-folder
			kiwix_dir_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, "kiwix", "dist");
		}

		string [] files_temp;
		copy_recursive (kiwix_dir_path, "", out files_temp);
		foreach (string rec_f in files_temp) {
			to_add_to_gresource_kiwix_temp += rec_f;
		}

		message (@"Moved kiwix");
	#else
		string kiwix_out = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix-temp");
		string kiwix_location = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix.zip");

		message ("Fetching Kiwix…");
		File kiwix_zip = File.new_for_path (kiwix_location);

		#if USE_LIBSOUP
			FileOutputStream os = kiwix_zip.create (FileCreateFlags.PRIVATE);
			os.write_all (soup_fetch (@"https://github.com/kiwix/kiwix-js/archive/$KIWIX_HASH.zip"), null, null);
			os.close ();
		#else
			File kiwix_file = File.new_for_uri (@"https://github.com/kiwix/kiwix-js/archive/$KIWIX_HASH.zip");
			kiwix_file.copy (kiwix_zip, FileCopyFlags.OVERWRITE);
		#endif

		File kiwix_out_file = File.new_for_path (kiwix_out);
		if (!kiwix_out_file.query_exists ()) kiwix_out_file.make_directory_with_parents ();
		message ("Fetched Kiwix");

		message ("Extracting kiwix.zip…");
		Archive.Read archive = new Archive.Read ();
		archive.support_format_zip ();

		Archive.WriteDisk extractor = new Archive.WriteDisk ();
		extractor.set_options (Archive.ExtractFlags.ACL | Archive.ExtractFlags.FFLAGS);
		extractor.set_standard_lookup ();

		if (archive.open_filename (kiwix_location, 10240) != Archive.Result.OK) {
			critical ("Error opening %s: %s (%d)", kiwix_location, archive.error_string (), archive.errno ());
			return;
		}

		string prev_dir = GLib.Environment.get_current_dir ();
		Posix.chdir (kiwix_out);

		unowned Archive.Entry entry;
		Archive.Result last_result;
		while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {
			string entry_path = entry.pathname ();
			int index_of_dot = entry_path.last_index_of_char ('.');
			if (
				index_of_dot == -1
				|| entry_path.down ().slice (index_of_dot, entry_path.length) in DISALLOWED_TYPES
			) continue;

			string[] path_items = entry_path.split (GLib.Path.DIR_SEPARATOR_S);
			if (
				path_items.length < 2
				|| path_items[1] != "dist"
				|| path_items[2] == "_locales"
				|| path_items[2] == "replayWorker.js"
				|| path_items[2] == "package.json"
				|| path_items[2].has_prefix ("manifest.")
				|| extractor.write_header (entry) != Archive.Result.OK
			) continue;

			to_add_to_gresource_kiwix_temp += string.joinv (GLib.Path.DIR_SEPARATOR_S, path_items[2:path_items.length]);

			unowned uint8[] buffer = null;
			Archive.int64_t offset;
			while (archive.read_data_block (out buffer, out offset) == Archive.Result.OK) {
				if (extractor.write_data_block (buffer, offset) != Archive.Result.OK) {
					break;
				}
			}
		}

		if (last_result != Archive.Result.EOF) {
			critical ("Error: %s (%d)", archive.error_string (), archive.errno ());
			return;
		}

		Posix.chdir (prev_dir);
		File.new_for_path (kiwix_location).delete ();
		message ("Extracted kiwix.zip");

		string random_github_folder_for_no_reason = GLib.Path.build_path (Path.DIR_SEPARATOR_S, kiwix_out, @"kiwix-js-$KIWIX_HASH");
		File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, random_github_folder_for_no_reason, "dist")).move (
			File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, kiwix_out, "..", "kiwix")),
			GLib.FileCopyFlags.OVERWRITE
		);

		File.new_for_path (random_github_folder_for_no_reason).delete ();
		kiwix_out_file.delete ();
	#endif

	File file_to_fix = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix", "www", "index.html"));
	uint8[] content;
	file_to_fix.load_contents (null, out content, null);
	content = ((string) content).replace ("<meta name=\"referrer\" content=\"none\">", "").data;
	file_to_fix.replace_contents (content, null, false, FileCreateFlags.NONE, null);

	file_to_fix = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix", "www", "js", "bundle.js"));
	file_to_fix.load_contents (null, out content, null);
	content = ((string) content).replace ("'serviceWorker' in navigator", "false").data;
	file_to_fix.replace_contents (content, null, false, FileCreateFlags.NONE, null);

	file_to_fix = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix", "www", "js", "init.js"));
	file_to_fix.load_contents (null, out content, null);
	content = ((string) content)
		.replace ("params['contentInjectionMode'] =", "params['contentInjectionMode'] = 'jquery' ||")
		.replace ("params['defaultModeChangeAlertDisplayed'] =", "params['defaultModeChangeAlertDisplayed'] = true ||")
		.replace ("'serviceWorker' in navigator", "false")
		.data;
	file_to_fix.replace_contents (content, null, false, FileCreateFlags.NONE, null);

	to_add_to_gresource_kiwix = to_add_to_gresource_kiwix_temp;
}

public void copy_recursive (string kiwix_dir_path, string current_rel_vendored_dir, out string[] files) throws GLib.Error {
	string[] files_temp = {};

	Dir kiwix_dir = Dir.open (kiwix_dir_path, 0);
	string? name = null;
	while ((name = kiwix_dir.read_name ()) != null) {
		string name_down = name.down ();
		int index_of_dot = name_down.last_index_of_char ('.');

		if (
			!(name_down.slice (index_of_dot, name_down.length) in DISALLOWED_TYPES)
			&& name_down != "_locales"
			&& name_down != "replayworker.js"
			&& name_down != "package.json"
			&& !name_down.has_prefix ("manifest.")
		) {
			string new_rel_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, current_rel_vendored_dir, name);
			string vendor_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "kiwix", current_rel_vendored_dir);
			string entry_path = GLib.Path.build_path (Path.DIR_SEPARATOR_S, kiwix_dir_path, name);
			GLib.File entry = File.new_for_path (entry_path);
			GLib.File kiwix_vendored = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, vendor_path, name));

			GLib.FileType src_type = entry.query_file_type (GLib.FileQueryInfoFlags.NONE, null);
  			if (src_type == GLib.FileType.DIRECTORY) {
				if (!kiwix_vendored.query_exists ()) kiwix_vendored.make_directory_with_parents ();

				string[] rec;
				copy_recursive (
					entry_path,
					new_rel_path,
					out rec
				);

				foreach (string rec_s in rec) {
					files_temp += rec_s;
				}
			} else if (src_type == GLib.FileType.REGULAR) {
				files_temp += new_rel_path;
				entry.copy (kiwix_vendored, FileCopyFlags.OVERWRITE, null);
			}
		}
	}

	files = files_temp;
}

#if USE_LIBSOUP
	public uint8[] soup_fetch (string url) throws Error {
		var session = new Soup.Session ();
		var message = new Soup.Message ("GET", url);

		Bytes bytes = session.send_and_read (message, null);

		if (message.status_code != 200) {
			throw new IOError.FAILED ("HTTP %u while fetching %s".printf ((uint) message.status_code, url));
		}

		return (uint8[]) bytes.get_data ();
	}
#endif
