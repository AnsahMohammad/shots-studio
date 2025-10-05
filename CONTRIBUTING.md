# Contributing to Shots Studio

Thank you for your interest in contributing to **Shots Studio**! We welcome contributions of all kinds — whether it's code, bug reports, feature ideas, documentation improvements, or community support.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Development Guidelines](#development-guidelines)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Getting Help](#getting-help)
- [Recognition](#recognition)

## Code of Conduct

This project follows a simple code of conduct: **Be respectful and constructive**. We're building something amazing together, and everyone deserves to be treated with kindness and respect.

## Getting Started

Before you start contributing, please:

1. **Check existing issues** to see if your bug report or feature request already exists
2. **Create an issue first** before starting any significant work — this helps us track progress and avoid duplicate efforts
3. **Read through this guide** to understand our development process

## Development Setup

### Prerequisites

- **Flutter SDK**: Version 3.7.2 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio/VS Code**: For development and debugging
- **Git**: For version control
- **Python 3.x**: For the web component (if working on web features)

### Setting Up Your Development Environment

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/your-username/shots-studio.git
   cd shots-studio
   ```

2. **Set up Git hooks** (required for version management):
   ```bash
   git config core.hooksPath scripts/git-hooks
   ```

3. **Navigate to the Flutter app directory**:
   ```bash
   cd shots_studio
   ```

4. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

5. **Verify your setup**:
   ```bash
   flutter doctor
   ```

6. **Run the app**:
   ```bash
   # F-Droid flavor (recommended for development)
   flutter run --flavor fdroid --dart-define=BUILD_SOURCE=fdroid
   
   # Or run specific flavors
   flutter run --flavor github --dart-define=BUILD_SOURCE=github
   flutter run --flavor playstore --dart-define=BUILD_SOURCE=playstore
   ```

### Build Flavors

This project supports different build flavors for different distribution sources. See [`docs/BUILD_FLAVORS.md`](docs/BUILD_FLAVORS.md) for detailed information.

**Quick Reference:**
- **F-Droid (recommended)**: `flutter run --flavor fdroid --dart-define=BUILD_SOURCE=fdroid`
- **GitHub**: `flutter run --flavor github --dart-define=BUILD_SOURCE=github`
- **Play Store**: `flutter run --flavor playstore --dart-define=BUILD_SOURCE=playstore`

The build source affects:
- Update checking behavior (enabled for GitHub, disabled for F-Droid/Play Store)
- Analytics tracking
- About section display in the app

### Project Structure

```
shots-studio/
├── shots_studio/           # Main Flutter application
│   ├── lib/
│   │   ├── main.dart      # App entry point
│   │   ├── models/        # Data models (screenshot, collection, etc.)
│   │   ├── screens/       # UI screens
│   │   ├── services/      # Business logic & API services
│   │   ├── widgets/       # Reusable UI components
│   │   └── utils/         # Utility functions
│   ├── test/              # Unit and widget tests
│   ├── android/           # Android-specific configuration
│   └── pubspec.yaml       # Flutter dependencies
├── web/                   # Discontinued Flask web version
├── docs/                  # Documentation and website
├── scripts/               # Build scripts and Git hooks
└── metadata/              # App store metadata
```

## How to Contribute

### 🐛 Reporting Bugs

1. **Search existing issues** to avoid duplicates
2. **Create a new issue** with the "bug" label
3. **Include the following information**:
   - Device and Android version
   - App version (found in Settings)
   - Steps to reproduce the bug
   - Expected vs. actual behavior
   - Screenshots or error logs (if applicable)
   - Whether you have dev mode enabled

### 💡 Feature Requests

1. **Check existing issues** for similar requests
2. **Create a new issue** with the "enhancement" label
3. **Describe**:
   - The problem you're trying to solve
   - Your proposed solution
   - Why this would benefit other users
   - Any implementation ideas (optional)

### 🔧 Code Contributions

1. **Create or comment on an issue** describing what you want to work on
2. **Wait for assignment** — this helps us coordinate efforts and provide guidance
3. **Fork the repository** and create a feature branch
4. **Implement your changes** following our guidelines
5. **Submit a pull request** referencing the issue

## Development Guidelines

### Code Style

- **Flutter/Dart**: Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Python**: Use [Black](https://black.readthedocs.io/) formatter for consistent code formatting
- **Naming**: Use descriptive names for variables, functions, and classes
- **Comments**: Write clear comments for complex logic, but prefer self-documenting code

### Architecture Patterns

- **State Management**: Use Flutter's built-in state management (setState, StatefulWidget)
- **Services**: Business logic should be in service classes (`lib/services/`)
- **Models**: Data structures should be in model classes (`lib/models/`)
- **Separation of Concerns**: Keep UI, business logic, and data access separate

### Git Workflow

1. **Branch Naming**: Use descriptive names like `feature/ai-search-improvements` or `fix/screenshot-loading-issue`
2. **Commit Messages**: Write clear, concise commit messages explaining what and why
3. **Small Commits**: Make atomic commits that can be easily reviewed
4. **Rebase**: Prefer rebasing over merging for cleaner history

### Key Development Areas

- **Flutter App** (`shots_studio/`): Main mobile application
- **AI Integration**: Gemini API service integration
- **Database**: Local storage and data management
- **UI/UX**: Material Design components and user experience
- **Performance**: Memory management and background processing
- **Documentation**: User guides and API documentation

## Testing

We follow **Test-Driven Development (TDD)** principles:

### Writing Tests

1. **Unit Tests**: Test individual functions and classes
   ```bash
   flutter test test/unit/
   ```

2. **Widget Tests**: Test UI components
   ```bash
   flutter test test/widget/
   ```

3. **Integration Tests**: Test complete user flows
   ```bash
   flutter test test/integration/
   ```

### Test Requirements

- **New Features**: Must include corresponding tests
- **Bug Fixes**: Should include regression tests
- **Coverage**: Aim for meaningful test coverage, not just high percentages
- **Test Quality**: Tests should be readable, maintainable, and reliable

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/gemini_service_test.dart
```

## Submitting Changes

### Pull Request Process

1. **Create your PR from a fork** (not a direct branch)
2. **Reference the issue** in your PR description
3. **Include a clear description** of your changes
4. **Add screenshots** for UI changes
5. **Ensure tests pass** and add new tests as needed
6. **Update documentation** if your changes affect user-facing features

### PR Checklist

- [ ] I have read the contributing guidelines
- [ ] My code follows the project's style guidelines
- [ ] I have added tests for my changes
- [ ] All existing tests still pass
- [ ] I have updated documentation where necessary
- [ ] My commits have clear, descriptive messages
- [ ] I have referenced the related issue in my PR

### Review Process

1. **Automated Checks**: Your PR will be automatically tested
2. **Code Review**: Maintainers will review your code and provide feedback
3. **Iterate**: Address any feedback and update your PR
4. **Merge**: Once approved, your changes will be merged

## Getting Help

If you need help or have questions:

- **GitHub Discussions**: Use [GitHub Discussions](https://github.com/your-username/shots-studio/discussions) for general questions
- **Issues**: Create an issue for specific problems or bugs
- **Email**: Reach out personally via email (check the main README for contact info)

## Recognition

We value all contributions! Contributors will be:

- **Acknowledged** in our [Contributors](#contributors) section of the README
- **Credited** in release notes for significant contributions
- **Appreciated** by the entire community

### Contributors

A huge thanks to everyone who has contributed to Shots Studio! 🎉

<!-- This section will be automatically updated -->

---

## Development Tips

### Useful Commands

```bash
# Clean build files
flutter clean && flutter pub get

# Run with verbose logging
flutter run -v

# Build APK for testing (F-Droid flavor)
flutter build apk --debug --flavor fdroid --dart-define=BUILD_SOURCE=fdroid

# Build specific flavors
flutter build apk --release --flavor fdroid --dart-define=BUILD_SOURCE=fdroid
flutter build apk --release --flavor github --dart-define=BUILD_SOURCE=github
flutter build apk --release --flavor playstore --dart-define=BUILD_SOURCE=playstore

# Build test release version (separate package name: com.ansah.shots_studio.dog)
flutter run apk --release --flavor dog --dart-define=BUILD_SOURCE=github

# Play Store flavor (most common for app bundles)
flutter build appbundle --release --flavor playstore --dart-define=BUILD_SOURCE=playstore


# Use the convenience build script
chmod +x build_flavors.sh
./build_flavors.sh fdroid debug      # F-Droid debug build
./build_flavors.sh github release    # GitHub release build
./build_flavors.sh dog release       # Test release build (separate package)

# Check for dependency updates
flutter pub outdated

# Generate code (if using code generation)
flutter packages pub run build_runner build

# Run with specific device
flutter run -d <device-id>
```

### Debugging

- **Enable Dev Mode**: In app settings for additional debugging features
- **Check Logs**: Use `flutter logs` or Android Studio's logcat
- **Performance**: Use Flutter Inspector for UI debugging
- **Memory**: Monitor memory usage during AI processing

### Common Gotchas

- **API Keys**: Don't commit API keys — use environment variables or local config
- **File Paths**: Use `path_provider` for cross-platform file operations
- **Background Processing**: Test on real devices, not just emulators
- **Permissions**: Android permissions need to be declared and requested properly

---

Thank you for contributing to Shots Studio! Together, we're making screenshot management better for everyone. 🚀
