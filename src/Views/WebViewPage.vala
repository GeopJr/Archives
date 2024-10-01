public class Archives.Views.WebViewPage : Gtk.Box {
	public string title { get; protected set; }
	public string subtitle { get; protected set; }
	public bool has_navigation_bar { get; protected set; default=false; }
	public bool can_go_forward { get; private set; default=false; }
	public bool can_go_back { get; private set; default=false; }

	protected double progress {
		get {
			return progressbar.fraction;
		}

		set {
			progressbar.fraction = value;
			progressbar.visible = value > 0 && value < 1;
		}
	}

	protected Widgets.WebView webview { get; private set; }

	~WebViewPage () {
		debug ("Destroying WebViewPage");
	}

	Gtk.ProgressBar progressbar;
	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 0;

		progressbar = new Gtk.ProgressBar () {
			visible = false
		};
		progressbar.add_css_class ("osd");
		this.append (progressbar);

		this.webview = new Widgets.WebView () {
			vexpand = true,
			hexpand = true
		};
		this.append (this.webview);

		this.webview.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
		this.webview.bind_property ("uri", this, "subtitle", BindingFlags.SYNC_CREATE);
		this.webview.bind_property ("estimated-load-progress", this, "progress", BindingFlags.SYNC_CREATE);
		this.webview.load_changed.connect (on_load_changed);

		this.webview.web_context.set_cache_model (WebKit.CacheModel.DOCUMENT_BROWSER);
	}

	protected virtual void on_load_changed (WebKit.LoadEvent load_event) {
		this.can_go_forward = this.webview.can_go_forward ();
		this.can_go_back = this.webview.can_go_back ();
	}

	public void load_uri (string uri) {
		string clean_uri = uri;
		bool is_valid = true;

		if (
			clean_uri.index_of_char (' ') == -1
			&& clean_uri.index_of ("://") == -1
			&& clean_uri.index_of_char ('.') > -1
		) clean_uri = @"https://$clean_uri";
		try {
			is_valid = GLib.Uri.is_valid (clean_uri, GLib.UriFlags.NONE);
		} catch {
			is_valid = false;
		}

		if (!is_valid) clean_uri = @"https://start.duckduckgo.com/?k5=1&kay=b&kpsb=-1&kbg=-1&kbd=-1&kp=-2&k1=-1&kak=-1&kax=-1&kaq=-1&kap=-1&kao=-1&kau=-1&q=$(GLib.Uri.escape_string (uri))";
		this.webview.load_uri (clean_uri);
	}

	public void go_forward () {
		this.webview.go_forward ();
	}

	public void go_back () {
		this.webview.go_back ();
	}

	protected void download_in_browser (WebKit.Download download) {
		download.cancel ();
		Utils.Host.open_url (download.get_request ().uri);
	}

	protected bool open_new_tab_in_browser (WebKit.PolicyDecision decision, WebKit.PolicyDecisionType type) {
		switch (type) {
			case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
				WebKit.NavigationPolicyDecision navigation_decision = decision as WebKit.NavigationPolicyDecision;
				if (navigation_decision == null) return false;

				Utils.Host.open_url (navigation_decision.navigation_action.get_request ().uri);
				navigation_decision.ignore ();
				return true;
			case WebKit.PolicyDecisionType.RESPONSE:
				WebKit.ResponsePolicyDecision response_decision = decision as WebKit.ResponsePolicyDecision;
				if (
					response_decision == null
					|| response_decision.is_mime_type_supported ()
					|| response_decision.response.mime_type.has_prefix ("text/")
				) return false;

				Utils.Host.open_url (response_decision.request.uri);
				response_decision.ignore ();
				return true;
			default:
				return false;
		}
	}
}
