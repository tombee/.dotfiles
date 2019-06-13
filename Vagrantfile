# -*- mode: ruby -*-
# vi: set ft=ruby :

if Vagrant::Util::Platform.windows? then
  def running_in_admin_mode?
    (`reg query HKU\\S-1-5-19 2>&1` =~ /ERROR/).nil?
  end
 
  unless running_in_admin_mode?
    puts "This vagrant makes use of SymLinks to the host. On Windows, Administrative privileges are required to create symlinks (mklink.exe). Try again from an Administrative command prompt."
    exit 1
  end
end

# Check SSH keys are installed
ssh_dir = File.expand_path("~/.ssh")
if File.directory?(ssh_dir)
  if !File.file?(File.join(ssh_dir, "id_rsa"))
    abort "#{ssh_dir}/id_rsa does not exist, please create this before continuing"
  end
  if !File.file?(File.join(ssh_dir, "id_rsa.pub"))
    abort "#{ssh_dir}/id_rsa.pub does not exist, please create this before continuing"
  end
else
  abort "#{ssh_dir} does not exist, please create this and include your id_rsa and id_rsa.pub before continuing"
end

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/cosmic64"
  config.disksize.size = '50GB'
  config.vm.boot_timeout = 600

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = 4  
    vb.memory = "8192"
  end

  # Add any forwarded ports required here
  config.vm.network :forwarded_port, guest: 22, host_ip: "127.0.0.1", host: 22, id: "ssh"
  
  username = "#{ENV['USERNAME'] || `whoami`}"
  uid = 1337

  # Create a user matching the username on the host
  config.vm.provision "shell", inline: <<-SHELL
    if grep "#{username}" /etc/passwd >/dev/null 2>&1; then
      echo "#{username} already created"
      exit 0
    fi

    echo "creating user #{username} with home directory /home/#{username}"
    useradd -m -s /bin/bash -U #{username} -u #{uid}
    ln -snf /vagrant /home/#{username}/.dotfiles
    chown -R #{username}:#{username} /home/#{username}

    echo "configuring #{username} for sudo"
    gpasswd -a "#{username}" sudo
    echo "#{username} ALL=(ALL) NOPASSWD:ALL" > "/tmp/sudo_#{username}"
    echo "#{username} ALL=NOPASSWD: /bin/mount, /sbin/mount.nfs, /bin/umount, /sbin/umount.nfs, /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery, /sbin/mount.cifs, /sbin/umount.cifs" >> "/tmp/sudo_$USER_NAME"
    visudo -c -f "/tmp/sudo_#{username}"
    cp "/tmp/sudo_#{username}" /etc/sudoers.d/
    exit 0
  SHELL
  
  # If ~/workspace directory exists, sync this to the vm
  if File.directory?(File.expand_path("~/workspace"))
    config.vm.synced_folder "~/workspace", "/home/#{username}/workspace", id: "workspace", owner: uid, group: uid, mount_options: ["umask=0077"]
  end

  # Set up ssh keys on guest
  config.vm.provision "shell" do |s|
    ssh_prv_key = File.read("#{Dir.home}/.ssh/id_rsa")
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      if grep -sq "#{ssh_pub_key}" /home/#{username}/.ssh/authorized_keys; then
        echo "SSH keys already provisioned."
        exit 0
      fi
      echo "copying ssh keys from host to /home/#{username}/.ssh"
      mkdir -p /home/#{username}/.ssh/
      touch /home/#{username}/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /home/#{username}/.ssh/authorized_keys
      echo #{ssh_pub_key} > /home/#{username}/.ssh/id_rsa.pub
      chmod 644 /home/#{username}/.ssh/id_rsa.pub
      echo "#{ssh_prv_key}" > /home/#{username}/.ssh/id_rsa
      chmod 600 /home/#{username}/.ssh/id_rsa
      chown -R #{username}:#{username} /home/#{username}/.ssh
      exit 0
    SHELL
  end

  # Install system packages and dotfiles
  config.vm.provision "shell", path: "install.sh", args: username

end
