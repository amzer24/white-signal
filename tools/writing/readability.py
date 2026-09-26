"""Readability and fit checks for WHITE SIGNAL's player-facing text.

Measures Flesch-Kincaid grade, average sentence length and syllables per word
for (a) villager lines in levels/story/npcs.json, (b) the intro cards in
scripts/intro/intro_scene.gd, (c) level hints in levels/world*/*.txt.
Also checks that every villager line wraps to 3 rows or fewer at 40 characters
(the game's own greedy word wrap, asterisks removed) and uses only characters
the pixel font can draw.

    python readability.py <game root> [label]
    python readability.py --before <snapshot dir>   (npcs.json, intro_scene.gd, hints.txt)
"""
import glob
import json
import os
import re
import sys

ALLOWED = set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.:/-+=?![](),'><^~%_*#@|\\ ")

# Syllable counts the rule of thumb below gets wrong, checked by hand.
OVERRIDES = {
    "radio": 3, "radios": 3, "area": 3, "idea": 3, "being": 2, "every": 2, "everything": 3,
    "everyone": 3, "everywhere": 3, "notebook": 2, "careful": 2, "carefully": 3, "trying": 2,
    "afterwards": 3, "howling": 2, "hilltop": 2, "joining": 2, "sleeping": 2, "until": 2, "random": 2, "nicknamed": 2, "sparks'": 1, "asleep": 2, "exactly": 3, "workers": 2, "connected": 3, "everybody": 4, "glowing": 2, "watched": 1, "genuine": 3, "favourite": 3, "mysterious": 4, "crumbling": 2, "studying": 3, "repeating": 3, "operated": 4, "operating": 4, "permission": 3, "moments": 2, "arrives": 2, "peaceful": 2, "peacefully": 3, "absolutely": 4, "energy": 3, "noticed": 2, "corridor": 3, "entire": 2, "message": 2, "possibly": 3, "perfectly": 3, "callers": 2, "language": 2, "village": 2, "visited": 3, "visit": 2, "travelled": 2, "traveled": 2, "certain": 2, "written": 2, "treasure": 2, "sideways": 2, "lifetime": 2, "homemade": 2, "someday": 2, "evening": 2, "quiet": 2, "quietly": 3, "quieter": 3,
    "science": 2, "diamond": 2, "lion": 2, "fire": 1, "hour": 1, "hours": 1, "our": 1,
    "flyer": 2, "flyers": 2, "higher": 2, "tower": 2, "towers": 2, "power": 2, "flower": 2,
    "listener": 3, "listeners": 3, "listened": 2, "listening": 3, "listen": 2,
    "people": 2, "little": 2, "handle": 2, "able": 2, "table": 2, "trouble": 2, "middle": 2,
    "single": 2, "simple": 2, "whistle": 2, "rubble": 2, "bubble": 2, "puzzle": 2,
    "whole": 1, "while": 1, "alone": 2, "someone": 2, "somewhere": 2, "something": 2,
    "sometimes": 2, "anyone": 3, "anything": 3, "anywhere": 3, "nobody": 3, "maybe": 2,
    "because": 2, "before": 2, "above": 2, "across": 2, "away": 2, "again": 2, "against": 2,
    "once": 1, "twice": 1, "done": 1, "gone": 1, "come": 1, "comes": 1, "some": 1,
    "one": 1, "ones": 1, "none": 1, "gave": 1, "give": 1, "gives": 1, "live": 1, "lives": 1,
    "have": 1, "move": 1, "moves": 1, "above": 2, "love": 1, "sure": 1, "shore": 1,
    "i'm": 1, "i've": 1, "i'll": 1, "i'd": 1, "you're": 1, "you've": 1, "you'll": 1,
    "we're": 1, "we've": 1, "they're": 1, "they've": 1, "there's": 1, "that's": 1,
    "it's": 1, "what's": 1, "who's": 1, "he's": 1, "she's": 1, "let's": 1, "here's": 1,
    "didn't": 2, "isn't": 2, "wasn't": 2, "doesn't": 2, "hasn't": 2, "haven't": 2,
    "couldn't": 2, "wouldn't": 2, "shouldn't": 3, "weren't": 1, "aren't": 1, "can't": 1,
    "don't": 1, "won't": 1, "what'll": 2, "where's": 1, "how's": 1, "relay's": 2,
    "tally's": 2, "mast's": 1, "spire's": 1, "haggle": 2,
    "relay": 2, "relays": 2, "station": 2, "stations": 2, "signal": 2, "channel": 2,
    "channels": 2, "shaking": 2, "machine": 2, "protecting": 3, "protect": 2,
    "switchyard": 2, "switchboard": 2, "aerials": 3, "aerial": 3, "spire": 1,
    "wire": 1, "wires": 1, "tired": 1, "fuses": 2, "fuse": 1, "used": 1, "use": 1,
    "useful": 2, "cure": 1, "create": 2, "created": 3, "real": 1, "really": 2,
    "piano": 3, "video": 3, "ringing": 2, "rings": 1, "going": 2, "doing": 2, "seeing": 2,
    "the": 1, "sp": 1, "hello": 2, "okay": 2, "ok": 2, "oh": 1, "via": 2,
    "flares": 1, "stares": 1, "spares": 1, "shares": 1, "cares": 1, "ages": 2,
    "voices": 2, "places": 2, "spaces": 2, "pieces": 2, "noises": 2, "changes": 2,
    "edges": 2, "bridges": 2, "reaches": 2, "switches": 2, "watches": 2, "catches": 2,
    "wanted": 2, "waited": 2, "started": 2, "needed": 2, "ended": 2, "landed": 2,
    "lifted": 2, "lasted": 2, "painted": 2, "shouted": 2, "counted": 2, "stranded": 2,
    "rigged": 1, "lived": 1, "saved": 1, "tuned": 1, "joined": 1, "burned": 1,
    "every's": 3, "fire's": 1, "ideas": 3, "poem": 2, "poet": 2, "quite": 1,
    "cruel": 2, "fuel": 2, "jewel": 2, "towards": 2, "toward": 2, "hollow": 2,
    "echo": 2, "echoes": 2, "outlines": 2, "outline": 2, "lifeline": 2, "sometime": 2,
    "somewhere's": 2, "lantern": 2, "lanterns": 2, "static": 2, "fizz": 1, "hum": 1,
    "humming": 2, "hums": 1, "customer": 3, "customers": 3, "counter": 2, "prices": 2,
    "priced": 1, "discount": 2, "discounts": 2, "bouncing": 2, "bounces": 2,
    "whoever": 3, "however": 3, "forever": 3, "whatever": 3, "wherever": 3,
    "exchange": 2, "danger": 2, "dangerous": 3, "strangers": 2, "stranger": 2,
    "arc": 1, "arcs": 1, "spark": 1, "sparks": 1, "mid-air": 2, "midair": 2,
    "mid": 1, "air": 1, "fire": 1, "hire": 1, "yours": 1, "your": 1, "you": 1,
    "being's": 2, "curious": 3, "serious": 3, "various": 3, "period": 3,
    "beginning": 3, "begins": 2, "begin": 2, "business": 2, "family": 3,
    "different": 3, "interesting": 3, "several": 3, "camera": 3, "general": 3,
    "favourite": 3, "favorite": 3, "chocolate": 2, "vegetable": 3, "evenly": 3,
    "buried": 2, "worried": 2, "hurried": 2, "carried": 2, "married": 2, "tried": 1,
    "cried": 1, "dried": 1, "lied": 1, "died": 1, "fried": 1, "spied": 1,
    "yes": 1, "eyes": 1, "eye": 1, "dye": 1, "bye": 1, "goodbye": 2,
    "blinking": 2, "twinkle": 2, "sparkle": 2, "crackle": 2, "crackled": 2,
    "tickled": 2, "bottle": 2, "battle": 2, "rattle": 2, "gentle": 2, "settle": 2,
    "whole's": 1, "bumping": 2, "stomping": 2, "falling": 2, "coming": 2,
    "thinking": 2, "holding": 2, "calling": 2, "breaking": 2, "carrying": 3,
    "hollowed": 2, "follow": 2, "followed": 2, "following": 3, "swallowed": 2,
    "patched": 1, "patch": 1, "reached": 1, "watched": 1, "crashed": 1, "wished": 1,
    "cooked": 1, "looked": 1, "walked": 1, "talked": 1, "picked": 1, "knocked": 1,
    "knocks": 1, "stopped": 1, "dropped": 1, "stepped": 1, "jumped": 1, "bumped": 1,
    "slammed": 1, "rang": 1, "cut": 1, "gate": 1, "gates": 1, "shard": 1, "shards": 1,
    "loose": 1, "these": 1, "those": 1, "there": 1, "where": 1, "here": 1, "were": 1,
    "more": 1, "store": 1, "before's": 2, "their": 1, "they": 1, "sure's": 1,
    "fine": 1, "line": 1, "lines": 1, "time": 1, "times": 1, "home": 1, "place": 1,
    "shape": 1, "shapes": 1, "make": 1, "made": 1, "same": 1, "came": 1, "name": 1,
    "names": 1, "gave's": 1, "wave": 1, "waves": 1, "stone": 1, "note": 1, "notes": 1,
    "else": 1, "sense": 1, "since": 1, "prince": 1, "piece": 1, "voice": 1, "noise": 1,
    "choice": 1, "raise": 1, "raises": 2, "rise": 1, "rises": 2, "rising": 2,
    "raised": 1, "closed": 1, "close": 1, "closes": 2, "lose": 1, "loses": 2,
    "nose": 1, "rose": 1, "chose": 1, "choose": 1, "whose": 1, "house": 1, "houses": 2,
    "blue": 1, "true": 1, "clue": 1, "clues": 1, "glue": 1, "due": 1,
    "ahead": 2, "instead": 2, "steady": 2, "ready": 2, "already": 3, "heavy": 2,
    "idle": 2, "beautiful": 3, "science's": 2, "violet": 3, "quietest": 3,
    "hopper": 2, "hoppers": 2, "walker": 2, "walkers": 2, "warden": 2, "updraft": 2,
    "updrafts": 2, "girder": 2, "girders": 2, "lever": 2, "beacon": 2, "beacons": 2,
    "rubble": 2, "plate": 1, "plates": 1, "vent": 1, "vents": 1, "spikes": 1,
    "spiked": 1, "spike": 1, "rideable": 3, "ride": 1, "rides": 1, "lull": 1,
    "lulls": 1, "gust": 1, "gusts": 1, "streaks": 1, "tailwind": 2, "headwind": 2,
    "whenever": 3, "wondered": 2, "wonder": 2, "whispered": 2, "whisper": 2,
    "answer": 2, "answered": 2, "answers": 2, "answering": 3, "fading": 2, "faded": 2,
    "tunes": 1, "tune": 1, "tuning": 2, "tuned": 1, "dial": 2, "dials": 2,
    "flicker": 2, "flickers": 2, "flickered": 2, "flickering": 3,
    "we'll": 1, "she'll": 1, "he'll": 1, "they'll": 1, "it'll": 2, "that'll": 2,
    "who'd": 1, "you'd": 1, "we'd": 1, "they'd": 1, "there'd": 1, "wren's": 1,
    "brace's": 2, "dot's": 1, "hum's": 1, "ring's": 1, "line's": 1, "gate's": 1,
    "spark's": 1, "station's": 2, "world's": 1, "else's": 2,
}


