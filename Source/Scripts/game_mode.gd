extends Node

var endless: bool = false
var intro_seen: bool = false
var level: int = 1                      # story level, starting at 1
var carry_unlocked: Dictionary = {}     # units unlocked in earlier levels

const LEVEL_SCENES := [
	"res://Scenes/world.tscn",
	"res://Scenes/world2.tscn",
]

func scene_for_level() -> String:
	return LEVEL_SCENES[level - 1]

func has_next_level() -> bool:
	return level < LEVEL_SCENES.size()
