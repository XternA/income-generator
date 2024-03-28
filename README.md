 # Income Generator

**[ Docker Stack | Containerized | Passive Income | Auto Update ]**

If you like this project, don't forget to leave a star. ⭐

---
***NOTE:** "This tool has always been developed for my own personal use in mind, therefore the focus has always been Linux first as I run them on my home and cloud servers before making it available to the general public."*

## Overview 🚀📑
**Income Generator** is an all-in-one tool that consolidates a variety of supported applications, enabling users to generate passive income by leveraging everyday devices and unused internet bandwidth.

By seamlessly integrating these applications, simplifying the entire process, making it more efficient and accessible with applications auto-updating.

## Getting Started 🚥
### Prerequisite 📦
**Everything the tool configures to run will be under a containerised virtualised environment isolated from the host.**

- The tool works best on a 64-bit machine, though it is still possible to run it under a 32-bit operating system (OS), but will will definitely come with certain performance limitations, specifically with lower memory availability.
- A minimum of 4GB would be best recommended to ensure the most resource available and for future expansions.
- The stack requires **Docker** and **Compose** in order to operate as everything is ran in a containerised environment and easily managed.
- For ARM architecture devices, such as Raspberry Pi, Apple Silicon etc, will be required to install an emulation layer such as **[qemu-user-static (qus)](https://github.com/dbhi/qus)** to run x86 architecture on ARM. This can be easily enabled via the Docker container.

### Quick Start Guide ⚙️
Assuming **Docker** and **Compose** is already pre-installed (Can also be installed from the tool):

:warning: *Newer versions of Docker integrates Compose directly. Accessed as `docker compose` instead of `docker-compose`.*

**1.** Open the terminal and clone the project.
```sh
git clone --depth=1 https://github.com/XternA/income-generator.git ~/.income-generator
```
**2.** Add to path then source the shell file for global access.
```sh
# To find out which shell the terminal is using
echo $SHELL

# If shell is bash
echo "alias igm='(cd $HOME/workspace/income-generator; sh start.sh)'" >> ~/.bashrc
source ~/.bashrc

# If shell is zsh
echo "alias igm='(cd $HOME/workspace/income-generator; sh start.sh)'" >> ~/.zshrc
source ~/.zshrc
```
**3.** Register an account for each application in the **[applications table](#app-compatibility-)**.
**4.** Run the tool via alias or within folder.
```sh
# Just type anywhere in the shell
igm

# If prefer to run from tool folder
cd income-generator
sh start.sh
```
**5.** Follow the setup configuration which will have comments regarding tips for configuration.
```
1. Install & Run Applications
2. Setup Configuration
3. Start Applications
4. Stop Applications
...
Select an option (1-9):
```
**6.** Select choice 1 to install, then pick accordingly to install based on what IP address the device is connected as.
```
1. Only applications with VPS/Hosting support
2. All applications including residential IPs only support
3. All applications including residential IPs only support, excluding single instances only
4. Applications with unlimited counts

Select an option (1-4):
```
**6.** Start earning passively. 💸

## App Compatibility 📋
Using the table below, each app can be identified its total install count per IP type. This indicates which stack option to run in the **'Install & Run Applications'** option of the tool.

Each app has been grouped in the install option. Therefore, whether it be residential or hosting already installed in the same network, you can install on another device within the same network using the selective choice. The tool will install all the apps that meet the conditions below.

- 📋 Register via the links below will entitle you to receive a bonus added to your account on registration. Additionally, it ensures you're registering at the correct site and showing your support for my work.
- 🔐 If using social logins such as Google, be sure to set a password to the account as it will be required for authentication to the app later.

| Services | Residential / Mobile IP | VPS / Hosting IP | Max Devices Per Account | Max Devices Per IP |
| --- | :---: | :---: | :---: | :---: |
| **[EARNAPP](https://bit.ly/4a4XJLF)**         | :white_check_mark:  | :x:                 |15|1|
| **[HONEYGAIN](https://bit.ly/3x6nX1S)**       | :white_check_mark:  | :x:                 |10|1|
| **[PEER2PROFIT](https://bit.ly/3x7CquB)**     | :white_check_mark:  | :white_check_mark:	 |Unlimited|Unlimited|
| **[TRAFFMONETIZER](https://bit.ly/3TKmJlU)**  | :white_check_mark:  | :white_check_mark:  |Unlimited|Unlimited|
| **[PAWNS](https://bit.ly/498zRFV)**           | :white_check_mark:  | :x:                 |Unlimited|1|
| **[REPOCKET](https://bit.ly/3TNO6LY)**        | :white_check_mark:  | :white_check_mark:  |Unlimited|2|
| **[PACKETSTREAM](https://bit.ly/4ajvcSg)**    | :white_check_mark:  | :x:                 |Unlimited|1|
| **[PROXYRACK](https://bit.ly/497RsOj)**       | :white_check_mark:  | :white_check_mark:  |500|1|
| **[PROXYLITE](https://bit.ly/4a3CjPe)**       | :white_check_mark:  | :white_check_mark:  |Unlimited|1|
| **[EARNFM](https://bit.ly/3Vzenip)**          | :white_check_mark:  | :x:                 |Unlimited|1|
| **[SPIDE](https://bit.ly/3VpoiXH)**           | :white_check_mark:  | :x:                 |10|1|
| **[SPEEDSHARE](https://bit.ly/4cstfEZ)**      | :white_check_mark:  | :x:                 |Unlimited|1|
| **[GRASS](https://bit.ly/495PPAn)**           | :white_check_mark:  | :x:                 |Unlimited|1|
| **[MYSTNODE](https://bit.ly/4cl0YAt)**        | :white_check_mark:  | :white_check_mark:  |Unlimited|Unlimited|
| **[BITPING](https://bit.ly/43xHKDt)**         | :white_check_mark:  | :white_check_mark:  |Unlimited|1|

## Tested Environments ✅
The docker stack should work on anything that may have docker installed. In particular, it has been tested on:

| Windows WSL2 (x86_64 / amd64) | Linux Ubuntu (x86_64 / amd64) | Raspbian OS (arm32/64) | MacOS Intel (x86_64) | MacOS Apple Silicon (arm64) |
| :---: | :---: | :---: | :---: | :---: |
| :red_circle: | :green_circle: | :green_circle: | :yellow_circle: | :yellow_circle: |
| Desktop / Laptop | Desktop / Laptop | Raspberry Pi 3/4 | MacBook Pro | MacBook Pro |

:green_circle: - Everything supported, tested and working, including stack orchestration.

:yellow_circle: - Almost everything supported, with only minor things which may not be fully supported.

:orange_circle: - Orchestrating applications and docker stack should work, but not everything is intended for full support.

:red_circle: - No current intended support.

Note that working means within the tool when you run and interact with it.

## Like The Project? 🫶

Your efforts and interest is well appreciated if you would like to contribute and improve the tool or compatibility and enabling it widely available and easy to use.

Even if you do not wish to contribute, you can still show your support by giving this project a star⭐.

### Donations 💸
Donations are warmly welcomed, no matter the amount, your support is gratefully appreciated. Additionally, it helps fuel future developments. Thank you. 🙏🏻

- **Bitcoin (BTC)** - bc1qq993w3mxsf5aph5c362wjv3zaegk37tcvw7rl4
- **Ethereum (ETH)** - 0x2601B9940F9594810DEDC44015491f0f9D6Dd1cA
- **Binance (BNB)** - bnb1dj3l3fp24z05vtwtjpaatjyz9sll4elu9lkjww
- **Binance Smart Chain (BSC)** - 0x2601B9940F9594810DEDC44015491f0f9D6Dd1cA
- **Solana (SOL)** - Ap5aiAbnsLtR2XVJB3sp37qdNP5VfqydAgUThvdEiL5i
- **PayPal** - [@xterna](https://paypal.me/xterna)

---
### :warning: Disclaimer
Prior to using the applications provided in this stack, it is essential to verify that your actions comply with the laws of your jurisdiction and adhere to the terms outlined in your internet service provider's contract. The integration of these applications within this stack is purely for user convenience and does not signify an endorsement of their utilization.

The author of this stack does not accept any responsibility for the outcomes resulting from the utilization of these applications. While this stack streamlines the configuration process and facilitates automated updates for the included applications, it is distributed on an "as is" basis without any warranties.

The author does not provide any assurances, whether explicit or implicit, regarding the accuracy, completeness, or appropriateness of this script for specific purposes. The author shall not be held accountable for any damages, including but not limited to direct, indirect, incidental, consequential, or special damages, arising from the use or inability to use this tool or its accompanying documentation, even if the possibility of such damages has been communicated.

By choosing to utilize this tool, you acknowledge and assume all risks associated with its use. Additionally, you agree that the author cannot be held liable for any issues or consequences that may arise as a result of its usage.
