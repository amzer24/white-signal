from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent

def room(id, name, x, y, purpose):
    return dict(id=id, name=name, x=x, y=y, purpose=purpose)

def edge(a,b,need='',kind='route'):
    return dict(a=a,b=b,need=need,kind=kind)

regions = [
dict(id='R0',name='Flats Line',x=100,y=230,goal='Reach the first receiver',verb='Discover',
 lore='Observation came before defence. These dishes were left waiting, not destroyed in battle.',
 art='Low salt plates, buried receiver bowls, empty sky; a trace of ochre ceramic after restoration.',
 mechanic='Hit a memory block, break a marked brick, enter a maintenance conduit and restore a beacon.',
 reward='A map fragment and a visible roof route to remember.', revisit='Dash plus Air Jump opens the maintenance roof from the Wire.',
 assets='Salt floor kit; buried dish landmark; shutter and brick states; quiet wind and first-receiver hum.',
 rooms=[room('F0','Wake basin',0,1,'Safe movement and readable silhouettes.'),room('F1','Survey shelf',1,1,'Jump, then see the unreachable roof.'),room('F2','Packet shelter',2,1,'Hit a block; replay an Operator memory.'),room('F3','Service passage',2,2,'Break marked masonry and enter a conduit.'),room('F4','First receiver',3,1,'Beacon, map fragment and Field destination.'),room('F5','Maintenance roof',1,0,'Later return from the Wire; archive, not a required key.')],
 edges=[edge('F0','F1'),edge('F1','F2'),edge('F2','F4'),edge('F2','F3'),edge('F3','F4'),edge('F1','F5','Dash + Air Jump','optional')]),
dict(id='R1',name='Listening Field',x=300,y=230,goal='Reconnect three different ears',verb='Reconnect',
 lore='One intact dish was isolated deliberately. The fourth ear is a question, not a fourth compulsory switch.',
 art='Dish bowls and survey posts; amber filaments; three distinct window patterns around a shared shaft.',
 mechanic='Manual selector and catch; dish alignment; cleared intake. Find permanent Dash in the Upper Amplifier.',
 reward='Dash, a hub lift, restored workshop windows and the Stand route.',revisit='Air Jump reaches the Fourth Dish archive. The lower service path leads to Drowned before the Field is complete.',
 assets='Three-ear landmark at two distances; workshop kit; selector/catch/lift states; registered memory layer; cable pulses.',
 rooms=[room('L0','Arrival bowl',0,1,'First view of three ears; safe approach.'),room('L1','Triangulation hub',1,1,'Beacon, workshop stair and pump descent; two actionable leads.'),room('L2','West workshop',1,0,'See selector power move a safe demonstration platform.'),room('L3','Ballast gallery',2,0,'Borrowed Current: catch the lift, then redirect power.'),room('L4','Upper amplifier',3,0,'Discover permanent Dash; safe immediate use.'),room('L5','Counterweight return',3,1,'Open the direct hub lift from this side.'),room('L6','East causeway',2,1,'Align the second ear through a visible opening.'),room('L7','Pump cellar',1,2,'Clear the south intake with the established brick interaction.'),room('L8','Drain lookout',2,2,'Early Drowned exit; show the old service street below.'),room('L9','Fourth dish',4,0,'Later Air Jump archive; replayable memory and isolation evidence.'),room('L10','Transmitter sump',3,2,'Three feeder indicators; Stand exit once Field is restored.')],
 edges=[edge('L0','L1'),edge('L1','L2'),edge('L2','L3'),edge('L3','L4','West ear restored'),edge('L4','L5'),edge('L5','L6','Return opened from L5','shortcut'),edge('L6','L1'),edge('L1','L7'),edge('L7','L8'),edge('L8','L10'),edge('L10','L6'),edge('L5','L1','Opened from L5','shortcut'),edge('L4','L9','Air Jump','optional')]),
dict(id='R2',name='The Stand',x=515,y=140,goal='Isolate the unstable storm feed',verb='Shelter',
 lore='Civilian receiver frames became braces and barricades. The surviving wiring records an emergency choice.',
 art='Braced diagonals, broken rim landmark, sheltered dark pockets and slate storm light.',
 mechanic='Store conductor charge, then redirect it into a bridge motor. Charge is held; ambient thunder is not the timer.',
 reward='A latched sheltered bridge and restored feeder.',revisit='Drowned sluice and Approach service return shorten travel. Optional collapse trial has a completed bypass.',
 assets='Brace and shelter kit; conductor/gauge/reservoir/bridge states; distant rim; sheltered and exposed weather stems.',
 rooms=[room('S0','Broken rim',0,1,'See bridge destination and marked discharge channel.'),room('S1','Shelter court',1,1,'Beacon and branch choice; storm cannot hurry reading.'),room('S2','Conductor bay',1,0,'Safe charge demonstration.'),room('S3','Reservoir walk',2,0,'Store and redirect charge into bridge motor.'),room('S4','Latched bridge',2,1,'Restored feeder and Wire exit; bridge remains open.'),room('S5','Sluice shelter',1,2,'Drowned shortcut with visible pipe continuity.'),room('S6','Fracture trial',3,0,'Optional bounded crumble trial; archive reward and reset.')],
 edges=[edge('S0','S1'),edge('S1','S2'),edge('S2','S3'),edge('S3','S4','Bridge latched'),edge('S4','S1','Bridge latched','shortcut'),edge('S1','S5'),edge('S3','S6','','optional')]),
dict(id='R3',name='Drowned Array',x=500,y=350,goal='Recover the old service street',verb='Reveal',
 lore='The reservoirs were diverted to keep distant hardware alive; abandoned survey marks remain below the line.',
 art='Horizontal water marks, drowned masts, depth gauges and green-gray substrate; fixed dry edges stay legible.',
 mechanic='High/middle/low water states and guided floats. Find permanent Air Jump in the exposed survey gallery.',
 reward='Dry main street, Air Jump, freight lift to Array and Stand sluice.',revisit='Cycling side basin remains optional; the main return never requires replaying a full tide cycle.',
 assets='Rim and service-street kit; water surface with stable collision boundary; three pump positions; float rails; submerged mast landmark.',
 rooms=[room('D0','High-water rim',0,0,'Dry observation and marked limits.'),room('D1','Pump house',1,0,'Dry controls at every level; manual bleed works before impeller repair.'),room('D2','Service street',1,1,'Manual bleed reveals the street and missing pump impeller; recover it for the dry pump house.'),room('D3','Survey gallery',2,1,'Air Jump discovery and safe immediate return practice.'),room('D4','Float chamber',2,0,'Raise guided carrier to upper return conduit.'),room('D5','Freight dock',3,1,'Freight lift is enabled by upper-conduit restoration.'),room('D6','Cycling basin',2,2,'Optional timing remix, separate from main water state.')],
 edges=[edge('D0','D1'),edge('D1','D2','Low water'),edge('D2','D3'),edge('D3','D4','Impeller fitted + float raised'),edge('D4','D1','Upper conduit latched','shortcut'),edge('D3','D5','Upper conduit latched'),edge('D2','D6','','optional')]),
dict(id='R4',name='The Wire',x=740,y=80,goal='Repair the cross-district carriage',verb='Connect',
 lore='Hand-numbered clamps and inspection shelters show the labour behind an apparently empty crossing.',
 art='Huge negative space, sagging cables, subdued clouds and pale copper clamps.',
 mechanic='Recallable transport with safe inspection platforms; optional environmental dash-refill chain.',
 reward='A permanent fast carriage between Stand and Array.',revisit='A later roof lead returns to the Flats using Dash and Air Jump.',
 assets='Two non-repeating pylon views; cable tiles; carriage docks and recall controls; low cloud planes; cable tension audio.',
 rooms=[room('W0','West dock',0,1,'Preview far pylon; first footroute uses Dash.'),room('W1','Inspection shelf',1,1,'See the fault clue and recover a compatible spare brake assembly.'),room('W2','Broken carriage',2,1,'Fit the recovered brake assembly and test recall; repair approach works from either arrival without Dash.'),room('W3','East dock',3,1,'Array connection and recall control.'),room('W4','Repeater crown',2,0,'Optional chained dash test; fall returns to shelf.'),room('W5','Old roof line',0,0,'Late route to Flats and an Operator archive.')],
 edges=[edge('W0','W1','Dash'),edge('W1','W2'),edge('W2','W3'),edge('W0','W3','Carriage repaired','shortcut'),edge('W1','W4','Dash','optional'),edge('W0','W5','Dash + Air Jump','optional')]),
dict(id='R5',name='The Array',x=760,y=275,goal='Reconnect the distribution core',verb='Route',
 lore='The building is a working machine: shafts, weights and cable runs explain its height.',
 art='Repeated ceramic ribs, tall counterweight shafts and warm instruments against cold slit windows.',
 mechanic='Select lift destinations and retain a counterweight using the established mechanical catch rule.',
 reward='A persistent vertical spine and the Approach route.',revisit='Freight and Wire entrances meet at a familiar loading floor; recalls work from both.',
 assets='Vertical shaft kit; counterweight pair; selector with shaped destination labels; lift recall poses; instrument hum layers.',
 rooms=[room('A0','Loading floor',0,2,'Freight entrance from Drowned.'),room('A1','Wire landing',0,0,'Alternative arrival from the Wire.'),room('A2','Distribution hall',1,1,'Beacon and visible lift spine.'),room('A3','Counterweight room',2,2,'Remix the retained-state catch without a new verb.'),room('A4','Selector floor',2,0,'Route lift to core while preserving return.'),room('A5','Core gallery',3,1,'Restore Array and open Approach.'),room('A6','Instrument loft',3,0,'Optional archive about severed feeders.')],
 edges=[edge('A0','A2'),edge('A1','A2'),edge('A2','A3'),edge('A3','A4','Catch latched'),edge('A4','A5'),edge('A5','A2','Core restored','shortcut'),edge('A4','A6','','optional')]),
dict(id='R6',name='The Approach',x=965,y=230,goal='Trace the original service line',verb='Understand',
 lore='Many small routes converge beneath the intact source. The service line reveals where the network began.',
 art='Accumulating cables, compressed architecture and restrained light under heavy doors.',
 mechanic='Recombine familiar routing, transport and latches; any pursuit is a clearly entered optional trial.',
 reward='A return to the Stand and an overview of incomplete feeder projects.',revisit='The service elevator makes remaining restoration projects convenient to revisit.',
 assets='Dense cable supports; shared Stand elevator shaft; feeder board with four distinct shapes; optional swarm boundary.',
 rooms=[room('P0','Cable throat',0,1,'Array arrival and view toward the source.'),room('P1','Service junction',1,1,'Beacon and feeder overview.'),room('P2','Old elevator',1,2,'Open return to Stand from this side.'),room('P3','Isolation archive',2,0,'Replay evidence of deliberate disconnection.'),room('P4','Source vestibule',3,1,'Gate access reflects four completed projects.'),room('P5','Swarm bypass',2,2,'Optional bounded chase with permanent completion bypass.')],
 edges=[edge('P0','P1'),edge('P1','P2'),edge('P1','P3'),edge('P3','P4'),edge('P1','P4'),edge('P2','P5','','optional'),edge('P5','P4','','optional')]),
dict(id='R7',name='The Gate',x=1170,y=230,goal='Configure the restored network',verb='Carry',
 lore='The hardware never stopped waiting. Restoration answers what the Spark can carry, not every question about why it was silenced.',
 art='Sparse symmetry and one source aperture; test a pale background with dark figures without changing hazard grammar.',
 mechanic='Final switchboard uses existing source, selector, receiver and latch contracts; no surprise final tool.',
 reward='Persistent restoration and a world still open to exploration.',revisit='Inspect changed views and remaining archives; no forced new run that erases discoveries.',
 assets='Unique source aperture; aligned dormant/active silhouettes; four-feed switchboard; restrained completion transition; revisitable ambience.',
 rooms=[room('G0','Outer collar',0,1,'Safe source reveal and checkpoint.'),room('G1','Feeder ring',1,1,'Read four restored projects through shapes and positions.'),room('G2','Switchboard',2,1,'Apply established routing relationships.'),room('G3','Carrier chamber',3,1,'Final act with stable escape route.'),room('G4','Return gallery',2,0,'Open post-restoration view and return connection.')],
 edges=[edge('G0','G1'),edge('G1','G2'),edge('G2','G3','Switchboard complete'),edge('G3','G4','Source restored'),edge('G4','G1','Source restored','shortcut')])
]

