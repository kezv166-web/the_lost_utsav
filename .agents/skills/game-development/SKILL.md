---
name: game-development
description: >-
  Game development orchestrator and principles guide. Covers game loops,
  fixed timesteps, state machines, input abstraction, collision systems,
  2D sprite/tilemap pipelines, and performance budgets for web and standalone games.
---

# Game Development

> Architectural principles, design patterns, and implementation guidelines for game projects.

---

## When to Use This Skill

Activate this skill when designing, structuring, reviewing, or coding game systems:
- Frame rate & delta-time physics/simulation
- Character state machines (idle, walk, jump, attack, hurt, dead)
- Input abstraction layers (mapping keys/touch/gamepads to logical actions)
- 2D tilemaps, sprite sheets, camera tracking, and animations
- Collision detection (AABB, circles, spatial hashing)
- Object pooling and memory optimization (preventing GC stutter)
- Juice, game feel (screen shake, freeze frames, particle effects)
- Audio management and game state management

---

## Core Principles

1. **Fun is the first feature**: Prototype and validate the core gameplay loop before building massive auxiliary systems.
2. **Frame rate is non-negotiable**: 60 FPS is a core feature. Delta time is mandatory for all movement.
3. **Juice makes the difference**: Hit-stop freeze frames, screen shakes, dust particles, and snappy easing transform basic mechanics into satisfying combat.
4. **Scope discipline**: Ship a polished vertical slice first.

---

## Reference System Usage

Consult the specialized reference files in `references/` for in-depth rules and patterns:

* **For Creation & Code Architecture:** Consult [patterns.md](file:///d:/the_lost_utsav/.agents/skills/game-development/references/patterns.md) for battle-tested patterns (Delta Time, FSMs, Object Pools, Screen Shake, Input Buffers).
* **For Diagnosis & Bug Hunting:** Consult [sharp_edges.md](file:///d:/the_lost_utsav/.agents/skills/game-development/references/sharp_edges.md) for critical traps (GC spikes, collision tunneling, audio leaks, float drift).
* **For Code Review & Quality Gates:** Consult [validations.md](file:///d:/the_lost_utsav/.agents/skills/game-development/references/validations.md) to check against anti-patterns and performance violations.

---

## 1. The Game Loop & Timing

```
INPUT  → Read & buffer player action states
UPDATE → Process game simulation with a fixed timestep
RENDER → Interpolate & draw the current frame to canvas / screen
```

### Fixed Timestep Rule
- **Physics & Logic:** Tick at a fixed rate (e.g., 60Hz = 16.67ms per tick).
- **Rendering:** Runs via `requestAnimationFrame` as fast as the display allows.
- **Interpolation:** If delta time accumulates between ticks, interpolate render positions for silky smooth motion without physics glitches.

```javascript
let lastTime = performance.now();
let accumulator = 0;
const TIMESTEP = 1000 / 60; // 16.67ms

function loop(currentTime) {
  const dt = Math.min(currentTime - lastTime, 250); // clamp to avoid spiral of death
  lastTime = currentTime;
  accumulator += dt;

  // Process input
  input.update();

  // Fixed update ticks
  while (accumulator >= TIMESTEP) {
    gameState.fixedUpdate(TIMESTEP / 1000);
    accumulator -= TIMESTEP;
  }

  // Render with alpha blend
  const alpha = accumulator / TIMESTEP;
  renderer.render(gameState, alpha);

  requestAnimationFrame(loop);
}
```

---

## 2. Architecture & Pattern Matrix

| Pattern | Best For | Example in 2D Action Games |
|---|---|---|
| **Finite State Machine (FSM)** | Character / Enemy states | Player: `IDLE` → `RUN` → `JUMP` → `ATTACK` |
| **Object Pooling** | Frequent spawn/destroy entities | Weapon swings, particles, projectiles, floating text |
| **Observer / Event Bus** | Cross-system decoupled communication | Health change → UI update; Boss defeated → Trigger cutscene |
| **Component / Entity Composition** | Entities with varying capabilities | Player has `Transform`, `Sprite`, `Collider`, `Health` |
| **Content-as-Data** | Levels, enemy stats, weapon damages | JSON / config objects loaded at runtime |

**Rule of Thumb:** Start with clean FSMs and Composition. Avoid premature complex ECS (Entity-Component-System) unless simulating hundreds of identical active entities simultaneously.

---

## 3. Input Abstraction

Never bind raw keyboard/mouse events directly inside entity update logic. Abstract input into logical actions:

```javascript
// Logical Actions
const Actions = {
  MOVE_LEFT: 'move_left',
  MOVE_RIGHT: 'move_right',
  JUMP: 'jump',
  ATTACK_PRIMARY: 'attack_primary', // Axe / Melee
  ATTACK_SECONDARY: 'attack_secondary', // Rope / Special
  INTERACT: 'interact'
};

// Input System maps raw keys/touch to action states:
// isActionActive(action), isActionJustPressed(action)
```

This enables seamless keyboard rebinding, touch controls / virtual joysticks, and gamepad support without touching game logic.

---

## 4. 2D Sprite Sheets, Tilesets & Animations

For 2D sprite/tilemap games:
- **Sprite Sheets:** Store animations in compact grids. Maintain frame metadata: `frameWidth`, `frameHeight`, `frameRate`, and frame sequences per animation clip.
- **Tilemaps:** Divide maps into layers:
  - Background (decor, visual only)
  - Terrain / Collision (solid tiles)
  - Foreground / Overhead (rendered above entities)
  - Object / Spawners (spawn points, pickups, interactables)
- **Camera Follow:** Smooth lerping (linear interpolation) with deadzones and level boundary clamping.

---

## 5. Collision Strategies

| Strategy | Best Suited For | Implementation |
|---|---|---|
| **AABB (Axis-Aligned Bounding Box)** | 2D platformers, top-down tiles | Rect-rect overlap check `(x1 < x2 + w2 && ...)` |
| **Circle / Distance** | Radius triggers, weapon sweeps, round pickups | Distance squared `(dx*dx + dy*dy <= (r1+r2)^2)` |
| **Spatial Hashing / Grid Partitioning** | World with many entities | Bucket entities into grid cells; only test entities sharing cells |

---

## 6. Performance Budget (60 FPS Target = 16.67ms per frame)

| Subsystem | Target Budget |
|---|---|
| Input Processing | 1.0 ms |
| Physics & Collision | 3.0 ms |
| Game Logic & FSM | 4.0 ms |
| AI / Pathfinding | 2.0 ms |
| Rendering (Canvas/WebGL) | 5.0 ms |
| Safety Buffer | 1.67 ms |

---

## 7. Universal Game Dev Anti-Patterns

| Anti-Pattern | Recommended Practice |
|---|---|
| ❌ Allocating objects/arrays in the update loop (causes GC hitches) | ✅ Pre-allocate vectors, points, and reuse object pools |
| ❌ Mixing UI code directly inside game entity code | ✅ Keep UI in separate DOM/HUD overlay driven by events |
| ❌ Polling input state randomly throughout classes | ✅ Centralized input manager sampled at the start of the frame |
| ❌ Frame-rate dependent movement (e.g. `pos += 5`) | ✅ Always scale movement by delta time (e.g. `pos += speed * dt`) |
| ❌ Checking every entity against every other entity ($O(N^2)$) | ✅ Filter by layers, tags, or spatial grid partitioning |
