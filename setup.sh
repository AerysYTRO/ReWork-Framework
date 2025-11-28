#!/bin/bash

# ReWork Framework - Installation & Setup Script
# This script automates the ReWork Framework setup process

set -e

echo ""
echo "================================"
echo "ReWork Framework Setup Wizard"
echo "================================"
echo ""

# Check if running on correct directory
if [ ! -f "fxmanifest.yaml" ]; then
    echo "❌ Error: fxmanifest.yaml not found!"
    echo "Please run this script from the ReWork-Framework directory"
    exit 1
fi

echo "✅ Found ReWork Framework directory"
echo ""

# Step 1: Check Node.js
echo "📦 Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

NODE_VERSION=$(node -v)
echo "✅ Node.js $NODE_VERSION found"
echo ""

# Step 2: Check npm
echo "📦 Checking npm installation..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found"
    exit 1
fi

NPM_VERSION=$(npm -v)
echo "✅ npm $NPM_VERSION found"
echo ""

# Step 3: Install dependencies
echo "📥 Installing npm dependencies..."
npm install --legacy-peer-deps
echo "✅ Dependencies installed"
echo ""

# Step 5: Create dist directory if needed
if [ ! -d "dist" ]; then
    mkdir -p dist/client
    echo "📁 Created dist directory"
fi
echo ""

# Step 6: Database setup instructions
echo "💾 Database Setup Instructions:"
echo "================================"
echo "1. Create database:"
echo "   CREATE DATABASE rework;"
echo ""
echo "2. Create user:"
echo "   CREATE USER 'rework'@'localhost' IDENTIFIED BY 'rework';"
echo ""
echo "3. Grant permissions:"
echo "   GRANT ALL PRIVILEGES ON rework.* TO 'rework'@'localhost';"
echo "   FLUSH PRIVILEGES;"
echo ""

# Step 7: Copy to resources
echo "📋 To use this framework:"
echo "=========================="
echo "1. Copy this directory to your FiveM resources:"
echo "   cp -r ReWork-Framework /path/to/fivem/resources/"
echo ""
echo "2. Add to server.cfg:"
echo "   ensure ReWork-Framework"
echo ""
echo "3. Restart your server"
echo ""

echo "✅ Setup complete!"
echo ""
echo "📚 Next steps:"
echo "- Read GETTING_STARTED.md for detailed setup"
echo "- Check API.md for API reference"
echo "- See CONFIGURATION.md for configuration examples"
echo ""
echo "🚀 Happy coding!"
