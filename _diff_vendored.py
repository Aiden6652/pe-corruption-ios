import os, json, urllib.request, difflib
TOKEN = os.environ['GH_TOKEN']
H = {"Authorization": f"token {TOKEN}", "Accept": "application/vnd.github+json", "User-Agent": "wb"}
def raw(url):
    req = urllib.request.Request(url, headers={"User-Agent":"wb"})
    with urllib.request.urlopen(req) as r: return r.read().decode(errors="replace")
PAIRS = [
    # (local path, upstream repo, upstream ref, upstream path)
    ("source/flixel/system/FlxSound.hx",            "HaxeFlixel/flixel",        "4.11.0", "flixel/system/FlxSound.hx"),
    ("source/flixel/animation/FlxAnimationController.hx", "HaxeFlixel/flixel",    "4.11.0", "flixel/animation/FlxAnimationController.hx"),
    ("source/flixel/addons/display/FlxRuntimeShader.hx",  "HaxeFlixel/flixel-addons", "2.11.0", "flixel/addons/display/FlxRuntimeShader.hx"),
    ("source/flixel/addons/ui/FlxInputText.hx",      "HaxeFlixel/flixel-addons", "2.11.0", "flixel/addons/ui/FlxInputText.hx"),
    ("source/flixel/addons/ui/FlxUIInputText.hx",    "HaxeFlixel/flixel-addons", "2.11.0", "flixel/addons/ui/FlxUIInputText.hx"),
]
for lp, repo, ref, up in PAIRS:
    if not os.path.exists(lp):
        print(f"{lp}: LOCAL MISSING"); continue
    local = open(lp, encoding="utf-8", errors="replace").read().splitlines()
    try:
        remote = raw(f"https://raw.githubusercontent.com/{repo}/{ref}/{up}").splitlines()
    except Exception as e:
        print(f"{lp}: remote err {e}"); continue
    diff = list(difflib.unified_diff(remote, local, lineterm=""))
    print(f"{lp}: local={len(local)}L remote={len(remote)}L diff_hunks={sum(1 for d in diff if d.startswith('@@'))} diff_lines={len(diff)}")
    # show first 3 hunks
    shown = 0
    cur = []
    for d in diff:
        cur.append(d)
        if d.startswith("@@"):
            shown += 1
            if shown > 3: break
            print("   ", d)
        elif shown and shown <= 3 and cur:
            pass
    # print up to 12 changed lines of first hunks
    cnt = 0
    for d in diff:
        if d.startswith("+") and not d.startswith("+++"):
            print("    ADD:", d[:120]); cnt += 1
            if cnt >= 6: break
    cnt = 0
    for d in diff:
        if d.startswith("-") and not d.startswith("---"):
            print("    DEL:", d[:120]); cnt += 1
            if cnt >= 6: break
