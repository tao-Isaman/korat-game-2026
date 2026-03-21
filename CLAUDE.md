# CLAUDE.md — korat-game

## Project overview
FMV interactive story game called "อีกฝั่งของเธอ (The Other Side)" built in Godot 4.6. Data-driven scene flow with video playback, branching choices, and character relationship system.

## Tech stack
- **Engine**: Godot 4.6.1
- **Scripting**: GDScript
- **Renderer**: Mobile (`renderer/rendering_method="mobile"`)
- **Viewport**: 1920x1080, stretch mode `canvas_items`
- **Video format**: OGV (Theora + Vorbis) only — Godot 4 does NOT support MP4/WebM
- **Platform targets**: macOS (primary dev), Windows (D3D12)

## Project structure
```
project.godot
data/
  scenes.json              # Scene definitions (all game flow data)
  scene_1/                 # Video files per scene (gitignored)
  scene_2/
  ...
scenes/fmv/
  Main.tscn                # Entry point → MainMenu
  MainMenu.tscn            # Title screen with menu buttons
  ScenePlayer.tscn         # Video player + choices overlay
  ChoiceOverlay.tscn       # Dynamic choice buttons (CanvasLayer)
scripts/fmv/
  GameManager.gd           # Autoload singleton — scene data, relationships
  MainMenu.gd              # Menu logic (New Game, Exit)
  ScenePlayer.gd           # Video sequencing, fade transitions, scene flow
  ChoiceOverlay.gd         # Choice button creation + relationship apply
tools/
  convert_video.py         # MP4 → OGV converter (uses Docker)
```

## Autoloads
- `GameManager` → `scripts/fmv/GameManager.gd`

## FMV Scene System

### scenes.json format
```json
{
  "id": "scene_01",
  "title": "ฉาก 1 — หน้าอาคาร",
  "videos": ["res://data/scene_1/s1.1.ogv", "res://data/scene_1/s1.2.ogv"],
  "loop_video": "res://data/scene_1/loop.ogv",
  "duration": 5.0,
  "choices": [
    {
      "id": "choice_class",
      "icon": "",
      "label": "ไปเรียนกับใบเตย",
      "next": "scene_03",
      "relationship": { "baitoey": 10 }
    }
  ],
  "next": "scene_02"
}
```

### Video playback flow
```
videos[0] → fade → videos[1] → ... → videos[N] → loop_video (loops) + show choices
```
- `videos` (array): played sequentially, fade transition between each
- `loop_video` (string): loops after all videos finish, choices shown on top
- Fade starts 0.3s before video ends for smooth transition
- Video rendered via TextureRect with STRETCH_KEEP_ASPECT_COVERED (no black bars)
- Old `"video"` field (single string) still supported for backward compat

### Scene flow (no videos)
- `duration` > 0 + choices → show choices after timer
- `duration` > 0, no choices → auto-advance to `next`
- `duration` = 0 + choices → show choices immediately

### Special scene IDs
- `scene_main_menu` → returns to MainMenu.tscn (not handled in ScenePlayer)

## Relationship System

### Characters
| Key | Name |
|-----|------|
| `paeng` | แป้ง |
| `baitoey` | ใบเตย |
| `beam` | บีม |
| `ploy` | พลอย |

### How it works
- Each character has a relationship score: 0–100 (starts at 0)
- Choices in scenes.json can modify relationships via `"relationship"` field
- Positive values increase, negative values decrease
- Multiple characters per choice: `{ "baitoey": 5, "beam": -3 }`
- Empty `{}` or omitted = no change
- `GameManager.relationship_changed` signal fires on every change
- New Game resets all relationships to 0

## Video conversion
Godot 4 only supports `.ogv` (Theora). Convert MP4 using Docker:
```bash
python3 tools/convert_video.py data/scene_X/video.mp4
python3 tools/convert_video.py data/scene_X/*.mp4 --delete-original
```
Requires Docker (OrbStack) running. Uses `linuxserver/ffmpeg` image.

## Export

### Web (WebGL)
1. Open Godot editor: **Project → Export**
2. Select **Web** preset (Thread Support: Disabled)
3. Export to project root or `build/web/`
4. Run with local server:
```bash
python3 -m http.server 8080 --bind 127.0.0.1
# Open http://localhost:8080/korat-game.html
```