def syllables(word: str) -> int:
    w = word.lower().strip("'")
    if not w:
        return 0
    if w in OVERRIDES:
        return OVERRIDES[w]
    if w.isdigit():
        return {1: 1, 2: 2, 3: 3}.get(len(w), 4)   # 0-9 one, 10-99 two, 100s three
    base = w
    extra = 0
    if base.endswith("'s"):
        base = base[:-2]
        if re.search(r"(s|x|z|ch|sh|ce|ge|se)$", base):
            extra = 1
    base = base.replace("'", "")
    groups = re.findall(r"[aeiouy]+", base)
    n = len(groups)
    # silent final e, but not the -le of 'little'
    if base.endswith("e") and not re.search(r"[^aeiou]le$", base) and n > 1:
        n -= 1
    # -ed is silent unless after t or d
    if base.endswith("ed") and not re.search(r"[td]ed$", base) and n > 1:
        n -= 1
    # -es is silent unless after s, x, z, ch, sh, ce, ge
    if base.endswith("es") and not re.search(r"(s|x|z|ch|sh|c|g)es$", base) and n > 1:
        n -= 1
    # vowel pairs that are two sounds (radio, violet, video), but not -tion
    n += len(re.findall(r"(?:ia|eo|ua|uo)", base)) + len(re.findall(r"io(?!n)", base))
    return max(1, n) + extra


