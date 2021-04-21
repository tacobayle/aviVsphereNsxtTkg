#!/bin/bash
# export TF_VAR_vcenter_credentials='{ "vcenter_credentials": [ {"username": "admin", "password": "password1"}, {"username": "admin", "password": "password2"}, {"username": "admin", "password": "password3"} ] }'
# rm -f backend* ; rm -f controller* ; rm -f jump* ; rm -f provider_vcenter* ; rm -f vsphere_infrastructure* ; rm -f nsxt_pool* ; /bin/bash beforeTf.sh
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
#
# This will read environment variable such the following:
#echo $TF_VAR_vcenter_credentials | jq -r . | tee vCenterCreds.json
IFS=$'\n'
count=0
count_app=0
for vcenter in $(cat nsxt.json | jq -c -r .nsxt.vcenters[])
  do
    export GOVC_DATACENTER=$(echo $vcenter | jq -r .dc)
    export GOVC_URL=$(echo $TF_VAR_vcenter_credentials | jq -r ".vcenter_credentials[$count] .username"):$(echo $vcenter_credentials | jq -r ".vcenter_credentials[$count] .password")@$(echo $vcenter | jq -r .vsphere_server)
    export GOVC_INSECURE=true
    export GOVC_DATASTORE=$(echo $vcenter | jq -r .datastore)
#    echo ""
#    echo "++++++++++++++++++++++++++++++++"
#    echo "Checking for vCenter Connectivity..."
#    govc find / -type m > /dev/null 2>&1
#    status=$?
#    if [[ $status -ne 0 ]]
#    then
#      echo "ERROR: vCenter connectivity issue - please check that you have Internet connectivity and please check that vCenter API endpoint is reachable from this EasyAvi appliance"
#      exit 1
#    fi
    jq -n \
    --arg dc $(echo $vcenter | jq -r .dc) \
    --arg cluster $(echo $vcenter | jq -r .cluster) \
    --arg datastore $(echo $vcenter | jq -r .datastore) \
    --arg count $count \
    --arg cl_se_name $(cat nsxt.json | jq -r .nsxt.cl_se_name) \
    '{dc: $dc, cluster: $cluster, datastore: $datastore, count: $count, cl_se_name: $cl_se_name}' | tee config.json >/dev/null
    python3 python/template.py template/vsphere_infrastructure.j2 config.json vsphere_infrastructure$count.tf
    rm config.json
    count=$((count+1))
  done