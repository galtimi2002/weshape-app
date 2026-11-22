import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/submitted_assessment.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/report/report_file.dart';
import '../../core/theme/weshape_palette.dart';
import 'page_frame.dart';

/// Saved assessments: every kept assessment with its report number, place and dates, and its report as a
/// PDF saved under the report number, WSE-….pdf (Timi, 2026-11-22). Comparing is still "Soon".
class SavedAssessmentsPage extends StatefulWidget {
  const SavedAssessmentsPage({super.key, required this.onNew});

  final VoidCallback onNew;

  @override
  State<SavedAssessmentsPage> createState() => _SavedAssessmentsPageState();
}

class _SavedAssessmentsPageState extends State<SavedAssessmentsPage> {
  late final Future<List<SubmittedAssessment>> _list = context.read<ApiClient>().assessments();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;

    return PageFrame(
      maxWidth: 880,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 14,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PageTitle(t.savedTitle),
                const SizedBox(height: 6),
                Text(t.savedHint, style: TextStyle(fontSize: 14, color: p.muted)),
              ],
            ),
            _NewButton(label: t.savedNew, onTap: widget.onNew),
          ],
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<SubmittedAssessment>>(
          future: _list,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              final e = snap.error;
              final error = e is ApiException ? e : const ApiException(statusCode: 500);
              return Text(error.message(t), style: TextStyle(fontSize: 14, color: p.muted));
            }
            final list = snap.data ?? const <SubmittedAssessment>[];
            if (list.isEmpty) return const _Empty();
            return Column(children: [for (final a in list) _ReportRow(assessment: a)]);
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(t.savedCompare, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted)),
              const SizedBox(width: 10),
              Expanded(child: Text(t.savedCompareHint, style: TextStyle(fontSize: 12.5, color: p.muted))),
              const SizedBox(width: 10),
              SoonBadge(t.comingSoon),
            ],
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: p.fieldFill,
        border: Border.all(color: p.fieldBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: p.selected, shape: BoxShape.circle),
            child: Icon(Icons.bookmark_border_rounded, color: p.primary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(t.savedEmpty, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.text)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(t.savedEmptyHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, height: 1.45, color: p.muted)),
          ),
        ],
      ),
    );
  }
}

/// One kept assessment: its number, place and dates, and the button that saves its report as WSE-….pdf.
class _ReportRow extends StatefulWidget {
  const _ReportRow({required this.assessment});

  final SubmittedAssessment assessment;

  @override
  State<_ReportRow> createState() => _ReportRowState();
}

class _ReportRowState extends State<_ReportRow> {
  bool _busy = false;

  Future<void> _download() async {
    final t = context.t;
    final api = context.read<ApiClient>();
    final number = widget.assessment.reportNumber;
    setState(() => _busy = true);
    try {
      final pdf = await api.reportPdf(number);
      savePdf(pdf, reportFileName(number));
    } catch (e) {
      if (!mounted) return;
      final error = e is ApiException ? e : const ApiException(statusCode: 500);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(error.message(t))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = widget.assessment;
    final dates = MaterialLocalizations.of(context);
    // Past "valid until" the report may be out of date: its last page says so in red, and so does the date here.
    final expired = a.validUntil.isBefore(DateUtils.dateOnly(DateTime.now()));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.fieldFill,
        border: Border.all(color: p.fieldBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: p.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.reportNumber, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
                if (a.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.address, style: TextStyle(fontSize: 13, color: p.muted)),
                ],
                const SizedBox(height: 2),
                Text(
                  '${dates.formatMediumDate(a.madeOn)} → ${dates.formatMediumDate(a.validUntil)}',
                  style: TextStyle(fontSize: 12.5, color: expired ? const Color(0xFFC0432B) : p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: t.reportOpen,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _download,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded, size: 18),
              label: const Text('PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: p.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: p.buttonShadow, blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -10)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: p.onPrimary),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: p.onPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
