# Over Employed - Engineering Specification

## Overview

"Over Employed" is a 2D time management game built in Godot 4.4 where players take on the role of a software engineer managing multiple office tasks simultaneously. The game features a fast-paced gameplay loop with task spawning, resource management, and strategic decision-making.

## Architecture Overview

### Core Systems
- **Game State Management**: Centralized in `main_room.gd`
- **Player System**: Character movement and interaction handling
- **Task System**: Dynamic task spawning and completion tracking
- **UI System**: Menu management and in-game HUD
- **Audio System**: Sound effects and music integration
- **Coffee System**: Power-up mechanics with timing

### Technology Stack
- **Engine**: Godot 4.4 with GL Compatibility renderer
- **Language**: GDScript
- **Resolution**: 3456x1944 viewport
- **Audio**: WAV/OGG format with AudioStreamPlayer2D

## Core Game Systems

### 1. Game State Management (`main_room.gd`)

The main room serves as the central orchestrator for all game systems:

```gdscript
# Key State Variables
var game_time_elapsed = 0.0
var is_game_active = false
var fail_count = 0
var max_fails = 3
var score = 0
var active_tasks = {}  # Dictionary tracking active tasks
```

**Task Spawning System:**
- Initial spawn: 1 random task at game start
- Cyclic spawning: New task every 5 seconds
- Task duration: 15 seconds to complete
- Failure condition: 3 failed tasks = game over

**Task Locations:**
- 3 Pushpal desks (workstations)
- 2 Computers
- 1 Printer
- 1 Coffee machine (special power-up)

### 2. Player System (`player.gd`)

**Movement:**
- WASD/Arrow key controls
- Normalized velocity with configurable speed (1000 units)
- Screen boundary clamping
- Animated sprite with directional animations

**Interaction System:**
- Proximity-based interaction areas
- Space key for task completion
- Visual feedback through speech bubbles
- Typing animation during interactions

**Speed Buff System:**
- Coffee consumption provides 2x speed boost
- 30-second duration
- Visual indicator in UI

### 3. Task System

#### Computer Tasks (`computer.gd`)
- **States**: Off (idle) → On (active task)
- **Interaction**: Press Space when nearby
- **Audio**: Computer startup and typing sounds
- **Visual**: Screen state changes, speech bubble indicators

#### Printer Tasks (`printer.gd`)
- **States**: IDLE, OUT_OF_PAPER, PAPER_JAM, FIXING, COMPLETED
- **Paper Jam Fixing**: Hold P key for 5 seconds
- **Paper Refill**: Requires paper from shelf
- **Visual**: Color-coded light indicators (red/yellow/green)

#### Desk Tasks (`pushpal_desk1.gd`, etc.)
- **Simple interaction**: Press Space to complete
- **Audio**: Typing sounds
- **Visual**: Computer sprite animation

### 4. Coffee System (`coffee.gd`)

**State Machine:**
```gdscript
enum CoffeeState { 
    IDLE, 
    READY_TO_MAKE, 
    BREWING, 
    READY_TO_DRINK, 
    DRINKING, 
    CONSUMED 
}
```

**Timing:**
- Initial spawn: 30 seconds after game start
- Brewing time: 15 seconds
- Drinking time: 5 seconds (hold Space)
- Buff duration: 30 seconds
- Respawn cycle: 30 seconds after buff expires

**Power-up Effect:**
- Doubles player movement speed
- Visual indicator in UI
- Automatic deactivation after duration

### 5. Resource Management

#### Paper System (`paper_shelf.gd`)
- **Pickup**: Press Space when shelf has active task
- **Inventory**: Managed by GameUI system
- **Respawn**: Automatic after printer use
- **Integration**: Required for printer paper refill tasks

#### Inventory System (`game_ui.gd`)
- **Items**: Paper, USB drives (planned)
- **Display**: Temporary status label near player
- **Persistence**: Maintained during gameplay

## UI System Architecture

### 1. Menu Management (`menu_manager.gd`)

**State Management:**
```gdscript
enum GameState { START_MENU, PLAYING, PAUSED, GAME_OVER }
```

**Menu Types:**
- **Start Menu**: Game entry point with title image
- **Pause Menu**: In-game pause with controls info
- **Game Over Menu**: Win/lose state with statistics
- **Settings Menu**: Audio and display options

**Pause System:**
- ESC key toggle
- Full game state preservation
- Process mode handling for UI responsiveness

### 2. Game UI (`game_ui.gd`)

**Components:**
- **Progress Bar**: For timed interactions (coffee drinking, paper jam fixing)
- **Inventory Display**: Temporary item status
- **Text Input**: Reserved for future command system

