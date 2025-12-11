import csv
import os
import tkinter as tk
from tkinter import filedialog, messagebox

# ---- Conversion logic ----

# Map CSV numbers to 4-bit palette indices
MAPPING = {
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

TARGET_W = 80
TARGET_H = 80


def convert_csv_to_sprite(csv_path: str) -> str:
    rows = []
    with open(csv_path, newline="") as f:
        reader = csv.reader(f)
        for row in reader:
            rows.append(row)

    height = len(rows)

    sprite = []
    for y in range(TARGET_H):
        if y < height:
            r = rows[y]
        else:
            r = []

        # pad row to at least TARGET_W
        r = list(r) + [""] * (TARGET_W - len(r))
        r = r[:TARGET_W]

        sprite.append([MAPPING.get(v.strip(), "0000") for v in r])

    # Build VHDL constant as a single string
    lines = []
    lines.append("CONSTANT SPRITE : sprite_t := (")
    for y, row in enumerate(sprite):
        entries = ", ".join(f'"{val}"' for val in row)
        end = "," if y < TARGET_H - 1 else ""
        lines.append(f"    {y} => ({entries}){end}")
    lines.append(");")

    return "\n".join(lines)


# ---- GUI ----

def main():
    root = tk.Tk()
    root.title("CSV → VHDL Sprite Converter")

    # Store selected file path
    selected_file = tk.StringVar()

    # Script directory (for starting the file dialog)
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # --- Callbacks ---

    def choose_file():
        path = filedialog.askopenfilename(
            initialdir=script_dir,
            title="Select CSV file",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
        )
        if path:
            selected_file.set(path)

    def generate_output():
        path = selected_file.get()
        if not path:
            messagebox.showwarning("No file selected", "Please select a CSV file first.")
            return

        try:
            output = convert_csv_to_sprite(path)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to convert file:\n{e}")
            return

        # Put text into the Text widget
        text_box.delete("1.0", tk.END)
        text_box.insert(tk.END, output)

        # Optionally auto-copy to clipboard (comment out if you don't want this)
        root.clipboard_clear()
        root.clipboard_append(output)
        messagebox.showinfo("Done", "Conversion complete.\nOutput copied to clipboard.")

    def copy_to_clipboard():
        output = text_box.get("1.0", tk.END).strip()
        if not output:
            messagebox.showwarning("No output", "Nothing to copy. Generate the sprite first.")
            return
        root.clipboard_clear()
        root.clipboard_append(output)
        messagebox.showinfo("Copied", "Output copied to clipboard.")

    # --- Layout ---

    top_frame = tk.Frame(root)
    top_frame.pack(fill="x", padx=10, pady=10)

    btn_select = tk.Button(top_frame, text="Select CSV File", command=choose_file)
    btn_select.pack(side="left")

    entry_file = tk.Entry(top_frame, textvariable=selected_file, width=60)
    entry_file.pack(side="left", padx=5, fill="x", expand=True)

    btn_generate = tk.Button(top_frame, text="Generate VHDL", command=generate_output)
    btn_generate.pack(side="left", padx=5)

    # Text box for output
    text_frame = tk.Frame(root)
    text_frame.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    text_box = tk.Text(text_frame, wrap="none", height=25)
    text_box.pack(side="left", fill="both", expand=True)

    # Scrollbars
    y_scroll = tk.Scrollbar(text_frame, orient="vertical", command=text_box.yview)
    y_scroll.pack(side="right", fill="y")
    text_box.configure(yscrollcommand=y_scroll.set)

    x_scroll = tk.Scrollbar(root, orient="horizontal", command=text_box.xview)
    x_scroll.pack(fill="x")
    text_box.configure(xscrollcommand=x_scroll.set)

    # Bottom buttons
    bottom_frame = tk.Frame(root)
    bottom_frame.pack(fill="x", padx=10, pady=(0, 10))

    btn_copy = tk.Button(bottom_frame, text="Copy to Clipboard", command=copy_to_clipboard)
    btn_copy.pack(side="left")

    root.mainloop()


if __name__ == "__main__":
    main()
