<h1 align="center">
💻 Income Generator 💵
 </h1>

<h4 align="center">
[ Multi-Platform | OS Native | Containerized Stack | Passive Income | Auto Update | Multi-Proxy ]
</h4>

<div align="center">

[![GitHub Release Date](https://img.shields.io/github/release-date/XternA/income-generator?style=&label=Latest%20Release)](https://github.com/XternA/income-generator/releases)
[![Static Badge](https://img.shields.io/badge/License-purple?style=flat&logo=github)](https://github.com/XternA/income-generator?tab=License-1-ov-file)
[![GitHub Release](https://img.shields.io/github/v/release/XternA/income-generator?sort=date&display_name=release&style=flat&label=Version)](https://github.com/XternA/income-generator/releases/latest)
[![GitHub Repo stars](https://img.shields.io/github/stars/XternA/income-generator?style=flat&logo=github&label=Stars&color=orange)](https://github.com/XternA/income-generator)
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg?style=flat&logo=paypal)](https://www.paypal.com/donate/?hosted_button_id=32DCQ65QM5FNE)

If you like this project, don't forget to leave a star. ⭐
</div>

![image](https://github.com/XternA/income-generator/assets/9136075/22881e8c-c3f8-4c61-a927-cccc18bd0c7e)

**Income Generator** is an all-in-one feature-rich tool that allows generating passive income by leveraging income generating applications and unused internet bandwidth with minimal system resource.

Designed for minimal setup and native cross-platform support, utilizing containerized runtime isolation from the host, with full orchestration allowing fast deployment across multiple hosts.

📖 It's' strongly recommended to refer to the [**Wiki**](../../wiki) for in-depth details and instructions.

## Key Features ✨
- **Multi-platform** - Deploy across different OS.
- **Global Access** - Access the tool anywhere, just type `igm`.
- **Auto update** - Ensures applications always running up-to-date.
- **On-the-fly-update** - Tool can be updated on the fly whilst preserving config settings.
- **Local Config** - Config file is auto-generated and stored locally, including credentials.
- **Encryption** - Credential secrets are automatically encrypted/decrypted when in operation.
- **Resource Limit** - Easily apply resource limit based on system hardware dynamically.
- **Selective Apps** - Enable or disable the application of your choice to deploy and earn.
- **Quick Actions** -  CLI commands for common operations without launching the tool.
- **Auto Claim** - Auto claim daily rewards for supported applications with service apps.
- **Multi-Proxy** - Scale and deploy multiple proxy instances based on proxy entries automatically.

## Getting Started 🚥
### Prerequisite 📦
**The tool configures and runs everything in a containerized virtualized environment isolated from the host.**

- A 64-bit machine. It is possible to run on a 32-bit machine, but expect performance or compatibility limitations.
- A minimum of 4GB is recommended to ensure enough resource availability for scaling and future expansion.
- ARM architecture devices, such as Raspberry Pi, Apple Silicon, etc, require  an emulation layer such as [**qemu-user-static (qus)**](https://github.com/dbhi/qus) to run x86 architecture applications on ARM. Automatically configured seamlessly through the tool.
- On Windows, [**WSL2**](https://learn.microsoft.com/en-us/windows/wsl/install) and [**Winget**](https://learn.microsoft.com/en-us/windows/package-manager) is required.

### Quick Start Guide ⚙️
If the prerequisites are met based on the platform, you can simply follow the quick start guide, otherwise, refer to the [**Wiki**](../../wiki) for the full setup procedure.

### Windows
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

Refer to the [**Windows**](../../wiki/Windows-Host) guide first to ensure prerequisites are met before proceeding. If WSL is already configured, continue.

Open the command line and get the bootstrap script.
```markdown
curl -o %APPDATA%\IGM\igm.bat --create-dirs --ssl-no-revoke -L https://raw.githubusercontent.com/XternA/income-generator/main/start.bat
```
Register the bootstrap script by adding an entry to the environment variable path.
```sh
for /f "delims=" %i in ('powershell -Command "[Environment]::GetEnvironmentVariable('Path', 'User')"') do set USERPATH=%i && setx PATH %USERPATH%;%APPDATA%\IGM
```
For the registering to take effect, close and re-open a new command line process.

Run the tool.
```sh
# Type anywhere in the command line
igm
```

---
### Linux & macOS
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)![macOS](https://img.shields.io/badge/MacOS-444444?style=for-the-badge&logo=apple&logoColor=white)

Open the terminal and clone the project.
```sh
git clone --depth=1 https://github.com/XternA/income-generator.git ~/.igm
```
Register alias for global access. (Auto detects and adds to current shell choice e.g. `.bashrc`, `.zshrc` etc.)
```sh
echo "alias igm=\"sh -c 'cd ~/.igm; sh start.sh \\\"\\\$@\\\"' --\"" >> ~/."${SHELL##*/}rc"; source ~/."${SHELL##*/}rc"
```
Run the tool.
```sh
# Type anywhere in the command line
igm
```

## Account Registration 📋
The application table provides the install specification for each applications.

App registration can also be done in the tool via `Setup Configuration` process.

- 📋 The provided registration links will entitle you to receive a bonus added to your account on registration. Additionally, it ensures you're registering at the correct site and showing your support for my work.

- 🔐 If using social logins such as Google, set a password for the account so it can be used for app authentication.

| Application | Residential / Mobile IP | VPS / Hosting IP | Devices Per Account | Devices Per IP | Major Payout Type |
| --- | :---: | :---: | :---: | :---: | :---: |
| **[EARNAPP](https://bit.ly/4a4XJLF)**         | :white_check_mark: | :x:                |15|1               | PayPal |
| **[HONEYGAIN](https://bit.ly/3x6nX1S)**       | :white_check_mark: | :x:                |10|1               | PayPal, Crypto |
| **[PEER2PROFIT](https://bit.ly/3x7CquB)**     | :white_check_mark: | :white_check_mark: |Unlimited|Unlimited| Crypto |
| **[TRAFFMONETIZER](https://bit.ly/3TKmJlU)**  | :white_check_mark: | :white_check_mark: |Unlimited|Unlimited| Crypto |
| **[PAWNS](https://bit.ly/498zRFV)**           | :white_check_mark: | :x:                |Unlimited|1        | PayPal, Crypto |
| **[REPOCKET](https://bit.ly/3TNO6LY)**        | :white_check_mark: | :white_check_mark: |Unlimited|2        | PayPal, Wise |
| **[PACKETSTREAM](https://bit.ly/4ajvcSg)**    | :white_check_mark: | :x:                |Unlimited|1        | PayPal |
| **[PROXYRACK](https://bit.ly/497RsOj)**       | :white_check_mark: | :white_check_mark: |500|1              | PayPal |
| **[PROXYLITE](https://bit.ly/4a3CjPe)**       | :white_check_mark: | :white_check_mark: |Unlimited|1        | Crypto |
| **[EARNFM](https://bit.ly/3Vzenip)**          | :white_check_mark: | :white_check_mark: |Unlimited|1        | PayPal, Crypto |
| **[SPIDE](https://bit.ly/3VpoiXH)**           | :white_check_mark: | :x:                |Unlimited|Unlimited| PayPal, Crpyto |
| **[SPEEDSHARE](https://bit.ly/4cstfEZ)**      | :white_check_mark: | :x:                |Unlimited|1        | PayPal, Crypto |
| **[GRASS](https://bit.ly/495PPAn)**           | :white_check_mark: | :x:                |Unlimited|1        | Crypto |
| **[MYSTNODE](https://bit.ly/4cl0YAt)**        | :white_check_mark: | :white_check_mark: |Unlimited|Unlimited| Crypto |
| **[BITPING](https://bit.ly/43xHKDt)**         | :white_check_mark: | :white_check_mark: |Unlimited|1        | Crypto |
| **[GAGANODE](https://bit.ly/4452ram)**        | :white_check_mark: | :white_check_mark: |Unlimited|1        | Crypto |
| **[NODEPAY](https://bit.ly/3zs6B0o)**         | :white_check_mark: | :x:                |250|Unlimited      | Coming Soon |
| **[BEARSHARE](https://bit.ly/4g7PmCs)**       | :white_check_mark: | :white_check_mark: |Unlimited|1        | Crypto |
| **[PACKETSHARE](https://bit.ly/47NcTVR)**     | :white_check_mark: | :x:                |Unlimited|1        | PayPal |

### Additional Applications
These are applications currently without support via IGM. You can start running these alongside IGM to start earning until they become supported.

| Application | Major Payout Type |
| --- | :---: |
| **[ByteLixir](https://bit.ly/48Aes9V)** | Crypto |
| **[Wipter](https://bit.ly/3AtdSy7)** | Crypto |
| **[UpRock](https://bit.ly/4efUcf5)** | Crypto |

The applcations are usually a desktop GUI application.

## Supported Environments ✅
The tool has been tried and tested on the following environments and should be runnable if the host instances is capable of supporting container runtime such as Docker.

| Windows WSL2 (x86_64 / amd64) | Linux Ubuntu (x86_64 / amd64) | Raspbian OS (arm32/64) | Intel macOS (x86_64) | Apple Silicon (arm64) |
| :---: | :---: | :---: | :---: | :---: |
| :green_circle: | :green_circle: | :green_circle: | :green_circle: | :green_circle: |
| Desktop / Laptop | Desktop / Laptop | Raspberry Pi 3/4 | MacBook Pro | MacBook Pro |

## Like The Project? 🫶

Your efforts and interest are well appreciated if you would like to contribute and improve the tool or compatibility and enable it widely available and easy to use.

Even if you do not wish to contribute, you can still show your support by giving this project a star ⭐ or sharing it with others.

### Donations 💸
- **Bitcoin (BTC)** - `bc1qq993w3mxsf5aph5c362wjv3zaegk37tcvw7rl4`
- **Ethereum (ETH)** - `0x2601B9940F9594810DEDC44015491f0f9D6Dd1cA`
- **Binance (BNB)** - `bnb1dj3l3fp24z05vtwtjpaatjyz9sll4elu9lkjww`
- **Binance Smart Chain (BSC)** - `0x2601B9940F9594810DEDC44015491f0f9D6Dd1cA`
- **Solana (SOL)** - `Ap5aiAbnsLtR2XVJB3sp37qdNP5VfqydAgUThvdEiL5i`
- **PayPal** - [@xterna](https://paypal.me/xterna)

Donations are warmly welcomed, no matter the amount, your support is gratefully appreciated. Additionally, it helps fuel future developments and maintenance. Thank you. 🙏🏻

## Disclaimer ⚠️
Before using the applications provided in this stack, it is essential to verify that your actions comply with the laws of your jurisdiction and adhere to the terms outlined in your internet service provider's contract. The integration of these applications within this stack is purely for user convenience and does not signify an endorsement of their utilization.

The author of this stack does not accept any responsibility for the outcomes resulting from the utilization of these applications. While this stack streamlines the configuration process and facilitates automated updates for the included applications, it is distributed on an "as is" basis without any warranties.

The author does not provide any assurances, whether explicit or implicit, regarding the accuracy, completeness, or appropriateness of this script for specific purposes. The author shall not be held accountable for any damages, including but not limited to direct, indirect, incidental, consequential, or special damages, arising from the use or inability to use this tool or its accompanying documentation, even if the possibility of such damages has been communicated.

By choosing to utilize this tool, you acknowledge and assume all risks associated with its use. Additionally, you agree that the author cannot be held liable for any issues or consequences that may arise as a result of its usage.
