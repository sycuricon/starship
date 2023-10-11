#!/usr/bin/env python3

import re
from optparse import OptionParser
from elftools.elf.elffile import ELFFile
from elftools.elf.sections import Section

config_template = """{{
    "version": 1,
    "machine":"riscv64",
    "memory_size": 2048,
    "trace": {trace},
    "bios": "{testcase}",
    "memory_base_addr": 0x80000000,
    "htif_base_addr": {tohost}
}}"""


def main():
    param = {
        'trace': options.trace,
        'testcase': options.testcase,
        'tohost': options.tohost
    }
    print(config_template.format(**param))


if __name__ == '__main__':
    parser = OptionParser(usage="%prog [OPTION] [INPUT FILE]")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="trace enable")
    parser.add_option("-t", "--testcase", dest="testcase", type="string", help="testcase file")
    (options, args) = parser.parse_args()
    options.trace = "true" if options.verbose else "false"

    with open(options.testcase, 'rb') as elf:
            for section  in ELFFile(elf).iter_sections():
                if (section.name == ".tohost"):
                    options.tohost = hex(section['sh_addr'])
                    break

    if not options.testcase:
        parser.error("Testcase file is required!")
    if not options.tohost:
        parser.error(".tohost section is required!")


    # print(options)
    main()