def words_of(text: str):
    text = text.replace("*", "")
    return re.findall(r"[A-Za-z0-9]+(?:'[A-Za-z]+)?", text)


def sentences_of(text: str):
    """Split on runs of . ! ? ; a trailing piece without punctuation is a sentence too."""
    text = text.replace("*", "")
    parts = re.split(r"[.!?]+(?:\s+|$)", text)
    return [p for p in parts if words_of(p)]


def stats(texts):
    s_count = 0
    w_count = 0
    syl = 0
    for t in texts:
        sents = sentences_of(t)
        s_count += len(sents)
        for s in sents:
            ws = words_of(s)
            w_count += len(ws)
            syl += sum(syllables(w) for w in ws)
    if not w_count:
        return {"sentences": 0, "words": 0, "asl": 0, "spw": 0, "fk": 0}
    asl = w_count / s_count
    spw = syl / w_count
    fk = 0.39 * asl + 11.8 * spw - 15.59
    return {"sentences": s_count, "words": w_count, "asl": asl, "spw": spw, "fk": fk}


def wrap(s: str, width: int = 40):
    """The game's own wrap (w1_game.gd _wrap): greedy, on single spaces."""
    out = []
    cur = ""
    first = True
    for word in s.split(" "):
        if first:
            cur = word
            first = False
        elif len(cur + " " + word) <= width:
            cur += " " + word
        else:
            out.append(cur)
            cur = word
    out.append(cur)
    return out


