# Candidate package

`create-skill.ps1` writes this shape and nothing else:

```text
plugins/<plugin>/skills/<skill>/
  SKILL.md
  agents/<agent>.md
  scripts/validate.ps1
  references/package.md
  assets/request.json
  tests/fixture.json
```

The script does not edit `marketplace.json`, `dotagents.manifest.json`, or `.agents/catalog.json`. A candidate is not runnable through the catalog until a later, separate registration.
