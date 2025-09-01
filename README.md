<p align="center">
<img src="./distro/image.jpg">
</p>

<p align="center">
<img src="https://img.shields.io/badge/MADE%20BY-UnQ-blue?colorA=%23ff6b35&colorB=%23f7931e&style=for-the-badge">
<img src="https://img.shields.io/badge/Version-3.0%20Enhanced-green?style=for-the-badge">
<img src="https://img.shields.io/badge/Developer-SANDEEP%20GADDAM-orange?style=for-the-badge">
</p>

<p align="center">
<img src="https://img.shields.io/badge/Written%20In-Bash-darkgreen?style=flat-square">
<img src="https://img.shields.io/badge/Open%20Source-Yes-darkviolet?style=flat-square">
<img src="https://img.shields.io/github/stars/UnQOfficial/ubuntu?style=flat-square">
<img src="https://img.shields.io/github/issues/UnQOfficial/ubuntu?color=red&style=flat-square">
<img src="https://img.shields.io/github/forks/UnQOfficial/ubuntu?color=teal&style=flat-square">
</p>

<p align="center"><b>🚀 Enhanced Ubuntu GUI for Termux - Professional Edition by UnQ</b></p>

---

## ✨ Enhanced Features (UnQ Edition)

### 🎯 **Core Enhancements**
- **Professional Installation System** - Progress bars, error handling, and enhanced UX
- **AI-Powered IDEs** - Cursor AI Editor and Void AI Editor integration
- **Enhanced Package Management** - Auto-install modes and better dependency resolution
- **UnQ Branding** - Professional banners and enhanced visual design
- **Better Error Recovery** - Intelligent fallback mechanisms and troubleshooting

### 🛠 **Development Tools**
- **Traditional IDEs**: Visual Studio Code, Sublime Text Editor
- **AI-Powered IDEs**: Cursor AI Editor, Void AI Editor (NEW!)
- **Multiple Installation Options**: Interactive, Auto-install, Custom selection
- **Enhanced Desktop Integration**: Improved .desktop files with better MIME support

### 🌐 **Browser Support**
- **Firefox** - Latest version from Mozilla Team PPA
- **Chromium** - Optimized for Termux environment
- **Multiple Installation Options** - Choose individual or install both

### 🎵 **Media & Entertainment**
- **VLC Media Player** - Full-featured media player
- **MPV Media Player** - Lightweight and efficient
- **Enhanced Audio System** - Fixed audio output with PulseAudio integration

### 🎨 **Visual & Themes**
- **Professional Themes** - Clean, modern desktop themes
- **Enhanced Fonts** - Support for multiple language fonts
- **Optimized UI** - Touch-friendly interface for mobile devices

### ⚡ **Performance & Reliability**
- **Lightweight Design** - Optimized for minimum 4GB storage
- **Enhanced Stability** - Better process management and cleanup
- **Auto-Update System** - Seamless version management
- **Professional Logging** - Detailed installation and error logs

---

## 📦 Installation Guide

