import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shots_studio/services/custom_path_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class CustomPathsDialog extends StatefulWidget {
  final VoidCallback? onPathAdded;
  final Function(String)? onPathRemoved;

  const CustomPathsDialog({super.key, this.onPathAdded, this.onPathRemoved});

  @override
  State<CustomPathsDialog> createState() => _CustomPathsDialogState();
}

class _CustomPathsDialogState extends State<CustomPathsDialog> {
  List<String> _customPaths = [];
  final TextEditingController _pathController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomPaths();

    // Track dialog access
    AnalyticsService().logFeatureUsed('custom_paths_dialog_opened');
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomPaths() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paths = await CustomPathService.getCustomPaths();
      setState(() {
        _customPaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarService().showError(context, 'Error loading custom paths: $e');
      }
    }
  }

  Future<void> _addCustomPath() async {
    // For web platform, use manual text entry
    if (kIsWeb) {
      await _addCustomPathManual();
    } else {
      // For mobile platforms, use native directory picker
      await _addCustomPathNative();
    }
  }

  Future<void> _addCustomPathManual() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      SnackbarService().showWarning(context, 'Please enter a valid path');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate path exists
      final isValid = await CustomPathService.validatePath(path);
      if (!isValid) {
        SnackbarService().showWarning(
          context,
          'Directory does not exist or is not accessible',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add path
      final success = await CustomPathService.addCustomPath(path);
      if (success) {
        // Track successful path addition
        AnalyticsService().logFeatureUsed('custom_path_added_manual');

        _pathController.clear();
        await _loadCustomPaths();
        SnackbarService().showSuccess(
          context,
          'Custom path added successfully',
        );

        // Notify parent that a path was added
        widget.onPathAdded?.call();
      } else {
        SnackbarService().showWarning(
          context,
          'Path already exists or could not be added',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarService().showError(context, 'Error adding custom path: $e');
    }
  }

  Future<void> _addCustomPathNative() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // User cancelled the picker
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add path
      final success = await CustomPathService.addCustomPath(selectedDirectory);
      if (success) {
        // Track successful path addition
        AnalyticsService().logFeatureUsed('custom_path_added_native');

        await _loadCustomPaths();
        SnackbarService().showSuccess(
          context,
          'Custom path added successfully',
        );

        // Notify parent that a path was added
        widget.onPathAdded?.call();
      } else {
        SnackbarService().showWarning(
          context,
          'Path already exists or could not be added',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarService().showError(context, 'Error adding custom path: $e');
    }
  }

  Future<void> _removeCustomPath(String path) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await CustomPathService.removeCustomPath(path);
      if (success) {
        // Track successful path removal
        AnalyticsService().logFeatureUsed('custom_path_removed');

        await _loadCustomPaths();
        SnackbarService().showSuccess(context, 'Custom path removed');

        // Notify parent that a path was removed
        widget.onPathRemoved?.call(path);
      } else {
        setState(() {
          _isLoading = false;
        });
        SnackbarService().showError(context, 'Could not remove custom path');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarService().showError(context, 'Error removing custom path: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button (fixed at top)
            Container(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Custom Screenshot Paths',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : null,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add custom directories where your screenshots are stored. The app will scan these locations along with the default screenshot folders.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Add new path section
                    _buildAddPathSection(isSmallScreen),
                    const SizedBox(height: 20),

                    // Current custom paths
                    Text(
                      'Current Custom Paths',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildCustomPathsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPathSection(bool isSmallScreen) {
    if (kIsWeb) {
      // For web, show manual text input
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Directory Path:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pathController,
            decoration: InputDecoration(
              labelText: 'Directory Path',
              hintText:
                  isSmallScreen
                      ? '/path/to/screenshots'
                      : '/home/user/Pictures/Screenshots',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.folder),
            ),
            onSubmitted: (_) => _addCustomPath(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _addCustomPath,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add),
              label: const Text('Add Path'),
            ),
          ),
        ],
      );
    } else {
      // For mobile, show directory picker button
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Directory:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _addCustomPath,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.folder_open),
              label: const Text('Browse for Directory'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to open the file picker and select a directory containing screenshots.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCustomPathsList() {
    if (_isLoading && _customPaths.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_customPaths.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          kIsWeb
              ? 'No custom paths added yet.\nEnter a directory path above to get started.'
              : 'No custom paths added yet.\nTap "Browse for Directory" above to get started.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _customPaths.length,
      itemBuilder: (context, index) {
        final path = _customPaths[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(
              path,
              style: const TextStyle(fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            trailing: IconButton(
              onPressed: _isLoading ? null : () => _removeCustomPath(path),
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Remove path',
            ),
            isThreeLine: path.length > 40,
            subtitle:
                path.length > 40
                    ? Text(
                      path,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                    : null,
          ),
        );
      },
    );
  }
}
