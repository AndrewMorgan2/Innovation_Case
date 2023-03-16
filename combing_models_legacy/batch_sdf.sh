#!/bin/sh

#SBATCH --job-name sdf_comb
#SBATCH --nodes 1
#SBATCH --time 00:30:00
#SBATCH --account cosc027924
#SBATCH -o ./logs/log_%j.out # STDOUT out
#SBATCH -e ./logs/log_%j.err # STDERR out
#SBATCH --partition cpu
#SBATCH --mem=30GB

python sdf_combine.py