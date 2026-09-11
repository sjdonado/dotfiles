## Purpose

Reading a markdown design document in the terminal with its tables intact and its images and mermaid diagrams displayed, because design work in this repository is markdown that carries diagrams.

## ADDED Requirements

### Requirement: Markdown renders with tables, images, and diagrams

A single command SHALL render a markdown file for reading, such that a wide table's cells wrap inside their own column, embedded images display, and each mermaid fence displays as a diagram rather than as source. A rendering dependency that is absent SHALL degrade to readable output rather than a broken document.

#### Scenario: A design document with a wide table and a diagram

- **WHEN** the human runs the reader on a markdown file containing a table whose cells exceed the window width and a mermaid fence
- **THEN** the table is boxed with each cell wrapped inside its column, and the mermaid fence appears as a rendered diagram

#### Scenario: Diagram renderer missing

- **WHEN** the mermaid renderer is not installed
- **THEN** the reader still produces a readable document and the fence's source is preserved rather than left as a broken image reference

### Requirement: Images reach the outer terminal

The reader SHALL run as a direct child of the terminal that displays it, never nested inside another terminal emulator, because a nested emulator consumes the graphics protocol and the images silently fail to display. Documentation SHALL state this constraint.

#### Scenario: Run in a terminal pane

- **WHEN** the reader is launched in a terminal pane
- **THEN** its images display

#### Scenario: Nested in another terminal emulator

- **WHEN** the reader is launched inside an editor's embedded terminal
- **THEN** images are expected to fail, and this is documented as a known constraint rather than treated as a defect to debug

### Requirement: Rendered images stay inside the terminal's display budget

Diagram rendering SHALL size its output by a decoded-size budget rather than a fixed scale multiplier, because the terminal's budget for a displayed image is far below what it accepts over the wire and shrinks as the window grows. Exceeding it displays nothing, with no error.

#### Scenario: A large diagram in a tall window

- **WHEN** a diagram is rendered for a large window
- **THEN** its decoded size stays within the budget and the diagram displays, rather than being transmitted successfully and silently not drawn

### Requirement: Re-reading a changed file

Re-running the reader on the same source SHALL overwrite the same rendered output, so an already-open reader can reload the same location rather than requiring a new invocation.

#### Scenario: Source edited while open

- **WHEN** the source markdown is edited and the reader is re-run
- **THEN** the rendered output is replaced in place at the same path
