Mandatory reading: AGENTS.md, docs/input/project_plan.md (milestone definition),
tracking/_exit_record_template.md, tracking/problem_reports.md, the milestone's result/review cards.

1. Run the full regression (`make regress`) via vivado-runner; read only the summary.
2. Check: every requirement of the milestone has a passing test or an approved review/analysis;
   coverage meets the spec thresholds; every DERIVED-nnn is accepted or removed; open problem
   reports are closed or explicitly deferred.
3. Read code only for risky features (hard, or with many problem reports) - sample, do not read all.
4. Write tracking/<milestone>/exit_record.md from the template, including the frozen paths.
Recommend pass/fail to the user; the user approves and tags.
