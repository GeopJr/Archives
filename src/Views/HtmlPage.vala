public class Archives.Views.HtmlPage : Views.WebViewPage {
	~HtmlPage () {
		debug ("Destroying HtmlPage");
	}

	construct {
		this.webview.network_session.download_started.connect (download_in_browser);
		this.webview.decide_policy.connect (open_new_tab_in_browser);
		this.has_navigation_bar = true;
	}

	public HtmlPage (string path) {
		this.webview.load_uri (path);
	}
}
