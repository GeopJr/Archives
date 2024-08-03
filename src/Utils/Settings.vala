// vala-lint=ellipsis
public class Archives.Utils.Settings : GLib.Settings {
	public string user_agent { get; set; }
	public bool replaywebpage_adblock { get; set; }
	public bool singlefile_compress_html { get; set; }
	public bool singlefile_compress_css { get; set; }
	public bool singlefile_insert_meta_csp { get; set; }
	public bool singlefile_remove_hidden_elements { get; set; }
	public bool singlefile_remove_unused_styles { get; set; }
	public bool singlefile_remove_unused_fonts { get; set; }
	public bool singlefile_remove_frames { get; set; }
	public bool singlefile_display_infobar { get; set; }
	public bool singlefile_include_infobar { get; set; }
	public bool singlefile_save_deferred_images { get; set; }
	public bool singlefile_block_videos { get; set; }
	public bool singlefile_block_audios { get; set; }
	public bool singlefile_block_scripts { get; set; }
	public bool singlefile_block_images { get; set; }
	public bool singlefile_block_styles { get; set; }
	public bool singlefile_block_fonts { get; set; }

	public string to_single_file_js () {
		return """
			singlefile_archives_settings = {
				...singlefile_archives_settings,
				removeHiddenElements: %s,
				removeUnusedStyles: %s,
				removeUnusedFonts: %s,
				removeFrames: %s,
				compressHTML: %s,
				compressCSS: %s,
				loadDeferredImages: %s,
				blockScripts: %s,
				blockVideos: %s,
				blockAudios: %s,
				blockFonts: %s,
				blockStylesheets: %s,
				blockImages: %s,
				insertMetaCSP: %s,
				displayInfobar: %s,
				includeInfobar: %s,
			}
		""".printf (
			singlefile_remove_hidden_elements.to_string (),
			singlefile_remove_unused_styles.to_string (),
			singlefile_remove_unused_fonts.to_string (),
			singlefile_remove_frames.to_string (),
			singlefile_compress_html.to_string (),
			singlefile_compress_css.to_string (),
			singlefile_save_deferred_images.to_string (),
			singlefile_block_scripts.to_string (),
			singlefile_block_videos.to_string (),
			singlefile_block_audios.to_string (),
			singlefile_block_fonts.to_string (),
			singlefile_block_styles.to_string (),
			singlefile_block_images.to_string (),
			singlefile_insert_meta_csp.to_string (),
			singlefile_display_infobar.to_string (),
			singlefile_include_infobar.to_string ()
		);
	}

	private static string[] keys_to_init = {
		"user-agent",
		"replaywebpage-adblock",
		"singlefile-compress-html",
		"singlefile-compress-css",
		"singlefile-insert-meta-csp",
		"singlefile-remove-hidden-elements",
		"singlefile-remove-unused-styles",
		"singlefile-remove-unused-fonts",
		"singlefile-remove-frames",
		"singlefile-display-infobar",
		"singlefile-include-infobar",
		"singlefile-save-deferred-images",
		"singlefile-block-videos",
		"singlefile-block-audios",
		"singlefile-block-scripts",
		"singlefile-block-images",
		"singlefile-block-styles",
		"singlefile-block-fonts"
	};

	public Settings () {
		Object (schema_id: Build.DOMAIN);

		foreach (var key in keys_to_init) {
			init (key);
		}
	}

	void init (string key, bool apply_instantly = false) {
		bind (key, this, key, SettingsBindFlags.DEFAULT);
	}
}
