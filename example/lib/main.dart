import 'package:flutter/material.dart';
import 'package:adapter_manager/adapter_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adapter Manager Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AdapterManagerDemo(),
    );
  }
}

class AdapterManagerDemo extends StatefulWidget {
  const AdapterManagerDemo({Key? key}) : super(key: key);

  @override
  State<AdapterManagerDemo> createState() => _AdapterManagerDemoState();
}

class _AdapterManagerDemoState extends State<AdapterManagerDemo> {
  bool _locationPermissionGranted = false;
  bool _bluetoothPermissionGranted = false;
  bool _gpsEnabled = false;
  bool _bluetoothEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _requestLocationPermission() async {
    final granted = await AdapterManager.requestLocationPermission();
    setState(() => _locationPermissionGranted = (granted == PermissionStatus.granted));

    if (!_locationPermissionGranted) {
      if (granted == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog(
          'Location Permission',
          'Location permission is permanently denied. Please enable it in settings.',
              () => AdapterManager.openLocationSettings(),
        );
      } else {
        _showSnackBar('Location permission denied');
      }
    } else {
      _showSnackBar('Location permission granted');
    }
  }

  Future<void> _requestBluetoothPermission() async {
    final granted = await AdapterManager.requestBluetoothPermission();
    setState(() => _bluetoothPermissionGranted = (granted == PermissionStatus.granted));

    if (!_bluetoothPermissionGranted) {
      if (granted == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog(
          'Bluetooth Permission',
          'Bluetooth permission is permanently denied. Please enable it in settings.',
              () => AdapterManager.openBluetoothSettings(),
        );
      } else {
        _showSnackBar('Bluetooth permission denied');
      }
    } else {
      _showSnackBar('Bluetooth permission granted');
    }
  }

  Future<void> _enableGps() async {
    final enabled = await AdapterManager.promptEnableGps();
    await Future.delayed(const Duration(seconds: 1));
    final isEnabled = await AdapterManager.isGpsEnabled();
    setState(() => _gpsEnabled = isEnabled);

    if (isEnabled) {
      _showSnackBar('GPS enabled successfully');
    } else {
      _showSnackBar('Please enable GPS in settings');
    }
  }

  Future<void> _enableBluetooth() async {
    await AdapterManager.promptEnableBluetooth();
    await Future.delayed(const Duration(seconds: 1));
    final isEnabled = await AdapterManager.isBluetoothEnabled();
    setState(() => _bluetoothEnabled = isEnabled);

    if (isEnabled) {
      _showSnackBar('Bluetooth enabled successfully');
    } else {
      _showSnackBar('Please enable Bluetooth in settings');
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    final results = await AdapterManager.requestAllPermissions();

    setState(() {
      _locationPermissionGranted = (results['location'] == PermissionStatus.granted) ?? false;
      _bluetoothPermissionGranted = (results['bluetooth'] == PermissionStatus.granted) ?? false;
      _isLoading = false;
    });

    final allGranted = results.values.every((granted) => granted == PermissionStatus.granted);
    if (allGranted) {
      _showSnackBar('All permissions granted!');
    } else {
      _showSnackBar('Some permissions were denied');
    }
  }

  Future<void> _checkAllStatus() async {
    try{
      final result = await AdapterManager.setupAllPermissionsAndAdapters();
      if (result['success']) {
        _showSnackBar('All setup complete!');
      } else {
        _showSnackBar('${result['errors']}');
      }
    }on AdapterException catch(e){
      if(e.message.contains("GPS")){
        showLocationDialog(context);
      }
    }
  }

  void showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const LocationServicesDialog();
      },
    );
  }

  void _showPermissionDialog(String title, String message, VoidCallback onOpenSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required bool isEnabled,
    required VoidCallback onTap,
    required IconData icon,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          icon,
          color: isEnabled ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle ?? (isEnabled ? 'Enabled' : 'Disabled'),
          style: TextStyle(
            color: isEnabled ? Colors.green : Colors.red,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: _isLoading ? null : onTap,
          child: Text(isEnabled ? 'Check' : 'Enable'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adapter Manager'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Permissions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusCard(
            title: 'Location Permission',
            isEnabled: _locationPermissionGranted,
            onTap: _requestLocationPermission,
            icon: Icons.location_on,
          ),
          const SizedBox(height: 8),
          _buildStatusCard(
            title: 'Bluetooth Permission',
            isEnabled: _bluetoothPermissionGranted,
            onTap: _requestBluetoothPermission,
            icon: Icons.bluetooth,
          ),
          const SizedBox(height: 24),
          const Text(
            'Adapters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusCard(
            title: 'GPS',
            isEnabled: _gpsEnabled,
            onTap: _enableGps,
            icon: Icons.gps_fixed,
          ),
          const SizedBox(height: 8),
          _buildStatusCard(
            title: 'Bluetooth Adapter',
            isEnabled: _bluetoothEnabled,
            onTap: _enableBluetooth,
            icon: Icons.bluetooth_connected,
          ),
          const SizedBox(height: 24),
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checkAllStatus,
            icon: const Icon(Icons.check),
            label: const Text('Check all status'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => AdapterManager.openAppSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Open App Settings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}