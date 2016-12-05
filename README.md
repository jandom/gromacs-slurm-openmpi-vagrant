# MPI Cluster Vagrantfile, with SLURM and GROMACS 5.x

Heavily based on (https://github.com/mrahtz/mpi-vagrant)

This is a Vagrantfile (to be used with HashiCorp's
[Vagrant](https://vagrantcloud.com/) tool) for automatically bringing up
a cluster suitable for testing MPI loads.

Practically, all this involves is bringing up several VMs on a private network,
setting up SSH key-based authentication between them, and installing OpenMPI.

Currently only works with the VirtualBox provider.

## Usage

In your checkout directory, simply run:
```
$ vagrant up
```
By default, the cluster will be made of 3 VMs: one controller and 2 worker nodes.
If you want more, change `slurm_cluster` in the `Vagrantfile`.

The VMs will be named `server1` through `server<n>`. To SSH to, say, `server1`:
```
$ vagrant ssh server1
```

As a simple sanity check, try running `hostname` on each machine in the
cluster:
```
ubuntu@server1:~$ mpirun -np 3 --host server1,server2,server3 hostname
```
Note that OpenMPI will try to use all networks it thinks are common
to all hosts for any inter-node communication, including Vagrant's
host-only networks. To work around this, you should tell `mpirun` explicitly
which networks to use:

Identify the interface shared by the nodes

```
ubuntu@server1:~$ ifconfig
...
enp0s9    Link encap:Ethernet  HWaddr 08:00:27:7a:d5:5d  
          inet addr:192.168.0.101  Bcast:192.168.0.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe7a:d55d/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:180 errors:0 dropped:0 overruns:0 frame:0
          TX packets:202 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:32273 (32.2 KB)  TX bytes:36325 (36.3 KB)
...
```

And use the --mca flag to only use that interface

```
ubuntu@controller:~$ mpirun -np 2 --host server1,server2 --mca oob_tcp_if_include enp0s9 hostname
```
For more detail, see http://www.open-mpi.org/faq/?category=tcp#tcp-selection.

Another sanity test is to see if we can print the help message for gromacs in parallel
```
ubuntu@controller:~$ mpirun -np 2 --host server1,server2 --mca oob_tcp_if_include enp0s9 gmx mdrun -h
```

Let's launch slurm deamon and workers

```
vagrant ssh controller -c 'sudo systemctl start slurmctld'
vagrant ssh server1 -c 'sudo systemctl start slurmd'
vagrant ssh server2 -c 'sudo systemctl start slurmd'
```

Inspect if the partition is responsive

```
ubuntu@controller:~$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug*       up   infinite      2   idle server[1-2]
```

Submit a simple one-line command
```
ubuntu@controller:~$ srun -N2 -l '/bin/hostname'
1: server2
0: server1
```

Submit a test slurm job from /vagrant to allow output files shared over NFS
```
ubuntu@controller:/vagrant$ sbatch test.sh
ubuntu@controller:/vagrant$ cat test_job.out
Running hostname with 2 MPI tasks
Nodelist: server[1-2]
server1
server2

```

Submit a test gromacs job
```
ubuntu@controller:/vagrant$ sbatch gromacs.sh
ubuntu@controller:/vagrant$ cat gromacs_job.out | head
Running Gromacs 5.x with 2 MPI tasks
Nodelist: server[1-2]
                   :-) GROMACS - gmx mdrun, VERSION 5.1.2 (-:

                            GROMACS is written by:
     Emile Apol                       :-) GROMACS - gmx mdrun, VERSION 5.1.2 (-:

                            GROMACS is written by:
     Emile Apol      Rossen Apostolov  Herman J.C. Berendsen    Par Bjelkmar   
 Aldert van Buuren   Rudi van Drunen     Anton Feenstra   Sebastian Fritsch

```
