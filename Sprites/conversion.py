import csv

CSV_FILE = "torterra.csv"

# Map your CSV numbers to 3-bit palette indices
# '' or empty = 0 (transparent)
mapping = {
    "":  "0000",  # transparent
    "0": "0000",  # also transparent
    "1": "0001",
    "2": "0010",
    "3": "0011",
    "4": "0100",
    "5": "0101",
    "6": "0110",
    "7": "0111",
    "8": "1000",
    "9": "1001",
    "10": "1010",
    "11": "1011",
    "12": "1100",
    "13": "1101",
    "14": "1110",
    "15": "1111",
}

rows = []
with open(CSV_FILE, newline="") as f:
    reader = csv.reader(f)
    for row in reader:
        rows.append(row)

height = len(rows)
width = max(len(r) for r in rows)

# We want exactly 80x80; pad with transparent if needed
TARGET_W = 80
TARGET_H = 80

# Trim/pad rows
sprite = []
for y in range(TARGET_H):
    if y < height:
        r = rows[y]
    else:
        r = []

    # pad row to at least TARGET_W
    r = list(r) + [""] * (TARGET_W - len(r))
    r = r[:TARGET_W]

    sprite.append([mapping.get(v.strip(), "0000") for v in r])

print("CONSTANT SPRITE : sprite_t := (")
for y, row in enumerate(sprite):
    entries = ", ".join(f'\"{val}\"' for val in row)
    end = "," if y < TARGET_H - 1 else ""
    print(f"    {y} => ({entries}){end}")
print(");")
