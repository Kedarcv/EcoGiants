import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Centralized icon registry for Eco-Giants.
/// Replaces all emoji usage with beautiful Phosphor icons.

class AppIcons {
  // ── Eco Levels ───────────────────────────────────────────────
  static IconData get seedling => PhosphorIconsRegular.plant;
  static IconData get sprout => PhosphorIconsRegular.tree;
  static IconData get guardian => PhosphorIconsRegular.shieldCheck;
  static IconData get protector => PhosphorIconsRegular.shieldStar;
  static IconData get ecoGiant => PhosphorIconsRegular.globeHemisphereWest;

  static IconData levelIcon(String level) {
    switch (level) {
      case 'Seedling':
        return seedling;
      case 'Sprout':
        return sprout;
      case 'Guardian':
        return guardian;
      case 'Protector':
        return protector;
      case 'Eco Giant':
        return ecoGiant;
      default:
        return seedling;
    }
  }

  // ── Categories ───────────────────────────────────────────────
  static IconData get recyclable => PhosphorIconsRegular.recycle;
  static IconData get organic => PhosphorIconsRegular.leaf;
  static IconData get eWaste => PhosphorIconsRegular.deviceMobileCamera;
  static IconData get general => PhosphorIconsRegular.trash;
  static IconData get hazardous => PhosphorIconsRegular.warningOctagon;

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return recyclable;
      case 'organic':
        return organic;
      case 'e-waste':
        return eWaste;
      case 'general':
        return general;
      case 'hazardous':
        return hazardous;
      default:
        return general;
    }
  }

  // ── Trophies / Leaderboard ───────────────────────────────────
  static IconData get trophyGold => PhosphorIconsRegular.trophy;
  static IconData get trophySilver => PhosphorIconsRegular.medal;
  static IconData get trophyBronze => PhosphorIconsRegular.medalMilitary;

  static IconData trophyForRank(int rank) {
    switch (rank) {
      case 1:
        return trophyGold;
      case 2:
        return trophySilver;
      case 3:
        return trophyBronze;
      default:
        return PhosphorIconsRegular.crown;
    }
  }

  // ── Streak ───────────────────────────────────────────────────
  static IconData get streak => PhosphorIconsRegular.flame;

  // ── Rewards ──────────────────────────────────────────────────
  static IconData get rewardBadge => PhosphorIconsRegular.sealCheck;
  static IconData get rewardTShirt => PhosphorIconsRegular.tShirt;
  static IconData get rewardBottle => PhosphorIconsRegular.drop;
  static IconData get rewardPen => PhosphorIconsRegular.penNib;
  static IconData get rewardHoodie => PhosphorIconsRegular.hoodie;
  static IconData get rewardGift => PhosphorIconsRegular.gift;

  // ── AI / Live Tutor ──────────────────────────────────────────
  static IconData get aiBot => PhosphorIconsRegular.robot;
  static IconData get aiLeaf => PhosphorIconsRegular.leaf;
  static IconData get chat => PhosphorIconsRegular.chatCircleText;
  static IconData get chatOpen => PhosphorIconsRegular.chatCircle;

  // ── Success / Celebration ────────────────────────────────────
  static IconData get celebrate => PhosphorIconsRegular.confetti;
  static IconData get levelUp => PhosphorIconsRegular.arrowFatLinesUp;
  static IconData get check => PhosphorIconsRegular.checkCircle;
  static IconData get star => PhosphorIconsRegular.star;

  // ── Navigation / Actions ─────────────────────────────────────
  static IconData get leaderboard => PhosphorIconsRegular.trophy;
  static IconData get rewards => PhosphorIconsRegular.gift;
  static IconData get history => PhosphorIconsRegular.clockCounterClockwise;
  static IconData scanQR([bool filled = false]) => filled
      ? PhosphorIconsFill.qrCode
      : PhosphorIconsRegular.qrCode;
  static IconData get camera => PhosphorIconsRegular.camera;
  static IconData get gallery => PhosphorIconsRegular.images;
  static IconData get send => PhosphorIconsRegular.paperPlaneRight;
  static IconData get micOn => PhosphorIconsRegular.microphone;
  static IconData get micOff => PhosphorIconsRegular.microphoneSlash;
  static IconData get videoOn => PhosphorIconsRegular.videoCamera;
  static IconData get videoOff => PhosphorIconsRegular.videoCameraSlash;
  static IconData get flipCamera => PhosphorIconsRegular.arrowsClockwise;
  static IconData get leaveCall => PhosphorIconsRegular.phoneDisconnect;

  // ── Misc ─────────────────────────────────────────────────────
  static IconData get settings => PhosphorIconsRegular.gear;
  static IconData get profile => PhosphorIconsRegular.user;
  static IconData get info => PhosphorIconsRegular.info;
  static IconData get warning => PhosphorIconsRegular.warning;
  static IconData get error => PhosphorIconsRegular.xCircle;
  static IconData get delete => PhosphorIconsRegular.trash;
}
