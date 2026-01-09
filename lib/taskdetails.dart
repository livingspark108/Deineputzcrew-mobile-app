import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:deineputzcrew/a.dart';
import 'package:deineputzcrew/complete.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'db_helper.dart';
import 'home.dart';

  class TaskDetailsScreen extends StatefulWidget {
    final String? title;
    final String? time;
    final String? location;
    final String? duration;
    final String? highPriority;
    final String? completed;
    final String? taskId;

    const TaskDetailsScreen({
      super.key,
      required this.title,
      required this.time,
      required this.location,
      required this.duration,
     required  this.highPriority,
      required this.completed,
      required this.taskId,
    });

    @override
    State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
  }

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  String selectedStatus = "Completed";
  List<File> images = [];
  final ImagePicker _picker = ImagePicker();

  final TextEditingController remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainApp()),
              );
            }
          },
        ),
        title: const Text("Task Details",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w500)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Task",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
               Text(widget.title!,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins')),
              const Divider(height: 30),

              /// Status row
              const Text("Status",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final result = await _showStatusPopup(context, selectedStatus);
                  if (result != null) {
                    setState(() {
                      selectedStatus = result;
                    });
                  }
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedStatus,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins')),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const Divider(height: 30),

              /// Logged Time
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Logged:",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontFamily: 'Poppins')),
                              Text(widget.highPriority ?? " ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontFamily: 'Poppins'))
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(widget.duration!,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins')),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.black54),
                              SizedBox(width: 4),
                              Text(widget.time.toString(),
                                  style: TextStyle(fontFamily: 'Poppins')),
                              SizedBox(width: 12),
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(widget.location!,
                                  style: TextStyle(fontFamily: 'Poppins')),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Start / End Time
             /* Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Start at",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Poppins')),
                          SizedBox(height: 6),
                          Text("10:15 AM",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins'))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("End at",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Poppins')),
                          SizedBox(height: 6),
                          Text("11:00 AM",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins'))
                        ],
                      ),
                    ),
                  )
                ],
              ),*/
              const SizedBox(height: 20),

              /// Attachments
              const Text("Attachments",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          images[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => images.removeAt(index));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Remarks",
                  hintText: "Enter Remark",
                  labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              /// Add Attachment Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Camera'),
                            onTap: () async {
                              Navigator.pop(context);
                              final XFile? pickedFile =
                              await _picker.pickImage(source: ImageSource.camera);
                              if (pickedFile != null) {
                                setState(() {
                                  images.add(File(pickedFile.path));
                                });
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo),
                            title: const Text('Gallery'),
                            onTap: () async {
                              Navigator.pop(context);
                              final List<XFile> pickedFiles =
                              await _picker.pickMultiImage(); // allows multiple images
                              if (pickedFiles.isNotEmpty) {
                                setState(() {
                                  images.addAll(pickedFiles.map((x) => File(x.path)));
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },

                  icon: const Icon(Icons.upload),
                  label: const Text("Add Attachment"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (selectedStatus == "Completed")
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // You can add any task completion logic here
                      _handlePunchOut(context, widget.taskId!, images,remarkController);

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Mark as Completed",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/*
  Future<void> _handlePunchOut(
      BuildContext context,
      String taskId,
      List<File> images,
      TextEditingController controller,
      ) async {
    try {
      if (images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
        return;
      }

      // Step 1: Get location
      final position = await Geolocator.getCurrentPosition();

      // Step 2: Prepare request
      final uri = Uri.parse('https://admin.deineputzcrew.de/api/punch-out/');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'token $token';
      request.fields.addAll({
        'task_id': taskId,
        'lat': position.latitude.toStringAsFixed(6),
        'long': position.longitude.toStringAsFixed(6),
        'remark': controller.text.trim(),
      });

      // Step 3: Attach images
      for (final image in images) {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          image.path,
          filename: basename(image.path),
        ));
      }

      // Step 4: Send
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Punch-out raw response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse safely
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // ✅ Success → clear prefs
        await prefs.remove('punchedInTaskId');
        await prefs.remove('punchInStartTime');
        await prefs.remove('onBreak');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Punch-out successful')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainApp()),
              (route) => false,
        );

        debugPrint("Punch-out details → ${responseData.toString()}");
      } else {
        // ❌ Server error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Punch-out failed (${response.statusCode}).")),
        );
      }
    } catch (e) {
      debugPrint('Punch-out exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

*/

// Future<void> _handlePunchOut(
//     BuildContext context,
//     String taskId,
//     List<File> images,
//     TextEditingController controller,
//     ) async {
//   try {
//     if (images.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least one image')),
//       );
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Authentication error. Please log in again.')),
//       );
//       return;
//     }

//     // Step 1: Get location
//     final position = await Geolocator.getCurrentPosition();

//     // Step 2: Try sending API request
//     final uri = Uri.parse('https://admin.deineputzcrew.de/api/punch-out/');
//     var request = http.MultipartRequest('POST', uri);

//     request.headers['Authorization'] = 'token $token';
//     request.fields.addAll({
//       'task_id': taskId,
//       'lat': position.latitude.toStringAsFixed(6),
//       'long': position.longitude.toStringAsFixed(6),
//       'remark': controller.text.trim(),
//     });

//     for (final image in images) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'images',
//         image.path,
//         filename: basename(image.path),
//       ));
//     }

//     try {
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       debugPrint("Punch-out raw response: ${response.statusCode} ${response.body}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // ✅ Success → clear prefs
//         await prefs.remove('punchedInTaskId');
//         await prefs.remove('punchInStartTime');
//         await prefs.remove('onBreak');

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Punch-out successful')),
//         );

//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => MainApp()),
//               (route) => false,
//         );
//         return;
//       } else {
//         throw Exception("Server error: ${response.statusCode}");
//       }
//     } catch (networkError) {
//       // 🌐 Offline or request failed → save locally
//       debugPrint("Network failed, saving Punch-Out offline: $networkError");

//       final db = DBHelper();
//     /*  await db.insertPunchAction({
//         'task_id': taskId,
//         'type': 'punch_out',
//         'lat': position.latitude.toStringAsFixed(6),
//         'long': position.longitude.toStringAsFixed(6),
//         'remark': controller.text.trim(),
//         'image_path': images.first.path, // store first image path (extend if needed)
//         'timestamp': DateTime.now().toIso8601String(),
//         'synced': 0,
//       });*/

//       // Clear prefs locally as if punched out
//       await prefs.remove('punchedInTaskId');
//       await prefs.remove('punchInStartTime');
//       await prefs.remove('onBreak');

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Punch-out saved offline. Will sync when online.')),
//       );

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => MainApp()),
//             (route) => false,
//       );
//     }
//   } catch (e) {
//     debugPrint('Punch-out exception: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error: $e')),
//     );
//   }
// }

Future<void> _handlePunchOut(
    BuildContext context,
    String taskId,
    List<File> images,
    TextEditingController controller,
    ) async {
  try {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    // Step 1: Get location
    final position = await Geolocator.getCurrentPosition();

    // ✅ Step 2: Check connectivity FIRST
    final connectivity = await Connectivity().checkConnectivity();

    // ==================== OFFLINE MODE ====================
    if (connectivity == ConnectivityResult.none) {
      debugPrint("📴 Offline - Saving punch-out to DB");
      
      final db = DBHelper();
      
      // ✅ Save each image as a separate action (or just first image)
      // If you want to sync multiple images, you'll need to handle that
      await db.insertPunchAction({
        'task_id': taskId,
        'type': 'punch-out',  // ✅ Fixed: was 'punch_out', should be 'punch-out'
        'lat': position.latitude.toStringAsFixed(6),
        'long': position.longitude.toStringAsFixed(6),
        'remark': controller.text.trim(),
        'image_path': images.first.path, // First image
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      });

      // ✅ DEBUG: Check what was saved
      final allActions = await DBHelper().getPunchActions();
      debugPrint("📊 Total offline actions after punch-out: ${allActions.length}");
      for (var action in allActions) {
        debugPrint("   - ${action['type']} at ${action['timestamp']}");
      }

      // Clear prefs
      await prefs.remove('punchedInTaskId');
      await prefs.remove('punchInStartTime');
      await prefs.remove('onBreak');
      await prefs.remove('pausedDuration');
      await prefs.remove('breakDuration');
      await prefs.remove('breakStartTime');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 Punch-out saved offline. Will sync when online.'),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainApp()),
            (route) => false,
      );
      
      return; // ⛔ STOP HERE
    }

    // ==================== ONLINE MODE ====================
    final uri = Uri.parse('https://admin.deineputzcrew.de/api/punch-out/');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'token $token';
    request.fields.addAll({
      'task_id': taskId,
      'lat': position.latitude.toStringAsFixed(6),
      'long': position.longitude.toStringAsFixed(6),
      'remark': controller.text.trim(),
      'timestamp': DateTime.now().toIso8601String(), // ✅ Added timestamp
    });

    // Attach all images
    for (final image in images) {
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
        filename: basename(image.path),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("📡 Punch-out online response: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      // ✅ Success → clear prefs
      await prefs.remove('punchedInTaskId');
      await prefs.remove('punchInStartTime');
      await prefs.remove('onBreak');
      await prefs.remove('pausedDuration');
      await prefs.remove('breakDuration');
      await prefs.remove('breakStartTime');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Punch-out successful')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainApp()),
            (route) => false,
      );
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
    
  } catch (e) {
    debugPrint('❌ Punch-out exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}


/// Bottom sheet popup
Future<String?> _showStatusPopup(BuildContext context, String currentStatus) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatusPopup(currentStatus: currentStatus);
    },
  );
}

class StatusPopup extends StatefulWidget {
  final String currentStatus;
  const StatusPopup({super.key, required this.currentStatus});

  @override
  State<StatusPopup> createState() => _StatusPopupState();
}

class _StatusPopupState extends State<StatusPopup> {
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Change Status",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins')),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 10),
          _buildStatusOption("Pending", Colors.purple),
          const SizedBox(height: 8),
          _buildStatusOption("Work in progress", Colors.orange),
          const SizedBox(height: 8),
          _buildStatusOption("Completed", Colors.green),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (){


                Navigator.pop(context, selectedStatus);

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff5F55F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Select",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins')),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status, Color color) {
    bool isSelected = selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: color,
            ),
            const SizedBox(width: 10),
            Text(status,
                style: const TextStyle(fontSize: 16, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}
