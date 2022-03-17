#!/usr/bin/env python3

import re
from optparse import OptionParser

config_template = """{{
    "version": 1,
    "machine":"riscv64",
    "memory_size": 2048,
    "trace": {trace},
    "bios": "{testcase}",
    "memory_base_addr": 0x80000000,
    "htif_base_addr": 0x80001000
}}"""


def main():
    param = {
        'trace': options.trace,
        'testcase': options.testcase
    }
    print(config_template.format(**param))


if __name__ == '__main__':
    parser = OptionParser(usage="%prog [OPTION] [INPUT FILE]")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="trace enable")
    parser.add_option("-t", "--testcase", dest="testcase", type="string", help="testcase file")
    (options, args) = parser.parse_args()
    options.trace = "true" if options.verbose else "false"

    if not options.testcase:
        parser.error("Testcase file is required!")
   
    # print(options)
    main()
