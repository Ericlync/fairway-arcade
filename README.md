# Fairway Arcade

Golden Tee-inspired 3D arcade golf, using a MacBook trackpad as the swing
control. The active project is now **Godot 4.7.2**, in `godot/`. The original
Ursina prototype (`main.py`, `golfi/`, `run_game.py`, and `.venv/`) is preserved
and is no longer the game entry point.

## Why Godot

Ursina/Panda3D was already installed, so it was a fast first prototype. Running
it on this Mac exposed an upstream macOS shader compatibility issue: the
installed Panda3D context and Ursina's built-in shaders disagree on supported
GLSL versions. A newer GL context alone did not resolve it cleanly. Godot has a
more complete editor and cross-platform 3D workflow, avoids this Ursina shader
path, and provides mouse-pointer events suitable for the first trackpad swing
prototype. The project uses Godot's OpenGL Compatibility renderer for this
Intel Mac and a lightweight, dependency-free GDScript project.

## Run

Godot 4.7.2 is installed on the development Mac. If needed, install Godot for
Intel macOS from the [official download page](https://godotengine.org/download/).
With the Godot command line in `PATH`:

```sh
godot --editor --path godot
```

Press **F6** to run the current scene from the editor, or run the 3D game
directly:

```sh
godot --path godot scenes/game.tscn
```

To run an automated flight test (launches a 92% power shot after 1.5 s), add
`--test-shot`:

```sh
godot --path godot scenes/game.tscn --test-shot
```

## Current build

**Milestone 1 — 3D conversion is playable.** The new `scenes/game.tscn` loads a
fully procedural 3D first hole with real elevation: tee, fairway, green, bunkers,
water hazard, trees, cup, flagstick, and boundary walls. The terrain visual mesh
shares its height data with a `HeightMapShape3D` collider, so the ball rolls over
slopes instead of a flat plane.

The visible golf ball can be aimed through a full **360° orbit** with the
left/right arrow keys, launched with the trackpad swing, and followed by an
elevated arcade camera. Camera states cover aiming, swing, flight follow, and
resting after the ball settles.
The HUD displays hole, par, strokes, distance to cup, lie, aim, power, shot
shape, and explicit airborne/bounce/settled feedback.

Use the left/right arrow keys to aim smoothly around the entire ball. Hold the
left trackpad click,
drag down for a backswing, flick up, then release to hit. The trackpad now
controls only backswing power, forward swing speed, acceleration, and lateral
swing-path deviation. A live power gauge, club-path line, and predicted ball
path show the result before release; lateral deviation still produces
intentional pull/push and hook/slice behavior. These pointer measurements are
affected by macOS acceleration and will need calibration on the actual device.

Use **↑ / ↓** or **1–6** to select Driver, 3-Wood, 5-Iron, 7-Iron, Wedge, or
Putter. Club selection changes launch angle, speed, spin, and shot distance.

The old 2D/flat prototype (`scenes/main.tscn`, `scripts/main.gd`, etc.) is
preserved but no longer the entry point.

## Architecture

```text
godot/
  project.godot
  scenes/
    game.tscn            # Main 3D scene (set as run/main_scene)
    main.tscn            # Legacy 2D/flat prototype scene
  scripts/
    game.gd              # 3D scene composer and game loop
    golf_course.gd       # Procedural first-hole terrain and surface logic
    terrain_manager.gd   # Heightfield mesh + HeightMapShape3D collision
    golf_ball.gd         # Rigid-body ball, surface detection, and visuals
    golf_ball_physics.gd # Configurable flight/ground physics
    golf_camera.gd       # Arcade camera states and interpolation
    club_data.gd         # Driver, woods, irons, wedge, and putter profiles
    trackpad_input.gd    # Raw pointer swing sampling
    golf_swing_controller.gd # Combines input with shot calculation
    shot_calculator.gd   # Launch direction, power, and spin
    golf_hud.gd          # Arcade UI
    game_manager.gd      # Strokes, par, and water/OOB handling
    # Legacy prototype scripts (preserved)
    main.gd, swing_input.gd, course.gd, camera_rig.gd, hud.gd
  tests/
    swing_input_smoke.gd # Headless swing-to-shot check
    inspect_heightmap.gd # Sanity check for HeightMapShape3D properties
```

Keep future game-state/scoring rules, terrain surfaces, and audio/visual effects
independent of pointer input and ball physics. No asset pack or third-party
runtime dependency is required for this first playable scene.

## Roadmap

1. **Godot project and window** — done.
2. **Milestone 1: 3D conversion** — done. Real heightfield terrain, 3D ball,
   elevated arcade camera, aim indicator, and trackpad swing in `scenes/game.tscn`.
3. **Milestone 2: Golf physics** — in progress. Club-specific launch and roll
   resistance, controlled bounce, slope rolling, and static-friction stopping
   are implemented; continue tuning against real-device feel.
4. **Milestone 3: Advanced swing mechanics** — refine pull/push/hook/slice
   mapping, face-to-path relationships, and on-device calibration.
5. **Milestone 4: Course and assets** — improve terrain materials, textures,
   trees, water, bunkers, and lighting.
6. **Milestone 5: Polish** — camera refinements, ball visuals/shadows, sound
   effects, full scoring, and putting.

## Smoke test

```sh
godot --headless --path godot --script res://tests/swing_input_smoke.gd
```
