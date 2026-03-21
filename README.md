# อีกฝั่งของเธอ (The Other Side)

An interactive FMV (Full Motion Video) story game built with Godot 4.6.

## Requirements

- [Godot 4.6.1](https://godotengine.org/download/) (stable)
- [Docker](https://www.docker.com/) (for video conversion only)

## Getting Started

### Run in editor
```bash
godot /path/to/project/project.godot
```

### Video setup
Videos are not included in the repository. Place `.ogv` (Theora) video files in the `data/` folders as defined in `data/scenes.json`.

Convert MP4 to OGV:
```bash
python3 tools/convert_video.py data/scene_X/video.mp4 --delete-original
```

## Export

### Web (WebGL)
1. Open Godot editor → **Project → Export**
2. Select **Web** preset
3. Click **Export Project**
4. Serve with a local HTTP server:
```bash
cd /path/to/export
python3 -m http.server 8080 --bind 127.0.0.1
```
5. Open http://localhost:8080/korat-game.html

### Desktop
```bash
# macOS
godot --headless --path . --export-release "macOS" build/mac/korat-game.dmg

# Windows
godot --headless --path . --export-release "Windows Desktop" build/win/korat-game.exe
```

## Project Structure

```
data/
  scenes.json          # All scene definitions (branching, videos, choices)
  scene_1/             # Video files per scene (.ogv)
  scene_2/
  ...
scenes/fmv/
  Main.tscn            # Entry point → Main Menu
  MainMenu.tscn        # Title screen
  ScenePlayer.tscn     # Video player + choice overlay
  ChoiceOverlay.tscn   # Dynamic choice buttons
  PhoneUI.tscn         # In-game phone (relationship + history)
scripts/fmv/
  GameManager.gd       # Autoload — scene data, relationships, history
  ScenePlayer.gd       # Video sequencing, fade transitions
  ChoiceOverlay.gd     # Choice buttons + relationship notifications
  PhoneUI.gd           # Phone UI with tabs
  MainMenu.gd          # Menu logic
tools/
  convert_video.py     # MP4 → OGV converter (requires Docker)
```

## Features

- Data-driven scene flow via `scenes.json`
- Multiple sequential videos per scene + looping video
- Branching choices with fade transitions
- Character relationship system (hidden from player)
- In-game phone UI (relationship view + choice history)
- Video cover-fill rendering (no black bars)
- Key Item system (coming soon)
- Unlockable choices (coming soon)

## Game Mechanics

### ระบบความสัมพันธ์ (Relationship System)
ทุกตัวเลือกที่ผู้เล่นเลือกจะส่งผลต่อความสัมพันธ์กับตัวละครแต่ละตัวแบบซ่อนอยู่เบื้องหลัง ผู้เล่นจะเห็นแค่คะแนนที่เปลี่ยนแต่ไม่รู้ว่าเป็นของตัวละครไหน สามารถเช็คความสัมพันธ์ได้ผ่านโทรศัพท์ในเกม

### ไอเทมสำคัญ (Key Item) — coming soon
บางตัวเลือกในเกมจะทำให้ผู้เล่นได้รับไอเทมสำคัญ ไอเทมเหล่านี้จะส่งผลต่อเนื้อเรื่องในฉากถัดๆ ไป เช่น ได้รับกุญแจจะสามารถเปิดประตูลับได้ หรือได้รับจดหมายจะทำให้เนื้อเรื่องเปลี่ยนไป

### ตัวเลือกที่ซ่อนอยู่ (Unlockable Choice) — coming soon
บางฉากจะมีตัวเลือกที่ซ่อนอยู่ ตัวเลือกเหล่านี้จะปลดล็อคได้เมื่อ:
- **ความสัมพันธ์** กับตัวละครบางตัวถึงระดับที่กำหนด
- **มีไอเทมสำคัญ** บางชิ้นอยู่ในมือ
- หรือ **ทั้งสองอย่าง** รวมกัน

ตัวเลือกที่ปลดล็อคได้จะเปิดเส้นทางใหม่ในเนื้อเรื่องหรือนำไปสู่ตอนจบที่แตกต่างออกไป ทำให้เกมมีความ replay value สูง

## Tech Stack

- Godot 4.6.1 (Mobile renderer)
- GDScript
- Video: OGV (Theora + Vorbis)
- Viewport: 1920x1080
