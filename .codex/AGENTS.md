# AGENTS.md

## Purpose

You are Codex working in a Godot game project with a limited token budget.

Your goals, in order:
1. make correct, reviewable changes
2. preserve scene/resource integrity
3. minimize unnecessary tokens
4. avoid broad speculative rewrites
5. keep the game buildable and debuggable

Optimize for useful progress, not verbosity.

---

## Core Rules

### 1. Read narrowly first
Inspect only the files most likely to matter:
- the specific `.gd` script named in the task
- the related `.tscn` scene
- directly referenced autoloads, resources, or helper scripts
- project settings only if relevant

Do not perform broad repo summaries.

### 2. Do not restate visible context
Do not paraphrase:
- pasted code
- visible scene content
- error logs
- existing file contents

Only mention details that affect the fix.

### 3. Prefer the smallest safe change
Choose:
- local fix before refactor
- script patch before scene rewrite
- minimal node changes before scene restructuring

Avoid unrelated cleanup.

### 4. Preserve Godot project stability
Be careful with:
- node names
- node paths
- exported variables
- signal connections
- resource references
- autoload names
- input action names

Do not change any of these unless necessary.

### 5. Explain only what matters
Default response:
- patch or code first
- short rationale second
- short verification note third

Do not give long tutorials unless asked.

---

## Token Budget Policy

Treat tokens as scarce.

Always minimize:
- repeated summaries
- full-file dumps
- broad architecture tours
- long alternative lists
- line-by-line explanations

Prefer:
- focused diffs
- exact file targets
- short verification steps
- brief notes about engine-specific risks

Default limits unless asked otherwise:
- explanation under 120 words
- alternatives max 2
- bullets max 6
- examples max 1
- comments only for non-obvious logic

---

## Godot-Specific Reading Strategy

When solving a task, inspect in this order when relevant:

1. the target `.gd` file
2. the owning `.tscn` file
3. any directly referenced child scene or resource
4. autoload or singleton involved
5. `project.godot` only if input, autoloads, display, physics, or plugin config matters

Do not read large unrelated scene trees unless the task truly depends on them.

If a scene file is large:
- inspect only the nodes/scripts involved
- avoid summarizing the whole tree

---

## Scene Safety Rules

### 1. Be conservative with `.tscn` and `.tres`
Do not rewrite large sections of scene/resource files unless necessary.

Prefer:
- changing a script attached to a node
- adding a small property change
- preserving resource ordering and formatting where possible

### 2. Do not rename nodes casually
Renaming nodes can break:
- `$NodePath` references
- `%UniqueName` references
- signal targets
- animation tracks
- script assumptions

Rename only if required.

### 3. Do not move nodes casually
Moving nodes may break:
- relative NodePaths
- scene instantiation assumptions
- UI layout behavior
- animation and signal bindings

### 4. Respect instanced scenes
When a scene is instanced elsewhere:
- prefer fixing shared script behavior
- avoid intrusive scene-local edits unless the bug is scene-specific

### 5. Preserve exported properties
Do not rename or remove `@export` variables unless necessary.
Scene data may depend on them.

---

## GDScript Coding Rules

When editing GDScript:
- preserve the existing style unless clearly harmful
- prefer simple, readable logic
- avoid unnecessary abstractions
- avoid clever one-liners if they reduce debug clarity
- keep functions focused and local

Prefer:
- explicit state changes
- readable conditions
- stable node access
- small helper functions only when they reduce duplication meaningfully

Avoid:
- speculative architecture rewrites
- introducing patterns the project is not already using
- changing signal flow without a clear reason

### Typing
If the project already uses typed GDScript, preserve it.
If it does not, do not force typed rewrites across the file.

### Node access
Prefer the project’s existing convention:
- `$Node`
- `%Node`
- `get_node(...)`
- cached `@onready var`

Do not convert access style unless there is a real bug or consistency reason.

---

## Signal and Input Rules

### Signals
Before changing signal logic:
- verify where the signal is emitted
- verify where it is connected
- prefer local fixes over rewiring the entire flow

Do not casually replace signals with direct calls unless the architecture clearly prefers it.

### Input
When input is involved:
- check action names carefully
- preserve existing input map conventions
- do not invent new actions unless necessary
- if a new action is required, mention the exact `project.godot` or Input Map update needed

---

## Autoload / Singleton Rules

Be careful with autoloads.
Before editing:
- confirm the singleton name used in code
- preserve public methods and data shape where possible
- avoid turning a local problem into a global system rewrite

If a bug can be fixed locally, do that first.

---

## UI Rules

For UI scenes:
- preserve anchors, containers, and size flags unless the task is layout-related
- avoid restructuring Control node hierarchies without need
- keep fixes local to the affected screen

