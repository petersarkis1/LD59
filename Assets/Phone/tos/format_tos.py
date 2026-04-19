#!/usr/bin/env python3
"""
Reformats a text file to wrap at a given character width.
Usage: python3 format_tos.py input.txt output.txt --width 52
"""

import argparse
import textwrap

def format_file(input_path: str, output_path: str, width: int) -> None:
    with open(input_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    output_lines = []

    for line in lines:
        stripped = line.strip()

        if stripped == "":
            output_lines.append("")
            continue

        if stripped.isupper() or len(stripped) <= width * 0.4:
            output_lines.append(stripped)
            continue

        wrapped = textwrap.fill(stripped, width=width)
        output_lines.append(wrapped)

    output = "\n".join(output_lines)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(output)

    print(f"Done! {len(output_lines)} lines written to {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Reformat text to fit phone screen.")
    parser.add_argument("input",           help="Input text file")
    parser.add_argument("output",          help="Output text file")
    parser.add_argument("--width", type=int, default=52,
                        help="Max characters per line (default: 52)")
    args = parser.parse_args()
    format_file(args.input, args.output, args.width)
