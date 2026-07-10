/// A read-only, web-style overlay time picker text field for Flutter.
///
/// Drop [TimePickerField] into any form. It renders as a normal [TextField]
/// and opens a compact HOURS/MINUTES dropdown panel anchored under the field,
/// writing the selected value back as an `HH:mm` string. Full keyboard
/// support: Enter/Space to open, Tab between columns, arrows to move, Escape
/// to close.
library;

export 'src/time_picker_field.dart';
export 'src/time_number_dropdown.dart' show TimeNumberDropdown;