### CLI export (after preset created in editor)
```bash
# Web
godot --headless --path . --export-release "Web" build/web/index.html

# macOS
godot --headless --path . --export-release "macOS" build/mac/korat-game.dmg

# Windows
godot --headless --path . --export-release "Windows Desktop" build/win/korat-game.exe
```

### Export notes
- Web export bundles all videos into `.pck` (~600MB) — slow to load
- Export templates must be installed first (Godot editor → Editor → Manage Export Templates)
- Templates location on macOS: `~/Library/Application Support/Godot/export_templates/4.6.1.stable/`
- Web build requires HTTP server with proper headers (SharedArrayBuffer needs COOP/COEP if threads enabled)

## Git rules
- `*.ogv`, `*.mp4`, `*.pck`, `*.wasm` are gitignored — video/build files not tracked
- Web build output files (`korat-game.html`, `.js`, `.png`) are gitignored
- `data/scenes.json` IS tracked (scene definitions, not video data)

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
- CLI binary: `godot` (symlinked to `~/.local/bin/godot`)

## Godot CLI reference (v4.6.1)

### General
| Command | Description |
|---------|-------------|
| `godot --help` | Display help message |
| `godot --version` | Display version string |
| `godot -v, --verbose` | Use verbose stdout mode |
| `godot --quiet` | Quiet mode, silences stdout (errors still shown) |
| `godot --no-header` | Do not print engine version header on startup |

### Run options
| Command | Description |
|---------|-------------|
| `godot -e, --editor` | Start the editor instead of running the scene |
| `godot -p, --project-manager` | Start the project manager |
| `godot --recovery-mode` | Start editor in recovery mode (disables tool scripts, plugins, GDExtension) |
| `godot --debug-server <uri>` | Start editor debug server (e.g. `tcp://127.0.0.1:6007`) |
| `godot --dap-port <port>` | Set port for GDScript Debug Adapter Protocol |
| `godot --lsp-port <port>` | Set port for GDScript Language Server Protocol |
| `godot --quit` | Quit after the first iteration |
| `godot --quit-after <int>` | Quit after N iterations (0 = disable) |
| `godot -l, --language <locale>` | Use a specific locale (two-letter code) |
| `godot --path <directory>` | Path to project directory (must contain `project.godot`) |
| `godot --scene <path>` | Path or UID of scene to start |
| `godot --main-pack <file>` | Path to a `.pck` file to load |
| `godot --render-thread <mode>` | Render thread mode: `safe`, `separate` |
| `godot --remote-fs <address>` | Remote filesystem address (`host:port`) |
| `godot --remote-fs-password <pw>` | Password for remote filesystem |
| `godot --audio-driver <driver>` | Audio driver (`CoreAudio`, `Dummy`) |
| `godot --display-driver <driver>` | Display driver (`macos`, `headless`) |
| `godot --audio-output-latency <ms>` | Override audio output latency (default 15ms) |
| `godot --rendering-method <renderer>` | Set renderer (requires driver support) |
| `godot --rendering-driver <driver>` | Set rendering driver |
| `godot --gpu-index <index>` | Use a specific GPU device |
| `godot --text-driver <driver>` | Text driver for font rendering/shaping |
| `godot --tablet-driver <driver>` | Pen tablet input driver |
| `godot --headless` | Headless mode (no display, dummy audio). Useful for servers and `--script` |
| `godot --log-file <file>` | Write log to specified path |
| `godot --write-movie <file>` | Record video to file (`.avi` or `.png`) |

### Display options
| Command | Description |
|---------|-------------|
| `godot -f, --fullscreen` | Request fullscreen mode |
| `godot -m, --maximized` | Request maximized window |
| `godot -w, --windowed` | Request windowed mode |
| `godot -t, --always-on-top` | Request always-on-top window |
| `godot --resolution <W>x<H>` | Request window resolution |
| `godot --position <X>,<Y>` | Request window position |
| `godot --screen <N>` | Request window screen |
| `godot --single-window` | Use single window (no subwindows) |
| `godot --xr-mode <mode>` | XR mode: `default`, `off`, `on` |
| `godot --accessibility <mode>` | Accessibility mode: `auto`, `always`, `disabled` |

