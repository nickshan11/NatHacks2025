import pandas as pd
import numpy as np
import pyedflib


def CSVtoEDF(fileName):
    # Load ECG values
    df = pd.read_csv(fileName, header=None)
    ecg_signal = df.iloc[1:, 0].values.astype(np.float64)

    # Define sampling rate (Hz) — must be known or estimated
    fs = 250  # Change this to your actual sampling frequency

    # Create EDF writer
    output_file = "ourECG.edf"
    f = pyedflib.EdfWriter(
        output_file, n_channels=1, file_type=pyedflib.FILETYPE_EDFPLUS
    )

    # Channel metadata
    channel_info = [
        {
            "label": "ECG",
            "dimension": "uV",  # or mV, arbitrary units, etc.
            "sample_frequency": fs,
            "physical_min": np.min(ecg_signal),
            "physical_max": np.max(ecg_signal),
            "digital_min": -32768,
            "digital_max": 32767,
            "transducer": "",
            "prefilter": "",
        }
    ]

    # Set header and write data
    f.setSignalHeaders(channel_info)
    f.writeSamples([ecg_signal])
    f.close()

    print(f"✅ EDF file saved as {output_file}")
