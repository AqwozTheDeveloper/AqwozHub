# Aqwoz Hub

A powerful Roblox script hub developed by **AqwozTheDeveloper**. Features include ESP, Aimbot, and Silent Aim with a modern UI.

![Version](https://img.shields.io/badge/version-1.3.0-blue)
![Status](https://img.shields.io/badge/status-active-green)

## 🚀 Features

### Vision (ESP)
- **Player ESP** - See players through walls with highlights and boxes
- **Health Bars** - Real-time health display with color indicators (green/yellow/red)
- **Player Names** - Display player names above their heads
- **Team Check** - Don't show teammates
- **Custom Colors** - Choose your ESP color

### Aimbot (Legit)
- **Smooth Aiming** - Adjustable smoothing (1-10)
- **FOV Circle** - Visual FOV indicator
- **Prediction** - Lead moving targets (0-30%)
- **Team Check** - Don't aim at teammates
- **Wall Check** - Only aim at visible targets
- **Hold to Aim** - Hold right-click to aim
- **Dynamic Smoothing** - Faster aim when closer to target
- **Target Lock Pointer** - Visual cursor on target
- **F Key Toggle** - Quick enable/disable
- **Target Part Selection** - Head or UpperTorso

### Silent Aim
- **Invisible Aim Assist** - Bullets redirect to target
- **FOV Circle** - Red FOV indicator
- **Team Check** - Don't hit teammates
- **Executor Support Check** - Automatic compatibility detection
- **Target Part Selection** - Head or UpperTorso

## 📦 Installation

### Method 1: Direct Execute
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/main/main.luau"))()
```

### Method 2: Local Files
1. Download all `.luau` files
2. Place them in your executor's workspace folder
3. Execute `main.luau`

## 🔑 Key System

The script uses a daily rotating key system via [work.ink](https://work.ink).

### For Users:
1. Run the script
2. Key link is auto-copied to clipboard
3. Paste in browser and complete the page
4. Copy the key shown
5. Enter it in the key box

### For Developers:
- Keys rotate daily at midnight UTC
- Use `KeyGen.luau` to generate today's key
- VIP keys are permanent and don't expire

## ⚙️ Settings

All settings are automatically saved and persist between sessions.

| Setting | Location | Description |
|---------|----------|-------------|
| Config File | `AqwozHubSettings.json` | All user preferences |
| Key File | `AqwozHubKey.txt` | Daily key storage |
| Date File | `AqwozHubKeyDate.txt` | Key expiration tracking |

## 🎮 Supported Executors

| Executor | Aimbot | Silent Aim | ESP |
|----------|--------|------------|-----|
| Synapse X | ✅ | ✅ | ✅ |
| Script-Ware | ✅ | ✅ | ✅ |
| Xeno | ✅ | ✅ | ✅ |
| Fluxus | ✅ | ⚠️ | ✅ |
| KRNL | ✅ | ⚠️ | ✅ |

✅ = Full Support | ⚠️ = Partial Support (may require specific functions)

## 📁 File Structure

```
AqwozHub/
├── main.luau             # Main script (entry point)
├── aimbotScripts.luau    # Aimbot module
├── silentAimScripts.luau # Silent Aim module
├── visionScripts.luau    # ESP module
├── ragingScripts.luau    # Rage module (placeholder)
├── KeyGen.luau           # Key generator (developer only - DO NOT SHARE)
├── README.md             # This file
├── LICENSE               # License file
└── .gitignore            # Git ignore rules
```

## 🛠️ Debug Mode

Enable debug mode in Settings tab to see detailed logs in the console (F9).

Available debug modes:
- Vision Debug Mode
- Aimbot Debug Mode
- Silent Aim Debug Mode

## 📊 Stats

Print module stats from the Settings tab:
- **Aimbot Stats** - Current target, FOV, smoothing, prediction
- **Silent Aim Stats** - FOV, max distance, target part
- **Vision Stats** - Tracked players, team check status

## ⚠️ Disclaimer

This script is for educational purposes only. Use at your own risk. The developer is not responsible for any bans or consequences from using this script.

## 📞 Support

- **Discord**: [discord.gg/aqwozhub](https://discord.gg/aqwozhub)
- **Developer**: AqwozTheDeveloper

## 📝 Changelog

### v1.3.0 (Current)
- Added daily key system with work.ink
- Added health bars and player names to ESP
- Added prediction slider for aimbot
- Improved executor compatibility
- Bug fixes and stability improvements

### v1.2.0
- Added Silent Aim module
- Added FOV circles for both aimbots
- Added debug modes

### v1.1.0
- Added settings persistence
- Added team and wall checks
- Added dynamic smoothing

### v1.0.0
- Initial release
- Basic ESP and Aimbot

## 📄 License

This project is for personal use only. Do not redistribute without permission.

---

Made with ❤️ by AqwozTheDeveloper
