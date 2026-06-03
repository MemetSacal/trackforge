// ── ai_helpers.dart ─────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';

Widget aiHeader(BuildContext context, WidgetRef ref, bool isDark,
    Color bg, Color bgCard, Color border, Color text, Color textSoft, Color muted, Color accent, String title) {
  return Container(
    color: bg,
    padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3)),
        ])),
        GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft)),
        ),
      ],
    ),
  );
}

Widget aiLoadingState(Color accent, Color text, String message) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    CircularProgressIndicator(color: accent),
    const SizedBox(height: 24),
    Text(message, style: TextStyle(fontSize: 15, color: text)),
    const SizedBox(height: 8),
    Text('Bu 10–20 saniye sürebilir', style: TextStyle(fontSize: 12, color: accent.withOpacity(0.6))),
  ]));
}

Widget aiErrorState(String error, Color danger, Color accent, VoidCallback onRetry) {
  return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('😕', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 16),
    Text(error, textAlign: TextAlign.center, style: TextStyle(color: danger, fontSize: 14)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
  ])));
}

Widget aiErrorCard(String error, Color danger, Color border) =>
  Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: danger.withOpacity(0.3))),
    child: Row(children: [
      Icon(Icons.error_outline, color: danger, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(error, style: TextStyle(color: danger, fontSize: 13))),
    ]));

Widget aiOutlineBtn(String label, IconData icon, Color accent, Color border, VoidCallback? onTap) =>
  SizedBox(width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: accent, size: 16),
      label: Text(label, style: TextStyle(color: accent)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ));