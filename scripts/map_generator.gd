class_name MapGenerator
extends RefCounted

const ROWS = 8
const COLS = 6
const PATHS = 4

const SHOP_PROBABILITY := 0.10
const MIN_SHOPS := 1
const MAX_SHOPS := 2

static func generate() -> Array[MapNode]:
	var grid = []
	var next_id = 0
	for i in ROWS:
		var row: Array = []
		row.resize(COLS)
		grid.append(row)

	var cols = range(COLS)
	cols.shuffle()
	var starts = cols.slice(0, PATHS)
	for col in starts:
		var start_node = MapNode.new()
		start_node.id = next_id
		start_node.type = "combat"
		start_node.row = 0
		start_node.col = col
		next_id += 1
		grid[0][col] = start_node

		var current = col
		for r in range(1, ROWS):
			var choices = [current]
			if current > 0 and not _would_cross(grid, r, current, current - 1):
				choices.append(current - 1)
			if current < COLS - 1 and not _would_cross(grid, r, current, current + 1):
				choices.append(current + 1)
			var next_col = choices.pick_random()

			if grid[r][next_col] == null:
				var node = MapNode.new()
				node.id = next_id
				node.type = "combat"
				node.row = r
				node.col = next_col
				next_id += 1
				grid[r][next_col] = node

			var source: MapNode = grid[r - 1][current]
			var dest: MapNode = grid[r][next_col]
			if dest.id not in source.connections:
				source.connections.append(dest.id)

			current = next_col

	var boss = MapNode.new()
	boss.id = next_id
	boss.type = "boss"
	boss.row = ROWS
	boss.col = COLS / 2
	for c in COLS:
		var leaf: MapNode = grid[ROWS - 1][c]
		if leaf != null:
			leaf.connections.append(boss.id)

	_assign_shops(grid)
	_assign_pars(grid, boss)

	var nodes: Array[MapNode] = []
	for r in ROWS:
		for c in COLS:
			if grid[r][c] != null:
				nodes.append(grid[r][c])
	nodes.append(boss)
	return nodes


static func _would_cross(grid: Array, r: int, current: int, next_col: int) -> bool:
	var other_source: MapNode = grid[r - 1][next_col]
	var other_dest: MapNode = grid[r][current]
	if other_source == null or other_dest == null:
		return false
	return other_dest.id in other_source.connections


static func _has_shop_parent(grid: Array, node: MapNode) -> bool:
	if node.row == 0:
		return false
	var parent_row: Array = grid[node.row - 1]
	for parent in parent_row:
		if parent == null:
			continue
		if parent.type == "shop" and node.id in parent.connections:
			return true
	return false


static func _assign_shops(grid: Array) -> void:
	var shop_count := 0
	var eligible_candidates: Array[MapNode] = []

	for r in range(1, ROWS - 1):
		for c in COLS:
			var node: MapNode = grid[r][c]
			if node == null:
				continue
			if _has_shop_parent(grid, node):
				continue
			eligible_candidates.append(node)
			if shop_count >= MAX_SHOPS:
				continue
			if randf() < SHOP_PROBABILITY:
				node.type = "shop"
				shop_count += 1

	if shop_count < MIN_SHOPS and not eligible_candidates.is_empty():
		var forced: MapNode = eligible_candidates.pick_random()
		forced.type = "shop"


static func print_grid(grid: Array) -> void:
	for r in range(ROWS - 1, -1, -1):
		var line = ""
		for c in COLS:
			line += "O" if grid[r][c] != null else "."
		print(line)


static func print_connections(grid: Array) -> void:
	for r in ROWS:
		for c in COLS:
			var n: MapNode = grid[r][c]
			if n != null:
				print("node ", n.id, " (r", r, " c", c, ") -> ", n.connections)
				
static func _assign_pars(grid: Array, boss: MapNode) -> void:
	for r in ROWS:
		for c in COLS:
			var node: MapNode = grid[r][c]
			if node == null:
				continue
			if node.type == "shop":
				continue
			node.par = randi_range(3, 5)
	boss.par = randi_range(3, 5)
