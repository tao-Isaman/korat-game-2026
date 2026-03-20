# CLAUDE.md — korat-game

## Project overview
Godot 4.6 game project ("korat-game") using the Mobile renderer and Jolt Physics 3D engine.

## Tech stack
- **Engine**: Godot 4.6
- **Scripting**: GDScript (default for this project)
- **Physics**: Jolt Physics (3D)
- **Renderer**: Mobile (`renderer/rendering_method="mobile"`)
- **Platform targets**: macOS (primary dev), Windows (D3D12)

## Project structure
```
project.godot        # Main Godot project config
icon.svg             # Default project icon
.godot/              # Godot internal cache (gitignored)
```

## Conventions
- Line endings: LF (enforced via `.gitattributes`)
- Charset: UTF-8 (enforced via `.editorconfig`)
- Use GDScript for game logic (`.gd` files)
- Scene files use `.tscn` (text-based) format
- Resource files use `.tres` (text-based) format

## Development
- Open the project in Godot 4.6 editor
- Run scenes with F5 (main scene) or F6 (current scene)
- Export presets are configured per-platform in `export_presets.cfg`

## File organization guidelines
- `scenes/` — Scene files (`.tscn`)
- `scripts/` — GDScript files (`.gd`)
- `assets/` — Art, audio, fonts, and other media
- `addons/` — Godot plugins/extensions
- `resources/` — Shared `.tres` resource files

## Important notes
- Do not edit `.godot/` contents directly — these are engine-managed caches
- The `project.godot` file can be edited but prefer using the Godot editor UI
- Jolt Physics replaces the default Godot physics engine for 3D
