# The Last Forge

A 2D top-down action roguelite built in **Godot 4.7**, from an empty project to a
shipped game — the companion code for the Coding Quests roguelike course.

You wield a corrupted weapon: every upgrade makes you stronger *and* raises a
corruption meter that boosts the damage you deal **and** the damage you take.
Descend through procedurally connected floors, clear rooms, collect items that
combine into builds, spend gold in shops, gamble health at the Forge Altar, and
fight a boss at the bottom of every floor.

---

## Checking out a lesson

`main` is the finished game. **Every lesson has its own branch**, holding the
project exactly as it stands at the *end* of that lesson.

```bash
git clone https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube.git
cd 2D-Roguelike-Tutorial-youtube
git checkout lesson-1.2     # the project as it is when lesson 1.2 ends
```

Then open the folder in Godot 4.7. Every branch is a complete, openable project —
not a diff, not a snippet. Each one also has a `LESSON.md` at the root telling you
what that lesson built and what changed since the last one.

Branches are chained: `lesson-1.2` is `lesson-1.1` plus that lesson's work. So

```bash
git diff lesson-1.1 lesson-1.2
```

shows you exactly what the lesson added — which is often the fastest way to catch
up if you got lost partway through a video.

---

## The 28 lessons

### Chapter 0 — The Plan
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-0.1` | The whole game, and why we build it backwards | An empty project, set up and ready |

### Chapter 1 — Make the Player Worth Controlling
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-1.1` | Move and aim | Walking one way, pointing another |
| `lesson-1.2` | The dash | One dash, then a wait |
| `lesson-1.3` | The frames that make a dodge work | Blue tint, passing through a hazard |
| `lesson-1.4` | A camera that doesn't fight you | Smooth follow, then shake that means something |

### Chapter 2 — Make Hitting Something Feel Good
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-2.1` | Something that can be hurt | A dummy takes damage and dies |
| `lesson-2.2` | Who checks whom | Hitbox/hurtbox, and no friendly-fire code |
| `lesson-2.3` | The swing | It swings, and it feels like nothing |
| `lesson-2.4` | Make the hit land | The same swing, before and after seven layers |

### Chapter 3 — Make One Room Worth Fighting In
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-3.1` | One enemy, off one script | It chases and hits you |
| `lesson-3.2` | Telegraphs — being readable beats being hard | A fight you can learn |
| `lesson-3.3` | Four enemies from the same base | Four different decisions |
| `lesson-3.4` | A boss with a tell | Patterns and an enrage |
| `lesson-3.5` | The room knows the fight is over | Doors lock, wave clears, HUD reads |

### Chapter 4 — Turn It Into a Run
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-4.1` | A room built in code | Floor, walls, a dressed space |
| `lesson-4.2` | Why random rooms are boring | Constrained randomness, dead space proved |
| `lesson-4.3` | A floor of connected rooms | Walk a whole floor |
| `lesson-4.4` | Knowing where you are | Minimap, room types, gated doors |

### Chapter 5 — Make Every Run Different
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-5.1` | The reward moment | Three cards, one choice |
| `lesson-5.2` | Power that costs you something | Corruption rising, and you feel it |
| `lesson-5.3` | Items you own, not stats you bump | Effects that compound |
| `lesson-5.4` | Gold, shops and the deal you shouldn't take | The altar, paid in health |

### Chapter 6 — Make Them Want Another Run
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-6.1` | A HUD that shows less | Thirteen elements down to five |
| `lesson-6.2` | Dying properly | A death screen that shows what the run was |
| `lesson-6.3` | Unlocks that widen, not unlocks that inflate | The Forge, and why +5 health is a trap |

### Chapter 7 — Make It Feel Finished
| Branch | Lesson | Ends with |
|---|---|---|
| `lesson-7.1` | The shell | Title, transitions, pause, restart |
| `lesson-7.2` | Sound is half the game | The same fight, muted then scored |
| `lesson-7.3` | The polish pass, and shipping it | Juice everywhere, then export |

`lesson-7.3` and `main` are the same tree — the last lesson *is* the finished game.

---

## Running it

1. Install **Godot 4.7** (standard build, no C#).
2. Open the project folder in the Godot project manager.
3. Press **F5**. `TitleScreen.tscn` is the entry point.

**Controls:** WASD move · Space dash · LMB quick attack · RMB heavy attack ·
Q swap weapon · E active item · F interact · Esc pause.

On the early lesson branches most of these don't exist yet — that's the point.

---

## How the project is laid out

```
project.godot          input map, autoloads, window/render settings
TitleScreen.tscn       main scene (entry point)
Main.tscn              CombatRoom + UI (HUD)
Hub.tscn               the Forge (between-runs upgrades)
scripts/               all GDScript
scenes/                reusable scenes (Player, enemies, pickups, pedestal…)
Assets/                Kenney tiles, audio, UI nine-patches
shaders/               screen FX, sprite FX, flash
tools/                 SFX/music generators, headless test scenes
docs/                  the long-form build guide
```

**Autoloads:** `GameManager`, `AudioManager`, `MetaProgression`, `Transitions`.

`docs/BUILD_FROM_SCRATCH.md` is the written companion to the whole course —
the same build, in prose, with the gotchas called out.

---

## Credits

Art: [Kenney](https://kenney.nl) tile packs. SFX and music generated
procedurally (`tools/generate_sfx.py`, `tools/generate_music.py`).
