# GYMR // BEYOND_PERFORMANCE // VERSION

## Current: v0.1.5 — "OVARCH Plan DayBlock WB Picker + DEL PAST Cleanup"
Date: 2026-06-13
DB Schema: 29

### Version Scheme
`vMAJOR.MINOR.PATCH[-suffix]`

| Segment | Rule |
|:---|:---|
| **MAJOR** | Production-ready. v1.0 when core PNDEV resolved |
| **MINOR** | Feature release. New capability |
| **PATCH** | Bugfix / polish pass |
| **-dev** | Known bugs present. Not stable |
| **(none)** | ≥90% confidence, no known hidden bugs |

### Changelog

#### v0.1.5 — 2026-06-13
- [NEW] WO.BLCKS `DEL PAST` aggressive cleanup button removes stale workout blocks not currently visible in WO.BLCKS; if the current list is empty, it deletes all possible WBs.
- [FIX] OVARCH Plan Day WB picker no longer shows deleted/stale WBs by filtering real WB rows through `COALESCE(deleted_at, 0) = 0`, legacy `wb_store`, and real soft-delete state.
- [FIX] OVARCH Plan Day WB picker maps the exact `QualitySearchPicker` visible label back to the block ID, avoiding duplicate-name selection bugs.
- [FIX] `plan_day_blocks` legacy compatibility repair adds/backfills `day_id`, `plan_day_id`, `block_id`, and `workout_block_id` in `beforeOpen`.
- [FIX] DayBlock insertion now populates both normalized and legacy FK columns so older DBs do not fail on `NOT NULL constraint failed: plan_day_blocks.plan_day_id`.
- [POLISH] Added OVARCH picker/debug logs for active WBs, picker selection, and DayBlock insertion.

#### v0.1.3 — 2026-06-05
- [NEW] Batch headers in PDF export: full-width styled containers (blueGrey100) between batch segments
- [NEW] Nexus export cards: each format now has SHARE + DOWNLOAD buttons side by side
- [NEW] DOWNLOAD button saves file via FilePicker.platform.saveFile(bytes:) directly (mobile-compatible)
- [NEW] ExportService methods accept `bool share = true` parameter — DOWNLOAD passes share: false
- [NEW] Pie chart ≤2% grouping: items with ≤2% of total are grouped into white OTHER slice
- [CHANGE] _buildSynthesisCard accepts onShare + onDownload callbacks instead of single onTap
- [CHANGE] Somatic registration overlay: folder picker dropdown + auto-assign to folder on register
- [CHANGE] SOMATIC_LOGS: collapsible ALL LOGS section, folders tap to sub-screen
- [CHANGE] Inject movement sort button (6 modes) + removed SEARCH label
- [CHANGE] LabUtilitySelector: new utility text field + sort toggle (4 modes) + theme-colored borders
- [CHANGE] Interleaved batch/unbatched rendering (batches and solo groups mix in orderIndex order)
- [CHANGE] Global batch registry (batch_definitions table via beforeOpen)
- [POLISH] MuscleDonutChart: threshold-based OTHER aggregation for clean pie charts
- [FIX] _confirmDelete (DELETE_KNS): raw SQL with FK-safe order
- [FIX] last_insert_rowid() for folder-log association on somatic registration
- [FIX] Widget tree nesting errors in workout_manager (indentation, builder closure)

