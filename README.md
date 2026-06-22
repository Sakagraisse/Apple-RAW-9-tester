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

These are preliminary visual findings from a small sample set, not a controlled
benchmark. Results may vary with the camera, ISO, exposure, subject, macOS beta,
and development settings. The camera models currently reported as RAW 9
compatible are listed in the [RAW 9 Supported Cameras](#raw-9-supported-cameras)
section near the end of this README.

### Sample comparisons

Three comparison sets are available in this
[Google Drive folder](https://drive.google.com/drive/folders/1WbI23_YMFsOyB7Q6dzllVdF2xnEdF732?usp=share_link).
Each set contains:

- the original Sony `.ARW` file;
- an Apple RAW 8 JPEG;
- an Apple RAW 9 JPEG;
- a Lightroom JPEG using conventional, non-AI noise reduction with luminance
  set to 30;
- a Lightroom AI Denoise JPEG at 50;
- a Lightroom AI Denoise JPEG at 100.

Except for the stated denoising values, the other Lightroom settings were left
at their defaults. Exposure was increased by either +1 or +2 EV, depending on
the image, because the RAW files were intentionally underexposed to preserve
the highlights. The Apple RAW 8 and RAW 9 outputs use the decoder defaults
reported for each image.

### Initial image-quality impression

For these three samples, the subjective ranking is:

```text
Apple RAW 8 < Lightroom non-AI < Apple RAW 9 < Lightroom AI 100 < Lightroom AI 50
```

Lightroom AI Denoise at 100 produces a better overall result than Apple RAW 9
in these samples, while Lightroom AI Denoise at 50 currently gives the most
balanced result to my eyes. This ranking is based on the default or stated
settings; all of these results could be improved or changed through manual
denoising and sharpening adjustments.

### Decoder behavior

Apple changes the RAW development defaults according to image metadata. In
particular, higher-ISO images receive stronger default noise reduction, so the
numerical settings should not be interpreted independently of the source file.

RAW 9 must be requested explicitly through Core Image. Otherwise,
`CIRAWFilter` continues to use RAW 8 by default.

The currently limited camera-compatibility list suggests that Apple may still
be translating or calibrating existing RAW 8 camera profiles for the RAW 9
pipeline. This is an observation rather than confirmed information about
Apple's implementation.

Unsupported proprietary RAW files can be converted to DNG with Adobe DNG
Converter and then processed through RAW 9. However, conversion may discard or
alter some camera-specific information, including data used for optical
corrections, so native RAW 9 support remains preferable.

### Performance

In the current macOS beta, RAW 9 processing has been observed to take up to
approximately eight times as long as RAW 8. RAW 9 is clearly slower in these
initial tests, but the measured difference may partly result from the specific
processing and export code used by this repository rather than the decoder
alone. More rigorous performance conclusions will require further testing and
future macOS releases.

### What this could enable

Because RAW 9 is exposed through the system Core Image framework, a developer
could theoretically build a free macOS preprocessing utility in the spirit of
Topaz Photo AI or DxO PureRAW, or integrate the same RAW 9 development and
denoising pipeline directly into a photo-editing application. The practical
limits will depend on output quality across more cameras, processing speed,
metadata preservation, and the behavior of future macOS releases.

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
