import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/chart_enums.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ZenChartToolbar extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final Function(String) onTimeframeChanged;
  final String selectedTimeframe;
  final Function(DrawingMode) onDrawingModeChanged;
  final DrawingMode drawingMode;
  final Function(bool) onChartTypeChanged;
  final bool isCandleChart;
  final List<Widget> navIcons;

  const ZenChartToolbar({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onTimeframeChanged,
    required this.selectedTimeframe,
    required this.onDrawingModeChanged,
    required this.drawingMode,
    required this.onChartTypeChanged,
    required this.isCandleChart,
    required this.navIcons,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // ── Zoom Buttons ──
        Positioned(
          right: 8,
          bottom: 30,
          child: Column(
            children: [
              _chartBtn('+', l10n.zoomIn, onZoomIn),
              const SizedBox(height: 3),
              _chartBtn('-', l10n.zoomOut, onZoomOut),
              const SizedBox(height: 3),
              _chartBtn('↺', l10n.resetView, onReset),
            ],
          ),
        ),

        // ── Top Navigation (Timeframe, Demo Badge, Chart Type) ──
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimeframeSelector(),
                      const SizedBox(width: 8),
                      _buildDrawingToggle(l10n),
                      const SizedBox(width: 8),
                      _buildDemoBadge(),
                      const SizedBox(width: 8),
                      _buildChartToggle(),
                      const SizedBox(width: 12),
                      ...navIcons,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartBtn(String icon, String tooltip, VoidCallback fn) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: fn,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildTimeframeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['1M', '15M', '1H', '4H', '1D'].map((tf) {
          final isSelected = selectedTimeframe == tf;
          return GestureDetector(
            onTap: () => onTimeframeChanged(tf),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? MehdAiTheme.blue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tf,
                style: MehdAiTheme.labelStyle.copyWith(
                  color: isSelected ? MehdAiTheme.blue : MehdAiTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDemoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MehdAiTheme.yellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: MehdAiTheme.yellow.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: MehdAiTheme.yellow),
          const SizedBox(width: 6),
          Text(
            'DEMO',
            style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.yellow, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(Icons.candlestick_chart, 'Candles', true),
          _buildToggleOption(Icons.show_chart, 'Line', false),
        ],
      ),
    );
  }

  Widget _buildToggleOption(IconData icon, String label, bool isCandle) {
    final isSelected = isCandleChart == isCandle;
    return InkWell(
      onTap: () => onChartTypeChanged(isCandle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? MehdAiTheme.bgPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? MehdAiTheme.white : MehdAiTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: MehdAiTheme.labelStyle.copyWith(
                color: isSelected ? MehdAiTheme.white : MehdAiTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: const Color(0xFF111111)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _drawingModeBtn(l10n.autoMode, DrawingMode.auto),
          _drawingModeBtn(l10n.manualMode, DrawingMode.manual),
        ],
      ),
    );
  }

  Widget _drawingModeBtn(String label, DrawingMode mode) {
    final isActive = drawingMode == mode;
    return GestureDetector(
      onTap: () => onDrawingModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF020810) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: isActive ? Border.all(color: const Color(0xFF58A6FF)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF333333),
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
