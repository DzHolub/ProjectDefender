# DefendTheEarth - Complete Project Documentation

Based on comprehensive review of the Godot 4.4 project, here's the complete documentation of all existing logic:

## Project Overview

**DefendTheEarth** is a tower defense-style game where players defend Earth from incoming enemies using various turrets. The game features touch/mouse controls, multiple enemy types, different weapon systems, and a scoring mechanism.

### Project Configuration
- **Engine**: Godot 4.4
- **Resolution**: 1080x1920 (portrait orientation)
- **Target Platform**: Mobile (Android) with desktop testing support
- **Main Scene**: `res://assets/levels/Demo.tscn`

## Core Systems Architecture

### 1. Global Data Management

#### Constants (`Const.gd`)
- **Paths**: Defines all asset paths and file locations
- **Enums**: 
  - `TURRET_TYPE`: Machinegun, Laser, Artillery
  - `AMMO_TYPE`: Bullet, Laser, Explosive
  - `AMMO`: Specific ammunition types
  - `ENEMY_TYPE`: 15+ enemy types (Scout, Asteroid, Bomb, Meteor, etc.)
- **Game Constants**: Health/shield values, UI colors, screen margins
- **Groups**: Turret and ground collision groups

#### Global Variables (`GlobalVars.gd`)
- **Game State**: Score, health (3), citizens (45,000)
- **Touch System**: Multi-touch support (max 2 touches)
- **Spawner Management**: Queue-based enemy spawning
- **Save/Load System**: JSON-based progress persistence
- **Helper Functions**: Screen border calculations, vector utilities

#### Data Initialization Scripts
- **`GlobalAmmoData.gd`**: Ammunition properties and instantiation
- **`GlobalEnemyData.gd`**: Enemy stats and behavior initialization  
- **`GlobalTurretData.gd`**: Turret configuration and parameters

### 2. Enemy System

#### Enemy Base (`EnemyBP.gd`)
**Core Properties:**
- Health/shield system with visual indicators
- Movement with gravity and rotation
- Damage dealing to turrets and cities
- Particle effects for hits and destruction
- Collision detection with ground and turrets

**Enemy Types Implemented:**
- **Asteroid**: 110 HP, 150 shield, rotating, city damage
- **Scout**: 50 HP, 50 shield, complex AI behavior
- **Bomb**: 5 HP, explosive damage, flickering effect

**Special Behaviors:**
- Shield visualization with collision zones
- Training enemies show movement trails
- Bomb enemies have flickering explosion zones
- Death particles and score integration

#### Scout AI (`ScoutBehaviour.gd`)
**Complex Movement Pattern:**
1. **Entry**: Smooth entrance animation
2. **Patrol**: Random position selection with 5 movement cycles
3. **Combat**: 50% chance to shoot bombs during movement
4. **Exit**: Return to top of screen

**Technical Implementation:**
- Tween-based smooth movement
- Dynamic rotation based on movement direction
- Bomb spawning from muzzle point
- Screen boundary awareness

#### Enemy Spawning (`Spawner.gd`)
**Queue-Based System:**
- Multiple spawners with queue positions
- Delay timers between spawner activations
- Random enemy selection from available types
- Configurable spawn rates and positions

**Spawn Configuration:**
- Screen margin calculations (10% borders)
- Random timing (0.4-3 seconds)
- Enemy type dictionaries with counts
- Sequential queue processing

### 3. Turret System

#### Turret Base (`TurretBP.gd`)
**Three Turret Types:**

**Machinegun:**
- Fast rotation (0.2), rapid fire (0.25s)
- Bullet spread with sway
- High ammunition capacity

**Laser:**
- Slow rotation (0.015), slow fire (1.0s)
- Chargeable weapon with time dilation
- High damage (800), limited ammo

**Artillery:**
- Medium rotation (0.1), slow fire (3.0s)
- Explosive ammunition
- Highest damage (1800), very limited ammo

**Control System:**
- Touch-based activation within 100px radius
- Mouse support for desktop testing
- Multi-touch finger tracking
- Visual feedback with activation zones

**UI Integration:**
- Ammo counter with reload indicators
- Aiming sight with collision detection
- Charged laser visualization
- Screen margin handling for UI elements

#### Ammunition (`TurretBPAmmo.gd`)
**Three Ammo Types:**

**Bullet (Machinegun):**
- Speed: 5000, Damage: 50
- Direct hit mechanics
- Hit particles

**Laser:**
- Speed: 5000, Damage: 800
- Trail rendering with fade
- Instant hit

**Explosive (Artillery):**
- Speed: 500, Damage: 1800
- Area of effect explosion
- Flickering explosion zone

**Physics:**
- Gravity simulation
- Velocity-based movement
- Collision detection with enemies
- Automatic destruction timers

