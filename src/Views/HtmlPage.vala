public class Archives.Views.HtmlPage : Views.WebViewPage {
	~HtmlPage () {
		debug ("Destroying HtmlPage");
	}

	construct {
		this.webview.network_session.download_started.connect (download_in_browser);
		this.webview.decide_policy.connect (open_new_tab_in_browser);
		this.has_navigation_bar = true;
	}

	public HtmlPage (string path, bool with_server = false) {
		string t_path = path;
		if (with_server) {
			try {
				app.server.run ();
			} catch (Error e) {
				critical (@"Error while trying to run server: $(e.message)");
				app.toast (e.message, 5);
			}

			t_path = @"http://localhost:$(app.server.port)$path";
		}

		this.webview.load_uri (t_path);
	}
}
