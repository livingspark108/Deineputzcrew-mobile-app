import 'package:flutter/material.dart';


class CompleteTaskScreen extends StatefulWidget {
  const CompleteTaskScreen({super.key});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  final TextEditingController remarkController = TextEditingController();

  final List<String> images = [
    'assets/images/pic.png',
    'assets/images/pic.png',
    'assets/images/pic.png',
    'assets/images/pic.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Complete Task",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please add Remark and photos to mark the task as completed.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),

            // Remarks Field
            TextField(
              controller: remarkController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Remarks",
                hintText: "Enter your task name",
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

            // Attachments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Attachments (${images.length})",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
                OutlinedButton.icon(
                  onPressed: () {
                    // Add image picker logic here
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text("Add Attachment"),
                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          images[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              images.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Mark as Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Submit logic
                  final remark = remarkController.text.trim();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Task Completed with remark: $remark and ${images.length} images")),
                  );
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("Mark as Complete",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
