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
    _checkAllStatuses();
    _listenToBluetoothState();
  }

  void _listenToBluetoothState() {
    AdapterManager.bluetoothAdapterStateStream.listen((state) {
      setState(() {
        _bluetoothEnabled = state == BluetoothAdapterState.on;
      });
    });
  }

  Future<void> _checkAllStatuses() async {
    setState(() => _isLoading = true);

    try {
      final permissions = await AdapterManager.checkAllPermissions();
      final adapters = await AdapterManager.checkAllAdapters();

      setState(() {
        _locationPermissionGranted = permissions['location'] ?? false;
        _bluetoothPermissionGranted = permissions['bluetooth'] ?? false;
        _gpsEnabled = adapters['gps'] ?? false;
        _bluetoothEnabled = adapters['bluetooth'] ?? false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    final granted = await AdapterManager.requestLocationPermission();
    setState(() => _locationPermissionGranted = granted);

    if (!granted) {
      final isPermanentlyDenied = await AdapterManager.isLocationPermanentlyDenied();
      if (isPermanentlyDenied) {
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
    setState(() => _bluetoothPermissionGranted = granted);

    if (!granted) {
      final isPermanentlyDenied = await AdapterManager.isBluetoothPermanentlyDenied();
      if (isPermanentlyDenied) {
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
      _locationPermissionGranted = results['location'] ?? false;
      _bluetoothPermissionGranted = results['bluetooth'] ?? false;
      _isLoading = false;
    });

    final allGranted = results.values.every((granted) => granted);
    if (allGranted) {
      _showSnackBar('All permissions granted!');
    } else {
      _showSnackBar('Some permissions were denied');
    }
  }

  Future<void> _checkAllStatus() async {
    final result = await AdapterManager.setupAllPermissionsAndAdapters();
    if (result['success']) {
      _showSnackBar('All setup complete!');
    } else {
      _showSnackBar('${result['errors']}');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await AdapterManager.getCurrentLocation();

      if (position != null) {
        _showLocationDialog(position);
      } else {
        _showSnackBar('Unable to get location. Check permissions and GPS.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _showLocationDialog(Position position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${position.latitude}'),
            Text('Longitude: ${position.longitude}'),
            Text('Accuracy: ${position.accuracy}m'),
            Text('Altitude: ${position.altitude}m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
      body: RefreshIndicator(
        onRefresh: _checkAllStatuses,
        child: ListView(
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
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Get Current Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkAllStatuses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh All Status'),
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
      ),
    );
  }
}