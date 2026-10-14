## Plan Mode
- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Testing

- Always propose tests for new code and bug fixes.
- Prefer fast, deterministic tests; minimize mocking and sociable tests.
- Call out edge cases and failure modes.

## Where things live on this machine

- `~/dev/p11y/` — Purpose in Play repos. `~/dev/p6l/` — personal.
  Each repo is a bare clone plus worktrees: `<repo>/.bare`, `<repo>/main`,
  `<repo>/wt-<task>`. One worktree per agent — never two agents in one.
- `~/data/` — durable non-git output: exports, datasets, reference files.
- `~/scratch/` — disposable. Temp files, experiments, anything you'd not
  miss. Put scratch output **here**, never beside the file you're editing.

Never write generated files into a worktree unless they're meant to be
committed. After installing a CLI outside mise (`npm i -g`), run `mise reshim`
or it won't resolve.
