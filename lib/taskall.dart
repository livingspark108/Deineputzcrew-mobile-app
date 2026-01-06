import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:deineputzcrew/task_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'home.dart';



class AllTasksScreen2 extends StatefulWidget {
  const AllTasksScreen2({super.key});

  @override
  State<AllTasksScreen2> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen2> {
  String selectedPriority = "all"; // all | low | medium | high

  int selectedTabIndex = 0;
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  final List<String> tabs = ["All", "Pending", "Completed"];
  bool isLoading = false;
  String selectedTaskId = '';
  String? punchedInTaskId;
  int? userId;
  @override
  void initState() {
    super.initState();
    fetchTasks();

  }
  Future<void> fetchTasks() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    userId = prefs.getInt('userid') ?? 0;

    if (connectivityResult != ConnectivityResult.none) {
      // ✅ Online
      final response = await http.post(
        Uri.parse('https://admin.deineputzcrew.de/api/get_user_detail/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'token $token',
        },
        body: jsonEncode({"id": userId}),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        final List<dynamic> taskByDate = data['task_by_date'] ?? [];

        final List<Task> parsed = taskByDate
            .expand((dayData) {
          final String day = dayData['day'] ?? "";
          final String date = dayData['date'] ?? "";
          final List<dynamic> jsonTasks = dayData['tasks'] ?? [];
          return jsonTasks.map(
                (t) => Task.fromJson(t, day: day, date: date),
          );
        })
            .toList();

        // 🔥 SORT: Latest date + latest start time FIRST
        parsed.sort((a, b) {
          // ✅ Combine DATE + START TIME into DateTime
          DateTime parseDateTime(Task t) {
            try {
              final date = DateTime.parse(t.date!); // yyyy-MM-dd

              final parts = t.startTime.split(':');
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;
              final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

              return DateTime(
                date.year,
                date.month,
                date.day,
                hour,
                minute,
                second,
              );
            } catch (_) {
              return DateTime(1970);
            }
          }

          final dtA = parseDateTime(a);
          final dtB = parseDateTime(b);

          // 🔥 Latest FIRST
          return dtB.compareTo(dtA);
        });



        setState(() {
          tasks = parsed;
          applyFilter(); // keeps status + priority filters
          isLoading = false;
        });
      }

    } else {
      // ❌ Offline → load from SQLite
      setState(() => isLoading = false);
    }
  }


  void applyFilter() {
    List<Task> temp = tasks;

    // 🔹 STATUS FILTER
    if (selectedTabIndex != 0) {
      final status = tabs[selectedTabIndex].toLowerCase();
      temp = temp.where((t) => t.status.toLowerCase() == status).toList();
    }

    // 🔹 PRIORITY FILTER
    if (selectedPriority != "all") {
      temp = temp
          .where((t) => t.priority.toLowerCase() == selectedPriority)
          .toList();
    }

    filteredTasks = temp;
  }
  int priorityCount(String priority) {
    return tasks
        .where((t) => t.priority.toLowerCase() == priority)
        .length;
  }

  Widget _priorityChip(String label) {
    final isSelected = selectedPriority == label.toLowerCase();

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          selectedPriority = label.toLowerCase();
          applyFilter();
        });
      },
    );
  }

  void onTabChanged(int index) {
    setState(() {
      selectedTabIndex = index;
      applyFilter();
    });
  }

  String formatTime(String time) {
    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? "AM" : "PM";
    final formattedHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return "$formattedHour:${parts[1]} $period";
  }

  String calculateDuration(String start, String end) {
    final startParts = start.split(":").map(int.parse).toList();
    final endParts = end.split(":").map(int.parse).toList();

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];
    final diff = endMinutes - startMinutes;

    if (diff >= 60 && diff % 60 == 0) {
      return "${diff ~/ 60} hr";
    } else if (diff >= 60) {
      return "${(diff / 60).toStringAsFixed(1)} hr";
    } else {
      return "$diff min";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "All Tasks",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tabs Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedTabIndex == index;

                // Count logic
                int count = 0;
                if (index == 0) {
                  count = tasks.length; // All
                } else if (index == 1) {
                  count = tasks.where((t) => t.status== 'pending').length;
                } else if (index == 2) {
                  count = tasks.where((t) => t.status == 'completed').length;
                }

                return GestureDetector(
                  onTap: () => onTabChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey.shade200 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            color: isSelected ? Colors.black : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),


            Wrap(
              spacing: 10,
              children: [
                _priorityChip("All"),
                _priorityChip("Low"),
                _priorityChip("Medium"),
                _priorityChip("High"),
              ],
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    applyFilter();
                    filteredTasks = filteredTasks
                        .where((task) => task.taskName
                        .toString()
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                        .toList();
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search Task",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Task List
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return TaskCard(
                    title: task.taskName,
                    time: task.timeRange,
                    location: task.locationName,
                    duration: task.totalWorkTime,
                    highPriority: task.priority,
                    completed: task.status,
                    taskId: task.id,
                    punchIn: task.punchIn,
                    selectedTaskId: selectedTaskId ?? "",
                    punchedInTaskId: punchedInTaskId ?? "",
                    taskList: filteredTasks,
                    day: task.day,
                    date:task.date,
                    lat: task.lat,
                    longg: task.longg,
                    onTaskSelected: (id) {
                      final taskObj = filteredTasks.firstWhere((t) => t.id == id);

                      // ❌ Block if completed

                      // ✅ Allow selecting if it's the active punched-in task
                      setState(() {
                        selectedTaskId = id;

                        if(task.punchIn==true){
                          // startDashboardWorkTimer();

                        }
                      });
                    },


                    onPunchIn: () async {
                      setState(() {
                        selectedTaskId = task.id; // Select the task
                        // Mark as punched in
                      });



                      //startDashboardWorkTimer();
                    },

                    onPunchStart: () {
                      //stopTimer();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}