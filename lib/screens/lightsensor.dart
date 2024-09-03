import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light_sensor/light_sensor.dart';

class LightSensorPage extends StatefulWidget {
  @override
  _LightSensorPageState createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> with SingleTickerProviderStateMixin {
  double _lightIntensity = 0.0;
  bool _showHighIntensityPopup = true;
  bool _showLowIntensityPopup = true;
  late StreamSubscription<int> _lightSubscription;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.8).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _startListeningToLightSensor();
  }

  @override
  void dispose() {
    _lightSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startListeningToLightSensor() {
    LightSensor.hasSensor().then((hasSensor) {
      if (hasSensor) {
        _lightSubscription = LightSensor.luxStream().listen((int luxValue) {
          setState(() {
            _lightIntensity = luxValue.toDouble();
            checkAndTriggerPopups();
          });
        });
      } else {
        print("Device does not have a light sensor");
      }
    });
  }

  void checkAndTriggerPopups() {
    if (_lightIntensity >= 30000.0 && _showHighIntensityPopup) {
      _showPopup(
          'High Light Intensity', 'Too much light');
      _showHighIntensityPopup = false;
    } else if (_lightIntensity != 30000.0) {
      _showHighIntensityPopup = true;
    }

    if (_lightIntensity == 0 && _showLowIntensityPopup) {
      _showPopup(
          'Low Light Intensity', 'Very Low light');
      _showLowIntensityPopup = false;
    } else if (_lightIntensity != 0) {
      _showLowIntensityPopup = true;
    }
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Color _getBackgroundColor() {
    double normalizedIntensity = (_lightIntensity / 40000).clamp(0, 1);
    return Color.lerp(Colors.black, Colors.yellow, normalizedIntensity)!;
  }

  Color _getIconColor() {
    if (_lightIntensity >= 30000.0) {
      return Colors.yellow;
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Light Sensor',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      backgroundColor: _getBackgroundColor(),
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wb_sunny,
                size: 100,
                color: _getIconColor(),
              ),
              SizedBox(height: 20),
              Text(
                'Light Intensity: $_lightIntensity lx',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}