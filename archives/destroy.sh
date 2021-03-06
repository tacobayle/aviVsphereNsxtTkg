#!/bin/bash
current_dir=$PWD
sudo apt install -y jq
if ! command -v govc &> /dev/null
then
    cd /usr/local/bin
    sudo wget https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz
    sudo gunzip govc_linux_amd64.gz
    sudo mv govc_linux_amd64 govc
    sudo chmod +x govc
fi
cd $current_dir
count=0
IFS=$'\n'
for vcenter in $(cat nsxt.json | jq -c -r .nsxt.vcenters[])
  do
    export GOVC_DATACENTER=$(echo $vcenter | jq -r .dc)
    export GOVC_URL=$(echo $TF_VAR_vcenter_credentials | jq -r ".vcenter_credentials[$count] .username"):$(echo $TF_VAR_vcenter_credentials | jq -r ".vcenter_credentials[$count] .password")@$(echo $vcenter | jq -r .vsphere_server)
    export GOVC_INSECURE=true
    export GOVC_DATASTORE=$(echo $vcenter | jq -r .datastore)
    echo ""
    echo "++++++++++++++++++++++++++++++++"
    echo "Checking for vCenter Connectivity..."
    govc find / -type m > /dev/null 2>&1
    status=$?
    if [[ $status -ne 0 ]]
    then
      echo "ERROR: vCenter connectivity issue - please check that you have Internet connectivity and please check that vCenter API endpoint is reachable from this EasyAvi appliance"
      exit 1
    fi
    IFS=$'\n'
    for vm in $(govc find / -type m)
    do
      if [[ $(basename $vm) == EasyAvi-se* ]]
      then
        echo "removing VM called $(basename $vm)"
        govc vm.destroy $(basename $vm)
      fi
    done
    #
    count=$((count+1))
  done