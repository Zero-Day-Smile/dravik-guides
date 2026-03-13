import 'package:flutter/material.dart';
import 'package:dravik/services/emergency_contact_service.dart';
import 'package:hive/hive.dart';
import 'package:dravik/models/emergency_contact.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:dravik/screens/settings_screen.dart' show LocationAccuracy;
import 'package:dravik/config/feature_flags.dart';
import 'package:dravik/widgets/platform_unavailable_screen.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final EmergencyContactService _service = EmergencyContactService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<EmergencyContact> _contacts = [];
  Duration _interval = const Duration(hours: 12);
  bool _loading = true;
  String? _lastOkText;
  String? _pendingAlertText;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contacts = await _service.getContacts();
    // Read header status info
    final settings = await Hive.openBox('emergency_settings');
    final lastOk = settings.get('last_ok');
    final pending = settings.get('pending_alert');
    String? okText;
    String? alertText;
    if (lastOk is Map) {
      okText = lastOk['message'] as String?;
    }
    if (pending is Map) {
      alertText = pending['message'] as String?;
    }
    setState(() {
      _contacts = contacts;
      _loading = false;
      _lastOkText = okText;
      _pendingAlertText = alertText;
    });
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    final c = _service.newContact(name: name, phone: phone, email: email);
    await _service.addContact(c);
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    await _load();
  }

  Future<void> _removeContact(String id) async {
    await _service.removeContact(id);
    await _load();
  }

  Future<void> _startSync() async {
    await _service.setCheckInInterval(_interval);
    await _service.startCheckIn();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency check-ins enabled')),
    );
  }

  Future<void> _manualOk() async {
    await _service.manualCheckIn();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in sent')),
    );
  }

  Future<void> _showSOSConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Emergency SOS'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Send location to emergency contacts'),
            Text('• Trigger emergency notifications'),
            Text('• Play audible alert'),
            Text('• Vibrate device'),
            SizedBox(height: 16),
            Text(
              'Only use in real emergencies!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _triggerSOS();
    }
  }

  Future<void> _triggerSOS() async {
    final messenger = ScaffoldMessenger.of(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      final permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        final newPermission = await geolocator.Geolocator.requestPermission();
        if (newPermission == geolocator.LocationPermission.denied ||
            newPermission == geolocator.LocationPermission.deniedForever) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Cannot send SOS.'),
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      try {
        final settingsBox = await Hive.openBox('settings');
        final accuracyIndex = settingsBox.get('locationAccuracy',
            defaultValue: LocationAccuracy.medium.index);
        final accuracy = geolocator.LocationAccuracy.values[accuracyIndex];
        final position = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: geolocator.LocationSettings(
            accuracy: accuracy,
          ),
        );
        final supabaseClient = supabase.Supabase.instance.client;
        await supabaseClient.from('sos_logs').insert({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              '🚨 SOS LOGGED!\nLocation: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      try {
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 800);
        }
        await _audioPlayer.play(
          AssetSource('sounds/whistle.mp3'),
          mode: PlayerMode.lowLatency,
        );
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text(
                '⚠️ OFFLINE SOS: Whistle & vibration activated\n(No internet - contacts NOT notified)'),
            duration: Duration(seconds: 6),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Offline SOS failed: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.isEnabled(AppFeature.emergencyContacts)) {
      return const PlatformUnavailableScreen(
        title: 'Emergency Contacts',
        message:
            'Emergency SOS flows use native device capabilities and are available in Android/iOS app builds.',
        icon: Icons.sos,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Emergency SOS button at top - requires confirmation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _showSOSConfirmation,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade600, Colors.red.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sos,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EMERGENCY SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _contacts.isEmpty
                                        ? 'Add contacts below first'
                                        : 'Tap to send alert to ${_contacts.length} contact(s)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_lastOkText != null || _pendingAlertText != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_lastOkText != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_lastOkText!)),
                              ],
                            ),
                          ),
                        if (_pendingAlertText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_pendingAlertText!)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Check-in interval (hours)',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _interval.inHours,
                              items: const [6, 12, 24, 48]
                                  .map((h) => DropdownMenuItem<int>(
                                        value: h,
                                        child: Text('$h hours'),
                                      ))
                                  .toList(),
                              onChanged: (h) {
                                if (h != null) {
                                  setState(
                                      () => _interval = Duration(hours: h));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _startSync,
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _addContact,
                          child: const Text('Add Contact'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, i) {
                      final c = _contacts[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                              '${c.phone}${c.email != null ? ' · ${c.email}' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeContact(c.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _manualOk,
        icon: const Icon(Icons.check_circle),
        label: const Text('I\'m OK'),
      ),
    );
  }
}