### Debug options
| Command | Description |
|---------|-------------|
| `godot -d, --debug` | Debug with local stdout debugger |
| `godot -b, --breakpoints <list>` | Breakpoints as `source::line` comma-separated pairs |
| `godot --ignore-error-breaks` | Prevent sending error breakpoints to debugger |
| `godot --profiling` | Enable profiling in script debugger |
| `godot --gpu-profile` | Show GPU profile of frame rendering tasks |
| `godot --gpu-validation` | Enable graphics API validation layers |
| `godot --gpu-abort` | Abort on graphics API usage errors |
| `godot --generate-spirv-debug-info` | Generate SPIR-V debug info (Vulkan only, for RenderDoc) |
| `godot --extra-gpu-memory-tracking` | Enable additional GPU memory tracking |
| `godot --accurate-breadcrumbs` | Force barriers between breadcrumbs (Vulkan only) |
| `godot --remote-debug <uri>` | Remote debug (e.g. `tcp://127.0.0.1:6007`) |
| `godot --single-threaded-scene` | Force scene tree to single-threaded mode |
| `godot --debug-collisions` | Show collision shapes when running |
| `godot --debug-paths` | Show path lines when running |
| `godot --debug-navigation` | Show navigation polygons when running |
| `godot --debug-avoidance` | Show navigation avoidance debug visuals |
| `godot --debug-stringnames` | Print all StringName allocations on quit |
| `godot --debug-canvas-item-redraw` | Show rectangle on canvas item redraw |
| `godot --max-fps <fps>` | Set max FPS (0 = unlimited) |
| `godot --frame-delay <ms>` | Simulate high CPU load (delay each frame) |
| `godot --time-scale <scale>` | Force time scale (1.0 = normal) |
| `godot --disable-vsync` | Force disable vertical sync |
| `godot --disable-render-loop` | Disable render loop (render only from script) |
| `godot --disable-crash-handler` | Disable crash handler |
| `godot --fixed-fps <fps>` | Force fixed FPS (disables real-time sync) |
| `godot --delta-smoothing <enable>` | Frame delta smoothing: `enable`, `disable` |
| `godot --print-fps` | Print FPS to stdout |

### Standalone tools
| Command | Description |
|---------|-------------|
| `godot -s, --script <script>` | Run a GDScript file |
| `godot --main-loop <name>` | Run a MainLoop by global class name |
| `godot --check-only` | Only parse for errors and quit (use with `--script`) |
| `godot --import` | Import resources then quit |
| `godot --export-release <preset> <path>` | Export project in release mode |
| `godot --export-debug <preset> <path>` | Export project in debug mode |
| `godot --export-pack <preset> <path>` | Export project data only (PCK/ZIP) |
| `godot --export-patch <preset> <path>` | Export pack with changed files only |
| `godot --patches <paths>` | Comma-separated patch list for `--export-patch` |
| `godot --install-android-build-template` | Install Android build template |
| `godot --convert-3to4` | Convert project from Godot 3.x to 4.x |
| `godot --validate-conversion-3to4` | Preview 3.x to 4.x conversion changes |
| `godot --doctool [path]` | Dump engine API reference as XML |
| `godot --gdextension-docs` | Generate API docs from GDExtensions (with `--doctool`) |
| `godot --gdscript-docs <path>` | Generate API docs from GDScript inline docs (with `--doctool`) |
| `godot --build-solutions` | Build scripting solutions (e.g. C#) |
| `godot --dump-gdextension-interface` | Generate `gdextension_interface.h` |
| `godot --dump-extension-api` | Generate `extension_api.json` |
| `godot --validate-extension-api <path>` | Validate extension API compatibility |
| `godot --benchmark` | Benchmark run time and print to console |
| `godot --benchmark-file <path>` | Benchmark and save to JSON file |

### Common usage examples
```bash
# Open editor for current project
godot --path . -e

# Run the main scene
godot --path .

# Run a specific scene
godot --path . --scene res://scenes/main.tscn

# Run with debug collision shapes visible
godot --path . --debug-collisions

# Run headless (for CI/servers)
godot --path . --headless -s res://scripts/test.gd

# Export release build
godot --path . --export-release "macOS" builds/game.dmg

# Check GDScript for errors without running
godot --path . -s res://scripts/main.gd --check-only
```

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
