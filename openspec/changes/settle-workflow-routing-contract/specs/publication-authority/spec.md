## Purpose

Defines what agreement authorizes an agent to publish on the user's behalf, meaning a commit, a push, a pull request, or a message to anyone other than the user, and which workflow holds that authority for how long.

## ADDED Requirements

### Requirement: Yolo entry requires settled agreement, not artifact presence

An agent SHALL enter `yolo` only when the session's purpose, whole scope, and acceptance evidence are settled and an identifiable source of user agreement covers that scope. A formal planning document SHALL remain optional. An agent-authored requirements ledger, a passing check run, or a finished diff SHALL NOT by itself establish that agreement. When part of the request is settled and part is not, the agent SHALL route the whole request to `proto` rather than promoting the unresolved part on the strength of the settled one.

#### Scenario: A settled subtask travels with an unresolved experiment

- **WHEN** the user asks for one branch containing a specified lifecycle fix plus an experiment whose backend decision is still open
- **THEN** the agent enters `proto`, names in one line which part is unsettled, and creates no branch and no pull request

#### Scenario: Green local checks are offered as readiness

- **WHEN** an agent has edited instruction files and the local ladder is green, but no user agreement covers a pull request for that scope
- **THEN** the agent does not offer or start a `yolo` run on the strength of the green checks, and states what agreement is missing

#### Scenario: The agent wrote the contract itself

- **WHEN** the only contract is a ledger, plan, or task list the agent authored during this session, with no user response accepting it
- **THEN** the agent treats the contract as unsettled and stays in `proto`

#### Scenario: A bounded request with no planning document

- **WHEN** the user asks for a specific, bounded change and asks for a pull request, without any OpenSpec change or written plan
- **THEN** the agent enters `yolo` and does not demand a planning document first

### Requirement: Yolo is the only scoped publication exception

An approved `yolo` run SHALL authorize, for its agreed scope and without further confirmation, creating the task branch, committing, pushing, opening the pull request, updating that pull request's title and body, and driving its required checks to green. The agent SHALL NOT stop the run to confirm the initial push or the pull request. That authorization SHALL NOT extend to any other external write, including creating or editing an issue, a tracker comment, a top-level pull request comment, or a review reply. The run SHALL never merge.

#### Scenario: Approved run reaches its first push

- **WHEN** an approved `yolo` run has a green local ladder and no pull request exists for the branch
- **THEN** the agent commits, pushes, and opens the pull request without asking, then drives the required remote checks

#### Scenario: The run wants to comment on a tracker issue

- **WHEN** the same approved run would post a progress comment on the linked issue
- **THEN** the agent asks for confirmation for that specific post, or omits it, and the run's branch authority is not treated as covering it

#### Scenario: The run finishes green

- **WHEN** every resolved oracle and the mergeability check are green
- **THEN** the agent removes the `WIP:` prefix, leaves the pull request open for human review, and does not merge

### Requirement: What does not authorize an external write

An agent SHALL NOT treat any of the following as authorization for an external write: a pull request the user approved earlier, default-branch hygiene or a rule against committing to the default branch, a workflow's own procedure, an unrelated open or blocked pull request, or a branch note recording a past approval. A specific authorization already given SHALL remain valid, and the agent SHALL NOT ask twice for the same authorized act.

#### Scenario: Precedent offered as authority

- **WHEN** an agent wants to open a fourth pull request and can cite three earlier approved pull requests, two unrelated blocked ones, and the default-branch rule
- **THEN** the agent opens no pull request and asks once for authorization for this one, stating what it would contain

#### Scenario: Note records an earlier approval

- **WHEN** the branch note says a previous batch was approved for publication
- **THEN** the agent treats that record as history, not as approval for the current batch

#### Scenario: Authorization already given for this act

- **WHEN** the user has already approved publishing the current batch to the existing pull request
- **THEN** the agent publishes it without asking again

### Requirement: Post-PR feedback iterates locally and publishes per batch

After a pull request is open, feedback work SHALL accumulate as local iterations on that same branch, validated by the local ladder, and SHALL NOT commit or push until the user approves publishing that batch. On approval the agent SHALL commit, push to the same branch, refresh that pull request's title and body from the pushed diff, and drive its required checks, without further confirmation for that batch. Approval of one batch SHALL NOT carry to the next.

#### Scenario: First feedback round on an open pull request

- **WHEN** the user gives a bullet list of changes for a branch whose pull request is open
- **THEN** the agent applies them, runs the local ladder, reports the result, and asks whether to publish this batch, having pushed nothing

#### Scenario: Several rounds before publication

- **WHEN** the user gives two further rounds of feedback before approving any publication
- **THEN** the agent accumulates all rounds locally on the same branch, with no intermediate push and no second pull request

#### Scenario: Batch approved

- **WHEN** the user approves publishing the accumulated batch
- **THEN** the agent commits, pushes to the same branch, updates the existing pull request's description to match the diff, and drives its required checks green without asking again for that batch

### Requirement: One line of work is one branch and one pull request

An agent SHALL keep one line of work on one branch with one pull request. Only `yolo` SHALL create or switch to a task branch. A request to start work on a branch separate from the default branch SHALL NOT by itself select `yolo` or authorize a pull request. A separate line of work SHALL be the user's explicit choice, and the agent SHALL NOT infer it from the shape of the request. Where ownership of the work is unclear, the agent SHALL ask once whether it belongs to the open pull request or to a separate line, and SHALL NOT edit or branch before the answer.

#### Scenario: Isolation requested without a pull request

- **WHEN** the user asks for the work to be kept off the default branch but the contract is still open
- **THEN** the agent stays in `proto`, holds the edits in the working tree, and creates no branch and no pull request

#### Scenario: Feedback changes the shape of the work

- **WHEN** later feedback expands the work beyond the plan the branch started from
- **THEN** the work stays on the same branch and pull request, and the agent opens no second pull request

#### Scenario: Ownership unclear

- **WHEN** a new request may belong either to the open pull request or to a new line of work
- **THEN** the agent asks once, with what each option would contain, and makes no edit or branch until answered
