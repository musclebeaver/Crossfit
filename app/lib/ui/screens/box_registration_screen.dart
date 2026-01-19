import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class BoxRegistrationScreen extends StatefulWidget {
  const BoxRegistrationScreen({super.key});

  @override
  State<BoxRegistrationScreen> createState() => _BoxRegistrationScreenState();
}

class _BoxRegistrationScreenState extends State<BoxRegistrationScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _businessNumberController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty || _businessNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.post('/boxes', data: {
        'name': _nameController.text,
        'location': _locationController.text,
        'businessNumber': _businessNumberController.text,
      });

      if (res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Box registration application submitted successfully.')));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Box Register Error: $e");
      if (mounted) {
        String message = 'Failed to register box: Connection error';
        if (e is DioException && e.response != null && e.response?.data != null) {
          message = 'Failed to register box: ${e.response?.data['message'] ?? 'Unknown error'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register Your Box', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.business, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Apply for Official Box Registration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once approved, you can manage members and WODs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            _buildTextField(_nameController, 'Box Name', Icons.drive_file_rename_outline),
            const SizedBox(height: 16),
            _buildTextField(_locationController, 'Location', Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(_businessNumberController, 'Business Registration Number', Icons.numbers),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Application', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }
}
