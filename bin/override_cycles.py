import csv
import sys
from pathlib import Path
from collections import defaultdict

# --- Helper functions ---

def reverse_complement(seq):
    complement = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(complement)[::-1]

def format_read_cycles(length, drop_first=False):
    if length > 1:
        return f"N1Y{length-1}" if drop_first else f"Y{length-1}N1"
    else:
        return f"N{length}"

def format_index_cycles(index_seq, expected_length):
    if not index_seq:
        return f"N{expected_length}"
    actual_len = len(index_seq)
    if actual_len < expected_length:
        return f"I{actual_len}N{expected_length - actual_len}"
    elif actual_len == expected_length:
        return f"I{actual_len}"
    else:
        print(f"Warning: index {index_seq} longer than expected {expected_length} cycles. Truncating.")
        return f"I{expected_length}"

def generate_override_cycles(index1, index2, r1_len, r2_len, i1_len, i2_len, drop_first=False):
    cycles = []
    cycles.append(format_read_cycles(r1_len, drop_first))
    if i1_len > 0:
        cycles.append(format_index_cycles(index1, i1_len))
    if i2_len > 0:
        cycles.append(format_index_cycles(index2, i2_len))
    if r2_len > 0:
        cycles.append(format_read_cycles(r2_len, drop_first))
    return ";".join(cycles)

# --- Main processing ---

def fill_override_cycles(input_sheet, output_dir):
    input_path = Path(input_sheet)
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True)

    with open(input_path, newline="") as infile:
        lines = infile.readlines()

    # Split into sections
    header, reads, settings, data = [], [], [], []
    section = None
    for line in lines:
        if line.startswith("[Header]"):
            section = "header"
        elif line.startswith("[Reads]"):
            section = "reads"
        elif line.startswith("[BCLConvert_Settings]"):
            section = "settings"
        elif line.startswith("[BCLConvert_Data]"):
            section = "data"
        if section == "header":
            header.append(line)
        elif section == "reads":
            reads.append(line)
        elif section == "settings":
            settings.append(line)
        elif section == "data":
            data.append(line)

    # Extract cycle lengths
    r1_len, r2_len, i1_len, i2_len = 0, 0, 0, 0
    for line in reads:
        if line.startswith("Read1Cycles"):
            r1_len = int(line.split(",")[1])
        elif line.startswith("Read2Cycles"):
            r2_len = int(line.split(",")[1])
        elif line.startswith("Index1Cycles"):
            i1_len = int(line.split(",")[1])
        elif line.startswith("Index2Cycles"):
            i2_len = int(line.split(",")[1])

    # Parse data
    reader = csv.DictReader(data[1:])
    fieldnames = reader.fieldnames
    if "OverrideCycles" not in fieldnames:
        fieldnames.append("OverrideCycles")

    # Group rows by lane and track projects
    lane_to_rows = defaultdict(list)
    project_to_lanes = defaultdict(set)

    for row in reader:
        index1 = row.get("index", "").strip()
        index2 = row.get("index2", "").strip()
        project = row.get("Sample_Project", "").strip()
        lane = row.get("Lane", "").strip()

        drop_first = project.endswith("_Ill")

        # Grenier-specific rules
        if "Grenier" in project:
            if index2:
                index2 = reverse_complement(index2)
                if len(index2) == 12:
                    index2 = index2[:-2]  # trim last 2 bases
                row["index2"] = index2
            if index1 and len(index1) == 12:
                index1 = index1[:-2]  # trim last 2 bases only if len==12
                row["index"] = index1

        row["OverrideCycles"] = generate_override_cycles(
            index1, index2, r1_len, r2_len, i1_len, i2_len, drop_first
        )

        lane_to_rows[lane].append(row)
        project_to_lanes[project].add(lane)

    # Determine lane groups (merge if projects span multiple lanes)
    merged_lane_groups = []
    seen_sets = set()
    for project, lanes in project_to_lanes.items():
        lanes_set = frozenset(lanes)
        if lanes_set not in seen_sets:
            merged_lane_groups.append(lanes_set)
            seen_sets.add(lanes_set)

    # Write files
    for lanes_set in merged_lane_groups:
        lanes_list = sorted(lanes_set, key=int)  # numeric sort
        filename = "L" + "_".join(lanes_list) + ".csv"
        all_rows = []
        for lane in lanes_list:
            all_rows.extend(lane_to_rows[lane])

        out_file = output_dir / filename
        with open(out_file, "w", newline="") as outfile:
            outfile.writelines(header)
            outfile.writelines(reads)
            outfile.writelines(settings)
            outfile.write("[BCLConvert_Data]\n")
            writer = csv.DictWriter(outfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(all_rows)
        print(f"Wrote {out_file}")

# --- Entry point ---
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python fill_override_cycles.py input_samplesheet.csv output_directory")
    else:
        fill_override_cycles(sys.argv[1], sys.argv[2])

