import 'package:flutter/material.dart';
import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_manager.dart';
import 'package:provider/provider.dart';

/// Scans for and connects to the bite-tracker bracelet, and shows what it
/// reports while connected. Reached from the Bluetooth button on the Bite tab;
/// leaving the page keeps the link open.
class BraceletPage extends StatefulWidget {
  const BraceletPage({super.key});

  @override
  State<BraceletPage> createState() => _BraceletPageState();
}

class _BraceletPageState extends State<BraceletPage> {
  @override
  void initState() {
    super.initState();
    final manager = context.read<BraceletManager>();
    if (manager.connectionState == BraceletConnectionState.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => manager.startScan());
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BraceletManager>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bracelet')),
      body: manager.isConnected
          ? _ConnectedView(manager: manager)
          : _DisconnectedView(manager: manager),
    );
  }
}

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView({required this.manager});

  final BraceletManager manager;

  @override
  Widget build(BuildContext context) {
    final connecting =
        manager.connectionState == BraceletConnectionState.connecting;
    final error = manager.error;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusRow(state: manager.connectionState),
        if (error != null) ...[
          const SizedBox(height: 8),
          _ErrorMessage(error: error),
        ],
        const SizedBox(height: 16),
        if (connecting) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Connecting to ${manager.deviceName ?? 'bracelet'}…'),
        ] else ...[
          FilledButton.icon(
            onPressed: manager.isScanning ? null : manager.startScan,
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(manager.isScanning ? 'Scanning…' : 'Scan'),
          ),
          if (manager.isScanning) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 8),
          for (final bracelet in manager.scanResults)
            ListTile(
              leading: const Icon(Icons.watch),
              title: Text(bracelet.name),
              subtitle: Text('Signal ${bracelet.rssi} dBm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => manager.connect(bracelet),
            ),
          if (manager.hasScanned &&
              !manager.isScanning &&
              manager.scanResults.isEmpty &&
              error == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No bracelet found. Make sure it is switched on and not '
                'connected to another device, then scan again.',
              ),
            ),
        ],
      ],
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({required this.manager});

  final BraceletManager manager;

  @override
  Widget build(BuildContext context) {
    final battery = manager.batteryPercent;
    final charging = manager.isCharging;
    final uptime = manager.uptime;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusRow(state: manager.connectionState),
        _InfoTile(
          icon: Icons.watch,
          label: 'Device',
          value: manager.deviceName ?? '—',
        ),
        _InfoTile(
          icon: Icons.battery_std,
          label: 'Battery',
          value: battery == null ? '—' : '$battery %',
        ),
        _InfoTile(
          icon: Icons.power,
          label: 'Charging',
          value: charging == null ? '—' : (charging ? 'Yes' : 'No'),
        ),
        _InfoTile(
          icon: Icons.timer_outlined,
          label: 'Uptime',
          value: uptime == null ? '—' : formatUptime(uptime),
        ),
        _InfoTile(
          icon: Icons.restart_alt,
          label: 'Last reset',
          value: manager.resetReason?.label ?? '—',
        ),
        _InfoTile(
          icon: Icons.factory_outlined,
          label: 'Manufacturer',
          value: manager.manufacturer ?? '—',
        ),
        _InfoTile(
          icon: Icons.memory,
          label: 'Model',
          value: manager.model ?? '—',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: manager.disconnect,
          icon: const Icon(Icons.bluetooth_disabled),
          label: const Text('Disconnect'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => _confirmShutdown(context),
          icon: const Icon(Icons.power_settings_new),
          label: const Text('Shut down'),
        ),
      ],
    );
  }

  Future<void> _confirmShutdown(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shut down the bracelet?'),
        content: const Text(
          'To switch it back on, press its reset button or plug it into a '
          'USB cable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Shut down'),
          ),
        ],
      ),
    );
    if (confirmed == true) await manager.shutdown();
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.state});

  final BraceletConnectionState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      BraceletConnectionState.connected => 'Connected',
      BraceletConnectionState.connecting => 'Connecting',
      BraceletConnectionState.disconnected => 'Disconnected',
    };
    return _InfoTile(
      icon: state == BraceletConnectionState.connected
          ? Icons.bluetooth_connected
          : Icons.bluetooth,
      label: 'Status',
      value: label,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final BraceletError error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      BraceletError.permissionDenied =>
        'FoodLocker needs the Nearby devices permission to find the bracelet. '
            'Allow it in Android settings, then scan again.',
      BraceletError.bluetoothOff =>
        'Bluetooth is off. Turn it on, then scan again.',
      BraceletError.bluetoothUnavailable =>
        'This phone has no Bluetooth the app can use.',
      BraceletError.scanFailed => 'Scanning failed. Try again.',
      BraceletError.connectionFailed =>
        "Couldn't connect to the bracelet. Make sure it is on and nearby, "
            'then try again.',
      BraceletError.connectionLost => 'The bracelet disconnected.',
    };
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}

/// [uptime] in its two largest units, e.g. `1 h 12 min`.
String formatUptime(Duration uptime) {
  final days = uptime.inDays;
  final hours = uptime.inHours % 24;
  final minutes = uptime.inMinutes % 60;
  if (days > 0) return '$days d $hours h';
  if (hours > 0) return '$hours h $minutes min';
  if (minutes > 0) return '$minutes min';
  return '${uptime.inSeconds} s';
}
