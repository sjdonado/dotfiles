## Purpose

One terminal editor covers reading code, viewing diffs, and running git workflows, provisioned identically on every machine from configuration tracked in this repository.

## ADDED Requirements

### Requirement: One editor provisioned from tracked config

Provisioning SHALL install the editor and link this repository's editor configuration so a fresh machine presents the same keybindings, theme, and settings without manual setup. Where a platform has no package for the editor, provisioning SHALL report that in one line and continue rather than abort.

#### Scenario: Fresh machine

- **WHEN** the macOS or Linux provisioning script runs on a machine without the editor
- **THEN** the editor is installed where a package exists, its config directory is linked to this repository's tracked copy, and a missing package is reported without failing the run

#### Scenario: Config is tracked, not hand-made

- **WHEN** the editor's settings, keybindings, or theme are changed
- **THEN** the change lives in this repository and reaches every machine through provisioning, with no per-machine editing

### Requirement: Git review without a second tool

The editor SHALL be the single place for reading a diff, staging, committing, and reviewing a pull request. Provisioning SHALL NOT install a separate terminal git UI.

#### Scenario: Pre-PR review

- **WHEN** the human reviews changes before opening a pull request
- **THEN** the diff, staging, and commit happen in the editor, and no separate git TUI is installed or configured

### Requirement: Usable by touch

The editor SHALL be operable by mouse and touch, so a phone or tablet terminal is a usable surface for reading and small edits.

#### Scenario: Reading on a tablet

- **WHEN** the human opens the editor from a tablet or phone terminal
- **THEN** positioning the cursor, switching files, and viewing a diff are reachable by pointer without modal key chords

#### Scenario: Right-click inside the editor

- **WHEN** the editor runs inside the terminal workspace manager and the human right-clicks in it
- **THEN** the click reaches the editor's own context menu rather than the workspace manager's pane menu, and this holds for every editor pane without a per-pane setting being chosen by hand

### Requirement: No orphaned host surfaces

When a tool is removed, the terminal-workspace surfaces that existed only to host it SHALL be removed with it, including their keybindings. A surface that still serves a remaining tool SHALL be kept.

#### Scenario: Editor and git UI removed

- **WHEN** the previous editor and git UI are no longer provisioned
- **THEN** the workspace plugins and keybindings that only launched them are gone, and any surface still serving a remaining tool is retained with its reason recorded
