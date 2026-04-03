import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/manual_drawing.dart';

/// FILE — drawing_toolbar.dart
/// AUDIT FIX #7: Manual Drawing Toolbar
///
/// Appears in fullscreen chart mode. Provides tools for:
/// - Trendline (2-point tap)
/// - Horizontal Line (1-tap price level)
/// - Zone (2-tap price levels)
/// - Fibonacci (2-tap high/low)
/// - Select/Delete tool

class DrawingToolbar extends StatelessWidget {
  final ManualDrawingTool activeTool;
  final ValueChanged<ManualDrawingTool> onToolChanged;
  final VoidCallback onDeleteSelected;
  final VoidCallback onClearAll;
  final int drawingCount;
  final bool hasSelection;

  const DrawingToolbar({
    super.key,
    required this.activeTool,
    required this.onToolChanged,
    required this.onDeleteSelected,
    required this.onClearAll,
    required this.drawingCount,
    required this.hasSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MehdAiTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.draw, size: 12, color: MehdAiTheme.blue),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'DRAW',
                    style: MehdAiTheme.labelStyle.copyWith(
                      fontSize: 9,
                      color: MehdAiTheme.blue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Tool Buttons
          _buildToolButton(
            icon: Icons.timeline,
            label: 'Line',
            tool: ManualDrawingTool.trendline,
            tooltip: 'Trendline — tap 2 points',
          ),
          const SizedBox(height: 4),
          _buildToolButton(
            icon: Icons.horizontal_rule,
            label: 'H-Line',
            tool: ManualDrawingTool.horizontalLine,
            tooltip: 'Horizontal Line — tap 1 price level',
          ),
          const SizedBox(height: 4),
          _buildToolButton(
            icon: Icons.crop_square,
            label: 'Zone',
            tool: ManualDrawingTool.zone,
            tooltip: 'Zone — tap 2 price levels',
          ),
          const SizedBox(height: 4),
          _buildToolButton(
            icon: Icons.architecture,
            label: 'Fib',
            tool: ManualDrawingTool.fibonacci,
            tooltip: 'Fibonacci — tap swing low then high',
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              height: 1,
              width: 36,
              color: MehdAiTheme.borderColor,
            ),
          ),

          // Delete button (only active when something is selected)
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Del',
            onTap: hasSelection ? onDeleteSelected : null,
            color: hasSelection ? MehdAiTheme.red : MehdAiTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 4),
          _buildActionButton(
            icon: Icons.layers_clear,
            label: 'Clear',
            onTap: drawingCount > 0 ? onClearAll : null,
            color: drawingCount > 0 ? MehdAiTheme.yellow : MehdAiTheme.textSecondary.withOpacity(0.3),
          ),

          if (drawingCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$drawingCount',
              style: MehdAiTheme.labelStyle.copyWith(
                fontSize: 9,
                color: MehdAiTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required ManualDrawingTool tool,
    required String tooltip,
  }) {
    final isActive = activeTool == tool;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onToolChanged(isActive ? ManualDrawingTool.none : tool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? MehdAiTheme.blue.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? MehdAiTheme.blue : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18,
                color: isActive ? MehdAiTheme.blue : MehdAiTheme.textSecondary),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: MehdAiTheme.labelStyle.copyWith(
                    fontSize: 8,
                    color: isActive ? MehdAiTheme.blue : MehdAiTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 8, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
