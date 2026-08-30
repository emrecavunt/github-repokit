# evals/

Eval suites for every plugin skill, keyed by skill name. They live here —
not inside `plugins/` — so plugin installs ship only the procedure.

```text
evals/
  <skill>/
    evals.json          # output cases: skill_name, evals[{id, prompt, expected_output, files, assertions}]
    eval_queries.json   # description-trigger queries: [{query, should_trigger}]
    files/…             # synthetic fixtures (placeholders only)
  workspaces/           # gitignored — with/without-skill runs
```

`make plugin-check` schema-checks the suites. It does not run a model.

To evaluate output quality, run each case **with** the skill and
**without** it in a clean context. See
[Evaluating skill output quality](https://agentskills.io/skill-creation/evaluating-skills)
and [Optimizing descriptions](https://agentskills.io/skill-creation/optimizing-descriptions).
