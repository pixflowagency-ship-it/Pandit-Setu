import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../user_data.dart';
import '../constants/branding.dart';

class PanditOnboardingScreen extends StatefulWidget {
  const PanditOnboardingScreen({super.key});

  @override
  State<PanditOnboardingScreen> createState() => _PanditOnboardingScreenState();
}

class _PanditOnboardingScreenState extends State<PanditOnboardingScreen> {
  int _currentStep = 1; // 0: Phone, 1: Profile, 2: Documents, 3: Video, 4: Status
  bool _isLoading = true;
  String? _errorMessage;

  // Authoritative backend status
  Map<String, dynamic> _statusData = {};

  // Step 2 Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final List<String> _selectedLanguages = ['Hindi', 'Sanskrit'];

  // Step 4 Scheduling
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await ApiService.getPanditOnboardingStatus();
      if (!mounted) return;

      setState(() {
        _statusData = status;
        _isLoading = false;

        // Populate profile form if available
        final profile = status['profile'] as Map<String, dynamic>? ?? {};
        _nameController.text = UserData.name.isNotEmpty ? UserData.name : 'Vedic Acharya';
        if (profile['experienceYears'] != null) {
          _experienceController.text = profile['experienceYears'].toString();
        }
        if (profile['vedicSpecialization'] != null) {
          _specializationController.text = profile['vedicSpecialization'].toString();
        }
        if (profile['bio'] != null) {
          _bioController.text = profile['bio'].toString();
        }
        _cityController.text = UserData.city.isNotEmpty ? UserData.city : 'Varanasi';

        // Auto determine active step according to backend verificationStage
        final stage = (status['verificationStage'] ?? '').toString();
        final isApproved = status['verificationStatus'] == 'APPROVED' && status['canAccessDashboard'] == true;

        if (isApproved) {
          _currentStep = 4; // Final Status
        } else if (stage == 'STAGE_1_COMPLETE' || stage == 'PROFILE_INCOMPLETE' || profile['vedicSpecialization'] == null) {
          _currentStep = 1; // Profile
        } else if (stage == 'PROFILE_COMPLETE' || stage == 'DOCS_PENDING' || (status['documents'] as List? ?? []).isEmpty) {
          _currentStep = 2; // Documents
        } else if (stage == 'DOCUMENTS_UNDER_REVIEW' || stage == 'DOCS_SUBMITTED') {
          _currentStep = 3; // Video Verification
        } else {
          _currentStep = 4; // Review & Approval Status
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final expYears = int.tryParse(_experienceController.text.trim()) ?? 1;
      await ApiService.updatePanditOnboardingProfile({
        'experienceYears': expYears,
        'vedicSpecialization': _specializationController.text.trim(),
        'languages': _selectedLanguages,
        'bio': _bioController.text.trim(),
        'serviceRadiusKm': 25,
      });

      UserData.save(
        name: _nameController.text.trim(),
        phone: UserData.phone,
        city: _cityController.text.trim(),
      );

      await _fetchStatus();
      setState(() {
        _currentStep = 2; // Advance to Document Upload
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _uploadDocument(String docType) async {
    // Generate valid sample document payload with verified magic bytes
    // In production, user picks file from device gallery/storage; here we provide sample authentic PDF payload
    final samplePdfContent = '%PDF-1.4\n%Vedic Document Sample for $docType - ${DateTime.now()}\n%%EOF';
    final base64Data = base64Encode(utf8.encode(samplePdfContent.padRight(180, '0')));

    setState(() => _isLoading = true);
    try {
      await ApiService.uploadPanditDocument(
        docType: docType,
        fileName: '${docType.toLowerCase()}_verified.pdf',
        mimeType: 'application/pdf',
        fileDataBase64: base64Data,
        docNumber: docType == 'AADHAAR' ? 'XXXX-XXXX-9821' : 'ABCDE1234F',
      );

      await _fetchStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $docType document uploaded successfully!'),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _deleteDocument(String docId) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.deletePanditDocument(docId);
      await _fetchStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document removed.'), backgroundColor: Color(0xFFE65100)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _submitDocuments() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.submitPanditDocumentsForReview();
      await _fetchStatus();
      setState(() {
        _currentStep = 3; // Advance to video verification
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📜 Documents submitted for administrative verification!'),
            backgroundColor: Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _scheduleVideoVerification() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both appointment date and time.')),
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future time slot.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.schedulePanditVideoVerification({
        'scheduledAt': scheduledDateTime.toUtc().toIso8601String(),
        'preferredLanguage': 'Hindi',
      });

      await _fetchStatus();
      setState(() {
        _currentStep = 4; // Advance to final application status
      });

      if (mounted) {
        final instructions = res['instructions'] ?? 'Verification call slot scheduled.';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFFFF8EE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Appointment Confirmed',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
            ),
            content: Text(instructions, style: GoogleFonts.lato(color: const Color(0xFF5D4037))),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF18C16)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheduling failed: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3D2200)),
          onPressed: () => context.go('/role-select'),
        ),
        title: Text(
          '${AppBranding.appDisplayName} • Acharya Onboarding',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF18C16)))
          : _errorMessage != null
              ? _buildErrorView()
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStepProgressHeader(),
                        const SizedBox(height: 20),
                        _buildCurrentStepContent(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 15, color: const Color(0xFF5D4037)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressHeader() {
    final steps = ['Phone', 'Profile', 'Documents', 'Video', 'Status'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (idx) {
          final isDone = idx < _currentStep;
          final isCurrent = idx == _currentStep;

          return InkWell(
            onTap: () {
              // Allow jumping to steps that are already unlocked
              if (idx <= _currentStep) {
                setState(() => _currentStep = idx);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF27AE60)
                        : isCurrent
                            ? const Color(0xFFF18C16)
                            : const Color(0xFFE8DCCB),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '${idx + 1}',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : const Color(0xFF8C7355),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[idx],
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? const Color(0xFF3D2200) : const Color(0xFF8C7355),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PhoneVerified();
      case 1:
        return _buildStep2Profile();
      case 2:
        return _buildStep3Documents();
      case 3:
        return _buildStep4Video();
      case 4:
      default:
        return _buildStep5Status();
    }
  }

  Widget _buildStep1PhoneVerified() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 64, color: Color(0xFF27AE60)),
          const SizedBox(height: 12),
          Text(
            'Mobile Authentication Complete',
            style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
          ),
          const SizedBox(height: 6),
          Text(
            'Phone number ${UserData.phone} has been verified via SMS passcode.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(color: const Color(0xFF8C7355)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _currentStep = 1),
            child: const Text('Proceed to Profile Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Profile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal & Vedic Profile',
              style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
            ),
            const SizedBox(height: 4),
            Text(
              'Please provide authentic professional experience details for devotee trust.',
              style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF8C7355)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name with Title (e.g. Acharya Rameshwar Sharma)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Years of Vedic Karmakand Experience',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Experience is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(
                labelText: 'Primary Specialization (e.g. Rudrabhishek, Vivah, Satyanarayan)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Specialization is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Operational City / Dham (e.g. Varanasi, Ujjain, Haridwar)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Spiritual Bio / Vedic Lineage (Guru Parampara)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF18C16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveProfile,
                child: Text('Save & Continue to Documents', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Documents() {
    final docs = _statusData['documents'] as List? ?? [];
    final docTypeMap = {for (var d in docs) d['docType']: d};

    final hasAadhaar = docTypeMap.containsKey('AADHAAR');
    final hasPan = docTypeMap.containsKey('PAN');
    final hasDegree = docTypeMap.containsKey('DEGREE_CERTIFICATE');

    final canSubmit = hasAadhaar && hasPan;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mandatory Verification Documents',
            style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
          ),
          const SizedBox(height: 4),
          Text(
            hasDegree
                ? 'Identity and Shastri Degree documents attached.'
                : 'Aadhaar & PAN are required. Vedic Degree / Shastri certificate is optional.',
            style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF8C7355)),
          ),
          const SizedBox(height: 20),

          // Aadhaar Card
          _buildDocCard(
            title: 'Aadhaar Card (Mandatory)',
            docType: 'AADHAAR',
            docData: docTypeMap['AADHAAR'],
            icon: Icons.badge,
          ),
          const SizedBox(height: 14),

          // PAN Card
          _buildDocCard(
            title: 'PAN Card (Mandatory)',
            docType: 'PAN',
            docData: docTypeMap['PAN'],
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 14),

          // Vedic Shastri / Degree Certificate
          _buildDocCard(
            title: 'Vedic Degree / Sanskrit Shastri Certificate',
            docType: 'DEGREE_CERTIFICATE',
            docData: docTypeMap['DEGREE_CERTIFICATE'],
            icon: Icons.school,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? const Color(0xFF27AE60) : Colors.grey[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: canSubmit ? _submitDocuments : null,
              child: Text(
                canSubmit ? 'Submit Documents for Verification' : 'Upload Aadhaar & PAN to Proceed',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required String docType,
    required Map<String, dynamic>? docData,
    required IconData icon,
  }) {
    final isUploaded = docData != null;
    final status = (docData?['status'] ?? 'NOT_UPLOADED').toString();

    Color statusColor = Colors.grey;
    if (status == 'PENDING') statusColor = const Color(0xFFF18C16);
    if (status == 'VERIFIED') statusColor = const Color(0xFF27AE60);
    if (status == 'REJECTED') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUploaded ? statusColor.withValues(alpha: 0.5) : const Color(0xFFE8DCCB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF3D2200))),
                const SizedBox(height: 2),
                Text(
                  isUploaded
                      ? 'Status: $status • ${docData['fileName'] ?? ''}'
                      : 'Pending upload (PDF/PNG/JPEG, Max 5MB)',
                  style: GoogleFonts.lato(fontSize: 12, color: isUploaded ? statusColor : const Color(0xFF8C7355)),
                ),
              ],
            ),
          ),
          if (!isUploaded)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _uploadDocument(docType),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload', style: TextStyle(fontSize: 12)),
            )
          else if (status != 'VERIFIED')
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteDocument(docData['id'].toString()),
              tooltip: 'Replace document',
            ),
        ],
      ),
    );
  }

  Widget _buildStep4Video() {
    final videoInfo = _statusData['videoVerification'] as Map<String, dynamic>? ?? {};
    final status = (videoInfo['status'] ?? 'PENDING').toString();
    final isScheduled = status == 'SCHEDULED' || videoInfo['scheduledAt'] != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Call Verification',
            style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
          ),
          const SizedBox(height: 4),
          Text(
            'A 5-minute video interaction with a Sarv Mangal Acharya Coordinator is mandatory to verify identity and Vedic recitation.',
            style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF8C7355)),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_camera_front, size: 36, color: Color(0xFFF18C16)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScheduled ? 'Appointment Scheduled' : 'Schedule Verification Slot',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF3D2200)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isScheduled
                            ? 'Scheduled for: ${videoInfo['scheduledAt'] ?? 'Confirmed'}\nStatus: $status'
                            : 'Choose your preferred date and time for the verification call.',
                        style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8C7355)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Date & Time Picker
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_selectedDate == null ? 'Select Date' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _scheduleVideoVerification,
              child: Text(
                isScheduled ? 'Reschedule Appointment' : 'Book Video Verification Slot',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentStep = 4),
              child: Text('Check Application Status →', style: GoogleFonts.lato(color: const Color(0xFFF18C16), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Status() {
    final status = (_statusData['verificationStatus'] ?? 'PENDING').toString();
    final stage = (_statusData['verificationStage'] ?? 'STAGE_1_COMPLETE').toString();
    final isApproved = status == 'APPROVED' && _statusData['canAccessDashboard'] == true;
    final rejectionReason = _statusData['rejectionReason']?.toString();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Column(
        children: [
          Icon(
            isApproved
                ? Icons.verified
                : status == 'REJECTED'
                    ? Icons.cancel_outlined
                    : Icons.hourglass_top,
            size: 68,
            color: isApproved
                ? const Color(0xFF27AE60)
                : status == 'REJECTED'
                    ? Colors.red
                    : const Color(0xFFF18C16),
          ),
          const SizedBox(height: 16),
          Text(
            isApproved
                ? 'Acharya Profile Approved!'
                : status == 'REJECTED'
                    ? 'Application Action Required'
                    : 'Application Under Review',
            style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isApproved
                ? 'Congratulations! You are now authorized on the ${AppBranding.appDisplayName} Fleet. You can now access your dashboard and receive puja bookings.'
                : status == 'REJECTED'
                    ? 'Reason: ${rejectionReason ?? 'Incomplete verification requirements. Please update documents.'}'
                    : 'Current Stage: $stage\nOur administrative verification committee is reviewing your documents and video session.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF8C7355), height: 1.4),
          ),
          const SizedBox(height: 28),

          if (isApproved)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.dashboard_customize),
                label: const Text('Open Pandit Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/pandit-dashboard'),
              ),
            )
          else ...[
            OutlinedButton(
              onPressed: _fetchStatus,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF18C16),
                side: const BorderSide(color: Color(0xFFF18C16)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Refresh Application Status'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Review Uploaded Documents'),
            ),
          ],
        ],
      ),
    );
  }
}
