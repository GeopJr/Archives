public class Archives.Views.ReplayPage : Views.WebViewPage {
	~ReplayPage () {
		debug ("Destroying ReplayPage");
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
		this.webview.load_uri (@"http://localhost:$(app.server.port)/replay.html");
	}

	public int file_pos { get; set; }
	public string file_ext { get; set; }
	public ReplayPage (int file_pos, string ext) {
		this.file_pos = file_pos;
		this.file_ext = ext;
	}

	protected override void on_load_changed (WebKit.LoadEvent load_event) {
		base.on_load_changed (load_event);
		if (load_event == WebKit.LoadEvent.FINISHED) {
			load_replay ();
		}
	}

	// If replaywebpage fails to load something
	// it prompts the user to refresh
	// doing so however, would not cause the
	// following script to run again
	// so let's just let it run as many times as it needs
	//
	//  bool replay_loaded = false;
	private void load_replay () {
		//  if (replay_loaded) return;
		//  replay_loaded = true;

		string script = @"load_replay(\"loaded-file/$(this.file_pos)$(this.file_ext)?password=$(app.server.password)\", $(settings.replaywebpage_adblock));";
		this.webview.evaluate_javascript.begin (
			script,
			-1,
			null,
			null,
			null
		);
	}
}
