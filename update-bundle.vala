const string GRESOURCE = "./data/gresource.xml";
const string PARENT = "./data/vendored";
const string FILENAME_BUNDLE = "single-filez-bundle.js";
const string FILENAME_CAPTURE = "single-filez-capture.js";
const string SINGLEFILE_COMMIT_HASH = "2962d4f89accbb36aaaa1502022bb29715497566";
const string RUFFLE_URL = "nightly-2024-10-01/ruffle-nightly-2024_10_01-web-selfhosted.zip";
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
const string REPLAY_COMMIT_HASH = "c24cafe21015da4e4c05c9f75c2b9991c2501849";
const string[] REPLAY_FILES = {
	"ui.js",
	"sw.js",
	"adblock/adblock.gz",
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
			return @"https://raw.githubusercontent.com/gildas-lormeau/single-filez-cli/$SINGLEFILE_COMMIT_HASH/$file_name";
		case Service.REPLAY:
			return @"https://raw.githubusercontent.com/webrecorder/replayweb.page/$REPLAY_COMMIT_HASH/$file_name";
		default:
			assert_not_reached ();
	}
}

void main () {
	#if OFFLINE
		message ("Offline mode");
	#endif

	try {
		string[] to_add_to_gresource = {};

		message (@"Creating $PARENT…");
		File file_parent = File.new_for_path (PARENT);
		if (!file_parent.query_exists ()) file_parent.make_directory_with_parents ();
		message (@"Created $PARENT");

		message ("Fetching single-file-zip.min.js…");
		#if OFFLINE
			File zip_file_remote = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, "single-file-zip.min.js"));
		#else
			File zip_file_remote = File.new_for_uri (get_gh_url ("lib/single-file-zip.min.js"));
		#endif
		uint8[] contents;
		zip_file_remote.load_contents (null, out contents, null);
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
			#if OFFLINE
				File file_remote = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, OFFLINE_FOLDER, GLib.Path.get_basename (file_name)));
			#else
				string url = get_gh_url (file_name);
				File file_remote = File.new_for_uri (url);
			#endif

			dos.splice (file_remote.read (), GLib.OutputStreamSpliceFlags.CLOSE_SOURCE);
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

		// In offline mode, outside tools are responsible
		// for extracting Ruffle and ReplayWeb.page doesn't
		// need any processing
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
						to_add_to_gresource += name;

					ruffle_vendored = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle", name));
					var ruffle_source = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, ruffle_dir_path, name));
					ruffle_source.copy (ruffle_vendored, FileCopyFlags.OVERWRITE, null);
				}
			}
			message (@"Moved Ruffle");
		#else
			// Ruffle
			message ("Fetching Ruffle…");
			string ruffle_location = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle.zip");
			string ruffle_out = GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, "ruffle");

			File ruffle_file = File.new_for_uri (@"https://github.com/ruffle-rs/ruffle/releases/download/$RUFFLE_URL");
			File ruffle_zip = File.new_for_path (ruffle_location);
			ruffle_file.copy (ruffle_zip, FileCopyFlags.OVERWRITE);
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
					to_add_to_gresource += entry_path;

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

			// ReplayWeb.page
			message ("Fetching ReplayWeb.page…");
			foreach (string file_name in REPLAY_FILES) {
				message (@"Fetching $file_name…");
				File file_local = File.new_for_path (GLib.Path.build_path (Path.DIR_SEPARATOR_S, PARENT, file_name));
				GLib.DirUtils.create_with_parents (GLib.Path.get_dirname (file_local.get_path ()), 0775);

				File file_remote = File.new_for_uri (get_gh_url (file_name, Service.REPLAY));
				file_remote.copy (file_local, FileCopyFlags.OVERWRITE);
				message (@"Fetched $file_name");
			}
			message ("Fetched ReplayWeb.page");
		#endif

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

		FileIOStream gresource_iostream = gresource_out.replace_readwrite (null, false, FileCreateFlags.NONE);
		OutputStream gresource_ostream = gresource_iostream.output_stream;
		DataOutputStream gresource_dostream = new DataOutputStream (gresource_ostream);
		gresource_dostream.put_string (((string) contents).printf (gresource_snippet));
		message ("Generated gresources");
	} catch (Error e) {
		critical (e.message);
	}
}
