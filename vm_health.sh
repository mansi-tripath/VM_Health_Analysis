#!/bin/bash

# VM Health Check Script for Ubuntu
# Analyzes CPU, memory, and disk usage to determine VM health status

EXPLAIN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        explain)
            EXPLAIN=true
            shift
            ;;
        *)
            echo "Usage: $0 [explain]"
            exit 1
            ;;
    esac
done

THRESHOLD=60

# Get CPU usage (idle percentage, convert to used)
CPU_IDLE=$(top -bn1 | grep -i "cpu" | grep -v "CPU" | head -1 | awk '{print $8}' | sed 's/%//' | cut -d'.' -f1)
if [ -z "$CPU_IDLE" ] || ! [[ "$CPU_IDLE" =~ ^[0-9]+$ ]]; then
    CPU_IDLE=100
fi
CPU_USAGE=$((100 - CPU_IDLE))

# Get memory usage
MEM_INFO=$(free | grep Mem)
MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
MEM_USAGE=$((MEM_USED * 100 / MEM_TOTAL))

# Get disk usage for root partition
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

# Determine health status
HEALTHY=true
REASONS=()

if [ -n "$CPU_USAGE" ] && [ "$CPU_USAGE" -gt "$THRESHOLD" ] 2>/dev/null; then
    HEALTHY=false
    REASONS+=("CPU usage is ${CPU_USAGE}% (threshold: ${THRESHOLD}%)")
fi

if [ -n "$MEM_USAGE" ] && [ "$MEM_USAGE" -gt "$THRESHOLD" ] 2>/dev/null; then
    HEALTHY=false
    REASONS+=("Memory usage is ${MEM_USAGE}% (threshold: ${THRESHOLD}%)")
fi

if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -gt "$THRESHOLD" ] 2>/dev/null; then
    HEALTHY=false
    REASONS+=("Disk usage is ${DISK_USAGE}% (threshold: ${THRESHOLD}%)")
fi

# Output results
if [ "$HEALTHY" = true ]; then
    echo "Health Status: HEALTHY"
    if [ "$EXPLAIN" = true ]; then
        echo ""
        echo "Reason: All resources are below the ${THRESHOLD}% threshold"
        echo "  - CPU usage: ${CPU_USAGE}%"
        echo "  - Memory usage: ${MEM_USAGE}%"
        echo "  - Disk usage: ${DISK_USAGE}%"
    fi
else
    echo "Health Status: NOT HEALTHY"
    if [ "$EXPLAIN" = true ]; then
        echo ""
        echo "Reasons:"
        for reason in "${REASONS[@]}"; do
            echo "  - $reason"
        done
    fi
fi
