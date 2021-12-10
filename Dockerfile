FROM ubuntu

RUN apt-get update && apt-get install python3 python3-pip dos2unix ansible sshpass nano -y

ENV EDITOR=nano
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

RUN ansible-galaxy collection install community.general

RUN wget https://networkgenomics.com/try/mitogen-0.2.9.tar.gz -O /mitogen.tar.gz && tar xvfz /mitogen.tar.gz && rm -f /mitogen.tar.gz && ln -s /mitogen-0.2.9 /mitogen
