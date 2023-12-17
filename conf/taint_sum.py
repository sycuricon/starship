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

data = pd.read_csv(logfile)
fig = px.line(
    data, x='time', y='taint_sum', 
    title=f"""
        Taint Sum over Time
        <br><sup>{source}, {datetime.datetime.fromtimestamp(os.path.getctime(logfile))}<sup>
    """
    )
fig.show()
