import 'package:flutter/material.dart';

class SubscriptionFeature {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the icon data for this feature
  IconData get icon {
    // Map string icon names to IconData
    switch (iconName) {
      case 'collections_bookmark':
        return Icons.collections_bookmark;
      case 'analytics':
        return Icons.analytics;
      case 'download':
        return Icons.download;
      case 'school':
        return Icons.school;
      case 'sync':
        return Icons.sync;
      case 'account_balance':
        return Icons.account_balance;
      case 'compare_arrows':
        return Icons.compare_arrows;
      case 'insights':
        return Icons.insights;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.star; // Default icon
    }
  }

  /// Create a SubscriptionFeature from a JSON object
  factory SubscriptionFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeature(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconName: json['icon_name'],
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'priority': priority,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
