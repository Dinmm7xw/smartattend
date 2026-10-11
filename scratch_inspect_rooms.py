import json, re

with open('aitu_floors_data.js', 'r', encoding='utf-8') as f:
    text = f.read()

m = re.search(r'window\.AITU_FLOORS\s*=\s*(\{.*?\});', text, re.DOTALL)
if m:
    data = json.loads(m.group(1))
    target_numbers = ['228', '229', '230', '240', '241', '262', '263', '222', '237', '247']
    for fl in ['floor1', 'floor2', 'floor3']:
        svg = data.get(fl, '')
        ids = re.findall(r'id=["\']([^"\']+)["\']', svg)
        matches = [i for i in ids if any(num in i for num in target_numbers)]
        if matches:
            print(f'{fl} matches: {matches}')
