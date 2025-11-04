import json
import argparse
import shutil
import os
import sys
import re
from typing import List, Dict, Set, Iterable, Tuple, Any, Optional

TB_SFX = "_tb"

module_search_path = []
in_filelists = []
module_path_map = {}
memconfig_map = {}

tb_hier_map = {}
dut_hier_map = {}

def handle_multiple_arguments(arg_value: str, separator: str) -> list[str]:
    if separator in arg_value:
        return arg_value.split(separator)
    else:
        return [arg_value]

def get_file_abs_path(file: str) -> str:
    if not os.path.exists(file):
        for dir in module_search_path:
            alt = os.path.join(dir, file)
            if os.path.exists(alt):
                return os.path.abspath(alt)
        raise FileNotFoundError(f"File {file} not found, searched in paths: {module_search_path}")
    else:
        return os.path.abspath(file)

def write_filelist(tb_out_filelist, dut_out_filelist):
    tb_extern_modules = [m for m in tb_hier_map.keys() if m not in module_path_map.keys()]
    with open(tb_out_filelist, 'w', encoding='utf-8') as f:
        for module in tb_hier_map.keys():
            if module in tb_extern_modules:
                continue
            path = module_path_map[module]
            f.write(f"{path}\n")
    
    dut_extern_modules = [m for m in dut_hier_map.keys() if m not in module_path_map.keys()]
    with open(dut_out_filelist, 'w', encoding='utf-8') as f:
        for module in dut_hier_map.keys():
            if module in dut_extern_modules:
                continue
            path = module_path_map[module]
            f.write(f"{path}\n")

def write_memconf(tb_memconf, dut_memconf):
    tb_mems = [m for m in memconfig_map.keys() if m in tb_hier_map.keys()]
    with open(tb_memconf, 'w', encoding='utf-8') as f:
        for mem in tb_mems:
            line = memconfig_map[mem]
            f.write(f"{line}\n")
    
    dut_mems = [m for m in memconfig_map.keys() if m in dut_hier_map.keys()]
    with open(dut_memconf, 'w', encoding='utf-8') as f:
        for mem in dut_mems:
            line = memconfig_map[mem]
            f.write(f"{line}\n")

def rename_testbench_modules(tb, dut):
    global module_path_map, tb_hier_map

    shared_modules = [m for m in tb_hier_map.keys() if m in dut_hier_map.keys()]
    extern_modules = [m for m in tb_hier_map.keys() if m not in module_path_map.keys()] + [dut]

    for old_module, instances in list(tb_hier_map.items()):
        if old_module in extern_modules:
            continue

        old_path = module_path_map[old_module]
        dir_name, file_name = os.path.split(old_path)
        base_name = file_name.rsplit('.', 1)
        new_path = os.path.join(dir_name, f"{base_name[0]}{TB_SFX}.{base_name[1]}")
        new_module = old_module + TB_SFX
        
        print(f"[*] 1/3 Copy file {old_path} to {new_path}.")
        shutil.copyfile(old_path, new_path)

        
        with open(new_path, 'r', encoding='utf-8') as f:
            src = f.read()

        if old_module != tb:
            print(f"[*] 2/3 Rename module {old_module}.")
            lr_module = re.compile(
                rf'''^
                (\s*(?:\(\*.*?\*\)\s*)*module\s+(?:automatic\s+|static\s+)?)
                ({re.escape(old_module)})
                ''', flags=re.MULTILINE | re.DOTALL | re.VERBOSE)
            src, n = lr_module.subn(rf'\1{new_module}', src, count=1)
            if n == 0:
                raise Exception(f"Failed to rename module {old_module}.")
        
        
        for (sub_module, instance_name) in instances:
            if sub_module in extern_modules:
                continue

            print(f"[*] 3/3 Update instance {instance_name}.")
            lr_instance = re.compile(
                rf'''^
                (\s*(?:\(\*.*?\*\)\s*)*)
                ({re.escape(sub_module)})
                (\s*(?:\#\s*\([^;]*?\))?\s+)
                ({re.escape(instance_name)})
                ''', re.MULTILINE | re.DOTALL | re.VERBOSE)

            src, n = lr_instance.subn(rf'\1{sub_module + TB_SFX}\3\4', src, count=1)
            if n == 0:
                raise Exception(f"Failed to rename instance {instance_name}@{sub_module} in module {old_module}.")

        with open(new_path, 'w', encoding='utf-8') as f:
            f.write(src)

        tb_hier_map[new_module] = [(m + TB_SFX, inst) for (m, inst) in tb_hier_map[old_module]]
        tb_hier_map.pop(old_module)
        module_path_map[new_module] = new_path

        if old_module not in shared_modules:
            module_path_map.pop(old_module)


