import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smarthome/main.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> with SingleTickerProviderStateMixin {
  int _stepCount = 0;
  bool _motionDetected = false;
  bool _notificationShown = false;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late double _previousMagnitude;
  late DateTime _lastStepTime;
  late AnimationController _controller;
  late Animation<double> _animation;

  List<double> _accelerometerValues = [0, 0, 0];
  List<FlSpot> _accelerometerData = [];
  Timer? _timer;
  bool _initialCalibrated = false;
  int _timestamp = 0;

  @override
  void initState() {
    super.initState();
    _previousMagnitude = 0.0;
    _lastStepTime = DateTime.now();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _startListeningToAccelerometer();
    _calibrateInitialState();
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startListeningToAccelerometer() {
    Timer? motionTimer;

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (_isStepDetected(magnitude)) {
        setState(() {
          _stepCount++;
          _motionDetected = true;
          _triggerNotification();
          _notificationShown = true;
          motionTimer?.cancel();
          motionTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _motionDetected = false;
                _notificationShown = false;
              });
            }
          });
        });
      }

      _previousMagnitude = magnitude;

      if (_initialCalibrated) {
        setState(() {
          _accelerometerValues = [event.x, event.y, event.z];
          _updateAccelerometerData();
        });
      }
    });

    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {});
    });
  }

  void _calibrateInitialState() {
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _initialCalibrated = true;
      });
    });
  }

  void _updateAccelerometerData() {
    _timestamp++;
    if (_accelerometerData.length >= 50) {
      _accelerometerData.removeAt(0);
    }
    _accelerometerData.add(FlSpot(_timestamp.toDouble(), _accelerometerValues[1]));
  }

  bool _isStepDetected(double magnitude) {
    final currentTime = DateTime.now();
    final timeDifference = currentTime.difference(_lastStepTime).inMilliseconds;

    if (magnitude > 12 && timeDifference > 300) {
      _lastStepTime = currentTime;
      return true;
    }
    return false;
  }

  void _triggerNotification() async {
    if (!_notificationShown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'StepCounter_channel',
        'StepCounter Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Step Alert!',
        'Motion detected!',
        platformChannelSpecifics,
      );
      _notificationShown = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Motion Detector (Steps)',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundImage(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    Icons.speed, // Use a different icon, such as speed
                    size: 100,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildStepCounterWidget(theme),
                SizedBox(height: 20),
                _motionDetected
                    ? Text(
                  'Motion Detected!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                )
                    : Text(
                  'No motion',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 20),
                _buildGraph(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.jpg'), // Add your background image asset
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStepCounterWidget(ThemeData theme) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: Text(
            '$_stepCount',
            key: ValueKey<int>(_stepCount),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        Text(
          'Steps',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGraph() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(20),
      child: LineChart(
        LineChartData(
          minY: -10,
          maxY: 10,
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _accelerometerData.isNotEmpty
                  ? _accelerometerData
                  : [FlSpot(0, 0)],
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}