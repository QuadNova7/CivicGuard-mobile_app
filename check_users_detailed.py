import os
import json
import urllib.request
from pathlib import Path

env_file = Path(r'E:\semester 4\Projects\compititions\codearena\codes\webapp and backend\CivicGuard\.env')
env = {}
with open(env_file, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip().strip('"').strip("'")

url = env.get('SUPABASE_URL', '')
key = env.get('SUPABASE_SERVICE_ROLE_KEY', '')

headers = {
    'apikey': key,
    'Authorization': f'Bearer {key}',
    'Content-Type': 'application/json'
}

# Check user with id 33333333-3333-3333-3333-333333333333
req = urllib.request.Request(f"{url}/rest/v1/users?id=eq.33333333-3333-3333-3333-333333333333&select=*", headers=headers)
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode('utf-8'))
    print("User with ID 33333333-3333-3333-3333-333333333333:")
    print(" ", res)

# Check all users with Colombo in email or name
req2 = urllib.request.Request(f"{url}/rest/v1/users?name=ilike.*Colombo*&select=id,name,email", headers=headers)
with urllib.request.urlopen(req2) as resp:
    res2 = json.loads(resp.read().decode('utf-8'))
    print("\nUsers with 'Colombo' in name:")
    for u in res2:
        print(" ", u)