def get_hierarchy(file: str, ignores: List[str] | None = None):
    file = get_file_abs_path(file)

    hier_map = {}
    with open(file, encoding='utf-8') as f:
        hier = json.load(f)

        def walk_hierarchy(node):
            module = node["module_name"]
            sub_nodes = node.get("instances", [])
            sub_modules = [(s["module_name"], s["instance_name"]) for s in sub_nodes]

            if module not in hier_map:
                hier_map[module] = sub_modules
                for child in sub_nodes:
                    if ignores and child["module_name"] in ignores:
                        continue
                    walk_hierarchy(child)

            else:
                prev_list = hier_map[module]
                if prev_list != sub_modules:
                    raise Exception(f"Module {module} has inconsistent instance lists.")

    walk_hierarchy(hier)
    return hier_map

def split_hierarchy(file: str, dut: str):
    file = get_file_abs_path(file)
    
    tb_hier_map = {}
    dut_hier_map = {}

    with open(file, encoding='utf-8') as f:
        hier = json.load(f)

    def walk_hierarchy(node, in_dut: bool):
        module = node["module_name"]
        sub_nodes = node.get("instances", [])
        sub_modules = [(s["module_name"], s["instance_name"]) for s in sub_nodes]

        selected_map = dut_hier_map if in_dut else tb_hier_map
        if module not in selected_map:
            selected_map[module] = sub_modules
            for child in sub_nodes:
                if child["module_name"] == dut:
                    walk_hierarchy(child, True)
                else:
                    walk_hierarchy(child, in_dut)
        else:
            prev_list = selected_map[module]
            if prev_list != sub_modules:
                raise Exception(f"Module {module} has inconsistent instance lists.")
    
    walk_hierarchy(hier, False)

    return tb_hier_map, dut_hier_map


def load_modules(file: str):
    # blackbox file may contain multiple modules
    module_names: List[str] = []


    with open(file, encoding='utf-8') as f:
        src = f.read()

    lr_module = re.compile(
        r'''^
            \s*(?:\(\*.*?\*\)\s*)*
            module\s+
            (?:automatic\s+|static\s+)?
            ([A-Za-z_][\w$]*)
        ''', re.MULTILINE | re.DOTALL | re.VERBOSE)

    for m in lr_module.finditer(src):
        module_names.append(m.group(1))

    return module_names

def load_filelist(filelist: list[str]):
    filelist = get_file_abs_path(filelist)
    paths = {}
    with open(filelist, encoding='utf-8') as f:
        for line in f:
                line = line.strip()
                ext = os.path.basename(line).split('.')[-1]
                if ext in ("v","sv"):
                    path = get_file_abs_path(line)
                    modules = load_modules(path)
                    for module in modules:
                        paths[module] = path
                    if len(modules) == 0:
                        print(f"warning: {path} has no module declarations")
                # elif ext in ("c","cpp","h","hpp"):
                else:
                    raise Exception(f"Unsupported source files found: {line}")

    return paths


def load_memconf(conf: str):
    conf = get_file_abs_path(conf)
    mems = {}
    with open(conf) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("name "):
                continue
            parts = line.split()
            name = parts[1]
            mems[name] = line

    return mems

def main(tb, dut, tb_out_filelist, dut_out_filelist, tb_memconf, dut_memconf):
    rename_testbench_modules(tb, dut)
    write_filelist(tb_out_filelist, dut_out_filelist)
    write_memconf(tb_memconf, dut_memconf)

if __name__=="__main__":
    parser = argparse.ArgumentParser(description="Split DUT from testbench for instrumentation purposes.")
    # inputs
    parser.add_argument("--tb", type=str, required=True, help="testbench name")
    parser.add_argument("--dut", type=str, required=True, help="DUT name")
    parser.add_argument("--hierarchy", type=str, required=True, help="design hierarchy json")
    parser.add_argument('--filelist', type=str, required=True, help='whole design filelist, split by `,`')
    parser.add_argument('--include', type=str, required=True, help='path where to find source files, split by `,`')
    parser.add_argument('--memconf', type=str, required=True, help='path where to find memory configuration')
    # outputs
    parser.add_argument('--tb-filelist', type=str, required=True, help='testbench filelist')
    parser.add_argument('--dut-filelist', type=str, required=True, help='DUT filelist')
    parser.add_argument("--tb-memconf", type=str, required=True, help="testbench memory configuration")
    parser.add_argument("--dut-memconf", type=str, required=True, help="DUT memory configuration")
    
    args = parser.parse_args()

    module_search_path.extend(handle_multiple_arguments(args.include, ','))
    in_filelists.extend(handle_multiple_arguments(args.filelist, ','))
    for filelist in in_filelists:
        module_path_map |= load_filelist(filelist)
    tb_hier_map, dut_hier_map = split_hierarchy(args.hierarchy, args.dut)
    memconfig_map = load_memconf(args.memconf)

    main(args.tb, args.dut, args.tb_filelist, args.dut_filelist, args.tb_memconf, args.dut_memconf)
