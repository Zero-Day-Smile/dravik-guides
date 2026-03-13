import 'dart:async';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:dravik/models/emergency_contact.dart';

class EmergencyContactService {
  static final EmergencyContactService _instance = EmergencyContactService._();
  factory EmergencyContactService() => _instance;
  EmergencyContactService._();

  final _uuid = const Uuid();
  Timer? _checkInTimer;
  Duration _checkInInterval = const Duration(hours: 12);
  DateTime? _lastCheckIn;

  Future<Box> _contactsBox() async => Hive.openBox('emergency_contacts');
  Future<Box> _settingsBox() async => Hive.openBox('emergency_settings');

  Future<List<EmergencyContact>> getContacts() async {
    final box = await _contactsBox();
    return box.values
        .map((v) => EmergencyContact.fromJson(Map<String, dynamic>.from(v)))
        .toList();
  }

  Future<void> addContact(EmergencyContact contact) async {
    final box = await _contactsBox();
    await box.put(contact.id, contact.toJson());
  }

  Future<void> removeContact(String id) async {
    final box = await _contactsBox();
    await box.delete(id);
  }

  Future<void> setCheckInInterval(Duration interval) async {
    _checkInInterval = interval;
    final settings = await _settingsBox();
    await settings.put('check_in_hours', interval.inHours);
    await restartCheckIn();
  }

  Future<void> startCheckIn() async {
    if (_checkInTimer != null) return;
    final settings = await _settingsBox();
    final hours = settings.get('check_in_hours', defaultValue: 12) as int;
    _checkInInterval = Duration(hours: hours);

    _checkInTimer = Timer.periodic(_checkInInterval, (_) async {
      await _evaluateCheckIn();
    });
  }

  Future<void> restartCheckIn() async {
    await stopCheckIn();
    await startCheckIn();
  }

  Future<void> stopCheckIn() async {
    _checkInTimer?.cancel();
    _checkInTimer = null;
  }

  Future<void> manualCheckIn({String? note}) async {
    _lastCheckIn = DateTime.now();
    final settings = await _settingsBox();
    await settings.put('last_check_in', _lastCheckIn!.toIso8601String());
    await _notifyContactsOk(note: note);
  }

  Future<void> _evaluateCheckIn() async {
    final settings = await _settingsBox();
    final last = settings.get('last_check_in');
    final lastTime = last != null ? DateTime.tryParse(last) : null;
    final now = DateTime.now();
    if (lastTime == null || now.difference(lastTime) > _checkInInterval) {
      await _sendAlert();
    }
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendAlert() async {
    final contacts = await getContacts();
    final pos = await _getPosition();
    final message = _buildAlertMessage(pos);
    // Store pending alert
    final box = await _settingsBox();
    await box.put('pending_alert', {
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'contacts': contacts.map((c) => c.toJson()).toList(),
    });

    // Attempt delivery via Twilio/SendGrid if configured
    await _deliverAlerts(message, contacts);
  }

  Future<void> _notifyContactsOk({String? note}) async {
    final contacts = await getContacts();
    final pos = await _getPosition();
    final msg = _buildOkMessage(pos, note: note);
    final box = await _settingsBox();
    await box.put('last_ok', {
      'timestamp': DateTime.now().toIso8601String(),
      'message': msg,
      'contacts': contacts.map((c) => c.toJson()).toList(),
    });

    await _deliverAlerts(msg, contacts);
  }

  Future<void> _deliverAlerts(
      String message, List<EmergencyContact> contacts) async {
    final settings = await _settingsBox();
    final twilioSid = settings.get('twilio_sid');
    final twilioToken = settings.get('twilio_token');
    final twilioFrom = settings.get('twilio_from');
    final sendgridKey = settings.get('sendgrid_key');
    final sendgridFrom = settings.get('sendgrid_from');

    // SMS via Twilio
    if (twilioSid != null && twilioToken != null && twilioFrom != null) {
      for (final c
          in contacts.where((c) => c.receivesSms && c.phone.isNotEmpty)) {
        try {
          final uri = Uri.parse(
              'https://api.twilio.com/2010-04-01/Accounts/$twilioSid/Messages.json');
          await http.post(
            uri,
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('$twilioSid:$twilioToken'))}',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'From': twilioFrom,
              'To': c.phone,
              'Body': message,
            },
          );
          // Best-effort; ignore failures silently
        } catch (_) {}
      }
    }

    // Email via SendGrid
    if (sendgridKey != null && sendgridFrom != null) {
      for (final c in contacts
          .where((c) => c.receivesEmail && (c.email ?? '').isNotEmpty)) {
        try {
          final uri = Uri.parse('https://api.sendgrid.com/v3/mail/send');
          final payload = {
            'personalizations': [
              {
                'to': [
                  {'email': c.email}
                ]
              }
            ],
            'from': {'email': sendgridFrom},
            'subject': 'Dravik Alert',
            'content': [
              {'type': 'text/plain', 'value': message}
            ],
          };
          await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $sendgridKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          );
        } catch (_) {}
      }
    }
  }

  String _buildAlertMessage(Position? p) {
    final base = '⚠️ Emergency: missed check-in.';
    if (p == null) return base;
    return '$base Last known location: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  String _buildOkMessage(Position? p, {String? note}) {
    final base = '✅ Check-in: I am OK';
    final withNote = note != null && note.isNotEmpty ? ' — $note' : '';
    if (p == null) return '$base$withNote';
    return '$base$withNote. Location: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  EmergencyContact newContact(
      {required String name, required String phone, String? email}) {
    return EmergencyContact(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      email: email,
      receivesSms: true,
      receivesEmail: email != null,
    );
  }
}
