#!/bin/bash

# Define benchmark configurations. Each config is a tuple: (s, e).
#
#    s : search strategy or strategies (separated by comma, no space!)
#    e (optional): extra arguments for the search strategy
#

BENCHMARKS=(
    "DFS"
    "BFS"
    "SGS"
    "RPS,COS"
    "FOS"
    "FOS,COS"
    "PP" "d,b,h"
)

# Check if the time budget is provided
if [[ -z "$1" ]]; then
    echo "Error: Time budget not provided"
    echo "Usage: $0 <time_budget_in_seconds>"
    exit 1
fi

TIME_BUDGET="$1"

# Loop through each benchmark pair
for benchmark in "${BENCHMARKS[@]}"; do
    strategy=$(echo "$benchmark" | awk '{print $1}')
    extraArgs=$(echo "$benchmark" | awk '{print $2}')

    echo "-----------------------------------"
    echo "Running benchmark with strategy:$strategy", extra-search-arg:$extraArgs
    echo "-----------------------------------"

    # Update the runtool file to set search strategy and concrete-driven mode
    cat > "./runtool" << EOF
#!/bin/bash

java -cp lib/maze_runtool-1.0.0.jar sbst.runtool.Main "$strategy" "$extraArgs"
EOF
    chmod +x "./runtool"

    #concrete_name="SD"
    #if [ "$concrete" == "true" ]; then
    #    concrete_name="CD"
    #fi
    #name="maze-${strategy//,/+}-${concrete_name}"
    name="maze-${strategy//,/+}"
    echo "Generating tests for $name with time budget $TIME_BUDGET"
    contest_generate_tests.sh "$name" 10 1 $TIME_BUDGET > state_log.txt 2> error_log.txt

    echo "Computing metrics for $name with time budget $TIME_BUDGET"
    contest_compute_metrics.sh results_"$name"_"$TIME_BUDGET" > state_log.txt 2> error_log.txt

    echo "Finished benchmark $name"
    echo "-----------------------------------"
done

# Clean up
cp ./orig-runtool ./runtool
chmod +x ./runtool
echo "All benchmarks completed!"