# ---------------------------------------------------------------- loading

def load_npcs(path):
    data = json.load(open(path, encoding="utf-8"))
    out = []
    for who, d in data.items():
        if who.startswith("_"):
            continue
        for e in d["talk"]:
            for line in e["lines"]:
                out.append((who, e.get("when", ""), line))
    return data, out


def load_cards(path):
    src = open(path, encoding="utf-8").read()
    body = src.split("const CARDS := [", 1)[1].split("\n]", 1)[0]
    cards = []
    for m in re.finditer(r'"lines": \["([^"]*)", "([^"]*)"\]', body):
        cards.append((m.group(1), m.group(2)))
    return cards


def load_hints_from_root(root):
    out = []
    for path in sorted(glob.glob(os.path.join(root, "levels", "world*", "*.txt"))):
        for line in open(path, encoding="utf-8"):
            m = re.match(r"^hint#\d+ .*text=(\S+)", line)
            if m:
                out.append((os.path.basename(path), m.group(1)))
    return out


def load_hints_from_dump(path):
    out = []
    for line in open(path, encoding="utf-8"):
        m = re.match(r"^(.*?):\d+:hint#\d+ .*text=(\S+)", line)
        if m:
            out.append((os.path.basename(m.group(1)), m.group(2)))
    return out


def hint_text(raw):
    return raw.replace("_", " ")


# How a reader hears each card: does line 2 carry on line 1's sentence?
# The cards have no full stop at the end of a line, so this is judged by hand,
# once per card text. Anything not listed counts as carrying on.
CARD_BREAK_ENDS_SENTENCE = {
    "THEN A NOISE CAME DOWN THE LINE|IT SPREAD FROM STATION TO STATION",
    "THE NOISE STOPPED . SO DID THE VOICES|EACH STATION ALONE IN THE QUIET",
    "THE NOISE STOPPED . SO DID THE VOICES|EVERY STATION FELL INTO THE QUIET",
    "THEN ONE NIGHT THE DEAD LINE RANG|ONCE . TWICE . THREE TIMES",
    "UNTIL ONE NIGHT THE DEAD LINE RANG|ONCE . TWICE . THREE TIMES",
}


def card_as_text(c):
    key = c[0] + "|" + c[1]
    joiner = " . " if key in CARD_BREAK_ENDS_SENTENCE else " "
    return c[0] + joiner + c[1]


# ---------------------------------------------------------------- checks

def check_npcs(entries):
    problems = []
    lengths = []
    for who, when, line in entries:
        plain = line.replace("*", "")
        lengths.append(len(plain))
        rows = wrap(plain)
        rows_raw = wrap(line)
        if len(rows) > 3:
            problems.append(f"{who} [{when}] wraps to {len(rows)} rows: {line}")
        if len(rows_raw) > 3:
            problems.append(f"{who} [{when}] wraps to {len(rows_raw)} rows if the asterisks are drawn: {line}")
        bad = sorted(set(ch for ch in line if ch not in ALLOWED))
        if bad:
            problems.append(f"{who} [{when}] has characters the font can't draw {bad}: {line}")
        if line.count("*") % 2:
            problems.append(f"{who} [{when}] has an unpaired asterisk: {line}")
        if line.count("*") > 4:
            problems.append(f"{who} [{when}] has more than 2 highlights: {line}")
        for hl in re.findall(r"\*([^*]*)\*", line):
            if len(hl.split()) > 3:
                problems.append(f"{who} [{when}] highlight is too long ({hl}): {line}")
    return problems, lengths


