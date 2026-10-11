import sys
sys.stdout.reconfigure(encoding='utf-8')

content = open('smartattend_flutter/lib/screens/student_dashboard.dart', encoding='utf-8').read()
import re
print("_getFloorRooms count:", len(re.findall(r'_getFloorRooms', content)))
print("_DashboardBlueprintPainter count:", len(re.findall(r'_DashboardBlueprintPainter', content)))
print("_buildFloorChip count:", len(re.findall(r'_buildFloorChip', content)))
print("_mapFloor count:", len(re.findall(r'_mapFloor', content)))
print("_selectedMapRoom count:", len(re.findall(r'_selectedMapRoom', content)))
