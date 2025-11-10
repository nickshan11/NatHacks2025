import csv
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import find_peaks
import os

# --- Configuration ---
FILENAME = os.path.join(os.path.dirname(os.path.abspath(__file__)),"working.csv")  # your uploaded file
CHANNEL = 0
SAMPLING_RATE = 125  # Hz (adjust if needed)
PEAK_HEIGHT_FACTOR = 2.5

# --- Load CSV ---
data = np.genfromtxt(FILENAME, delimiter=',', names=True)
times = data['ElapsedTime']
ecg = data[f'CH{CHANNEL}']

# --- Preprocess ---
ecg = ecg - np.mean(ecg)
threshold = np.std(ecg) * PEAK_HEIGHT_FACTOR

# --- R-peak detection ---
peaks, props = find_peaks(ecg, distance=int(0.3 * SAMPLING_RATE), height=threshold)

# --- Compute RR intervals (filter invalid ones) ---
if len(peaks) > 1:
    rr_intervals = np.diff(peaks) / SAMPLING_RATE
    rr_intervals = rr_intervals[rr_intervals > 0]  # remove zeros
    if len(rr_intervals) == 0:
        raise ValueError("No valid RR intervals found (all were zero).")
    hr_bpm = 60.0 / rr_intervals
else:
    raise ValueError("Not enough peaks detected to compute RR intervals.")

# --- Save output ---
out_name = FILENAME.replace(".csv", "_rr.csv")
with open(out_name, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Time_s", "R_index", "RR_interval_s", "HR_BPM"])
    for i in range(1, len(peaks)):
        rr = (peaks[i] - peaks[i-1]) / SAMPLING_RATE
        if rr > 0:
            writer.writerow([times[peaks[i]], peaks[i], rr, 60.0 / rr])

print(f"Detected {len(peaks)} R-peaks")
print(f"Average HR: {np.mean(hr_bpm):.1f} BPM")
print(f"Saved results to {out_name}")

# --- Plot ---
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 6))
ax1.plot(times, ecg, label="ECG (CH0)")
ax1.plot(times[peaks], ecg[peaks], "rx", label="R-peaks")
ax1.set_title("ECG with R-peaks")
ax1.set_ylabel("Amplitude")
ax1.legend()

ax2.plot(times[peaks[1:]], hr_bpm, label="Instant HR (BPM)")
ax2.set_xlabel("Time (s)")
ax2.set_ylabel("Heart Rate (BPM)")
ax2.legend()
plt.tight_layout()
plt.show()