def check_cards(cards):
    problems = []
    if len(cards) != 10:
        problems.append(f"{len(cards)} cards, want 10")
    for i, c in enumerate(cards):
        for line in c:
            if len(line) > 38:
                problems.append(f"card {i + 1} line over 38 characters ({len(line)}): {line}")
            bad = sorted(set(ch for ch in line if ch not in ALLOWED or ch == "*"))
            if bad:
                problems.append(f"card {i + 1} has characters not allowed on cards {bad}: {line}")
    if len(cards) > 6 and cards[6][1] != "ONCE . TWICE . THREE TIMES":
        problems.append("card 7 line 2 must stay ONCE . TWICE . THREE TIMES")
    return problems


def check_hints(hints):
    problems = []
    for f, raw in hints:
        t = hint_text(raw)
        plain = t.replace("*", "")
        if len(plain) > 30:
            problems.append(f"{f} hint over 30 characters ({len(plain)}): {t}")
        bad = sorted(set(ch for ch in t if ch not in ALLOWED or ch == "="))
        if bad:
            problems.append(f"{f} hint has characters it can't use {bad}: {t}")
        if t.count("*") not in (0, 2):
            problems.append(f"{f} hint has more than one highlight or an unpaired asterisk: {t}")
    return problems


def report(label, npc_lines, cards, hints):
    a = stats([l for _, _, l in npc_lines])
    b = stats([card_as_text(c) for c in cards])
    c = stats([hint_text(h) for _, h in hints])
    everything = stats([l for _, _, l in npc_lines] + [card_as_text(x) for x in cards])
    rows = [("Villager lines", a, len(npc_lines)), ("Intro cards", b, len(cards)),
            ("Level hints", c, len(hints)), ("Villagers + cards", everything, len(npc_lines) + len(cards))]
    print(f"== {label}")
    print(f"{'set':<20}{'items':>6}{'sentences':>10}{'words':>7}{'words/sent':>11}{'syll/word':>10}{'FK grade':>9}")
    for name, s, n in rows:
        print(f"{name:<20}{n:>6}{s['sentences']:>10}{s['words']:>7}{s['asl']:>11.1f}{s['spw']:>10.2f}{s['fk']:>9.1f}")
    return rows


def main():
    args = sys.argv[1:]
    if args and args[0] == "--before":
        snap = args[1]
        _, npc_lines = load_npcs(os.path.join(snap, "npcs.json"))
        cards = load_cards(os.path.join(snap, "intro_scene.gd"))
        hints = load_hints_from_dump(os.path.join(snap, "hints.txt"))
        label = "BEFORE"
    else:
        root = args[0] if args else "."
        _, npc_lines = load_npcs(os.path.join(root, "levels", "story", "npcs.json"))
        cards = load_cards(os.path.join(root, "scripts", "intro", "intro_scene.gd"))
        hints = load_hints_from_root(root)
        label = args[1] if len(args) > 1 else "NOW"
    report(label, npc_lines, cards, hints)
    p1, lengths = check_npcs(npc_lines)
    p2 = check_cards(cards)
    p3 = check_hints(hints)
    rows = [len(wrap(l.replace("*", ""))) for _, _, l in npc_lines]
    print(f"villager lines: {len(npc_lines)}, rows max {max(rows)}, "
          f"characters min {min(lengths)} max {max(lengths)} mean {sum(lengths) / len(lengths):.0f}, "
          f"outside 60-100: {sum(1 for n in lengths if n < 60 or n > 100)}")
    print(f"highlights in villager lines: {sum(l.count('*') // 2 for _, _, l in npc_lines)}")
    for p in p1 + p2 + p3:
        print("PROBLEM:", p)
    print("checks:", "all pass" if not (p1 or p2 or p3) else f"{len(p1 + p2 + p3)} problem(s)")
    if "--lines" in args:
        for who, when, l in npc_lines:
            st = stats([l])
            print(f"{st['asl']:5.1f} {st['spw']:4.2f} {len(wrap(l.replace('*', ''))):d} {len(l.replace('*', '')):3d}  {who:<6}{l}")
    if "--words" in args:
        seen = {}
        for _, _, l in npc_lines:
            for w in words_of(l):
                seen[w.lower()] = syllables(w)
        for c in cards:
            for w in words_of(" ".join(c)):
                seen[w.lower()] = syllables(w)
        for w in sorted(seen):
            print(f"{w}:{seen[w]}", end="  ")
        print()


if __name__ == "__main__":
    main()
