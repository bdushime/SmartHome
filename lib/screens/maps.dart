import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:smarthome/components/consts.dart';
import 'package:smarthome/main.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
  Completer<GoogleMapController>();
  LatLng _kigaliCenter =
  LatLng(-1.9441, 30.0619); // Coordinates for Kigali center
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentP;
  Map<PolylineId, Polyline> polylines = {};
  Map<PolygonId, Polygon> _polygons = {};
  StreamSubscription<LocationData>? _locationSubscription;
  bool _notificationSentOutSide = false;
  bool _notificationSentInSide = false;

  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this, // Corrected parameter name
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    getLocationUpdates().then(
          (_) => {
        getPolylinePoints().then((coordinates) => {
          generatePolyLineFromPoints(coordinates),
        }),
      },
    );
    _createGeofence();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Your Location',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
      ),
      body: _currentP == null
          ? const Center(
        child: Text("Loading..."),
      )
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: ((GoogleMapController controller) =>
                _mapController.complete(controller)),
            initialCameraPosition: CameraPosition(
              target: _kigaliCenter,
              zoom: 13,
            ),
            polygons: Set<Polygon>.of(_polygons.values),
            markers: {
              Marker(
                markerId: MarkerId("_currentLocation"),
                icon: BitmapDescriptor.defaultMarker,
                position: _currentP!,
              ),
              Marker(
                  markerId: MarkerId("_sourceLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pGooglePlex),
              Marker(
                  markerId: MarkerId("_destionationLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pApplePark)
            },
            polylines: Set<Polyline>.of(polylines.values),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FadeTransition(
              opacity: _animation!,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Your Location: ${_currentP?.latitude}, ${_currentP?.longitude}',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerInSideNotification() async {
    if (!_notificationSentInSide) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'Map_channel', // Change this to match your channel ID
        'Map Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Hello!',
        'Inside Geographical Boundaries of Gishushu',
        platformChannelSpecifics,
      );
      print('Inside geofence notification sent');
      _notificationSentInSide = true;
      _notificationSentOutSide = false;
    }
  }

  void _triggerOutSideNotification() async {
    if (!_notificationSentOutSide) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'Map_channel', // Change this to match your channel ID
        'Map Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Hello!',
        'Outside Geographical Boundaries of Gishushu',
        platformChannelSpecifics,
      );
      print('Outside geofence notification sent');
      _notificationSentOutSide = true;
      _notificationSentInSide = false;
    }
  }

  void _createGeofence() {
    // Define the boundaries for the geofence around Gishushu
    List<LatLng> gishushuBoundaries = [
      LatLng(-1.9500, 30.0911), // Northwest corner
      LatLng(-1.9500, 30.1020), // Northeast corner
      LatLng(-1.9570, 30.1020), // Southeast corner
      LatLng(-1.9570, 30.0911), // Southwest corner
    ];

    // Create a polygon to represent the geofence boundaries
    PolygonId polygonId = PolygonId('gishushu');
    Polygon polygon = Polygon(
      polygonId: polygonId,
      points: gishushuBoundaries,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
    );

    // Add the polygon to the map
    setState(() {
      _polygons[polygonId] = polygon;
    });

    // Start location updates subscription to monitor device's location
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    _locationSubscription =
        _locationController.onLocationChanged.listen((LocationData currentLocation) {
          // Check if the device's location is inside or outside the geofence
          bool insideGeofence = _isLocationInsideGeofence(
              currentLocation.latitude!, currentLocation.longitude!);

          if (insideGeofence && !_notificationSentInSide) {
            _triggerInSideNotification();
            _notificationSentInSide = true;
            _notificationSentOutSide = false;
          } else if (!insideGeofence && !_notificationSentOutSide) {
            _triggerOutSideNotification();
            _notificationSentOutSide = true;
            _notificationSentInSide = false;
          }
        });
  }

  bool _isLocationInsideGeofence(double latitude, double longitude) {
    // Check if the provided location is inside the geofence boundaries
    bool isInside = false;
    List<LatLng> gishushuBoundaries = [
      LatLng(-1.9500, 30.0911),
      LatLng(-1.9500, 30.1020),
      LatLng(-1.9570, 30.1020),
      LatLng(-1.9570, 30.0911),
    ];

    // Algorithm to determine if a point is inside a polygon
    int i, j = gishushuBoundaries.length - 1;
    for (i = 0; i < gishushuBoundaries.length; i++) {
      if ((gishushuBoundaries[i].latitude < latitude &&
          gishushuBoundaries[j].latitude >= latitude ||
          gishushuBoundaries[j].latitude < latitude &&
              gishushuBoundaries[i].latitude >= latitude) &&
          (gishushuBoundaries[i].longitude <= longitude ||
              gishushuBoundaries[j].longitude <= longitude)) {
        if (gishushuBoundaries[i].longitude +
            (latitude - gishushuBoundaries[i].latitude) /
                (gishushuBoundaries[j].latitude -
                    gishushuBoundaries[i].latitude) *
                (gishushuBoundaries[j].longitude -
                    gishushuBoundaries[i].longitude) <
            longitude) {
          isInside = !isInside;
        }
      }
      j = i;
    }
    return isInside;
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition cameraPosition = CameraPosition(
      target: pos,
      zoom: 16,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<void> getLocationUpdates() async {
    LocationData locationData = await _locationController.getLocation();
    setState(() {
      _currentP = LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    // Replace with your logic to fetch polyline coordinates
    return [
      LatLng(-1.9441, 30.0619),
      LatLng(-1.9351, 30.0659),
      LatLng(-1.9261, 30.0709),
    ];
  }

  void generatePolyLineFromPoints(List<LatLng> coordinates) {
    PolylineId polylineId = PolylineId('polyline_id');
    Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.blue,
      points: coordinates,
      width: 4,
    );

    setState(() {
      polylines[polylineId] = polyline;
    });
  }
}
