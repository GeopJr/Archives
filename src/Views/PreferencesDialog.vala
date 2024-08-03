[GtkTemplate (ui = "/dev/geopjr/Archives/ui/preferences.ui")]
public class Archives.Dialogs.Preferences : Adw.PreferencesDialog {
	[GtkChild] unowned Adw.EntryRow user_agent_entry;
	[GtkChild] unowned Adw.SwitchRow compress_html_switch;
	[GtkChild] unowned Adw.SwitchRow compress_css_switch;
	[GtkChild] unowned Adw.SwitchRow csp_switch;
	[GtkChild] unowned Adw.SwitchRow remove_hidden_elements_switch;
	[GtkChild] unowned Adw.SwitchRow remove_unused_styles_switch;
	[GtkChild] unowned Adw.SwitchRow remove_unused_fonts_switch;
	[GtkChild] unowned Adw.SwitchRow remove_iframes_switch;
	[GtkChild] unowned Adw.SwitchRow display_infobar_switch;
	[GtkChild] unowned Adw.SwitchRow include_infobar_switch;
	[GtkChild] unowned Adw.SwitchRow save_deferred_images_switch;
	[GtkChild] unowned Adw.SwitchRow block_video_switch;
	[GtkChild] unowned Adw.SwitchRow block_audio_switch;
	[GtkChild] unowned Adw.SwitchRow block_scripts_switch;
	[GtkChild] unowned Adw.SwitchRow block_images_switch;
	[GtkChild] unowned Adw.SwitchRow block_styles_switch;
	[GtkChild] unowned Adw.SwitchRow block_fonts_switch;
	[GtkChild] unowned Adw.SwitchRow use_adblock_switch;

	~Preferences () {
		debug ("Destroying Preferences");
	}

	construct {
		bind ();
	}

	void bind () {
		settings.bind ("replaywebpage-adblock", use_adblock_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-compress-html", compress_html_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-compress-css", compress_css_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-insert-meta-csp", csp_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-remove-hidden-elements", remove_hidden_elements_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-remove-unused-styles", remove_unused_styles_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-remove-unused-fonts", remove_unused_fonts_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-remove-frames", remove_iframes_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-display-infobar", display_infobar_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-include-infobar", include_infobar_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-save-deferred-images", save_deferred_images_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-block-videos", block_video_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-block-audios", block_audio_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-block-scripts", block_scripts_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-block-images", block_images_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-block-styles", block_styles_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("singlefile-block-fonts", block_fonts_switch, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("user-agent", user_agent_entry, "text", SettingsBindFlags.DEFAULT);
	}
}
