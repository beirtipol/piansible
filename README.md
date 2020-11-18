# Ansible Raspberry Pi Docker Swarm for Home Automation

I decided to share this setup after I found myself getting tired of running lots of scripts and following my chaotic notes every time I needed to rebuild my Raspberry Pis because I had done something stupid, and this happened far more often than I care to admit. The purpose of this project is to provide a fully hands-off installation and setup for my Home Automation cluster. I've tried to keep this project general enough so that others might find it useful.

Here's what it does (in about 10 minutes without any user interaction needed!!!)

- Set up multiple Raspberry Pi's with a new user account
- Install Docker on all nodes
- Create a Docker swarm
- Deploy [Portainer](https://www.portainer.io/) for Docker swarm management
- Deploy [Prometheus](https://prometheus.io/) for monitoring
    - Deploy [CAdvisor](https://github.com/google/cadvisor) for monitoring Docker Swarm workers
    - Deploy [Node Exporter](https://github.com/prometheus/node_exporter) for monitoring the Raspberry Pi Host Systems
    - Deploy [Arm Exporter](https://github.com/carlosedp/arm-monitoring) for monitoring Raspberry Pi CPU Temperatures
    - Deploy [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter) for monitoring network latency
    - Deploy [Ping Exporter](https://github.com/czerwonk/ping_exporter) for simple ping monitoring
    - Deploy [Prometheus Push Gateway](https://github.com/prometheus/pushgateway) for pushing stats in to Prometheus
- Deploy [Grafana](https://grafana.com/) as a frontend for Prometheus
    - Use Provisioning to set up some basic dashboards for:
        - Docker Swarm Monitoring
        - System Monitoring
        - Network latency monitoring of external services (like netflix, zoom etc.)
        - Energy Usage
    - Define public and private dashboards
- Set up an Nginx server with a [LetsEncrypt](https://letsencrypt.org/) HTTPS certificate to proxy external web traffic to:
    - [Grafana](https://grafana.com/)
    - [HomeAssistant](https://www.home-assistant.io/)
    - [JFixTools](https://github.com/beirtipol/jfixtools)
- Install a NOIP [Dynamic Update client](https://www.noip.com/download) to keep your noip hostname up to date with your current external IP
- Deploy [JFixTools](https://github.com/beirtipol/jfixtools).
    - This is one of my personal applications, run with Spring Boot. I've left it in here as an example for how you can host your own application locally. Assuming you don't want it, you can simply remove it from the Nginx [docker-compose.yml](./docker-stack-nginx/templates/docker-compose.yml) as well as the [subdomain file](./docker-stack-nginx/files/data/proxy-confs/fix.subdomain.conf) and the reference in the [up.yml](./up.yml). Then you can remove the directory for [docker-stack-jfixtools](./docker-stack-jfixtools)

## Pre-Requisites
* An Ansible environment. You have a choice of:
    * (Easy) Docker Desktop 
    * A Linux Environment
    * Windows 10 WSL 2 (for running Ansible, but you can alternatively run from a linux host)
        * Ubuntu for WSL
    * Ansible Community.General (If not taking the easy route)
* 2 or more Raspberry Pis
* Repeat for each Pi
    * Flash your Raspberry Pi SDCards with the latest Raspbian Lite OS
    * After flashing the SDCard, re-insert it and create an empty file called 'ssh'
    * Pop the SDCard in the Pi, plug it in and power it up.
    * Follow the instructions for your router to discover the new Pi and assign it a static IP. Note down the static IP that you choose.
* For Nginx LetsEncrypt, you will need a [NoIP](https://www.noip.com/) account (Free is fine)

## Pi Setup
I have set up my Pi's with the standard RAspbian install by using the RaspberryPi Imager, available [here](https://www.raspberrypi.org/software/).

## Docker Desktop
The Dockerfile in this project builds a simple Ubuntu image with the relevant dependencies installed. You only need to build it once with

`buildDockerContainer.bat`

And then you can start a shell at any point with 

`startDockerContainer.bat`

From there, you can run any ansible commands, including encrypting and decrypting your vault files.

## Ansible Installation
If you can't use or don't want to use Docker to install docker (it is a bit meta I guess) then you should refer to the latest documentation on installing [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Assuming you have installed an Ubuntu WSL environment, you can follow the default Ansible Installation instructions for [Ubuntu](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu)

To install the Community packages for Ansible, just run the following command:

`ansible-galaxy collection install community.general`

## Ansible Playbook explanation
This collection of playbooks is based upon a Raspberry Pi 4 with POE (Power Over Ethernet) Hat. If you are not using a POE Hat, you won't need the section on 'smoother fan speeds' in the common/tasks/main.yml

Edit the Inventory.yml and 
* Add the correct number of workers for your setup
* Ensure the IP address matches the static IP you assigned from your router.
* Rename the nodes if desired
    * If you do rename the nodes, ensure that you do a find and replace across this entire project for 'pinode01'
* If you have more than 3 Pis, you'll probably want to add a second manager node. You can simply define a group containing it and plug it in to the up.yml to use the docker-swarm-add-manager task.

### Encrypted files
Ansible allows you to encrypt files so that you can share config easily. Firstly, you can define the files you want to encrypt in plain text, and then run the command:

`ansible-vault encrypt the_file`

This will prompt you for a Vault password. You can follow instructions [here](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to set up a password file if you don't want to keep typing it in.

If you need to edit the file again, you can just decrypt, edit, and re-encrypt it.

`ansible-vault decrypt the_file`

These are the files which I have encrypted

#### group_vars/all/variables.yml
You'll need to create your own version of this file:

```
my_user: my_ssh_username
# Run the following command to generate a new hashed password
# mkpasswd --method=sha-512 my_password
my_pass: my_ssh_password
my_email: my_email_address for LetsEncrypt certificate registration
noip_username: my noip username
noip_password: my noip password
external_url: my domain as registered with noip
grafana_admin_password: my admin password for Grafana
homeassistant_token: my [long lived access token](https://www.home-assistant.io/docs/authentication/) from HomeAssistant used for Prometheus scraping of HomeAssistant data
```

#### docker-stack-monitoring/files/prometheus/private
Here I have some private blackbox targets, i.e. those servers which I monitor for work, as well as some private external targets, which are node-exporters running on the various desktops/laptops dotted around the house.

### Running Ansible

I ran this from Windows 10 WSL Ubuntu. I followed online instructions to install version 2.9+ of Ansible. 

To launch the Ansible setup, I just ran

`deploy.sh`

When I last ran this, the whole playbook completed in about 10 minutes. Most of that was performing the apt upgrade.

## Accessing and using Services
### Portainer
This will be accessible on http://pinode01:9000. When you first access it, you will be asked to create a new admin password.

### Grafana
This will be accessible on both http://pinode01:3000 and https://grafana.yourwebsite.com. You can log in as "admin" with the password you provided in the encrypted variables.yml

### Prometheus
You can access the raw prometheus installation on http://pinode01:9090. I haven't made this external as it is just another endpoint that would need securing

### Home Assistant
I'm just getting to grips with this at the moment, but I have simply set up a separate Raspberry Pi with a HomeAssistant image. Instructions on the HomeAssistant website are pretty clear and easy to follow. The host I have it installed on uses the hostname 'homeassistant' and the default port which means if you have done the same, it should be available on https://home.yourwebsite.com

