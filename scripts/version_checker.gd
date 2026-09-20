# this script is 103.33% AI boilerplate
# why 103.33%?
# because I *deleted* 3 lines with useless string comparisons
# updated the version and repo strings, then left everything else as is

class_name VersionChecker
extends Node

@export var current_version: String = "3.29_v15"
@export var github_repo: String = "slothofexile/slothofexile-overlay"
@export var overlay_main: Node3D

func _ready() -> void:
	check_version()

func check_version() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_version_check_completed.bind(http_request))

	var headers = [
		"User-Agent: GodotOverlayApp",
		"Accept: application/vnd.github+json"
	]
	var url = "https://api.github.com/repos/%s/releases/latest" % github_repo

	print("[VersionChecker] Requesting latest release from: ", url)
	var err = http_request.request(url, headers)
	if err != OK:
		push_error("[VersionChecker] Failed to start HTTP request. Error code: ", err)
		http_request.queue_free()

func _on_version_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	http_request.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("[VersionChecker] HTTP request failed with result code: ", result)
		return

	print("[VersionChecker] HTTP response code: ", response_code)

	if response_code != 200:
		push_error("[VersionChecker] GitHub API error response (Code ", response_code, "): ", body.get_string_from_utf8())
		return

	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	if not json or not json is Dictionary or not json.has("tag_name"):
		push_error("[VersionChecker] Failed to parse valid release JSON from response.")
		return

	var latest_tag: String = json["tag_name"]
	var release_url: String = json.get("html_url", "https://github.com/%s/releases/latest" % github_repo)

	print("[VersionChecker] Local version: '", current_version, "' | Remote version: '", latest_tag, "'")

	if _strip_v(latest_tag) != _strip_v(current_version):
		print("[VersionChecker] Version mismatch detected. Displaying update dialog.")
		_show_version_dialog(latest_tag, release_url)
	else:
		print("[VersionChecker] Application is up to date.")

func _strip_v(version: String) -> String:
	return version.trim_prefix("v").trim_prefix("V").strip_edges()

func _show_version_dialog(latest_tag: String, release_url: String) -> void:
	if is_instance_valid(overlay_main) and overlay_main.has_method("set_click_through"):
		overlay_main.set_click_through(false)

	var dialog = ConfirmationDialog.new()
	dialog.title = "Update Available"
	dialog.dialog_text = "A new release (%s) is available.\n\nWould you like to open the GitHub release page?" % latest_tag
	dialog.ok_button_text = "Open Release Page"
	dialog.cancel_button_text = "Dismiss"

	dialog.confirmed.connect(func():
		OS.shell_open(release_url)
	)

	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			if is_instance_valid(overlay_main) and overlay_main.has_method("set_click_through"):
				overlay_main.set_click_through(true)
			dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()
