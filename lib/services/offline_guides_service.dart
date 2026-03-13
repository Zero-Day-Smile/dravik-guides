import 'package:hive/hive.dart';

class OfflineGuidesService {
  static final OfflineGuidesService _instance = OfflineGuidesService._();
  factory OfflineGuidesService() => _instance;
  OfflineGuidesService._();

  // Built-in critical guides
  static final Map<String, String> _criticalGuides = {
    'hypothermia': '''🧊 HYPOTHERMIA - Emergency Response

SIGNS:
• Intense shivering → stops → slurred speech
• Confusion, poor judgment, drowsiness
• Weak pulse, slow breathing
• Possible unconsciousness

IMMEDIATE ACTIONS:
1. Move to shelter (avoid wind, moisture)
2. Remove wet clothing carefully
3. Wrap in blankets/sleeping bag
4. Warm (NOT hot) beverages if conscious
5. Monitor breathing & pulse
6. Call emergency if severe (< 30°C core temp)

⚠️ NO RAPID REWARMING - Can cause cardiac arrest
⚠️ DO NOT RUB SKIN - Damages tissue
⚠️ DO NOT GIVE HOT DRINKS - Risk of burns/shock
''',
    'heat_exhaustion': '''🔥 HEAT EXHAUSTION - Emergency Response

SIGNS:
• Heavy sweating, cool/clammy skin
• Weakness, dizziness, nausea
• Rapid heartbeat
• Normal or slightly elevated temp

IMMEDIATE ACTIONS:
1. Move to shade/cool area
2. Drink water (sips, not gulps)
3. Cool skin: wet cloths, pour water
4. Lie down with legs elevated
5. Rest for ≥ 30 minutes
6. Monitor for heat stroke signs

HEAT STROKE WARNING (MEDICAL EMERGENCY):
• High body temp (>40°C)
• Hot, dry skin (no sweating)
• Confusion, seizures, loss of consciousness
→ CALL EMERGENCY IMMEDIATELY
''',
    'severe_bleeding': '''🩸 SEVERE BLEEDING - Emergency Control

SIGNS:
• Blood flowing rapidly or spurting
• Soaking through bandages
• Weakness, dizziness, pale skin

IMMEDIATE ACTIONS:
1. Apply direct pressure with clean cloth
2. Don't remove first cloth - layer new ones
3. Elevate limb above heart (if possible)
4. Apply pressure point if available:
   - Arm: Inside upper arm (brachial artery)
   - Leg: Groin crease (femoral artery)
5. Tourniquet as LAST RESORT:
   - 2-3 inches above wound
   - Write time applied on tourniquet
6. Monitor for shock (pale, weak, confused)

SHOCK RESPONSE:
- Lie down, elevate legs
- Keep warm
- Keep calm, reassure

CALL EMERGENCY - Do not delay
''',
    'fractures': '''🦴 FRACTURE MANAGEMENT

SIGNS:
• Severe pain on movement
• Swelling, bruising
• Deformity, loss of function
• Bone piercing skin (open fracture)

IMMEDIATE CARE (R.I.C.E):
Rest - Immobilize immediately
Ice - Apply if available (max 20 min/hour)
Compression - Wrap snugly (not cutting off circulation)
Elevation - Raise above heart level

IMMOBILIZATION METHODS:
• Arm: Sling or splint with magazine/cardboard
• Leg: Splint with branches, rolled newspaper
• Spine: Keep in place, avoid movement

OPEN FRACTURE (bone visible):
1. Do NOT push bone back in
2. Cover with clean cloth
3. Immobilize immediately
4. Call emergency - infection risk is severe

WHEN TO MOVE CASUALTY:
Only if immediate danger (fire, flood, avalanche)
Use proper techniques to minimize movement
''',
    'water_safety': '''💧 WATER SAFETY & RESCUE

COLD WATER IMMERSION (<15°C):
• Loss of breath control (gasping) - 0-1 min
• Loss of muscle function - 2-3 min
• Loss of consciousness - 5-15 min
• Brain damage / death - 15+ min

IF SOMEONE IS IN COLD WATER:
1. Stay calm, don't panic-swim
2. Float if possible (survival float position)
3. Keep core temp: Hug yourself, draw knees up
4. Signal rescuers continuously

RESCUE TECHNIQUES:
• Reach: Extend hand/pole from shore
• Throw: Life jacket, rope, buoyant object
• Row: Use boat to reach
• Go: Enter water only if trained + backup

AFTER RESCUE (Afterdrop risk):
• Handle gently - avoid jarring
• Remove wet clothes slowly
• Wrap in blankets
• Warm beverages only if fully conscious
• Seek medical attention
''',
    'lightning': '''⚡ LIGHTNING SAFETY

PREVENTION:
• Seek shelter in sturdy building or vehicle
• Avoid: isolated trees, summits, open areas
• Stay low: crouch on heels, feet together
• Avoid: metal objects, bodies of water
• If caught on open ground:
  - Crouch in tight position on heels
  - Minimize contact with ground
  - Move away from group 20 meters apart

LIGHTNING STRIKE INJURIES:
• Burns (entry/exit wounds)
• Cardiac arrest
• Severe muscle damage
• Neurological injury

IF STRUCK:
1. Check responsiveness
2. Call emergency immediately
3. CPR if unconscious + no pulse
4. Monitor breathing
5. Transport to hospital ASAP

IMPORTANT: Lightning victims are not "electrically charged"
- Safe to touch immediately
- Brain/heart damage is concern, not electrocution
''',
    'snake_bite': '''🐍 SNAKE BITE RESPONSE

SIGNS OF ENVENOMATION:
• Fang marks (or just bruising)
• Swelling around bite
• Pain, discoloration
• Nausea, difficulty breathing (severe)

IMMEDIATE CARE:
1. Immobilize limb - splint, sling, or swathe
2. Keep affected limb below heart level
3. Apply firm bandaging (ankle to groin for leg)
   - Not tourniquets, but firm compression
4. Mark swelling edge with pen + time
5. Remove constricting items (rings, bracelets)
6. Rest completely - do NOT move

DO NOT:
✗ Cut or suck the bite
✗ Apply ice directly
✗ Use tourniquets
✗ Give alcohol or drugs
✗ Move victim unnecessarily

GET TO HOSPITAL:
- Carry if possible
- Calmly walk if mobile
- Antivenom available at medical facility
- Even dry bites need observation

PREVENTION:
• Wear boots & long pants in snake areas
• Watch ground, don't put hands in crevices
• Stay on trails
''',
  };

