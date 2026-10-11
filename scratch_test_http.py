import urllib.request, json

def test(name, url):
    try:
        r = urllib.request.urlopen(url)
        d = json.loads(r.read().decode())
        print(f"[OK] {name}: HTTP {r.status}, success={d.get('success', True)}")
    except Exception as e:
        print(f"[ERR] {name}: {e}")

test('S-Student', 'http://localhost:8585/api/student/dashboard?email=dinmuhammed@smartattend.kz')
test('S-Kurator', 'http://localhost:8585/api/curator/dashboard?email=curator.arai@smartattend.kz')
test('S-Parent', 'http://localhost:8585/api/parent/dashboard?email=parent.baitomor@smartattend.kz')
test('S-Teacher', 'http://localhost:8585/api/teacher/dashboard?email=kalniyazov@smartattend.kz')
test('S-Dean', 'http://localhost:8585/api/dean/overview')
test('Campus Map Rooms', 'http://localhost:8585/api/rooms/status')
