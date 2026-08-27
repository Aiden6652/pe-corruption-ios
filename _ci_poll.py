import subprocess, re, json, time, os, io, zipfile, urllib.request, urllib.error

REPO = "Aiden6652/pe-corruption-ios"
RUN_ID = "33041810216"
API = "https://api.github.com"

# token from git remote
url = subprocess.check_output(["git", "remote", "get-url", "origin"]).decode().strip()
m = re.search(r"://([^@]+)@", url)
TOKEN = m.group(1).split(":", 1)[1] if m else ""
HEADERS = {
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {TOKEN}",
    "X-GitHub-Api-Version": "2022-11-28",
}

def get(path):
    req = urllib.request.Request(API + path, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())

def fetch_logs():
    req = urllib.request.Request(f"{API}/repos/{REPO}/actions/runs/{RUN_ID}/logs", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    z = zipfile.ZipFile(io.BytesIO(data))
    chunks = []
    for n in z.namelist():
        try:
            chunks.append(z.read(n).decode("utf-8", "replace"))
        except Exception:
            pass
    return "\n".join(chunks)

last = None
while True:
    try:
        d = get(f"/repos/{REPO}/actions/runs/{RUN_ID}")
        status, concl = d["status"], d.get("conclusion")
    except Exception as e:
        print(f"[{time.strftime('%H:%M:%S')}] poll error: {e}", flush=True)
        time.sleep(60)
        continue
    if (status, concl) != last:
        print(f"[{time.strftime('%H:%M:%S')}] status={status} conclusion={concl} run={RUN_ID}", flush=True)
        last = (status, concl)
    if status == "completed":
        print(f"=== RUN {RUN_ID} COMPLETED: {concl} ===", flush=True)
        try:
            text = fetch_logs()
            print(f"=== total log chars: {len(text)} ===", flush=True)
            kws = ["disk full", "no space", "error:", "error ", "fatal:", "build failed",
                   "build succeeded", "ipa", "corruption-assets", "rm -f corruption",
                   "could not find", "command not found", "xcodebuild", "codesign",
                   "adhoc", "upload", "artifact", "psychEngine-release.ipa"]
            for kw in kws:
                lines = [l for l in text.splitlines() if kw.lower() in l.lower()]
                if lines:
                    print(f"--- keyword '{kw}' ({len(lines)} hits, last 6) ---", flush=True)
                    for l in lines[-6:]:
                        print("   " + l[:280], flush=True)
            print("=== TAIL (last 50 lines) ===", flush=True)
            for l in text.splitlines()[-50:]:
                print(l[:280], flush=True)
        except Exception as e:
            print(f"log fetch error: {e}", flush=True)
        break
    # also watch the OTHER run on same branch in case it's the relevant one
    time.sleep(90)
