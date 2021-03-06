#!/bin/bash
../examples/basic-vm.lua restart || exit 1
. ./autoip.sh basic-vm

ping -c 1 -w 5 $IPv4 || exit 1
ping6 -c 1 -w 5 $IPv6 || exit 1

if [ ! -f ~/.ssh/id_rsa.pub ]; then
	ssh-keygen -f ~/.ssh/id_rsa -N ''
fi
MYKEY=$(cat ~/.ssh/id_rsa.pub)
mkdir -p ../examples/.basic-vm.lua/root/.ssh/
EXISTINGKEYS=$(cat ../examples/.basic-vm.lua/root/.ssh/authorized_keys | grep -v "$MYKEY")
echo $EXISTINGKEYS > ../examples/.basic-vm.lua/root/.ssh/authorized_keys
echo $MYKEY >> ../examples/.basic-vm.lua/root/.ssh/authorized_keys
echo "SSH $IPv4"
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $IPv4 exit 0 >/dev/null 2>&1 || exit 1
echo "SSH $IPv6"
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $IPv6 exit 0 >/dev/null 2>&1 || exit 1

../examples/basic-vm.lua stop || exit 1
echo "Tests complete."
exit 0