import csv
import os

# Get folder where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Find all CSV files in this folder
csv_files = [f for f in os.listdir(SCRIPT_DIR) if f.lower().endswith(".csv")]

if not csv_files:
    print("No .csv files found in the script directory.")
    exit(1)

# Display menu
print("Select a CSV file to convert:")
for i, fname in enumerate(csv_files):
    print(f"{i+1}. {fname}")

# Ask user
choice = input("Enter number: ").strip()
if not choice.isdigit() or not (1 <= int(choice) <= len(csv_files)):
    print("Invalid selection.")
    exit(1)

CSV_FILE = os.path.join(SCRIPT_DIR, csv_files[int(choice) - 1])
print(f"Using file: {CSV_FILE}")

# Map CSV numbers to 4-bit palette indices
mapping = {
    "":  "0000",
    "0": "0000",
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

# Read CSV
rows = []
with open(CSV_FILE, newline="") as f:
    reader = csv.reader(f)
    for row in reader:
        rows.append(row)

height = len(rows)
width = max(len(r) for r in rows)

# Target 80x80
TARGET_W = 80
TARGET_H = 80

sprite = []
for y in range(TARGET_H):
    if y < height:
        r = rows[y]
    else:
        r = []

    # Pad row
    r = list(r) + [""] * (TARGET_W - len(r))
    r = r[:TARGET_W]

    sprite.append([mapping.get(v.strip(), "0000") for v in r])

# Print VHDL constant
print("CONSTANT SPRITE : sprite_t := (")
for y, row in enumerate(sprite):
    entries = ", ".join(f'\"{val}\"' for val in row)
    end = "," if y < TARGET_H - 1 else ""
    print(f"    {y} => ({entries}){end}")
print(");")
