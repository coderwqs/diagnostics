# diagnosis

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Package
```shell
sudo apt-get install debhelper clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev

dpkg-buildpackage -us -uc

sudo dpkg -i ../diagnostics_1.0.0-1_amd64.deb
```