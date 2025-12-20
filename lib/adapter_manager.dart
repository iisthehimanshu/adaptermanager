library adapter_manager;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:app_settings/app_settings.dart';

export 'package:geolocator/geolocator.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart';
export 'AdapterException.dart';

class AdapterManager {
  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if precise location permission is granted (iOS 14+)
  static Future<bool> isLocationAlwaysGranted() async {
    try {
      final status = await Permission.locationAlways.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking location always permission: $e');
      return false;
    }
  }

  /// Request always location permission
  static Future<bool> requestLocationAlwaysPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting location always permission: $e');
      return false;
    }
  }

  /// Check if Bluetooth permission is granted
  static Future<bool> isBluetoothPermissionGranted() async {
    try {
      if (Platform.isAndroid) {
        // Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;
        return scanStatus.isGranted && connectStatus.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        return status.isGranted;
      }
      return false;
    } catch (e) {
      print('Error checking Bluetooth permission: $e');
      return false;
    }
  }

  /// Request Bluetooth permission
  static Future<bool> requestBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        return statuses[Permission.bluetoothScan]?.isGranted == true &&
            statuses[Permission.bluetoothConnect]?.isGranted == true;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      print('Error requesting Bluetooth permission: $e');
      return false;
    }
  }

  /// Check if Bluetooth Advertise permission is granted (Android 12+)
  static Future<bool> isBluetoothAdvertiseGranted() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.bluetoothAdvertise.status;
        return status.isGranted;
      }
      return true; // Not needed on iOS
    } catch (e) {
      print('Error checking Bluetooth advertise permission: $e');
      return false;
    }
  }

  /// Request Bluetooth Advertise permission (Android 12+)
  static Future<bool> requestBluetoothAdvertisePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.bluetoothAdvertise.request();
        return status.isGranted;
      }
      return true; // Not needed on iOS
    } catch (e) {
      print('Error requesting Bluetooth advertise permission: $e');
      return false;
    }
  }

  /// Check if GPS/Location services are enabled
  static Future<bool> isGpsEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Error checking GPS status: $e');
      return false;
    }
  }

  /// Prompt user to enable GPS/Location services
  static Future<bool> promptEnableGps() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        // Try to trigger the system GPS prompt by requesting location
        try {
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 120),
          );
          for(int i = 0; i < 240; i++){
            final gpsEnabled = await isGpsEnabled();
            if(gpsEnabled){
              return true;
            }
            await Future.delayed(Duration(milliseconds: 500));
          }
          // If we reach here, GPS was enabled
          return true;
        } on LocationServiceDisabledException {
          // User dismissed the prompt without enabling GPS
          return false;
        } catch (e) {
          // Other errors (timeout, permissions, etc.)
          print('Error getting position: $e');
          final gpsEnabled = await isGpsEnabled();
          print("gpsEnabled $gpsEnabled");
          return gpsEnabled;
        }
      }
      return true;
    } catch (e) {
      print('Error checking GPS: $e');
      return false;
    }
  }

  /// Check if Bluetooth adapter is enabled
  static Future<bool> isBluetoothEnabled() async {
    try {
      if (Platform.isAndroid) {
        final adapterState = await FlutterBluePlus.adapterState.first;
        return adapterState == BluetoothAdapterState.on;
      } else if (Platform.isIOS) {
        // On iOS, check if Bluetooth is available
        final adapterState = await FlutterBluePlus.adapterState.first;
        return adapterState == BluetoothAdapterState.on;
      }
      return false;
    } catch (e) {
      print('Error checking Bluetooth status: $e');
      return false;
    }
  }

  /// Prompt user to enable Bluetooth
  static Future<bool> promptEnableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        // On Android, we can request to turn on Bluetooth
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 1));
        return await isBluetoothEnabled();
      } else if (Platform.isIOS) {
        // On iOS, we can only open settings
        await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
        return false;
      }
      return false;
    } catch (e) {
      print('Error prompting Bluetooth enable: $e');

      // Check if user rejected the prompt
      if (e.toString().contains('user rejected') ||
          e.toString().contains('fbp-code: 11')) {
        // User explicitly rejected, don't open settings
        return false;
      }

      // For other errors, open settings as fallback
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
      return false;
    }
  }

  /// Stream of Bluetooth adapter state changes
  static Stream<BluetoothAdapterState> get bluetoothAdapterStateStream {
    return FlutterBluePlus.adapterState;
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
    } catch (e) {
      print('Error opening location settings: $e');
    }
  }

  /// Open Bluetooth settings
  static Future<void> openBluetoothSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
    } catch (e) {
      print('Error opening Bluetooth settings: $e');
    }
  }

  /// Check if permission is permanently denied
  static Future<bool> isLocationPermanentlyDenied() async {
    try {
      final status = await Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      print('Error checking permanently denied status: $e');
      return false;
    }
  }

  /// Check if Bluetooth permission is permanently denied
  static Future<bool> isBluetoothPermanentlyDenied() async {
    try {
      if (Platform.isAndroid) {
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;
        return scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        return status.isPermanentlyDenied;
      }
      return false;
    } catch (e) {
      print('Error checking Bluetooth permanently denied status: $e');
      return false;
    }
  }

  /// Get current location (requires permission)
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await isLocationPermissionGranted();
      if (!hasPermission) {
        print('Location permission not granted');
        return null;
      }

      // final isEnabled = await isGpsEnabled();
      // if (!isEnabled) {
      //   print('GPS is not enabled');
      //   return null;
      // }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Request all necessary permissions at once
  static Future<Map<String, bool>> requestAllPermissions() async {
    final locationGranted = await requestLocationPermission();
    final bluetoothGranted = await requestBluetoothPermission();

    return {
      'location': locationGranted,
      'bluetooth': bluetoothGranted,
    };
  }

  /// Check all permissions status at once
  static Future<Map<String, bool>> checkAllPermissions() async {
    final locationGranted = await isLocationPermissionGranted();
    final bluetoothGranted = await isBluetoothPermissionGranted();

    return {
      'location': locationGranted,
      'bluetooth': bluetoothGranted,
    };
  }

  /// Check all adapters status at once
  static Future<Map<String, bool>> checkAllAdapters() async {
    final gpsEnabled = await isGpsEnabled();
    final bluetoothEnabled = await isBluetoothEnabled();

    return {
      'gps': gpsEnabled,
      'bluetooth': bluetoothEnabled,
    };
  }

  /// Master function to setup all permissions and adapters in order
  /// Returns a map with status of each step and overall success
  static Future<Map<String, dynamic>> setupAllPermissionsAndAdapters() async {
    final errors = <String>[];
    final result = <String, dynamic>{
      'success': false,
      'locationPermission': false,
      'gpsEnabled': false,
      'bluetoothPermission': false,
      'bluetoothEnabled': false,
      'errors': errors,
    };

    try {
      // Step 1: Request Location Permission
      print('Step 1: Requesting location permission...');
      final locationPermission = await requestLocationPermission();
      result['locationPermission'] = locationPermission;

      if (!locationPermission) {
        final isPermanentlyDenied = await isLocationPermanentlyDenied();
        if (isPermanentlyDenied) {
          errors.add('Location permission permanently denied. Please enable in settings.');
          // await openLocationSettings();
          result['PermanentlyDenied'] = true;
          return result;
        } else {
          errors.add('Location permission denied.');
          return result;
        }
      }

      // Step 2: Enable GPS/Location Adapter
      print('Step 2: Checking GPS status...');
      final gpsEnabled = await isGpsEnabled();

      if (!gpsEnabled) {
        print('GPS disabled. Prompting user to enable...');
        final gpsPromptResult = await promptEnableGps();
        result['gpsEnabled'] = gpsPromptResult;

        if (!gpsPromptResult) {
          errors.add('GPS not enabled. Please enable location services.');
          return result;
        }
      } else {
        result['gpsEnabled'] = true;
      }

      // Step 3: Request Bluetooth Permission
      print('Step 3: Requesting Bluetooth permission...');
      final bluetoothPermission = await requestBluetoothPermission();
      result['bluetoothPermission'] = bluetoothPermission;

      if (!bluetoothPermission) {
        final isPermanentlyDenied = await isBluetoothPermanentlyDenied();
        if (isPermanentlyDenied) {
          errors.add('Bluetooth permission permanently denied. Please enable in settings.');
          // await openBluetoothSettings();
          result['PermanentlyDenied'] = true;
          return result;
        } else {
          errors.add('Bluetooth permission denied.');
          return result;
        }
      }

      // Step 4: Enable Bluetooth Adapter
      print('Step 4: Checking Bluetooth status...');
      final bluetoothEnabled = await isBluetoothEnabled();

      if (!bluetoothEnabled) {
        print('Bluetooth disabled. Prompting user to enable...');
        final bluetoothPromptResult = await promptEnableBluetooth();
        result['bluetoothEnabled'] = bluetoothPromptResult;

        if (!bluetoothPromptResult) {
          // Wait a moment and check again (user might have enabled it in settings)
          await Future.delayed(const Duration(seconds: 2));
          final recheckBluetooth = await isBluetoothEnabled();
          result['bluetoothEnabled'] = recheckBluetooth;

          if (!recheckBluetooth) {
            errors.add('Bluetooth not enabled. Please enable Bluetooth.');
            return result;
          }
        }
      } else {
        result['bluetoothEnabled'] = true;
      }

      // All steps completed successfully
      result['success'] = true;
      print('All permissions and adapters setup successfully!');

    } catch (e) {
      print('Error during setup: $e');
      errors.add('Unexpected error: $e');
    }

    return result;
  }

  /// Simplified master function that returns only success status
  static Future<bool> setupAll() async {
    final result = await setupAllPermissionsAndAdapters();
    return result['success'] as bool;
  }
}
