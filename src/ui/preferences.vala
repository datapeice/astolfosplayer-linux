namespace G4 {
    namespace BlurMode {
        public const uint NEVER = 0;
        public const uint ALWAYS = 1;
        public const uint ART_ONLY = 2;
    }

    [GtkTemplate (ui = "/com/datapeice/astolfosplayer/gtk/preferences.ui")]
    public class PreferencesWindow : Adw.PreferencesWindow {
        [GtkChild]
        unowned Adw.ComboRow blur_row;
        [GtkChild]
        unowned Gtk.Switch compact_btn;
        [GtkChild]
        unowned Gtk.Switch grid_btn;
        [GtkChild]
        unowned Gtk.Switch single_btn;
        [GtkChild]
        unowned Gtk.Button music_dir_btn;
        [GtkChild]
        unowned Gtk.Switch monitor_btn;
        [GtkChild]
        unowned Gtk.Switch thumbnail_btn;
        [GtkChild]
        unowned Gtk.Switch playbkgnd_btn;
        [GtkChild]
        unowned Gtk.Switch rotate_btn;
        [GtkChild]
        unowned Gtk.Switch gapless_btn;
        [GtkChild]
        unowned Adw.ComboRow replaygain_row;
        [GtkChild]
        unowned Adw.ComboRow audiosink_row;
        [GtkChild]
        unowned Adw.ExpanderRow peak_row;
        [GtkChild]
        unowned Gtk.Entry peak_entry;
        [GtkChild]
        unowned Adw.EntryRow server_entry;
        [GtkChild]
        unowned Adw.EntryRow username_entry;
        [GtkChild]
        unowned Adw.PasswordEntryRow password_entry;
        [GtkChild]
        unowned Adw.PasswordEntryRow security_key_entry;
        [GtkChild]
        unowned Gtk.Entry token_entry;
        [GtkChild]
        unowned Gtk.Button login_btn;
        [GtkChild]
        unowned Gtk.Button register_btn;

        private GenericArray<Gst.ElementFactory> _audio_sinks = new GenericArray<Gst.ElementFactory> (8);

        public PreferencesWindow (Application app) {
            var settings = app.settings;

            blur_row.model = new Gtk.StringList ({_("Never"), _("Always"), _("Art Only")});
            settings.bind ("blur-mode", blur_row, "selected", SettingsBindFlags.DEFAULT);

            settings.bind ("compact-playlist", compact_btn, "active", SettingsBindFlags.DEFAULT);
            settings.bind ("grid-mode", grid_btn, "active", SettingsBindFlags.DEFAULT);
            settings.bind ("single-click-activate", single_btn, "active", SettingsBindFlags.DEFAULT);

            music_dir_btn.label = get_display_name (app.music_folder);
            music_dir_btn.clicked.connect (() => {
                pick_music_folder (app, this, (dir) => {
                    music_dir_btn.label = get_display_name (app.music_folder);
                });
            });

            settings.bind ("monitor-changes", monitor_btn, "active", SettingsBindFlags.DEFAULT);

            settings.bind ("remote-thumbnail", thumbnail_btn, "active", SettingsBindFlags.DEFAULT);

            settings.bind ("play-background", playbkgnd_btn, "active", SettingsBindFlags.DEFAULT);

            settings.bind ("rotate-cover", rotate_btn, "active", SettingsBindFlags.DEFAULT);

            replaygain_row.model = new Gtk.StringList ({_("Never"), _("Track"), _("Album")});
            settings.bind ("replay-gain", replaygain_row, "selected", SettingsBindFlags.DEFAULT);

            settings.bind ("gapless-playback", gapless_btn, "active", SettingsBindFlags.DEFAULT);

            settings.bind ("show-peak", peak_row, "enable_expansion", SettingsBindFlags.DEFAULT);
            settings.bind ("peak-characters", peak_entry, "text", SettingsBindFlags.DEFAULT);

            GstPlayer.get_audio_sinks (_audio_sinks);
            var sink_names = new string[_audio_sinks.length];
            for (var i = 0; i < _audio_sinks.length; i++)
                sink_names[i] = get_audio_sink_name (_audio_sinks[i]);
            audiosink_row.model = new Gtk.StringList (sink_names);
            this.bind_property ("audio_sink", audiosink_row, "selected", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

            settings.bind ("server-address", server_entry, "text", SettingsBindFlags.DEFAULT);
            settings.bind ("username", username_entry, "text", SettingsBindFlags.DEFAULT);
            settings.bind ("password", password_entry, "text", SettingsBindFlags.DEFAULT);
            settings.bind ("auth-token", token_entry, "text", SettingsBindFlags.DEFAULT);

            login_btn.clicked.connect (() => on_login_clicked (app));
            register_btn.clicked.connect (() => on_register_clicked (app));
        }

        private void on_login_clicked (Application app) {
            var username = username_entry.text;
            var password = password_entry.text;
            var server = server_entry.text;

            Thread.create<void*> (() => {
                try {
                    var client = new AuthClient (server);
                    var token = client.login (username, password);
                    Idle.add (() => {
                        token_entry.text = token;
                        app.settings.set_string ("auth-token", token);
                        return false;
                    });
                } catch (Error e) {
                    var msg = e.message;
                    Idle.add (() => {
                        stderr.printf ("Login failed: %s\n", msg);
                        return false;
                    });
                }
                return null;
            }, false);
        }

        private void on_register_clicked (Application app) {
            var username = username_entry.text;
            var password = password_entry.text;
            var server = server_entry.text;
            var security_key = security_key_entry.text;

            Thread.create<void*> (() => {
                try {
                    var client = new AuthClient (server);
                    var token = client.register (username, password, security_key);
                    Idle.add (() => {
                        token_entry.text = token;
                        app.settings.set_string ("auth-token", token);
                        return false;
                    });
                } catch (Error e) {
                    var msg = e.message;
                    Idle.add (() => {
                        stderr.printf ("Register failed: %s\n", msg);
                        return false;
                    });
                }
                return null;
            }, false);
        }

        public uint audio_sink {
            get {
                var app = (Application) GLib.Application.get_default ();
                var sink_name = app.player.audio_sink;
                for (int i = 0; i < _audio_sinks.length; i++) {
                    if (sink_name == _audio_sinks[i].name)
                        return i;
                }
                return _audio_sinks.length > 0 ? 0 : -1;
            }
            set {
                if (value < _audio_sinks.length) {
                    var app = (Application) GLib.Application.get_default ();
                    app.player.audio_sink = _audio_sinks[value].name;
                }
            }
        }
    }

    public string get_audio_sink_name (Gst.ElementFactory factory) {
        var name = factory.get_metadata ("long-name") ?? factory.name;
        name = name.replace ("Audio sink", "")
                    .replace ("Audio Sink", "")
                    .replace ("sink", "")
                    .replace ("(", "").replace (")", "");
        return name.strip ();
    }

    public delegate void FolderPicked (File dir);

    public void pick_music_folder (Application app, Gtk.Window? parent, FolderPicked picked) {
        var music_dir = File.new_for_uri (app.music_folder);
        show_select_folder_dialog.begin (parent, music_dir, (obj, res) => {
            var dir = show_select_folder_dialog.end (res);
            if (dir != null) {
                var uri = ((!)dir).get_uri ();
                if (app.music_folder != uri)
                    app.music_folder = uri;
                picked ((!)dir);
            }
        });
    }
}