### **Prerequisites**
1. **Install Termux** from [F-Droid](https://f-droid.org/repo/com.termux_118.apk)
2. **Minimum Requirements**: 4GB free storage, Android 7.0+

### **🚀 Quick Installation (Recommended)**


### **Update Termux packages**
```
yes | pkg update && pkg upgrade -y
```
### **Install essential tools**
```
pkg install git wget curl -y
```
### **Clone UnQ Ubuntu repository**

```
git clone --depth=1 https://github.com/UnQOfficial/ubuntu.git
```
### **Navigate to directory**
```
cd ubuntu
```
### **Run enhanced setup script**
```
bash setup.sh
```

### **⚡ Auto Installation (One-Command)**

```
# Download and auto-install (no prompts)
curl -fsSL https://raw.githubusercontent.com/UnQOfficial/ubuntu/master/setup.sh | bash -s -- -a
```

### **🔧 Post-Installation Setup**

1. **Restart Termux** and run:
   ```
   ubuntu
   ```

2. **Create user account**:
   ```
   bash user.sh
   ```
   - Enter username (lowercase, no spaces)
   - Enter secure password

3. **Restart Termux** again and run:
   ```
   ubuntu
   sudo bash gui.sh
   ```

4. **Note your VNC password** for later use

### **🖥️ VNC Setup**

1. **Start VNC Server**:
   ```
   vncstart
   ```

2. **Install VNC Viewer** on your Android device:
   - [Google Play Store](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android)
   - [F-Droid Alternative](https://f-droid.org/packages/com.gaurav.avnc/)

3. **Connect to VNC**:
   - Address: `localhost:1`
   - Name: `UnQ Ubuntu`
   - Quality: `High`
   - Password: (your noted VNC password)

4. **Stop VNC Server** when done:
   ```
   vncstop
   ```

---

## 🎮 Usage Commands

| Command | Description |
|---------|-------------|
| `ubuntu` | Launch Ubuntu CLI environment |
| `vncstart` | Start VNC server for GUI |
| `vncstop` | Stop VNC server |
| `bash gui.sh` | Install GUI components (run inside Ubuntu) |
| `bash remove.sh` | Remove Ubuntu installation |

---

## 🤖 AI IDE Integration

### **Quick AI IDE Installation**

```
# Inside Ubuntu environment
sudo bash gui.sh

# Select option  for AI-Powered IDEs[1]
# Or option  for All AI IDEs[2]
# Or option  for Custom Selection[3]
```

### **Individual AI IDE Installation**

**Cursor AI Editor:**
```
curl -fsSL https://raw.githubusercontent.com/UnQOfficial/cursor/refs/heads/main/cursor.sh | sudo bash -s -- -a
```

**Void AI Editor:**
```
curl -fsSL https://raw.githubusercontent.com/UnQOfficial/void/main/void.sh | sudo bash -s -- -a
```

---

## 🔧 Advanced Features

### **Professional Installation Options**
- **Interactive Mode**: Full menu-driven installation
- **Auto Mode**: Silent installation with optimal defaults  
- **Custom Mode**: Choose specific components to install

### **Enhanced Error Recovery**
- Automatic dependency resolution
- Network failure recovery with retry mechanisms
- Installation verification and rollback on failures
- Professional error logging and troubleshooting guides

### **Multi-Architecture Support**
- ARM64/AArch64 (Recommended)
- ARM32/ARMv7l  
- x86_64 (Android emulators)
- Automatic architecture detection

---

## 🎥 Video Tutorial

[![UnQ Ubuntu Installation Tutorial](./distro/image1.jpg)]()

---

## 📋 Troubleshooting

### **Common Issues**

**Installation Fails:**
```
# Check system requirements
bash setup.sh -s

# Retry with auto-install
bash setup.sh -a
```

**VNC Connection Issues:**
```
# Restart VNC server
vncstop
vncstart

# Check VNC status
ps aux | grep vnc
```

**Audio Problems:**
```
# Restart PulseAudio
pulseaudio --kill
pulseaudio --start
```

---

## 📝 Changelog

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history and updates.

---

## 📄 License

Licensed under [Apache License 2.0](./LICENSE) - see the LICENSE file for details.

---

## 🙏 Credits & Acknowledgments

```
This enhanced project builds upon and includes work from:

-  Termux Project - https://termux.com/
-  Termux Proot-Distro - https://github.com/termux/proot-distro  
-  Original modded-ubuntu contributors
-  Open-source community contributors

All modifications and enhancements are provided under the same
Apache License 2.0 terms while adding professional features
and improved user experience.
```

---

## 👨‍💻 Developer

**Sandeep Gaddam (UnQ)**
- 🌟 **GitHub**: [@UnQOfficial](https://github.com/UnQOfficial)
- 📧 **Email**: devunq@gmail.com
- 🔗 **Repository**: [UnQ Ubuntu](https://github.com/UnQOfficial/ubuntu)
- 💬 **Issues**: [Report Issues](https://github.com/UnQOfficial/ubuntu/issues)

---

## 🌟 Support the Project

If you find UnQ Ubuntu helpful, please consider:

- ⭐ **Star this repository**
- 🍴 **Fork and contribute**  
- 🐛 **Report bugs and issues**
- 💡 **Suggest new features**
- 📢 **Share with the community**

---

<p align="center">
<b>Made with ❤️ by SANDEEP GADDAM (UnQ)</b><br>
<i>Transforming mobile development experience</i>
</p>

<p align="center">
<img src="https://img.shields.io/badge/UnQ-Enhanced-blue?style=for-the-badge&logo=ubuntu&logoColor=white">
</p>
