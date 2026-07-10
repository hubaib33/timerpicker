import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'time_number_dropdown.dart';

/// A read-only text field that opens a compact, web-style overlay panel with
/// HOURS and MINUTES dropdowns for picking a time.
///
/// The selected value is written back into [controller] as a zero-padded
/// `HH:mm` string (24-hour). Tapping the field — or pressing Enter/Space while
/// it is focused — opens the panel; Tab moves between the HOURS and MINUTES
/// dropdowns, Enter confirms, and Escape closes.
///
/// It renders as a normal [TextField], so it drops straight into an existing
/// form and honours a supplied [decoration].
///
/// ```dart
/// TimePickerField(
///   controller: myController,
///   decoration: const InputDecoration(labelText: 'TIME'),
/// )
/// ```
class TimePickerField extends StatefulWidget {
  const TimePickerField({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.textStyle = const TextStyle(fontSize: 12),
    this.accent = const Color(0xFF4F46E5),
    this.borderColor = const Color(0xFFE5E7EB),
    this.showPrefixIcon = true,
    this.prefixIcon = Icons.access_time,
    this.onChanged,
  });

  /// Holds the selected time as an `HH:mm` string. Seed it with an initial
  /// value if you want the panel to open on a specific time.
  final TextEditingController controller;

  /// Decoration applied to the underlying [TextField].
  final InputDecoration decoration;

  /// Text style of the value shown inside the field.
  final TextStyle textStyle;

  /// Accent color used by the OK button and the selected list items.
  final Color accent;

  /// Border color for the panel and dropdowns.
  final Color borderColor;

  /// Whether to show the leading clock icon.
  final bool showPrefixIcon;

  /// Icon shown as the prefix when [showPrefixIcon] is true.
  final IconData prefixIcon;

  /// Called with the confirmed `HH:mm` string when the user presses OK.
  final ValueChanged<String>? onChanged;

  @override
  State<TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<TimePickerField> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _entry;

  // Focus handling for the open panel so Tab can move between HOURS/MINUTES.
  final _panelScope = FocusScopeNode();
  final _hoursFocus = FocusNode();
  final _minutesFocus = FocusNode();

  int _hour = 0;
  int _minute = 0;

  @override
  void dispose() {
    _hide();
    _panelScope.dispose();
    _hoursFocus.dispose();
    _minutesFocus.dispose();
    super.dispose();
  }

  void _seedFromText() {
    final now = TimeOfDay.now();
    _hour = now.hour;
    _minute = now.minute;
    final parts = widget.controller.text.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts[1].trim());
      if (h != null && h >= 0 && h < 24) _hour = h;
      if (m != null && m >= 0 && m < 60) _minute = m;
    }
  }

  void _toggle() {
    if (_entry != null) {
      _hide();
      return;
    }
    _seedFromText();
    _entry = OverlayEntry(builder: _buildPanel);
    Overlay.of(context).insert(_entry!);
    // Move focus into the panel so Tab works between the dropdowns.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry != null) _hoursFocus.requestFocus();
    });
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  void _apply() {
    final hh = _hour.toString().padLeft(2, '0');
    final mm = _minute.toString().padLeft(2, '0');
    final value = '$hh:$mm';
    widget.controller.text = value;
    widget.onChanged?.call(value);
    _hide();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_entry != null) {
        _hide();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_entry == null) _toggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildPanel(BuildContext context) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldWidth = box?.size.width ?? 240.0;
    final fieldHeight = box?.size.height ?? 40.0;
    final panelWidth = fieldWidth < 250.0 ? 250.0 : fieldWidth;
    return Positioned(
      width: panelWidth,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, fieldHeight + 4),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          // FocusScope keeps Tab traversal inside the open panel.
          child: FocusScope(
            node: _panelScope,
            child: StatefulBuilder(
              builder: (context, setPanel) {
                Widget dd(String title, int value, int count,
                    ValueChanged<int> onPicked,
                    {required FocusNode focusNode, bool autofocus = false}) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        const SizedBox(height: 4),
                        TimeNumberDropdown(
                          value: value,
                          count: count,
                          focusNode: focusNode,
                          autofocus: autofocus,
                          accent: widget.accent,
                          borderColor: widget.borderColor,
                          onChanged: (v) => setPanel(() => onPicked(v)),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: widget.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          dd('HOURS', _hour, 24, (v) => _hour = v,
                              focusNode: _hoursFocus, autofocus: true),
                          const SizedBox(width: 12),
                          dd('MINUTES', _minute, 60, (v) => _minute = v,
                              focusNode: _minutesFocus),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _hide,
                            child: const Text('CANCEL'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _apply,
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _handleKey,
        child: TextField(
          key: _fieldKey,
          controller: widget.controller,
          readOnly: true,
          style: widget.textStyle,
          onTap: _toggle,
          decoration: widget.showPrefixIcon
              ? widget.decoration.copyWith(
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 28, minHeight: 0),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Icon(widget.prefixIcon,
                        size: 15, color: Colors.grey),
                  ),
                )
              : widget.decoration,
        ),
      ),
    );
  }
}
