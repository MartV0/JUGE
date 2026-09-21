#!/usr/bin/env bash

# Check if the directory is provided
if [[ -z "$1" ]]; then
    echo "Error: Result directory not provided"
    echo "Usage: $0 <result directory>"
    exit 1
fi

cd "$1" || exit

time_pattern="^([0-9]{2}):([0-9]{2}):([0-9]{2}).([0-9]{3}) .*$"
# default value that gets used when data is missing or not applicable
default="-"
header="targets,infeasible,uncovered,covered,lastCoverageTime,totalTime"
# Takes a log entry and converts the time to seconds since 00:00
time_to_seconds() {
    if [[ -n "$1" ]]; then
        hour=$(echo "$1" | sed -E "s/$time_pattern/\1/")
        minute=$(echo "$1" | sed -E "s/$time_pattern/\2/")
        second=$(echo "$1" | sed -E "s/$time_pattern/\3/")
        ms=$(echo "$1" | sed -E "s/$time_pattern/\4/")
        echo "scale=3;($hour * 60 + $minute) * 60 + $second + $ms/1000" | bc
    else
        echo "$default"
    fi
}

output() {
    transcript_file="$1"
    values="$2"
    # Add the extra columns to the end of the transcript file
    sed -i "1s/\$/,$header/" "$transcript_file"
    sed -i "2s/\$/,$values/" "$transcript_file"
}

log_name="maze.log"
transcript_name="transcript.csv"
default_values=$(echo "$header" | sed -E "s/[^,]*(,|$)/$default\1/g")

analyze_log() {
    dir="$1"
    # dir already contains a trailing /
    transcript_file="$dir$transcript_name"

    if [[ ! -f "$transcript_file" ]]; then
        echo "Warning: transcript.csv missing"
        return 1
    fi

    # dir already contains a trailing /
    log_file="$dir$log_name"
    if [[ ! -f "$log_file" ]]; then
        output "$transcript_file" "$default_values"
        return 0
    fi

    log=$(cat "$log_file")

    strategy_pattern="^.*Using search strategy: (.*)$"
    strategy=$(echo "$log" | grep -E "$strategy_pattern" | sed -E "s/$strategy_pattern/\1/")

    if [[ $strategy == "PathStrategy"* ]]; then
        added_pattern="^.*Added ([0-9]*) path targets, ([0-9]*) paths infeasible"
        uncovered_pattern="^.* ([0-9]*) Uncovered target paths"
        covered_pattern="Covered prime path(s)"
    elif [[ $strategy == "BasisPathStrategy" ]]; then
        added_pattern="^.*Added new target with cyclomatic complexity ([0-9]*)"
        uncovered_pattern="^.* ([0-9]*) too few independent paths in basis sets"
        covered_pattern="Found new independent vector"
    else
        output "$transcript_file" "$default_values"
        return 0
    fi

    added=$(echo "$log" | grep -E "$added_pattern")
    if [[ -n "$added" ]]; then
        targets=$(echo "$added" | sed -E "s/$added_pattern/\1/" | paste -sd+ | bc)
        if [[ $strategy == "PathStrategy"* ]]; then
            infeasible=$(echo "$added" | sed -E "s/$added_pattern/\2/" | paste -sd+ | bc)
        else
            infeasible="$default"
        fi
    else
        targets="$default"
        infeasible="$default"
    fi

    uncovered=$(echo "$log" | grep -E "$uncovered_pattern" | sed -E "s/$uncovered_pattern/\1/")
    if [[ -z "$uncovered" ]]; then
        uncovered="$default"
    fi

    last_coverage=$(time_to_seconds "$(echo "$log" | grep "$covered_pattern" | tail -1)")
    start_time=$(time_to_seconds "$(echo "$log" | grep -E "$time_pattern" | head -1)")
    end_time=$(time_to_seconds "$(echo "$log" | grep -E "$time_pattern" | tail -1)")
    last_coverage_time=$(echo "$last_coverage - $start_time" | bc)
    total_time=$(echo "$end_time - $start_time" | bc)

    covered=$(echo "$targets - $uncovered" | bc)

    # echo "uncovered:$uncovered"
    # echo "file:$log_file"
    output "$transcript_file" "$targets,$infeasible,$uncovered,$covered,$last_coverage_time,$total_time"
}
 
for dir in */
do
    analyze_log "$dir"
done
