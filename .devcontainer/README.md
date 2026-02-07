# Dev Container

This directory contains the devcontainer.json, Docker configuration, and utility
scripts for building, running, and publishing the development container image
for this project.

## Folder Structure

```none
<root>
└── .devcontainer/
    ├── docker/
    │   ├── Dockerfile          # Multi-stage Dockerfile
    │   ├── README.md
    │   ├── bin/                # Shell scripts for container lifecycle management
    │   ├── helpers/            # Helper "scripts" with useful functions;
    │   │                         meant to be sourced from other scripts
    │   ├── lib-scripts/        # Container installer scripts
    │   ├── scripts/            # Container user scripts
    │   └── utils/              # Container utility scripts
    ├── devcontainer.json       # VS Code Dev Container configuration
    └── README.md               # This file
```

## Dev Container Configuration

The [devcontainer.json](devcontainer.json) file configures VS Code's
development container environment. Key aspects:

### Build Configuration

```jsonc
"build": {
  "dockerfile": "./docker/Dockerfile",
  "target": "devtools",
  "context": "..",
  "args": {
    "USERNAME": "vscode",
    // Default values, here for reference
    // "USER_UID": "1000",
    // "USER_GID": "1000"
  }
}
```

- **dockerfile**: Path to the Dockerfile relative to `.devcontainer/`
- **target**: Multi-stage build target to use (common: `base`, `devtools`, `cloudtools`)
- **context**: Docker build context (parent directory to access workspace files)
- **args**: Build arguments passed to Docker (see [docker/README.md](./docker/README.md) for full list)

### Workspace Configuration

```jsonc
{
 "remoteUser": "vscode",
 "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
 "workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind,consistency=cached"
}
```

- **remoteUser**: `vscode` - Non-root user for development (matches USERNAME build arg)
- **workspaceFolder**: `/workspaces/${localWorkspaceFolderBasename}` - Container path where workspace is mounted
  (default workspace directory)
- **workspaceMount**: Bind mount configuration with cached consistency for performance

### SSH Keys

Local ssh keys will be mounted, to allow seamless integration with remote servers. Comment out if this behavior is undesired.

```jsonc
{
 "mounts": ["source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached"]
}
```

### Additional Features

The configuration installs development tools via [devcontainers features](https://containers.dev/features):

- **Languages**: Node.js (LTS), Python 3.x (default: latest; configurable), Terraform 1.4.5 (configurable)
- **Linters/Formatters**: Prettier, Pylint, Black, isort
- **Tools**: Docker-in-Docker (needs to be enabled/uncommented), GitHub CLI, AWS CLI
- **Extensions**: Python, Terraform, Markdown, YAML, ESLint, and more

## Docker

> [!NOTE]
> See the [docker/README.md](./docker/README.md) for a complete reference.

The [Dockerfile](docker/Dockerfile) uses a multi-stage approach to build several targets.

The primary targets for development containers are:

1. **base** - Foundation development environment with essential tools and configuration
2. **devtools** - Full-featured environment with Python, Node.js, and development tools
3. **cloudtools** - Environment with AWS CLI, Terraform, and cloud infrastructure tools
4. **codeserver** - Web-based VS Code instance with development tools
5. **production** - Minimal production-ready container

Most users will use the **base** or **devtools** target for VS Code Dev Containers.

## CLI Tool

For command line integration, install [the dev container cli](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli#_the-dev-container-cli).

See the [official repo](https://github.com/devcontainers/cli) for a complete reference.

### Install

#### npm

```bash
npm install -g @devcontainers/cli

# Or install locally to workspace (i.e. not global):
# npm install @devcontainers/cli
```

#### Homebrew

> [!NOTE]
> No option for local workspace install

```bash
brew install devcontainer
```

### Usage

```bash
devcontainer up --workspace-folder .
```

See the [official repo](https://github.com/devcontainers/cli) for a complete reference.
