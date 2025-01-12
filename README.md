# Post Fedora Script 41

Post Fedora Script 41 is a shell script designed to automate the installation of essential applications and tools on a fresh Fedora 41 installation. It streamlines the setup process, ensuring your system is ready for use with minimal effort.

## Features

- **Automated Installation**: Installs a list of applications and tools commonly used on Fedora systems.
- **Flathub Integration**: Includes a script to add the Flathub repository, expanding the range of available applications.
- **Manual Instructions**: Provides a manual with additional setup instructions and tips.

## Prerequisites

Before running the script, ensure you have:

- A fresh installation of Fedora 41.
- An active internet connection.
- Sudo privileges.

## Installation

1. **Clone the Repository**:
```bash
   git clone https://github.com/darrenoshan/pfs41.git
```

2. **Navigate to the Directory**:

```bash
    cd pfs41
    sudo bash ./run.main.sh
```

## Suggestions

Suggested command for Graphical Workstations with minimal useful apps

```bash
    sudo bash ./run.main.sh -u <YOUR USER> -ighdma
```

Suggested command switchs for Graphical Workstations with extra apps

```bash
    sudo bash ./run.main.sh -u <YOUR USER> -ighdmax
```

Suggested command switchs for text based server installation with minimal useful apps

```bash
    sudo bash ./run.main.sh -u <YOUR USER> -ihda
```

