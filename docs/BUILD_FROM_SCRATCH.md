# Building "The Last Forge" From Scratch

A complete, step-by-step guide to building this 2D top-down roguelite in **Godot
4.7**. It is organised as **Parts** (big systems) made of **Lessons** (one
self-contained idea each). Every lesson ends with a **Checkpoint** — a playable
or testable state — so you always have something working.

You can read this start-to-finish to recreate the game, or jump to one Part to
understand how that system fits together. File names point at where the real
implementation lives (`scripts/`, `scenes/`, root `.tscn` files).

---

## What you're building

**The Last Forge** is a top-down, melee-combat roguelite. You wield a *corrupted
weapon*: every upgrade makes you stronger but raises a **corruption** meter, and
corruption is a double-edged sword — it boosts the damage you deal *and* the
damage you take. You descend through procedurally connected dungeon floors,
clearing rooms, collecting items that **combine into builds**, spending gold in
shops, gambling health at a Forge Altar, and fighting a boss at the bottom of
each floor.

**Design pillars** (borrowed from Binding of Isaac, Hades, Dead Cells):
1. **Build diversity** — items stack and *combine* into emergent synergies.
2. **Risk/reward economy** — corruption and the Forge Altar make every choice a
   gamble.
3. **Game feel** — hits land with flash, shake, hit-stop, particles and sound.

**Tech:** Godot 4.7 (Mobile renderer), GDScript, Kenney art tiles, procedurally
generated SFX/music.

---

## The mental model: how Godot games are wired

Three ideas underpin the whole project. Internalise these first:

1. **Scenes are reusable node trees.** A `.tscn` is a tree of nodes you build in
   the editor. You instance scenes inside other scenes. The Player, each enemy,
   each pickup, and the dungeon room are all scenes.

2. **Scripts add behaviour to nodes.** A `.gd` script `extends` a node type and
   adds logic. Prefer to keep *structure* (which nodes exist, their collision
   shapes, layers, groups, static visuals) in the **scene/inspector**, and keep
   *behaviour* (what happens each frame, in response to input/signals) in the
   **script**.

3. **Signals and groups decouple systems.** A node `emit`s a signal; others
   `connect` to it without knowing each other. Nodes join named **groups** so
   you can find them (`get_tree().get_first_node_in_group("player")`).

A fourth idea is specific to action games:

4. **Autoloads are global singletons.** Systems that everyone needs but nobody
   owns — the camera-shake/hit-stop manager, the audio manager, save data, scene
   transitions — are registered as **autoloads** so any script can reach them by
   name (`GameManager.shake_camera(...)`).

---

# Part 0 — Project setup

### Lesson 0.1 — Create the project & import art
- New Godot 4.7 project, **Mobile** renderer (cheap, no fancy lighting needed).
- Window size 1280×720, stretch mode `canvas_items`, aspect `expand`
  (`project.godot [display]`).
- Drop the Kenney tile PNGs into `Assets/`. Set the default texture filter to
  **Nearest** (`rendering/textures/canvas_textures/default_texture_filter=0`) so
  pixel art stays crisp.

### Lesson 0.2 — The Input Map
Open Project Settings → Input Map and add named actions. Naming inputs (not
hardcoding keys) is the first best practice. You'll add: `move_up/down/left/right`,
`dash` (Space), `quick_attack` (LMB), `heavy_attack` (RMB), `swap_weapon` (Q),
`active_item` (E), `interact` (F). (Pause uses the built-in `ui_cancel` = Esc.)

**Checkpoint:** the project opens and the input actions exist.

---

# Part 1 — The player

### Lesson 1.1 — Movement
- `Player.tscn`: a `CharacterBody2D` root with a `Sprite2D`, a `CollisionShape2D`,
  and (later) component children. Script: `PlayerController.gd`.
- Read input into a normalized vector and `move_and_slide()`:
  ```gdscript
  velocity = _get_move_input() * move_speed
  move_and_slide()
  ```
- Put `move_speed`, `dash_speed`, etc. as `@export var`s so they're tunable in
  the inspector.

