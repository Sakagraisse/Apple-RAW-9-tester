# Apple RAW 9 Tester

A small macOS SwiftUI app for inspecting and exporting RAW files through
Core Image's `CIRAWFilter`.

## Disclaimer

> [!IMPORTANT]
> **Apple RAW 9 Tester requires macOS 27 beta or newer. It will not run on
> macOS 26 or earlier.**

This is an experimental, unofficial utility for testing Apple Core Image's
RAW 8 and RAW 9 decoders. It is not affiliated with or endorsed by Apple.
Decoder behavior, camera compatibility, output quality, and performance may
change between macOS beta releases.

Keep your original RAW files and do not rely on this app as the only step in a
production workflow.

## Installation

Download the latest
[Apple RAW 9 Tester release](https://github.com/Sakagraisse/Apple-RAW-9-tester/releases/latest),
unzip it, and move `Apple RAW 9 Tester.app` to the Applications folder.

The downloadable app is signed ad hoc but is not notarized with an Apple
Developer ID. Gatekeeper may therefore block its first launch. Use either of
the following methods.

### Graphical method

1. Open `Apple RAW 9 Tester.app` once and dismiss the macOS warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the security message concerning Apple RAW 9 Tester.
4. Click **Open Anyway**, authenticate if requested, then confirm **Open**.

This exception is normally required only for the first launch.

### Terminal method

After moving the app to `/Applications`, remove its quarantine attribute:

```sh
xattr -dr com.apple.quarantine "/Applications/Apple RAW 9 Tester.app"
```

You can then open the app normally.

## Findings

_Findings from RAW 8/RAW 9 image-quality, compatibility, and performance tests
will be documented here._

## Features

The app focuses on RAW 8 / RAW 9 decoder behavior:

- drop one or more RAW/DNG files;
- browse imported files with thumbnails;
- switch between RAW 8 and RAW 9;
- load the decoder defaults for the selected file;
- edit RAW development settings;
- gray out settings that Core Image reports as unsupported for the current file
  and decoder;
- export the developed photo as JPEG or 8-bit PNG;
- list the camera models currently reported by Core Image as RAW 9 compatible.

## Building from source

Building requires **macOS 27 beta or newer** and Xcode 27 or the Xcode 27
command line tools.

Run:

```sh
zsh build_raw_options_app.sh
```

The app is generated at:

```text
.build/Apple RAW 9 Tester.app
```

### Packaging a standalone release

Create a GitHub-ready ZIP archive with:

```sh
zsh package_release.sh
```

The archive and its SHA-256 checksum are generated in `dist/`. The app is
self-contained and does not require Xcode on the destination Mac.

By default, the app is signed ad hoc. macOS may therefore require
Control-clicking the app and choosing **Open** the first time. For a
Developer ID release, provide a signing identity:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  zsh package_release.sh
```

### Local samples

Local RAW files can be placed in `Sample raw` for quick testing. This folder is
ignored by Git so large camera originals are not accidentally committed.

## RAW 9 Supported Cameras

This list is generated from `CIRAWFilter.supportedCameraModels(with: .version9)`
on the current macOS 27 beta SDK used to build this project.

<details>
<summary>Canon (18)</summary>

- Canon EOS 5D Mark II
- Canon EOS 5D Mark III
- Canon EOS 5D Mark IV
- Canon EOS 6D
- Canon EOS 6D Mark II
- Canon EOS 1500D
- Canon EOS 2000D
- Canon EOS R
- Canon EOS R1
- Canon EOS R5
- Canon EOS R5C
- Canon EOS R6
- Canon EOS R6 Mark II
- Canon EOS R8
- Canon EOS R50
- Canon EOS Rebel T7
- Canon EOS RP
- Canon R100

</details>

<details>
<summary>Fujifilm (2)</summary>

- Fujifilm X-T5
- Fujifilm X-T50

</details>

<details>
<summary>Leica (1)</summary>

- Leica D-Lux 8

</details>

<details>
<summary>Nikon (5)</summary>

- Nikon D750
- Nikon D850
- Nikon Z 6 2
- Nikon Z fc
- Nikon Z50

</details>

<details>
<summary>Panasonic (4)</summary>

- Panasonic LUMIX DC-G100
- Panasonic LUMIX DC-G110
- Panasonic LUMIX DC-S5M2
- Panasonic LUMIX DC-S5M2X

</details>

<details>
<summary>Sony (16)</summary>

- Sony Alpha ILCE-7 II
- Sony Alpha ILCE-7C
- Sony Alpha ILCE-7C II
- Sony Alpha ILCE-7M IV
- Sony Alpha ILCE-7M3
- Sony Alpha ILCE-7M4
- Sony Alpha ILCE-7R III
- Sony Alpha ILCE-7R III A
- Sony Alpha ILCE-7R V
- Sony Alpha ILCE-7S III
- Sony Alpha ILCE-6100
- Sony Alpha ILCE-6100A
- Sony Alpha ILCE-6400
- Sony Alpha ILCE-6400A
- Sony Alpha ILCE-6700
- Sony Alpha ZV-E10

</details>
