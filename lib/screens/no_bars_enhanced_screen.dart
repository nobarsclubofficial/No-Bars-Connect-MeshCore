import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import 'app_debug_log_screen.dart';
import 'app_settings_screen.dart';
import 'ble_debug_log_screen.dart';
import 'region_management_screen.dart';

/// No Bars Connect Enhanced feature hub.
///
/// This screen intentionally builds on the upstream MeshCore Open services
/// instead of duplicating protocol logic. No Bars additions are orchestration,
/// visibility, backup/restore, and one-place access to advanced tools.
class NoBarsEnhancedScreen extends StatelessWidget {
  const NoBarsEnhancedScreen({super.key});

  static const _pink = Color(0xFFFF1493);
  static const _blue = Color(0xFF00A6FF);
  static const _yellow = Color(0xFFFFD400);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No Bars Enhanced'), centerTitle: true),
      body: Consumer2<MeshCoreConnector, AppSettingsService>(
        builder: (context, connector, settingsService, _) {
          final settings = settingsService.settings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _hero(context, connector),
              const SizedBox(height: 18),
              _section('CONNECTION & AUTOMATION'),
              _card([
                _statusTile(
                  icon: Icons.autorenew,
                  color: _pink,
                  title: 'Auto reconnect',
                  subtitle: connector.isAutoReconnectScheduled
                      ? 'Recovering connection now'
                      : 'Armed for unexpected BLE disconnects',
                  trailing: const _ActiveChip(label: 'ACTIVE'),
                ),
                _divider(),
                _statusTile(
                  icon: Icons.health_and_safety_outlined,
                  color: _blue,
                  title: 'Connection recovery',
                  subtitle:
                      'Disconnect detection + exponential retry backoff up to 30 seconds',
                  trailing: const _ActiveChip(label: 'ON'),
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.route, color: _yellow),
                  title: const Text('Smart route rotation'),
                  subtitle: const Text(
                    'Learns successful paths and rotates routes on retries',
                  ),
                  value: settings.autoRouteRotationEnabled,
                  onChanged: settingsService.setAutoRouteRotationEnabled,
                ),
                _divider(),
                ListTile(
                  leading: const Icon(Icons.replay_circle_filled, color: _pink),
                  title: const Text('Message retry limit'),
                  subtitle: Text('${settings.maxMessageRetries} attempts'),
                  trailing: SizedBox(
                    width: 132,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Fewer retries',
                          onPressed: settings.maxMessageRetries > 2
                              ? () => settingsService.setMaxMessageRetries(
                                  settings.maxMessageRetries - 1,
                                )
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'More retries',
                          onPressed: settings.maxMessageRetries < 10
                              ? () => settingsService.setMaxMessageRetries(
                                  settings.maxMessageRetries + 1,
                                )
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              _section('RADIO & TRAFFIC'),
              _card([
                _navTile(
                  context,
                  icon: Icons.wifi_tethering,
                  color: _blue,
                  title: 'Live traffic',
                  subtitle: 'Raw BLE frames + decoded radio traffic',
                  screen: const BleDebugLogScreen(),
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.route_outlined, color: _yellow),
                  title: const Text('Traceroute & path metadata'),
                  subtitle: const Text(
                    'Show route/path details and tracing controls on messages',
                  ),
                  value: settings.enableMessageTracing,
                  onChanged: settingsService.setEnableMessageTracing,
                ),
                _divider(),
                _navTile(
                  context,
                  icon: Icons.public,
                  color: _pink,
                  title: 'Regions & coverage presets',
                  subtitle: 'Manage geographic transmit regions and presets',
                  onTap: () => pushRegionManagementScreen(context),
                ),
                _divider(),
                _navTile(
                  context,
                  icon: Icons.bug_report_outlined,
                  color: _blue,
                  title: 'Diagnostics log',
                  subtitle: 'Connection, retry and app diagnostics',
                  screen: const AppDebugLogScreen(),
                ),
              ]),
              const SizedBox(height: 18),
              _section('CONTACTS & DIRECTORY'),
              _card([
                _statusTile(
                  icon: Icons.person_add_alt_1,
                  color: _pink,
                  title: 'Auto add adverts',
                  subtitle:
                      'Users ${_onOff(connector.autoAddUsers)}  •  Repeaters ${_onOff(connector.autoAddRepeaters)}  •  Rooms ${_onOff(connector.autoAddRoomServers)}  •  Sensors ${_onOff(connector.autoAddSensors)}',
                ),
                _divider(),
                _statusTile(
                  icon: Icons.manage_search,
                  color: _yellow,
                  title: 'Directory / auto lookup',
                  subtitle:
                      '${connector.contacts.length} known contacts • ${connector.discoveredContacts.length} discovered nodes',
                  trailing: const _ActiveChip(label: 'LOCAL'),
                ),
                _divider(),
                _statusTile(
                  icon: Icons.hub_outlined,
                  color: _blue,
                  title: 'Path lookup & learning',
                  subtitle:
                      'Uses route history, reliability, latency and freshness for retry paths',
                  trailing: const _ActiveChip(label: 'ACTIVE'),
                ),
              ]),
              const SizedBox(height: 18),
              _section('NOTIFICATIONS'),
              _card([
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.notifications_active, color: _pink),
                  title: const Text('Notifications'),
                  subtitle: const Text('Master notification switch'),
                  value: settings.notificationsEnabled,
                  onChanged: settingsService.setNotificationsEnabled,
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.message_outlined, color: _blue),
                  title: const Text('Direct messages'),
                  value: settings.notifyOnNewMessage,
                  onChanged: settings.notificationsEnabled
                      ? settingsService.setNotifyOnNewMessage
                      : null,
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.tag, color: _yellow),
                  title: const Text('Channel messages'),
                  value: settings.notifyOnNewChannelMessage,
                  onChanged: settings.notificationsEnabled
                      ? settingsService.setNotifyOnNewChannelMessage
                      : null,
                ),
                _divider(),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.sensors, color: _pink),
                  title: const Text('New adverts / nodes'),
                  value: settings.notifyOnNewAdvert,
                  onChanged: settings.notificationsEnabled
                      ? settingsService.setNotifyOnNewAdvert
                      : null,
                ),
              ]),
              const SizedBox(height: 18),
              _section('CONNECTION & DEVICE'),
              _card([
                ListTile(
                  leading: const Icon(Icons.battery_charging_full, color: _blue),
                  title: const Text('Battery monitor'),
                  subtitle: Text(_batteryText(connector)),
                  trailing: IconButton(
                    tooltip: 'Refresh battery',
                    onPressed: connector.isConnected
                        ? () => connector.requestBatteryStatus(force: true)
                        : null,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                _divider(),
                _statusTile(
                  icon: Icons.bluetooth_connected,
                  color: _pink,
                  title: 'Connection state',
                  subtitle: connector.isConnected
                      ? 'Connected to ${connector.deviceDisplayName}'
                      : 'Not connected',
                ),
              ]),
              const SizedBox(height: 18),
              _section('BACKUP & APP'),
              _card([
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: _yellow),
                  title: const Text('Backup settings'),
                  subtitle: const Text('Copy a portable JSON settings backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportSettings(context, settingsService),
                ),
                _divider(),
                ListTile(
                  leading: const Icon(Icons.restore, color: _pink),
                  title: const Text('Restore settings'),
                  subtitle: const Text('Paste a No Bars Connect settings backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _restoreSettings(context, settingsService),
                ),
                _divider(),
                _navTile(
                  context,
                  icon: Icons.tune,
                  color: _blue,
                  title: 'All app settings',
                  subtitle: 'Appearance, maps, translation, battery and more',
                  screen: const AppSettingsScreen(),
                ),
              ]),
              const SizedBox(height: 16),
              const Text(
                'No Bars Connect Enhanced adds a consolidated advanced-control layer while preserving MeshCore protocol compatibility and upstream attribution.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context, MeshCoreConnector connector) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pink.withValues(alpha: .55)),
        gradient: LinearGradient(
          colors: [
            _pink.withValues(alpha: .14),
            _blue.withValues(alpha: .08),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: _yellow),
              SizedBox(width: 8),
              Text(
                'No Bars Enhanced',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            connector.isConnected
                ? 'Advanced mesh tools are online.'
                : 'Connect a node to light up the live radio tools.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.15,
      ),
    ),
  );

  Widget _card(List<Widget> children) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );

  Widget _divider() => const Divider(height: 1, indent: 56);

  Widget _statusTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: trailing,
  );

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? screen,
    VoidCallback? onTap,
  }) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap ??
        (screen == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => screen),
                )),
  );

  String _batteryText(MeshCoreConnector connector) {
    final mv = connector.batteryMillivolts;
    final percent = connector.batteryPercent;
    if (mv == null) return 'Waiting for battery telemetry';
    final volts = (mv / 1000).toStringAsFixed(2);
    return percent == null ? '$volts V' : '$percent% • $volts V';
  }

  static String _onOff(bool? value) => value == true ? 'ON' : 'OFF';

  Future<void> _exportSettings(
    BuildContext context,
    AppSettingsService service,
  ) async {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'format': 'no-bars-connect-settings',
      'version': 1,
      'settings': service.settings.toJson(),
    });
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup copied'),
        content: const Text(
          'Your No Bars Connect settings backup is on the clipboard. Save it somewhere safe as text or JSON.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreSettings(
    BuildContext context,
    AppSettingsService service,
  ) async {
    final controller = TextEditingController();
    final payload = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore settings'),
        content: TextField(
          controller: controller,
          minLines: 5,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Paste No Bars Connect backup JSON here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (payload == null || payload.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != 'no-bars-connect-settings' ||
          decoded['settings'] is! Map) {
        throw const FormatException('Not a No Bars Connect settings backup');
      }
      final settingsMap = Map<String, dynamic>.from(decoded['settings'] as Map);
      await service.updateSettings(AppSettings.fromJson(settingsMap));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings restored successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not restore backup: $error')),
      );
    }
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;

  const _ActiveChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00A6FF).withValues(alpha: .13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFF00A6FF).withValues(alpha: .45),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF00A6FF),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
