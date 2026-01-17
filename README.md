# py-start

My rather opinionated Python project template.

To start a project with this template, run:
```
./init-template.sh new_project_name
```

Don't forget to [change](https://choosealicense.com/) the LICENSE.

## Documentation Structure

This repository contains several documentation files for different audiences:

- **README.md** - User-facing project documentation for developers using or deploying this project
- [**AGENTS.md**](AGENTS.md) - Comprehensive development guidelines for AI agents, including code style, conventions, and workflows
- [**CLAUDE.md**](CLAUDE.md) - Entry point for Claude Code integration, just references AGENTS.md

## Development

Update dependencies
```
nix flake update
```

Start nix dev shell
```
nix develop
```