### Lesson 1.2 — Aim & dash
- Aim a `WeaponPivot` child at the mouse every frame:
  `weapon.rotation = (get_global_mouse_position() - global_position).angle()`.
- Dash: a short burst of speed with **i-frames** (temporary invulnerability).
  Track `_is_dashing`, a duration timer, and a cooldown timer.

### Lesson 1.3 — A smooth camera
- `PlayerCamera.gd` on a `Camera2D` that lerps toward the player. Later you'll
  layer screen-shake (trauma), a directional kick, a zoom-punch and aim-lead on
  top — but start with a plain smooth follow.

**Best-practice note — defensive physics:** `move_and_slide()` will spam
"Vector2 cannot be normalized" forever if `velocity` ever becomes non-finite
(e.g. a bad knockback). Guard it: if `velocity`/`_knockback` isn't finite, zero
it before moving, and keep a `_last_good_pos` to restore from. (See
`PlayerController._physics_process`.)

**Checkpoint:** walk, aim and dash around an empty scene with a following camera.

---

# Part 2 — A reusable damage system (components)

This is the backbone of all combat. **Components** are small, single-purpose
nodes you reuse on the player, every enemy and every breakable prop.

### Lesson 2.1 — HealthComponent
`HealthComponent.gd` (a plain `Node`): holds `max_health`/`current_health`, with
`damage()`/`heal()`/`set_max_health()` methods and `damaged`/`healed`/`died`
signals. Nothing else in the game touches health directly — it goes through this.

### Lesson 2.2 — The Hitbox/Hurtbox contract
Two `Area2D` components, and **one rule that prevents 90% of collision bugs**:

- **`HitboxComponent`** *deals* damage. It is **passive** — it never reads
  overlaps. It just carries `damage`, `knockback_force`, `is_crit`, and a
  `hit_landed` signal.
- **`HurtboxComponent`** *receives* damage. It is the **active detector**: it
  watches for overlapping hitboxes, pulls their values, applies them to its
  sibling `HealthComponent`, knocks its body back, and plays hit feedback.

> **The rule: the Hurtbox is always the detector; hitboxes are passive.** This
> removes the "who checks whom?" ambiguity that makes collision code a mess.

### Lesson 2.3 — Collision layers (set these in the Inspector, not code)
Define a fixed bit assignment and set each node's layer/mask in the scene:

| Bit | Layer | Value |
|----|----|----|
| 1 | World | 1 |
| 2 | PlayerBody | 2 |
| 3 | EnemyBody | 4 |
| 4 | PlayerHurtbox | 8 |
| 5 | EnemyHurtbox | 16 |
| 6 | PlayerHitbox | 32 |
| 7 | EnemyHitbox / projectiles | 64 |
| 8 | Pickups | 128 |

Friendly fire is prevented purely by layers/masks: the player's hurtbox masks
*only* the EnemyHitbox bit, so a player-fired projectile on the PlayerHitbox bit
(32) is detected by enemy hurtboxes but never the player's. **No team-check code
needed.** Set these on the Area2D nodes in the inspector.

**Checkpoint:** a test dummy (Health + Hurtbox) takes damage from a hitbox and
dies, emitting `died`.

---

# Part 3 — Attacks & game feel ("juice")

### Lesson 3.1 — The weapon state machine
`WeaponController.gd` on the `WeaponPivot`. A tiny state machine —
`IDLE → WINDUP → ACTIVE → RECOVERY` — drives a quick slash and a heavier cleave.
During `ACTIVE` the attack hitbox is enabled; otherwise it's disabled. Store
weapon stats as **data profiles** (sword/spear/daggers) in a `const` array so
weapons are just data.

> **Deferred toggling gotcha:** enabling/disabling an Area2D's
> `monitorable`/`disabled` from inside a physics signal throws "can't change
> state while flushing queries". Always `set_deferred("monitorable", true)` etc.

### Lesson 3.2 — Juice helpers
`Juice.gd` is a library of static helpers reused everywhere: a white hit-`flash`
(via a shader material), `impact`/`spark` particle bursts, `squash`/`stretch`
scale pops, `afterimage` ghosts, `ring` expansions, `decal` splats, and floating
`damage_number`/`floating_text`. One place, so the player and every enemy share
identical polish.

