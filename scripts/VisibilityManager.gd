extends Node

## Visibility Manager
## Optimizes rendering by culling off-screen entities and managing visibility

# Configuration
const CULL_MARGIN: float = 100.0  # Extra margin beyond viewport for culling

var viewport_rect: Rect2 = Rect2()
var entities_tracked: Array[Node2D] = []
var culling_enabled: bool = true

# Statistics
var total_entities: int = 0
var visible_entities: int = 0
var culled_entities: int = 0


func _ready() -> void:
	update_viewport_rect()
	print("VisibilityManager initialized")


func _process(_delta: float) -> void:
	if not culling_enabled:
		return
	
	# Update viewport rect (handles screen resize)
	update_viewport_rect()
	
	# Update visibility for tracked entities
	update_entities_visibility()


# Update the viewport rectangle
func update_viewport_rect() -> void:
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		viewport_rect = Rect2(-CULL_MARGIN, -CULL_MARGIN, 
			viewport_size.x + CULL_MARGIN * 2, 
			viewport_size.y + CULL_MARGIN * 2)


# Register an entity for visibility management
func register_entity(entity: Node2D) -> void:
	if entity and not entities_tracked.has(entity):
		entities_tracked.append(entity)
		total_entities += 1


# Unregister an entity
func unregister_entity(entity: Node2D) -> void:
	var index = entities_tracked.find(entity)
	if index >= 0:
		entities_tracked.remove_at(index)
		total_entities -= 1


# Update visibility for all tracked entities
func update_entities_visibility() -> void:
	visible_entities = 0
	culled_entities = 0
	
	for entity in entities_tracked:
		if not entity or not is_instance_valid(entity):
			continue
		
		if is_entity_visible(entity):
			if not entity.visible:
				entity.visible = true
				# Re-enable processing when becoming visible
				entity.set_process(true)
			visible_entities += 1
		else:
			if entity.visible:
				entity.visible = false
				# Disable processing when not visible
				entity.set_process(false)
			culled_entities += 1


# Check if an entity is within the viewport
func is_entity_visible(entity: Node2D) -> bool:
	if not entity or not is_instance_valid(entity):
		return false
	
	var global_pos = entity.global_position
	return viewport_rect.has_point(global_pos)


# Check if a position is visible
func is_position_visible(pos: Vector2) -> bool:
	return viewport_rect.has_point(pos)


# Check if a rect is visible
func is_rect_visible(rect: Rect2) -> bool:
	return viewport_rect.intersects(rect)


# Enable/disable culling
func set_culling_enabled(enabled: bool) -> void:
	culling_enabled = enabled
	
	# If disabling, make all entities visible
	if not enabled:
		for entity in entities_tracked:
			if entity and is_instance_valid(entity):
				entity.visible = true
				entity.set_process(true)


# Get visibility statistics
func get_stats() -> Dictionary:
	return {
		"total_entities": total_entities,
		"visible_entities": visible_entities,
		"culled_entities": culled_entities,
		"culling_enabled": culling_enabled,
		"cull_percentage": (float(culled_entities) / max(total_entities, 1)) * 100.0
	}


# Print visibility report
func print_visibility_report() -> void:
	var stats = get_stats()
	print("\n=== Visibility Manager Report ===")
	print("Total Entities: " + str(stats["total_entities"]))
	print("Visible: " + str(stats["visible_entities"]))
	print("Culled: " + str(stats["culled_entities"]))
	print("Cull Percentage: " + str(stats["cull_percentage"]) + "%")
	print("Culling Enabled: " + str(stats["culling_enabled"]))
	print("================================\n")


# Clean up invalid entities from tracking
func cleanup_invalid_entities() -> void:
	var to_remove: Array[Node2D] = []
	
	for entity in entities_tracked:
		if not entity or not is_instance_valid(entity):
			to_remove.append(entity)
	
	for entity in to_remove:
		unregister_entity(entity)
	
	if to_remove.size() > 0:
		print("VisibilityManager: Cleaned up " + str(to_remove.size()) + " invalid entities")

