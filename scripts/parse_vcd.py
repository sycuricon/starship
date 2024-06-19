#! /usr/bin/env python3

import os
import argparse
from vcdvcd import VCDVCD
import plotly.express as px
from plotly.subplots import make_subplots
import plotly.graph_objects as go
import hjson

def draw(fig, dut_tv, vnt_tv, idx):
    dut_t = [x[0] for x in dut_tv]
    dut_v = [x[1] for x in dut_tv]
    fig.add_trace(go.Scatter(x=dut_t, y=dut_v, name="dut"), row=idx+1, col=1)

    vnt_t = [x[0] for x in vnt_tv]
    vnt_v = [x[1] for x in vnt_tv]
    fig.add_trace(go.Scatter(x=vnt_t, y=vnt_v, name="vnt"), row=idx+1, col=1)

def expand_trace(tv, max_cycle):
    new_tv = []
    last_cycle = tv[0][0]/100
    last_value = int(tv[0][1], 2)

    for t, v in tv[1:]:
        time = t/100
        value = int(v, 2)
        
        while last_cycle < time:
            new_tv.append((last_cycle, last_value))
            last_cycle += 1
        
        if last_cycle != time:
            new_tv.append((time, value))

        last_value = value
    
    while last_cycle < max_cycle:
        new_tv.append((last_cycle, last_value))
        last_cycle += 1

    return new_tv

def process_signal(raw_signal_list, vcd):
    signal_list = []
    max_cycle = 0
    for signal in raw_signal_list:
        max_cycle = max(max_cycle, vcd[signal].tv[-1][0]/100)

        # for xiangshan
        if signal.find("l2") != -1:
            continue

        if signal.find("Testbench.testHarness.ldut") != -1:
            vnt_signal = signal.replace("testHarness", "testHarness_variant")
            if len(vcd[signal].tv) != 1 or len(vcd[vnt_signal].tv) != 1:
                signal_list.append(signal)

    # bleed
    max_cycle += 10

    for dut_signal in signal_list:
        vnt_signal = dut_signal.replace("testHarness", "testHarness_variant")
        vcd[dut_signal].tv = expand_trace(vcd[dut_signal].tv, max_cycle)
        vcd[vnt_signal].tv = expand_trace(vcd[vnt_signal].tv, max_cycle)

    return signal_list

def main(args):
    print(f"[*] Parsing VCD file: {args.input}")
    vcd = VCDVCD(args.input)
    raw_signal_list = sorted(vcd.references_to_ids.keys())

    signal_list = process_signal(raw_signal_list, vcd)
    signal_name_list = ["/".join(s.split(".")[5:-1]) for s in signal_list]

    potential_leakage = {}

    if len(signal_list) > 0:
        fig = make_subplots(
            rows=len(signal_list), cols=1, 
            subplot_titles=(signal_name_list),
            shared_xaxes=True
        )

        for i, signal in enumerate(signal_list):
            dut_signal = signal
            vnt_signal = dut_signal.replace("testHarness", "testHarness_variant")
            dut_tv = vcd[dut_signal].tv
            vnt_tv = vcd[vnt_signal].tv

            draw(fig, dut_tv, vnt_tv, i)

            if (dut_tv[-1][1] > 0):
                print(f"[!] catch {signal_name_list[i]}: {dut_tv[-1][1]}")
                potential_leakage[signal_name_list[i]] = dut_tv[-1][1]

        fig.update_layout(height=len(signal_list)*200, title_text="Taint Analysis")
        fig.write_html(args.output)

        with open(args.leak, "w") as leak_list:
            hjson.dump(potential_leakage, leak_list)
        

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Taint Analysis")

    parser.add_argument(
        "-i", "--input", type=str, required=True, help="input vcd file"
    )
    parser.add_argument(
        "-o", "--output", type=str, default="build/analysis.html", help="output plot name"
    )
    parser.add_argument(
        "-l", "--leak", type=str, default="build/analysis.hjson", help="potential leakage signal list"
    )

    args = parser.parse_args()
    args.output = os.path.abspath(args.output)
    if not os.path.exists(os.path.dirname(args.output)):
            os.makedirs(os.path.dirname(args.output), exist_ok=True)
    main(args)
