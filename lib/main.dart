import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarthome/components/ThemeProvider.dart';
import 'package:smarthome/screens/StepCounter.dart';
import 'package:smarthome/screens/lightsensor.dart';
import 'package:smarthome/screens/maps.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
  await initNotifications();
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      // Handle notification tap
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeSphere',
      theme: themeNotifier.currentTheme,
      home: const MyHomePage(title: 'SafeSphere'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // To track the selected index
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20), // Dark green color
        centerTitle: true, // Center the title
        title: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 5 * _animation.value),
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_open, color: Colors.white), // Change the icon
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/image.PNG'),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 5 * _animation.value),
                        child: Text(
                          'SAFESPHERE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2.0,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.map,
              text: 'Maps',
              index: 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => MapPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.directions_walk,
              text: 'Step Counter',
              index: 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => StepCounterPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.lightbulb_rounded,
              text: 'Light Sensor',
              index: 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => LightSensorPage()));
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20), // Dark green
              Color(0xFF4CAF50), // Light green
              Color(0xFFC8E6C9), // Light gray
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAnimatedCard(),
                const SizedBox(height: 20),
                _buildImageCard(),
                const SizedBox(height: 20),
                _buildTextCard(),
                const SizedBox(height: 20),
                _buildIconCard(),
                const SizedBox(height: 20),
                _buildListTileCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      selected: _selectedIndex == index,
      selectedTileColor: Colors.green[100],
      title: Row(
        children: <Widget>[
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.green : Colors.grey,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              text,
              style: TextStyle(
                  color: _selectedIndex == index ? Colors.green : Colors.grey),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildAnimatedCard() {
    return ScaleTransition(
      scale: _animation,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: const [
              Icon(Icons.star, size: 50, color: Colors.amber),
              SizedBox(height: 10),
              Text(
                'Welcome to SAFESPHERE!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Image.asset(
              'assets/image.PNG',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'SafeSphere Technology',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Enjoy the seamless integration of your home devices with our cutting-edge SafeSphere system. Control everything from your lights to your security system with ease.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildIconCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.lightbulb_outline, size: 40, color: Colors.yellow),
            Icon(Icons.security, size: 40, color: Colors.blue),
            Icon(Icons.thermostat_outlined, size: 40, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildListTileCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Setting'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}
