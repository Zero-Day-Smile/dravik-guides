import 'package:flutter/material.dart';
import 'package:dravik/theme_provider.dart';
import 'package:dravik/screens/place_guide_screen.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class UltimateGuideScreen extends StatefulWidget {
  const UltimateGuideScreen({super.key});

  @override
  State<UltimateGuideScreen> createState() => _UltimateGuideScreenState();
}

class _UltimateGuideScreenState extends State<UltimateGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<GuideCategory> categories = [
    GuideCategory(
      title: 'First Aid & Injuries',
      icon: Icons.medical_services,
      color: Colors.red,
      guides: [
        Guide(
          title: 'Splinter Removal',
          emoji: '🪡',
          content: '''
**How to Remove a Splinter Safely**

1. **Assess the Splinter**
   - Is it deep or shallow?
   - Is it clean or dirty?
   - How long has it been there?

2. **Sterilize Your Tools**
   - Use tweezers, needle, or sterile lancet
   - Clean with rubbing alcohol or antiseptic
   - Wash hands thoroughly

3. **Removal Techniques**

   **For Shallow Splinters:**
   - Soak area in warm water (5-10 min)
   - Use tweezers to grasp and pull at same angle it entered
   - Pull slowly and steadily

   **For Deep Splinters:**
   - Soak in warm water with Epsom salt (15 min)
   - Sterilize needle with flame or alcohol
   - Make small opening in skin over splinter
   - Gently remove with tweezers
   - Apply pressure if bleeding

4. **Aftercare**
   - Wash with soap and water
   - Apply antibiotic ointment
   - Cover with bandage if needed
   - Watch for signs of infection

5. **When to See Doctor**
   - Can't remove it
   - Signs of infection (red, swollen, pus)
   - Deep glass or metal splinter
   - Splinter near eye
        ''',
        ),
        Guide(
          title: 'Shark Bite Response',
          emoji: '🦈',
          content: '''
**Immediate Shark Bite Treatment**

**CRITICAL: Get out of water IMMEDIATELY**

**Step 1: Exit Water**
- Don't thrash or panic - move deliberately
- Alert others without causing hysteria
- Get to shore or boat ASAP

**Step 2: Stop Bleeding (PRIORITY)**
- Apply direct pressure with clean cloth
- Use tourniquet above bite if limb bleeding heavily
   - Tie above wound, tight enough to stop bleeding
   - Note time applied (max 2 hours)
- Elevate wounded limb

**Step 3: Rinse Wound**
- Use fresh water if available
- Flush debris and bacteria
- Don't use vinegar (old myth)

**Step 4: Assess Damage**
- Check for arterial bleeding (spurting blood)
- Check for deep tissue damage
- Count wounds/bites

**Step 5: First Aid**
- Apply sterile gauze or clean cloth
- Maintain pressure for 10-15 minutes
- Apply antibiotic ointment
- Cover with sterile bandage

**Step 6: Immobilize**
- Keep limb still
- Use splint if possible
- Avoid movement which increases bleeding

**EMERGENCY: Call for medical evacuation**
- Most shark bites are survivable
- Professional medical care essential
- Time to hospital = survival

**Prevention at Beach**
- Avoid dawn/dusk swimming
- Don't swim alone
- Avoid murky water
- Don't touch dead fish
- Don't wear shiny jewelry
- Stay in groups
        ''',
        ),
        Guide(
          title: 'Fractures & Broken Bones',
          emoji: '🦴',
          content: '''
**Identifying & Treating Fractures**

**Signs of Fracture**
- Severe pain at injury site
- Deformity or abnormal angle
- Swelling and bruising
- Unable to use limb
- Bone protruding through skin (open fracture)

**Treatment: R.I.C.E.**

**Rest**
- Stop activity immediately
- Don't try to straighten
- Support limb in comfortable position

**Ice**
- Apply for 15-20 minutes
- Every 2-3 hours for first 48 hours
- Reduces swelling and pain

**Compression**
- Wrap with elastic bandage
- Start from toes/fingers
- Wrap upward, not too tight
- Should be snug but not cutting off circulation

**Elevation**
- Raise above heart level
- Reduces swelling
- Use pillow or sling

**Immobilization**
- Use sling for arm/shoulder
- Use crutches for leg
- Avoid putting weight on injury

**Types of Fractures & Response**

**Closed Fracture (skin intact)**
- Follow R.I.C.E. protocol
- Medical evaluation needed

**Open Fracture (bone through skin)**
- EMERGENCY - seek immediate help
- Don't push bone back in
- Apply sterile bandage
- Control bleeding with pressure
- Immobilize and elevate
- Risk of infection is high

**When to Seek Emergency**
- Severe deformity
- Open fracture
- Numbness or tingling
- Severe swelling
- Inability to move
- Trauma to head/spine
        ''',
        ),
        Guide(
          title: 'Severe Burns Treatment',
          emoji: '🔥',
          content: '''
**Burn Severity & Treatment**

**Burn Classification**

**1st Degree (Superficial)**
- Red, painful, no blistering
- Like sunburn
- Heals in 7-10 days

**2nd Degree (Partial Thickness)**
- Blistered, red, swollen
- Very painful
- Heals in 2-3 weeks, may scar

**3rd Degree (Full Thickness)**
- White/charred appearance
- May not be painful (nerve damage)
- Requires medical care
- High infection risk

**Immediate Response**

**STOP THE BURNING**
- Remove from heat source
- Remove burning clothing
- Pat out flames with blanket
- Don't roll if minor burns

**COOL THE BURN**
- Immerse in cool water (not ice)
- 15-20 minutes for pain relief
- After 20 min, continuing cooling ineffective
- Don't use ice directly (causes frostbite)

**REMOVE CONSTRICTING ITEMS**
- Remove rings, bracelets, watches
- Swelling occurs quickly
- May need to cut if swollen

**CLEAN & COVER**
- Wash with soap and water
- Apply antibiotic ointment
- Cover with sterile non-stick bandage
- Don't use cotton (fibers stick)

**PAIN MANAGEMENT**
- Over-the-counter painkillers (ibuprofen)
- Don't give aspirin
- Elevation helps reduce pain

**DO NOT:**
- Apply ice directly
- Use butter, oil, or grease
- Pop blisters
- Use tight bandages
- Breathe on burn

**When to Seek Medical Help**
- 2nd degree burns larger than 3 inches
- Any 3rd degree burn
- Burns on face, hands, genitals
- Any deep/severe burn
- Electrical or chemical burns
        ''',
        ),
      ],
    ),
    GuideCategory(
      title: 'Shelter & Survival',
      icon: Icons.cabin,
      color: Colors.orange,
      guides: [
        Guide(
          title: 'Emergency Tent Setup',
          emoji: '⛺',
          content: '''
**How to Build an Emergency Tent/Shelter**

**Without Tent (Emergency Shelter)**

**1. Debris Hut (Quick & Effective)**
- Find fallen logs or fallen tree
- Lean branches against log to form A-frame
- Cover with leaves, pine needles, bark
- Insulate floor with dried leaves (prevents ground cold)
- Leave small opening for entrance
- Build up sides for wind protection
- Time: 30-60 minutes

**2. Lean-To Shelter**
- Find tree or sturdy branch
- Lean branches at 45-degree angle
- Cover with bark, leaves, pine branches
- Build facing away from wind
- Ensure good drainage (not in water runoff)

**3. Snow Cave (In Snow)**
- Find snow bank
- Dig horizontal into bank
- Create small entrance
- Make sleeping platform higher (warmth rises)
- Smooth ceiling to prevent dripping
- Poke air hole in roof
- Insulate floor with pine branches

**Basic Tent Setup (If You Have One)**

**Ground Preparation**
- Remove sharp rocks, sticks
- Level the ground
- Check for water drainage (avoid low spots)

**Orientation**
- Face entrance away from prevailing wind
- Use sun position for morning warmth
- In rain, face away from storm direction

**Setup Steps**
1. Lay out tent footprint
2. Stake corner closest to you first
3. Stake opposite corner
4. Stake remaining corners
5. Tighten guy lines equally
6. Check for wrinkles in fabric
7. Ensure doors and windows seal properly

**Guy Line Tension**
- Not too tight (can tear fabric)
- Not too loose (reduces waterproofing)
- Should feel snug, not stressed

**Ventilation**
- Crack windows/doors in rain (prevents condensation)
- Fully open in fair weather
- Prevents moisture buildup inside

**Organization Inside**
- Keep gear in waterproof bags
- Don't store wet items
- Keep floor clear
- Place valuables away from tent opening

**Takedown**
- Remove stakes carefully
- Shake out debris
- Roll instead of fold (less wear)
- Store in dry place
        ''',
        ),
        Guide(
          title: 'Water from Sea Water',
          emoji: '💧',
          content: '''
**Desalination: Getting Fresh Water from Sea Water**

**Why Sea Water is Dangerous**
- Salt content causes dehydration
- Drinking increases thirst
- Can lead to death

**Method 1: Solar Still (Slowest but Effective)**

**Materials Needed**
- Plastic sheet or clear plastic bag
- Container
- Sea water
- Stones or weights

**Process**
1. Place container on ground
2. Pour sea water around container (not in it)
3. Place plastic sheet over, tented over container
4. Weight plastic at edges and center
5. Place stone in center above container
6. Sun's heat evaporates water
7. Condensation drips into container
8. Yields: ~1 liter per day per square meter

**Method 2: Boiling & Condensation**

**Materials**
- Pot for boiling
- Collection vessel
- Cloth or plastic wrap
- Cool surface (rock, metal)

**Process**
1. Boil sea water in pot
2. Stretch cloth over pot
3. Place ice or cold rock on cloth center
4. Steam condenses on cloth
5. Drips into collection vessel
6. Repeat as needed

**Method 3: Improvised Distiller**

**Setup**
1. Dig hole in sand near shore
2. Place container in hole
3. Surround with sea water (in sand)
4. Cover with plastic sheet, sloped
5. Secure edges with sand/rocks
6. Place small rock in center
7. Sun heats, evaporates, condenses

**Method 4: Fire & Cloth (Emergency)**

**Materials**
- Clean cloth
- Bucket of sea water
- Heat source
- Collection vessel

**Process**
1. Soak cloth in sea water
2. Hold near flame (not in flames)
3. Cloth dries, salt stays behind
4. Water vapor condenses
5. Wring out into container
6. Very slow method but works

**Prevention Is Best**
- Ration fresh water carefully
- Collect rainwater
- Find natural springs if possible
- 1 liter per day minimum to survive
- 2-3 liters per day for comfort

**Other Water Sources**
- Fish contain fresh water in eyes/spinal fluid
- Coconut milk is drinkable
- Cacti store fresh water (some varieties)
- Morning dew on leaves
- Rainwater (first run-off may have salt)
        ''',
        ),
        Guide(
          title: 'Fire Making Without Matches',
          emoji: '🔥',
          content: '''
**Primitive Fire Making Techniques**

**Method 1: Friction (Slow Fire Bow)**

**Materials**
- Dry softwood for spindle
- Dry wood for fireboard
- Curved stick for bow
- Cord or vine for bow string
- Cloth for tinder
- Dry grass/leaves

**Process**
1. Cut notch in fireboard
2. Place spindle in notch
3. Use bow with downward pressure
4. Move bow back and forth rapidly
5. Friction creates heat
6. Dark powder forms in notch
7. Transfer to tinder bundle
8. Blow gently to ignite
9. Add small twigs, then larger wood

**Time: 15-45 minutes**

**Method 2: Flint & Steel**

**Materials**
- Flint or similar hard stone
- Steel striker (or metal)
- Dry tinder (cotton, bark, grass)

**Process**
1. Hold tinder material
2. Strike flint with steel at angle
3. Sparks fall onto tinder
4. Blow gently to catch flame
5. Transfer to kindling

**Method 3: Solar Fire (Magnifying Glass/Ice)**

**Materials**
- Magnifying glass, ice, or water drop
- Tinder material
- Sunlight

**Process**
1. Focus sunlight through lens onto tinder
2. Hold steady until smoking
3. Blow to flame
4. Don't move lens once smoke starts
5. Be patient - takes few minutes

**Method 4: Battery & Steel Wool**

**Materials**
- Battery (any size)
- Steel wool
- Tinder

**Process**
1. Touch steel wool to both battery terminals
2. Steel wool catches fire instantly
3. Transfer to tinder/kindling
4. Fastest method if materials available

**Tinder Materials**
- Dry bark (inner portion)
- Dry grass
- Cotton fibers
- Cattail fluff
- Pine resin
- Birch bark
- Thistle down
- Animal fur

**Kindling**
- Small dry twigs (pencil-thin)
- Split wood
- Dry pine needles
- Dead moss
- Small branches

**Firewood**
- Arm-thick branches
- Dead standing trees
- Split wood (burns better than round)
- Hardwood for longer burn

**Fire Lay Principles**
1. Start with tinder
2. Add kindling in pyramid
3. Allow air flow
4. Gradually add larger pieces
5. Keep fire contained
        ''',
        ),
      ],
    ),
    GuideCategory(
      title: 'Water & Hydration',
      icon: Icons.water_drop,
      color: Colors.blue,
      guides: [
        Guide(
          title: 'Finding Clean Water',
          emoji: '🚰',
          content: '''
**Locating Water in Wilderness**

**Natural Water Sources**

**Best Sources (Usually Safe)**
- Fresh flowing streams
- Mountain springs
- Rainwater (recent)
- Morning dew on plants
- Clear lake water
- Melted snow/ice

**Questionable Sources**
- Stagnant water
- Water near animal remains
- Discolored water
- Water with algae bloom
- Marshes and swamps
- Puddles

**Indicators of Clean Water**
- Clear appearance
- No odor
- Fast-flowing
- Away from settlements/animals
- High elevation sources

**How to Find Water**

**Follow Paths**
- Animal tracks lead to water
- Look for converging paths
- Watch birds at dawn/dusk

**Look for Vegetation**
- Green plants need water
- Follow dry streambeds downhill
- Valley bottoms often have water

**Listen for Sound**
- Flowing water makes noise
- Birds gather near water
- Insects indicate moisture

**Dig in Dry Streambeds**
- Water often under sand
- Dig hole in lowest area
- Let water seep in
- May take hours

**Collect Dew**
- Use cloth to collect morning dew
- Wring into container
- Very slow but safe
- ~1 liter per hour with good conditions

**Water Purification Methods**

**Boiling (Most Reliable)**
- Boil for 1-3 minutes
- Kills bacteria, viruses, parasites
- Doesn't remove chemical pollution
- Uses fuel

**Filtering**
- Sand and charcoal layers
- Removes particles only
- Doesn't kill microorganisms
- Build layered filter

**Chemical Treatment**
- Iodine tablets (kills microbes)
- Chlorine dioxide
- Follow package instructions
- Won't remove particles

**UV Light**
- Requires UV flashlight
- Kills microorganisms
- Only works on clear water

**Combination Approach**
1. Filter with cloth (remove debris)
2. Boil or treat chemically
3. Filter again through charcoal
4. Most reliable method

**Signs of Contaminated Water**
- Cloudiness
- Discoloration
- Unpleasant odor
- Foam or bubbles
- Dead fish/animals
- Mineral deposits
        ''',
        ),
        Guide(
          title: 'Dehydration & Heat Exhaustion',
          emoji: '☀️',
          content: '''
**Recognizing & Treating Dehydration**

**Dehydration Stages**

**Mild (2-5% body fluid loss)**
- Thirst
- Slightly dry mouth
- Normal skin turgor

**Moderate (5-10% body fluid loss)**
- Increased thirst
- Dry mouth and lips
- Dark urine
- Sluggishness
- Nausea
- Dizziness

**Severe (10-15% body fluid loss)**
- Extreme thirst
- Confusion
- Difficulty concentrating
- Labored breathing
- Unconsciousness possible

**Treatment**

**Mild Dehydration**
- Drink water slowly
- Electrolyte beverage better than water alone
- Rest in shade
- Continue monitoring

**Moderate Dehydration**
- Drink water regularly (small sips)
- Use electrolyte solution if available
- Rest completely
- Don't continue activity
- Monitor for worsening

**Severe Dehydration**
- MEDICAL EMERGENCY
- Keep person lying down
- Elevate legs
- Try small sips of water (if conscious)
- Cool body with water
- Seek emergency help

**Heat Exhaustion vs Heat Stroke**

**Heat Exhaustion**
- Heavy sweating
- Weakness
- Dizziness
- Nausea
- Normal to high temp
- TREATMENT: Cool body, drink water

**Heat Stroke (EMERGENCY)**
- Little or no sweating
- Confusion
- Hot to touch
- Possible unconsciousness
- TREATMENT: Cool aggressively, seek help immediately

**Prevention**

**Hydration**
- Drink 2-3 liters daily in normal conditions
- More in heat/exertion
- Drink before thirsty
- Electrolytes help retention

**Clothing**
- Light-colored, loose-fitting
- Hat or head covering
- Protect skin from sun

**Activity**
- Avoid peak heat hours (11am-3pm)
- Take frequent breaks
- Slow pace
- Watch for signs in companions

**Acclimatization**
- Takes 7-14 days in heat
- Gradually increase activity
- Allow body to adjust
        ''',
        ),
      ],
    ),
    GuideCategory(
      title: 'Wildlife & Animals',
      icon: Icons.pets,
      color: Colors.brown,
      guides: [
        Guide(
          title: 'Snake Bite Treatment',
          emoji: '🐍',
          content: '''
**Snake Identification & Bite Treatment**

**Identifying Venomous Snakes**

**Venomous Features**
- Triangular head
- Vertical slit pupils
- Pit organs (heat sensing)
- Thick body relative to head
- Rattle (rattlesnakes)

**Non-Venomous Features**
- Round head
- Round pupils
- No pits
- Thin head/body transition

**Immediate Response**

**STAY CALM**
- Panic increases heart rate
- Worsens venom spread
- Fear clouds judgment

**IMMOBILIZE LIMB**
- Don't move bitten area
- Use sling or splint
- Keep limb at heart level
- Elevate slightly if possible

**REMOVE CONSTRICTING ITEMS**
- Remove rings, bracelets, watches
- Swelling may trap circulation
- Remove before swelling starts

**WASH BITE**
- Use soap and water
- Gently remove any fangs
- Don't squeeze venom out (doesn't work)

**DO NOT:**
- Cut the bite (no benefit)
- Apply tourniquets (causes tissue damage)
- Apply ice directly (causes frostbite)
- Suck out venom (ineffective)
- Apply electric shock (dangerous)
- Give alcohol

**MEDICAL TREATMENT**
- Antivenom is only effective treatment
- Get to hospital immediately
- Mark bite location
- Remove constrictive clothing
- Take pain medication

**Transport to Hospital**
- Walk slowly (exercise speeds venom)
- Carry if possible
- If alone, call for help/crawl out slowly
- Tie cloth marker to show swelling progression

**Prevention**

**Wear Protection**
- High boots
- Long pants
- Gaiters

**Watch Where You Step**
- Check before sitting
- Don't put hands in unseen places
- Use stick to move vegetation
- Stay on paths

**Snake Behavior**
- Most snakes avoid humans
- Strike as last resort
- Give them escape route
- Back away slowly

**What to Report to Doctor**
- Exact time of bite
- Snake description (if known)
- Symptoms progression
- Any allergies
- Medications being taken
        ''',
        ),
        Guide(
          title: 'Bear Encounter Protocol',
          emoji: '🐻',
          content: '''
**What To Do If You Encounter a Bear**

**Prevention (Most Important)**

**Make Noise**
- Talk/sing while hiking
- Bears prefer to avoid
- Use bear bells
- Clap hands in brush

**Store Food Properly**
- Hang 12 feet high, 6 feet from tree
- Use bear canister
- Never store in tent
- Clean up all food debris

**Know Your Route**
- Avoid known bear territory
- Travel in groups
- Ask locals about recent activity
- Avoid dawn/dusk

**If You Encounter a Bear**

**Black Bear**
1. Don't run (triggers chase instinct)
2. Make yourself look big
3. Back away slowly
4. Speak calmly and firmly
5. Climb tree if available
6. If charged, use bear spray

**Grizzly Bear**
1. Don't run
2. Speak in calm, low voice
3. Back away slowly
4. If charged, use bear spray
5. Fall to ground in fetal position as last resort
6. Don't climb trees (grizzlies can climb)

**Polar Bear**
1. EXTREME DANGER - Predator
2. Use all available deterrents
3. Make maximum noise
4. Use bear spray
5. If can't escape, prepare to fight

**Bear Spray**
- Use when bear is 30-40 feet away
- Aim down and across bear's face
- Spray in sweeping motion
- Back away after spraying

**What NOT To Do**
- Don't run
- Don't climb (black bears climb)
- Don't make eye contact
- Don't feed bear (never)
- Don't separate cubs from mother
- Don't corner bear

**If Attacked**
- Don't play dead (wrong for black bears)
- Black bear: Fight back, make noise
- Grizzly bear: Play dead in fetal position
- Protect head and neck
- Use anything as weapon

**Post-Attack**
- Get to hospital immediately
- Take photos of injuries
- Report to authorities
- Request bear tracking data

**Bear Bells & Noise**
- Worn on belt/pack
- Make constant noise
- Alerts bears to your presence
- Most effective deterrent
        ''',
        ),
      ],
    ),
    GuideCategory(
      title: 'Extreme Scenarios',
      icon: Icons.warning,
      color: Colors.deepPurple,
      guides: [
        Guide(
          title: 'Alien Attack Response',
          emoji: '👽',
          content: '''
**Extraterrestrial Encounter Protocol**

**If You Experience Alien Contact**

**FIRST: Verify Reality**
- Pinch yourself
- Are you dreaming?
- Check for carbon monoxide poisoning
- Look for rational explanations

**SECOND: Document Everything**
- Take photos/video if possible
- Note exact time and location
- Describe craft/entity appearance
- Record details while fresh

**THIRD: Secure Yourself**
- Move to safe location
- Lock doors/windows
- Hide if necessary
- Keep communication device handy

**FOURTH: Contact Authorities**
- Call police (if being threatened)
- Contact local UFO research group
- Report to MUFON (Mutual UFO Network)
- NASA Planetary Protection Office

**IF ABDUCTED:**

**Stay Calm**
- Panic won't help
- Observe surroundings carefully
- Remember details

**Protect Yourself**
- Don't resist violently (unknown strength)
- Comply with commands
- Look for escape opportunity

**Medical Examination**
- Aliens may conduct examination
- Document any marks/implants
- See doctor immediately after

**Communication**
- Try universal gestures
- Slow, deliberate movements
- Avoid sudden actions

**IF IN CRAFT:**

**Observe Layout**
- Exits and entrances
- Propulsion method
- Crew behavior patterns
- Weapons capability

**Resources**
- Look for water source
- Check for emergency exits
- Identify dangerous areas
- Note material composition

**Escape Strategy**
- Plan escape route
- Wait for opportunity
- Use distraction if possible
- Don't attempt risky escape

**AFTER CONTACT:**

**Medical Evaluation**
- Full physical exam
- Blood tests
- Neurological exam
- Mental health evaluation

**Psychological Support**
- Talk to therapist
- Contact support groups
- Avoid isolation
- Share experience

**Scientific Documentation**
- Detailed timeline
- Physical evidence
- Witness testimony
- Official reports

**Known Encounters**
- Keep investigation ongoing
- Monitor for effects
- Report complications
- Stay engaged with research

**IMPORTANT REMINDER:**
*If you believe you've had contact with extraterrestrials, seek professional medical and psychological evaluation first. Many symptoms can be explained by terrestrial causes.*

**Resources**
- MUFON.com (UFO research)
- NUFORC (National UFO Reporting Center)
- Project Blue Book (historical data)
- Local astronomical societies
        ''',
        ),
        Guide(
          title: 'Zombie Apocalypse Survival',
          emoji: '🧟',
          content: '''
**Survival Guide: Undead Outbreak**

**PHASE 1: INITIAL OUTBREAK**

**Shelter Immediately**
- Find secure location
- Reinforce doors/windows
- Multiple exits planned
- High ground preferred
- Natural defenses (barriers)

**Secure Resources**
- Water: 1 gallon per person per day
- Food: Non-perishable goods
- Medical supplies: First aid essential
- Weapons: Blunt objects best (silent)
- Tools: Crowbar, flashlight, rope

**Create Safe Zone**
- Perimeter fence/barriers
- Interior supplies stockpile
- Multiple exits
- Water source
- Communication equipment

**PHASE 2: ORGANIZED RESPONSE**

**Group Structure**
- Elect leader
- Assign roles: Security, medical, food, supplies
- Establish communication system
- Create watch schedule (24-hour coverage)

**Defensive Strategy**
- Eliminate walkers inside perimeter
- Secure all entry points
- Create kill zones
- Establish retreat routes
- Stock ammunition/weapons

**Supply Management**
- Inventory all resources
- Ration food and water
- Rotate supplies (oldest first)
- Hunt/farm if possible
- Trade with other groups

**PHASE 3: LONG-TERM SURVIVAL**

**Community Building**
- Establish trade routes
- Share intelligence
- Pool resources
- Defend together
- Maintain morale

**Scavenging**
- Plan routes carefully
- Never go alone
- Secure area before entering
- Use distractions
- Exit before dark

**Agriculture/Hunting**
- Establish gardens
- Hunt local wildlife
- Fish if water available
- Preserve meat (smoking, salting)
- Store seeds

**Zombie Characteristics**
- Slow moving (usually)
- Poor hearing (but attracted to noise)
- Follow heat signatures
- Avoid water deeper than head
- Attracted to crowds

**Weapons & Defense**

**Effective Weapons**
- Crowbar: Silent, reusable
- Machete: Quick, effective
- Baseball bat: Heavy, impact
- Crossbow: Silent, long range
- Handguns: Last resort

**Ineffective Weapons**
- Guns (loud, attracts others)
- Swords (get stuck)
- Explosives (uncontrollable)
- Fire (burns out of control)

**Escape Tactics**
- Stealth: Move quietly, avoid contact
- Speed: Run if discovered
- Distractions: Noise elsewhere
- Fire: As last resort only
- Water crossing: Zombies struggle

**Psychological Survival**
- Maintain hope
- Keep busy
- Support each other
- Record history
- Plan for future

**Common Mistakes to Avoid**
- Trusting strangers
- Traveling at night
- Making unnecessary noise
- Wasting ammunition
- Poor hygiene
- Losing discipline
        ''',
        ),
      ],
    ),
    GuideCategory(
      title: 'Navigation & Orientation',
      icon: Icons.compass_calibration,
      color: Colors.green,
      guides: [
        Guide(
          title: 'Navigate Without Compass',
          emoji: '🧭',
          content: '''
**Finding Your Way Without Navigation Tools**

**Using The Sun**

**Day Navigation**
- Sun rises in EAST
- Sun sets in WEST
- Sun is in SOUTH at noon (Northern Hemisphere)
- Sun is in NORTH at noon (Southern Hemisphere)

**Shadow Stick Method**
1. Place stick in ground vertically
2. Mark shadow tip with stone
3. Wait 15 minutes
4. Mark new shadow tip
5. Line between marks = East-West
6. First mark is WEST, second is EAST

**Using Stars**

**Northern Hemisphere**
- Find North Star (Polaris)
- Located 40 degrees above north horizon
- Part of Little Bear constellation
- True north indicator

**Finding North Star**
1. Find Big Dipper (Ursa Major)
2. Locate two stars forming cup edge farthest from handle
3. Draw line 5 times the distance between stars
4. This is North Star

**Southern Hemisphere**
- Find Southern Cross (Crux)
- Four bright stars forming cross
- Locate dark nebula (Coalsack)
- Draw line from cross through space
- Length equals distance to south horizon
- South pole is below horizon

**Using Moon**
- First quarter: Moon south at 6pm
- Full moon: Moon south at midnight
- Last quarter: Moon south at 6am
- Terminator (light/dark line) points south

**Natural Indicators**

**Vegetation**
- Moss grows on north side of trees (usually)
- Trees denser/greener on south side
- Snow lasts longer on north-facing slopes
- Branches fuller on sunny (south) side

**Animal Behavior**
- Ants build nests on south side of trees
- Spider webs often on south side
- Birds roost on protected (north) side
- Animals travel to water at dusk (usually east or downhill)

**Water Flow**
- All water flows downhill
- Follow downhill to major streams
- Streams lead to civilization eventually
- Waterfalls indicate steep terrain

**Following Landmarks**
- Mark positions: North, South, East, West
- Follow consistent direction
- Keep track of time/distance
- Mark trail as you go
- Return same route if needed

**Creating A Map**
- Draw as you travel
- Mark water sources
- Note landmarks (peaks, trees)
- Use relative positions
- Include dangerous areas

**Staying Found**
- Pick distinct destination
- Check progress regularly
- Don't rely on single landmark
- Cross-check directions
- Mark trail frequently

**What To Do If Lost**
1. STOP immediately
2. Calm yourself
3. Retrace steps if possible
4. Stay in location
5. Make yourself visible
6. Ration water/food
7. Signal for help
        ''',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Guide> get _filteredGuides {
    return categories
        .expand((cat) => cat.guides)
        .where((guide) =>
            guide.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            guide.content.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor:
                      isDark ? Colors.grey[850] : Colors.deepPurple[700],
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Ultimate Guide',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Colors.grey[850]!, Colors.grey[900]!]
                              : [
                                  Colors.deepPurple[600]!,
                                  Colors.deepPurple[900]!
                                ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Icon(Icons.travel_explore,
                                size: 200,
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Complete Travel Survival',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${_filteredGuides.length} Topics',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.place),
                      tooltip: 'Place Guide',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PlaceGuideScreen()),
                      ),
                    ),
                  ],
                ),
              ];
            },
            body: Column(
              children: [
                const EditionBannerForScreen(
                  screen: EditionScreen.ultimateGuide,
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search (e.g., "shark", "tent")',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Guides
                Expanded(
                  child: _searchQuery.isEmpty
                      ? _buildTabView(isDark)
                      : _buildSearchResults(isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabView(bool isDark) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          indicatorColor: Colors.deepPurple,
          tabs: categories
              .map((cat) => Tab(
                    icon: Icon(cat.icon, size: 20),
                    text: cat.title,
                  ))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: categories
                .map((cat) => _buildCategoryContent(cat, isDark))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent(GuideCategory cat, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cat.guides.length,
      itemBuilder: (context, index) {
        final guide = cat.guides[index];
        return GestureDetector(
          onTap: () => _showGuideDetail(guide, isDark),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cat.color.withOpacity(0.7), cat.color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(guide.emoji,
                          style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(guide.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Tap to read full guide',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.6), size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredGuides.length,
      itemBuilder: (context, index) {
        final guide = _filteredGuides[index];
        final cat = categories.firstWhere((c) => c.guides.contains(guide));
        return GestureDetector(
          onTap: () => _showGuideDetail(guide, isDark),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(guide.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guide.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(cat.title,
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: isDark ? Colors.white54 : Colors.black38,
                      size: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGuideDetail(Guide guide, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(guide.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(guide.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(guide.content,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<Guide> guides;

  GuideCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.guides,
  });
}

class Guide {
  final String title;
  final String emoji;
  final String content;

  Guide({
    required this.title,
    required this.emoji,
    required this.content,
  });
}
