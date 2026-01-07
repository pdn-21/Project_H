#!/bin/bash

# ============================================
# Linux Build Fix Script
# แก้ปัญหา ld.lld not found
# ============================================

echo "🔧 Fixing Linux Build Issues..."

# ติดตั้ง Dependencies ที่จำเป็นสำหรับ Linux
echo "📦 Installing required packages..."

# Ubuntu/Debian
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        lld \
        llvm
fi

# Fedora/RHEL
if command -v dnf &> /dev/null; then
    sudo dnf install -y \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        gtk3-devel \
        lld \
        llvm
fi

# Arch Linux
if command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm \
        clang \
        cmake \
        ninja \
        pkg-config \
        gtk3 \
        lld \
        llvm
fi

echo "✅ Dependencies installed"

# ล้าง Flutter cache
echo "🧹 Cleaning Flutter cache..."
flutter clean
flutter pub get

# สร้าง symlink สำหรับ ld (ถ้าจำเป็น)
if ! command -v ld &> /dev/null; then
    echo "⚠️  ld not found, creating symlink..."
    
    # หา ld.lld
    LLD_PATH=$(which ld.lld)
    
    if [ -n "$LLD_PATH" ]; then
        sudo ln -sf "$LLD_PATH" /usr/bin/ld
        echo "✅ Created symlink: /usr/bin/ld -> $LLD_PATH"
    else
        echo "❌ ld.lld not found. Please install lld package."
        exit 1
    fi
fi

echo "✅ Linux build environment is ready!"
echo ""
echo "Now you can build with:"
echo "  flutter build linux --release"
echo "  or"
echo "  flutter run -d linux"