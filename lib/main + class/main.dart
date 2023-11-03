import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_handler.dart'; // Import the NotificationHandler class

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

var logger = Logger(
  printer: PrettyPrinter(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  logger.i("trying to configure LocalTimeZone");
  await _configureLocalTimeZone();
  logger.i("configured LocalTimeZone");

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('hakedj');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {},
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      logger.i("onDidReceiveNotificationResponse");
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  _isAndroidPermissionGranted();

  final notificationHandler = NotificationHandler(
      flutterLocalNotificationsPlugin); // Create a NotificationHandler instance

  runApp(MyApp(notificationHandler: notificationHandler));
}

class MyApp extends StatelessWidget {
  final NotificationHandler
      notificationHandler; // Define the NotificationHandler instance

  const MyApp({Key? key, required this.notificationHandler})
      : super(
            key:
                key); // Modify the constructor to accept the NotificationHandler instance

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
          title: 'Flutter Demo Home Page',
          notificationHandler:
              notificationHandler), // Pass the NotificationHandler instance to MyHomePage
    );
  }
}

class MyHomePage extends StatefulWidget {
  final NotificationHandler
      notificationHandler; // Define the NotificationHandler instance
  final String title;

  const MyHomePage(
      {Key? key, required this.title, required this.notificationHandler})
      : super(
            key:
                key); // Modify the constructor to accept the NotificationHandler instance

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _sendInstantNotif() {
    widget.notificationHandler
        .sendInstantNotif(); // Update the method call to use the NotificationHandler instance
  }

  void _sendScheduledNotif(int delayInSeconds) {
    widget.notificationHandler.sendScheduledNotif(
        delayInSeconds); // Update the method call to use the NotificationHandler instance
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: _sendInstantNotif,
                child: const Text(
                  'Envoyer une notif maintenant',
                )),
            const SizedBox(height: 30),
            ElevatedButton(
                onPressed: () => _sendScheduledNotif(5),
                child: const Text(
                  'Envoyer une notif dans 5 secondes',
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendInstantNotif,
        tooltip: 'send',
        child: const Icon(Icons.send),
      ),
    );
  }
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  logger.i("timeZoneName: $timeZoneName");
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

void notificationTapBackground(NotificationResponse notificationResponse) {
  logger.i('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    logger.i(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

Future<void> _isAndroidPermissionGranted() async {
  final bool granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ??
      false;

  logger.i("is android permission granted: $granted");

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (!granted) {
    await androidImplementation?.requestNotificationsPermission();
  }
}
