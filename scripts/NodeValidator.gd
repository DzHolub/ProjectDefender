extends Node

## NodeValidator
## Utility for safe node access and validation
## Prevents crashes from null references and invalid nodes

## Safe Node Access Functions

# Safely get a node with validation
static func get_node_safe(from_node: Node, path: NodePath) -> Node:
	if from_node == null:
		push_error("Cannot get node from null parent")
		return null
	
	if not is_instance_valid(from_node):
		push_error("Parent node is not valid")
		return null
	
	if not from_node.has_node(path):
		push_error("Node path does not exist: " + str(path) + " from " + str(from_node.name))
		return null
	
	var node = from_node.get_node(path)
	if node == null:
		push_error("Node is null at path: " + str(path))
		return null
	
	if not is_instance_valid(node):
		push_error("Node is not valid at path: " + str(path))
		return null
	
	return node


# Safely get a typed node with validation
static func get_node_typed(from_node: Node, path: NodePath, expected_type: String) -> Node:
	var node = get_node_safe(from_node, path)
	if node == null:
		return null
	
	if not node.is_class(expected_type):
		push_warning("Node type mismatch at " + str(path) + ". Expected: " + expected_type + ", Got: " + node.get_class())
	
	return node


# Safely get child node by name
static func get_child_safe(parent: Node, child_name: String) -> Node:
	if parent == null:
		push_error("Cannot get child from null parent")
		return null
	
	if not is_instance_valid(parent):
		push_error("Parent node is not valid")
		return null
	
	for child in parent.get_children():
		if child.name == child_name:
			if is_instance_valid(child):
				return child
			else:
				push_error("Child node is not valid: " + child_name)
				return null
	
	push_error("Child node not found: " + child_name + " in " + parent.name)
	return null


# Safely add child with validation
static func add_child_safe(parent: Node, child: Node, deferred: bool = false) -> bool:
	if parent == null:
		push_error("Cannot add child to null parent")
		if child != null:
			child.queue_free()
		return false
	
	if not is_instance_valid(parent):
		push_error("Parent node is not valid")
		if child != null:
			child.queue_free()
		return false
	
	if child == null:
		push_error("Cannot add null child to " + parent.name)
		return false
	
	if not is_instance_valid(child):
		push_error("Child node is not valid")
		return false
	
	if deferred:
		parent.add_child.call_deferred(child)
	else:
		parent.add_child(child)
	
	return true


# Safely remove child with validation
static func remove_child_safe(parent: Node, child: Node) -> bool:
	if parent == null:
		push_error("Cannot remove child from null parent")
		return false
	
	if not is_instance_valid(parent):
		push_error("Parent node is not valid")
		return false
	
	if child == null:
		push_error("Cannot remove null child")
		return false
	
	if not is_instance_valid(child):
		push_warning("Child node is not valid, skipping removal")
		return false
	
	if child.get_parent() != parent:
		push_error("Child is not a child of the specified parent")
		return false
	
	parent.remove_child(child)
	return true


# Safely queue free a node
static func queue_free_safe(node: Node) -> void:
	if node == null:
		return
	
	if is_instance_valid(node):
		node.queue_free()


## Node Validation Functions

# Check if node is valid and in tree
static func is_node_valid_in_tree(node: Node) -> bool:
	if node == null:
		return false
	
	if not is_instance_valid(node):
		return false
	
	if not node.is_inside_tree():
		return false
	
	return true


# Validate node has required children
static func validate_node_children(parent: Node, required_children: Array[String]) -> bool:
	if parent == null:
		push_error("Cannot validate children of null parent")
		return false
	
	if not is_instance_valid(parent):
		push_error("Parent node is not valid")
		return false
	
	var all_valid = true
	for child_name in required_children:
		if not parent.has_node(child_name):
			push_error("Required child node missing: " + child_name + " in " + parent.name)
			all_valid = false
	
	return all_valid


# Get node or return default
static func get_node_or_default(from_node: Node, path: NodePath, default: Node = null) -> Node:
	var node = get_node_safe(from_node, path)
	if node != null:
		return node
	return default


## Scene Tree Utilities

# Safely get root node
static func get_root_safe() -> Node:
	var tree = Engine.get_main_loop()
	if tree == null:
		push_error("Scene tree is null")
		return null
	
	if not tree is SceneTree:
		push_error("Main loop is not a SceneTree")
		return null
	
	var root = tree.root
	if root == null:
		push_error("Root node is null")
		return null
	
	return root


# Safely find node by path from root
static func find_node_from_root(path: String) -> Node:
	var root = get_root_safe()
	if root == null:
		return null
	
	if not root.has_node(path):
		push_error("Node not found in scene tree: " + path)
		return null
	
	return root.get_node(path)


# Get nodes in group safely
static func get_nodes_in_group_safe(group_name: String) -> Array[Node]:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("Scene tree is null")
		return []
	
	var nodes = tree.get_nodes_in_group(group_name)
	var valid_nodes: Array[Node] = []
	
	for node in nodes:
		if is_instance_valid(node):
			valid_nodes.append(node)
	
	return valid_nodes


## Debug Functions

# Print node tree for debugging
static func print_node_tree(node: Node, indent: int = 0) -> void:
	if node == null:
		print("  ".repeat(indent) + "NULL NODE")
		return
	
	if not is_instance_valid(node):
		print("  ".repeat(indent) + "INVALID NODE")
		return
	
	print("  ".repeat(indent) + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_node_tree(child, indent + 1)


# Validate and report node status
static func report_node_status(node: Node, node_name: String) -> void:
	print("=== Node Status Report: " + node_name + " ===")
	
	if node == null:
		print("❌ Node is NULL")
		return
	
	print("✅ Node exists")
	
	if not is_instance_valid(node):
		print("❌ Node is NOT VALID")
		return
	
	print("✅ Node is valid")
	print("   Type: " + node.get_class())
	print("   Name: " + node.name)
	print("   In Tree: " + str(node.is_inside_tree()))
	print("   Children: " + str(node.get_child_count()))

