class_name GoogleAuthManager
extends RefCounted

## GoogleAuthManager – Google Identity Services (GIS) Web OAuth Bridge for Itch.io
## Enables players to sign in with Google to sync scores and usernames across all devices.

const GOOGLE_CLIENT_ID: String = "178792813633-tc8nml8vi8sok723pnojkb78n24854tb.apps.googleusercontent.com"

static var _instance: GoogleAuthManager = null
static var _js_callback = null

static func get_instance() -> GoogleAuthManager:
	if _instance == null:
		_instance = GoogleAuthManager.new()
	return _instance

func is_signed_in() -> bool:
	var profile = LeaderboardManager.get_instance().get_player_profile()
	return profile.get("is_google_linked", false)

func get_google_name() -> String:
	var profile = LeaderboardManager.get_instance().get_player_profile()
	return profile.get("google_name", "")

func sign_in(callback: Callable = Callable()) -> void:
	if not OS.has_feature("web"):
		print("[GoogleAuthManager] Google Sign-In is only available in Web builds (Itch.io / Browser).")
		if callback.is_valid():
			callback.call(false, "Web build only")
		return

	# Setup callback that JavaScript calls upon authentication
	_js_callback = JavaScriptBridge.create_callback(func(args: Array):
		if args.is_empty():
			if callback.is_valid():
				callback.call(false, "No data received")
			return

		var json_str = str(args[0])
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary and parsed.has("sub"):
			var google_sub = str(parsed["sub"])
			var google_name = str(parsed.get("name", "Warrior"))
			_on_auth_success(google_sub, google_name, callback)
		else:
			var err = "Authentication canceled or failed"
			if parsed is Dictionary and parsed.has("error"):
				err = str(parsed["error"])
			print("[GoogleAuthManager] Auth error: ", err)
			if callback.is_valid():
				callback.call(false, err)
	)

	JavaScriptBridge.get_interface("window").onGodotGoogleAuthComplete = _js_callback

	var js_code = """
	(function() {
		function runGIS() {
			if (!window.google || !window.google.accounts || !window.google.accounts.oauth2) {
				var s = document.createElement('script');
				s.src = 'https://accounts.google.com/gsi/client';
				s.async = true;
				s.defer = true;
				s.onload = function() { startClient(); };
				document.head.appendChild(s);
			} else {
				startClient();
			}
		}

		function startClient() {
			try {
				var tokenClient = google.accounts.oauth2.initTokenClient({
					client_id: '%s',
					scope: 'openid profile email',
					callback: function(tokenResponse) {
						if (tokenResponse && tokenResponse.access_token) {
							fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
								headers: { 'Authorization': 'Bearer ' + tokenResponse.access_token }
							})
							.then(function(res) { return res.json(); })
							.then(function(userinfo) {
								if (window.onGodotGoogleAuthComplete) {
									window.onGodotGoogleAuthComplete(JSON.stringify(userinfo));
								}
							})
							.catch(function(err) {
								if (window.onGodotGoogleAuthComplete) {
									window.onGodotGoogleAuthComplete(JSON.stringify({ error: err.toString() }));
								}
							});
						} else {
							if (window.onGodotGoogleAuthComplete) {
								window.onGodotGoogleAuthComplete(JSON.stringify({ error: 'No access token' }));
							}
						}
					}
				});
				tokenClient.requestAccessToken();
			} catch (e) {
				if (window.onGodotGoogleAuthComplete) {
					window.onGodotGoogleAuthComplete(JSON.stringify({ error: e.toString() }));
				}
			}
		}

		runGIS();
	})();
	""" % GOOGLE_CLIENT_ID

	JavaScriptBridge.eval(js_code)

func _on_auth_success(google_sub: String, google_name: String, callback: Callable) -> void:
	print("[GoogleAuthManager] Successfully authenticated with Google! User: %s (ID: %s)" % [google_name, google_sub])
	var mgr = LeaderboardManager.get_instance()
	var profile = mgr.get_player_profile()
	
	profile["google_id"] = google_sub
	profile["google_name"] = google_name
	profile["is_google_linked"] = true
	
	# Sanitize and adopt Google name
	var clean_name = LeaderboardManager.sanitize_player_name(google_name)
	if clean_name.length() >= 3:
		profile["name"] = clean_name
		profile["is_custom_name"] = true

	mgr.save_player_profile()

	# Handshake with Talo using service = "google"
	mgr.link_talo_google_account(google_sub, func(ok: bool):
		if callback.is_valid():
			callback.call(true, profile["name"])
	)
