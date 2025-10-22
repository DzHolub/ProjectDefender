extends Node

## ResourceValidator
## Utility for validating and safely loading game resources
## Provides error handling for missing or corrupted assets

## Resource Loading Functions

# Safely load a scene with validation
static func load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_error("Scene does not exist: " + path)
		return null
	
	var scene = load(path)
	if scene == null:
		push_error("Failed to load scene: " + path)
		return null
	
	if not scene is PackedScene:
		push_error("Resource is not a PackedScene: " + path)
		return null
	
	return scene


# Safely load a texture with validation
static func load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_error("Texture does not exist: " + path)
		return null
	
	var texture = load(path)
	if texture == null:
		push_error("Failed to load texture: " + path)
		return null
	
	if not texture is Texture2D:
		push_error("Resource is not a Texture2D: " + path)
		return null
	
	return texture


# Safely load any resource with validation
static func load_resource(path: String, expected_type: String = "") -> Resource:
	if not ResourceLoader.exists(path):
		push_error("Resource does not exist: " + path)
		return null
	
	var resource = load(path)
	if resource == null:
		push_error("Failed to load resource: " + path)
		return null
	
	if not expected_type.is_empty():
		if not resource.get_class() == expected_type:
			push_warning("Resource type mismatch. Expected: " + expected_type + ", Got: " + resource.get_class())
	
	return resource


# Validate and instantiate a scene
static func instantiate_scene(scene: PackedScene, scene_name: String = "scene") -> Node:
	if scene == null:
		push_error("Cannot instantiate null scene: " + scene_name)
		return null
	
	var instance = scene.instantiate()
	if instance == null:
		push_error("Failed to instantiate scene: " + scene_name)
		return null
	
	return instance


# Validate resource path format
static func validate_resource_path(path: String) -> bool:
	if path.is_empty():
		push_error("Resource path is empty")
		return false
	
	if not path.begins_with("res://") and not path.begins_with("user://"):
		push_error("Invalid resource path format: " + path)
		return false
	
	return true


# Check if a resource exists without loading it
static func resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)


# Get resource type without loading it
static func get_resource_type(path: String) -> String:
	if not ResourceLoader.exists(path):
		return ""
	
	# Load the resource to check its type
	var resource = load(path)
	if resource == null:
		return ""
	
	return resource.get_class()


## Batch Resource Validation

# Validate multiple resources at once
static func validate_resources(resources: Dictionary) -> Dictionary:
	var validation_results = {}
	
	for key in resources.keys():
		var path = resources[key]
		validation_results[key] = {
			"path": path,
			"exists": ResourceLoader.exists(path),
			"type": get_resource_type(path) if ResourceLoader.exists(path) else "N/A"
		}
	
	return validation_results


# Print validation report
static func print_validation_report(resources: Dictionary) -> void:
	print("=== Resource Validation Report ===")
	var results = validate_resources(resources)
	
	var missing_count = 0
	for key in results.keys():
		var result = results[key]
		if result["exists"]:
			print("✅ " + key + ": " + result["path"] + " (" + result["type"] + ")")
		else:
			print("❌ " + key + ": " + result["path"] + " (MISSING)")
			missing_count += 1
	
	print("================================")
	print("Total: " + str(results.size()) + " | Missing: " + str(missing_count))


## Fallback Resources

# Create a placeholder scene for missing resources
static func create_placeholder_node(node_name: String) -> Node2D:
	var placeholder = Node2D.new()
	placeholder.name = node_name + "_Placeholder"
	
	# Add a visual indicator for missing resources
	var label = Label.new()
	label.text = "MISSING: " + node_name
	label.modulate = Color.RED
	placeholder.add_child(label)
	
	push_warning("Created placeholder for missing resource: " + node_name)
	return placeholder


# Get a fallback texture (solid color)
static func get_fallback_texture(size: Vector2i = Vector2i(64, 64), color: Color = Color.MAGENTA) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
