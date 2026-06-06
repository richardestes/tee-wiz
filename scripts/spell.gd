class_name Spell extends Resource

@export var name : String
@export var typed_cost: Dictionary[ManaPool.Element, int]= {}
@export var generic_cost: int
