import 'dart:async';
import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class RecordEntryScreen extends StatefulWidget {
  final dynamic wod;
  const RecordEntryScreen({super.key, required this.wod});

  @override
  State<RecordEntryScreen> createState() => _RecordEntryScreenState();
}

class _RecordEntryScreenState extends State<RecordEntryScreen> {
  // Timer/Stopwatch state
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "00:00.0";

  // Counter state
  int _counter = 0;

  // Weight state
  final _weightController = TextEditingController();

  bool _isRx = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _weightController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _formattedTime = _formatTime(_stopwatch.elapsedMilliseconds);
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _resetTimer() {
    _stopwatch.reset();
    setState(() {
      _formattedTime = "00:00.0";
    });
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 100).truncate();
    int seconds = (hundreds / 10).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 10).toString();

    return "$minutesStr:$secondsStr.$hundredsStr";
  }

  Future<void> _handleSave() async {
    double resultValue = 0;
    final type = widget.wod['type'];

    if (type == 'FOR_TIME') {
      resultValue = _stopwatch.elapsedMilliseconds / 1000.0;
    } else if (type == 'AMRAP') {
      resultValue = _counter.toDouble();
    } else if (type == 'MAX_WEIGHT') {
      resultValue = double.tryParse(_weightController.text) ?? 0;
    }

    if (resultValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid result')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await ApiClient().dio.post('/records', data: {
        'wodId': widget.wod['id'],
        'resultValue': resultValue,
        'isRx': _isRx,
      });

      if (res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record saved!'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Save Record Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.wod['type'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.wod['title'] ?? 'Record Result', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWodInfoCard(),
            const SizedBox(height: 32),
            if (type == 'FOR_TIME') _buildTimerUI(),
            if (type == 'AMRAP') _buildCounterUI(),
            if (type == 'MAX_WEIGHT') _buildWeightUI(),
            const SizedBox(height: 40),
            _buildRxToggle(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Record', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWodInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(widget.wod['type'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.wod['description'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTimerUI() {
    return Column(
      children: [
        Text(_formattedTime, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleButton(
              onPressed: _stopwatch.isRunning ? _stopTimer : _startTimer,
              icon: _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
              color: _stopwatch.isRunning ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 24),
            _buildCircleButton(
              onPressed: _resetTimer,
              icon: Icons.refresh,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterUI() {
    return Column(
      children: [
        const Text('REPS / ROUNDS', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$_counter', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleButton(
              onPressed: () => setState(() { if(_counter > 0) _counter--; }),
              icon: Icons.remove,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(width: 40),
            _buildCircleButton(
              onPressed: () => setState(() => _counter++),
              icon: Icons.add,
              color: AppColors.primary,
              size: 80,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightUI() {
    return TextField(
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: 'Result Weight (kg)',
        suffixText: 'kg',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildRxToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Rx\'d'),
          selected: _isRx,
          onSelected: (val) => setState(() => _isRx = true),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: _isRx ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Scaled'),
          selected: !_isRx,
          onSelected: (val) => setState(() => _isRx = false),
          selectedColor: Colors.orange,
          labelStyle: TextStyle(color: !_isRx ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCircleButton({required VoidCallback onPressed, required IconData icon, required Color color, double size = 64}) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: size * 0.5),
      ),
    );
  }
}