### 4. User Interface System

#### Main UI (`UI.gd`)
**Game State Display:**
- Citizens counter with "K" formatting
- Score tracking
- Critical citizen threshold (20% of total)
- Visual feedback on citizen changes

**UI Effects:**
- Scale animation on citizen count changes
- Debug information display
- Reset button for testing

#### Visual Elements
- **Citizens Icon**: Sprite from spritesheet
- **Debug Label**: Real-time game state
- **Reset Button**: Development testing tool
- **Color Inversion Shader**: Screen effect capability

### 5. Level System

#### Demo Level (`Demo.tscn`)
**Scene Structure:**
- **Player Node**: Contains all turrets
- **Enemy Node**: Spawners and enemy instances
- **Ground Zone**: Collision area for city damage
- **UI**: In-game interface overlay

**Turret Layout:**
- Machinegun: Left position (150 ammo)
- Artillery: Center position (3 ammo)
- Laser: Right position (10 ammo)

**Enemy Spawners:**
- Multiple spawners with different configurations
- Queue-based activation system
- Random and sequential spawning modes

### 6. Technical Implementation Details

#### Touch Input System
- **Multi-touch Support**: Up to 2 simultaneous touches
- **Finger Tracking**: Individual finger ID assignment
- **Turret Assignment**: Touch-to-turret mapping
- **Screen Boundaries**: Margin calculations for UI positioning

#### Save System
- **JSON Format**: Human-readable save data
- **Persistent Data**: Score, health, citizens
- **File Location**: `user://data.save`
- **Auto-save**: On enemy destruction

#### Performance Optimizations
- **Particle Pooling**: Reused particle effects
- **Object Cleanup**: Proper queue_free() usage
- **Collision Layers**: Optimized collision detection
- **Screen Margins**: Efficient boundary calculations

#### Visual Effects
- **Particle Systems**: Hit effects, explosions, muzzle flashes
- **Trail Rendering**: Laser beams, training enemy paths
- **Shield Visualization**: Dynamic collision zones
- **UI Animations**: Smooth transitions and feedback

## Game Flow

1. **Initialization**: Load saved progress, setup spawners
2. **Enemy Spawning**: Queue-based wave system
3. **Player Interaction**: Touch/mouse turret control
4. **Combat**: Ammunition vs enemy collision detection
5. **Damage System**: Health/shield mechanics
6. **Scoring**: Enemy destruction rewards
7. **Game State**: Citizens and health tracking
8. **Persistence**: Auto-save on events

## Development Features

- **Debug Tools**: Reset button, debug labels
- **Cross-Platform**: Android + desktop testing
- **Modular Design**: Separate systems for easy expansion
- **Visual Feedback**: Comprehensive UI and effects
- **Scalable Architecture**: Easy to add new enemies/turrets

## File Structure Overview

```
Projectv4/
├── scripts/                    # Global scripts and constants
│   ├── Const.gd               # Game constants and enums
│   ├── GlobalVars.gd          # Game state and helper functions
│   ├── GlobalAmmoData.gd      # Ammunition configuration
│   ├── GlobalEnemyData.gd     # Enemy initialization
│   └── GlobalTurretData.gd    # Turret configuration
├── assets/
│   ├── enemies/               # Enemy types and behaviors
│   │   ├── EnemyBP.gd         # Base enemy class
│   │   ├── ScoutBehaviour.gd  # Scout AI implementation
│   │   └── Spawner.gd         # Enemy spawning system
│   ├── turrets/               # Turret types and ammunition
│   │   ├── TurretBP.gd        # Base turret class
│   │   └── TurretBPAmmo.gd    # Ammunition system
│   └── levels/                # Level scenes and spawner configs
│       └── Demo_spawner.gd    # Demo level spawner queue
├── ui/                        # User interface components
│   ├── UI.gd                  # Main UI controller
│   └── ColorReverse.gdshader  # Visual effect shader
└── project.godot             # Project configuration
```

## Key Design Patterns

1. **Singleton Pattern**: GlobalVars and other autoloads
2. **Factory Pattern**: GlobalAmmoData for ammunition creation
3. **State Machine**: Enemy and turret state management
4. **Observer Pattern**: UI updates based on game state changes
5. **Component System**: Modular enemy and turret behaviors

## Code Quality Notes

- **Type Safety**: Uses @export for editor integration
- **Error Handling**: Graceful fallbacks for missing resources
- **Performance**: Efficient collision detection and particle management
- **Maintainability**: Clear separation of concerns
- **Extensibility**: Easy to add new enemy/turret types

This documentation covers all existing logic in the DefendTheEarth project. The codebase follows good Godot practices with proper separation of concerns, modular design, and comprehensive systems for a tower defense game.
