# Gemini Activity Log

## Significant Actions

### [2026-05-28] Push Code to Remote Repository
- Executed `git add .` to stage the changes including the updated Main Menu layout, the scripts, scenes definitions, and newly imported UI assets (`button.png`, `hear in her flow no bg.png`, `themesong.mp3` with loops, etc.).
- Excluded `.ogv` and `.mp4` video files from being added, as they are correctly ignored under `.gitignore`.
- Committed and pushed the changes to the remote repository.

### [2026-05-28] Add Logo Fade-In and Configure Intro Videos
- Implemented a smooth logo fade-in animation in `scripts/fmv/MainMenu.gd` using Godot `Tween` over a 2.0-second duration.
- Configured `data/scenes.json` to play the three intro videos in `scene_01` in the requested sequence: `entrance_sut.ogv`, `walkingtocamera.ogv`, and `classroom.ogv` sequentially before transitioning to `scene_02`.

### [2026-05-28] Isolate Custom Button Texture to Main Menu Only
- Reverted the global `assets/theme/default_theme.tres` theme to its original clean state (only defining global fonts Kanit-Regular/Medium) to ensure that in-game choice overlays and phone buttons use standard Godot buttons without the custom `button.png` textures or black text colors.
- Created a separate `assets/theme/main_menu_theme.tres` theme file that contains the custom `button.png` stylebox texture and black font color definitions.
- Configured `scenes/fmv/MainMenu.tscn` to use `main_menu_theme.tres` as its specific node theme, confining the custom styled buttons exclusively to the Main Menu.

### [2026-06-07] Redesign Buttons — Pill Shape with Bounce Animation
- **Replaced** texture-based button (`button.png`) with `StyleBoxFlat` pill-shaped design using corner_radius=50 for fully rounded ends.
- **Color scheme**: Very light orange background (`Color(1.0, 0.62, 0.3, 0.22~0.25)`), white border (2px), white text for contrast. Hover state uses deeper orange (`0.6 alpha`) + brighter white border (3px).
- **Created** `assets/theme/choice_theme.tres` — dedicated theme for all in-game choice overlay buttons.
- **Updated** `assets/theme/main_menu_theme.tres` — same pill style for Main Menu buttons (no more `button.png` texture).
- **Added** bounce (jiggle) hover animation in both `scripts/fmv/MainMenu.gd` and `scripts/fmv/ChoiceOverlay.gd` using `Tween` with `TRANS_ELASTIC` (scale up to 1.08) and `TRANS_SPRING` (scale back to 1.0). `pivot_offset` set to button center for correct scaling origin.
- **Translated** Main Menu button texts to Thai: เริ่มเกม, โหลดเกม, ตั้งค่า, เกี่ยวกับ, ออกจากเกม.
- **Adjusted Button Shapes & Color**: Replaced transparent/pill shapes with Solid Peach-Orange (hex `#F37A33`, RGB `(0.953, 0.478, 0.2)`) rounded rectangles (corner_radius = 24 / 16).
- **Increased Font Sizes**: Set choice overlay font size to 36px and Main Menu font size to 32px.
- **Fixed Font Size Override**: Removed `theme_override_font_sizes/font_size = 24` override configurations from `MainMenu.tscn` to allow the new Theme values to apply successfully.
- **Slim Choice Buttons**: Changed choice buttons to auto-fit to text by setting width to 0 and height to 58 (`Vector2(0, 58)`). Changed size flags to `SIZE_SHRINK_CENTER` so buttons align centered and don't stretch down off the screen. Increased the spacing (`separation`) between buttons to 80 in `ChoiceOverlay.tscn` for a better layout. Set `pivot_offset` dynamically via `resized` signal to maintain bounce symmetry.
- **Integrated Wait Sound**: Added calls to `_play_wait_sound()` in `ScenePlayer.gd` for all paths where choices are shown (direct loops, scenes with no video, and auto-advance timers).
- **Fixed Cut-off Click Sound**: Moved the click sound player logic to `GameManager.gd` (Autoload) under `play_click_sound()` to prevent scene-change transition deletions from cutting off the sound, and connected it to Main Menu and Choice Overlay buttons.

### [2026-06-07] Push Code to Remote Repository
- Executed `git add .` to stage the changes including the redesigned buttons (choice_theme.tres, main_menu_theme.tres), bounce animations, wait/click sound integration, scene configuration, and script adjustments.
- Committed and pushed the changes to the remote repository.
