import 'package:flutter/material.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/reminder_utils.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class RemindersScreen extends StatefulWidget {
  final List<Screenshot> allScreenshots;
  final List<Collection> allCollections;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;

  const RemindersScreen({
    super.key,
    required this.allScreenshots,
    required this.allCollections,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.onScreenshotUpdated,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Screenshot> _activeReminders = [];
  List<Screenshot> _pastReminders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReminders();

    // Track screen view
    AnalyticsService().logScreenView('reminders_screen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReminders() {
    final now = DateTime.now();
    final screenshotsWithReminders =
        widget.allScreenshots
            .where(
              (screenshot) =>
                  screenshot.reminderTime != null && !screenshot.isDeleted,
            )
            .toList();

    setState(() {
      _activeReminders =
          screenshotsWithReminders
              .where((screenshot) => screenshot.reminderTime!.isAfter(now))
              .toList()
            ..sort((a, b) => a.reminderTime!.compareTo(b.reminderTime!));

      _pastReminders =
          screenshotsWithReminders
              .where((screenshot) => screenshot.reminderTime!.isBefore(now))
              .toList()
            ..sort((a, b) => b.reminderTime!.compareTo(a.reminderTime!));
    });

    // Log reminder statistics
    AnalyticsService().logFeatureUsed('reminders_screen_loaded');
    _logReminderStats();
  }

  void _logReminderStats() {
    // Log analytics about reminder usage
    AnalyticsService().logFeatureUsed(
      'active_reminders_count_${_activeReminders.length}',
    );
    AnalyticsService().logFeatureUsed(
      'past_reminders_count_${_pastReminders.length}',
    );
  }

  void _openScreenshotDetail(Screenshot screenshot) {
    AnalyticsService().logFeatureUsed('reminder_screenshot_opened');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ScreenshotDetailScreen(
              screenshot: screenshot,
              allCollections: widget.allCollections,
              allScreenshots: widget.allScreenshots,
              onUpdateCollection: widget.onUpdateCollection,
              onDeleteScreenshot: widget.onDeleteScreenshot,
              onScreenshotUpdated: () {
                widget.onScreenshotUpdated?.call();
                _loadReminders();
              },
            ),
      ),
    );
  }

  Future<void> _editReminder(Screenshot screenshot) async {
    AnalyticsService().logFeatureUsed('reminder_edit_initiated');

    final result = await ReminderUtils.showReminderBottomSheet(
      context,
      screenshot.reminderTime,
      screenshot.reminderText,
    );

    if (result != null) {
      setState(() {
        screenshot.reminderTime = result['reminderTime'];
        screenshot.reminderText = result['reminderText'];
      });

      if (result['reminderTime'] != null) {
        await ReminderUtils.setReminder(
          context,
          screenshot,
          result['reminderTime'],
          customMessage: result['reminderText'],
        );
        AnalyticsService().logFeatureUsed('reminder_updated');
      } else {
        ReminderUtils.clearReminder(context, screenshot);
        AnalyticsService().logFeatureUsed('reminder_cleared_from_edit');
      }

      widget.onScreenshotUpdated?.call();
      _loadReminders();
    }
  }

  void _removePastReminder(Screenshot screenshot) {
    AnalyticsService().logFeatureUsed('past_reminder_removed');

    setState(() {
      screenshot.reminderTime = null;
      screenshot.reminderText = null;
    });

    widget.onScreenshotUpdated?.call();
    _loadReminders();

    SnackbarService().showInfo(
      context,
      AppLocalizations.of(context)?.pastReminderRemoved ??
          'Past reminder removed',
    );
  }

  Widget _buildReminderTile(Screenshot screenshot, bool isActive) {
    final reminderTime = screenshot.reminderTime!;
    final now = DateTime.now();
    final isOverdue = reminderTime.isBefore(now);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: _buildThumbnail(screenshot),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              screenshot.title ?? 'Screenshot',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy • hh:mm a').format(reminderTime),
              style: TextStyle(
                fontSize: 12,
                color:
                    isOverdue
                        ? Colors.red
                        : Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (screenshot.reminderText?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                screenshot.reminderText!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: _buildActionButtons(screenshot, isActive),
        onTap: () => _openScreenshotDetail(screenshot),
      ),
    );
  }

  Widget _buildThumbnail(Screenshot screenshot) {
    Widget imageWidget;

    if (screenshot.path != null) {
      final file = File(screenshot.path!);
      if (file.existsSync()) {
        imageWidget = Image.file(file, fit: BoxFit.cover);
      } else {
        imageWidget = const Icon(Icons.broken_image, size: 32);
      }
    } else if (screenshot.bytes != null) {
      imageWidget = Image.memory(screenshot.bytes!, fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.image, size: 32);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: imageWidget,
      ),
    );
  }

  Widget _buildActionButtons(Screenshot screenshot, bool isActive) {
    if (isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _editReminder(screenshot),
              tooltip:
                  AppLocalizations.of(context)?.editReminder ?? 'Edit Reminder',
            ),
          ),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            Icons.close,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _removePastReminder(screenshot),
          tooltip: AppLocalizations.of(context)?.removePastReminder ?? 'Remove',
        ),
      );
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.reminders ?? 'Reminders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: AppLocalizations.of(context)?.activeReminders ?? 'Active',
              icon: const Icon(Icons.notifications_active),
            ),
            Tab(
              text: AppLocalizations.of(context)?.pastReminders ?? 'Past',
              icon: const Icon(Icons.history),
            ),
          ],
          onTap: (index) {
            AnalyticsService().logFeatureUsed(
              'reminder_tab_switched_${index == 0 ? 'active' : 'past'}',
            );
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Reminders Tab
          _activeReminders.isEmpty
              ? _buildEmptyState(
                AppLocalizations.of(context)?.noActiveReminders ??
                    'No active reminders.\nSet reminders from screenshot details.',
                Icons.notifications_none,
              )
              : RefreshIndicator(
                onRefresh: () async {
                  _loadReminders();
                  AnalyticsService().logFeatureUsed('reminders_refreshed');
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: _activeReminders.length,
                  itemBuilder: (context, index) {
                    return _buildReminderTile(_activeReminders[index], true);
                  },
                ),
              ),

          // Past Reminders Tab
          _pastReminders.isEmpty
              ? _buildEmptyState(
                AppLocalizations.of(context)?.noPastReminders ??
                    'No past reminders.',
                Icons.history,
              )
              : RefreshIndicator(
                onRefresh: () async {
                  _loadReminders();
                  AnalyticsService().logFeatureUsed('reminders_refreshed');
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: _pastReminders.length,
                  itemBuilder: (context, index) {
                    return _buildReminderTile(_pastReminders[index], false);
                  },
                ),
              ),
        ],
      ),
    );
  }
}
