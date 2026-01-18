import 'package:flutter/material.dart';
import 'background_task_manager.dart';
import 'task_model.dart';

class BackgroundTasksWidget extends StatefulWidget {
  const BackgroundTasksWidget({Key? key}) : super(key: key);

  @override
  _BackgroundTasksWidgetState createState() => _BackgroundTasksWidgetState();
}

class _BackgroundTasksWidgetState extends State<BackgroundTasksWidget> {
  bool _isMonitoring = false;
  List<Task> _activeTasks = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final tasks = BackgroundTaskManager.getActiveTasks();
      setState(() {
        _activeTasks = tasks;
        _isMonitoring = tasks.any((task) => task.autoCheckin);
      });
    } catch (e) {
      print('Error loading background task status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.background_replace,
                  color: _isMonitoring ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto Check-in Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isMonitoring ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isMonitoring ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tasks with Auto Check-in: ${_activeTasks.where((t) => t.autoCheckin).length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (_activeTasks.isNotEmpty) ...[
              const Text(
                'Upcoming Tasks:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ..._activeTasks.where((task) => task.autoCheckin && !task.punchIn).take(3).map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        task.autoCheckin ? Icons.schedule : Icons.schedule_outlined,
                        size: 16,
                        color: task.autoCheckin ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${task.taskName} - ${task.startTime}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshTasks,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isMonitoring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Monitoring active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshTasks() async {
    try {
      await BackgroundTaskManager.refreshTasks();
      await _loadStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Background tasks refreshed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to refresh: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}