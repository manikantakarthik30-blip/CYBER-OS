import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TerminalLogEntry {
  final String text;
  final String type; // INFO, SCANNING, FOUND, PASS, COMPLETE

  TerminalLogEntry({required this.text, this.type = 'INFO'});
}

class TerminalLogWidget extends StatefulWidget {
  final List<String> rawLogs;
  final double height;
  final bool showCursor;

  const TerminalLogWidget({
    super.key,
    required this.rawLogs,
    this.height = 180,
    this.showCursor = true,
  });

  @override
  State<TerminalLogWidget> createState() => _TerminalLogWidgetState();
}

class _TerminalLogWidgetState extends State<TerminalLogWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    if (widget.showCursor) {
      _cursorTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
        if (mounted) setState(() => _cursorVisible = !_cursorVisible);
      });
    }
  }

  @override
  void didUpdateWidget(covariant TerminalLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rawLogs.length != oldWidget.rawLogs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.void_black,
        border: Border.all(color: AppColors.signal_dim, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: widget.rawLogs.isEmpty
          ? Row(
              children: [
                Text(
                  '> System idle. Awaiting scan target...',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.text_ghost,
                  ),
                ),
                if (widget.showCursor && _cursorVisible)
                  Container(
                    width: 7,
                    height: 13,
                    margin: const EdgeInsets.only(left: 4),
                    color: AppColors.signal,
                  ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.rawLogs.length + (widget.showCursor ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.rawLogs.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Text(
                          '> ',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppColors.signal,
                          ),
                        ),
                        if (_cursorVisible)
                          Container(
                            width: 7,
                            height: 13,
                            color: AppColors.signal,
                          ),
                      ],
                    ),
                  );
                }

                final log = widget.rawLogs[index];
                final color = _getLogColor(log);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: color,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getLogColor(String log) {
    final lower = log.toLowerCase();
    if (lower.contains('critical') || lower.contains('fail') || lower.contains('found 0') == false && lower.contains('found')) {
      return AppColors.critical;
    } else if (lower.contains('warning') || lower.contains('cve')) {
      return AppColors.high;
    } else if (lower.contains('pass') || lower.contains('secure') || lower.contains('✓')) {
      return AppColors.safe;
    } else if (lower.contains('initiating') || lower.contains('scanning')) {
      return AppColors.signal;
    } else if (lower.contains('complete')) {
      return AppColors.text_primary;
    }
    return AppColors.text_secondary;
  }
}
