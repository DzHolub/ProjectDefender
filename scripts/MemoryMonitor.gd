extends Node

## Memory Usage Monitor
## Tracks and reports memory usage statistics

# Configuration
const MONITOR_INTERVAL_SECONDS: float = 5.0  # Check memory every 5 seconds
const MEMORY_WARNING_THRESHOLD_MB: float = 500.0  # Warn if memory exceeds this
const MEMORY_CRITICAL_THRESHOLD_MB: float = 800.0  # Critical if memory exceeds this

var monitor_timer: Timer = null
var peak_memory_usage: float = 0.0
var last_memory_usage: float = 0.0

# Statistics
var memory_samples: Array[float] = []
const MAX_SAMPLES: int = 60  # Keep last 60 samples (5 minutes at 5s interval)


func _ready() -> void:
	# Setup monitoring timer
	monitor_timer = Timer.new()
	monitor_timer.wait_time = MONITOR_INTERVAL_SECONDS
	monitor_timer.timeout.connect(_on_monitor_timer_timeout)
	add_child(monitor_timer)
	monitor_timer.start()
	
	print("MemoryMonitor initialized")


func _exit_tree() -> void:
	if monitor_timer and is_instance_valid(monitor_timer):
		monitor_timer.stop()
		monitor_timer.queue_free()


# Get current memory usage in MB
func get_memory_usage_mb() -> float:
	var memory_info = Performance.get_monitor(Performance.MEMORY_STATIC)
	return memory_info / 1024.0 / 1024.0  # Convert to MB


# Get static memory usage
func get_static_memory_mb() -> float:
	return Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0


# Get dynamic memory usage
func get_dynamic_memory_mb() -> float:
	return Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024.0 / 1024.0


# Get object count
func get_object_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))


# Get resource count
func get_resource_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))


# Get node count
func get_node_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


# Get orphan node count
func get_orphan_node_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))


# Monitor timer callback
func _on_monitor_timer_timeout() -> void:
	last_memory_usage = get_memory_usage_mb()
	
	# Track peak usage
	if last_memory_usage > peak_memory_usage:
		peak_memory_usage = last_memory_usage
	
	# Store sample
	memory_samples.append(last_memory_usage)
	if memory_samples.size() > MAX_SAMPLES:
		memory_samples.pop_front()
	
	# Check thresholds
	if last_memory_usage > MEMORY_CRITICAL_THRESHOLD_MB:
		push_error("CRITICAL: Memory usage exceeds " + str(MEMORY_CRITICAL_THRESHOLD_MB) + "MB: " + str(last_memory_usage) + "MB")
		emit_memory_warning(last_memory_usage, true)
	elif last_memory_usage > MEMORY_WARNING_THRESHOLD_MB:
		push_warning("WARNING: Memory usage exceeds " + str(MEMORY_WARNING_THRESHOLD_MB) + "MB: " + str(last_memory_usage) + "MB")
		emit_memory_warning(last_memory_usage, false)


# Emit memory warning signal
func emit_memory_warning(usage_mb: float, is_critical: bool) -> void:
	EventBus.emit_debug_info("Memory: " + str(usage_mb) + "MB " + ("CRITICAL" if is_critical else "WARNING"))


# Get comprehensive memory statistics
func get_memory_stats() -> Dictionary:
	return {
		"current_mb": last_memory_usage,
		"peak_mb": peak_memory_usage,
		"average_mb": get_average_memory_usage(),
		"static_mb": get_static_memory_mb(),
		"dynamic_mb": get_dynamic_memory_mb(),
		"object_count": get_object_count(),
		"resource_count": get_resource_count(),
		"node_count": get_node_count(),
		"orphan_nodes": get_orphan_node_count()
	}


# Get average memory usage from samples
func get_average_memory_usage() -> float:
	if memory_samples.is_empty():
		return 0.0
	
	var total: float = 0.0
	for sample in memory_samples:
		total += sample
	
	return total / memory_samples.size()


# Print detailed memory report
func print_memory_report() -> void:
	var stats = get_memory_stats()
	
	print("\n=== Memory Monitor Report ===")
	print("Current Memory: " + str(stats["current_mb"]) + " MB")
	print("Peak Memory: " + str(stats["peak_mb"]) + " MB")
	print("Average Memory: " + str(stats["average_mb"]) + " MB")
	print("Static Memory: " + str(stats["static_mb"]) + " MB")
	print("Dynamic Memory: " + str(stats["dynamic_mb"]) + " MB")
	print("\nObject Statistics:")
	print("  Total Objects: " + str(stats["object_count"]))
	print("  Resources: " + str(stats["resource_count"]))
	print("  Nodes: " + str(stats["node_count"]))
	print("  Orphan Nodes: " + str(stats["orphan_nodes"]))
	
	if stats["orphan_nodes"] > 0:
		push_warning("Found " + str(stats["orphan_nodes"]) + " orphan nodes - potential memory leak!")
	
	print("============================\n")


# Force immediate memory check
func check_memory_now() -> void:
	_on_monitor_timer_timeout()


# Reset peak memory tracking
func reset_peak_memory() -> void:
	peak_memory_usage = last_memory_usage


# Get memory trend (increasing, stable, or decreasing)
func get_memory_trend() -> String:
	if memory_samples.size() < 5:
		return "insufficient_data"
	
	# Compare recent average to older average
	var recent_samples = memory_samples.slice(-5, memory_samples.size())
	var older_samples = memory_samples.slice(-10, -5)
	
	var recent_avg: float = 0.0
	var older_avg: float = 0.0
	
	for sample in recent_samples:
		recent_avg += sample
	recent_avg /= recent_samples.size()
	
	for sample in older_samples:
		older_avg += sample
	older_avg /= older_samples.size()
	
	var difference = recent_avg - older_avg
	var threshold = 5.0  # MB
	
	if difference > threshold:
		return "increasing"
	elif difference < -threshold:
		return "decreasing"
	else:
		return "stable"

