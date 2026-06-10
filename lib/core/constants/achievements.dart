import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String imagePath;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

const List<Achievement> kAllAchievements = [
  // Wins
  Achievement(
    id: 'first_blood',
    title: 'First Blood',
    description: 'Win your 1st match.',
    imagePath: 'assets/images/achievements/first_blood.png',
  ),
  Achievement(
    id: 'defender_of_the_fort',
    title: 'Defender of the Fort',
    description: 'Win 10 matches.',
    imagePath: 'assets/images/achievements/defender_of_the_fort.png',
  ),
  Achievement(
    id: 'unconquerable',
    title: 'Unconquerable',
    description: 'Win 50 matches.',
    imagePath: 'assets/images/achievements/unconquerable.png',
  ),
  Achievement(
    id: 'warlord',
    title: 'Warlord',
    description: 'Win 100 matches.',
    imagePath: 'assets/images/achievements/warlord.png',
  ),

  // Level
  Achievement(
    id: 'initiate',
    title: 'Initiate',
    description: 'Reach Level 5.',
    imagePath: 'assets/images/achievements/initiate.png',
  ),
  Achievement(
    id: 'scholar',
    title: 'Scholar',
    description: 'Reach Level 15.',
    imagePath: 'assets/images/achievements/scholar.png',
  ),
  Achievement(
    id: 'linguist',
    title: 'Linguist',
    description: 'Reach Level 30.',
    imagePath: 'assets/images/achievements/linguist.png',
  ),
  Achievement(
    id: 'master_of_words',
    title: 'Master of Words',
    description: 'Reach Level 45 (Max Level).',
    imagePath: 'assets/images/achievements/master_of_words.png',
  ),

  // Damage
  Achievement(
    id: 'sharpshooter',
    title: 'Sharpshooter',
    description: 'Deal 1,000 total lifetime damage.',
    imagePath: 'assets/images/achievements/sharpshooter.png',
  ),
  Achievement(
    id: 'artillery_commander',
    title: 'Artillery Commander',
    description: 'Deal 10,000 total lifetime damage.',
    imagePath: 'assets/images/achievements/artillery_commander.png',
  ),
  Achievement(
    id: 'devastator',
    title: 'Devastator',
    description: 'Deal 50,000 total lifetime damage.',
    imagePath: 'assets/images/achievements/devastator.png',
  ),

  // Losses
  Achievement(
    id: 'what_doesnt_kill_you',
    title: 'What Doesn\'t Kill You...',
    description: 'Suffer 5 defeats.',
    imagePath: 'assets/images/achievements/what_doesnt_kill_you.png',
  ),
  Achievement(
    id: 'battle_scarred',
    title: 'Battle Scarred',
    description: 'Suffer 20 defeats.',
    imagePath: 'assets/images/achievements/battle_scarred.png',
  ),
];

/// Helper function to check which achievements should be unlocked given user stats.
List<String> evaluateAchievements({
  required int currentLevel,
  required double lifetimeScore,
  required int wins,
  required int losses,
}) {
  List<String> unlocked = [];

  // Wins
  if (wins >= 1) unlocked.add('first_blood');
  if (wins >= 10) unlocked.add('defender_of_the_fort');
  if (wins >= 50) unlocked.add('unconquerable');
  if (wins >= 100) unlocked.add('warlord');

  // Levels
  if (currentLevel >= 5) unlocked.add('initiate');
  if (currentLevel >= 15) unlocked.add('scholar');
  if (currentLevel >= 30) unlocked.add('linguist');
  if (currentLevel >= 45) unlocked.add('master_of_words');

  // Damage
  if (lifetimeScore >= 1000) unlocked.add('sharpshooter');
  if (lifetimeScore >= 10000) unlocked.add('artillery_commander');
  if (lifetimeScore >= 50000) unlocked.add('devastator');

  // Losses
  if (losses >= 5) unlocked.add('what_doesnt_kill_you');
  if (losses >= 20) unlocked.add('battle_scarred');

  return unlocked;
}
