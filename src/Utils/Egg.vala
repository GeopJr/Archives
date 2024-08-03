public class Archives.Utils.Egg {
	// I forgot which is which
	const string[] EGGS = {
		"468851703",
		"3900270425",
		"1902006259",
		"1105814355",
		"2605595328",
		"641933291",
		"1824731590",
		"2476989764",
		"2221426966",
		"3573205871",
		"931958616",
		"1682819046",
		"3925165715",
		"772678320",
		"748121027",
		"2257070751",
		"551136399",
		"2874416960",
		"2411711478",
		"2558648716",
		"993261724"
	};

	public static string get_css_class (string url) {
		try {
			string hash = GLib.str_hash (GLib.Uri.parse (url.down (), GLib.UriFlags.NONE).get_host ()).to_string ();
			if (hash in EGGS)
				return @"egg-$hash";
		} catch {}

		return "";
	}
}
