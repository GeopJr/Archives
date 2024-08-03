public class Archives.Views.RufflePage : Views.WebViewPage {
	~RufflePage () {
		debug ("Destroying RufflePage");
	}

	construct {
		try {
			app.server.run ();
		} catch (Error e) {
			critical (@"Error while trying to run server: $(e.message)");
			app.toast (e.message, 5);
		}

		this.webview.load_uri (@"http://localhost:$(app.server.port)/ruffle.html");
	}

	public int file_pos { get; set; }
	public string file_ext { get; set; }
	public RufflePage (int file_pos, string ext) {
		this.file_pos = file_pos;
		this.file_ext = ext;
	}

	protected override void on_load_changed (WebKit.LoadEvent load_event) {
		base.on_load_changed (load_event);
		if (load_event == WebKit.LoadEvent.FINISHED) {
			load_swf ();
		}
	}

	bool swf_loaded = false;
	private void load_swf () {
		if (swf_loaded) return;
		swf_loaded = true;

		string script = @"
			const ruffle = window.RufflePlayer.newest();
			const player = ruffle.createPlayer();
			document.getElementById(\"container\").appendChild(player);
			player.load(\"loaded-file/$(this.file_pos)$(this.file_ext)?password=$(app.server.password)\");
		";
		this.webview.evaluate_javascript.begin (
			script,
			-1,
			null,
			null,
			null
		);
	}
}
