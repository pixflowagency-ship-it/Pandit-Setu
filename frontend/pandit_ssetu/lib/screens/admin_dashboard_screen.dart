import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Colors matching SARV MANGAL theme
  static const Color primarySaffron = Color(0xFFE65100);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color darkBg = Color(0xFF1E1E24);
  static const Color cardBg = Colors.white;

  // Overview stats state
  bool _loadingStats = true;
  String? _statsError;
  Map<String, dynamic>? _stats;

  // Pandit KYC state
  bool _loadingPandits = true;
  String? _panditsError;
  List<Map<String, dynamic>> _pandits = [];
  String _panditStatusFilter = 'PENDING';

  // Subscriptions state
  bool _loadingSubscriptions = true;
  String? _subscriptionsError;
  List<Map<String, dynamic>> _subscriptions = [];
  String _subStatusFilter = 'ALL';

  // Consultations state
  bool _loadingConsultations = true;
  String? _consultationsError;
  List<Map<String, dynamic>> _consultations = [];
  String _consultationStatusFilter = 'ALL';

  // Kundli Orders state
  bool _loadingKundliOrders = true;
  String? _kundliOrdersError;
  List<Map<String, dynamic>> _kundliOrders = [];
  String _kundliStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchStats(),
      _fetchPandits(),
      _fetchSubscriptions(),
      _fetchConsultations(),
      _fetchKundliOrders(),
    ]);
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final res = await ApiService.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = res;
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsError = e.toString().replaceAll('Exception: ', '');
          _loadingStats = false;
        });
      }
    }
  }

  Future<void> _fetchPandits() async {
    setState(() {
      _loadingPandits = true;
      _panditsError = null;
    });

    try {
      final res = await ApiService.getAdminPandits(
        status: _panditStatusFilter,
        page: 1,
        limit: 50,
      );
      if (mounted) {
        final items = res['items'] as List<dynamic>? ?? [];
        setState(() {
          _pandits = items.map((e) => Map<String, dynamic>.from(e)).toList();
          _loadingPandits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _panditsError = e.toString().replaceAll('Exception: ', '');
          _loadingPandits = false;
        });
      }
    }
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _loadingSubscriptions = true;
      _subscriptionsError = null;
    });

    try {
      final res = await ApiService.getAdminSubscriptions(
        status: _subStatusFilter,
        page: 1,
        limit: 50,
      );
      if (mounted) {
        final items = res['items'] as List<dynamic>? ?? [];
        setState(() {
          _subscriptions =
              items.map((e) => Map<String, dynamic>.from(e)).toList();
          _loadingSubscriptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscriptionsError = e.toString().replaceAll('Exception: ', '');
          _loadingSubscriptions = false;
        });
      }
    }
  }

  Future<void> _fetchConsultations() async {
    setState(() {
      _loadingConsultations = true;
      _consultationsError = null;
    });

    try {
      final res = await ApiService.getAdminConsultations(
        status: _consultationStatusFilter == 'ALL' ? null : _consultationStatusFilter,
        page: 1,
        limit: 50,
      );
      if (mounted) {
        final items = res['items'] as List<dynamic>? ?? [];
        setState(() {
          _consultations = items.map((e) => Map<String, dynamic>.from(e)).toList();
          _loadingConsultations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _consultationsError = e.toString().replaceAll('Exception: ', '');
          _loadingConsultations = false;
        });
      }
    }
  }

  Future<void> _fetchKundliOrders() async {
    setState(() {
      _loadingKundliOrders = true;
      _kundliOrdersError = null;
    });

    try {
      final res = await ApiService.getAdminKundliOrders(
        status: _kundliStatusFilter == 'ALL' ? null : _kundliStatusFilter,
        page: 1,
        limit: 50,
      );
      if (mounted) {
        final items = res['items'] as List<dynamic>? ?? [];
        setState(() {
          _kundliOrders = items.map((e) => Map<String, dynamic>.from(e)).toList();
          _loadingKundliOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kundliOrdersError = e.toString().replaceAll('Exception: ', '');
          _loadingKundliOrders = false;
        });
      }
    }
  }

  Future<void> _handleApprovePandit(String panditId, String panditName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Pandit Application'),
        content: Text(
          'Are you sure you want to approve $panditName as a verified SARV MANGAL Pandit? '
          'This will allow them to accept bookings and go on-duty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminApprovePandit(panditId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$panditName has been approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectPandit(String panditId, String panditName) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please provide a mandatory rejection reason for $panditName:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'e.g. Unclear identity documents or insufficient experience',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Reason cannot be empty';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminRejectPandit(panditId, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application for $panditName was rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleScheduleConsultation(Map<String, dynamic> c) async {
    final TextEditingController linkCtrl = TextEditingController(text: c['meetingLink'] ?? '');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Schedule: ${c['consultationNumber']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Topic: ${c['topic'] ?? 'General Consultation'}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setDlgState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(selectedTime.format(ctx)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDlgState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (c['type'] == 'ONLINE') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Meeting URL (Optional)',
                    hintText: 'https://meet.google.com/...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Schedule', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final scheduledIso = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toUtc().toIso8601String();

    try {
      await ApiService.adminScheduleConsultation(
        c['id'],
        scheduledDateTime: scheduledIso,
        meetingLink: linkCtrl.text.trim().isNotEmpty ? linkCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation ${c['consultationNumber']} scheduled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchConsultations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scheduling failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAssignConsultation(Map<String, dynamic> c) async {
    final verifiedPandits = _pandits.where((p) => p['verificationStatus'] == 'APPROVED').toList();
    if (verifiedPandits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No verified/approved Pandits available for assignment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String selectedPanditId = verifiedPandits.first['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Assign Pandit: ${c['consultationNumber']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select an approved Vedic Pandit:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPanditId,
                isExpanded: true,
                items: verifiedPandits.map((p) {
                  final name = p['userName'] ?? 'Pandit';
                  final spec = p['vedicSpecialization'] ?? 'Vedic Karmakand';
                  return DropdownMenuItem<String>(
                    value: p['id'] as String,
                    child: Text('$name ($spec)', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => selectedPanditId = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Assign', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminAssignPanditToConsultation(
        c['id'],
        panditId: selectedPanditId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pandit assigned to ${c['consultationNumber']}.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchConsultations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdateConsultationStatus(Map<String, dynamic> c) async {
    const statuses = ['REQUESTED', 'UNDER_REVIEW', 'SCHEDULED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REJECTED'];
    String selectedStatus = c['status'] ?? 'UNDER_REVIEW';
    final TextEditingController reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Update Status: ${c['consultationNumber']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedStatus = val);
                },
                decoration: const InputDecoration(labelText: 'Target Status'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason / Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminUpdateConsultationStatus(
        c['id'],
        status: selectedStatus,
        reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $selectedStatus.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchConsultations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDecisionKundli(Map<String, dynamic> k, String decision) async {
    final TextEditingController reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${decision == 'ACCEPT' ? 'Accept' : 'Reject'} Kundli Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${k['orderNumber']}'),
            Text('Devotee: ${k['devoteeName']}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: decision == 'REJECT' ? 'Rejection Reason *' : 'Notes / Instructions (Optional)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == 'ACCEPT' ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (decision == 'REJECT' && reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Rejection reason is required.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(decision, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminDecisionKundliOrder(
        k['id'],
        decision: decision,
        reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${k['orderNumber']} ${decision == 'ACCEPT' ? 'accepted' : 'rejected'}.'),
            backgroundColor: decision == 'ACCEPT' ? Colors.green : Colors.orange,
          ),
        );
        _fetchKundliOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Decision failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAssignKundli(Map<String, dynamic> k) async {
    final verifiedPandits = _pandits.where((p) => p['verificationStatus'] == 'APPROVED').toList();
    if (verifiedPandits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No verified Pandits available for assignment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String selectedPanditId = verifiedPandits.first['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Assign Acharya: ${k['orderNumber']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Jyotish Acharya for manuscript preparation:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPanditId,
                isExpanded: true,
                items: verifiedPandits.map((p) {
                  final name = p['userName'] ?? 'Pandit';
                  final spec = p['vedicSpecialization'] ?? 'Jyotish';
                  return DropdownMenuItem<String>(
                    value: p['id'] as String,
                    child: Text('$name ($spec)', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => selectedPanditId = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Assign', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminAssignPanditToKundli(
        k['id'],
        panditId: selectedPanditId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acharya assigned to order ${k['orderNumber']}.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchKundliOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdateKundliStatus(Map<String, dynamic> k) async {
    const statuses = ['REQUESTED', 'UNDER_REVIEW', 'ACCEPTED', 'PAYMENT_PENDING', 'PAID', 'ASSIGNED', 'PREPARING', 'READY', 'DISPATCHED', 'DELIVERED', 'CANCELLED', 'REJECTED'];
    String selectedStatus = k['status'] ?? 'PREPARING';
    final TextEditingController courierCtrl = TextEditingController(text: k['courierPartner'] ?? 'India Post / Speed Post');
    final TextEditingController trackCtrl = TextEditingController(text: k['trackingNumber'] ?? '');
    final TextEditingController notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Update Status: ${k['orderNumber']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                  decoration: const InputDecoration(labelText: 'Target Status'),
                ),
                if (selectedStatus == 'DISPATCHED') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: courierCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Courier Partner *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: trackCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tracking Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Reason (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.adminUpdateKundliStatus(
        k['id'],
        status: selectedStatus,
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
        courierPartner: selectedStatus == 'DISPATCHED' ? courierCtrl.text.trim() : null,
        trackingNumber: selectedStatus == 'DISPATCHED' ? trackCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kundli status updated to $selectedStatus.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchKundliOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status update failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showKundliDetailSheet(Map<String, dynamic> k) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          k['orderNumber'] ?? 'Kundli Order',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primarySaffron,
                          ),
                        ),
                      ),
                      _buildStatusBadge(k['status'] ?? 'REQUESTED'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  _buildDetailRow(Icons.person, 'Devotee Name', k['devoteeName'] ?? 'N/A'),
                  _buildDetailRow(Icons.phone, 'Devotee Phone', k['devoteePhone'] ?? 'N/A'),
                  _buildDetailRow(Icons.calendar_today, 'Date of Birth', k['dob'] ?? 'N/A'),
                  _buildDetailRow(Icons.access_time, 'Time of Birth', k['tob'] ?? 'N/A'),
                  _buildDetailRow(Icons.location_city, 'Place of Birth', k['pob'] ?? 'N/A'),
                  _buildDetailRow(Icons.gps_fixed, 'Birth Accuracy', k['birthAccuracy'] ?? 'accurate'),
                  _buildDetailRow(Icons.translate, 'Script / Language', k['language'] ?? 'Hindi'),
                  _buildDetailRow(Icons.family_restroom, 'Gotra', k['gotra'] ?? 'Not specified'),
                  _buildDetailRow(Icons.home, 'Delivery Address', k['deliveryAddress'] ?? 'N/A'),
                  if (k['specialNotes'] != null && (k['specialNotes'] as String).isNotEmpty)
                    _buildDetailRow(Icons.notes, 'Special Questions', k['specialNotes']),
                  _buildDetailRow(Icons.payments_outlined, 'Payment Status', '${k['paymentStatus'] ?? 'PENDING'} (₹${k['amount'] ?? 1501})'),
                  _buildDetailRow(Icons.person_pin, 'Assigned Acharya', k['assignedPanditName'] ?? 'Unassigned'),
                  if (k['trackingNumber'] != null)
                    _buildDetailRow(Icons.local_shipping, 'Dispatch Tracking', '${k['courierPartner'] ?? 'Speed Post'}: ${k['trackingNumber']}'),
                  if (k['rejectionReason'] != null)
                    _buildDetailRow(Icons.warning, 'Rejection Reason', k['rejectionReason']),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPanditDetailSheet(Map<String, dynamic> pandit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final docs = (pandit['documents'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final name = pandit['userName'] ?? 'Pandit Application';
        final phone = pandit['userPhone'] ?? 'N/A';
        final spec = pandit['vedicSpecialization'] ?? 'Vedic Karmakand';
        final exp = pandit['experienceYears']?.toString() ?? '1';
        final city = pandit['userCity'] ?? 'N/A';
        final status = pandit['verificationStatus'] ?? 'PENDING';
        final bio = pandit['bio'] ?? 'No bio provided';
        final rejectionReason = pandit['rejectionReason'];

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primarySaffron,
                          ),
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  Text(
                    phone,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  _buildDetailRow(Icons.psychology, 'Specialization', spec),
                  _buildDetailRow(Icons.work_history, 'Experience', '$exp Years'),
                  _buildDetailRow(Icons.location_on, 'City / Region', city),
                  _buildDetailRow(Icons.description, 'Bio / Background', bio),
                  if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Rejection Reason: $rejectionReason',
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Verification Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No verification documents uploaded yet for this application.',
                        style: TextStyle(fontSize: 13, color: Colors.brown),
                      ),
                    )
                  else
                    ...docs.map((d) => _buildDocumentTile(d, pandit['id'])),
                  const SizedBox(height: 24),
                  if (status == 'PENDING') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleRejectPandit(pandit['id'], name);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleApprovePandit(pandit['id'], name);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentTile(Map<String, dynamic> doc, String panditId) {
    final docType = doc['docType'] ?? 'DOCUMENT';
    final docNumber = doc['docNumber'] ?? '•••• Hidden';
    final fileName = doc['fileName'] ?? 'Document.pdf';
    final status = doc['status'] ?? 'PENDING';
    final docId = doc['id'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  docType == 'AADHAAR'
                      ? Icons.badge
                      : docType == 'PAN'
                          ? Icons.credit_card
                          : Icons.school,
                  color: primarySaffron,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docType,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fileName,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID No: $docNumber',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (status == 'PENDING') ...[
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Verify Document',
                        onPressed: () async {
                          try {
                            await ApiService.adminVerifyDocument(docId, 'VERIFIED');
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Document verified.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadAllData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        tooltip: 'Reject Document',
                        onPressed: () async {
                          try {
                            await ApiService.adminVerifyDocument(
                              docId,
                              'REJECTED',
                              rejectionReason: 'Invalid or illegible document scan',
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Document rejected.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              _loadAllData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primarySaffron),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: darkBg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACTIVE':
      case 'VERIFIED':
      case 'DELIVERED':
      case 'COMPLETED':
      case 'PAID':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'REJECTED':
      case 'HALTED':
      case 'CANCELLED':
      case 'PAYMENT_FAILED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case 'SCHEDULED':
      case 'CONFIRMED':
      case 'IN_PROGRESS':
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'PREPARING':
      case 'READY':
      case 'DISPATCHED':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'REQUESTED':
      case 'UNDER_REVIEW':
      case 'PAYMENT_PENDING':
      case 'PENDING':
      case 'CREATED':
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: accentGold),
            SizedBox(width: 8),
            Text(
              'SARV MANGAL Admin Desk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: primarySaffron,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.verified_user_outlined), text: 'Pandit KYC'),
            Tab(icon: Icon(Icons.card_membership_outlined), text: 'Subscriptions'),
            Tab(icon: Icon(Icons.support_agent_outlined), text: 'Consultation Desk'),
            Tab(icon: Icon(Icons.auto_graph_outlined), text: 'Kundli Orders'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPanditKycTab(),
          _buildSubscriptionsTab(),
          _buildConsultationDeskTab(),
          _buildKundliOrdersTab(),
        ],
      ),
    );
  }

  // TAB 1: OVERVIEW METRICS
  Widget _buildOverviewTab() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _statsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final p = _stats?['pandits'] ?? {};
    final b = _stats?['bookings'] ?? {};
    final s = _stats?['subscriptions'] ?? {};
    final o = _stats?['productOrders'] ?? {};

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primarySaffron.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.security, size: 40, color: Colors.white),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SARV MANGAL Verification Desk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time operational metrics & verification pipeline',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pandit Onboarding Pipeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBg),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Pending KYC',
                  (p['pending'] ?? 0).toString(),
                  Icons.hourglass_empty,
                  Colors.amber.shade800,
                  onTap: () {
                    setState(() => _panditStatusFilter = 'PENDING');
                    _fetchPandits();
                    _tabController.animateTo(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Approved',
                  (p['approved'] ?? 0).toString(),
                  Icons.check_circle_outline,
                  Colors.green.shade700,
                  onTap: () {
                    setState(() => _panditStatusFilter = 'APPROVED');
                    _fetchPandits();
                    _tabController.animateTo(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Rejected',
                  (p['rejected'] ?? 0).toString(),
                  Icons.highlight_off,
                  Colors.red.shade700,
                  onTap: () {
                    setState(() => _panditStatusFilter = 'REJECTED');
                    _fetchPandits();
                    _tabController.animateTo(1);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Operational Volumes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBg),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Bookings',
                  (b['total'] ?? 0).toString(),
                  Icons.auto_stories,
                  primarySaffron,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Mala Subscriptions',
                  (s['total'] ?? 0).toString(),
                  Icons.local_florist,
                  Colors.purple.shade700,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Store Orders',
                  (o['total'] ?? 0).toString(),
                  Icons.shopping_bag_outlined,
                  Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: PANDIT KYC APPLICATIONS
  Widget _buildPanditKycTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Pending Review'),
                const SizedBox(width: 8),
                _buildFilterChip('APPROVED', 'Approved'),
                const SizedBox(width: 8),
                _buildFilterChip('REJECTED', 'Rejected'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loadingPandits
              ? const Center(child: CircularProgressIndicator())
              : _panditsError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_panditsError!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchPandits,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _pandits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No $_panditStatusFilter applications found.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchPandits,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pandits.length,
                            itemBuilder: (ctx, i) {
                              final p = _pandits[i];
                              final docs = (p['documents'] as List<dynamic>? ?? []);
                              final name = p['userName'] ?? 'Unnamed Applicant';
                              final phone = p['userPhone'] ?? 'N/A';
                              final spec = p['vedicSpecialization'] ?? 'Vedic Karmakand';
                              final exp = p['experienceYears']?.toString() ?? '1';
                              final status = p['verificationStatus'] ?? 'PENDING';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _showPanditDetailSheet(p),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            _buildStatusBadge(status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          phone,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.psychology, size: 16, color: primarySaffron),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '$spec • $exp yrs exp',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${docs.length} Document(s) submitted',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Row(
                                              children: [
                                                Text(
                                                  'Review Details',
                                                  style: TextStyle(
                                                    color: primarySaffron,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: primarySaffron,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _panditStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primarySaffron,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _panditStatusFilter = value);
          _fetchPandits();
        }
      },
    );
  }

  // TAB 3: SUBSCRIPTIONS OVERSIGHT
  Widget _buildSubscriptionsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildSubFilterChip('ACTIVE', 'Active'),
                const SizedBox(width: 8),
                _buildSubFilterChip('CREATED', 'Created'),
                const SizedBox(width: 8),
                _buildSubFilterChip('CANCELLED', 'Cancelled'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loadingSubscriptions
              ? const Center(child: CircularProgressIndicator())
              : _subscriptionsError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_subscriptionsError!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchSubscriptions,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _subscriptions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_florist_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No $_subStatusFilter subscriptions recorded.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchSubscriptions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _subscriptions.length,
                            itemBuilder: (ctx, i) {
                              final s = _subscriptions[i];
                              final plan = s['planId'] ?? 'Phool Mala Plan';
                              final name = s['userName'] ?? 'Devotee Customer';
                              final phone = s['userPhone'] ?? 'N/A';
                              final status = s['status'] ?? 'CREATED';
                              final end = s['currentPeriodEnd'] ?? 'Ongoing';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            plan,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Customer: $name ($phone)',
                                          style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('Period End: $end',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildSubFilterChip(String value, String label) {
    final selected = _subStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primarySaffron,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _subStatusFilter = value);
          _fetchSubscriptions();
        }
      },
    );
  }

  // TAB 4: CONSULTATION DESK (OPERATIONAL QUEUE)
  Widget _buildConsultationDeskTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.headset_mic, color: primarySaffron, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Live Vedic Consultation Desk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Devotees currently connect with certified Acharyas via direct administrative helpline dispatch.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Database Persistence Notice: Dedicated consultation table and scheduling schema are active for Phase P3. In accordance with zero-mock guidelines, no fabricated appointments or simulated records are shown here.',
                        style: TextStyle(fontSize: 13, height: 1.4, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Helpline Desk Dispatch Contacts:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: primarySaffron),
                title: const Text('+91 98765 43210 / +91 1800 123 7278'),
                subtitle: const Text('Primary Acharya Coordination Desk'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Consultation Status Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildConsultationFilterChip('ALL', 'All Requests'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('REQUESTED', 'Requested'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('UNDER_REVIEW', 'Under Review'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('SCHEDULED', 'Scheduled'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('CONFIRMED', 'Confirmed'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('IN_PROGRESS', 'In Progress'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('COMPLETED', 'Completed'),
              const SizedBox(width: 8),
              _buildConsultationFilterChip('CANCELLED', 'Cancelled'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_loadingConsultations)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_consultationsError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_consultationsError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchConsultations,
                    style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          )
        else if (_consultations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No consultation requests in ${_consultationStatusFilter.toLowerCase()} status.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ..._consultations.map((c) {
            final cNumber = c['consultationNumber'] ?? 'CNS-REQ';
            final status = c['status'] ?? 'REQUESTED';
            final type = c['type'] ?? 'ONLINE';
            final topic = c['topic'] ?? 'General Consultation';
            final duration = c['durationMinutes'] ?? 15;
            final devotee = c['devoteeName'] ?? 'Devotee';
            final phone = c['devoteePhone'] ?? 'N/A';
            final preferredTime = c['preferredDateTime'] ?? 'Flexible';
            final scheduledTime = c['scheduledDateTime'];
            final assignedPandit = c['assignedPanditName'];
            final paymentStatus = c['paymentStatus'] ?? 'PENDING';
            final amount = c['amount'] ?? 199;
            final meetingLink = c['meetingLink'];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: type == 'ONLINE' ? Colors.indigo.shade50 : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: type == 'ONLINE' ? Colors.indigo.shade200 : Colors.teal.shade200,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: type == 'ONLINE' ? Colors.indigo.shade800 : Colors.teal.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$topic • $duration mins',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: darkBg),
                    ),
                    const SizedBox(height: 6),
                    Text('Devotee: $devotee ($phone)', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                    Text('Preferred Time: $preferredTime', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    if (scheduledTime != null)
                      Text('Scheduled Time: $scheduledTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    if (meetingLink != null && meetingLink.isNotEmpty)
                      Text('Meeting: $meetingLink', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Assigned: ${assignedPandit ?? 'Unassigned'}', style: TextStyle(fontSize: 12, color: assignedPandit != null ? Colors.green.shade800 : Colors.orange.shade800)),
                        Text('₹$amount • $paymentStatus', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.schedule, size: 14),
                          label: const Text('Schedule', style: TextStyle(fontSize: 12)),
                          onPressed: () => _handleScheduleConsultation(c),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_add, size: 14),
                          label: const Text('Assign Pandit', style: TextStyle(fontSize: 12)),
                          onPressed: () => _handleAssignConsultation(c),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.update, size: 14, color: Colors.white),
                          label: const Text('Status', style: TextStyle(fontSize: 12, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
                          onPressed: () => _handleUpdateConsultationStatus(c),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildConsultationFilterChip(String value, String label) {
    final selected = _consultationStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primarySaffron,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _consultationStatusFilter = value);
          _fetchConsultations();
        }
      },
    );
  }

  // TAB 5: HANDMADE KUNDLI ORDERS QUEUE
  Widget _buildKundliOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_graph_outlined, color: primarySaffron, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Handmade Kundli Orders Desk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBg,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vedic handwritten Janam Patri manuscript preparation and fulfilment queue.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Kundli Status Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildKundliFilterChip('ALL', 'All Orders'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('REQUESTED', 'Requested'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('UNDER_REVIEW', 'Under Review'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('ACCEPTED', 'Accepted'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('PAID', 'Paid'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('ASSIGNED', 'Assigned'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('PREPARING', 'Preparing'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('READY', 'Ready'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('DISPATCHED', 'Dispatched'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('DELIVERED', 'Delivered'),
              const SizedBox(width: 8),
              _buildKundliFilterChip('CANCELLED', 'Cancelled'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_loadingKundliOrders)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_kundliOrdersError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_kundliOrdersError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchKundliOrders,
                    style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          )
        else if (_kundliOrders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No Kundli orders in ${_kundliStatusFilter.toLowerCase()} status.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ..._kundliOrders.map((k) {
            final orderNum = k['orderNumber'] ?? 'KND-ORD';
            final status = k['status'] ?? 'REQUESTED';
            final devotee = k['devoteeName'] ?? 'Devotee';
            final phone = k['devoteePhone'] ?? 'N/A';
            final dob = k['dob'] ?? '••••-••-••';
            final tob = k['tob'] ?? '••••';
            final pob = k['pob'] ?? 'N/A';
            final lang = k['language'] ?? 'Hindi';
            final accuracy = k['birthAccuracy'] ?? 'accurate';
            final assignedAcharya = k['assignedPanditName'];
            final paymentStatus = k['paymentStatus'] ?? 'PENDING';
            final amount = k['amount'] ?? 1501;
            final courier = k['courierPartner'];
            final tracking = k['trackingNumber'];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          orderNum,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primarySaffron),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Devotee: $devotee ($phone)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Birth Profile: DOB: $dob | TOB: $tob | POB: $pob',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Text(
                      'Manuscript: $lang Script • Accuracy: $accuracy',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Acharya: ${assignedAcharya ?? 'Unassigned'}', style: TextStyle(fontSize: 12, color: assignedAcharya != null ? Colors.green.shade800 : Colors.orange.shade800)),
                        Text('₹$amount • $paymentStatus', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (tracking != null) ...[
                      const SizedBox(height: 4),
                      Text('Dispatch: ${courier ?? 'Courier'} #$tracking', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility, size: 14),
                          label: const Text('Details', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showKundliDetailSheet(k),
                        ),
                        if (status == 'REQUESTED' || status == 'UNDER_REVIEW') ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 14, color: Colors.white),
                            label: const Text('Accept', style: TextStyle(fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _handleDecisionKundli(k, 'ACCEPT'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close, size: 14, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(fontSize: 12, color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            onPressed: () => _handleDecisionKundli(k, 'REJECT'),
                          ),
                        ],
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_pin, size: 14),
                          label: const Text('Assign Acharya', style: TextStyle(fontSize: 12)),
                          onPressed: () => _handleAssignKundli(k),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_note, size: 14, color: Colors.white),
                          label: const Text('Status', style: TextStyle(fontSize: 12, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: primarySaffron),
                          onPressed: () => _handleUpdateKundliStatus(k),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildKundliFilterChip(String value, String label) {
    final selected = _kundliStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primarySaffron,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _kundliStatusFilter = value);
          _fetchKundliOrders();
        }
      },
    );
  }
}
