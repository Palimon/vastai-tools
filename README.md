# vastai-tools

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
    - [Checking System Information](#checking-system-information)
    - [Monitoring GPU Usage](#monitoring-gpu-usage)
    - [Network Diagnostics](#network-diagnostics)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This repository contains various scripts and tools for troubleshooting AI servers running Ubuntu. These tools help in diagnosing system issues, monitoring hardware usage, and performing network diagnostics.

## Installation

To get started, clone the repository and navigate to the directory:

```bash
git clone https://github.com/yourusername/vastai-tools.git
cd vastai-tools
```

## Usage

### Checking System Information

Use the `system_info.sh` script to gather detailed information about the system:

```bash
./scripts/system_info.sh
```

### Monitoring GPU Usage

The `gpu_monitor.py` script helps in monitoring GPU usage:

```bash
python3 scripts/gpu_monitor.py
```

### Network Diagnostics

Run the `network_diagnostics.sh` script to perform network diagnostics:

```bash
./scripts/network_diagnostics.sh
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE Version 3. See the [LICENSE](LICENSE) file for details.