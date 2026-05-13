---
name: unity-cli-reference
description: >
  Reference for the unity-cli tool (v0.3.x) — Unity Editor control from the
  command line. Auto-triggers when the user discusses unity-cli, asks how
  to drive the Unity Editor from a terminal, needs to refresh/compile,
  read console errors, execute C# in the editor, run Test Runner, capture
  screenshots, or call custom IPC tools registered in a Unity project.
  Korean triggers: "유니티 cli", "unity-cli", "에디터 컴파일", "콘솔 확인",
  "C# 실행", "유니티 테스트 러너", "유니티 스크린샷", "커스텀 툴 호출"
  English triggers: "unity-cli", "unity editor cli", "compile unity",
  "read unity console", "execute C# in editor", "unity test runner"
---

# unity-cli Reference

This skill describes the unity-cli command surface and standard patterns
for driving a Unity Editor from the command line. It assumes:

- The Unity Editor is open with the unity-cli Connector package installed.
- A single Unity instance — when multiple are open, pass `--project <path>`
  or `--port <N>` to select.

The set of **custom tools** registered in a given Unity project varies.
Run `unity-cli list` against a live project to see what is available there.

## Basic invocation

```bash
unity-cli <command> [options] [--project <path>]
```

- Single instance: `--project` is optional.
- Multiple instances: select with `--project <path>` (forward slashes,
  case must match the path Unity registered — typically uppercase drive
  letter on Windows) or `--port <N>`.

## Command surface

| Command | Key options | Purpose |
|---|---|---|
| `editor play` | `--wait` | Enter play mode |
| `editor stop` | — | Exit play mode |
| `editor pause` | — | Toggle pause (play mode only) |
| `editor refresh` | `--compile`, `--force` | Refresh AssetDatabase; recompile scripts |
| `console` | `--type error,warning,log`, `--lines N`, `--stacktrace none/user/full`, `--clear` | Read or clear console |
| `exec "<code>"` (or stdin pipe) | `--usings ns1,ns2`, `--csc`, `--dotnet` | Execute C# in the editor — `return` required for output |
| `menu "<path>"` | — | Execute a menu item (File/Quit is blocked) |
| `screenshot` | `--view scene/game`, `--width`, `--height`, `--output_path` | Capture editor view |
| `reserialize [path...]` | — | Re-serialize assets after text edits to .prefab/.unity/.asset |
| `test` | `--mode EditMode/PlayMode`, `--filter`, `--allow-dirty-scenes`, `--auto-save-scenes` | Unity Test Runner |
| `profiler hierarchy` | `--depth`, `--root`, `--frames`, `--min`, `--sort`, `--max`, `--parent`, `--thread` | Profiler hierarchy |
| `profiler enable/disable/status/clear` | — | Profiler state control |
| `list` | — | List custom tools registered in the active project + their parameter schemas |
| `status` | — | Editor heartbeat — port, project path, Unity version, PID |
| `update [--check]` | — | Self-update the CLI |
| `<tool_name>` | `--params '{"k":"v"}'` | Call a custom tool |

## C# `exec` patterns

- **Single line**: `echo 'return Application.dataPath;' | unity-cli exec`
- **Multi-line**: write to a temp `.cs` file, pipe with `Get-Content -Raw`
  (PowerShell) or `cat` (POSIX). Avoid here-strings piped directly — they
  introduce escaping/parse errors that are easy to misread as Unity
  compile errors.
- **Void / editor side-effect only**: return `null;` explicitly.
- **Extra namespaces**: `--usings Unity.Entities,Custom.Ns`.
- **Default usings**: `System`, `System.Collections.Generic`, `System.IO`,
  `System.Linq`, `System.Reflection`, `System.Threading.Tasks`,
  `UnityEngine`, `UnityEngine.SceneManagement`, `UnityEditor`,
  `UnityEditor.SceneManagement`, `UnityEditorInternal`.

## Standard verification after code edits

```bash
unity-cli editor refresh --compile
unity-cli console --type error
```

`refresh --compile` blocks until script compilation finishes, then
`console --type error` surfaces any new errors. Run as a pair.

## Custom tool calls

```bash
unity-cli <tool_name> --params '{"key":"value","other":42}'
```

- Parameters are JSON. Optional ones can be omitted.
- `unity-cli list` returns the full schema (name, description, parameters,
  required flags) for every tool a project exposes.
- Common categories you may see when running `list` against a project:
  - **Analyzers** — read-only introspection of assemblies, addressables,
    asset dependencies, ScriptableObject fields, prefab structure, scene
    instances, banned API patterns, code coverage.
  - **Manage** — `manage_gameobject`, `manage_component`, `manage_prefab`,
    `manage_editor` — direct mutation actions (create/delete/modify/find).
  - **Find** — `find_assets`, `find_scene_objects` — queries that beat
    raw `AssetDatabase.FindAssets` round-trips.
  - **Diff / Multi-screenshot / Reserialize / Refresh / Run tests** —
    higher-level wrappers over editor APIs.
  - **Project-specific builders** — domain tools the project team has
    added (e.g., prefab-variant builders). These vary per project.

Prefer custom tools over raw `exec` whenever a matching tool exists.
They are structured, validated, and stable across Unity API churn.

## Working pattern for spec → Unity application

1. **Locate** — `find_assets` (by filter / folder / label) or
   `find_scene_objects` (by name / component / tag).
2. **Inspect** — `analyzer_so_fields` for ScriptableObject layout,
   `analyzer_prefab_structure` for prefab hierarchy and serialized values.
3. **Mutate** —
   - SO data: `exec` with `SerializedObject` + `SerializedProperty` + save.
   - Components: `manage_component`.
   - GameObjects: `manage_gameobject`.
   - Prefabs: `manage_prefab` (or `prefab_convert_variant` /
     `prefab_variant_base_switch` if available).
4. **Verify** — `diff_prefab` for structural comparison;
   `editor refresh --compile` then `console --type error`.
5. **Test** — `test --mode EditMode --filter <ns.cls>` for affected suites.

## Pitfalls

- PowerShell here-strings piped directly to `exec` are fragile. Use
  temp `.cs` files for anything longer than one line.
- `editor refresh` is blocked in play mode unless `--force` is set.
- A `--project` path that does not exactly match the path Unity
  registered (case sensitive on Windows for the drive letter) will
  return "no Unity instance found".
- Custom tool schemas can change between project snapshots. Re-run
  `unity-cli list` instead of relying on cached parameter sets.

## What this skill does NOT do

- Document every parameter of every project-specific custom tool —
  schemas live in `unity-cli list` and may change without notice.
- Replace Unity's official Test Framework / Profiler / Editor docs.
- Replace project-level guidance (AGENTS.md / CLAUDE.md in the Unity
  project root).

## References

- `unity-cli --help` and `unity-cli <command> --help` — authoritative
  per-command flag list.
- `unity-cli list` — authoritative live custom tool schema for the
  currently connected project.
