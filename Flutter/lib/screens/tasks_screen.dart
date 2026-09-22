import 'package:flutter/material.dart';

// ============================================================
// SCALEFLOW COLORS & CONSTANTS
// ============================================================
const Color _charcoal = Color(0xFF2C2D30);
const Color _softText = Color(0xFF666A70);
const Color _mutedText = Color(0xFF858990);
const Color _pageBackground = Color(0xFFF7F6FB);
const Color _purple = Color(0xFF6C5CE7);

// ============================================================
// TASK MODEL WITH START & DUE DATE
// ============================================================
class TaskModel {
  String title;
  String subtitle;
  String time;
  String priority; // High, Medium, Low
  String status; // To Do, In Progress, Done
  DateTime startDate;
  DateTime dueDate;
  bool isCompleted;

  TaskModel({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.priority,
    required this.status,
    required this.startDate,
    required this.dueDate,
    this.isCompleted = false,
  });
}

// ============================================================
// TASKS SCREEN
// ============================================================
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'All'; // All, To Do, In Progress, Done

  // Mock Tasks List matching reference
  final List<TaskModel> _tasks = [
    TaskModel(
      title: 'Site Inspection',
      subtitle: 'Midtown Tower Project',
      time: '10:00 AM',
      priority: 'High',
      status: 'In Progress',
      startDate: DateTime.now(),
      dueDate: DateTime.now(),
    ),
    TaskModel(
      title: 'Material Delivery',
      subtitle: 'Riverside Residence',
      time: '2:00 PM',
      priority: 'Medium',
      status: 'To Do',
      startDate: DateTime.now(),
      dueDate: DateTime.now(),
    ),
    TaskModel(
      title: 'Design Review',
      subtitle: 'Commercial Complex',
      time: '4:00 PM',
      priority: 'Low',
      status: 'To Do',
      startDate: DateTime.now(),
      dueDate: DateTime.now(),
    ),
    TaskModel(
      title: 'Client Call',
      subtitle: 'West End Plaza',
      time: '5:30 PM',
      priority: 'Low',
      status: 'Done',
      startDate: DateTime.now(),
      dueDate: DateTime.now(),
    ),
  ];

  List<TaskModel> get _filteredTasks {
    return _tasks.where((task) {
      final matchesSearch =
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              task.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedTab == 'All') return matchesSearch;
      if (_selectedTab == 'To Do') {
        return matchesSearch && task.status == 'To Do';
      }
      if (_selectedTab == 'In Progress') {
        return matchesSearch && task.status == 'In Progress';
      }
      if (_selectedTab == 'Done') return matchesSearch && task.status == 'Done';
      return matchesSearch;
    }).toList();
  }

  // Open Add Task Dialog with Start Date & Due Date
  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedStatus = 'To Do';
    DateTime startDate = DateTime.now();
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Add New Task',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: InputDecoration(
                        labelText: 'Project / Subtitle',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Low', 'Medium', 'High']
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedPriority = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['To Do', 'In Progress', 'Done']
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedStatus = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade400)),
                      title: Text(
                          'Start Date: ${startDate.toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.calendar_today,
                          size: 18, color: _purple),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade400)),
                      title: Text(
                          'Due Date: ${dueDate.toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.event_available,
                          size: 18, color: _purple),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _tasks.add(TaskModel(
                          title: titleController.text.trim(),
                          subtitle: subtitleController.text.trim().isEmpty
                              ? 'General Task'
                              : subtitleController.text.trim(),
                          time: '09:00 AM',
                          priority: selectedPriority,
                          status: selectedStatus,
                          startDate: startDate,
                          dueDate: dueDate,
                        ));
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Task added successfully!')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: _charcoal),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tasks',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _charcoal),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _purple,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScheduleCalendarScreen()),
                          );
                        },
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text('Calendar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAddTaskDialog,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: _purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: _mutedText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Search tasks...',
                          hintStyle: TextStyle(fontSize: 13, color: _mutedText),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13, color: _charcoal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', 'To Do', 'In Progress', 'Done'].map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? _purple : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? []
                              : const [
                                  BoxShadow(
                                      color: Color(0x08000000), blurRadius: 4)
                                ],
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _softText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text('Today',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _charcoal)),
                  const SizedBox(height: 8),
                  ..._filteredTasks.map((task) => _buildTaskCard(task)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    Color priorityColor = Colors.green;
    if (task.priority == 'High') priorityColor = Colors.red;
    if (task.priority == 'Medium') priorityColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.task_alt, color: _purple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(task.subtitle,
                    style: const TextStyle(fontSize: 11, color: _mutedText)),
                const SizedBox(height: 4),
                Text(task.time,
                    style: const TextStyle(fontSize: 10.5, color: _softText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor),
                ),
              ),
              const SizedBox(height: 6),
              Checkbox(
                value: task.isCompleted,
                activeColor: _purple,
                visualDensity: VisualDensity.compact,
                onChanged: (val) {
                  setState(() {
                    task.isCompleted = val ?? false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCHEDULE / CALENDAR SCREEN
// ============================================================
class ScheduleCalendarScreen extends StatefulWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  bool _isTimelineView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: _charcoal),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Schedule & Calendar',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _charcoal)),
                    ],
                  ),
                  ToggleButtons(
                    isSelected: [_isTimelineView, !_isTimelineView],
                    onPressed: (index) {
                      setState(() {
                        _isTimelineView = index == 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: _purple,
                    color: _charcoal,
                    constraints:
                        const BoxConstraints(minHeight: 32, minWidth: 45),
                    children: const [
                      Icon(Icons.view_agenda_outlined, size: 18),
                      Icon(Icons.calendar_month_outlined, size: 18),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isTimelineView
                  ? _buildTimelineView()
                  : _buildColorCalendarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    final hours = [
      '9 AM',
      '10 AM',
      '11 AM',
      '12 PM',
      '1 PM',
      '2 PM',
      '3 PM',
      '4 PM'
    ];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 55,
                child: Text(hours[index],
                    style: const TextStyle(
                        fontSize: 12,
                        color: _mutedText,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                        left: BorderSide(color: _purple, width: 4)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x08000000), blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task at ${hours[index]}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _charcoal)),
                      const SizedBox(height: 2),
                      const Text('In Progress • Assigned to Team',
                          style: TextStyle(fontSize: 11, color: _softText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorCalendarView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8)
            ],
          ),
          child: Column(
            children: [
              const Text('September 2026',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _charcoal)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: 31,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isToday = day == 21;
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? _purple : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : _charcoal,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text("Today's Scheduled Tasks",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: _charcoal)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('09:00 - 10:00 am',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Project Architecture Sync',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _charcoal)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('10:00 - 11:00 am',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Security Vulnerability Scan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _charcoal)),
            ],
          ),
        ),
      ],
    );
  }
}
