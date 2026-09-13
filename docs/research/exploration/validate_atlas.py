from pathlib import Path
import json,itertools,re
root=Path(__file__).resolve().parent
d=json.loads((root/'maps/atlas-data.json').read_text(encoding='utf-8'))
checks=[]
def check(test,label):
    if not test: raise AssertionError(label)
    checks.append(label)
def reach(nodes,edges,start,enabled):
    seen={start}
    while True:
        prev=set(seen)
        for e in edges:
            if e['need'] and not enabled(e['need']):continue
            if e['a'] in seen or e['b'] in seen:seen.update([e['a'],e['b']])
        if seen==prev:return seen
ids={r['id'] for r in d['regions']}
check(len(ids)==8,'Eight unique districts')
for r in d['regions']:
    nodes={n['id'] for n in r['rooms']}
    check(len(nodes)==len(r['rooms']),r['id']+' unique room IDs')
    check(all(e['a'] in nodes and e['b'] in nodes for e in r['edges']),r['id']+' valid edge endpoints')
    check(reach(nodes,r['edges'],r['rooms'][0]['id'],lambda _:True)==nodes,r['id']+' fully connected when requirements met')
check(reach(ids,d['world_edges'],'R0',lambda _:False)=={'R0','R1','R3'},'Opening has Field and Drowned leads')
for values in itertools.product([False,True],repeat=len(d['flags'])):
    flags=dict(zip(d['flags'],values))
    reached=reach(ids,d['world_edges'],'R0',lambda s:all(flags[k] for k in s.split(',')))
    check(('R7' in reached)==all(flags[k] for k in ['field','stand','drowned','array']),'Gate project invariant '+str(values))
r=next(r for r in d['regions'] if r['id']=='R1')
early=reach(None,r['edges'],'L1',lambda _:False)
check('L4' not in early and 'L5' not in early,'No reverse shortcut bypass to Dash')
after=reach(None,r['edges'],'L1',lambda s:s=='West ear restored')
check('L4' in after and 'L5' in after,'Completed west ear opens Dash and far-side return controls')
r=next(r for r in d['regions'] if r['id']=='R3')
check('D5' not in reach(None,r['edges'],'D0',lambda s:s!='Upper conduit latched'),'Freight waits for upper conduit completion')
check('D5' in reach(None,r['edges'],'D0',lambda _:True),'Completed Drowned has freight route')
html=(root/'maps/atlas.html').read_text(encoding='utf-8')
check('/*ATLAS_DATA*/' not in html,'Atlas data embedded for offline viewing')
for rel in ['maps/atlas.html','EXPLORATION-DESIGN.html','notes/effects.html','notes/story-arc.html']:
    p=root/rel
    for target in re.findall(r'href="([^"#]+)(?:#[^"]*)?"',p.read_text(encoding='utf-8')):
        if ':' not in target:
            check((p.parent/target).is_file(),rel+' local link '+target)
print(f'{len(checks)} checks passed: IDs, connectivity, all 128 flag combinations, puzzle gates and local links.')
print('Topology validation only; physical traversal, renderer compatibility and puzzle escape are not playtested.')
