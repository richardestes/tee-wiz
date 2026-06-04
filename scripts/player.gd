class_name Player
extends Node

@export var health: HealthComponent

# Group membership in _enter_tree (not _ready) so other systems can find the
# player via get_first_node_in_group("player") during *their* _ready, before
# Player._ready has fired. Without this, nodes deeper in the tree would look up
# the group and get null.
func _enter_tree() -> void:
	add_to_group("player")
