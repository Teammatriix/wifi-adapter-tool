# Wi-Fi Adapter Tool  v3.1 (AI Enhanced)

![Banner](https://github.com/Teammatriix/wifi-adapter-tool/blob/main/Screenshot.png?raw=true) 

Welcome to the **Wi-Fi Adapter Tool**, a Bash script crafted by **Team Matrix Elite Hackers** for ethical penetration testing. Whether you're a beginner or an experienced pentester, this tool helps you explore your Wi-Fi adapter's capabilities with ease. It features AI-driven suggestions, supports hacking modes like monitor mode and Access Point (AP) setup, and runs smoothly on Kali Linux.

## What Does This Tool Do?
This script is your go-to companion for testing wireless adapters. It checks what your adapter can do (like sniffing packets or creating a fake Wi-Fi network) and lets you activate those features with simple menu options. Think of it as a Swiss Army knife for Wi-Fi testing—perfect for learning or professional use!

## Features
- **Adapter Details**: See your adapter’s name, chipset, driver, and mode (e.g., monitor or managed).
- **Capability Checks**: Test if your adapter supports monitor mode, packet injection, AP mode, and more.
- **Hacking Modes**: Turn on monitor mode, inject packets, or set up an AP with `hostapd`.
- **AI Smarts**: Get tips and recommendations tailored to your adapter.
- **Beginner-Friendly**: Clear menus, color-coded outputs, and step-by-step guidance.

## Changelog
- **Changelog**: See [CHANGELOG.md](CHANGELOG.md) for updates and version history.

## System Requirements
- **Operating System**: Kali Linux (tested on Kali 2023.4 and later—perfect for hacking tools!).
- **Root Access**: Run with `sudo` (you’ll need admin powers to tweak adapters).
- **Hardware**: A Wi-Fi adapter that supports hacking modes (see [Supported Adapters](#supported-adapters)).
- **Basic Specs**: Any Kali-compatible system (e.g., 2GB RAM, 20GB storage).

### Why Kali Linux?
Kali Linux is a special OS built for security testing. It comes with tons of tools pre-installed, making it ideal for this script. If you’re new, don’t worry—Kali is free and easy to set up on a USB or virtual machine!

## Installation

### How to Install and Set Up
1. **Get the Code from GitHub**:
   - Open a terminal (press `Ctrl + Alt + T` in Kali).
   - Type:
     ```bash
     git clone https://github.com/Teammatriix/wifi-adapter-tool.git
     ```
   - This downloads the tool to your computer.

2. **Navigate to the Directory**:
   - Move into the folder:
     ```bash
     cd wifi-adapter-tool
     ```
   - You’re now in the tool’s home!

3. **Make the Script Executable**:
   - Tell Kali it’s a program:
     ```bash
     chmod +x wifi-adapter-tool.sh
     ```
   - This is like flipping the “on” switch.

4. **Fix Line Endings (Important)**:
   - If you copied the script from a Windows system or GitHub, it might have incorrect line endings. Fix this:
     ```bash
     sudo apt install dos2unix
     dos2unix wifi-adapter-tool.sh
     ```

5. **Run the Script**:
   - Start it with:
     ```bash
     sudo ./wifi-adapter-tool.sh
     ```
   - `sudo` gives it superpowers to control your adapter.

### How to Install Requirements
The script checks for missing tools when you run it with `sudo` and tries to install them automatically. These tools are like helpers that make the script work:
- `iw`: Talks to your Wi-Fi adapter.
- `wireless-tools`: Gives adapter details.
- `usbutils`: Helps find USB adapters.
- `pciutils`: Finds internal Wi-Fi cards.
- `dos2unix`: Fixes file formatting.
- `aircrack-ng`: Unlocks hacking features.
- `hostapd`: Sets up Wi-Fi hotspots.

#### To Manually Install Them:
If you prefer to set things up yourself (or the auto-install fails):
1. Update Kali:
   ```bash
   sudo apt update
   ```
2. Install the tools:
   ```bash
   sudo apt install -y iw wireless-tools usbutils pciutils dos2unix aircrack-ng hostapd
   ```
3. Check if they’re installed:
   ```bash
   iw --version && aircrack-ng --help
   ```
   - If you see version info, you’re good!

## Usage
New to pentesting? No problem! Here’s how to use the tool step-by-step.

1. **Launch the Script**:
   ```bash
   sudo ./wifi-adapter-tool.sh
   ```
   - You’ll see a cool banner and a check for those helper tools.

2. **Select an Adapter**:
   - The tool lists your Wi-Fi adapters (e.g., `wlan0` for a USB Wi-Fi stick).
   - Type a number (like `1`) or an adapter name (e.g., `wlan0`).
   - Don’t see your adapter? Plug it in and try again!

3. **Main Menu Options**:
   - **1. Check Adapter Details**: Shows what your adapter is and what it’s doing.
   - **2. Check Adapter Capabilities**: Tests cool stuff like packet sniffing or hotspot creation.
   - **3. Activate Hacking Mode**: Turns on hacking features (e.g., monitor mode or AP).
   - **4. AI Mode**: Lets the AI pick the best setup for you.
   - **5. Exit**: Closes the tool when you’re done.

4. **Example**:
   - **Want to make a fake Wi-Fi hotspot?**
     - Pick `3` (Hacking Mode) > `3` (Enable AP Mode).
     - Enter a name (e.g., `TestAP`) and channel (e.g., `6`).
     - The tool uses `hostapd` to broadcast it—clients can connect!

5. **Tips for Beginners**:
   - Press `Enter` after each step to move forward.
   - Colors help: Green = good, Blue = info or warning.
   - Stuck? Check [Troubleshooting](#troubleshooting) below.

## Supported Adapters
Not all Wi-Fi adapters can hack. You need one that supports special modes like monitor mode (sniffing), packet injection (messing with traffic), or AP mode (hotspot). Here’s a beginner-friendly list:

| Adapter Model         | Chipset       | Driver      | Monitor Mode | Packet Injection | AP Mode | Notes                     |
|-----------------------|---------------|-------------|--------------|------------------|---------|---------------------------|
| TP-Link TL-WN722N v1  | Atheros AR9271| ath9k_htc   | Yes          | Yes              | Yes     | Cheap, popular, works great |
| Alfa AWUS036NHA       | Atheros AR9271| ath9k_htc   | Yes          | Yes              | Yes     | Strong signal, reliable   |
| Alfa AWUS036ACH       | Realtek RTL8187| rtl8187    | Yes          | Yes              | Yes     | Works on 2.4GHz and 5GHz  |
| Alfa w115             | Unknown       | Unknown     | Yes*         | Yes*             | Yes*    | Limited info, test required |
| Panda PAU05           | Ralink RT5572 | rt2800usb   | Yes          | Yes              | Yes     | Small, solid for testing  |
| Intel Wi-Fi 6 AX200   | Intel         | iwlwifi     | Yes          | No               | Yes     | Built-in laptops, limited |

**Notes**: 
- *Alfa w115*: Specific chipset/driver info isn’t widely documented. Test with `lsusb` and `iw list` to confirm capabilities (marked with *).
- **Tip**: Check your adapter with `lsusb` (USB) or `lspci` (PCIe) and verify driver compatibility with `lsmod`.

### How to Check Your Adapter
- **USB Adapters**: Plug it in, then run:
  ```bash
  lsusb
  ```
  - Look for names like “Atheros” or “Realtek.”
- **Internal Cards**: Run:
  ```bash
  lspci | grep Wireless
  ```
- **Driver Check**: See what’s loaded:
  ```bash
  lsmod | grep wifi
  ```
- **Not Sure?**: Buy a **Alfa w115** —it’s a safe bet for beginners!

## Troubleshooting
Things not working? Don’t panic—here’s how to fix common hiccups.

### Common Errors and Solutions
1. **Error: "No wireless adapters detected"**
   - **What’s Wrong?**: Your Wi-Fi adapter isn’t plugged in or Kali can’t see it.
   - **Fix**:
     - Check it’s connected: `iw dev`.
     - See loaded drivers: `lsmod`.
     - Unplug and replug it, then retry.

2. **Error: "Failed to bring wlanX down"**
   - **What’s Wrong?**: Something else (like NetworkManager) is using your adapter.
   - **Fix**:
     ```bash
     sudo airmon-ng check kill
     sudo ifconfig wlanX down
     ```
     - This stops pesky programs and frees your adapter.

3. **Error: "Failed to set wlanX to AP mode"**
   - **What’s Wrong?**: Missing `hostapd` or your adapter doesn’t support AP mode.
   - **Fix**:
     - Install it: `sudo apt install hostapd`.
     - Check support: `iw list | grep "AP"`.
     - No “AP”? You need a different adapter.

4. **Interface Name Mangling (e.g., wlan0monmon)**
   - **What’s Wrong?**: Monitor mode got applied too many times.
   - **Fix**:
     ```bash
     sudo airmon-ng stop wlan0monmon
     sudo iw dev wlan0monmon del
     ```
     - Cleans up the mess!

5. **Error: "Permission denied" or "No such file or directory"**
   - **What’s Wrong?**: You didn’t use `sudo`, or the script has formatting issues.
   - **Fix**:
     - Run with `sudo`: `sudo ./wifi-adapter-tool.sh`.
     - Fix line endings: `dos2unix wifi-adapter-tool.sh`.
     - Check shebang: Ensure first line is `#!/bin/bash` (use `nano wifi-adapter-tool.sh`).
     - Try full path: `sudo /home/kali/wifi-adapter-tool/wifi-adapter-tool.sh`.

### General Tips
- **Update Kali**: Keep everything fresh:
  ```bash
  sudo apt update && sudo apt full-upgrade -y
  ```
- **Reboot**: Stuck? Restart Kali to reset adapters:
  ```bash
  sudo reboot
  ```
- **Debug**: See what’s breaking:
  ```bash
  journalctl -xe
  ```
  - Look for `hostapd` or driver errors.
- **Beginner Tip**: If it’s your first time, test with a known adapter (like TP-Link TL-WN722N v1) to avoid headaches.
 
## Contributing
Love this tool? Want to make it better? Here’s how:
- **Fork It**: Click “Fork” on GitHub to get your own copy.
- **Fix or Add**: Tweak the code or add features (e.g., more adapter support).
- **Pull Request**: Send your changes back to us via GitHub.
- **Report Bugs**: Open an “Issue” on GitHub if something’s broken.

No coding skills? Just tell us your ideas—we’re happy to help!

## License
This project uses the MIT License—free to use, modify, and share. Check the [LICENSE](LICENSE) file for the full text.

## Contact
Reach out to **Team Matrix Elite Hackers**:
- **Website**: [https://teammatrix.net/](https://teammatrix.net/)
- **YouTube**: [https://www.youtube.com/@Teammatrixs](https://www.youtube.com/@Teammatrixs)
- **Facebook**: [https://www.facebook.com/teammatriix](https://www.facebook.com/teammatriix)
- **Telegram Channels**:
  - ❶ [https://t.me/teammatrixs](https://t.me/teammatrixs)
  - ❷ [https://t.me/teammatriix](https://t.me/teammatriix)
- **LinkedIn**: [https://www.linkedin.com/company/teammatriix](https://www.linkedin.com/company/teammatriix)
- **X**: [https://x.com/Teammatriixs](https://x.com/Teammatriixs)
- **Mobile**: +881303818319

## More Info for Beginners
### What’s Penetration Testing?
It’s like being a “good hacker.” You test networks to find weak spots—legally, with permission—to make them safer. This tool helps you practice those skills.

### Key Terms
- **Monitor Mode**: Lets your adapter “listen” to all Wi-Fi traffic, like a radio scanner.
- **Packet Injection**: Sends fake signals to trick devices (needs special adapters).
- **AP Mode**: Turns your adapter into a Wi-Fi hotspot.
- **hostapd**: A program that makes AP mode work.
- **aircrack-ng**: A toolkit for Wi-Fi hacking tricks.

### Getting Started with Kali
1. **Install Kali**: Download it from [kali.org](https://www.kali.org/) and put it on a USB or virtual machine (try VirtualBox).
2. **Learn Basics**: Search “Kali Linux beginner tutorial” on YouTube—tons of free guides!
3. **Safety First**: Only test networks you own or have permission for (e.g., your home Wi-Fi).

**Disclaimer**: This tool is for ethical penetration testing only. Unauthorized use on networks you don’t own or have permission to test is illegal. Use responsibly and follow local laws. Stay ethical, folks!
