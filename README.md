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
