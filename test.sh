#!/bin/bash
#SBATCH -p debug
#SBATCH --nodes 2
#SBATCH --tasks-per-node 1
#SBATCH -t 12:00:00
#SBATCH -J test_job
#SBATCH -o test_job.out

echo "Running hostname with $SLURM_NTASKS MPI tasks"
echo "Nodelist: $SLURM_NODELIST"

mpirun -np $SLURM_NTASKS --mca oob_tcp_if_include enp0s9 \
    hostname