#### v0.1.2 — 2026-06-05
- [NEW] Global Batch Registry (batch_definitions table via beforeOpen, NO schema bump)
- [NEW] Interleaved batch/unbatched rendering: batches and solo groups mix in orderIndex order
- [NEW] LabUtilitySelector: text field for new utilities + sort toggle (A-Z, Z-A, MST, NEW)
- [NEW] INJECT_MOVEMENT sort button: 6 modes (A-Z, Z-A, NEW, OLD, MST, LST)
- [NEW] KNS counter in session header ribbon (between SETS and PRs)
- [NEW] Global set numbering (#1 = top of session, sequential down)
- [NEW] Theme Wiring Guide in gymr skill (7-step recipe)
- [NEW] RIR hidden for isometric sets (ISO metadata detection)
- [CHANGE] Batch edit/delete per-chip (✏️ + 🗑️ on each existing batch chip)
- [CHANGE] 2-column chip layout in ASSIGN_BATCH dialog + scrollable
- [CHANGE] FIELD filter → IMPL filter in ExerciseSearchPicker
- [CHANGE] Theme section titles: removed C.WO_ prefix, removed PRIORITY_, UTILS only
- [CHANGE] Theme entries display: TAG_ prefix stripped from labels
- [CHANGE] SET/PR column headers unified height & color with LOAD/REPS headers
- [CHANGE] LOAD (KG) → LOAD
- [CHANGE] NEW RECORD → PR (space for checkbox, later moved to backburner)
- [CHANGE] Collapsible sections (batches, General Notes) default-collapsed
- [POLISH] Drag handle hitbox enlarged (2x wider left, 1.2x taller)
- [POLISH] All column headers same height (padding vertical 4, no bottom borders)
- [FIX] DELETE_KNS: raw SQL with FK-safe order (was broken via Drift DAO)
- [FIX] Compile errors: $ escaped in SQL, runSelect(..., []) args
- [FIX] beforeOpen hot-reload safety net for raw-SQL tables
- [FIX] LabUtilitySelector theme colors: uses ref.read(themeControllerProvider) + replaceAll(' ', '_')

#### v0.1.1-hotfix1 — 2026-05-31
- [FIX] Drag handle now works: unbatched groups wrapped in ReorderableListView; batched groups have inner ReorderableListView per batch section
- [FIX] Drag handle removed from batched → re-enabled: cards within batches are now individually draggable
- [CHANGE] TONNAGE/eORM moved inside _exp block (only visible when set expanded)
- [CHANGE] RPE/RIR/TECH moved inside _exp block (hidden when collapsed), unified into single bordered group with full-height vertical dividers
- [CHANGE] WORKOUT OPTS moved from bottom of C.WO to directly below header metrics
- [POLISH] AnimatedSize on set row expand/collapse
- [POLISH] Stronger RED_PR glow, brighter expanded border, subtle expand shadow
- [POLISH] Set number checkbox heading height reduced from 24→20 to match LOAD/REPS headings
- [CHANGE] COMPLEX_METRICS heading label removed from RPE/RIR/TECH group
- [FIX] TECH field has no default value (null starts empty, like RPE/RIR)

#### v0.1.1 — 2026-05-31
- [FIX] THEME.MDFYR null crash (PNDEV 43): wo_priority + wo_batch keys missing from _searchControllers and _expandedSections maps
- [NEW] allBatchNamesProvider: dynamic batch name discovery from complex_metadata['batch'] across all workout sets
- [NEW] Batch colors now editable in THEME.MDFYR via UI_TAG_BATCH_$name keys
- [NEW] Category section dividers in THEME.MDFYR (C.WO, Global/Structural, Data & Biomechanics, Movement Library)
- [NEW] Item counters on all 16 THEME.MDFYR section headers
- [POLISH] Visual overhaul: left-accent headers, HEX value tags on color swatches, rounded color picker swatches, improved search fields, consistent padding
- [POLISH] Better empty state messaging for batch sections

#### v0.1.0-dev — 2026-05-30
- First tracked version. Starting point for all future releases.
- Somatic: anomaly/recovery split in exports (PDF + MD)
- C.WO: independent anomaly/recovery boxes per set card
- C.WO: overlay filters by anomaly vs recovery mode
- C.WO: session header with SETS / PRs / UTIL chips (theme-colored frames)
- C.WO: WORKOUT OPTS moved below SESSION_GENERAL_NOTES
- C.WO: manual batch system (ASSIGN BATCH via complex_metadata)
- C.WO: collapsible batch sections with drag-to-reorder
- C.WO: batch headers colored via theme (UI_TAG_BATCH_$name)
- THEME.MDFYR: C.WO_PRIORITY_UTILS + C.WO_BATCH_COLORS sections
- Export: Unicode font for PDF emoji, double extension bugfix
- Known: THEME.MDFYR null check operator crash (PNDEV 43)

#### v0.1.3-bugfix1 — 2026-06-06
- [FIX] [UTIL] button not responding: GestureDetector was nested inside InkWell, causing gesture conflict. Extracted UTIL row outside InkWell.
- [FIX] _showUtilityEditDialog crash: removed reference to non-existent blueprint_exercises table.
- [FIX] _propagatePriorityChange crash: removed blueprintExercises update.

#### v0.1.31-bridge — 2026-06-06
- [NEW] WO.Blocks.manager.dart: create/list/delete/sort Workout Blocks
- [NEW] WO.BLCKS hub button replaced SESSION.BP
- [NEW] c.wo_husk.dart: pixel-exact C.WO copy with mock data
- [CHANGE] blueprint_manager.dart now routes to WO.Blocks.manager
- [NEXT] WB Editor: strip C.WO features, add WB metadata, wire DB schema

#### v0.1.33 — 2026-06-06
- [CHANGE] c.wo_husk.dart → WB.editor.dart
- [NEW] WbMockNotifier: mutable mock data (add/remove KNS in WB Editor)
- [FIX] _addExerciseToDate now adds to wbMockProvider instead of real DB
- [CHANGE] workoutSetsProvider reads from wbMockProvider
- [FIX] buildDefaultDragHandles=false for expand/collapse + complex mods


#### v0.1.35 — 2026-06-06
- [FIX] WB persistence: replaced SharedPreferences with SQLite (wb_store table via Drift)
- [FIX] SharedPreferences channel error on hot restart — Drift FFI works reliably
- [FIX] WB list loads via _initTable() in constructor (async table creation + load)
- [CHANGE] Removed shared_preferences dependency


#### v0.1.36 — 2026-06-06
- [NEW] WB.editor.dart replaces c.wo_husk.dart
- [FIX] GestureDetector replaces InkWell — expand/collapse + complex mods work
- [FIX] ADD SET writes to mock, not real DB — works in WB Editor
- [FIX] No horizontal swipe (PageView → single page)
- [FIX] Provider ref fix: DB passed directly to constructor
- [CHANGE] Set row: MIN REPS | P.LOAD | MAX REPS (no LOAD)
- [REMOVED] PR, somatic, failure phase, TECH, 3-dot mods from WB Editor
- [NEXT] Metadata space, inject WB into C.WO, export/import


#### v0.1.37 — 2026-06-06
- [NEW] C.WO Injection Type: "Session Blueprint" → "Workout Block" with WB picker
- [NEW] _injectWorkoutBlock: reads WB from wb_store/wb_kns_store, inserts into workout_sets
- [NEW] WORKOUT OPTS: "VIEW WB PROJECTIONS" button with organized KNS display
- [NEW] WB metadata: BLOCK DESCRIPTION field + WB META button
- [NEW] KNS metadata: KNS PURPOSE field per exercise card
- [NEW] Set metadata: SET TAGS chip selector (TOP_SET, BACKOFF, etc.) + SET META button
- [CHANGE] SESSION_GENERAL_NOTES → WB.NOTES


#### v0.1.38 — 2026-06-06
- [FIX] Value persistence: set IDs now match between WorkoutSet and WbEditorSet (updateSet finds correct set)
- [FIX] MIN REPS → technique field, P.LOAD → weight, MAX REPS → reps, SET TAGS → notes
- [FIX] didUpdateWidget updates controllers with loaded values + restores tags from notes
- [FIX] reload() forces _load() + knsVersionProvider++ to trigger UI refresh
- [FIX] knsId looked up from notifier by baseExerciseId (not derived from WorkoutSet ID)
- [CHANGE] SAVE WB button in AppBar persists KNS + sets to wb_kns_store
- [NEXT] Nexus export/import WBs, OVARCH.PLN overhaul, WORKOUT OPTS wiring

#### v0.1.32 — 2026-06-06
- [FIX] buildDefaultDragHandles=false on all ReorderableListViews — expand/collapse + complex mods now work
- [FIX] KNS cards start expanded by default
- [CHANGE] Removed header title/date from WB Editor (only metrics ribbon remains)
- [NEW] WO.Blocks.manager: create/list/delete/sort WBs with folder grouping
- [NEW] Manager starts empty (no mock WBs)
- [CHANGE] c.wo_husk: mock data, accepts blockName for AppBar
- [NEXT] Wire real DB schema for workout_block_* tables