If changing UI behavior:
- prefer script adjustments before large scene layout edits

---

## Physics and Gameplay Rules

For gameplay and physics bugs:
- identify whether the issue is in:
  - input handling
  - frame loop (`_process`)
  - physics loop (`_physics_process`)
  - collision layers/masks
  - state transitions
  - scene setup

Give the top likely cause first.

Do not mix `_process` and `_physics_process` behavior casually.
Preserve the project’s existing gameplay timing model unless the bug requires changing it.

---

## Animation Rules

When animation is involved:
- check whether behavior is controlled by `AnimationPlayer`, `AnimationTree`, Tween, or code
- prefer minimal fixes in the controlling layer
- avoid changing animation track structure unless necessary

Do not rename animated nodes casually.

---

## Testing and Validation Strategy

Be selective.

Prefer:
1. the smallest validation relevant to the change
2. running or describing the exact scene to test
3. checking logs or expected runtime behavior
4. broader validation only if the change is cross-cutting

If engine execution is unavailable, provide the shortest meaningful manual verification steps.

Example verification style:
- open scene `res://scenes/player/player.tscn`
- run movement test
- confirm jump only triggers once per press
- confirm no new errors appear in debugger

Do not claim the game works unless it was actually verified.

---

## Debugging Format

For bugs, prefer:

Cause:
Fix:
Verify:

Keep it short.

Example:
Cause: The attack state is reset every frame because `_process()` overwrites the state set by the input handler.  
Fix: Guard the idle transition so it does not run while `is_attacking` is true.  
Verify: Run the player scene and confirm attack animation completes before returning to idle.

---

## Editing Strategy

When making changes:
- keep edits local
- preserve scene structure
- preserve public script APIs where possible
- avoid unrelated formatting changes
- do not touch generated or editor-managed content without reason

If editing a scene file:
- change only the required section
- avoid reserializing unrelated nodes/resources

If editing multiple files:
- make sure each edit is directly necessary
- do not widen scope unless evidence requires it

---

## Planning Strategy

For simple tasks:
- act immediately

For bigger tasks:
- use a short plan with at most 5 steps
- begin executing after the plan

Do not spend many tokens planning obvious work.

---

## Response Format

### For script fixes
Use:
- file path
- changed snippet or patch
- 1 to 3 short notes
- quick verify step

### For scene fixes
Use:
- what scene/script changed
- exact node or property affected
- short warning if node paths/signals may be impacted
- quick verify step

### For gameplay bugs
Use:
- likely cause
- exact fix
- quick runtime check

### For feature work
Use:
- recommended minimal implementation
- changed files
- concise reasoning
- test path

---

## When To Spend More Tokens

Increase detail only if:
- the fix touches multiple scenes
- there is risk of breaking node paths or signals
- physics/gameplay timing is subtle
- save/load data compatibility matters
- the user explicitly asks for depth

Even then, stay compact.

---

## Anti-Patterns

Do not:
- rewrite whole scenes for a local issue
- rename nodes without need
- replace working signal systems casually
- summarize the entire scene tree
- dump full files unless requested
- propose broad engine migrations
- claim a scene was tested if it was not

Avoid filler and avoid tutorial-style narration unless asked.

---

## Repository Preferences

Assume these defaults unless the project indicates otherwise:
- preserve existing scene hierarchy
- prefer script-level fixes
- keep gameplay behavior stable
- do not add addons or dependencies casually
- do not change public exported variables without need
- do not rewrite working code for style reasons

---

## Honesty Rules

Never claim to have:
- run the game if you did not
- tested a scene if you did not
- inspected files you did not inspect
- verified behavior you did not verify

If uncertain:
- say what is uncertain in one sentence
- give the most likely safe next step

---

## Final Rule

Every token should earn its place.

Be concise by default.
Be detailed only when detail reduces risk.
Make the smallest correct change that keeps the Godot project stable.

## Project-Specific Preferences

### Search
- Prefer targeted symbol/path search over broad repo reading.
- Inspect the attached script and owning scene first.
- Only inspect `project.godot` when input, autoloads, plugins, or engine settings matter.

### Scripts
- Prefer local GDScript fixes over architectural rewrites.
- Preserve existing node access style.
- Preserve exported variables and signal flow unless necessary.

### Scenes
- Do not rename or move nodes unless required.
- Keep `.tscn` changes minimal.
- Avoid unrelated scene reserialization.

### Validation
- Prefer the smallest manual runtime test path.
- Name the exact scene to open and behavior to verify.
- Do not imply engine-side verification was performed unless it actually was.

### Output
- Give patch first when possible.
- Keep explanation short.
- Mention node path or signal risks only if relevant.