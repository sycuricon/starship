import os
import datetime
import argparse
import pandas as pd
import plotly.express as px

parse = argparse.ArgumentParser(description="Taint Visualization")
parse.add_argument("-s", "--source", dest="source", default="vcs", help="source of taint data")
args = parse.parse_args()

source = args.source
logfile = f'build/{source}/wave/taint.csv'

print(f"reading {logfile}")
data = pd.read_csv(logfile)
fig = px.line(
    data, x='time', y='taint_sum', 
    title=f"""
        Taint Sum over Time
        <br><sup>{source}, {datetime.datetime.fromtimestamp(os.path.getctime(logfile))}<sup>
    """
    )


annofile = f'build/{source}/wave/event.log'

print(f"reading {annofile}")
with open(annofile, 'r') as file:
    for line in file:
        values = line.strip().split(',')
        type = values[0].strip()
        time = int(values[1].strip())

        match type:
            case "INFO_TRAIN_START":
                fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="yellow", annotation_text="TS", annotation_position="bottom right")
            case "INFO_TRAIN_END":
                fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="yellow", annotation_text="TE", annotation_position="bottom right")
            case "INFO_TRAIN_START_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="yellow", annotation_text="TSC", annotation_position="bottom left")
            case "INFO_TRAIN_END_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="yellow", annotation_text="TEC", annotation_position="bottom left")

            case "INFO_DELAY_START":
                fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="green", annotation_text="DS", annotation_position="top right")
            case "INFO_DELAY_END":
                fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="green", annotation_text="DE", annotation_position="top right")
            case "INFO_DELAY_START_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="green", annotation_text="DSC", annotation_position="top left")
            case "INFO_DELAY_END_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="green", annotation_text="DEC", annotation_position="top left")
            
            case "INFO_TEXE_START":
                fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="blue", annotation_text="ES", annotation_position="top right")
            case "INFO_TEXE_END":
                fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="blue", annotation_text="EE", annotation_position="top right")
            case "INFO_TEXE_START_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="blue", annotation_text="ESC", annotation_position="top left")
            case "INFO_TEXE_END_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="blue", annotation_text="EEC", annotation_position="top left")

            case "INFO_LEAK_START":
                fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="red", annotation_text="LS", annotation_position="bottom right")
            case "INFO_LEAK_END":
                fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="red", annotation_text="LE", annotation_position="bottom right")
            case "INFO_LEAK_START_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="red", annotation_text="LSC", annotation_position="bottom left")
            case "INFO_LEAK_END_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="red", annotation_text="LEC", annotation_position="bottom left")

            case "INFO_VCTM_START":
                fig.add_vline(x=time, line_width=1, line_dash="dot", line_color="black", annotation_text="VS", annotation_position="top right")
            case "INFO_VCTM_END":
                fig.add_vline(x=time, line_width=1, line_dash="dash", line_color="black", annotation_text="VE", annotation_position="top right")
            case "INFO_VCTM_START_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="dashdot", line_color="black", annotation_text="VSC", annotation_position="top left")
            case "INFO_VCTM_END_COMMIT":
                fig.add_vline(x=time, line_width=2, line_dash="solid", line_color="black", annotation_text="VEC", annotation_position="top left")

print("opening figure")
fig.show()
