#!/bin/bash
#SBATCH -p debug
#SBATCH -N 2
#SBATCH --tasks-per-node 1
#SBATCH -t 12:00:00
#SBATCH -J gromacs_job
#SBATCH -o gromacs_job.out

echo "Running Gromacs 5.x with $SLURM_NTASKS MPI tasks"
echo "Nodelist: $SLURM_NODELIST"

mpirun -np 2 --mca oob_tcp_if_include enp0s9 gmx mdrun -h
