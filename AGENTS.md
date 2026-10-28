# PROCESS — every work unit

Use the project's existing scripts for SETUP and FINISH. If either is
missing, build and test a reusable script for it. Record the commands
in the project's root AGENTS.md. Run those scripts for this work unit
and every future one. Fix the scripts when needed; don't substitute
manual steps.

1. SETUP — make sure the project's `main` checkout is clean, then pull
   the latest `main`. Run the project's setup script. It creates an isolated
   branch and worktree, prepares the project, and returns the worktree
   path. Work only in the returned worktree.

2. WORK — commit each meaningful unit. No vestige (git has it → delete it):
   no `.bak`/`.orig`/`~`/`old-`/`new-`/`-v2`/`_final`/`_copy`…; no dead
   code (commented-out, orphaned, parallel old+new, `if(false)`/disabled);
   no `deprecated`/`legacy` tags instead of deleting; no stale/strikethrough
   doc text. Plow ahead.

3. FINISH — from the clean worktree run the project's landing script.
   It rebases, installs, runs the project's full validation and test
   suite, race-safely pushes `main`, synchronizes canonical `main` and
   any submodules to that exact commit, runs the project's deployment
   if applicable, verifies it, and cleans up. If `main` advances,
   rebase and validate again before retrying. Fix and rerun on failure.
