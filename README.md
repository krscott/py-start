# py-start

My rather opinionated Python project template.

To start a project with this template, run:
```
./init-template.sh new_project_name
```

With a Git identity configured, the script commits the template changes. If Nix
is in `PATH`, it also runs `nix flake update` and commits any changes to
`flake.lock` separately.

See README_TEMPLATE.md

## Nix command isolation

The command built by `nix build` runs Python in [isolated mode (`-I`)](https://docs.python.org/3/using/cmdline.html#cmdoption-I).
It uses the packaged dependencies and ignores inherited Python settings such as
`PYTHONPATH` and `PYTHONHOME`, user site-packages, and the script directory for
imports. Application environment variables such as `PYSTART_VERBOSE` and the
working directory's `.env` file still work. Python leaves the environment
variables available to application code and subprocesses.

Development shells, editable installs, and library imports use the active Python
environment as usual. If your project deliberately loads plugins through
`PYTHONPATH`, remove the `postInstall` block that adds `-I` in `default.nix` and
adapt `tests/test_nix_cli.py` to your plugin behavior. The packaged command will
then inherit the caller's Python import settings.

`nix flake check` tests the installed Nix executable with conflicting Python
settings. To run those tests directly after `nix build`:

```sh
nix develop -c env PYSTART_NIX_EXECUTABLE="$PWD/result/bin/pystart" python -m pytest tests/test_nix_cli.py
```
