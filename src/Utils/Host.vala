public class Archives.Utils.Host {
	// Open a URI in the user's default application
	public static bool open_url (string _uri) {
		var uri = _uri;
		if (!("://" in uri))
			uri = "file://" + _uri;

		open_in_default_app (uri);
		return true;
	}

	// To avoid creating multiple Uri instances,
	// split opening into two wrappers, one for
	// strings and one for GLib.Uri
	public static bool open_uri (Uri uri) {
		open_in_default_app (uri.to_string ());

		return true;
	}

	private static void open_in_default_app (string uri) {
		debug (@"Opening URI: $uri");
		try {
			AppInfo.launch_default_for_uri (uri, null);
		} catch (Error e) {
			var launcher = new Gtk.UriLauncher (uri);
			launcher.launch.begin (app.main_window, null, (obj, res) => {
				try {
					launcher.launch.end (res);
				} catch (Error e) {
					warning (@"Error opening uri \"$uri\": $(e.message)");
				}
			});
		}
	}
}
