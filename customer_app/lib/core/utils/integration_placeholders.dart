import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider));

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final hiveInitializerProvider = FutureProvider<void>((ref) async {
  await Hive.initFlutter();
});

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final customerMapCameraProvider = Provider<CameraPosition>((ref) {
  return const CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 4.6);
});

final geolocatorPlatformProvider = Provider<GeolocatorPlatform>((ref) {
  return GeolocatorPlatform.instance;
});

final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>((
  ref,
) {
  return FlutterLocalNotificationsPlugin();
});

final pdfDocumentFactoryProvider = Provider<pw.Document Function()>((ref) {
  return () => pw.Document();
});