> **Leak gotcha:** never use infinitely-looping tweens for ambient motion
> (`create_tween().set_loops()`) — they show up as "N ObjectDB instances leaked
> at exit". Do idle bob *procedurally* (`sin()` into `sprite.position.y`) and use
> particles for ambient flicker.

### Lesson 3.3 — Hit-stop & camera shake (the GameManager autoload)
`GameManager.gd` (autoload) is the glue for effects nobody owns:
- `shake_camera(trauma)` — random shake that decays.
- `hit_stop(seconds)` — freeze `Engine.time_scale = 0` for a few *real* ms to
  sell an impact. Use a token so the most-recent effect always wins.
- `slow_mo`, `camera_kick`, `zoom_punch`, `screen_impact` — the rest of the
  feel layer.

> **Time-scale gotcha:** when awaiting during hit-stop/slow-mo, use
> `create_timer(d, true, false, true)` (ignore_time_scale) or your awaits get
> stretched by the slowed clock.

**Checkpoint:** hitting a dummy *feels* good — flash, shake, a brief freeze,
particles, a damage number.

---

# Part 4 — Enemies & AI state machines

### Lesson 4.1 — EnemyBase
`EnemyBase.gd` (a `CharacterBody2D`) holds everything enemies share: the
`IDLE/CHASE/TELEGRAPH/ATTACK/RECOVERY/DEAD` state scaffold, telegraph helpers
(red shapes that warn the player), the melee `AttackArea`, knockback, hit
feedback, spawn-in animation, and death (gib + flash + decal). Concrete enemies
`extend EnemyBase` and override `_ai_process()`.

`EnemyBase.tscn` is the base scene; each enemy is an **inherited scene** that
swaps the texture and stats. The `"enemy"` **group is set on the EnemyBase.tscn
root** (in the editor) so every inherited enemy joins it automatically — no
`add_to_group` in code.

### Lesson 4.2 — Concrete enemies
Each overrides `_ai_process()` with its own pattern and sets its stats:
- **Grunt** — chase + simple melee.
- **Charger** — telegraph a line, then dash.
- **Caster** — keep distance, fire `Projectile`s.
- **Brute** — slow, huge telegraphed slam.
- **Skitterling** — fast, fragile swarmer.

> **Hit-stun (a real bug worth knowing):** a charging enemy re-sets
> `velocity = charge_dir * charge_speed` *every frame*. If your hit just does
> `velocity += knockback`, the knockback stacks on the charge and launches the
> enemy across the room. Fix: a short **hit-stun** — when struck, zero the
> enemy's AI velocity for a beat so the knockback *replaces* its motion. (See
> `EnemyBase.apply_knockback` / `_hitstun`.)

### Lesson 4.3 — Telegraph → attack → recovery
The readable-danger loop: every attack shows a red telegraph during WINDUP, has
a brief ACTIVE window where it can hurt you, then a RECOVERY you can punish.
Good enemies are *readable*.

**Checkpoint:** fight the core enemies; each one's tell is learnable.

---

# Part 5 — The room & wave loop

### Lesson 5.1 — RoomController
`RoomController.gd` orchestrates a fight: spawn a wave into the room, track how
many enemies are alive (via the `defeated` signal), and when the count hits zero,
"clear" the room. Containers (`Enemies`, `Projectiles`, `Pickups`) live in
`CombatRoom.tscn`; the `Projectiles`/`Pickups` **groups are set on those nodes in
the editor** so drops can find them.

### Lesson 5.2 — HUD
`HUD.gd` on a `CanvasLayer`: a health bar (with a lerping red "ghost" chip so you
see damage), the corruption meter, dash cooldown, a status banner, the upgrade
cards, and the death screen. The HUD registers itself with `GameManager` so any
system can reach it.

**Checkpoint:** clear a room of enemies and see "Room Cleared!".

---

# Part 6 — The corruption hook (upgrades)

