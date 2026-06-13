import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/settings_service.dart';
import '../../services/social_challenge_service.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: ref.watch(socialChallengeServiceProvider).watchIncomingChallenges(user.uid),
      builder: (context, snapshot) {
        final pendingDocs = snapshot.data?.docs ?? [];
        final count = pendingDocs.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: AppTheme.gold),
              onPressed: () {
                SettingsNotifier.playSfx('click.mp3');
                if (count > 0) {
                  _showInboxDialog(context, ref, pendingDocs);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications.')));
                }
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.redFort,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  void _showInboxDialog(BuildContext parentContext, WidgetRef ref, List<dynamic> docs) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Inbox', style: TextStyle(color: AppTheme.gold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  color: AppTheme.backgroundDark,
                  child: ListTile(
                    title: Text('${data['fromName']} (Level ${data['fromLevel']})', style: const TextStyle(color: Colors.white)),
                    subtitle: const Text('Challenged you to a battle!', style: TextStyle(color: AppTheme.textMuted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            SettingsNotifier.playSfx('click.mp3');
                            Navigator.of(dialogContext).pop();
                            
                            final user = ref.read(currentUserModelProvider).value;
                            if (user == null) return;
                            
                            final gameId = await ref.read(socialChallengeServiceProvider).acceptChallenge(
                              doc.id, 
                              user.uid, 
                              data['fromUid'], 
                              user.currentLevel,
                            );
                            if (gameId != null && parentContext.mounted) {
                              parentContext.go('${Routes.readingPhase}?gameId=$gameId');
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.redFort),
                          onPressed: () {
                            SettingsNotifier.playSfx('click.mp3');
                            ref.read(socialChallengeServiceProvider).declineChallenge(doc.id);
                            Navigator.of(dialogContext).pop(); // Close to refresh list
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        );
      },
    );
  }
}
