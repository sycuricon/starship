import os
import datetime
import argparse
import pandas as pd
import plotly.express as px
from plotly.subplots import make_subplots
import plotly.graph_objects as go

def getTargetFileList(path):
    file_list = []
    all_file = os.listdir(path)
    for i in all_file:
        if os.path.splitext(i)[1] == '.log':
            file_list.append(os.path.splitext(i)[0])
        
    return file_list


def getTargetList(file_list):
    target = set()
    for i in file_list:
        target.add(i.split('.')[0])
    return target

def genHTMLOutputFileName(target, simulator):
    return f"build/{simulator}/{target}.html"

def genTaintLogFileName(target, simulator):
    return f"build/{simulator}/wave/{target}.csv"

def genEventLogFileName(target, simulator):
    return f"build/{simulator}/wave/{target}.log"

def main():
    parse = argparse.ArgumentParser(description="Taint Visualization")
    parse.add_argument("-s", "--source", dest="source", default="vcs", help="source of taint data")
    parse.add_argument("-q", "--quite", dest="quite", action="store_true", help="quite mode, don't open browser")
    args = parse.parse_args()

    source = "verilator" if args.source == "vlt" else args.source
    target_file_list = sorted(getTargetFileList(f'build/{source}/wave'))

    targets = sorted(getTargetList(target_file_list))
    print(f"find targets: {targets}")

    for target in targets:
        print(f"processing {target}")
        selected_rounds = [round for round in target_file_list if round.startswith(target)]

        output_file = genHTMLOutputFileName(target, source)
        tlog_file_list = [genTaintLogFileName(round, source) for round in selected_rounds]
        elog_file_list = [genEventLogFileName(round, source) for round in selected_rounds]
       
        if (os.path.exists(output_file)):
            simulation_timestamp = [os.path.getmtime(file) for file in tlog_file_list]
            if any(sim_time < os.path.getmtime(output_file) for sim_time in simulation_timestamp):
                print("Already have output HTML, ignore")
                continue

        fig = make_subplots(rows=len(selected_rounds), cols=1, shared_xaxes=True, subplot_titles=selected_rounds)

        for i, (tlog, elog) in enumerate(zip(tlog_file_list, elog_file_list)):

            print(f"reading {tlog}")
            data = pd.read_csv(tlog)
            fig.add_trace(
                go.Scatter(x=data['time'], y=data['base'], name="base"),
                row=i + 1, col=1
            )
            fig.add_trace(
                go.Scatter(x=data['time'], y=data['variant'], name="vrnt"),
                row=i + 1, col=1
            )
            
            print(f"reading {elog}")
            with open(elog, 'r') as file:
                for line in file:
                    values = line.strip().split(',')
                    type = values[0].strip()
                    time = int(values[1].strip())
                    match type:
                        case "INFO_VCTM_START":
                            fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="black", annotation_text="VS", annotation_position="top right", row=i + 1, col=1)
                        case "INFO_VCTM_END":
                            fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="black", annotation_text="VE", annotation_position="top right", row=i + 1, col=1)
                        case "INFO_VCTM_START_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="black", annotation_text="VSC", annotation_position="top left", row=i + 1, col=1)
                        case "INFO_VCTM_END_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="black", annotation_text="VEC", annotation_position="top left", row=i + 1, col=1)

                        case "INFO_DELAY_START":
                            fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="green", annotation_text="DS", annotation_position="top right", row=i + 1, col=1)
                        case "INFO_DELAY_END":
                            fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="green", annotation_text="DE", annotation_position="top right", row=i + 1, col=1)
                        case "INFO_DELAY_START_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="green", annotation_text="DSC", annotation_position="top left", row=i + 1, col=1)
                        case "INFO_DELAY_END_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="green", annotation_text="DEC", annotation_position="top left", row=i + 1, col=1)
                        
                        case "INFO_TEXE_START":
                            fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="red", annotation_text="ES", annotation_position="top right", row=i + 1, col=1)
                        case "INFO_TEXE_END":
                            fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="red", annotation_text="EE", annotation_position="top right", row=i + 1, col=1)
                        case "INFO_TEXE_START_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="red", annotation_text="ESC", annotation_position="top left", row=i + 1, col=1)
                        case "INFO_TEXE_END_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="red", annotation_text="EEC", annotation_position="top left", row=i + 1, col=1)

                        case "INFO_LEAK_START":
                            fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="blue", annotation_text="LS", annotation_position="bottom right", row=i + 1, col=1)
                        case "INFO_LEAK_END":
                            fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="blue", annotation_text="LE", annotation_position="bottom right", row=i + 1, col=1)
                        case "INFO_LEAK_START_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="blue", annotation_text="LSC", annotation_position="bottom left", row=i + 1, col=1)
                        case "INFO_LEAK_END_COMMIT":
                            fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="blue", annotation_text="LEC", annotation_position="bottom left", row=i + 1, col=1)

        fig.update_layout(title_text=f"""
            Taint Sum over Time
            <br><sup>{source}, {datetime.datetime.fromtimestamp(os.path.getctime(tlog))}<sup>
        """)

        print(f"saving {output_file}")
        fig.write_html(file=output_file, full_html=True, auto_open=not args.quite)

if __name__ == "__main__":
    main()
