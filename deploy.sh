export ANSIBLE_CONFIG=ansible.cfg
ansible-playbook --ask-vault-pass -i inventory.yml up.yml