**Progress Bar System:**
- Configurable duration and description
- Tween-based animation
- Automatic cleanup

### 3. Visual Feedback System

**Speech Bubbles:**
- Task indicators (exclamation marks)
- Instruction bubbles (press Space, hold P)
- State-based visibility

**Light Indicators:**
- Printer: Red (jam), Yellow (out of paper), Green (ready)
- Coffee: Red (brewing), Green (ready), Off (idle)

## Audio System

### Sound Categories
- **UI Sounds**: Button clicks, menu transitions
- **Task Sounds**: Computer startup, typing, printer operation
- **Interaction Sounds**: Paper pickup, coffee brewing
- **Feedback Sounds**: Success, error, completion
- **Background Music**: Ambient office loop

### Implementation
- AudioStreamPlayer2D for spatial audio
- Preloaded sound resources
- Volume control through settings menu

## Input System

### Key Bindings (`project.godot`)
```gdscript
move_right: D, Right Arrow
move_left: A, Left Arrow
move_down: S, Down Arrow
move_up: W, Up Arrow
computer_activate: Space
cancel: P
coffee: C
```

### Input Handling
- **Movement**: Continuous input processing
- **Interaction**: Action-based with proximity detection
- **Hold Mechanics**: Space (coffee drinking), P (paper jam fixing)
- **Menu Navigation**: ESC for pause, arrow keys for selection

## Scene Structure

### Main Scenes
```
main_menu.tscn          # Entry point
main_room.tscn          # Main game scene
settings_menu.tscn      # Configuration
pause_menu.tscn         # In-game pause
```

### Game Objects
```
Player.tscn             # Player character
Computer.tscn           # Workstation
Printer.tscn            # Printer with states
Coffee.tscn             # Power-up system
PaperShelf.tscn         # Resource pickup
PushpalDesk*.tscn       # Workstations
```

## Data Flow

### Task Lifecycle
1. **Spawn**: Main room selects random inactive location
2. **Activation**: Location sets visual state and starts timer
3. **Interaction**: Player proximity enables interaction
4. **Completion**: Player action triggers completion
5. **Cleanup**: Timer stopped, visual state reset, score awarded

### Coffee Power-up Flow
1. **Spawn**: 30-second timer after game start
2. **Brewing**: 15-second brewing process
3. **Drinking**: 5-second hold interaction
4. **Buff**: 30-second speed boost
5. **Reset**: Return to idle, start respawn timer

## Performance Considerations

### Optimization Strategies
- **Object Pooling**: Reuse timer objects for tasks
- **Spatial Partitioning**: Proximity-based interaction areas
- **Audio Management**: Preloaded resources, spatial audio
- **UI Efficiency**: Minimal redraws, efficient layouts

### Memory Management
- **Resource Cleanup**: Automatic timer cleanup
- **Scene Transitions**: Proper signal disconnection
- **Audio Resources**: Preloaded and cached

## Error Handling

### Robustness Features
- **Null Checks**: Player and UI reference validation
- **State Validation**: Task completion verification
- **Timer Safety**: Automatic cleanup on scene changes
- **Input Validation**: Proximity and state checking

### Debug Features
- **Console Logging**: Task state changes and interactions
- **Visual Debugging**: Speech bubble and light indicators
- **State Inspection**: Game state variables in UI

## Extensibility

### Modular Design
- **Component-Based**: Each game object is self-contained
- **Signal-Based Communication**: Loose coupling between systems
- **Configurable Parameters**: Easily adjustable timing and values
- **Plugin Architecture**: Menu system as separate module

### Future Enhancements
- **Additional Task Types**: USB transfers, meetings
- **Multiple Levels**: Different office layouts
- **Power-ups**: More coffee types, equipment upgrades
- **Multiplayer**: Cooperative task management

## Build and Deployment

### Project Configuration
- **Godot Version**: 4.4 with GL Compatibility
- **Export Settings**: Desktop platform targeting
- **Asset Pipeline**: Automatic import processing
- **Version Control**: Git-friendly file structure

### Asset Organization
```
art/
├── backgrounds/     # Level backgrounds
├── character_mesh/  # Player sprites
├── coffee/         # Coffee machine assets
├── computer/       # Computer sprites
├── printer/        # Printer assets
├── run_cycle/      # Player animations
├── sounds/         # Audio files
└── static_assets/  # UI and menu assets
```

This engineering specification provides a comprehensive overview of the Over Employed game's architecture, systems, and implementation details, serving as documentation for development, maintenance, and future enhancements. 