import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../services/app_settings_service.dart';
import 'ble_debug_log_screen.dart';
import 'discovery_screen.dart';
import 'map_screen.dart';
import 'no_bars_enhanced_screen.dart';
import 'scanner_screen.dart';

class NoBarsProScreen extends StatelessWidget {
  const NoBarsProScreen({super.key});

  static const _pink = Color(0xFFFF1493);
  static const _blue = Color(0xFF00A6FF);
  static const _yellow = Color(0xFFFFD400);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NO BARS PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            Text('Connect Beyond Coverage.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer2<MeshCoreConnector, AppSettingsService>(
        builder: (context, connector, settingsService, _) {
          final settings = settingsService.settings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              _hero(context, connector),
              const SizedBox(height: 18),
              _section('PRO DASHBOARD'),
              _statsCard(connector),
              const SizedBox(height: 18),
              _section('NETWORK INTELLIGENCE'),
              _card([
                _navTile(
                  context,
                  icon: Icons.manage_search,
                  color: _pink,
                  title: 'Node discovery & lookup',
                  subtitle: '${connector.discoveredContacts.length} discovered • ${connector.contacts.length} known',
                  screen: const DiscoveryScreen(),
                ),
                _divider(),
                _navTile(
                  context,
                  icon: Icons.alt_route,
                  color: _blue,
                  title: 'Multi-path & route intelligence',
                  subtitle: 'Path learning, retries, tracing and route history',
                  screen: const NoBarsEnhancedScreen(),
                ),
                _divider(),
                _navTile(
                  context,
                  icon: Icons.map_outlined,
                  color: _yellow,
                  title: 'Coverage & network map',
                  subtitle: 'Nodes, repeaters, discovered contacts and route context',
                  screen: const MapScreen(),
                ),
              ]),
              const SizedBox(height: 18),
              _section('LIVE RADIO'),
              _card([
                _navTile(
                  context,
                  icon: Icons.monitor_heart_outlined,
                  color: _blue,
                  title: 'Live traffic monitor',
                  subtitle: 'BLE frames and decoded radio traffic in real time',
                  screen: const BleDebugLogScreen(),
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.route, color: _yellow),
                  title: const Text('Smart route rotation'),
                  subtitle: const Text('Automatically rotate learned paths when delivery needs another route'),
                  value: settings.autoRouteRotationEnabled,
                  onChanged: settingsService.setAutoRouteRotationEnabled,
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.notifications_active_outlined, color: _pink),
                  title: const Text('Mesh notifications'),
                  subtitle: const Text('Messages, channels and new node adverts'),
                  value: settings.notificationsEnabled,
                  onChanged: settingsService.setNotificationsEnabled,
                ),
              ]),
              const SizedBox(height: 18),
              _section('CONNECTION'),
              _card([
                _statusTile(
                  icon: Icons.autorenew,
                  color: _pink,
                  title: 'Auto reconnect',
                  subtitle: connector.isAutoReconnectScheduled
                      ? 'Reconnect attempt scheduled now'
                      : 'Automatic recovery armed for unexpected BLE drops',
                ),
                _divider(),
                _statusTile(
                  icon: Icons.battery_charging_full,
                  color: _blue,
                  title: 'Node battery',
                  subtitle: _batteryText(connector),
                ),
                _divider(),
                _navTile(
                  context,
                  icon: Icons.bluetooth_searching,
                  color: _yellow,
                  title: connector.isConnected ? 'Switch device' : 'Connect a device',
                  subtitle: connector.isConnected
                      ? 'Currently connected to ${connector.deviceDisplayName}'
                      : 'Scan for a MeshCore companion over Bluetooth',
                  screen: const ScannerScreen(),
                ),
              ]),
              const SizedBox(height: 18),
              _section('PRO TOOLKIT'),
              _card([
                _navTile(
                  context,
                  icon: Icons.bolt,
                  color: _pink,
                  title: 'Advanced automation & diagnostics',
                  subtitle: 'Reconnect, retries, paths, battery, backup, logs and regions',
                  screen: const NoBarsEnhancedScreen(),
                ),
                _divider(),
                const ListTile(
                  leading: Icon(Icons.hub_outlined, color: _blue),
                  title: Text('Online hop resolver'),
                  subtitle: Text('Foundation ready: resolve path prefixes against trusted public directories'),
                  trailing: _BetaChip(),
                ),
                _divider(),
                const ListTile(
                  leading: Icon(Icons.analytics_outlined, color: _yellow),
                  title: Text('Network statistics'),
                  subtitle: Text('Live counts now; packet, hop and repeater analytics expand from this dashboard'),
                  trailing: _BetaChip(),
                ),
              ]),
              const SizedBox(height: 18),
              const Text(
                'NO BARS PRO • Connect Beyond Coverage.\nBuilt on MeshCore Open with upstream attribution preserved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context, MeshCoreConnector connector) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pink.withValues(alpha: .6)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink.withValues(alpha: .16), _blue.withValues(alpha: .10), _yellow.withValues(alpha: .05)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NO BARS PRO', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          const SizedBox(height: 4),
          const Text('Connect Beyond Coverage.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _blue)),
          const SizedBox(height: 14),
          Text(
            connector.isConnected
                ? 'Live mesh intelligence is active on ${connector.deviceDisplayName}.'
                : 'Connect a node to activate live traffic, route intelligence and network diagnostics.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _statsCard(MeshCoreConnector connector) {
    return _card([
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _metric('KNOWN', '${connector.contacts.length}', _pink)),
            Expanded(child: _metric('DISCOVERED', '${connector.discoveredContacts.length}', _blue)),
            Expanded(child: _metric('CHANNELS', '${connector.channels.length}', _yellow)),
          ],
        ),
      ),
    ]);
  }

  Widget _metric(String label, String value, Color color) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: .8)),
        ],
      );

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.15)),
      );

  Widget _card(List<Widget> children) => Card(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, child: Column(children: children));
  Widget _divider() => const Divider(height: 1, indent: 56);

  Widget _statusTile({required IconData icon, required Color color, required String title, required String subtitle}) => ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      );

  Widget _navTile(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required Widget screen}) => ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
      );

  String _batteryText(MeshCoreConnector connector) {
    final mv = connector.batteryMillivolts;
    final percent = connector.batteryPercent;
    if (mv == null) return connector.isConnected ? 'Waiting for battery telemetry' : 'Connect a node to read battery';
    final volts = (mv / 1000).toStringAsFixed(2);
    return percent == null ? '$volts V' : '$percent% • $volts V';
  }
}

class _BetaChip extends StatelessWidget {
  const _BetaChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1493).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFFF1493).withValues(alpha: .45)),
      ),
      child: const Text('BETA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFF1493))),
    );
  }
}
