# we have a list of lists
# sub-lists are formatted [unknown, nrem, rem, awake]

my_input = [[6.7717599e-04, 2.5841177e-01, 2.5973726e-02, 7.1493727e-01], 
            [2.6535531e-04, 2.5332743e-01, 1.7589109e-02, 7.2881818e-01],
            [1.8706617e-04, 2.2932185e-01, 1.5328194e-02, 7.5516295e-01],
            [2.3121174e-04, 2.1493009e-01, 1.6798854e-02, 7.6803988e-01],
            [4.4561972e-04, 2.0256965e-01, 2.3033723e-02, 7.7395099e-01]]

# in seconds
time_interval = 1

count = [0,0,0,0]

for row in my_input:
    index_max = row.index(max(row))
    count[index_max] += 1

sub_scores = {}

# calculate total sleep time score
total_sleep_time = len(my_input)*time_interval # time in seconds
total_sleep_score = min(100, 100/(9*3600) * total_sleep_time) 
sub_scores["total_sleep_score"] = total_sleep_score
# 9*3600 = 9 hours of sleep


# calculate nrem score
nrem_sleep_time = count[1]*time_interval
nrem_score = 0
if nrem_sleep_time < 5580:
    nrem_score = 95/5580 * nrem_sleep_time
else:
    nrem_score = min(100, ((100-95) / (8670-5580))+86)
sub_scores["nrem_score"] = nrem_score

# calculate rem score
rem_sleep_time = count[2]*time_interval
rem_score = 0
if rem_sleep_time < 6690:
    rem_score = 95/6690 * rem_sleep_time
else:
    rem_score = min(100, ((100-95) / (8820-6690))+79.3)
sub_scores["rem_score"] = rem_score

"""
sleep efficiency -- time asleep/total time in bed
sleep latency -- time from enabling "sleep state" to actually falling asleep --> hrv
sleep timing -- closeness of enabling "sleep state" to "good" times to sleep 
"""

weights = {
        'total_sleep_score': 0.6,
        # 'restfulness_score': 0.15,
        # 'efficiency_score': 0.10,
        # 'latency_score': 0.10,
        'nrem_score': 0.15,
        'rem_score': 0.25,
        # 'timing_score': 0.10
    }

final_score = sum(sub_scores[score] * weight for score, weight in weights)

