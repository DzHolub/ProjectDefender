extends Node
class_name CollisionUtil

## Collision Optimization Utilities
## Provides helper functions for efficient collision detection and layer management

# Check if a layer bit is set
static func has_layer(layers: int, layer: int) -> bool:
	return (layers & layer) != 0


# Add a layer to the collision layer
static func add_layer(current_layers: int, layer_to_add: int) -> int:
	return current_layers | layer_to_add


# Remove a layer from the collision layer
static func remove_layer(current_layers: int, layer_to_remove: int) -> int:
	return current_layers & ~layer_to_remove


# Toggle a layer in the collision layer
static func toggle_layer(current_layers: int, layer: int) -> bool:
	return current_layers ^ layer


# Check if two collision layer sets can interact
static func can_collide(layer_a: int, mask_a: int, layer_b: int, mask_b: int) -> bool:
	return ((layer_a & mask_b) != 0) or ((layer_b & mask_a) != 0)


# Get all areas in a specific layer within a radius
static func get_areas_in_layer_radius(world: World2D, global_pos: Vector2, radius: float, layer_mask: int) -> Array[Area2D]:
	var space_state = world.direct_space_state
	if not space_state:
		return []
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_pos)
	query.collision_mask = layer_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_shape(query)
	var areas: Array[Area2D] = []
	
	for result in results:
		if result.collider is Area2D:
			areas.append(result.collider)
	
	return areas


# Get all areas in a specific layer within a rect
static func get_areas_in_layer_rect(world: World2D, rect: Rect2, layer_mask: int) -> Array[Area2D]:
	var space_state = world.direct_space_state
	if not space_state:
		return []
	
	var query = PhysicsShapeQueryParameters2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = rect.size
	query.shape = rect_shape
	query.transform = Transform2D(0, rect.get_center())
	query.collision_mask = layer_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_shape(query)
	var areas: Array[Area2D] = []
	
	for result in results:
		if result.collider is Area2D:
			areas.append(result.collider)
	
	return areas


# Perform a raycast with specific layer mask
static func raycast_layer(world: World2D, from: Vector2, to: Vector2, layer_mask: int, exclude: Array = []) -> Dictionary:
	var space_state = world.direct_space_state
	if not space_state:
		return {}
	
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = layer_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = exclude
	
	return space_state.intersect_ray(query)


# Check if a point is within an area's collision shape
static func is_point_in_area(area: Area2D, point: Vector2) -> bool:
	if not area or not is_instance_valid(area):
		return false
	
	# Get the area's collision shapes
	for child in area.get_children():
		if child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child
			if not collision_shape.shape:
				continue
			
			# Transform point to local space
			var local_point = area.to_local(point)
			local_point = collision_shape.transform.affine_inverse() * local_point
			
			# Check if point is in shape (works for circles and rectangles)
			if collision_shape.shape is CircleShape2D:
				var circle: CircleShape2D = collision_shape.shape
				return local_point.length() <= circle.radius
			elif collision_shape.shape is RectangleShape2D:
				var rect: RectangleShape2D = collision_shape.shape
				var half_size = rect.size / 2
				return abs(local_point.x) <= half_size.x and abs(local_point.y) <= half_size.y
	
	return false


# Get the closest area from a list
static func get_closest_area(from_position: Vector2, areas: Array[Area2D]) -> Area2D:
	if areas.is_empty():
		return null
	
	var closest: Area2D = null
	var closest_distance: float = INF
	
	for area in areas:
		if not area or not is_instance_valid(area):
			continue
		
		var distance = from_position.distance_squared_to(area.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = area
	
	return closest


# Filter areas by distance
static func filter_areas_by_distance(from_position: Vector2, areas: Array[Area2D], max_distance: float) -> Array[Area2D]:
	var filtered: Array[Area2D] = []
	var max_dist_squared = max_distance * max_distance
	
	for area in areas:
		if not area or not is_instance_valid(area):
			continue
		
		var dist_squared = from_position.distance_squared_to(area.global_position)
		if dist_squared <= max_dist_squared:
			filtered.append(area)
	
	return filtered


# Sort areas by distance (closest first)
static func sort_areas_by_distance(from_position: Vector2, areas: Array[Area2D]) -> Array[Area2D]:
	var sorted_areas = areas.duplicate()
	sorted_areas.sort_custom(func(a, b):
		var dist_a = from_position.distance_squared_to(a.global_position)
		var dist_b = from_position.distance_squared_to(b.global_position)
		return dist_a < dist_b
	)
	return sorted_areas