world_edges=[edge('R0','R1'),edge('R1','R2','field'),edge('R1','R3'),edge('R2','R3','drowned','shortcut'),edge('R2','R4','dash'),edge('R3','R5','drowned'),edge('R4','R5'),edge('R5','R6','array'),edge('R6','R7','field,stand,drowned,array'),edge('R6','R2','service','shortcut'),edge('R0','R4','dash,air','optional')]

blocks=[
['B01','Reveal and loop','960 × 270','Base movement','Show a landmark before a branch, then return beneath it.','Persistent shortcut; arrival unmistakable.','Shared landmark and upper/lower room kit.','loop'],
['B02','Elevated promise','480 × 540','Base now; Air Jump later','Show a reachable-looking roof without blocking the main route.','Safe return below; optional archive on revisit.','Roof silhouette, visible landing and archive.','shaft'],
['B03','Visible switch-result','480 × 270','Context action','Put control and moving object together; demonstrate before risk.','Fixed safe floor; reachable reset.','Lever, cable, receiver and platform states.','switch'],
['B04','Counterweight loop','960 × 540','Context action','Hold a weight with a manual catch, then divert supply.','Catch unfolds the permanent service stair; completion retains shortcut.','Paired weight/platform and catch.','weight'],
['B05','Memory archive','480 × 270','Hit from below','Past gesture points to a persistent seam and service handle.','Memory replayable after reward; no hidden lethal route.','Registered past/current layer and memory block.','memory'],
['B06','Power router','960 × 540','Context action','Choose between two visible outputs, then retain one with a latch.','Never close the only exit; reset on stable ground.','Shaped plugs, selector, cable pulses.','router'],
['B07','Sluice pair','960 × 540','Context action','Drain one route; raise a guided float to a second return.','Dry control stair in all states; carrier recall.','Basin marks, pumps, guided float and conduit.','water'],
['B08','Storm capacitor','960 × 270','Context action','Store charge before using it; no flash-frame reaction.','Observation shelter; neutral unfinished reset.','Rod, reservoir gauge, bridge and steady cue.','storm'],
['B09','Dash repeater','480 × 540','Permanent Dash','A visible refill permits a second dash inside one local trial.','Fall to safe shelf; optional reward only.','Distinct refill ring and spent/refilling states.','repeater'],
['B10','Freight shaft','480 × 810','Context action','Recall a platform and see the arrival before riding.','Recall on both ends; safe stop and camera preview.','Shaft, carriage, destinations and controls.','shaft'],
['B11','Return mastery','960 × 270','Dash + Air Jump','Reinterpret an old roof rather than repeat the original floor.','Optional route reconnects; original exit stays open.','Earlier landmark at a new elevation.','loop'],
['B12','Choice and convergence','960 × 540','Base; optional Dash','A technical upper path and a clue-bearing lower path have different rewards.','Both lead to a known junction; neither is an empty duplicate.','Distinct destinations, route landmark and reward props.','choice'],
['B13','Wall-kick shaft','480 × 540','Existing wall slide and kick','Climb a short safe shaft, then add offset rests and an optional upper branch.','Broad catch floor and rest shelves; no hazard in the first lesson.','Consistent grippable wall surface, rests and upper landmark.','shaft'],
['B14','Maintenance ladder','480 × 540','Proposed context climb','Deliberately enter a ladder to inspect a service route; jumping exits it.','Stable top and bottom mounts; never require it until controller tests pass.','Ladder/rung states, mount anchors and climb animation.','ladder'],
['B15','Trip plate and shutter','480 × 270','Base movement','First plate opens a harmless shutter. A later plate previews a timed optional door.','Timer never seals the only exit; reset and visible retreat floor.','Pressed/unpressed plate, connected cable and door travel gauge.','plate'],
['B16','Actuator crossing','960 × 270','Base timing; optional Dash','Watch a piston cycle from a protected recess before crossing its marked sweep.','No blind off-screen activation; checkpoint nearby and safe bay between cycles.','Retracted/warning/moving/held piston states and stable sweep boundary.','piston']
]
blocks=[dict(zip(['id','name','size','need','lesson','escape','assets','drawing'],b)) for b in blocks]

