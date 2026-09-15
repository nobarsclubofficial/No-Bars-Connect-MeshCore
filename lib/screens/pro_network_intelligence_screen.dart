import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../connector/meshcore_connector.dart';
import '../models/contact.dart';
import 'ble_debug_log_screen.dart';
import 'map_screen.dart';
import 'scanner_screen.dart';

class ProNetworkIntelligenceScreen extends StatefulWidget {
  const ProNetworkIntelligenceScreen({super.key});

  @override
  State<ProNetworkIntelligenceScreen> createState() => _ProNetworkIntelligenceScreenState();
}

class _ProNetworkIntelligenceScreenState extends State<ProNetworkIntelligenceScreen> {
  static const _pink = Color(0xFFFF1493);
  static const _blue = Color(0xFF00A6FF);
  static const _yellow = Color(0xFFFFD400);

  StreamSubscription<Uint8List>? _frameSub;
  MeshCoreConnector? _boundConnector;
  DateTime _sessionStarted = DateTime.now();
  int _frames = 0;
  int _bytes = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final connector = context.read<MeshCoreConnector>();
    if (!identical(_boundConnector, connector)) {
      _frameSub?.cancel();
      _boundConnector = connector;
      _frameSub = connector.receivedFrames.listen((frame) {
        if (!mounted) return;
        setState(() {
          _frames++;
          _bytes += frame.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _frameSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRO Network Intelligence')),
      body: Consumer<MeshCoreConnector>(
        builder: (context, connector, _) {
          final contacts = connector.allContactsUnfiltered;
          final now = DateTime.now();
          final active = contacts.where((c) => now.difference(c.lastSeen) <= const Duration(minutes: 15)).toList();
          final repeaters = contacts.where((c) => c.typeLabelRaw == 'Repeater').toList();
          final located = contacts.where((c) => c.hasLocation).toList();
          final favorites = contacts.where((c) => c.isFavorite).toList();
          final staleWatch = favorites.where((c) => now.difference(c.lastSeen) > const Duration(hours: 6)).toList();
          final highHop = contacts.where((c) => c.pathLength >= 4).toList();
          final routed = contacts.where((c) => c.pathLength >= 0).toList();
          final avgHops = routed.isEmpty ? 0.0 : routed.fold<int>(0, (sum, c) => sum + c.pathLength) / routed.length;
          final sortedRoutes = [...routed]..sort((a, b) => _routeScore(b, now).compareTo(_routeScore(a, now)));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              _hero(connector, active.length, staleWatch.length),
              const SizedBox(height: 16),
              _section('NETWORK HEALTH'),
              _metricGrid([
                _Metric('ACTIVE 15M', '${active.length}', _blue),
                _Metric('REPEATERS', '${repeaters.length}', _yellow),
                _Metric('AVG HOPS', avgHops.toStringAsFixed(1), _pink),
                _Metric('MAPPED', '${located.length}', _blue),
              ]),
              const SizedBox(height: 16),
              _section('ROUTE HEALTH'),
              _card([
                if (sortedRoutes.isEmpty)
                  const ListTile(title: Text('No learned routes yet'), subtitle: Text('Route scores appear as contacts and paths are learned.'))
                else
                  ...sortedRoutes.take(8).map((c) => _routeTile(c, now)),
              ]),
              const SizedBox(height: 16),
              _section('NODE WATCHLIST'),
              _card([
                if (favorites.isEmpty)
                  const ListTile(leading: Icon(Icons.star_border), title: Text('No watched nodes'), subtitle: Text('Favorite important nodes to make them part of the PRO watchlist.'))
                else
                  ...favorites.take(10).map((c) => _watchTile(c, now)),
              ]),
              const SizedBox(height: 16),
              _section('ANOMALY DETECTION'),
              _card([
                _alertTile(
                  connector.isConnected ? Icons.check_circle_outline : Icons.bluetooth_disabled,
                  connector.isConnected ? 'Companion connection healthy' : 'Companion disconnected',
                  connector.isConnected ? 'Live monitoring is available.' : 'Connect a companion to restore live monitoring.',
                  connector.isConnected ? _blue : _pink,
                ),
                const Divider(height: 1),
                _alertTile(
                  staleWatch.isEmpty ? Icons.visibility_outlined : Icons.warning_amber_rounded,
                  staleWatch.isEmpty ? 'Watchlist healthy' : '${staleWatch.length} watched node${staleWatch.length == 1 ? '' : 's'} stale',
                  staleWatch.isEmpty ? 'No favorite node has been silent for more than 6 hours.' : 'Review nodes that have not been heard recently.',
                  staleWatch.isEmpty ? _blue : _yellow,
                ),
                const Divider(height: 1),
                _alertTile(
                  highHop.isEmpty ? Icons.alt_route : Icons.route,
                  highHop.isEmpty ? 'No high-hop routes detected' : '${highHop.length} high-hop route${highHop.length == 1 ? '' : 's'}',
                  highHop.isEmpty ? 'Current learned paths are under four hops.' : 'Longer routes may deserve closer reliability monitoring.',
                  highHop.isEmpty ? _blue : _yellow,
                ),
              ]),
              const SizedBox(height: 16),
              _section('SESSION RECORDER'),
              _card([
                ListTile(
                  leading: const Icon(Icons.fiber_manual_record, color: _pink),
                  title: Text('$_frames received frames • ${_formatBytes(_bytes)}'),
                  subtitle: Text('Recording since ${_clock(_sessionStarted)} • resets locally when you tap Reset'),
                  trailing: TextButton(onPressed: _resetSession, child: const Text('RESET')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined, color: _blue),
                  title: const Text('Open filtered traffic tools'),
                  subtitle: const Text('Inspect decoded BLE/radio traffic and narrow down troubleshooting.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const BleDebugLogScreen()),
                ),
              ]),
              const SizedBox(height: 16),
              _section('COVERAGE INTELLIGENCE'),
              _card([
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: _yellow),
                  title: Text('${located.length} nodes with usable location data'),
                  subtitle: Text('${active.where((c) => c.hasLocation).length} mapped nodes heard in the last 15 minutes. Open the network map for spatial coverage.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const MapScreen()),
                ),
              ]),
              const SizedBox(height: 16),
              _section('EMERGENCY / OPERATOR MODE'),
              _card([
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: _pink),
                  title: Text(connector.isConnected ? connector.deviceDisplayName : 'No companion connected'),
                  subtitle: Text('${connector.channels.length} channels • ${active.length} active nodes • battery ${_battery(connector)}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bluetooth_searching, color: _yellow),
                  title: const Text('Switch operator device'),
                  subtitle: const Text('Move quickly between carry, vehicle, base or field companions.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const ScannerScreen()),
                ),
              ]),
              const SizedBox(height: 16),
              _section('OFFLINE INTELLIGENCE & REPORTING'),
              _card([
                ListTile(
                  leading: const Icon(Icons.storage_outlined, color: _blue),
                  title: Text('${contacts.length} locally available node records'),
                  subtitle: const Text('Names, IDs, last-seen state, learned paths and available location data remain useful without internet.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.ios_share, color: _yellow),
                  title: const Text('Export PRO network report'),
                  subtitle: const Text('Share a text snapshot of network health, routes, watchlist and current session.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _shareReport(connector, contacts, active, repeaters, favorites, avgHops),
                ),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Route health is an app-side operational score based on hop count and freshness; it is not a protocol delivery guarantee. More packet-success and latency history can be layered into the score as observations accumulate.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(MeshCoreConnector c, int active, int alerts) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _pink.withValues(alpha: .55)),
          gradient: LinearGradient(colors: [_pink.withValues(alpha: .14), _blue.withValues(alpha: .09), _yellow.withValues(alpha: .05)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NETWORK INTELLIGENCE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(c.isConnected ? '$active nodes active • ${alerts == 0 ? 'no watchlist alerts' : '$alerts watchlist alert${alerts == 1 ? '' : 's'}'}' : 'Offline snapshot ready • connect a companion for live intelligence', style: const TextStyle(color: _blue, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _metricGrid(List<_Metric> metrics) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: metrics.map((m) => SizedBox(width: (MediaQuery.sizeOf(context).width - 42) / 2, child: Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [Text(m.value, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: m.color)), const SizedBox(height: 3), Text(m.label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: .8))]))))).toList(),
      );

  Widget _routeTile(Contact c, DateTime now) {
    final score = _routeScore(c, now);
    final label = score >= 80 ? 'EXCELLENT' : score >= 60 ? 'GOOD' : score >= 40 ? 'FAIR' : 'POOR';
    final color = score >= 80 ? _blue : score >= 60 ? _yellow : _pink;
    final hops = c.pathLength == 0 ? 'direct' : '${c.pathLength} hop${c.pathLength == 1 ? '' : 's'}';
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12))),
      title: Text(c.name.isEmpty ? c.shortPubKeyHex : c.name),
      subtitle: Text('$hops • last heard ${_age(c.lastSeen, now)}'),
      trailing: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _watchTile(Contact c, DateTime now) {
    final stale = now.difference(c.lastSeen) > const Duration(hours: 6);
    return ListTile(
      leading: Icon(stale ? Icons.warning_amber_rounded : Icons.star, color: stale ? _yellow : _pink),
      title: Text(c.name.isEmpty ? c.shortPubKeyHex : c.name),
      subtitle: Text('${c.typeLabelRaw} • heard ${_age(c.lastSeen, now)}'),
      trailing: Text(stale ? 'STALE' : 'ONLINE', style: TextStyle(color: stale ? _yellow : _blue, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _alertTile(IconData icon, String title, String subtitle, Color color) => ListTile(leading: Icon(icon, color: color), title: Text(title), subtitle: Text(subtitle));
  Widget _card(List<Widget> children) => Card(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, child: Column(children: children));
  Widget _section(String text) => Padding(padding: const EdgeInsets.fromLTRB(6, 0, 6, 7), child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.15)));

  int _routeScore(Contact c, DateTime now) {
    if (c.pathLength < 0) return 35;
    final ageMinutes = now.difference(c.lastSeen).inMinutes.clamp(0, 1440);
    final hopPenalty = c.pathLength * 9;
    final agePenalty = (ageMinutes / 30).floor().clamp(0, 35);
    return (100 - hopPenalty - agePenalty).clamp(0, 100);
  }

  void _resetSession() => setState(() { _sessionStarted = DateTime.now(); _frames = 0; _bytes = 0; });
  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _shareReport(MeshCoreConnector c, List<Contact> contacts, List<Contact> active, List<Contact> repeaters, List<Contact> favorites, double avgHops) async {
    final report = '''NO BARS PRO — Network Intelligence Report
Generated: ${DateTime.now().toLocal()}
Companion: ${c.isConnected ? c.deviceDisplayName : 'Disconnected'}
Known/discovered records: ${contacts.length}
Active (15m): ${active.length}
Repeaters: ${repeaters.length}
Channels: ${c.channels.length}
Watchlist: ${favorites.length}
Average learned hops: ${avgHops.toStringAsFixed(1)}
Session frames: $_frames
Session bytes: $_bytes
Battery: ${_battery(c)}

Powered by MeshCore. NO BARS PRO operational metrics are app-side observations.''';
    await SharePlus.instance.share(ShareParams(text: report, subject: 'NO BARS PRO Network Report'));
  }

  String _battery(MeshCoreConnector c) {
    final mv = c.batteryMillivolts;
    final percent = c.batteryPercent;
    if (mv == null) return 'waiting';
    final volts = (mv / 1000).toStringAsFixed(2);
    return percent == null ? '$volts V' : '$percent% • $volts V';
  }

  String _formatBytes(int bytes) => bytes < 1024 ? '$bytes B' : bytes < 1024 * 1024 ? '${(bytes / 1024).toStringAsFixed(1)} KB' : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  String _clock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _age(DateTime d, DateTime now) { final diff = now.difference(d); if (diff.inMinutes < 1) return 'just now'; if (diff.inMinutes < 60) return '${diff.inMinutes}m ago'; if (diff.inHours < 24) return '${diff.inHours}h ago'; return '${diff.inDays}d ago'; }
}

class _Metric {
  final String label;
  final String value;
  final Color color;
  const _Metric(this.label, this.value, this.color);
}
