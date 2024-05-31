#! /usr/bin/env python3

import os
import argparse
import re
from collections import defaultdict
import json

def parseVecRegister(file):

    vec_list = defaultdict(set)

    with open(file, "r") as f:
        lines = f.readlines()

        working_module = None
        working_reginfo = defaultdict(set)

        for line in lines:
            if line.strip().startswith("module"):
                working_module = re.search(r"module\s+([A-Za-z0-9_$]+)\s*\(", line).group(1)
                working_reginfo.clear()

            elif line.strip().startswith("endmodule"):
                if len(working_reginfo) > 0:
                    # print(f"[*] Processing module: {working_module}")
                    for _, reg_set in working_reginfo.items():
                        if len(reg_set) > 1:
                            def preprocess(reg_name):
                                sub_fields = reg_name.split("_")
                                try:
                                    item_index = list(map(lambda x: x.isdigit() or len(x) == 0, sub_fields)).index(True)
                                    bundle_name = "_".join(sub_fields[:item_index])
                                except ValueError:
                                    item_index = -1
                                    bundle_name = reg_name
                                return (bundle_name, item_index, reg_name)

                            maybe_vec = filter(lambda reg_tuple: reg_tuple[1] >= 0, map(preprocess, reg_set))
                            for vec_tuple in maybe_vec:
                                vec_list[working_module].add(vec_tuple[2])

                # reset state
                working_module = None

            if working_module is None:
                continue

            if (
                len(line.strip()) == 0
                or line.strip().split()[0] != "reg"
                or "@" not in line
                or "<=" in line
            ):
                continue

            # print(f"[*] Found reg line: {line[:-1]}")

            reg_name = re.search(r"reg\s+(\[(\d+):(\d+)\])?\s*([A-Za-z0-9_$]+)\s*(\[\d+:\d+\])?\s*;", line).group(4)
            reg_info = line.split("@")[1][1:-2]

            working_reginfo[reg_info].add(reg_name)

            # print(f"[*] Found register: `{reg_name}` @ {reg_info}")
    
    return vec_list


def main(args):
    all_vec_list = defaultdict(set)
    for file in args.input:
        print(f"[*] Processing {file}")
        all_vec_list.update(parseVecRegister(file))
                
    with open(args.output, "w") as f:
        for module, vec_set in all_vec_list.items():
            if args.prefix is not None:
                if any(map(lambda x: module.startswith(x), args.prefix)):
                    continue

            f.write(f"{module}\n")
            for vec in sorted(vec_set):
                f.write(f"\t@{vec}\n")
            f.write("\n\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Collect Vec Register")

    parser.add_argument(
        "-i", "--input", nargs="+", type=str, required=True, help="input verilog files"
    )
    parser.add_argument(
        "-o", "--output", type=str, required=True, help="output file name"
    )
    parser.add_argument(
        "-p", "--prefix", nargs="*", type=str, default=["TL", "AXI", "XS_TL", "XS_AXI"],
        help="ignored module prefix"
    )

    args = parser.parse_args()
    if not os.path.exists(os.path.dirname(args.output)):
        os.makedirs(os.path.dirname(args.output), exist_ok=True)

    main(args)
