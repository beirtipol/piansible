from ubuntu

RUN apt-get update && apt-get install python3 python3-pip dos2unix ansible sshpass nano -y

ENV EDITOR=nano
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

RUN ansible-galaxy collection install community.general