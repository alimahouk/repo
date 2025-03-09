# Repo

Camera. Notepad. Map.  
All in one place in your pocket, with you all the time. Repo helps you document your life.

## Features

### 📸 Camera

Repo always launches to your camera, so you never miss capturing a moment. Tap to snap a photo, or long press to record a 10-second video.

### 📝 Notepad

A fresh sheet of writing space is always a tap away when you launch Repo. Instantly start writing down whatever you need to remember; organize it later.

Key features:

- Format your text and insert photos
- Pinch the screen to change the text size
- Links are turned into beautiful previews
- Paste a Google Maps link to turn it into an actual map
- Paste a link to an image to download & save it
- Draw highlights & annotations with your finger

### 🗺️ Map

Need to record your current location for later reference, or do you just like to keep a record of places you've been to? Repo's map allows you to do just that.

### ☁️ Sync & Privacy

- Automatic backup to iCloud
- Syncs across all your devices
- Uses your personal iCloud, not third-party servers
- No account creation required
- Quick and easy to get started

## Getting Started

You don't need to create an account or log into anything. It's super quick to get started with Repo, and to organize your life with it.

### Development Setup

1. Clone the repository

    ```bash
    git clone https://github.com/alimahouk/repo.git
    cd repo
    ```

2. Open the project in Xcode

    ```bash
    open Repo.xcodeproj
    ```

3. Configure the Project

    - Set your Development Team in Xcode project settings
    - Configure your Bundle Identifier (e.g., "com.yourcompany.repo")
    - Enable iCloud capability in Xcode project settings
    - Configure iCloud Container in Xcode project settings

### Required Configurations

#### iCloud Setup

1. Enable iCloud capability in your Apple Developer account
2. Configure iCloud container identifier in Xcode:
   - Go to Signing & Capabilities
   - Add iCloud capability if not present
   - Check "CloudKit" under Services
   - Configure container with your bundle identifier

#### App Transport Security

The app requires `NSAllowsArbitraryLoads` for:

- Loading web content previews
- Downloading images from various sources
- Displaying map content

Consider restricting this in production by adding specific domains to `NSExceptionDomains`.

## License

This project is licensed under the terms specified in the LICENSE file.

## Author

Created by Ali Mahouk in 2016.
