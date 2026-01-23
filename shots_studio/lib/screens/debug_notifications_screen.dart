import 'package:flutter/material.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:intl/intl.dart';

class DebugNotificationsScreen extends StatefulWidget {
  const DebugNotificationsScreen({super.key});

  @override
  State<DebugNotificationsScreen> createState() =>
      _DebugNotificationsScreenState();
}

class _DebugNotificationsScreenState extends State<DebugNotificationsScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addToOutput(String text) {
    setState(() {
      _debugOutput += '$text\n';
    });
    LoggerService.log(text); // Also print to console
  }

  Future<void> _clearOutput() async {
    setState(() {
      _debugOutput = '';
    });
  }

  Future<void> _runTest(String testName, Future<void> Function() test) async {
    setState(() {
      _isLoading = true;
    });

    _addToOutput('=== Running $testName ===');
    try {
      await test();
      _addToOutput('✅ $testName completed successfully');
    } catch (e) {
      _addToOutput('❌ $testName failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testImmediateNotification() async {
    await NotificationService().showTestNotification();
    _addToOutput('Immediate test notification sent');
  }

  Future<void> _testScheduledNotification10Seconds() async {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
    await NotificationService().scheduleNotification(
      id: 997,
      title: 'Test 10 Second Notification',
      body:
          'This notification was scheduled 10 seconds ago at ${DateFormat('h:mm:ss a').format(DateTime.now())}',
      scheduledTime: scheduledTime,
    );
    _addToOutput(
      'Notification scheduled for 10 seconds from now: ${DateFormat('h:mm:ss a').format(scheduledTime)}',
    );
  }

  Future<void> _testScheduledNotification1Minute() async {
    await NotificationService().testScheduleNotificationInMinute();
    _addToOutput('Notification scheduled for 1 minute from now');
  }

  Future<void> _debugPendingNotifications() async {
    await NotificationService().debugScheduledNotifications();
    _addToOutput('Pending notifications logged to console');
  }

  Future<void> _testPermissions() async {
    final notificationService = NotificationService();
    final notificationPermission =
        await notificationService.requestNotificationPermissions();
    final exactAlarmPermission =
        await notificationService.checkExactAlarmPermission();

    _addToOutput('Notification permission: $notificationPermission');
    _addToOutput('Exact alarm permission: $exactAlarmPermission');
  }

  Future<void> _testInitialization() async {
    try {
      await NotificationService().init();
      _addToOutput('NotificationService initialization completed');
    } catch (e) {
      _addToOutput('NotificationService initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _runTest(
                            'Immediate Notification',
                            _testImmediateNotification,
                          ),
                  child: const Text('Test Now'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _runTest(
                            '10 Second Notification',
                            _testScheduledNotification10Seconds,
                          ),
                  child: const Text('Test 10s'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _runTest(
                            '1 Minute Notification',
                            _testScheduledNotification1Minute,
                          ),
                  child: const Text('Test 1min'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _runTest(
                            'Debug Pending',
                            _debugPendingNotifications,
                          ),
                  child: const Text('Debug Pending'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () =>
                              _runTest('Test Permissions', _testPermissions),
                  child: const Text('Permissions'),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _runTest('Test Init', _testInitialization),
                  child: const Text('Re-Init'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Control buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _clearOutput,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Text(
                    'Ready',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Debug output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty
                        ? 'Debug output will appear here...'
                        : _debugOutput,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
