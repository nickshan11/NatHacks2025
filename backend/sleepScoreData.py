"""
Imports , DataVisualization, Pandas, Matplotlib, Seaborn, Numpy
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import scipy
import scipy.signal as sig
import warnings

warnings.filterwarnings("ignore")
import matplotlib.pyplot as plt
from datetime import datetime, timedelta

from edfio import read_edf

# import sleepecg
from sleepecg import SleepRecord, extract_features

def sleepscore(filename):
    # loading classifier, stages: rem, nrem, and wake
    clf = sleepecg.load_classifier("wrn-gru-mesa", "SleepECG")
    # change lookback and forward if small dataset, shouldn't be needed for whole night data set
    # clf2.feature_extraction_params["lookback"] = 1
    # clf2.feature_extraction_params["lookforward"] = 1


    nightDataEDF = read_edf(filename)


    # crop dataset (we only want data for the sleep duration)
    # start = datetime(2025, 1, 1, 0, 0, 0)
    # stop = datetime(2025, 1, 1, 0, 3, 0)
    # rec_start = datetime.combine(edf2.startdate, edf2.starttime)
    # edf2.slice_between_seconds((start - rec_start).seconds, (stop - rec_start).seconds)
    # edf2.slice_between_seconds(0, edf2.duration)

    rec_start = datetime.combine(nightDataEDF.startdate, nightDataEDF.starttime)
    start = rec_start + timedelta(seconds=0)
    nightDataEDF.slice_between_seconds(0, nightDataEDF.duration)

    # get ECG time series and sampling frequency
    ecg = nightDataEDF.get_signal("ECG").data
    fs = nightDataEDF.get_signal("ECG").sampling_frequency

    # detect heartbeats
    beats = sleepecg.detect_heartbeats(ecg, fs)
    sleepecg.plot_ecg(ecg, fs, beats=beats)


    # predict sleep stages
    record = sleepecg.SleepRecord(
        sleep_stage_duration=30,
        # ecording_start_time=start2,
        heartbeat_times=beats / fs,
    )

    stages = sleepecg.stage(clf, record, return_mode="prob")

    sleepecg.plot_hypnogram(
        record,
        stages,
        stages_mode=clf.stages_mode,
        merge_annotations=True,
    )
    return stages
