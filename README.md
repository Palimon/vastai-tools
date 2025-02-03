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

### GPU & Linkage Stress Test

1. Install the Screen app:

    ```bash
    sudo apt update
    sudo apt install screen
    ```

2. Install wilicc's gpu-burn program:

    ```bash
    git clone https://github.com/wilicc/gpu-burn
    cd gpu-burn
    docker build -t gpu_burn .
    ```

3. Create the shell script:

    ```bash
    nano gputest.sh
    ```
    ```bash
    #!/bin/bash
    screen -S burn

    for i in {1..500}; do
        echo "Running GPU stress test iteration $i"
        docker run --rm --gpus all gpu_burn
        sleep 60  # wait for 1 minute to cool down
    done
    echo "____________________"
    echo "_____          _____"
    echo "_____  SUCCESS _____"
    echo "____________________"
    ```
    Save and close (ctrl+s, ctrl+x)
    ```bash
    chmod +x gputest.sh
    ```

4. Enter screen and run burn test:

    ```bash
    screen -r burn
    ```
    ```bash
    ./gputest.sh
    ```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE Version 3 License. See the [LICENSE](LICENSE) file for details.