puzzles=[
dict(id='borrowed',name='Borrowed Current',region='Listening Field',insight='Temporary power and a persistent mechanical catch are different states.',reward='West ear, access to Dash and a permanent hub lift.',reset='Unfinished selector returns to lift supply with a safe floor below. The catch unfolds a permanent service stair; the completed catch, stair and route never reset.',states=[['Observe','Selector and both outputs are visible. The lift is down; the ear is dormant.'],['Power lift','Choose the lift output and ride to the upper safety catch.'],['Latch catch','Engage the manual catch. It retains the platform and unfolds the permanent service stair, which was unavailable before this step.'],['Reroute supply','Return by the newly unfolded stair; select the ear receiver. The catch retains the lift.'],['Route open','Ear wakes. Continue to Dash and open the hub return; persist both discoveries.']]),
dict(id='storm',name='Stored Storm',region='The Stand',insight='Charge can be collected and held, then deliberately routed; distant lightning is atmosphere.',reward='Latched bridge and restored Stand feeder.',reset='Unfinished charge returns to neutral on death; bridge completion persists. Safe bay is outside the discharge channel.',states=[['Observe','Inspect the rod, shaped reservoir gauge and bridge motor from shelter.'],['Collect','Select reservoir input. The deterministic machine cue advances the gauge.'],['Hold','Charge stays stored. There is no short reaction window.'],['Discharge','Select bridge motor. Rod animation and stable boundary communicate the event.'],['Bridge latched','Bridge stays open; decorative lightning can be disabled without changing access.']]),
dict(id='water',name='Street Beneath the Static',region='Drowned Array',insight='Removing water reveals a street; raising a guided carrier opens a different return.',reward='Air Jump, dry service street, freight lift and upper conduit.',reset='On death/reload, an unfinished main basin resets LOW and respawns at a fixed dry anchor. Air Jump persists. Dry stairs and controls work in every state. Completion keeps the street drained; the optional basin cycles separately.',states=[['High','Observe submerged service markings from the dry rim.'],['Middle','Lower water to the next mark; the fixed control stair remains usable.'],['Low','Recover the pump impeller in the service street; visit the Air Jump gallery.'],['Fit impeller','Return by the dry stair and fit the impeller. The manual bleed enabled discovery; the repaired pump now powers the float.'],['Float raised','Use the separate guided chamber to reach the upper landing; controls are outside its hazard.'],['Return latched','Open the conduit, drain the main street permanently and enable the freight connection.']])
]

