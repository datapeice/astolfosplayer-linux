using GLib;
using Soup;
using Json;

public class AuthClient {
    private string server_address;

    public AuthClient (string address) {
        server_address = address;
    }

    public string login (string username, string password) throws Error {
        if (server_address == null || server_address.strip ().length == 0)
            throw new Error (Quark.from_string ("auth"), 1, "No server address");

        // Use the Python gRPC helper to call the gRPC auth service.
        // discover the helper script at runtime (several candidate paths)
        string[] candidates = { "tools/grpc_auth_client.py", "../tools/grpc_auth_client.py", "../../tools/grpc_auth_client.py", "/usr/local/bin/grpc_auth_client.py" };
        string script = null;
        foreach (var p in candidates) {
            if (GLib.File.new_for_path (p).query_exists ()) {
                script = p;
                break;
            }
        }
        if (script == null)
            script = "tools/grpc_auth_client.py"; // fallback — rely on PATH or working dir

        var server = server_address;
        var argv = new string[] { "python3", script, server, "login", username, password };
        try {
            string out;
            string err;
            int status;
            GLib.spawn_sync (null, argv, null, GLib.SpawnFlags.SEARCH_PATH, null, out out, out err, out status);
            if (status != 0) {
                // try parsing error message
                try {
                    var parser = new Json.Parser ();
                    parser.load_from_data (err.length > 0 ? err : out, -1);
                    var root = parser.get_root ();
                    if (root != null && root.get_node_type () == Json.NodeType.OBJECT) {
                        var obj = root.get_object ();
                        var token_err = obj.get_string_member ("error");
                        throw new Error (Quark.from_string ("auth"), 1, token_err ?? "Login failed");
                    }
                } catch (Error) {
                    throw new Error (Quark.from_string ("auth"), 1, "Login failed");
                }
            }

            var parser = new Json.Parser ();
            parser.load_from_data (out, -1);
            var root = parser.get_root ();
            if (root == null || root.get_node_type () != Json.NodeType.OBJECT)
                throw new Error (Quark.from_string ("auth"), 1, "Invalid response");
            var obj = root.get_object ();
            var token = obj.get_string_member ("token");
            if (token == null)
                throw new Error (Quark.from_string ("auth"), 1, "No token in response");
            return token;
        } catch (Error e) {
            throw e;
        }
    }

    public string register (string username, string password, string security_key) throws Error {
        if (server_address == null || server_address.strip ().length == 0)
            throw new Error (Quark.from_string ("auth"), 1, "No server address");

        string[] candidates = { "tools/grpc_auth_client.py", "../tools/grpc_auth_client.py", "../../tools/grpc_auth_client.py", "/usr/local/bin/grpc_auth_client.py" };
        string script = null;
        foreach (var p in candidates) {
            if (GLib.File.new_for_path (p).query_exists ()) {
                script = p;
                break;
            }
        }
        if (script == null)
            script = "tools/grpc_auth_client.py";

        var server = server_address;
        var argv = new string[] { "python3", script, server, "register", username, password, security_key };
        try {
            string out;
            string err;
            int status;
            GLib.spawn_sync (null, argv, null, GLib.SpawnFlags.SEARCH_PATH, null, out out, out err, out status);
            if (status != 0) {
                try {
                    var parser = new Json.Parser ();
                    parser.load_from_data (err.length > 0 ? err : out, -1);
                    var root = parser.get_root ();
                    if (root != null && root.get_node_type () == Json.NodeType.OBJECT) {
                        var obj = root.get_object ();
                        var token_err = obj.get_string_member ("error");
                        throw new Error (Quark.from_string ("auth"), 1, token_err ?? "Register failed");
                    }
                } catch (Error) {
                    throw new Error (Quark.from_string ("auth"), 1, "Register failed");
                }
            }

            var parser = new Json.Parser ();
            parser.load_from_data (out, -1);
            var root = parser.get_root ();
            if (root == null || root.get_node_type () != Json.NodeType.OBJECT)
                throw new Error (Quark.from_string ("auth"), 1, "Invalid response");
            var obj = root.get_object ();
            var token = obj.get_string_member ("token");
            if (token == null)
                throw new Error (Quark.from_string ("auth"), 1, "No token in response");
            return token;
        } catch (Error e) {
            throw e;
        }
    }
}