// ── gamification_screen.dart ────────────────────────────
import 'package:flutter/material.dart';
import '../../core/widgets/celebrate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

final gamificationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.gamificationSummary);
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return {};
  }
});

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  String _extractEmoji(String badgeName) {
    final runes = badgeName.runes.toList();
    for (int i = runes.length - 1; i >= 0; i--) {
      final cp = runes[i];
      if ((cp >= 0x1F300 && cp <= 0x1FAFF) ||
          (cp >= 0x2600  && cp <= 0x27BF)  ||
          (cp >= 0xFE00  && cp <= 0xFE0F)  ||
          (cp >= 0x1F900 && cp <= 0x1F9FF)) {
        return String.fromCharCode(cp);
      }
    }
    return '🎖️';
  }

  String _extractName(String badgeName) {
    return badgeName.replaceAll(RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\s]+$',
      unicode: true,
    ), '').trim();
  }

  String _streakLabel(String type) {
    switch (type) {
      case 'water':    return '💧 Su';
      case 'exercise': return '💪 Egzersiz';
      case 'sleep':    return '😴 Uyku';
      default:         return type;
    }
  }

  String _levelTitle(String title) {
    switch (title) {
      case 'Beginner':  return 'Başlangıç';
      case 'Active':    return 'Aktif';
      case 'Fit':       return 'Fit';
      case 'Athlete':   return 'Atlet';
      case 'Champion':  return 'Şampiyon';
      default:          return title;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg        = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard    = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft    = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border    = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text      = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft  = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted     = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent    = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final positive  = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    final gamAsync = ref.watch(gamificationProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Başarılar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                  ),
                ),
              ],
            ),
          ),

          // ── İÇERİK ──────────────────────────────────────
          Expanded(
            child: gamAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Henüz veri yok', style: TextStyle(fontSize: 16, color: text)),
                        const SizedBox(height: 4),
                        Text('Aktiviteler tamamlandıkça XP ve rozetler burada görünür',
                          style: TextStyle(fontSize: 12, color: muted), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final levelData = data['level'] != null
                    ? Map<String, dynamic>.from(data['level'])
                    : <String, dynamic>{};
                final badges  = (data['badges']  as List?) ?? [];
                final streaks = (data['streaks'] as List?) ?? [];

                final xp         = (levelData['xp']              as num?)?.toInt() ?? 0;
                final levelNum   = (levelData['level']            as num?)?.toInt() ?? 1;
                final levelTitle = levelData['level_title']       as String? ?? 'Beginner';
                final xpToNext   = (levelData['xp_to_next_level'] as num?)?.toInt() ?? 500;

                const levelStarts = {1: 0, 2: 500, 3: 1500, 4: 3000, 5: 6000};
                final levelStart  = levelStarts[levelNum] ?? 0;
                final xpInLevel   = xp - levelStart;
                final xpNeeded    = (levelStarts[levelNum + 1] ?? 9999) - levelStart;
                final xpProgress  = xpNeeded > 0 ? (xpInLevel / xpNeeded).clamp(0.0, 1.0) : 1.0;

                final exerciseStreak = streaks
                    .map((s) => Map<String, dynamic>.from(s))
                    .where((s) => s['streak_type'] == 'exercise')
                    .firstOrNull;
                final streakDays = (exerciseStreak?['current_streak'] as num?)?.toInt() ?? 0;

                const levelTitles = {1: 'Beginner', 2: 'Active', 3: 'Fit', 4: 'Athlete', 5: 'Champion'};
                final nextLevelTitle = levelTitles[levelNum + 1] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    children: [

                      // ── XP / SEVİYE KARTI ──────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: accentDim,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.4)),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_levelTitle(levelTitle),
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
                                      Text('$xp XP',
                                        style: TextStyle(fontSize: 14, color: text, fontWeight: FontWeight.w600)),
                                      if (nextLevelTitle.isNotEmpty)
                                        Text('Sonraki: ${_levelTitle(nextLevelTitle)}',
                                          style: TextStyle(fontSize: 11, color: textSoft)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 24)),
                                    Text('$streakDays gün', style: TextStyle(fontSize: 11, color: text, fontWeight: FontWeight.w700)),
                                    Text('seri', style: TextStyle(fontSize: 10, color: muted)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: xpProgress,
                                minHeight: 8,
                                backgroundColor: accent.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_levelTitle(levelTitle), style: TextStyle(fontSize: 10, color: muted)),
                                Text('$xpToNext XP kaldı', style: TextStyle(fontSize: 10, color: muted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── STREAK'LER ─────────────────────────
                      if (streaks.isNotEmpty) ...[
                        Container(
                          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seriler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 12),
                              Row(
                                children: streaks.map((s) {
                                  final streak  = Map<String, dynamic>.from(s);
                                  final type    = streak['streak_type'] as String? ?? '';
                                  final current = (streak['current_streak'] as num?)?.toInt() ?? 0;
                                  final longest = (streak['longest_streak'] as num?)?.toInt() ?? 0;
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: bgSoft,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: current > 0 ? accent.withOpacity(0.4) : border),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(_streakLabel(type), style: TextStyle(fontSize: 11, color: muted)),
                                          const SizedBox(height: 4),
                                          Text('$current',
                                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                                              color: current > 0 ? accent : textSoft)),
                                          Text('gün', style: TextStyle(fontSize: 10, color: muted)),
                                          const SizedBox(height: 4),
                                          Text('En uzun: $longest', style: TextStyle(fontSize: 9, color: muted)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── KAZANILAN ROZETLER ─────────────────
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rozetler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99)),
                                  child: Text('${badges.length} kazanıldı',
                                    style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (badges.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      const Text('🎖️', style: TextStyle(fontSize: 32)),
                                      const SizedBox(height: 8),
                                      Text('Henüz rozet kazanılmadı', style: TextStyle(fontSize: 13, color: muted)),
                                      const SizedBox(height: 4),
                                      Text('Aktiviteler tamamlandıkça rozetler burada görünür',
                                        style: TextStyle(fontSize: 11, color: muted), textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  // FIX (21px taşma): 0.85 kartları kısa bırakıyordu;
                                  // uzun isim (ör. "İlk Antrenman") + 2 satır açıklama sığmıyordu.
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: badges.length,
                                itemBuilder: (ctx, i) {
                                  final b         = Map<String, dynamic>.from(badges[i]);
                                  final badgeName = b['badge_name'] as String? ?? 'Rozet';
                                  final desc      = b['description'] as String? ?? '';
                                  final emoji     = _extractEmoji(badgeName);
                                  final name      = _extractName(badgeName);
                                  return GestureDetector(
                                    onTap: () {
                                      // v8: rozetine dokun, kutlamayı tekrar yaşa
                                      HapticFeedback.mediumImpact();
                                      Celebrate.burst(context);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('$emoji $name'),
                                        duration: const Duration(seconds: 2),
                                      ));
                                    },
                                    child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: bgSoft,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: accent.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 28)),
                                        const SizedBox(height: 6),
                                        Text(name,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(desc,
                                            style: TextStyle(fontSize: 9, color: muted),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        ],
                                      ],
                                    ),
                                  ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── KİLİTLİ ROZETLER ──────────────────
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kazanılabilecek Rozetler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(height: 12),
                            _lockedBadges(badges, bgSoft, border, text, muted, accent, accentDim),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── XP NASIL KAZANILIR ─────────────────
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('XP Nasıl Kazanılır?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(height: 12),
                            ...[
                              ['💪', 'Antrenman Seansı',  '+50 XP'],
                              ['💧', 'Su Hedefi',          '+20 XP'],
                              ['😴', 'Uyku Logu',          '+15 XP'],
                              ['📊', 'Haftalık Rapor',     '+10 XP'],
                              ['🎖️', 'Rozet Kazan',        '+100 XP'],
                            ].map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                              child: Row(
                                children: [
                                  Text(r[0], style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(r[1], style: TextStyle(fontSize: 13, color: text))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99)),
                                    child: Text(r[2], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedBadges(List earned, Color bgSoft, Color border, Color text, Color muted, Color accent, Color accentDim) {
    // Tüm rozet tanımları — backend BADGE_DEFINITIONS ile sync
    const allBadges = {
      // Antrenman
      'first_workout':      ('💪', 'İlk Antrenman',       'İlk antrenman seansını tamamla'),
      'workout_10':         ('🏋️', '10 Antrenman',         '10 antrenman seansını tamamla'),
      'workout_30':         ('🥇', '30 Antrenman',         '30 antrenman seansını tamamla'),
      'streak_warrior':     ('⚔️', 'Streak Savaşçısı',    '7 gün boyunca egzersiz yap'),
      'streak_legend':      ('🔥', 'Seri Efsanesi',        '30 gün boyunca egzersiz yap'),
      // Su
      '7_day_water':        ('💧', '7 Gün Su',             '7 gün su hedefine ulaş'),
      '30_day_water':       ('🏆', '30 Gün Su',            '30 gün su hedefine ulaş'),
      // Uyku
      'sleep_7':            ('😴', 'Uyku Ustası',          '7 gün kaliteli uyku logu gir'),
      // Kilo
      'weight_loss_5kg':    ('⚡', '5 kg Kayıp',          '5 kg ver'),
      'weight_loss_10kg':   ('🔥', '10 kg Kayıp',         '10 kg ver'),
      'weight_loss_20kg':   ('🎯', '20 kg Kayıp',         '20 kg ver'),
      'weight_gain_5kg':    ('📈', '5 kg Aldın',          'Hedef kilo için 5 kg kazan'),
      // Fotoğraf
      'first_photo':        ('📸', 'İlk Fotoğraf',        'İlerleme fotoğrafı yükle'),
      // Sosyal
      'first_friend':       ('🤝', 'İlk Arkadaş',         'İlk arkadaşını ekle'),
      // AI
      'ai_explorer':        ('🤖', 'AI Kaşifi',           'AI koç özelliğini kullan'),
      // Özel
      'early_bird':         ('🌅', 'Erken Kuş',           'Sabah 7\'den önce antrenman yap'),
      'night_owl':          ('🌙', 'Gece Kuşu',           'Gece 22\'den sonra antrenman yap'),
    };

    final earnedKeys = earned
        .map((b) => (b is Map ? b['badge_key'] : null) as String?)
        .whereType<String>()
        .toSet();

    final locked = allBadges.entries.where((e) => !earnedKeys.contains(e.key)).toList();
    if (locked.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Tüm rozetleri kazandın! 🎉', style: TextStyle(fontSize: 13, color: muted)),
      ));
    }

    return Column(
      children: locked.map((e) {
        final (icon, name, hint) = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(icon, style: TextStyle(fontSize: 18, color: muted))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted)),
                    const SizedBox(height: 2),
                    Text(hint, style: TextStyle(fontSize: 11, color: muted.withOpacity(0.7))),
                  ],
                ),
              ),
              Icon(Icons.lock_outline, size: 14, color: muted),
            ],
          ),
        );
      }).toList(),
    );
  }
}