public class Archives.Views.KiwixPage : Views.WebViewPage {
	~KiwixPage () {
		debug ("Destroying KiwixPage");
	}

	construct {
		try {
			app.server.run ();
		} catch (Error e) {
			critical (@"Error while trying to run server: $(e.message)");
			app.toast (e.message, 5);
		}

		this.webview.network_session.download_started.connect (download_in_browser);
		this.webview.decide_policy.connect (open_new_tab_in_browser);
		this.webview.load_uri (@"http://localhost:$(app.server.port)/kiwix/index.html?allowInternetAccess=false&contentInjectionMode=jquery&defaultModeChangeAlertDisplayed=true");

		this.webview.web_context.set_cache_model (WebKit.CacheModel.WEB_BROWSER);
	}
}
