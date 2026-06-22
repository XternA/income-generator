<h4 align="center">
<img width="1980" height="800" alt="IGM Banner" src="https://github.com/user-attachments/assets/4934d96c-99a7-4fe5-842f-b2a7db27f24c" />
 
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

<div align="center">
  <img src="https://github.com/user-attachments/assets/883c4584-3c71-4040-a45d-da02bded1174" alt="IGM TUI" />
</div>

Income Generator (IGM) is a feature-rich tool for deploying and managing passive income applications at scale — in a containerized runtime environment with easy configurable resource limits and multi-proxy scaling to maximise earnings per device.

Manage everything from the command line, TUI, or via the built-in web dashboard. Quick to set up, easy to deploy, and runs anywhere. Lightweight and fast, IGM itself has a minimal footprint — making it well-suited for always-on home servers and low-power SBCs.

📖 For detailed instructions and advanced usage, refer to the [**Wiki**](../../wiki).

## Key Features ✨
- **Multi-platform** — Runs natively on any OS and architecture, including low-power SBCs.
- **ARM emulation** — QEMU automatically set up on ARM devices during container runtime installation.
- **Web dashboard** — Lightweight, responsive UI. Orchestrate, monitor and manage all within the browser.
- **Multi-proxy scaling** — Automatically deploy multiple instances per app from a proxy list to stack earnings.
- **Resource limits** — Easily apply resource limits across applications, dynamically based on hardware.
- **Credential encryption** — Secrets encrypted at rest; decrypted only during operation.
- **Auto update** — Income applications update automatically without interruption.
- **Auto claim** — Daily rewards claimed automatically for supported applications.
- **Proxy install limits** — Fine-tune per-app deployment counts for full control over proxy scaling.
- **Quick actions** — Common operations available as direct CLI commands, no TUI required.

## Quick Start 🚀

### Step 1: Install IGM

