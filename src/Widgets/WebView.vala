public class Archives.Widgets.WebView : WebKit.WebView {
	construct {
		WebKit.Settings webkit_settings = new WebKit.Settings () {
			default_font_family = Gtk.Settings.get_default ().gtk_font_name,
			allow_file_access_from_file_urls = false,
			allow_modal_dialogs = false,
			allow_universal_access_from_file_urls = false,
			auto_load_images = true,
			disable_web_security = true,
			javascript_can_open_windows_automatically = false,
			enable_developer_extras = Build.PROFILE == "development",
			enable_back_forward_navigation_gestures = true,
			//  enable_caret_browsing = true,
			enable_dns_prefetching = false,
			enable_fullscreen = true,
			enable_media = true,
			enable_media_capabilities = true,
			enable_mediasource = true,
			enable_site_specific_quirks = true,
			enable_webaudio = true,
			enable_webgl = true,
			enable_webrtc = false, // prevent leak, might re-enable if needed
			enable_write_console_messages_to_stdout = Build.PROFILE == "development",
			javascript_can_access_clipboard = false,
			javascript_can_open_windows_automatically = false,
			enable_html5_database = true,
			enable_html5_local_storage = true,
			enable_smooth_scrolling = true,
			hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.NEVER
		};

		if (Archives.settings.user_agent != "") {
			webkit_settings.set_user_agent (Archives.settings.user_agent);
		} else {
			webkit_settings.set_user_agent_with_application_details (Build.NAME, Build.VERSION);
		}
		this.settings = webkit_settings;

		Gtk.GestureClick back_click_gesture = new Gtk.GestureClick () {
			button = 8
		};
		back_click_gesture.pressed.connect (go_back);
		add_controller (back_click_gesture);

		Gtk.GestureClick forward_click_gesture = new Gtk.GestureClick () {
			button = 9
		};
		forward_click_gesture.pressed.connect (go_forward);
		add_controller (forward_click_gesture);
	}
}
