# Dev Container

This directory contains the devcontainer.json, Docker configuration, and utility scripts for building, running, and publishing the development container image for this project.

## Folder Structure

```
<root>
└── .devcontainer/
    ├── docker/
    │   ├── Dockerfile          # Multi-stage Dockerfile for building the development container
    │   ├── README.md
    │   └── bin/                # Shell scripts for container lifecycle management
    ├── devcontainer.json       # VS Code Dev Container configuration
    └── README.md               # This file
```

## Dev Container Configuration

The [devcontainer.json](devcontainer.json) file configures VS Code's development container environment. Key aspects:

### Build Configuration

```jsonc
"build": {
  "dockerfile": "./docker/Dockerfile",
  "target": "devcontainer",
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
- **target**: Multi-stage build target to use (see Dockerfile section below)
- **context**: Docker build context (parent directory to access workspace files)
- **args**: Build arguments passed to Docker (see Dockerfile Build Arguments section)

### Workspace Configuration

```jsonc
{
	"remoteUser": "vscode",
	"workspaceFolder": "/home/<remoteUser>/workspace",
	"workspaceMount": "source=${localWorkspaceFolder},target=/home/vscode/workspace,type=bind,consistency=cached"
}
```

- **remoteUser**: `vscode` - Non-root user for development (matches USERNAME build arg)
- **workspaceFolder**: `/home/<remoteUser>/workspace` - Container path where workspace is mounted
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

The [Dockerfile](docker/Dockerfile) uses a multi-stage build several targets.

The targets relevant to the _Dev Container_ are **`base`** and **`devcontainer`**:

1. **base** - Minimal Debian-based image with essential packages (build tools, git, sudo, etc.)
1. **devcontainer** - Extends base with a non-root user, Homebrew, and development tools

### Build Arguments

The Dockerfile accepts several build arguments that can be customized:

| Argument     | Default        | Target | Description                            |
| ------------ | -------------- | ------ | -------------------------------------- |
| `IMAGE_NAME` | `ubuntu`       | base   | Base image name (must be Debian-based) |
| `VARIANT`    | `latest`       | base   | Base image tag/version                 |
| `USERNAME`   | `devcontainer` | base   | Non-root user name to create           |
| `USER_UID`   | `1000`         | base   | User ID for the non-root user          |
| `USER_GID`   | `$USER_UID`    | base   | Group ID for the non-root user         |

> [!NOTE]
> As of Ubuntu 24+, a non-root `ubuntu` user exists. The Dockerfile automatically removes the default `ubuntu` user (UID 1000) to avoid conflicts when creating a custom user.
>
> See the [official docs](https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user) for more details on non-root users.
