#! /usr/bin/env python3

import os
import argparse
import re
from collections import defaultdict
from itertools import groupby

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
                        def extract_key(reginfo_pair):
                            parts = reginfo_pair[0].split('_')
                            for part in parts:
                                if part.isdigit() or part == '':
                                    return '_'.join(parts[:parts.index(part)])
                            return reginfo_pair[0]
                        print("[*]", possible_array_list)
                        for key, group in groupby(possible_array_list, key=extract_key):
                            group_list = list(group)
                            print(key, len(group_list), group_list)

                            vec_index = set()
                            
                            for reginfo in group_list:
                                reg_name = reginfo[0]
                                sub_fields = reg_name.split("_")
                                if reg_name == key:
                                    vec_index.add('')
                                for part in sub_fields:
                                    if part.isdigit() or part == '':
                                        vec_index.add(part)
                                        break
                            
                            if len(vec_index) <= 1:
                                print("Remove", key)
                                continue


                            for reginfo in group_list:
                                reg_name = reginfo[0]
                                sub_fields = reg_name.split("_")

                                # ignore pipeline registers and io buffer
                                if sub_fields[0] in ["s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7"] or \
                                    sub_fields[0] in ["f0", "f1", "f2", "f3", "f4", "f5", "f6", "f7"] or \
                                    sub_fields[0] in ["io"]:
                                    continue

                                # ignore counter
                                if sub_fields[0] in ["small", "big"]:
                                    continue
                                
                                # ignore RegNext buffer
                                if "REG" in sub_fields:
                                    continue
                                
                                print("Add", reg_name)

                                vec_list[key].add(reg_name)

                    for _, vec_set in vec_list.items():
                        if len(vec_set) > 1:
                            array_list[working_module].update(list(map(lambda reg_name: f"@{reg_name}", vec_set)))

                # reset state
                working_module = None

            if working_module is None:
                continue

            # print(f"[*] Parse line: {line}")

            if (len(line.strip()) != 0 and line.strip().split()[0] == "reg" and "@" in line):
                match_res = re.search(r"reg\s+(\[\d+:\d+\])?\s*([A-Za-z0-9_$]+)\s*(\[\d+:\d+\])?\s*;", line)
                reg_name = match_res.group(2)
                reg_type = "vec" if match_res.group(3) is None else "mem"
                reg_info = line.split("@")[1][1:-2]

                if reg_type == "mem":
                    continue

                working_reginfo[reg_info].add((reg_name, reg_type))

                # print(f"[*] Found {reg_type} under module {working_module}: `{reg_name}` @ {reg_info}")
    
    return array_list


def main(args):
    final_array_list = defaultdict(set)
    for file in args.input:
        print(f"[*] Processing {file}")
        final_array_list.update(parseVecRegister(file))
                
    with open(args.output, "w") as f:
        for module, target_set in final_array_list.items():
            if args.ignore is not None:
                if any(map(lambda x: module.startswith(x), args.ignore)):
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
        "-p", "--ignore", nargs="*", type=str, default=[
            "TL", "AXI", "XS_TL", "XS_AXI",
            "XS_SRAMTemplate", "XS_SyncDataModuleTemplate",
            "XS_FADD_pipe", "XS_BypassNetwork"],
        help="ignored module prefix"
    )

    args = parser.parse_args()
    if not os.path.exists(os.path.dirname(args.output)):
        os.makedirs(os.path.dirname(args.output), exist_ok=True)

    main(args)
