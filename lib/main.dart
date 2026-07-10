import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Picker Field',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const _DemoPage(),
    );
  }
}

class _DemoPage extends StatefulWidget {
  const _DemoPage();

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  final _controller = TextEditingController(text: '09:30');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Picker Field')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimePickerField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (_, value, __) => Text('Selected: ${value.text}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Time field — inline dropdown panel (HOURS + MINUTES + OK) below field
// ════════════════════════════════════════════════════════════════════
class _TimePickerField extends StatefulWidget {
  const _TimePickerField({
    required this.controller,
    required this.decoration,
  });
  final TextEditingController controller;
  final InputDecoration decoration;
  @override
  State<_TimePickerField> createState() => _TimePickerFieldState();
}
class _TimePickerFieldState extends State<_TimePickerField> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _entry;
  // Focus handling for the open panel so Tab can move between HOURS/MINUTES.
  final _panelScope = FocusScopeNode();
  final _hoursFocus = FocusNode();
  final _minutesFocus = FocusNode();
  int _hour = 0;
  int _minute = 0;
  static const _accent = Color(0xFF4F46E5);
  static const _border = Color(0xFFE5E7EB);
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
    widget.controller.text = '$hh:$mm';
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
                        _TimeNumberDropdown(
                          value: value,
                          count: count,
                          focusNode: focusNode,
                          autofocus: autofocus,
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
                    border: Border.all(color: _border),
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
                              backgroundColor: _accent,
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
          style: const TextStyle(fontSize: 12),
          onTap: _toggle,
          decoration: widget.decoration.copyWith(
            prefixIconConstraints:
            const BoxConstraints(minWidth: 28, minHeight: 0),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 8, right: 4),
              child: Icon(Icons.access_time, size: 15, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
// ════════════════════════════════════════════════════════════════════
// Web-style number dropdown — custom overlay list (no native Material
// menu). Used for HOURS / MINUTES inside the time picker panel.
// ════════════════════════════════════════════════════════════════════
class _TimeNumberDropdown extends StatefulWidget {
  const _TimeNumberDropdown({
    required this.value,
    required this.count,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });
  final int value;
  final int count;
  final ValueChanged<int> onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  State<_TimeNumberDropdown> createState() => _TimeNumberDropdownState();
}
class _TimeNumberDropdownState extends State<_TimeNumberDropdown> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  // Use the focus node passed by the parent if provided, otherwise own one.
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;
  OverlayEntry? _entry;
  late final ScrollController _scrollController;
  int _highlighted = 0;
  bool _focused = false;
  static const _accent = Color(0xFF4F46E5);
  static const _purple = Color(0xFF312E81);
  static const _border = Color(0xFFE5E7EB);
  static const _itemHeight = 36.0;
  static const _panelHeight = 220.0;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode.addListener(_onFocusChange);
  }
  @override
  void dispose() {
    _hide();
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _onFocusChange() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }
  void _toggle() {
    if (_entry != null) {
      _hide();
    } else {
      _open();
    }
  }
  void _open() {
    if (_entry != null) return;
    _highlighted = widget.value;
    _entry = OverlayEntry(builder: _buildPanel);
    Overlay.of(context).insert(_entry!);
    _focusNode.requestFocus();
    _scrollToSelected();
  }
  void _hide() {
    _entry?.remove();
    _entry = null;
  }
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target =
          (widget.value * _itemHeight) - (_panelHeight / 2) + (_itemHeight / 2);
      _scrollController.jumpTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }
  void _moveHighlight(int delta) {
    final next = (_highlighted + delta).clamp(0, widget.count - 1);
    if (next == _highlighted) return;
    _highlighted = next;
    _entry?.markNeedsBuild();
    _scrollHighlightedIntoView();
  }
  void _scrollHighlightedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final c = _scrollController;
      final itemTop = _highlighted * _itemHeight;
      final itemBottom = itemTop + _itemHeight;
      final viewTop = c.offset;
      final viewBottom = viewTop + _panelHeight;
      final maxScroll = c.position.maxScrollExtent;
      if (itemTop < viewTop) {
        c.jumpTo(itemTop.clamp(0.0, maxScroll));
      } else if (itemBottom > viewBottom) {
        c.jumpTo((itemBottom - _panelHeight).clamp(0.0, maxScroll));
      }
    });
  }
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_entry == null) {
        _open();
      } else {
        _moveHighlight(1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_entry == null) {
        _open();
      } else {
        _moveHighlight(-1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (_entry == null) {
        _open();
      } else {
        _pick(_highlighted);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _entry != null) {
      _hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
  void _pick(int v) {
    _hide();
    widget.onChanged(v);
  }
  Widget _buildPanel(BuildContext context) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 110.0;
    final height = box?.size.height ?? 36.0;
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, height + 4),
        child: TapRegion(
          onTapOutside: (_) => _hide(),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: _panelHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.count,
                itemBuilder: (_, i) {
                  final active = i == _highlighted;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) {
                      if (_highlighted == i) return;
                      _highlighted = i;
                      _entry?.markNeedsBuild();
                    },
                    child: InkWell(
                      onTap: () => _pick(i),
                      child: Container(
                        height: _itemHeight,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        color: active ? const Color(0xFFEEF2FF) : Colors.white,
                        child: Text(
                          i.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? _accent : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _handleKey,
        child: InkWell(
          key: _fieldKey,
          canRequestFocus: false,
          onTap: () {
            _focusNode.requestFocus();
            _toggle();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(
                color: _focused ? _purple : _border,
                width: _focused ? 1.8 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