This is the game's identity.

### Lesson 6.1 — UpgradeManager
`UpgradeManager.gd` holds every upgrade as a **plain dictionary** (`id`, `title`,
`desc`, `corruption` cost, `rarity`, and an `apply` Callable). Plain dicts (not
Resources) keep it trivial to read and extend. On room clear, offer 3 random
upgrades (rarity-weighted) as `UpgradeCard`s; the player picks one.

### Lesson 6.2 — Corruption as risk/reward
In `PlayerController`, corruption tiers (`Stable/Tainted/Corrupted/Overloaded`)
drive **two** multipliers: damage *dealt* and damage *taken*. Make them a knife's
edge — at Overloaded you deal +22% but take +40%, and more "corrupted elite"
enemies spawn. The whole game becomes "how greedy dare I be?"

**Checkpoint:** clear room → pick one of three cards → corruption rises and you
feel the trade-off.

---

# Part 7 — Procedural rooms

### Lesson 7.1 — A room built in code
`Dungeon.gd` (a `TileMapLayer`) builds the floor/walls procedurally. The tiny
`TileSet` (one atlas, a few tiles) is fine to **build in code** — there's no
benefit to a hand-authored `.tres` when the geometry is generated. Pick an
**intentional layout archetype** (pillars / ring / lanes / cover) instead of
random scatter so rooms feel designed.

### Lesson 7.2 — Decoration & destructibles
Dress rooms with boulders, braziers (with flame particles), and
`DestructibleProp`s (barrels/crates) — which are **"enemies that don't fight
back"**: they reuse the exact same Health + Hurtbox components, so your melee
smashes them for loot. A great lesson in component reuse.

**Checkpoint:** every room is a fresh, dressed layout.

---

# Part 8 — A connected dungeon (the roguelite shell)

### Lesson 8.1 — Generate a floor
`Dungeon.generate(depth)` grows a **random spanning tree** of rooms on a coarse
grid, carves 2-wide doorways, and types each room
(`ENTRANCE/COMBAT/TREASURE/BOSS/SHOP/ALTAR`). Store the tree edges (`links`) so
the minimap can draw corridors.

### Lesson 8.2 — Walk room-to-room
`RoomController` tracks which room the player is in each physics frame. Entering
an uncleared combat room **locks the doors** (gates) and spawns a depth-scaled
wave; clearing unlocks them. Treasure/shop/altar rooms open their contents
instead. Beating the **boss** descends to a deeper, harder floor.

### Lesson 8.3 — The minimap
`Minimap.gd` uses immediate-mode `_draw()` (this *must* stay in code — it's
custom drawing) to render a framed map: room boxes coloured by type, corridor
lines from `Dungeon.links`, and a pulsing outline on your current room.

**Checkpoint:** explore a connected floor, fight a boss, descend.

---

# Part 9 — Build diversity: items & synergies (the Isaac core)

The single most important Part for replayability.

### Lesson 9.1 — Items are owned and they stack
Stop applying upgrades as one-shot stat bumps. Give the player an `items` array
and **composable on-hit effect fields**: `burn_dps`, `chill_factor`,
`chain_count`, `execute_threshold`. Items add to these, so picking more
*compounds* the build. Show them in a HUD "BUILD" panel.

### Lesson 9.2 — Effects run on every hit
`WeaponController._apply_hit_effects()` runs the owned effects whenever a melee
hit lands: ignite (DoT), chill (slow), chain lightning to nearby enemies,
execute low-HP enemies, second-strike. `EnemyBase.ignite()/chill()` implement
the status side.

### Lesson 9.3 — Transformative items
Some items change *how the weapon works*: **Echo Blade** throws a piercing
ranged `SlashWave` on every swing (giving you ranged!), **Maelstrom** turns the
heavy attack into a 360° whirlwind, **Twin Fang** strikes twice.

> **Friendly-fire reminder:** `SlashWave.tscn` is on the PlayerHitbox layer (32),
> so enemy hurtboxes detect it but the player's doesn't. The capsule shape,
> crescent visual and layer live in the **scene**; the script only animates it
> and carries per-cast data.

