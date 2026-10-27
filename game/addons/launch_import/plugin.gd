@tool
extends EditorPlugin

var filesystem: EditorFileSystem
var quiet_time := 0.0
var finished := false
var scan_finished := false
var preparing := false

func _enter_tree() -> void:
	set_process(false)
	preparing = OS.get_cmdline_user_args().has("--nightshift-prepare")
	if not preparing: return
	filesystem = get_editor_interface().get_resource_filesystem()
	filesystem.filesystem_changed.connect(mark_changed)
	filesystem.resources_reimported.connect(func(_paths: PackedStringArray): mark_changed())
	set_process(true)

func _exit_tree() -> void:
	preparing = false
	set_process(false)

func mark_changed() -> void:
	scan_finished = true
	quiet_time = 0

func _process(delta: float) -> void:
	# Godot may enable processing automatically for a tool script after entering
	# the tree. Normal editor sessions never initialize the launch-only scanner.
	if not preparing or finished or not is_instance_valid(filesystem): return
	if filesystem.is_scanning():
		quiet_time = 0
		return
	if not scan_finished: return
	quiet_time += delta
	if quiet_time < 3.0: return
	var invalid: Array[String] = []
	validate_directory(filesystem.get_filesystem(), invalid)
	finished = true
	if invalid.is_empty():
		print("NIGHTSHIFT_IMPORT_READY")
		get_tree().quit(0)
	else:
		for path in invalid: push_error("NIGHTSHIFT_IMPORT_FAILED: " + path)
		get_tree().quit(1)

func validate_directory(directory: EditorFileSystemDirectory, invalid: Array[String]) -> void:
	for index in range(directory.get_file_count()):
		var path := directory.get_file_path(index)
		if not FileAccess.file_exists(path + ".import"): continue
		var config := ConfigFile.new()
		if config.load(path + ".import") != OK or not directory.get_file_import_is_valid(index):
			invalid.append(path)
			continue
		for destination in config.get_value("deps", "dest_files", PackedStringArray()):
			if not FileAccess.file_exists(destination): invalid.append(destination)
	for index in range(directory.get_subdir_count()):
		validate_directory(directory.get_subdir(index), invalid)
