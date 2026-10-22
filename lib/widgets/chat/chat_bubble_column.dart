import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shrink-wraps bubble content to the widest child, then places [trailing]
/// (the time / edited row) on the ambient trailing edge.
///
/// A normal [Column] cannot do both: [CrossAxisAlignment.stretch] expands to
/// the max bubble width, and [Align] expands the same way when its max width
/// is finite. Two layout passes keep short messages narrow.
class ChatBubbleColumn extends MultiChildRenderObjectWidget {
  final bool hasTrailing;

  ChatBubbleColumn({
    super.key,
    List<Widget> content = const [],
    Widget? trailing,
  }) : hasTrailing = trailing != null,
       super(children: <Widget>[...content, if (trailing != null) trailing]);

  @override
  RenderChatBubbleColumn createRenderObject(BuildContext context) {
    return RenderChatBubbleColumn(
      hasTrailing: hasTrailing,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderChatBubbleColumn renderObject,
  ) {
    renderObject
      ..hasTrailing = hasTrailing
      ..textDirection = Directionality.of(context);
  }
}

class ChatBubbleColumnParentData extends ContainerBoxParentData<RenderBox> {}

class RenderChatBubbleColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ChatBubbleColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ChatBubbleColumnParentData> {
  RenderChatBubbleColumn({
    required bool hasTrailing,
    required TextDirection textDirection,
  }) : _hasTrailing = hasTrailing,
       _textDirection = textDirection;

  bool _hasTrailing;
  TextDirection _textDirection;

  bool get hasTrailing => _hasTrailing;
  set hasTrailing(bool value) {
    if (_hasTrailing == value) return;
    _hasTrailing = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ChatBubbleColumnParentData) {
      child.parentData = ChatBubbleColumnParentData();
    }
  }

  @override
  void performLayout() {
    final maxWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;
    final loose = BoxConstraints(maxWidth: maxWidth);

    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(loose, parentUsesSize: true);
      final childWidth = child.size.width;
      if (childWidth.isFinite && childWidth > width) width = childWidth;
      child = childAfter(child);
    }
    if (width < constraints.minWidth) width = constraints.minWidth;
    if (constraints.hasBoundedWidth && width > constraints.maxWidth) {
      width = constraints.maxWidth;
    }

    final rtl = _textDirection == TextDirection.rtl;
    final last = lastChild;
    var y = 0.0;
    child = firstChild;
    while (child != null) {
      final trailing = _hasTrailing && identical(child, last);
      if (trailing) {
        child.layout(
          BoxConstraints(maxWidth: width.isFinite ? width : maxWidth),
          parentUsesSize: true,
        );
      } else if (width.isFinite) {
        child.layout(
          BoxConstraints.tightFor(width: width),
          parentUsesSize: true,
        );
      } else {
        child.layout(loose, parentUsesSize: true);
      }
      final box = child.parentData! as ChatBubbleColumnParentData;
      final dx = trailing && !rtl ? width - child.size.width : 0.0;
      box.offset = Offset(dx.isFinite ? dx : 0, y);
      y += child.size.height;
      child = box.nextSibling;
    }

    size = constraints.constrain(Size(width.isFinite ? width : 0, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