### Lesson 9.4 — Synergies (the "broken build" moments)
Owning the right *pair* fuses into a bonus (`PlayerController._resolve_synergies`):
Ember + Storm = chain bolts that ignite; Echo + Frost = freezing waves; etc.
Even without explicit pairs, *composable effects* already create emergent builds
— that's the whole magic of this genre.

**Checkpoint:** two different runs feel completely different.

---

# Part 10 — The run economy: gold, treasure & shops

### Lesson 10.1 — Gold
Add `gold` to the run stats (`GameManager`). Kills and smashed props drop
`GoldPickup` coins. Gold is the **in-run** currency (lost on death), distinct
from `essence` (the **meta** currency, banked between runs).

### Lesson 10.2 — Pedestals: interact to take/buy
`ItemPedestal.tscn` is a walk-up stand. Its **collision shape, layers and static
plinth live in the scene**; the script builds only the data-driven orb and
name/price labels. Stand on it and press **F** to take/buy — a "Press F" prompt
appears while you're in range (clear, and no accidental purchases).

> **The bug this design prevents:** an `Area2D` with no `CollisionShape2D`
> *silently never detects anything*. Putting the shape in the scene makes its
> absence obvious. (The original version built the pedestal entirely in code and
> forgot the shape — so buying did nothing.)

- **Treasure room:** three free pedestals; taking one dismisses the rest.
- **Shop room:** priced pedestals + a reroll stand; pressing F spends gold.

**Checkpoint:** earn gold, walk into a shop, press F to buy an item.

---

# Part 11 — Risk & reward: the Forge Altar (your Devil Deal)

`RoomType.ALTAR` offers powerful items for a **max-HP** price (not corruption) —
the signature gamble, à la Isaac's Devil Room. Two pedestals, choose one, pay in
flesh. Refuse the deal if it would leave the player too frail. This is the
emotional peak of a run: "I'm strong but I'm down to 40 HP — do I dare?"

**Checkpoint:** every floor forces a greed decision.

---

# Part 12 — Active abilities ([E])

A single **active slot** with a charge bar (`PlayerController.set_active_item` /
`use_active`): **Forge Pulse** (a nova that damages + knocks back nearby
enemies), **Phase Step** (a blink with i-frames), **Blood Siphon** (drain nearby
enemies to heal). Found like any item; bound to **E**. The panic-button /
build-defining layer that Isaac and Gungeon lean on.

**Checkpoint:** a charged active turns the tide of a tough room.

---

# Part 13 — Audio & music

### Lesson 13.1 — AudioManager
`AudioManager.gd` (autoload) plays SFX by **name** through a pool of players, so
events like `AudioManager.play("hit")` map to one of several Kenney `.ogg`
variants with a little random pitch — repeats never sound robotic.

### Lesson 13.2 — Ambient music
Generate seamless-looping ambient pads procedurally (`tools/generate_music.py`):
make every voice frequency and LFO rate complete a *whole number* of cycles over
the loop length so there's no seam. `AudioManager.play_music()` crossfades on a
dedicated Music bus and survives scene changes (calm for menus, tense for the
dungeon). Background music is the single biggest "this is a finished game" lever.

**Checkpoint:** the game has a soundtrack and punchy SFX.

---

# Part 14 — Framing the run

### Lesson 14.1 — Title, Hub & meta-progression
`TitleScreen.tscn` → `Main.tscn`. `MetaProgression.gd` (autoload) banks `essence`
and permanent unlocks to `user://` with `ConfigFile`; the Forge `Hub.tscn` spends
it. Drifting ember particles + a living title glow make the menus feel alive.

### Lesson 14.2 — Scene transitions
`Transitions.gd` (autoload, a high-layer `CanvasLayer` with a fade rect,
`process_mode = ALWAYS`, ignore-time-scale tweens) fades to black on **every**
scene change. No more hard cuts.

### Lesson 14.3 — Pause menu
`Esc` (`ui_cancel`) toggles `get_tree().paused`. The pause UI and the HUD need
`process_mode = ALWAYS` so they keep handling input while the tree is paused;
the HUD's `_process` early-returns when paused. Resume / Restart / Return to
Title.

