extends Node
## Autoload "SaveManager".
## Keeps the data that outlives a run in user://save.cfg: the best wave the player has
## reached (saved as soon as a new wave starts, so quitting mid-run never loses a record)
## and whether the tutorial was already completed or skipped.

const SAVE_PATH := "user://save.cfg"
const RECORDS_SECTION := "records"
const BEST_WAVE_KEY := "best_wave"
const PROGRESS_SECTION := "progress"
const TUTORIAL_COMPLETED_KEY := "tutorial_completed"

## Highest wave ever reached, across every run.
var best_wave: int = 0
## True once the player has finished or skipped the tutorial, so it only shows the first time.
var tutorial_completed: bool = false

## best_wave when the current run started, used to tell whether this run beat it.
var _best_wave_before_run: int = 0


func _ready() -> void:
	_load()
	_best_wave_before_run = best_wave
	Events.wave_started.connect(_on_wave_started)


## Remembers that the tutorial was seen so it never shows again.
func mark_tutorial_completed() -> void:
	if tutorial_completed:
		return
	tutorial_completed = true
	_save()


## Reads any other persistent value (e.g. DifficultyManager's difficulty).
func get_value(section: String, key: String, default: Variant) -> Variant:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return default
	return config.get_value(section, key, default)


## Writes any other persistent value, keeping the rest of the file.
func set_value(section: String, key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(section, key, value)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SaveManager: could not write %s (error %d)." % [SAVE_PATH, error])


## True when the current (or just finished) run reached a wave higher than the
## previous record.
func is_new_record() -> bool:
	return best_wave > _best_wave_before_run


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 1:
		_best_wave_before_run = best_wave
	if wave_number > best_wave:
		best_wave = wave_number
		_save()


func _load() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("SaveManager: could not read %s (error %d)." % [SAVE_PATH, error])
		return
	best_wave = maxi(int(config.get_value(RECORDS_SECTION, BEST_WAVE_KEY, 0)), 0)
	tutorial_completed = bool(config.get_value(PROGRESS_SECTION, TUTORIAL_COMPLETED_KEY, false))


func _save() -> void:
	var config := ConfigFile.new()
	# Keep any other section already in the file
	config.load(SAVE_PATH)
	config.set_value(RECORDS_SECTION, BEST_WAVE_KEY, best_wave)
	config.set_value(PROGRESS_SECTION, TUTORIAL_COMPLETED_KEY, tutorial_completed)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SaveManager: could not write %s (error %d)." % [SAVE_PATH, error])
