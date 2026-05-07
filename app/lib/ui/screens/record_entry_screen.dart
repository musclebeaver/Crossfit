import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/services/local_record_service.dart';
import '../../core/services/sync_manager.dart';

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
  final _repsController = TextEditingController();

  // Manual Time state
  final _minController = TextEditingController();
  final _secController = TextEditingController();

  // Weight state
  final _weightController = TextEditingController();

  bool _isRx = true;
  bool _isCapped = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _repsController.dispose();
    _minController.dispose();
    _secController.dispose();
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
      // Prioritize manual input if provided
      if (_minController.text.isNotEmpty || _secController.text.isNotEmpty) {
        int mins = int.tryParse(_minController.text) ?? 0;
        int secs = int.tryParse(_secController.text) ?? 0;
        resultValue = (mins * 60 + secs).toDouble();
      } else {
        resultValue = _stopwatch.elapsedMilliseconds / 1000.0;
      }
    } else if (type == 'AMRAP') {
      if (_repsController.text.isNotEmpty) {
        resultValue = double.tryParse(_repsController.text) ?? 0;
      } else {
        resultValue = _counter.toDouble();
      }
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
        'isCapped': _isCapped,
      });

      if (res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record saved!'), backgroundColor: Colors.green)
          );
          // Go back to the main screen (WodTab)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      debugPrint("Save Record Error: $e");
      if (mounted) {
        if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionError)) {
          // 네트워크 오류 시 로컬 저장
          final recordData = {
            'wodId': widget.wod['id'],
            'resultValue': resultValue,
            'isRx': _isRx,
            'isCapped': _isCapped,
          };
          await LocalRecordService.saveRecord(recordData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Network error. Record saved locally and will sync when online.'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          String message = 'Failed to save record: Connection error';
          if (e is DioException && e.response != null && e.response?.data != null) {
            message = 'Failed to save record: ${e.response?.data['message'] ?? 'Unknown error'}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.wod['type'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.wod['title'] ?? 'Record Result', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF115D33))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF115D33)),
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
                backgroundColor: const Color(0xFF115D33),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Record Result', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFF115D33), size: 20),
              const SizedBox(width: 8),
              Text(widget.wod['type'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF115D33))),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.wod['description'] ?? '', style: const TextStyle(color: Color(0xFF757575))),
        ],
      ),
    );
  }

  Widget _buildTimerUI() {
    return Column(
      children: [
        Text(_formattedTime, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.black87, fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleButton(
              onPressed: _stopwatch.isRunning ? _stopTimer : _startTimer,
              icon: _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
              color: _stopwatch.isRunning ? Colors.orange : const Color(0xFF115D33),
            ),
            const SizedBox(width: 24),
            _buildCircleButton(
              onPressed: _resetTimer,
              icon: Icons.refresh,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('OR Manual Entry (Min : Sec)', style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: _minController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Min', 
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _secController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Sec', 
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: _isCapped,
              onChanged: (val) {
                setState(() => _isCapped = val ?? false);
              },
              activeColor: const Color(0xFF115D33),
            ),
            const Text('Time Capped (Did not finish)', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterUI() {
    return Column(
      children: [
        const Text('REPS / ROUNDS', style: TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$_counter', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleButton(
              onPressed: () => setState(() { 
                if(_counter > 0) {
                  _counter--;
                  _repsController.text = _counter.toString();
                }
              }),
              icon: Icons.remove,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(width: 40),
            _buildCircleButton(
              onPressed: () => setState(() {
                _counter++;
                _repsController.text = _counter.toString();
              }),
              icon: Icons.add,
              color: const Color(0xFF115D33),
              size: 80,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text('OR Manual Entry', style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
        const SizedBox(height: 12),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (val) {
              setState(() {
                _counter = int.tryParse(val) ?? 0;
              });
            },
            decoration: InputDecoration(
              hintText: 'Reps', 
              hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33))),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightUI() {
    return TextField(
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Result Weight (kg)',
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        suffixText: 'kg',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33))),
        filled: false,
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
          selectedColor: const Color(0xFF115D33),
          labelStyle: TextStyle(color: _isRx ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Scaled'),
          selected: !_isRx,
          onSelected: (val) => setState(() => _isRx = false),
          selectedColor: Colors.orange,
          labelStyle: TextStyle(color: !_isRx ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
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
