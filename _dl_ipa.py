import subprocess, os, re, json, urllib.request, sys

# 优先用环境变量里的有效 token（remote 内嵌的 token 已失效，返回 401）
token = os.environ.get('GH_TOKEN')
if not token:
    out = subprocess.check_output(['git', 'remote', 'get-url', 'origin']).decode().strip()
    m = re.search(r'://([^@]+)@', out)
    token = m.group(1) if m else None
if not token:
    sys.exit('NO TOKEN')
repo = 'Aiden6652/pe-corruption-ios'
art = 9634359301

# 1) get the signed archive download url
api = f'https://api.github.com/repos/{repo}/actions/artifacts/{art}'
req = urllib.request.Request(api, headers={
    'Authorization': f'Bearer {token}',
    'Accept': 'application/vnd.github+json'})
info = json.load(urllib.request.urlopen(req))
dl = info['archive_download_url']
size = info.get('size_in_bytes')
print('archive size (bytes):', size, file=sys.stderr)

dest_dir = os.path.join(os.path.dirname(os.path.abspath('.')), 'CorruptionV50-iPad')
os.makedirs(dest_dir, exist_ok=True)
zip_path = os.path.join(dest_dir, 'iosBuild-release.zip')
print('saving to', zip_path, file=sys.stderr)

req2 = urllib.request.Request(dl, headers={'Authorization': f'Bearer {token}'})
total = 0
with urllib.request.urlopen(req2) as r, open(zip_path, 'wb') as f:
    while True:
        chunk = r.read(1024 * 1024)
        if not chunk:
            break
        f.write(chunk)
        total += len(chunk)
        if total % (50 * 1024 * 1024) < 1024 * 1024:
            print('downloaded', total // (1024 * 1024), 'MB', file=sys.stderr)
print('DONE bytes=%d path=%s' % (total, zip_path))
