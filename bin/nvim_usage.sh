#!/bin/bash

# Get the list of processes and filter for relevant ones
process_list=$(ps aux | grep -E 'nvim|tsserver|rust-analyzer|prettier|prismals|eslint' | grep -v grep)

# Calculate unique memory usage by PID
memory_usage=$(echo "$process_list" | awk '{print $2, $6}' | sort -u -k1,1 | awk '{sum += $2} END {printf "%.2f MB\n", sum / 1024}')

echo "$memory_usage"
