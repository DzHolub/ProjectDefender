extends Node

const PATH_DATA = "user://data.save" #path to game saves
const PATH_ASSETS = "res://assets/"
const PATH_TURRETS = "res://assets/turrets/"
const PATH_ENEMIES = "res://assets/enemies/"
const PATH_SPRITESHEET = "res://assets/SpriteSheet.png"

enum TURRET_TYPE {
	MACHINEGUN,
	LASER,
	ARTILLERY
}

const TURRET_HEALTH_MAX = 100
const TURRET_SHIELD_MAX = 100
const TURRET_GROUP = 'turret'

# Health and Shield Constants
const MIN_HEALTH: int = 0
const MIN_SHIELD: int = 0
const DEAD_STATE: int = 0

enum AMMO_TYPE {
	BULLET,
	LASER,
	EXPLOSIVE
}

enum AMMO {
	MACHINEGUN_BASIC,
	LASER_BASIC,
	ARTILLERY_BASIC
}

enum ENEMY_TYPE {
	SCOUT,
	ASTEROID,
	BOMB,
	METEOR,
	VESSEL,
	DRONE,
	DROPSHIP,
	PHANTOM,
	SCRAMBLER,
	ABDUCTOR,
	JAMMER,
	BLINKER,
	SHIELD,
	MOTHERSHIP,
	TRAINING
}

const ENEMY_SHIELD_SIZE = 50

const COLOR_TRANSP = Color(0, 0, 0, 0)
const COLOR_LASER_CHARGED = Color(0, 0, 0, 0.8)
const COLOR_SIGHT = Color(0.862745, 0.0784314, 0.235294, 0.4)
const COLOR_ACTIVATION_ZONE_OFF = Color(0, 0, 0, 0.3)
const COLOR_ACTIVATION_ZONE_ON = Color(0, 0, 0, 0.1)
const COLOR_RELOAD_INDICATOR = Color(0, 0, 0, 0.7)
const COLOR_ENEMY_SHIELD_INNER = Color(0, 0, 0, 0.1)
const COLOR_ENEMY_SHIELD_OUTER = Color(0.862745, 0.0784314, 0.235294, 0.3)
const COLOR_UI_FRAME = Color.BLACK
const COLOR_UI_HEALTH_SEGMENT = Color.BLACK

const SPRITESHEET_RECT_HEALTH = Rect2(65, 62, 28, 23)

const UI_FONT = "FontUniSans.otf"
const UI_GAP_HEALTH_SEGMENT = 11
const UI_TURRET_ACTIVATION_ZONE = 100
const UI_ACTIVE_AMMO_INDICATOR_POS = Vector2(60,-60)
const UI_SCREEN_MARGIN_POS = 300
const UI_SCREEN_MARGIN_PERCENT = 25

const GROUND_GROUP = 'ground'

# Render Layers (for visibility and culling optimization)
const RENDER_LAYER_GROUND: int = 1
const RENDER_LAYER_BACKGROUND: int = 1
const RENDER_LAYER_ENEMIES: int = 2
const RENDER_LAYER_TURRETS: int = 3
const RENDER_LAYER_PROJECTILES: int = 4
const RENDER_LAYER_EFFECTS: int = 5
const RENDER_LAYER_UI: int = 6

# Collision Layers (Physics Layers 2D)
# Layer 1 (bit 0): Ground/Environment
# Layer 2 (bit 1): Enemies
# Layer 3 (bit 2): Turrets
# Layer 4 (bit 3): Bullets/Projectiles
# Layer 5 (bit 4): Explosions

const COLLISION_LAYER_GROUND: int = 1 << 0      # Layer 1 (value: 1)
const COLLISION_LAYER_ENEMY: int = 1 << 1       # Layer 2 (value: 2)
const COLLISION_LAYER_TURRET: int = 1 << 2      # Layer 3 (value: 4)
const COLLISION_LAYER_BULLET: int = 1 << 3      # Layer 4 (value: 8)
const COLLISION_LAYER_EXPLOSION: int = 1 << 4   # Layer 5 (value: 16)

# Collision Masks (what each object type should detect)
const COLLISION_MASK_ENEMY: int = COLLISION_LAYER_GROUND | COLLISION_LAYER_TURRET | COLLISION_LAYER_BULLET  # Detect ground, turrets, bullets
const COLLISION_MASK_TURRET: int = COLLISION_LAYER_ENEMY  # Detect enemies only
const COLLISION_MASK_BULLET: int = COLLISION_LAYER_ENEMY  # Detect enemies only
const COLLISION_MASK_EXPLOSION: int = COLLISION_LAYER_ENEMY | COLLISION_LAYER_TURRET  # Detect enemies and turrets
const COLLISION_MASK_GROUND: int = COLLISION_LAYER_ENEMY  # Detect enemies only 
