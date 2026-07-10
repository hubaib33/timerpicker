import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Web-style number dropdown — a custom overlay list (no native Material menu).
///
/// Used internally by [TimePickerField] to render the HOURS / MINUTES columns.
/// Supports keyboard control: ArrowUp/ArrowDown to move the highlight,
/// Enter/Space to pick, Escape to close.
class TimeNumberDropdown extends StatefulWidget {
  const TimeNumberDropdown({
    super.key,
    required this.value,
    required this.count,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.accent = const Color(0xFF4F46E5),
    this.focusColor = const Color(0xFF312E81),
    this.borderColor = const Color(0xFFE5E7EB),
    this.highlightColor = const Color(0xFFEEF2FF),
  });

  /// Currently selected value (0-based).
  final int value;

  /// Number of selectable items (values run `0 .. count - 1`).
  final int count;

  /// Called with the newly picked value.
  final ValueChanged<int> onChanged;

  /// Optional external focus node so the parent can drive Tab traversal.
  final FocusNode? focusNode;

  /// Whether this dropdown should grab focus when first built.
  final bool autofocus;

  /// Accent color for the selected item text.
  final Color accent;

  /// Border color used when the control has keyboard focus.
  final Color focusColor;

  /// Idle border color.
  final Color borderColor;

  /// Background color of the highlighted row in the open list.
  final Color highlightColor;

  @override
  State<TimeNumberDropdown> createState() => _TimeNumberDropdownState();
}

class _TimeNumberDropdownState extends State<TimeNumberDropdown> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();

  // Use the focus node passed by the parent if provided, otherwise own one.
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;

  OverlayEntry? _entry;
  late final ScrollController _scrollController;
  int _highlighted = 0;
  bool _focused = false;

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
                border: Border.all(color: widget.borderColor),
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
                        color: active ? widget.highlightColor : Colors.white,
                        child: Text(
                          i.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? widget.accent : Colors.black87,
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
                color: _focused ? widget.focusColor : widget.borderColor,
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
