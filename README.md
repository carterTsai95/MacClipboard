# MacClipboard

A powerful clipboard management application for macOS that helps you manage and organize your clipboard history.

## Features

- 📋 Clipboard history management
- 🔍 Quick search through clipboard items
- 🖼️ Image preview support
- ⌨️ Keyboard shortcuts for quick access
- 🎯 Easy-to-use menu bar interface
- 🔒 Secure clipboard management

## Requirements

- macOS 13.0 or later
- Xcode 16.2 or later
- Swift 5.9 or later

## Installation

1. Clone the repository:
```bash
git clone https://github.com/carterTsai95/MacClipboard.git
```

2. Open the project in Xcode:
```bash
cd MacClipboard
open MacClipboard.xcodeproj
```

3. Build and run the project in Xcode

## Development

### Project Structure

```
MacClipboard/
├── Sources/
│   └── MacClipboard/
│       ├── Models/
│       │   ├── ClipboardItem.swift
│       │   └── ClipboardManager.swift
│       ├── Views/
│       │   ├── ContentView.swift
│       │   ├── ImagePreviewView.swift
│       │   └── MenuBarExtra.swift
│       ├── Services/
│       │   └── ClipboardService.swift
│       └── MacClipboardApp.swift
└── Tests/
    └── MacClipboardTests/
        ├── ClipboardServiceTests.swift
        └── ClipboardManagerTests.swift
```

### Building

```bash
xcodebuild -project MacClipboard.xcodeproj -scheme MacClipboard -configuration Debug
```

### Testing

```bash
xcodebuild test -project MacClipboard.xcodeproj -scheme MacClipboard -destination 'platform=macOS'
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all contributors who have helped shape this project
- Inspired by the need for better clipboard management on macOS

## Contact

Project Link: [https://github.com/carterTsai95/MacClipboard](https://github.com/carterTsai95/MacClipboard) 