![macOS](https://img.shields.io/badge/MacOS-444444?style=for-the-badge&logo=apple&logoColor=white)![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

Run the following installer in your terminal.
```sh
curl -fsSL https://raw.githubusercontent.com/XternA/income-generator/installer/install.sh | sh
```

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

Run the following installer in Windows Terminal (Command Prompt), outside of WSL.

```sh
curl -fsSL https://raw.githubusercontent.com/XternA/income-generator/installer/install.cmd -o install.cmd && install.cmd && del install.cmd
```

> IGM leverages WSL natively. Refer to the [**Windows guide**](../../wiki/Windows-Guide) to setup WSL on Windows.

### Step 2: Run IGM

#### IGM TUI
```sh
# Type anywhere in the command line
igm
```

#### WebUI Dashboard

A browser-based interface extension to IGM for deploying and managing applications. Requires a container runtime to be installed first. Run `igm runtime` to set up if needed.

```sh
# --auto flag will configure the WebUI to auto-start on boot
igm web start --auto
```

Open http://localhost:4747 (or LAN IP) in the browser to see the dashboard, configure, deploy and manage.

## Supported Applications 📋

The following table provides IGM support and the install specification for each application.

App registration can be done via IGM's TUI, CLI or Web UI interface.

- 📋 The provided registration links entitle you to a bonus on registration and ensure you’re signing up at the correct site.

| Application | Residential / Mobile IP | VPS / Hosting IP | Devices Per Account | Devices Per IP | Major Payout Type |
| --- | :---: | :---: | :---: | :---: | :---: |
| **[EarnApp](https://tinyurl.com/nhc97kh6)**         | :white_check_mark: | :x:                | 15        | 1         | PayPal |
| **[Honeygain](https://tinyurl.com/4pz24raa)**       | :white_check_mark: | :x:                | 10        | 1         | PayPal, Crypto |
| **[Peer2Profit](https://tinyurl.com/3besa7wy)**     | :white_check_mark: | :white_check_mark: | Unlimited | Unlimited | Crypto |
| **[Traffmonetizer](https://tinyurl.com/4n9d4r54)**  | :white_check_mark: | :white_check_mark: | Unlimited | Unlimited | Crypto |
| **[Pawns](https://tinyurl.com/3m25k4av)**           | :white_check_mark: | :x:                | Unlimited | 1         | PayPal, Crypto |
| **[Repocket](https://tinyurl.com/3w6ekwyx)**        | :white_check_mark: | :white_check_mark: | Unlimited | 2         | PayPal, Wise |
| **[Packetstream](https://tinyurl.com/22wccert)**    | :white_check_mark: | :x:                | Unlimited | 1         | PayPal |
| **[Proxyrack](https://tinyurl.com/4ypm8wya)**       | :white_check_mark: | :white_check_mark: | 500       | 1         | PayPal |
| **[Proxylite](https://tinyurl.com/ynhxy5we)**       | :white_check_mark: | :white_check_mark: | Unlimited | 1         | Crypto |
| **[EarnFM](https://tinyurl.com/3pxam34v)**          | :white_check_mark: | :white_check_mark: | Unlimited | 1         | PayPal, Crypto |
| **[Speedshare](https://tinyurl.com/bdddwn9e)**      | :white_check_mark: | :x:                | Unlimited | 1         | PayPal, Crypto |
| **[Spide](https://tinyurl.com/y3xtfd9z)**           | :white_check_mark: | :x:                | Unlimited | Unlimited | PayPal, Crypto |
| **[Grass](https://tinyurl.com/msfkrace)**           | :white_check_mark: | :x:                | Unlimited | 1         | Crypto |
| **[Mysterium](https://tinyurl.com/5dkekpmc)**       | :white_check_mark: | :white_check_mark: | Unlimited | Unlimited | Crypto |
| **[Bitping](https://tinyurl.com/2h5jam3b)**         | :white_check_mark: | :white_check_mark: | Unlimited | 1         | Crypto |
| **[GagaNode](https://tinyurl.com/mr2fb8jf)**        | :white_check_mark: | :white_check_mark: | Unlimited | 1         | Crypto |
| **[Wipter](https://tinyurl.com/mt8rj948)**          | :white_check_mark: | :x:                | Unlimited | Unlimited | Crypto |
| **[ProxyBase](https://tinyurl.com/3z9sas27)**       | :white_check_mark: | :white_check_mark: | Unlimited | 1         | Crypto |
| **[WizardGain](https://tinyurl.com/mw962kkv)**      | :white_check_mark: | :white_check_mark: | Unlimited | 1         | PayPal, Crypto |
| **[AntGain](https://tinyurl.com/usdtrrus)**         | :white_check_mark: | :white_check_mark: | Unlimited | Unlimited | Crypto, PayPal (Soon) |

### Additional Applications
These applications currently aren’t supported via IGM yet as they're desktop-GUI only versions. You can run them alongside IGM to earn in the meantime. Once supported, they will be integrated into IGM.

| Application | Residential / Mobile IP | VPS / Hosting IP | Devices Per Account | Devices Per IP | Major Payout Type |
| --- | :---: | :---: | :---: | :---: | :---: |
| **[PassiveApp](https://tinyurl.com/3ufkk4kc)**      | :white_check_mark: | :white_check_mark: | Unlimited | Unlimited | PayPal, Crypto |
| **[ByteLixir](https://tinyurl.com/2uhz58ae)**       | :white_check_mark: | :white_check_mark: | Unlimited | Unlimited | Crypto         |
| **[ByteBenefit](https://tinyurl.com/5actkn8m)**     | :white_check_mark: | :x:                | Unlimited | 1         | PayPal, Stripe |
| **[Earn.cc](https://tinyurl.com/y57x29nt)**         | :white_check_mark: | :x:                | Unlimited | 1         | Crypto         |
| **[UpRock](https://tinyurl.com/2tk9ppz7)**          | :white_check_mark: | :x:                | Unlimited | 1         | Crypto         |

## Tested Environments ✅
IGM has been tested on the following environments and should run on any host that supports a container runtime such as Docker.

| Platform | Architecture | Device Type | Fully Supported |
| :------- | :----------- | :---------- | :-------------: |
| Windows WSL2 (Ubuntu)   | amd64, arm64   | Desktop, Laptop PC                 | 🟢 |
| Linux Ubuntu, Debian    | amd64, arm64   | Desktop, Laptop PC, Raspberry Pi 4 | 🟢 |
| macOS                   | amd64, arm64   | MacBook Pro                        | 🟢 |

Older SBC devices, such as the Raspberry Pi 3 (arm32v7), can run IGM. However, due to hardware limitations, some applications may not work and overall performance may be reduced.

## Like The Project? 🫶
Your efforts and interest are well appreciated if you would like to contribute and improve the tool or compatibility and enable it widely available and easy to use.

Even if you do not wish to contribute, you can still show your support by giving this project a star ⭐ or sharing it with others.

### Donations 💸
- **Bitcoin (BTC)** - `bc1qq993w3mxsf5aph5c362wjv3zaegk37tcvw7rl4`
- **Ethereum (ETH)** - `0x2601B9940F9594810DEDC44015491f0f9D6Dd1cA`
- **Solana (SOL)** - `Ap5aiAbnsLtR2XVJB3sp37qdNP5VfqydAgUThvdEiL5i`
- **Binance Smart Chain (BSC)** - `0x2601B9940F9594810DEDC44015491f0f9D6Dd1cA`
- **PayPal** - [@xterna](https://paypal.me/xterna)

Donations are warmly welcomed, no matter the amount, your support is gratefully appreciated. Additionally, it helps fuel future developments and maintenance. Thank you. 🙏🏻

## Disclaimer ⚠️
Before using the applications provided in this stack, it is essential to verify that your actions comply with the laws of your jurisdiction and adhere to the terms outlined in your internet service provider's contract. The integration of these applications within this stack is purely for user convenience and does not signify an endorsement of their utilization.

The author of this stack does not accept any responsibility for the outcomes resulting from the utilization of these applications. While this stack streamlines the configuration process and facilitates automated updates for the included applications, it is distributed on an "as is" basis without any warranties.

The author does not provide any assurances, whether explicit or implicit, regarding the accuracy, completeness, or appropriateness of this script for specific purposes. The author shall not be held accountable for any damages, including but not limited to direct, indirect, incidental, consequential, or special damages, arising from the use or inability to use this tool or its accompanying documentation, even if the possibility of such damages has been communicated.

By choosing to utilize this tool, you acknowledge and assume all risks associated with its use. Additionally, you agree that the author cannot be held liable for any issues or consequences that may arise as a result of its usage.

## Stargazers ⭐️
[![Stargazers over time](https://starchart.cc/XternA/income-generator.svg?variant=adaptive)](https://starchart.cc/XternA/income-generator)
