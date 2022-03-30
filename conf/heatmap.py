#!/usr/bin/env python3

import os
import pickle
import matplotlib.pyplot as plt
from optparse import OptionParser
from matplotlib.colors import ListedColormap
from matplotlib.pyplot import MultipleLocator
import numpy as np
import tkinter as tk

def adjust_total(raw):
    remap = list(map(lambda vec: list(map(lambda sum: sum+32 if sum >= 1 else 1, vec)), raw))
    return np.log(remap)

def save_session(name, array):
    print("Save " + options.output + "/" + name + ".png")
    plt.savefig(options.output + "/" + name + ".png", dpi=1200, bbox_inches='tight')
    print("Save " + options.output + "/" + name + ".array")
    pickle.dump(array, open(options.output + "/" + name + '.array', 'wb+'))

def main(options):
    if not options.reload:
        print("Open " + options.input)
        with open(options.input, "r") as input_file:
            lines = input_file.readlines()
            heat_data = []
            total_toggle = []
            for line in lines:
                vector = list(map(lambda bit: True if bit == "1" else False, line[:-1]))
                heat_data.append(vector)

                step_toggle = list(map(lambda toggle: 1 if toggle else 0, vector))
                if len(total_toggle) == 0:
                    total_toggle.append([0 for i in range(0, len(step_toggle))])
                else:
                    total_toggle.append([sum(i) for i in zip(total_toggle[-1], step_toggle)])

                print(str(len(heat_data)) + "/" + str(len(lines)) + ": " + '{:04.2f}'.format(len(heat_data)/len(lines) * 100) + "%", end="\r")
                # if (len(heat_data) % 10000 == 0):
                #     plt.imshow(heat_data, cmap='hot', interpolation='nearest')
                #     plt.show()

            # print(total_toggle[-1])
            total_toggle_log = adjust_total(total_toggle)
            # https://matplotlib.org/3.5.1/tutorials/colors/colormap-manipulation.html
            fig_step, ax_step = plt.subplots()
            cmp = ListedColormap(["black", "yellow"])
            ax_step.imshow(heat_data, cmap=cmp, interpolation='None')
            save_session(options.name + "_step", heat_data)

            fig_total, ax_total = plt.subplots()
            ax_total.imshow(total_toggle_log, cmap='hot', interpolation='None')
            save_session(options.name + "_total", total_toggle)

    else:
        print("Load " + options.input)
        array = pickle.load(open(options.input, "rb"))
        path = os.path.split(options.input)
        if "_total" in path[-1]:
            draw_array = adjust_total(array)
        else:
            draw_array = array
        _, ax = plt.subplots()
        ax.imshow(draw_array, cmap='hot', interpolation='None')
        plt.show()

if __name__ == '__main__':
    parser = OptionParser(usage="%prog [OPTION] [INPUT FILE]")
    parser.add_option("-o", "--output", dest="output", type="string", help="output directory name")
    parser.add_option("-n", "--name", dest="name", type="string", help="output name")
    parser.add_option("-l", "--label", dest="label", type="string", help="label file")
    parser.add_option("-r", "--reload", dest="reload", action="store_true", default=False, help="reload a matplot session")
    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("Toggle log file is required!")
    elif not options.output and not options.reload:
        parser.error("Output directory name is required!")
    elif not options.name and not options.reload:
        parser.error("Output name is required!")
    options.input = args[0]
    main(options)