**Checkpoint:** a complete loop — Title → run → death summary → retry — that
opens, plays, pauses and transitions like a finished product.

---

# Part 15 — The full juice pass

Once the systems work, layer feel everywhere: a full-screen FX shader
(`shaders/screen_fx.gdshader`, UV-only so it compiles headless) for the
corruption vignette, low-health pulse and hurt flash; spark streaks and afterimages
on attacks; squash/stretch on stops, dashes and hits; a directional camera kick
and zoom-punch on heavy hits; a wave-clear slow-mo flourish; loot that bursts
and magnets to you; cards that fly in and flash on select. Juice is not a step —
it's a coat of paint you apply to *every* interaction.

---

# Appendix A — Project structure

```
project.godot          input map, autoloads, window/render settings
TitleScreen.tscn       main scene (entry point)
Main.tscn              CombatRoom + UI (HUD)
Hub.tscn               the Forge (between-runs upgrades)
scripts/               all GDScript (.gd)
scenes/                reusable scenes (Player, enemies, pickups, pedestal, wave…)
Assets/                Kenney tiles, audio, UI nine-patches
shaders/               flash.gdshader, screen_fx.gdshader
tools/                 generate_sfx.py, generate_music.py
docs/                  this file + COURSE_OUTLINE.md
```

**Autoloads** (global singletons): `GameManager`, `AudioManager`,
`MetaProgression`, `Transitions`.

---

# Appendix B — Best-practice principles used here

- **Structure in scenes, behaviour in scripts.** Collision shapes, layers,
  groups, and static visuals belong in the `.tscn`/inspector; only data-driven or
  per-frame logic belongs in code. (E.g. `ItemPedestal`/`SlashWave` keep their
  shapes + layers in the scene and build only their dynamic bits in code.)
- **Reusable components over copy-paste.** Health/Hitbox/Hurtbox are used by the
  player, every enemy, and props. A *reusable component* may set its own group in
  code (`HitboxComponent` joins `"hitbox"`) — that's DRY and correct; duplicating
  it across every scene instance would be worse.
- **Name your inputs and your groups.** Never hardcode keycodes or stringly-typed
  magic where an input action or a scene group reads clearer.
- **Data-driven content.** Upgrades, weapon profiles, and sound maps are plain
  `const` dictionaries/arrays — trivial to read and extend.
- **Defensive physics.** Guard `move_and_slide()` against non-finite velocity;
  use hit-stun so knockback doesn't stack on attack lunges.
- **Decouple with signals.** `health.died`, `enemy.defeated`, `hurtbox.hurt`,
  `pedestal.chosen` — systems talk through signals, not direct references.

---

# Appendix C — The headless validation workflow

You can validate the project without opening the editor — invaluable for catching
regressions:

```bash
# Catch parse/compile + scene-load errors:
Godot --headless --path . --import

# Run a scene for N frames then auto-quit (catches _ready/_process errors):
Godot --headless --path . res://Main.tscn --quit-after 900
```

Grep stderr for `error|warning|invalid|leaked`, filtering driver noise
(`rendering_device|d3d12|Vulkan|gl_compatibility`).

For paths headless can't reach without input (attacks, buying, dying), drive them
from a **temporary `Node` scene** that instances `Main.tscn`, then calls into it:
`player.weapon.try_quick_attack()`, `enemy.die()`,
`card.choose_button.pressed.emit()`. **Important:** to test an `Area2D` actually
*detecting* a body, you must move the body **incrementally** (walk it in via
`move_and_slide`/stepped position) — *teleporting* a body into an area does not
reliably trigger `body_entered`.

---

# Appendix D — Suggested commit checkpoints

One commit per Part keeps the history diffable and teachable. Tag them
`p0-setup`, `p1-player`, … `p15-juice`, so a learner can check out any stage and
see exactly that lesson's code.

> See also `docs/COURSE_OUTLINE.md` for the same material mapped to short,
> lesson-by-lesson course modules.
