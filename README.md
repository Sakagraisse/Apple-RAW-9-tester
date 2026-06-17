# Apple RAW 9 Tester

A small macOS SwiftUI app for inspecting and exporting RAW files through
Core Image's `CIRAWFilter`.

The app focuses on RAW 8 / RAW 9 decoder behavior:

- drop one or more RAW/DNG files;
- switch between RAW 8 and RAW 9;
- load the decoder defaults for the selected file;
- edit RAW development settings;
- gray out settings that Core Image reports as unsupported for the current file
  and decoder;
- export the developed photo as a JPEG;
- list the camera models currently reported by Core Image as RAW 9 compatible.

## Requirements

- macOS 27 beta or newer;
- Xcode 27 or the Xcode 27 command line tools.

## Build

```sh
zsh build_raw_options_app.sh
```

The app is generated at:

```text
.build/RAW Options.app
```

## Samples

The `Sample raw` folder contains RAW/DNG files for quick local testing.

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
