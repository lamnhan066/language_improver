import 'package:flutter/material.dart';

/// Expandable text widget that shows long text with expand/collapse functionality
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final int truncateLength;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 3,
    // ignore: unused_element_parameter
    this.truncateLength = 100,
  });

  @override
  State<ExpandableText> createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textLength = widget.text.length;
    final isLong = textLength > widget.truncateLength;

    if (!isLong) {
      return Text(widget.text, style: widget.style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _isExpanded
                    ? widget.text
                    : '${widget.text.substring(0, widget.truncateLength)}...',
                style: widget.style,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (isLong)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$textLength chars',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isExpanded ? 'Show less' : 'Show more',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
