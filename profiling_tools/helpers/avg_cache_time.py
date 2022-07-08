import re
import sys

def parseFile(results, file_name):
    file_channel = open(file_name, 'r')
    lines = file_channel.readlines()

    for line in lines:
        s = line.split("\t")
        s1 = re.split("m|s", s[1])
        results[s[0]].append(float(s1[0]) * 60 + float(s1[1]))

if __name__ == "__main__":
    results = {"cold" : {"real" : [], "user" : [], "sys" : []},
            "warm" : {"real" : [], "user" : [], "sys" : []},
            "hot" : {"real" : [], "user" : [], "sys" : []}}
    results_avg = {"cold" : {"real" : 0, "user" : 0, "sys" : 0},
            "warm" : {"real" : 0, "user" : 0, "sys" : 0},
            "hot" : {"real" : 0, "user" : 0, "sys" : 0}}
    ratios_avg = {"cold / hot" : {"real" : 0, "user" : 0, "sys" : 0},
            "cold / warm" : {"real" : 0, "user" : 0, "sys" : 0},
            "warm / hot" : {"real" : 0, "user" : 0, "sys" : 0}}
    best_ratio_estimator_1 = {"cold" : [0, 0], "warm" : [0, 0], "hot" : [0, 0]}
    best_ratio_estimator_2 = {"cold / hot" : {"real" : [0, 0], "user" : [0, 0], "sys" : [0, 0]},
            "cold / warm" : {"real" : [0, 0], "user" : [0, 0], "sys" : [0, 0]},
            "warm / hot" : {"real" : [0, 0], "user" : [0, 0], "sys" : [0, 0]}}

    rounds = int(sys.argv[1])

    parseFile(results["cold"], "tmp/cold_results")
    parseFile(results["warm"], "tmp/warm_results")
    parseFile(results["hot"], "tmp/hot_results")

    # Compute average times
    for cache_type in results_avg.keys():
        for time_type in results_avg[cache_type].keys():
            for i in range(rounds):
                results_avg[cache_type][time_type] += results[cache_type][time_type][i]
            results_avg[cache_type][time_type] /= rounds
    print("{:<20} {:<15} {:<15} {:<15}".format("Cache_Type","Real Avg","User Avg", "Sys Avg"))
    for cache_type in results_avg.keys():
        print("{:<20} {:<15.3f} {:<15.3f} {:<15.3f}".format(cache_type, results_avg[cache_type]["real"], results_avg[cache_type]["user"], results_avg[cache_type]["sys"]))

    print("-----------------------------------------------------------")

    # Compute time percantage on CPU and blocked
    for i in range(rounds):
        for cache_type in results_avg.keys():
            best_ratio_estimator_1[cache_type][0] += (results[cache_type]["user"][i] + results[cache_type]["sys"][i]) *  results[cache_type]["real"][i]
            best_ratio_estimator_1[cache_type][1] += results[cache_type]["real"][i] * results[cache_type]["real"][i]
    print("{:<20} {:<15} {:<15}".format("Cache_Type","CPU %","BLOCKED %"))
    for cache_type in results_avg.keys():
        cpu_percentage = best_ratio_estimator_1[cache_type][0] / best_ratio_estimator_1[cache_type][1]
        blocked_percentage = 1.0 - best_ratio_estimator_1[cache_type][0] / best_ratio_estimator_1[cache_type][1]
        print("{:<20} {:<15.3f} {:<15.3f}".format(cache_type, cpu_percentage, blocked_percentage))
    
    print("-----------------------------------------------------------")

    # Compute average ratios between different type of caches
    for compare_case in ratios_avg.keys():
        for time_type in ratios_avg[compare_case].keys():
            for i in range(rounds):
                best_ratio_estimator_2[compare_case][time_type][0] += results[compare_case.split(" / ")[0]][time_type][i] * results[compare_case.split(" / ")[1]][time_type][i]
                best_ratio_estimator_2[compare_case][time_type][1] += results[compare_case.split(" / ")[1]][time_type][i] * results[compare_case.split(" / ")[1]][time_type][i]
            ratios_avg[compare_case][time_type] = best_ratio_estimator_2[compare_case][time_type][0] / best_ratio_estimator_2[compare_case][time_type][1]
    print("{:<20} {:<15} {:<15} {:<15}".format('Compare Case','Real Time','User Time', 'Sys Time'))
    for compare_case in ratios_avg.keys():
        print("{:<20} {:<15.3f} {:<15.3f} {:<15.3f}".format(compare_case, ratios_avg[compare_case]["real"], ratios_avg[compare_case]["user"], ratios_avg[compare_case]["sys"]))
