#!/bin/sh
# custom_macos_settings.sh
# Example custom script for additional macOS configurations

echo "Applying custom macOS settings..."

# Check for arguments
if [ "$1" = "--help" ]; then
  echo "Usage: $0 [--dark-mode] [--dock-right]"
  echo "  --dark-mode    Enable dark mode"
  echo "  --dock-right   Position Dock on the right side"
  exit 0
fi

# Process arguments
for arg in "$@"; do
  case "$arg" in
    --dark-mode)
      echo "Setting Dark Mode..."
      defaults write -g AppleInterfaceStyle Dark
      ;;
    --dock-right)
      echo "Moving Dock to the right side..."
      defaults write com.apple.dock orientation right
      ;;
  esac
done

# Common macOS settings that many developers prefer

# Show hidden files in Finder
echo "Showing hidden files in Finder..."
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
echo "Showing path bar in Finder..."
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
echo "Showing status bar in Finder..."
defaults write com.apple.finder ShowStatusBar -bool true

# Disable the warning when changing file extensions
echo "Disabling warning when changing file extensions..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
echo "Disabling .DS_Store file creation on network and USB volumes..."
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
echo "Setting Finder default view to list view..."
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Enable Safari developer menu
echo "Enabling Safari developer menu..."
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Restart affected applications
echo "Restarting affected applications..."
killall Finder
killall Dock
killall Safari 2>/dev/null || true

echo "Custom macOS settings applied successfully!"
