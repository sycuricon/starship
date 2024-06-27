#! /usr/bin/env python3

import os
import argparse
import re
from collections import defaultdict

def parseVecRegister(file):

    array_list = defaultdict(set)

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
                    vec_list = defaultdict(set)

                    for _, possible_array_list in working_reginfo.items():
                        for reginfo_pair in possible_array_list:
                            reg_name = reginfo_pair[0]
                            reg_type = reginfo_pair[1]

                            if reg_type == "mem":
                                array_list[working_module].add(f"#{reg_name}")
                            
                            else: # is vec
                                sub_fields = reg_name.split("_")
                                try:
                                    item_index = list(map(lambda x: x.isdigit() or len(x) == 0, sub_fields)).index(True)
                                    bundle_name = "_".join(list(map(lambda x: "" if x.isdigit() else x, sub_fields)))

                                    # ignore pipeline registers and io buffer
                                    if sub_fields[0] in ["s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7"] or \
                                       sub_fields[0] in ["f0", "f1", "f2", "f3", "f4", "f5", "f6", "f7"] or \
                                       sub_fields[0] in ["io"]:
                                        continue

                                    # ignore RegNext buffer
                                    if "REG" in sub_fields:
                                        continue

                                    vec_list[bundle_name].add(reg_name)

                                except ValueError:
                                    continue

                    for _, vec_set in vec_list.items():
                        if len(vec_set) > 1:
                            array_list[working_module].update(list(map(lambda reg_name: f"@{reg_name}", vec_set)))

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

            match_res = re.search(r"reg\s+(\[\d+:\d+\])?\s*([A-Za-z0-9_$]+)\s*(\[\d+:\d+\])?\s*;", line)
            reg_name = match_res.group(2)
            reg_type = "vec" if match_res.group(3) is None else "mem"
            reg_info = line.split("@")[1][1:-2]

            working_reginfo[reg_info].add((reg_name, reg_type))

            # print(f"[*] Found register: `{reg_name}` @ {reg_info}")
    
    return array_list


def main(args):
    final_array_list = defaultdict(set)
    for file in args.input:
        print(f"[*] Processing {file}")
        final_array_list.update(parseVecRegister(file))
                
    with open(args.output, "w") as f:
        for module, target_set in final_array_list.items():
            if args.prefix is not None:
                if any(map(lambda x: module.startswith(x), args.prefix)):
                    continue

            f.write(f"{module}\n")
            for target in sorted(target_set):
                f.write(f"\t{target}\n")
            f.write("\n\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Collect Register Array from Verilog Files")

    parser.add_argument(
        "-i", "--input", nargs="+", type=str, required=True, help="input verilog files"
    )
    parser.add_argument(
        "-o", "--output", type=str, required=True, help="output file name"
    )
    parser.add_argument(
        "-p", "--prefix", nargs="*", type=str, default=["TL", "AXI", "XS_TL", "XS_AXI", "XS_SRAMTemplate", "XS_SyncDataModuleTemplate"],
        help="ignored module prefix"
    )

    args = parser.parse_args()
    if not os.path.exists(os.path.dirname(args.output)):
        os.makedirs(os.path.dirname(args.output), exist_ok=True)

    main(args)
