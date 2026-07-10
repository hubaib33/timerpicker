# timepickerfield

A read-only, **web-style overlay time picker text field** for Flutter. It looks
like a normal `TextField`, but tapping it opens a compact panel with **HOURS**
and **MINUTES** dropdowns anchored right under the field. The selected value is
written back into your controller as a zero-padded `HH:mm` (24-hour) string.

Repo: https://github.com/hubaib33/timerpicker

## Features

- 📎 Drops into any form — renders as a real `TextField`, honours your `InputDecoration`.
- 🕒 Overlay panel with scrollable HOURS (0–23) and MINUTES (0–59) dropdowns.
- ⌨️ Full keyboard support: Enter/Space to open, Tab between columns, ↑/↓ to move, Enter to pick, Esc to close.
- 🎨 Configurable accent / border colors and prefix icon.

## Install (from GitHub)

```yaml
dependencies:
  timepickerfield:
    git:
      url: https://github.com/hubaib33/timerpicker.git
      ref: main
```

Then `flutter pub get`.

## Usage

```dart
import 'package:timepickerfield/timepickerfield.dart';

TimePickerField(
  controller: myController,          // receives 'HH:mm'
  decoration: const InputDecoration(labelText: 'TIME'),
  onChanged: (value) => print(value),
)
```

## `TimePickerField` API

| Parameter        | Type                    | Default             |
| ---------------- | ----------------------- | ------------------- |
| `controller`     | `TextEditingController` | **required**        |
| `decoration`     | `InputDecoration`       | `InputDecoration()` |
| `textStyle`      | `TextStyle`             | `fontSize: 12`      |
| `accent`         | `Color`                 | `0xFF4F46E5`        |
| `borderColor`    | `Color`                 | `0xFFE5E7EB`        |
| `showPrefixIcon` | `bool`                  | `true`              |
| `prefixIcon`     | `IconData`              | `Icons.access_time` |
| `onChanged`      | `ValueChanged<String>?` | `null`              |

## License

MIT
