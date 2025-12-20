import 'package:flutter/material.dart';
import '../models/sponsorship_option.dart';

class SponsorshipService {
  static const List<SponsorshipOption> _defaultOptions = [
    // GitHub Sponsors (Primary - enabled)
    SponsorshipOption(
      id: 'github',
      title: 'GitHub Sponsors',
      subtitle: 'Monthly/One-time sponsorship via GitHub.',
      url: 'https://github.com/sponsors/AnsahMohammad',
      icon: Icons.favorite_rounded,
      iconColor: Colors.redAccent,
      enabled: true,
      badge: 'Active',
      badgeColor: Color(0xFF10B981), // Emerald green
    ),

    // Buy me a coffee (enabled)
    SponsorshipOption(
      id: 'buymeacoffee',
      title: 'Buy Me a Coffee',
      subtitle: 'A quick and simple way to support the project ☕',
      url: 'https://www.buymeacoffee.com/ansahk',
      icon: Icons.coffee_rounded,
      iconColor: Color(0xFFFFDD00), // Coffee yellow
      enabled: true,
      badge: 'Active',
      badgeColor: Color(0xFF10B981), // Green
    ),

    // // PayPal (Future option - disabled for now)
    // SponsorshipOption(
    //   id: 'paypal',
    //   title: 'PayPal',
    //   subtitle: 'One-time donation or recurring payments',
    //   url: 'https://paypal.me/ansahmohammad',
    //   icon: Icons.payment_rounded,
    //   iconColor: Color(0xFF3B82F6), // Blue
    //   enabled: false,
    //   badge: 'Soon',
    //   badgeColor: Color(0xFFF59E0B), // Amber
    // ),

    // Ko-fi (Future option - disabled for now)
    SponsorshipOption(
      id: 'kofi',
      title: 'Ko-fi',
      subtitle: 'Buy me a coffee to fuel development',
      url: 'https://ko-fi.com/ansahmohammad',
      icon: Icons.local_cafe_rounded,
      iconColor: Color(0xFFEF4444), // Red
      enabled: false,
      badge: 'Coming',
      badgeColor: Color(0xFF8B5CF6), // Purple
    ),

    // // Razorpay
    // SponsorshipOption(
    //   id: 'razorpay',
    //   title: 'Razorpay',
    //   subtitle: 'Quick and secure payment via cards/UPI/more',
    //   url: 'https://rzp.io/l/YOUR_LINK', // Replace with your Razorpay link
    //   icon: Icons.wallet_rounded,
    //   iconColor: Color(0xFF2563EB), // Blue
    //   enabled: false, // Enable when you add your Razorpay link
    //   badge: 'Flexible',
    //   badgeColor: Color(0xFF6366F1), // Indigo
    // ),
  ];

  /// Get all sponsorship options
  static List<SponsorshipOption> getAllOptions() {
    return List.unmodifiable(_defaultOptions);
  }

  /// Get only enabled sponsorship options
  static List<SponsorshipOption> getEnabledOptions() {
    return _defaultOptions.where((option) => option.enabled).toList();
  }

  /// Get only disabled sponsorship options
  static List<SponsorshipOption> getDisabledOptions() {
    return _defaultOptions.where((option) => !option.enabled).toList();
  }

  /// Get sponsorship option by ID
  static SponsorshipOption? getOptionById(String id) {
    try {
      return _defaultOptions.firstWhere((option) => option.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Enable a sponsorship option by ID
  static List<SponsorshipOption> enableOption(String id) {
    return _defaultOptions.map((option) {
      if (option.id == id) {
        return option.copyWith(enabled: true);
      }
      return option;
    }).toList();
  }

  /// Disable a sponsorship option by ID
  static List<SponsorshipOption> disableOption(String id) {
    return _defaultOptions.map((option) {
      if (option.id == id) {
        return option.copyWith(enabled: false);
      }
      return option;
    }).toList();
  }

  /// Add a custom sponsorship option (for future extensibility)
  static List<SponsorshipOption> addCustomOption(
    SponsorshipOption customOption,
  ) {
    return [..._defaultOptions, customOption];
  }

  /// Update an existing sponsorship option
  static List<SponsorshipOption> updateOption(
    String id,
    SponsorshipOption updatedOption,
  ) {
    return _defaultOptions.map((option) {
      if (option.id == id) {
        return updatedOption;
      }
      return option;
    }).toList();
  }

  /// Demo method: Enable all options (for testing the dialog appearance)
  static List<SponsorshipOption> enableAllOptions() {
    return _defaultOptions
        .map((option) => option.copyWith(enabled: true))
        .toList();
  }

  /// Demo method: Get mixed options with some enabled and some disabled (current state)
  static List<SponsorshipOption> getMixedOptions() {
    return List.unmodifiable(_defaultOptions);
  }

  /// Demo method: Get only GitHub enabled (minimal state)
  static List<SponsorshipOption> getMinimalOptions() {
    return _defaultOptions.map((option) {
      return option.copyWith(enabled: option.id == 'github');
    }).toList();
  }

  /// Get count of enabled options
  static int getEnabledCount() {
    return _defaultOptions.where((option) => option.enabled).length;
  }

  /// Get count of disabled options
  static int getDisabledCount() {
    return _defaultOptions.where((option) => !option.enabled).length;
  }

  /// Check if any options are available
  static bool hasAvailableOptions() {
    return _defaultOptions.any((option) => option.enabled);
  }

  /// Get the primary sponsorship option (GitHub)
  static SponsorshipOption? getPrimaryOption() {
    return getOptionById('github');
  }
}
