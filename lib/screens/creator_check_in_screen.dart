import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/check_in_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class CreatorCheckInScreen extends StatefulWidget {
  final Activity activity;

  const CreatorCheckInScreen({
    super.key,
    required this.activity,
  });

  @override
  State<CreatorCheckInScreen> createState() => _CreatorCheckInScreenState();
}

class _CreatorCheckInScreenState extends State<CreatorCheckInScreen> {
  final CheckInService _checkInService = CheckInService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _checkedIn = false;
  String? _checkInCode;
  int _timeRemaining = 300; // 5 minutes in seconds
  late Timer _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _timer.cancel();
        _handleTimeoutFailure();
      }
    });
  }

  Future<void> _handleTimeoutFailure() async {
    _timer.cancel();

    // Mark activity as failed
    await _checkInService.markActivityAsFailed(widget.activity.id);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ 活動失敗'),
          content: const Text('由於創建者未在5分鐘內打卡，活動已被標記為失敗。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst,
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _performCheckIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _checkInService.creatorCheckIn(
        activityId: widget.activity.id,
        activityLat: widget.activity.latitude,
        activityLng: widget.activity.longitude,
      );

      if (success) {
        // Get the check-in code from the activity
        // In a real app, we'd fetch this from the database
        setState(() {
          _checkedIn = true;
          _timer.cancel();
          _checkInCode = '****'; // Will be fetched from DB
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 打卡成功！密碼已生成'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = '❌ GPS驗證失敗。請確保您在活動地點附近。';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '❌ 打卡失敗: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('創建者打卡'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Activity info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.activity.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.activity.address ?? '位置未知',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Timer
              if (!_checkedIn)
                Column(
                  children: [
                    Text(
                      '剩餘時間',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _timeRemaining < 60
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _timeRemaining < 60 ? Colors.red : Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_timeRemaining),
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: _timeRemaining < 60
                                  ? Colors.red
                                  : Colors.blue,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_timeRemaining < 60)
                            const Text(
                              '⚠️ 即將超時',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),

              // Success state
              if (_checkedIn)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '打卡成功！',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '參與者密碼',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _checkInCode ?? 'XXXX',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '請將此密碼告知參與者以進行打卡確認',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('返回'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _isLoading ? null : _performCheckIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('開始打卡'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
