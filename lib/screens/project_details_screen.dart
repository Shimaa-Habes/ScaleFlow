import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../data/archive_manager.dart';
import '../models/project.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'architecture_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project get project => widget.project;

  late String _projectName;
  late String _projectSubtitle;

  File? _selectedImageFile;
  int _selectedTabIndex = 0;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _mockTasks = [
    {
      'title': 'Review structural blueprints',
      'description':
          'Analyze architectural safety margins and load calculations.',
      'assignee': 'Alexander Wright',
      'points': 5,
      'label': 'Architecture',
      'priority': 'High',
      'isCompleted': true,
    },
    {
      'title': 'Approve electrical schematic layout',
      'description': 'Ensure grid compliance with regional energy codes.',
      'assignee': 'Sophia Martinez',
      'points': 3,
      'label': 'Engineering',
      'priority': 'Medium',
      'isCompleted': false,
    },
  ];

  final List<Map<String, String>> _mockFiles = [
    {
      'name': 'Structural_Blueprint_v2.pdf',
      'size': '14.2 MB',
      'date': '2026-06-10',
      'type': 'pdf'
    },
    {
      'name': 'Budget_Allocation_Q3.xlsx',
      'size': '2.8 MB',
      'date': '2026-06-12',
      'type': 'xls'
    },
  ];

  final List<Map<String, String>> _mockTeam = [
    {
      'name': 'Alexander Wright',
      'role': 'Lead Project Manager',
      'email': 'alex.w@scaleflow.com',
      'avatar': 'AW'
    },
    {
      'name': 'Sophia Martinez',
      'role': 'Senior Architect',
      'email': 'sophia.m@scaleflow.com',
      'avatar': 'SM'
    },
  ];

  @override
  void initState() {
    super.initState();
    _projectName = widget.project.name;
    _projectSubtitle = widget.project.subtitle;
  }

  Future<void> _pickProjectImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project image uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // AI Diagnostic Popup in English Only
  void _showAiPopup(String title, String details, Color color, IconData icon) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Diagnostic Analysis:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  details,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF334155), height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommended Action: Monitor routine updates and optimize human resource allocation to mitigate potential friction.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final assigneeController = TextEditingController(text: 'Alexander Wright');
    final pointsController = TextEditingController(text: '5');
    String selectedLabel = 'Development';
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: const Text('Add New Task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                          labelText: 'Task Title',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: assigneeController,
                      decoration: InputDecoration(
                          labelText: 'Assignee Name',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pointsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: 'Story Points',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            items: ['Low', 'Medium', 'High']
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedPriority = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedLabel,
                      decoration: InputDecoration(
                          labelText: 'Label / Category',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      items: [
                        'Architecture',
                        'Engineering',
                        'Safety',
                        'Development'
                      ]
                          .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedLabel = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _mockTasks.add({
                          'title': titleController.text.trim(),
                          'description': descController.text.trim().isEmpty
                              ? 'No description provided.'
                              : descController.text.trim(),
                          'assignee': assigneeController.text.trim(),
                          'points': int.tryParse(pointsController.text) ?? 3,
                          'label': selectedLabel,
                          'priority': selectedPriority,
                          'isCompleted': false,
                        });
                      });
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Task added successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white),
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _simulateUploadFile() async {
    try {
      final XFile? file = await _picker.pickMedia();
      if (file != null) {
        setState(() {
          _mockFiles.insert(0, {
            'name': file.name,
            'size': '4.2 MB',
            'date': DateTime.now().toString().substring(0, 10),
            'type': file.name.split('.').last,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File "${file.name}" uploaded locally!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File picker simulation initialized!')),
      );
    }
  }

  void _showAddTeamMemberDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Developer';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: const Text('Invite Team Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                    items: [
                      'Lead Project Manager',
                      'Senior Architect',
                      'Site Engineer',
                      'Developer'
                    ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        emailController.text.trim().isNotEmpty) {
                      String initials = nameController.text
                          .trim()
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase();
                      setState(() {
                        _mockTeam.add({
                          'name': nameController.text.trim(),
                          'role': selectedRole,
                          'email': emailController.text.trim(),
                          'avatar': initials,
                        });
                      });
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Invitation email successfully sent to ${emailController.text.trim()}!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white),
                  child: const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProjectDialog() {
    final nameController = TextEditingController(text: _projectName);
    final descriptionController = TextEditingController(text: _projectSubtitle);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Project',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: 'Location / Subtitle',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _projectName = nameController.text.trim();
                    _projectSubtitle = descriptionController.text.trim();
                  });
                }
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        bottomNavigationBar: ScaleFlowBottomNav(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) Navigator.of(context).pop();
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectHeaderImageCard(
                  projectName: _projectName,
                  projectSubtitle: _projectSubtitle,
                  selectedImageFile: _selectedImageFile,
                  onUploadImage: _pickProjectImage,
                  onMenuSelected: (value) {
                    if (value == 'edit') _showEditProjectDialog();
                    if (value == 'upload_image') _pickProjectImage();
                    if (value == 'archive') {
                      ArchiveManager.archive(project);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _ProjectTabsRow(
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // 1. Overview Tab
                if (_selectedTabIndex == 0) ...[
                  const Text('Project Summary & Health',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),

                  // Clean, Perfectly Spaced Health & Description Card (Fixed Overlap)
                  _ProjectDescriptionAndHealthCard(
                    projectName: _projectName,
                    projectSubtitle: _projectSubtitle,
                  ),
                  const SizedBox(height: 22),

                  // New Architecture Section Card
                  const Text('Project Architecture',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  _AiDiagnosticCard(
                    title: 'System Architecture View',
                    subtitle:
                        'Tap to inspect system architecture, layers & components',
                    status: 'View Map',
                    statusColor: const Color(0xFF4F46E5),
                    icon: Icons.account_tree_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ArchitecturePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  const Text('AI Diagnostic Modules',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),

                  // Bottleneck Detector
                  _AiDiagnosticCard(
                    title: 'Bottleneck Detector',
                    subtitle:
                        'Resource load congestion identified in Foundation Phase',
                    status: 'Moderate Risk',
                    statusColor: Colors.orange,
                    icon: Icons.hourglass_bottom,
                    onTap: () => _showAiPopup(
                      'Bottleneck Detector Analysis',
                      'AI Insight: Resource congestion detected within the foundation phase due to concurrent task scheduling. Reallocating engineering resources is advised to minimize wait times.',
                      Colors.orange,
                      Icons.hourglass_bottom,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Risk Prediction Model
                  _AiDiagnosticCard(
                    title: 'Risk Prediction Model',
                    subtitle:
                        'Weather delays and material supply chain volatility',
                    status: 'High Priority',
                    statusColor: Colors.red,
                    icon: Icons.warning_amber_rounded,
                    onTap: () => _showAiPopup(
                      'Risk Prediction Analysis',
                      'AI Insight: A 15% delay probability is noted due to weather variations and raw material supply chain shifts. Contingency vendor strategies have been engaged.',
                      Colors.red,
                      Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Delay Forecast Engine
                  _AiDiagnosticCard(
                    title: 'Delay Forecast Engine',
                    subtitle:
                        'Current velocity suggests project completion on target (+2 days buffer)',
                    status: 'Stable',
                    statusColor: Colors.green,
                    icon: Icons.trending_up,
                    onTap: () => _showAiPopup(
                      'Delay Forecast Analysis',
                      'AI Insight: Task velocity metrics are exceptional. The project is proceeding on schedule with a reliable two-day proactive completion buffer.',
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Project Health Matrix
                  _AiDiagnosticCard(
                    title: 'Project Health Matrix',
                    subtitle:
                        'Financial allocation and team sentiment index is optimal',
                    status: '92 / 100 Score',
                    statusColor: const Color(0xFF4F46E5),
                    icon: Icons.health_and_safety_outlined,
                    onTap: () => _showAiPopup(
                      'Project Health Matrix Analysis',
                      'AI Insight: Financial expenditure distribution remains balanced and team morale metrics are peaking. Overall project health index is optimal.',
                      const Color(0xFF4F46E5),
                      Icons.health_and_safety_outlined,
                    ),
                  ),

                  const SizedBox(height: 22),
                  const Text('Key Metrics',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  const _KeyMetricsRow(),
                ]
                // 2. Tasks Tab
                else if (_selectedTabIndex == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Project Tasks',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      ElevatedButton.icon(
                        onPressed: _showAddTaskDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Task'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mockTasks.length,
                    itemBuilder: (context, index) {
                      final task = _mockTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: task['isCompleted'],
                                  activeColor: const Color(0xFF4F46E5),
                                  onChanged: (val) {
                                    setState(() {
                                      task['isCompleted'] = val ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    task['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: task['isCompleted']
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task['isCompleted']
                                          ? Colors.grey
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: task['priority'] == 'High'
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    task['priority'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: task['priority'] == 'High'
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['description'],
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 14, color: Color(0xFF4F46E5)),
                                      const SizedBox(width: 4),
                                      Text(task['assignee'],
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4F46E5))),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text('Points: ${task['points']}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.indigo.shade50,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(task['label'],
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]
                // 3. Files Tab
                else if (_selectedTabIndex == 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Project Files',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      ElevatedButton.icon(
                        onPressed: _simulateUploadFile,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Upload File'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mockFiles.length,
                    itemBuilder: (context, index) {
                      final file = _mockFiles[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file,
                                color: Color(0xFF4F46E5), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(file['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${file['size'] ?? ''} • ${file['date'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download,
                                  size: 20, color: Colors.grey),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Opening ${file['name']}...')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]
                // 4. Team Tab
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Team Members',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      ElevatedButton.icon(
                        onPressed: _showAddTeamMemberDialog,
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add Member'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mockTeam.length,
                    itemBuilder: (context, index) {
                      final member = _mockTeam[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF4F46E5).withOpacity(0.1),
                              foregroundColor: const Color(0xFF4F46E5),
                              child: Text(member['avatar'] ?? 'U',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(member['role'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF4F46E5))),
                                  Text(member['email'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text('Invited',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectHeaderImageCard extends StatelessWidget {
  final String projectName;
  final String projectSubtitle;
  final File? selectedImageFile;
  final VoidCallback onUploadImage;
  final ValueChanged<String> onMenuSelected;

  const _ProjectHeaderImageCard({
    required this.projectName,
    required this.projectSubtitle,
    required this.selectedImageFile,
    required this.onUploadImage,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    const defaultImageUrl =
        'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b3?auto=format&fit=crop&w=1000&q=80';

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: selectedImageFile != null
                  ? Image.file(selectedImageFile!, fit: BoxFit.cover)
                  : Image.network(
                      defaultImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFCBD5E1),
                        child: const Icon(Icons.apartment,
                            size: 50, color: Colors.white),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.30),
                      Colors.transparent,
                      Colors.black.withOpacity(0.70),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 18,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: Color(0xFF1E293B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt_outlined,
                              size: 18, color: Color(0xFF1E293B)),
                          onPressed: onUploadImage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        radius: 18,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: onMenuSelected,
                          icon: const Icon(Icons.more_horiz,
                              size: 20, color: Color(0xFF1E293B)),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'upload_image',
                                child: Text('Upload Image')),
                            PopupMenuItem(
                                value: 'edit', child: Text('Edit Details')),
                            PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(projectName,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(projectSubtitle,
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTabsRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _ProjectTabsRow(
      {required this.selectedIndex, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Overview', 'Tasks', 'Files', 'Team'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onTabSelected(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 3,
                width: isSelected ? 32 : 0,
                decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Clean, Perfectly Spaced Health & Description Card (Fixed layout & padding to prevent overflow)
class _ProjectDescriptionAndHealthCard extends StatelessWidget {
  final String projectName;
  final String projectSubtitle;

  const _ProjectDescriptionAndHealthCard({
    required this.projectName,
    required this.projectSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.5,
                  child: CircularProgressIndicator(
                    value: 0.92,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 62, 135, 70)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '92%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Health',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  projectSubtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.person_outline,
                        size: 13, color: Color(0xFF4F46E5)),
                    SizedBox(width: 4),
                    Text('Owner: ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey)),
                    Expanded(
                      child: Text('Shimaa Habes',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Clean and sleek AI Diagnostic Card
class _AiDiagnosticCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;
  final VoidCallback onTap;

  const _AiDiagnosticCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _KeyMetricsRow extends StatelessWidget {
  const _KeyMetricsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MetricCard(title: 'Budget', value: '\$1.8M')),
        SizedBox(width: 8),
        Expanded(child: _MetricCard(title: 'Spent', value: '\$720K')),
        SizedBox(width: 8),
        Expanded(child: _MetricCard(title: 'Velocity', value: '14 pts/w')),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
