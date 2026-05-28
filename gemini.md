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
