import 'package:flutter/material.dart';

class MemberInfo {
  final String id;
  final String displayName;

  MemberInfo({required this.id, required this.displayName});
}

class NoteInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isLoading;
  final List<MemberInfo> members;

  const NoteInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    required this.members,
  });

  @override
  State<NoteInput> createState() => _NoteInputState();
}

class _NoteInputState extends State<NoteInput> {
  late final _MentionTextEditingController _controller;
  final _focusNode = FocusNode();

  bool _hasText = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;
  String? _errorMessage;

  List<MemberInfo> _filteredMembers = [];
  bool _showSuggestions = false;
  bool _isHoveringDropdown = false;

  @override
  void initState() {
    super.initState();
    _controller = _MentionTextEditingController();
    _controller.updateMembers(widget.members.map((m) => m.displayName).toList());
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(NoteInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.members != oldWidget.members) {
      _controller.updateMembers(widget.members.map((m) => m.displayName).toList());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && !_isHoveringDropdown) {
      // Delay hiding to allow click on suggestion to register first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus && !_isHoveringDropdown) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    setState(() {
      _hasText = text.trim().isNotEmpty;
      _errorMessage = null;
    });

    // Check if we're typing a mention
    if (cursorPos > 0 && cursorPos <= text.length) {
      // Find the @ before cursor
      int atIndex = -1;
      for (int i = cursorPos - 1; i >= 0; i--) {
        if (text[i] == '@') {
          atIndex = i;
          break;
        } else if (text[i] == ' ' || text[i] == '\n') {
          break;
        }
      }

      if (atIndex >= 0) {
        final query = text.substring(atIndex + 1, cursorPos).toLowerCase();
        _mentionStartIndex = atIndex;
        _mentionQuery = query;
        _showMentionSuggestions();
        return;
      }
    }

    setState(() {
      _showSuggestions = false;
      _filteredMembers = [];
    });
    _mentionStartIndex = -1;
    _mentionQuery = '';
  }

  void _showMentionSuggestions() {
    List<MemberInfo> filtered;
    if (_mentionQuery.isEmpty) {
      filtered = widget.members;
    } else {
      filtered = widget.members
          .where((m) => m.displayName.toLowerCase().contains(_mentionQuery))
          .toList();
    }

    setState(() {
      _filteredMembers = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectMention(MemberInfo member) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    // Replace @query with @Name
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = cursorPos < text.length ? text.substring(cursorPos) : '';

    final mentionText = '@${member.displayName} ';

    final newText = beforeMention + mentionText + afterMention;
    final newCursorPos = beforeMention.length + mentionText.length;

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newCursorPos);

    setState(() {
      _showSuggestions = false;
      _filteredMembers = [];
      _isHoveringDropdown = false;
    });
    _focusNode.requestFocus();
  }

  List<String> _extractMentions(String text) {
    // Match @mentions against actual member names (handles spaces)
    final mentions = <String>[];
    final memberNames = widget.members.map((m) => m.displayName).toList();

    // Sort by length (longest first) to match "John Smith" before "John"
    memberNames.sort((a, b) => b.length.compareTo(a.length));

    var searchText = text;
    for (final name in memberNames) {
      final pattern = '@$name';
      if (searchText.toLowerCase().contains(pattern.toLowerCase())) {
        mentions.add(name);
        // Remove this mention to avoid double-counting
        searchText = searchText.replaceAll(RegExp(RegExp.escape(pattern), caseSensitive: false), '');
      }
    }

    // Also catch any @word that wasn't matched (for invalid mention detection)
    final unmatchedRegex = RegExp(r'@(\w+)');
    for (final match in unmatchedRegex.allMatches(text)) {
      final name = match.group(1)!;
      if (!mentions.any((m) => m.toLowerCase() == name.toLowerCase())) {
        mentions.add(name);
      }
    }

    return mentions;
  }

  String? _validateMentions(String text) {
    final mentions = _extractMentions(text);
    final memberNames = widget.members
        .map((m) => m.displayName.toLowerCase())
        .toSet();

    for (final mention in mentions) {
      if (!memberNames.contains(mention.toLowerCase())) {
        return '@$mention is not a member of your household';
      }
    }
    return null;
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Validate mentions
    final error = _validateMentions(text);
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    widget.onSubmit(text);
    _controller.clear();
    setState(() {
      _hasText = false;
      _errorMessage = null;
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: _errorMessage != null
                ? Border.all(color: Theme.of(context).colorScheme.error)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Add a note... (use @ to mention)',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _hasText ? _submit : null,
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ],
          ),
        ),

        // Mention suggestions dropdown (below input)
        if (_showSuggestions && _filteredMembers.isNotEmpty)
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringDropdown = true),
            onExit: (_) => setState(() => _isHoveringDropdown = false),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    children: _filteredMembers.map((member) {
                      return InkWell(
                        onTap: () {
                          _selectMention(member);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  member.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(member.displayName),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// Custom controller that styles @mentions in a different color
class _MentionTextEditingController extends TextEditingController {
  List<String> memberNames = [];

  void updateMembers(List<String> names) {
    memberNames = names;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (text.isEmpty || !text.contains('@')) {
      return TextSpan(text: text, style: style);
    }

    // Find all mention positions
    final mentionSpans = <({int start, int end, String match})>[];

    // Sort member names by length (longest first) for greedy matching
    final sortedNames = [...memberNames]..sort((a, b) => b.length.compareTo(a.length));

    var searchText = text.toLowerCase();
    for (final name in sortedNames) {
      final pattern = '@${name.toLowerCase()}';
      int startIndex = 0;
      while (true) {
        final index = searchText.indexOf(pattern, startIndex);
        if (index == -1) break;

        // Check if followed by word boundary (space, end, or punctuation)
        final endIndex = index + pattern.length;
        if (endIndex >= text.length || !RegExp(r'\w').hasMatch(text[endIndex])) {
          mentionSpans.add((start: index, end: endIndex, match: text.substring(index, endIndex)));
          // Mark as used to avoid overlap
          searchText = searchText.substring(0, index) +
              ' ' * pattern.length +
              searchText.substring(endIndex);
        }
        startIndex = endIndex;
      }
    }

    // Also match any @word pattern for partial mentions being typed
    final wordRegex = RegExp(r'@\w+');
    for (final match in wordRegex.allMatches(text)) {
      // Only add if not overlapping with existing spans
      if (!mentionSpans.any((s) =>
          (match.start >= s.start && match.start < s.end) ||
          (match.end > s.start && match.end <= s.end))) {
        mentionSpans.add((start: match.start, end: match.end, match: match.group(0)!));
      }
    }

    if (mentionSpans.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    // Sort by start position
    mentionSpans.sort((a, b) => a.start.compareTo(b.start));

    final List<InlineSpan> children = [];
    int lastEnd = 0;

    for (final span in mentionSpans) {
      // Add text before the mention
      if (span.start > lastEnd) {
        children.add(TextSpan(
          text: text.substring(lastEnd, span.start),
          style: style,
        ));
      }

      // Add the mention with special styling
      children.add(TextSpan(
        text: span.match,
        style: style?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ));

      lastEnd = span.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return TextSpan(children: children, style: style);
  }
}
