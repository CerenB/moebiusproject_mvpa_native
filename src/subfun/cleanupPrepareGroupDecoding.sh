#!/bin/bash
# Cleanup script for prepareGroupDecoding.m outputs
# Usage: bash cleanupGroupDecoding.sh [task] [strategy]
# Example: bash cleanupGroupDecoding.sh somatotopy specific

TASK=${1:-somatotopy}
STRATEGY=${2:-specific}
BASE_DIR="/Volumes/extreme/Cerens_files/fMRI/moebius_topo_analyses/outputs/derivatives"

echo "========================================="
echo "Cleaning up prepareGroupDecoding outputs"
echo "Task: $TASK | Strategy: $STRATEGY"
echo "========================================="

# Remove group-level MAT and TSV files
GROUP_DIR="$BASE_DIR/cosmoMvpa/group"
if [ -d "$GROUP_DIR" ]; then
  echo "Removing group-level files..."
  rm -v "$GROUP_DIR/groupDecoding_${TASK}_${STRATEGY}_"*.mat 2>/dev/null
  rm -v "$GROUP_DIR/groupDecoding_${TASK}_${STRATEGY}_"*.tsv 2>/dev/null
fi

# Remove per-subject groupMvpa folders (old location)
STATS_DIR="$BASE_DIR/bidspm-stats"
if [ -d "$STATS_DIR" ]; then
  echo "Removing per-subject groupMvpa folders..."
  find "$STATS_DIR" -type d -name "groupMvpa" -path "*/task-${TASK}_space-*" -exec rm -rfv {} + 2>/dev/null
  
  echo "Removing per-subject prepared files..."
  find "$STATS_DIR" -type f -name "*desc-*4D_*.nii" -path "*/task-${TASK}_space-*" ! -name "*desc-4D_*" -delete -print 2>/dev/null
  find "$STATS_DIR" -type f -name "*desc-*4D_*_labelfold.tsv" -path "*/task-${TASK}_space-*" -delete -print 2>/dev/null
  find "$STATS_DIR" -type f -name "*desc-*3D_*.nii" -path "*/task-${TASK}_space-*" -delete -print 2>/dev/null
  find "$STATS_DIR" -type f -name "*desc-*3D_*_labelfold.tsv" -path "*/task-${TASK}_space-*" -delete -print 2>/dev/null
fi

echo "========================================="
echo "Cleanup complete!"
echo "========================================="
