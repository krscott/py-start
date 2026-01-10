# py-start

My rather opinionated Python project template.

To start a project with this template, run:
```
./init-template.sh new_project_name
```

Don't forget to [change](https://choosealicense.com/) the LICENSE.

## Development

Update dependencies
```
nix flake update
```

Requires CMake and a C11 compiler. A nix dev shell is available:
```
nix develop
```

