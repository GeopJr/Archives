public class Archives.Widgets.ProgressBin : Adw.Bin {
	Gdk.RGBA color;

	private double _progress = 0;
	public double progress {
		get { return _progress; }
		set {
			double new_val = value.clamp (0.0, 1.0);
			if (new_val == 1) new_val = 0;
			if (_progress != new_val) {
				_progress = new_val;
				this.queue_draw ();
			}
		}
	}

	private void update_accent_color () {
		color = Adw.StyleManager.get_default ().get_accent_color_rgba ();
		color.alpha = 0.5f;
		if (this.progress != 0) this.queue_draw ();
	}

	construct {
		var default_sm = Adw.StyleManager.get_default ();
		if (default_sm.system_supports_accent_colors) {
			default_sm.notify["accent-color-rgba"].connect (update_accent_color);
			update_accent_color ();
		} else {
			color = {
				120 / 255.0f,
				174 / 255.0f,
				237 / 255.0f,
				0.5f
			};
		}
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		snapshot.append_color (
			color,
			Graphene.Rect () {
				origin = Graphene.Point () {
					x = 0,
					y = 0
				},
				size = Graphene.Size () {
					height = this.get_height (),
					width = (float) (this.get_width () * this.progress)
				}
			}
		);

		base.snapshot (snapshot);
	}
}
