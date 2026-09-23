import 'package:flutter/material.dart';

import '../models/project_architecture.dart';
import '../services/architecture_service.dart';

class ArchitecturePage extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ArchitecturePage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ArchitecturePage> createState() => _ArchitecturePageState();
}

class _ArchitecturePageState extends State<ArchitecturePage> {
  final ArchitectureService _architectureService = ArchitectureService();

  ProjectArchitecture? _architecture;

  bool _isLoading = true;
  bool _isSaving = false;

  static const Color _background = Color(0xFFF6F7FB);
  static const Color _text = Color(0xFF2C2D30);
  static const Color _muted = Color(0xFF73777F);
  static const Color _purple = Color(0xFF6C5CE7);
  static const Color _blue = Color(0xFF5B9BD5);
  static const Color _green = Color(0xFF72B968);
  static const Color _coral = Color(0xFFE88973);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadArchitecture();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadArchitecture() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final architecture =
          await _architectureService.getArchitecture(widget.projectId);

      if (!mounted) return;

      setState(() {
        _architecture = architecture;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Failed to load architecture: ${_cleanErrorMessage(e)}',
      );
    }
  }

  // ============================================================
  // FORM
  // ============================================================

  Future<void> _openArchitectureForm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _ArchitectureFormDialog(
          architecture: _architecture,
          onSave: _saveArchitecture,
        );
      },
    );

    if (result == true) {
      await _loadArchitecture();
    }
  }

  Future<void> _saveArchitecture(
    Map<String, String?> values,
  ) async {
    if (_isSaving) return;

    final isCreating = _architecture == null;

    setState(() {
      _isSaving = true;
    });

    try {
      ProjectArchitecture saved;

      if (isCreating) {
        saved = await _architectureService.createArchitecture(
          projectId: widget.projectId,
          frontend: values['frontend'],
          backend: values['backend'],
          database: values['database'],
          authentication: values['authentication'],
          aiMl: values['aiMl'],
          realTime: values['realTime'],
          externalServices: values['externalServices'],
        );
      } else {
        saved = await _architectureService.updateArchitecture(
          projectId: widget.projectId,
          frontend: values['frontend'],
          backend: values['backend'],
          database: values['database'],
          authentication: values['authentication'],
          aiMl: values['aiMl'],
          realTime: values['realTime'],
          externalServices: values['externalServices'],
        );
      }

      if (!mounted) return;

      setState(() {
        _architecture = saved;
        _isSaving = false;
      });

      Navigator.of(context).pop(true);

      _showMessage(
        isCreating
            ? 'Architecture created successfully.'
            : 'Architecture updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save architecture: ${_cleanErrorMessage(e)}',
      );
    }
  }

  // ============================================================
  // STATE
  // ============================================================

  bool get _hasArchitecture {
    final a = _architecture;

    if (a == null) return false;

    return [
      a.frontend,
      a.backend,
      a.database,
      a.authentication,
      a.aiMl,
      a.realTime,
      a.externalServices,
    ].any(
      (value) => value != null && value.trim().isNotEmpty,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _text,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Architecture',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading && _hasArchitecture)
            IconButton(
              tooltip: 'Edit Architecture',
              onPressed: _isSaving ? null : _openArchitectureForm,
              icon: const Icon(
                Icons.edit_outlined,
                color: _purple,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _purple,
              ),
            )
          : !_hasArchitecture
              ? _buildEmptyState()
              : _buildTree(),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  size: 38,
                  color: _purple,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Architecture Added',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add the technologies and services used in this project to build its architecture tree.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _openArchitectureForm,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add Architecture',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TREE
  // ============================================================

  Widget _buildTree() {
    final a = _architecture!;

    return RefreshIndicator(
      color: _purple,
      onRefresh: _loadArchitecture,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              children: [
                _buildTreeHeader(),

                const SizedBox(height: 24),

                // ==================================================
                // ROOT
                // ==================================================

                _TreeRootNode(
                  title: widget.projectName,
                  subtitle: 'Project Architecture',
                  icon: Icons.account_tree_rounded,
                ),

                _buildTreeConnector(),

                // ==================================================
                // LAYER 1
                // ==================================================

                _buildLayerNode(
                  layerNumber: '01',
                  title: 'User Applications',
                  subtitle: 'Application / Frontend',
                  icon: Icons.devices_outlined,
                  color: _blue,
                  branches: [
                    _TreeBranch(
                      label: 'Frontend',
                      value: a.frontend,
                      icon: Icons.web_outlined,
                    ),
                  ],
                ),

                _buildTreeConnector(),

                // ==================================================
                // LAYER 2
                // ==================================================

                _buildLayerNode(
                  layerNumber: '02',
                  title: 'Backend API',
                  subtitle: 'Application Services',
                  icon: Icons.dns_outlined,
                  color: _purple,
                  branches: [
                    _TreeBranch(
                      label: 'Backend',
                      value: a.backend,
                      icon: Icons.code_rounded,
                    ),
                    _TreeBranch(
                      label: 'Authentication',
                      value: a.authentication,
                      icon: Icons.lock_outline_rounded,
                    ),
                    _TreeBranch(
                      label: 'Real-Time',
                      value: a.realTime,
                      icon: Icons.sync_rounded,
                    ),
                  ],
                ),

                _buildTreeConnector(),

                // ==================================================
                // LAYER 3
                // ==================================================

                _buildLayerNode(
                  layerNumber: '03',
                  title: 'Data',
                  subtitle: 'Data Storage',
                  icon: Icons.storage_outlined,
                  color: _green,
                  branches: [
                    _TreeBranch(
                      label: 'Database',
                      value: a.database,
                      icon: Icons.storage_rounded,
                    ),
                  ],
                ),

                _buildTreeConnector(),

                // ==================================================
                // LAYER 4
                // ==================================================

                _buildLayerNode(
                  layerNumber: '04',
                  title: 'AI & Intelligence',
                  subtitle: 'Intelligent Services',
                  icon: Icons.auto_awesome_outlined,
                  color: _coral,
                  branches: [
                    _TreeBranch(
                      label: 'AI / ML',
                      value: a.aiMl,
                      icon: Icons.auto_awesome_rounded,
                    ),
                    _TreeBranch(
                      label: 'External Services',
                      value: a.externalServices,
                      icon: Icons.extension_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildEditBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TREE HEADER
  // ============================================================

  Widget _buildTreeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: _purple,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Architecture',
                  style: TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Project-specific architecture tree',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: _openArchitectureForm,
            icon: const Icon(
              Icons.edit_outlined,
              color: _purple,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAYER NODE
  // ============================================================

  Widget _buildLayerNode({
    required String layerNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<_TreeBranch> branches,
  }) {
    final visibleBranches = branches
        .where(
          (branch) => branch.value != null && branch.value!.trim().isNotEmpty,
        )
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // -----------------------------
          // Layer header
          // -----------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.055),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layer $layerNumber',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------
          // Tree branches
          // -----------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: visibleBranches.isEmpty
                ? _buildEmptyBranch()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;

                      if (visibleBranches.length == 1) {
                        return _buildSingleBranch(
                          visibleBranches.first,
                          color,
                        );
                      }

                      return _buildBranchTree(
                        visibleBranches,
                        color,
                        isWide,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBranch(
    _TreeBranch branch,
    Color color,
  ) {
    return Row(
      children: [
        _BranchConnector(
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBranchCard(
            branch,
            color,
          ),
        ),
      ],
    );
  }

  Widget _buildBranchTree(
    List<_TreeBranch> branches,
    Color color,
    bool isWide,
  ) {
    return Column(
      children: [
        // Horizontal trunk.
        Container(
          height: 1.5,
          width: double.infinity,
          color: color.withOpacity(0.20),
        ),

        const SizedBox(height: 12),

        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              branches.length,
              (index) {
                final branch = branches[index];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 5,
                      right: index == branches.length - 1 ? 0 : 5,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 18,
                          width: 1.5,
                          color: color.withOpacity(0.20),
                        ),
                        _buildBranchCard(
                          branch,
                          color,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          Column(
            children: List.generate(
              branches.length,
              (index) {
                final branch = branches[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == branches.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 18,
                            width: 1.5,
                            color: color.withOpacity(0.20),
                          ),
                          _BranchConnector(
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildBranchCard(
                          branch,
                          color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBranchCard(
    _TreeBranch branch,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              branch.icon,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  branch.value!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBranch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.remove_circle_outline,
            size: 18,
            color: _muted,
          ),
          SizedBox(width: 10),
          Text(
            'No data added for this layer.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTOR BETWEEN LAYERS
  // ============================================================

  Widget _buildTreeConnector() {
    return Column(
      children: [
        Container(
          width: 2,
          height: 20,
          color: _purple.withOpacity(0.22),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _border,
            ),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: _muted,
          ),
        ),
        Container(
          width: 2,
          height: 20,
          color: _purple.withOpacity(0.22),
        ),
      ],
    );
  }

  // ============================================================
  // EDIT BANNER
  // ============================================================

  Widget _buildEditBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _purple.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: _purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Architecture is editable',
                  style: TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Update the project architecture whenever the technology stack changes.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openArchitectureForm,
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: _purple,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ================================================================
// TREE ROOT
// ================================================================

class _TreeRootNode extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TreeRootNode({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 420,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.25),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6C5CE7),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project',
                  style: TextStyle(
                    color: Color(0xFF73777F),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2C2D30),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BRANCH MODEL
// ================================================================

class _TreeBranch {
  final String label;
  final String? value;
  final IconData icon;

  const _TreeBranch({
    required this.label,
    required this.value,
    required this.icon,
  });
}

// ================================================================
// BRANCH CONNECTOR
// ================================================================

class _BranchConnector extends StatelessWidget {
  final Color color;

  const _BranchConnector({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 2,
      color: color.withOpacity(0.22),
    );
  }
}

// ================================================================
// FORM
// ================================================================

class _ArchitectureFormDialog extends StatefulWidget {
  final ProjectArchitecture? architecture;
  final Future<void> Function(Map<String, String?> values) onSave;

  const _ArchitectureFormDialog({
    required this.architecture,
    required this.onSave,
  });

  @override
  State<_ArchitectureFormDialog> createState() =>
      _ArchitectureFormDialogState();
}

class _ArchitectureFormDialogState extends State<_ArchitectureFormDialog> {
  late final TextEditingController _frontendController;
  late final TextEditingController _backendController;
  late final TextEditingController _databaseController;
  late final TextEditingController _authenticationController;
  late final TextEditingController _aiMlController;
  late final TextEditingController _realTimeController;
  late final TextEditingController _externalServicesController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final a = widget.architecture;

    _frontendController = TextEditingController(
      text: a?.frontend ?? '',
    );

    _backendController = TextEditingController(
      text: a?.backend ?? '',
    );

    _databaseController = TextEditingController(
      text: a?.database ?? '',
    );

    _authenticationController = TextEditingController(
      text: a?.authentication ?? '',
    );

    _aiMlController = TextEditingController(
      text: a?.aiMl ?? '',
    );

    _realTimeController = TextEditingController(
      text: a?.realTime ?? '',
    );

    _externalServicesController = TextEditingController(
      text: a?.externalServices ?? '',
    );
  }

  @override
  void dispose() {
    _frontendController.dispose();
    _backendController.dispose();
    _databaseController.dispose();
    _authenticationController.dispose();
    _aiMlController.dispose();
    _realTimeController.dispose();
    _externalServicesController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave({
        'frontend': _frontendController.text,
        'backend': _backendController.text,
        'database': _databaseController.text,
        'authentication': _authenticationController.text,
        'aiMl': _aiMlController.text,
        'realTime': _realTimeController.text,
        'externalServices': _externalServicesController.text,
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.architecture != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        24,
        24,
        16,
        8,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        8,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        20,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isEdit ? 'Edit Architecture' : 'Add Architecture',
              style: const TextStyle(
                color: Color(0xFF2C2D30),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter the real technologies and services used by this project.',
                  style: TextStyle(
                    color: Color(0xFF73777F),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildField(
                controller: _frontendController,
                label: 'Frontend',
                hint: 'Flutter, React, Next.js...',
                icon: Icons.devices_outlined,
              ),
              _buildField(
                controller: _backendController,
                label: 'Backend',
                hint: 'ASP.NET Core, Node.js...',
                icon: Icons.dns_outlined,
              ),
              _buildField(
                controller: _databaseController,
                label: 'Database',
                hint: 'SQL Server, MongoDB...',
                icon: Icons.storage_outlined,
              ),
              _buildField(
                controller: _authenticationController,
                label: 'Authentication',
                hint: 'JWT, OAuth...',
                icon: Icons.lock_outline_rounded,
              ),
              _buildField(
                controller: _aiMlController,
                label: 'AI / ML',
                hint: 'Risk Prediction, ML API...',
                icon: Icons.auto_awesome_outlined,
              ),
              _buildField(
                controller: _realTimeController,
                label: 'Real-Time',
                hint: 'SignalR, WebSocket...',
                icon: Icons.sync_rounded,
              ),
              _buildField(
                controller: _externalServicesController,
                label: 'External Services',
                hint: 'Groq API, Cloud Storage...',
                icon: Icons.extension_outlined,
              ),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF6C5CE7).withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEdit ? 'Save Changes' : 'Save Architecture',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF6C5CE7),
          ),
          filled: true,
          fillColor: const Color(0xFFF6F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF6C5CE7),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