  Future<Box> _guidesBox() async => Hive.openBox('offline_guides');

  Future<void> cacheAllGuides() async {
    final box = await _guidesBox();
    for (final entry in _criticalGuides.entries) {
      await box.put(entry.key, {
        'title': _getGuideTitle(entry.key),
        'content': entry.value,
        'category': _getGuideCategory(entry.key),
        'cachedAt': DateTime.now().toIso8601String(),
        'isEmergency': true,
      });
    }
  }

  Future<List<Map>> getAllGuides() async {
    final box = await _guidesBox();
    return box.values.whereType<Map>().toList().cast<Map>();
  }

  Future<Map?> getGuide(String key) async {
    final box = await _guidesBox();
    return box.get(key) as Map?;
  }

  Future<List<Map>> searchGuides(String query) async {
    final box = await _guidesBox();
    final guides = box.values.whereType<Map>().toList().cast<Map>();
    final q = query.toLowerCase();
    return guides.where((g) {
      final title = (g['title'] ?? '').toString().toLowerCase();
      final content = (g['content'] ?? '').toString().toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  String _getGuideTitle(String key) {
    const titles = {
      'hypothermia': 'Hypothermia Response',
      'heat_exhaustion': 'Heat Exhaustion & Heat Stroke',
      'severe_bleeding': 'Severe Bleeding Control',
      'fractures': 'Fracture Management',
      'water_safety': 'Water Safety & Cold Water Rescue',
      'lightning': 'Lightning Safety',
      'snake_bite': 'Snake Bite Response',
    };
    return titles[key] ?? key;
  }

  String _getGuideCategory(String key) {
    const categories = {
      'hypothermia': 'Environmental',
      'heat_exhaustion': 'Environmental',
      'severe_bleeding': 'Trauma',
      'fractures': 'Trauma',
      'water_safety': 'Water',
      'lightning': 'Environmental',
      'snake_bite': 'Wildlife',
    };
    return categories[key] ?? 'General';
  }

  Future<void> deleteGuide(String key) async {
    final box = await _guidesBox();
    await box.delete(key);
  }
}