story_beats={
'R0': ['A beacon repair receives an answer from one distant workshop window.', 'Something can still answer. Reach the place behind that window.'],
'R1': ['Two Operators cooperate in a replay; an intact isolation handle was closed deliberately.', 'Some silence was chosen. Finish their repair and remember the disconnected branch.'],
'R2': ['Dish ribs brace a shelter while a conductor bypass protects an intact room.', 'Isolation protected daily life as well as machinery.'],
'R3': ['A diversion pipe crosses domestic doorways; old flood marks survive below broken masonry.', 'Emergency priorities preserved one system at the expense of another place.'],
'R4': ['Mismatched clamps and ordinary tool fittings show repeated shared repairs.', 'The network endured through local work, not only commands from the source.'],
'R5': ['A replayable diagnostic catches one branch fault while a neighbouring lamp remains stable.', 'Connection needs boundaries. The regional repairs enable a better arrangement.'],
'R6': ['The original service line returns to the already restored Stand.', 'The Operators left usable tools; the Spark can now apply them with understanding.'],
'R7': ['Familiar feeder shapes lead to district silhouettes; a common-return isolator contains the test fault.', 'A network of maintained local references can hold. Return to see the workshop repair endure.']
}
for region in regions:
    region['story_clue'],region['story_change']=story_beats[region['id']]

data=dict(regions=regions,world_edges=world_edges,blocks=blocks,puzzles=puzzles,
          flags=dict(dash='Dash found',air='Air Jump found',field='Field restored',stand='Stand restored',drowned='Drowned restored',array='Array restored',service='Approach return opened'))
(ROOT/'maps'/'atlas-data.json').write_text(json.dumps(data,indent=2,ensure_ascii=False),encoding='utf-8')
template=(ROOT/'maps'/'atlas-template.html').read_text(encoding='utf-8')
(ROOT/'maps'/'atlas.html').write_text(template.replace('/*ATLAS_DATA*/',json.dumps(data,ensure_ascii=False).replace('</','<\\/')),encoding='utf-8')
print(f'Atlas built: {len(regions)} districts, {sum(len(r["rooms"]) for r in regions)} rooms, {len(blocks)} blocks, {len(puzzles)} puzzles')
