#!/usr/bin/env python3

import re
import tempfile
from optparse import OptionParser


def gen_header(first):
    statement = []
    if options.mode_vlog:
        length = int("".join(filter(str.isdigit, first)))
        # statement.append("wire [%d:0] %s;\nassign %s = {" % (length - 1 if length else 0, options.name, options.name))
        statement.append("%s #(%d) %s (.clock(clock), .reset(reset), .finish(finish), \n.state({" % (options.name, length, options.name))
    elif options.mode_rc:
        pass
    elif options.mode_snap:
        pass

    return "%s\n" % "\n".join(statement)


def gen_tailer():
    statement = []
    if options.mode_vlog:
        # statement.append("};")
        statement.append("}));")
    elif options.mode_rc:
        pass
    elif options.mode_snap:
        pass

    return "%s\n" % "\n".join(statement)


def main():
    with open(options.output, "w+") as output:
        with open(options.reglist, "r") as input:
            head = gen_header(input.readline())
            output.write(head)

            lines = input.readlines()
            statement = []
            for line in lines:
                line = re.sub("^[a-zA-Z0-9]+", options.prefix, line.replace("\n", ""))

                (regPath, regDepthStr, regWidthStr) = line.split("@")
                (regDepthLow, regDepthHigh) = list(map(lambda x: int(x), regDepthStr.split(":")))
                (regWidthHigh, regWidthLow) = list(map(lambda x: int(x), regWidthStr.split(":")))
                regWidth = regWidthHigh - regWidthLow + 1
                regDepth = regDepthHigh - regDepthLow + 1
                suffixWidth = "[" + regWidthStr + "]" if not regWidth == 1 else ""

                if options.mode_vlog:
                    if regDepth >= 1:
                        for i in range(regDepth):
                            suffixDepth = "[" + str(i) + "]"
                            statement.append(regPath + suffixDepth + suffixWidth)
                    else:
                        statement.append(regPath + suffixWidth)
                elif options.mode_rc:
                    suffixDepth = "[" + regDepthStr + "]" if regDepth else ""
                    statement.append(regPath.replace(".", "/") + suffixDepth + suffixWidth)
                elif options.mode_snap:
                    pass
            output.write("%s\n" % ",\n".join(statement))

        tail = gen_tailer()
        output.write(tail)

    print("\033[1;32m[Starship] register list convert to \033[1;36m" + options.mode + "\033[1;32m done\033[0m")


if __name__ == '__main__':
    parser = OptionParser(usage="%prog [OPTION] [INPUT FILE]")
    parser.add_option("-o", "--output", dest="output", type="string", help="output file name")
    parser.add_option("-f", "--format", dest="mode",   type="string", help="target output format")
    parser.add_option("-p", "--prefix", dest="prefix", type="string", help="prefix of module path")
    parser.add_option("-n", "--name",   dest="name",   type="string", help="extra name information")
    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("Input register list file is required!")
    elif not options.output:
        parser.error("Output file name is required!")
    elif not options.mode:
        parser.error("Output format is required!")
    elif not options.prefix:
        parser.error("Path prefix is required!")
    else:
        options.reglist = args[0]
        options.mode_vlog = options.mode_rc = options.mode_snap = False
        if options.mode in ["signal", "vlog", "verilog"]:
            options.mode_vlog = True
        elif options.mode in ["wave", "rc", "verdi"]:
            options.mode_rc = True
        elif options.mode in ["snapshot", "snap", "coverage"]:
            options.mode_snap = True
        else:
            parser.error("Support format: signal, wave, snapshot")

        if (options.mode_vlog and not options.name) or (options.mode_snap and not options.name):
            parser.error("Extra information is required!")

    # print(options)
    main()
