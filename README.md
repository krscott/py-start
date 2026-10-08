# py-start

My rather opinionated Python project template.

To start a project with this template, run:
```
./init-template.sh new_project_name
```

With a Git identity configured, the script commits the template changes, runs
`nix flake update`, and commits any changes to `flake.lock` separately. Nix must
be available for this step.

See README_TEMPLATE.md
