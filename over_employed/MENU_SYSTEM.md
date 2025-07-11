# Menu System Documentation

This document describes the menu system implemented for the Over Employed game, following the Godot documentation guidelines.

## Overview

The menu system consists of three main scenes:
1. **Main Menu** (`main_menu.tscn`) - The entry point of the game
2. **Settings Menu** (`settings_menu.tscn`) - Game settings and configuration
3. **Pause Menu** (`pause_menu.tscn`) - In-game pause functionality

## File Structure

```
over_employed/
├── main_menu.tscn          # Main menu scene
├── main_menu.gd            # Main menu script
├── settings_menu.tscn      # Settings menu scene
├── settings_menu.gd        # Settings menu script
├── pause_menu.tscn         # Pause menu scene
├── pause_menu.gd           # Pause menu script
└── fonts/
    └── Xolonium-Regular.ttf # Custom font for menus
```

## Main Menu (`main_menu.tscn`)

The main menu serves as the entry point for the game and provides navigation to other menus and the game itself.

### Features:
- **Start Game** - Launches the main game scene (`main_room.tscn`)
- **Settings** - Opens the settings menu
- **Quit** - Exits the game
- **Keyboard Navigation** - ESC key to quit, arrow keys to navigate
- **Mouse Hover Effects** - Visual feedback on button hover

### Usage:
The main menu is set as the main scene in `project.godot` and will be the first screen players see when launching the game.

## Settings Menu (`settings_menu.tscn`)

The settings menu allows players to configure game options.

### Features:
- **Volume Control** - Adjusts master audio volume with real-time preview
- **Fullscreen Toggle** - Switches between windowed and fullscreen modes
- **Back Button** - Returns to the main menu
- **Settings Persistence** - Settings are saved when returning to main menu

### Usage:
Accessible from the main menu or pause menu. Settings are applied immediately and saved when returning to the main menu.

## Pause Menu (`pause_menu.tscn`)

The pause menu provides in-game functionality without losing progress.

### Features:
- **Resume** - Returns to the game
- **Settings** - Opens settings menu (game will be unpaused)
- **Main Menu** - Returns to main menu (game will be unpaused)
- **Quit** - Exits the game
- **ESC Key Toggle** - Press ESC to pause/unpause

### Usage:
The pause menu should be added as a child node to your main game scene. It will automatically handle pause functionality when ESC is pressed.

## Implementation Details

### Scene Structure
All menus follow a consistent structure:
- `Control` node as root with full-screen anchors
- `ColorRect` background for visual appeal
- `VBoxContainer` for vertical layout of UI elements
- Consistent styling with custom fonts and colors

### Styling
- **Colors**: Dark blue theme with white text
- **Font**: Xolonium-Regular.ttf for consistent typography
- **Buttons**: Rounded corners with hover effects
- **Layout**: Centered content with proper spacing

### Input Handling
- **Keyboard Navigation**: Arrow keys and Enter/Space for selection
- **Mouse Support**: Full mouse interaction with hover effects
- **ESC Key**: Universal cancel/back functionality

## Adding the Pause Menu to Your Game

To integrate the pause menu into your main game scene:

1. Add the pause menu as a child node to your main game scene:
```gdscript
# In your main game scene
var pause_menu = preload("res://pause_menu.tscn").instantiate()
add_child(pause_menu)
```

2. The pause menu will automatically handle ESC key input and pause functionality.

## Customization

### Adding New Menu Options
1. Add new buttons to the scene file
2. Connect signals in the script
3. Implement the corresponding functions

### Changing Colors
Modify the `StyleBoxFlat` resources in each scene file to change button appearance.

### Adding New Settings
1. Add UI elements to `settings_menu.tscn`
2. Implement logic in `settings_menu.gd`
3. Add save/load functionality as needed

## Best Practices

1. **Consistent Navigation**: All menus use the same navigation patterns
2. **Keyboard Accessibility**: All menus support keyboard navigation
3. **Visual Feedback**: Hover effects and focus indicators
4. **Responsive Design**: Menus adapt to different screen sizes
5. **Performance**: Menus use efficient UI layouts

## Troubleshooting

### Common Issues:
- **Menu not showing**: Check that the scene is set as the main scene in `project.godot`
- **Buttons not responding**: Verify signal connections in the script
- **Font not loading**: Ensure the font file path is correct
- **Pause menu not working**: Make sure it's added as a child of your game scene

### Debug Tips:
- Use `print()` statements to debug signal connections
- Check the Output panel for error messages
- Verify scene file paths in the script 