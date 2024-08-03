public class Archives.Utils.MushroomSoupServer : Soup.Server {
	public int port { get; private set; default = -1; }
	public bool running { get; private set; default = false; }
	public string password { get; private set; }

	construct {
		this.password = GLib.Uuid.string_random ();
		this.tls_auth_mode = GLib.TlsAuthenticationMode.NONE;
		this.add_handler (null, resource_handler);
		//  this.add_handler ("/file/", file_handler);
		this.add_handler ("/loaded-file/", loaded_file_handler);
	}

	private void resource_handler (Soup.Server server, Soup.ServerMessage msg, string path, GLib.HashTable<string, string>? query) {
		// Do not handle hidden files, parent folders or folders
		if (path.contains ("/.") || path.has_suffix ("/")) {
			msg.set_status (404, null);
			return;
		}

		msg.pause ();
		try {
			size_t resource_size;
			GLib.resources_get_info (
				@"/dev/geopjr/Archives$path",
				ResourceLookupFlags.NONE,
				out resource_size,
				null
			);

			InputStream input_stream = GLib.resources_open_stream (
				@"/dev/geopjr/Archives$path",
				ResourceLookupFlags.NONE
			);

			uint8[] data = new uint8[resource_size];
			input_stream.read_all_async.begin (data, GLib.Priority.DEFAULT, null, (obj, res) => {
				try {
					if (input_stream.read_all_async.end (res, null)) {
						string mime = GLib.ContentType.guess (GLib.Path.get_basename (path), data, null);
						msg.set_status (200, null);
						msg.set_response (mime, Soup.MemoryUse.COPY, data);
					} else {
						msg.set_status (404, null);
					}
				} catch (Error e) {
					debug (@"[Soup] Error while trying to read $path: $(e.message)");
					msg.set_status (404, null);
				}

				msg.unpause ();
			});
		} catch (Error e) {
			debug (@"[Soup] Error while trying to open $path: $(e.message)");
			msg.set_status (404, null);
			msg.unpause ();
		}
	}

	//  private void file_handler (Soup.Server server, Soup.ServerMessage msg, string path, GLib.HashTable<string, string>? query) {
	//  	// Do not handle hidden files, parent folders or folders
	//  	if (path.contains ("/.") || path.has_suffix ("/")) {
	//  		msg.set_status (404, null);
	//  		return;
	//  	}

	//  	string clear_path = path;
	//  	if (clear_path.has_prefix ("/file/")) clear_path = clear_path.splice (0, 5);

	//  	string file_path = Path.build_filename (".", clear_path);
	//  	var file = File.new_for_path (file_path);

	//  	if (!file.query_exists ()) {
	//  		msg.set_status (404, null);
	//  		return;
	//  	}

	//  	msg.pause ();
	//  	file.load_contents_async.begin (null, (obj, res) => {
	//  		uint8[] data = {};
	//  		try {
	//  			file.load_contents_async.end (res, out data, null);
	//  			string mime = GLib.ContentType.guess (file_path, data, null);
	//  			msg.set_response (mime, Soup.MemoryUse.COPY, data);
	//  			msg.set_status (200, null);
	//  		} catch (Error e) {
	//  			debug (@"[Soup] Error while trying to read $file_path: $(e.message)");
	//  			msg.set_status (404, null);
	//  		}
	//  		msg.unpause ();
	//  	});
	//  }

	private void loaded_file_handler (Soup.Server server, Soup.ServerMessage msg, string path, GLib.HashTable<string, string>? query) {
		// Do not handle hidden files, parent folders or folders
		if (
			path.contains ("/.") || path.has_suffix ("/")
			// let's require a password for the loaded-files handler
			// as to not allow misconfigured systems or rogue programs
			// to access the files easily
			|| query == null || query.length == 0 || !query.contains ("password") || query.get ("password") != this.password
		) {
			msg.set_status (404, null);
			return;
		}

		string? file_path = app.get_loaded_file_location (int.parse (GLib.Path.get_basename (path)));
		if (file_path == null) {
			msg.set_status (404, null);
			return;
		}

		var file = File.new_for_path (file_path);
		if (!file.query_exists ()) {
			msg.set_status (404, null);
			return;
		}

		msg.pause ();
		file.load_contents_async.begin (null, (obj, res) => {
			uint8[] data = {};
			try {
				file.load_contents_async.end (res, out data, null);
				string mime = GLib.ContentType.guess (file_path, data, null);
				msg.set_response (mime, Soup.MemoryUse.COPY, data);
				msg.set_status (200, null);
			} catch (Error e) {
				debug (@"[Soup] Error while trying to read $file_path: $(e.message)");
				msg.set_status (404, null);
			}
			msg.unpause ();
		});
	}

	public void run () throws GLib.Error {
		if (this.running) return;

		this.listen_local (0, Soup.ServerListenOptions.IPV4_ONLY);
		this.port = this.get_uris ().nth_data (0).get_port ();
		this.running = true;
	}

	public void stop () {
		if (!this.running) return;

		this.disconnect ();
		this.port = -1;
		this.running = false;
	}
}
