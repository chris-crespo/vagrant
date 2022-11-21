# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  DOMAIN = "aula104.local"
  RED = "192.168.1"
  DNSIP = "#{RED}.2"
  LAB = "bind9"

  $dnsclient = <<-SHELL
    echo "nameserver $1\ndomain $2" > /etc/resolv.conf
  SHELL

  config.vm.box = "ubuntu/focal64"

  config.vm.synced_folder "./", "/vagrant"

  config.vm.define :dns do |dns|
    dns.vm.provider "virtualbox" do |vb, conf|
      vb.name = "dns"
      conf.vm.hostname = "dns.#{DOMAIN}"
      conf.vm.network :private_network, ip: DNSIP, virtualbox__intnet: LAB
    end
    dns.vm.provision "shell", name: "dns-server", path: "enable-bind9.sh", args: "#{DNSIP} #{DOMAIN}"
  end

  $apache = <<-SHELL
    apt update
    apt install -y apache2
    echo "<h1>Bienvenido a $1! ($2)</h>">/var/www/html/index.html
  SHELL

  $nginx = <<-SHELL
    apt update
    apt install -y nginx
  echo "<h1>Bienvenido a $1! ($2)</h>">/var/www/html/index.nginx-debian.html
  SHELL

  services = {
    'apache1' => { :ip => "#{RED}.10", :provision => $apache, :port => "8080"},
    'apache2' => { :ip => "#{RED}.11", :provision => $apache, :port => "8081"},
    'nginx'   => { :ip => "#{RED}.12", :provision => $nginx,  :port => "8082"}
  }

  services.each_with_index do |(hostname, info), index|
    config.vm.define hostname do |client|
      client.vm.provider "virtualbox" do |vb, conf|
        vb.name = hostname
        conf.vm.hostname = "#{hostname}.#{DOMAIN}"
        conf.vm.network :private_network, ip: info[:ip], virtualbox__intnet: LAB
      end

      client.vm.provision "shell", name: "dns-client", inline: $dnsclient, args: "#{DNSIP} #{DOMAIN}"
      client.vm.provision "shell", name: "#{hostname}:#{info[:port]}", inline: info[:provision], args: "#{hostname} #{DOMAIN}"
      client.vm.network "forwarded_port", guest: 80, host: info[:port]
    end
  end

  (1..1).each do |id|
    config.vm.define "client#{id}" do |guest|
      guest.vm.provider "virtualbox" do |vb, subconf|
        vb.name = "client#{id}"
        subconf.vm.hostname = "client#{id}.#{DOMAIN}"
        subconf.vm.network :private_network, ip: "#{RED}.#{30 + id}", virtualbox__intnet: LAB
      end

      guest.vm.provision "shell", name: "dns-client", inline: $dnsclient, args: "#{DNSIP} #{DOMAIN}"
      guest.vm.provision "shell", name: "testing", inline: <<-SHELL
        dig google.com +short
        dig -x #{DNSIP} +short
        ping -a -c 1 apache1
        ping -a -c 1 apache2.#{DOMAIN}
        curl apache1 --no-progress-meter
        curl apache2 --no-progress-meter
        curl nginx --no-progress-meter
        nslookup nginx
      SHELL
    end
  end

end
