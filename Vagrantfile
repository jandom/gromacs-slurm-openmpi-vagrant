# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

#Define the list of machines
slurm_cluster = {
    :controller => {
        :hostname => "controller",
        :ipaddress => "192.168.0.100"
    },
    :server1 => {
        :hostname => "server1",
        :ipaddress => "192.168.0.101"
    },
    :server2 => {
        :hostname => "server2",
        :ipaddress => "192.168.0.102"
    },
}

$script = <<-SCRIPT
  set -x
  if [[ ! -e /etc/.provisioned ]]; then
    rm /etc/hosts
    echo "192.168.0.100    controller" >> /etc/hosts
    echo "192.168.0.101    server1" >> /etc/hosts
    echo "192.168.0.102    server2" >> /etc/hosts

    apt-get update
    apt-get upgrade -y

    # we only generate the key on one of the nodes
    if [[ ! -e /vagrant/id_rsa ]]; then
      ssh-keygen -t rsa -f /vagrant/id_rsa -N ""
    fi
    install -m 600 -o ubuntu -g ubuntu /vagrant/id_rsa /home/ubuntu/.ssh/
    # the extra 'echo' is needed because Vagrant inserts its own key without a
    # newline at the end
    (echo; cat /vagrant/id_rsa.pub) >> /home/ubuntu/.ssh/authorized_keys

    # install openmpi
    apt-get -y install openmpi-common openmpi-bin libopenmpi-dev openmpi-doc

    # we only generate the munge key once
    if [[ ! -e /vagrant/munge.key ]]; then
      /usr/sbin/create-munge-key
      cp /etc/munge/munge.key /vagrant
    fi
    cp /vagrant/munge.key /etc/munge
    chown munge /etc/munge/munge.key
    chmod g-w /var/log
    chmod g-w /var/log/munge
    sudo systemctl restart munge

    # install slurm
    apt-get install -y -q vim slurm-llnl
    cp /vagrant/slurm.conf /etc/slurm-llnl/slurm.conf

    apt-get install -y gromacs
    touch /etc/.provisioned
  fi
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/xenial64"
  # use a minimal amount of RAM for each node to avoid overwhelming the host
  config.vm.provider "virtualbox" do |v|
    v.memory = 256
    v.cpus = 1
  end
  config.vm.network "private_network", type: "dhcp"

  slurm_cluster.each_pair do |name, options|
    config.vm.define vm_name = name do |config|
      #config.vm.hostname = vm_name
      config.vm.hostname = "#{vm_name}"
      ip = options[:ipaddress]
      config.vm.network "private_network",
        ip: ip,
        virtualbox__intnet: "clusternet"
    end
  end

  config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ['rw', 'vers=3', 'tcp', 'fsc', 'actimeo=1'] # for macos
  config.vm.provision "shell", inline: $script

end
