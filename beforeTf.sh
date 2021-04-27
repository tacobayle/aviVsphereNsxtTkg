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
    #
    jq -n \
    --arg user $(echo $TF_VAR_vcenter_credentials | jq -r ".vcenter_credentials[$count] .username") \
    --arg password $(echo $TF_VAR_vcenter_credentials | jq -r ".vcenter_credentials[$count] .password") \
    --arg vsphere_server $(echo $vcenter | jq -r .vsphere_server) \
    --arg alias $count \
    '{user: $user, password: $password, vsphere_server: $vsphere_server, alias: $alias}' | tee config.json >/dev/null
    python3 python/template.py template/provider_vcenter.j2 config.json provider_vcenter$count.tf
    rm config.json
    #
    #
    jq -n \
    --arg dc $(echo $vcenter | jq -r .dc) \
    --arg cluster $(echo $vcenter | jq -r .cluster) \
    --arg datastore $(echo $vcenter | jq -r .datastore) \
    --arg count $count \
    '{dc: $dc, cluster: $cluster, datastore: $datastore, count: $count}' | tee config.json >/dev/null
    python3 python/template.py template/vsphere_infrastructure.j2 config.json vsphere_infrastructure$count.tf
    rm config.json
    #
    echo ""
    echo "++++++++++++++++++++++++++++++++"
    echo "Checking for Content Library conflict name..."
    for cl in $(govc library.ls)
    do
      if [[ $(basename $cl) == $(cat nsxt.json | jq -r .nsxt.cl_se_name) ]]
      then
        echo "ERROR: There is a Content Library called $(basename $cl) which will conflict with this deployment - please remove it before trying another attempt"
        beforeTfError=1
      fi
    done
    #
    #
    echo ""
    echo "++++++++++++++++++++++++++++++++"
    echo "Attempt to create folder(s)"
    IFS=$'\n'
    for seg in $(cat nsxt.json | jq -c -r .nsxt.serviceEngineGroup[])
    do
      govc folder.create /$(echo $vcenter | jq -r .dc)/vm/$(echo $seg | jq -r .vcenter_folder) > /dev/null 2>&1 || true
    done
    #
    #
    if [[ $(echo $vcenter | jq -r .avi) == true ]]
      then
        IFS=$'\n'
        echo ""
        echo "++++++++++++++++++++++++++++++++"
        echo "Checking for VM conflict name..."
        for vm in $(govc find / -type m)
        do
          if [[ $(basename $vm) == jump ]]
          then
            echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
            beforeTfError=1
          fi
          if [[ $(basename $vm) == $(basename $(cat nsxt.json | jq -r .nsxt.aviOva) .ova)-* ]] # need to be checked
          then
            echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
            beforeTfError=1
          fi
        done
        #
        govc folder.create /$(echo $vcenter | jq -r .dc)/vm/$(cat nsxt.json | jq -r .nsxt.folder_avi) > /dev/null 2>&1 || true
        #
        echo ""
        echo "++++++++++++++++++++++++++++++++"
        echo "Checking for Content Library conflict name..."
        for cl in $(govc library.ls)
        do
          if [[ $(basename $cl) == $(cat nsxt.json | jq -r .nsxt.cl_avi_name) ]]
          then
            echo "ERROR: There is a Content Library called $(basename cl) which will conflict with this deployment - please remove it before trying another attempt"
            beforeTfError=1
          fi
        done
        #
         jq -n \
         --arg dc $(echo $vcenter | jq -r .dc) \
         --arg count $count \
         '{dc: $dc, count: $count}' | tee config.json >/dev/null
         python3 python/template.py template/vsphere_infrastructure_avi.j2 config.json vsphere_infrastructure_avi$count.tf
         rm config.json
        #
        #
        if [[ $(cat nsxt.json | jq -c -r .nsxt.network_management.dhcp) == false ]]
        then
          jq -n \
          --arg count $count \
          '{count: $count}' | tee config.json >/dev/null
          python3 python/template.py template/controller_static.j2 config.json controller_static$count.tf
          rm config.json
          #
          cp userdata/jump.userdata.static userdata/jump.userdata
          jq -n \
          --arg count $count \
          '{count: $count}' | tee config.json >/dev/null
          python3 python/template.py template/jump_static.j2 config.json jump_static$count.tf
          rm config.json
          #

        fi
        if [[ $(cat nsxt.json | jq -c -r .nsxt.network_management.dhcp) == true ]]
        then
          jq -n \
          --arg count $count \
          '{count: $count}' | tee config.json >/dev/null
          python3 python/template.py template/controller_dhcp.j2 config.json controller_dhcp$count.tf
          rm config.json
          #
          cp userdata/jump.userdata.dhcp userdata/jump.userdata
          jq -n \
          --arg count $count \
          '{count: $count}' | tee config.json >/dev/null
          python3 python/template.py template/jump_dhcp.j2 config.json jump_dhcp$count.tf
          rm config.json
          #
        fi
        #
        #
    fi
    #
    #
    if [[ $(echo $vcenter | jq -r .application) == true ]]
      then
        #
        IFS=$'\n'
        echo ""
        echo "++++++++++++++++++++++++++++++++"
        echo "Checking for VM conflict name..."
        for vm in $(govc find / -type m)
        do
          if [[ $(basename $vm) == backend-* ]]
          then
            echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
            beforeTfError=1
          fi
        done
        #
        echo ""
        echo "++++++++++++++++++++++++++++++++"
        echo "Checking for Content Library conflict name..."
        for cl in $(govc library.ls)
        do
          if [[ $(basename $cl) == $(cat nsxt.json | jq -c -r .nsxt.cl_app_name) ]]
          then
            echo "ERROR: There is a Content Library called $(basename cl) which will conflict with this deployment - please remove it before trying another attempt"
            beforeTfError=1
          fi
        done
        #
        govc folder.create /$(echo $vcenter | jq -r .dc)/vm/$(cat nsxt.json | jq -c -r .nsxt.folder_application) > /dev/null 2>&1 || true
        #
        #
        jq -n \
        --arg dc $(echo $vcenter | jq -r .dc) \
        --arg count $count \
        '{dc: $dc, count: $count}' | tee config.json >/dev/null
        python3 python/template.py template/vsphere_infrastructure_app.j2 config.json vsphere_infrastructure_app$count.tf
        rm config.json
        #
        #
        if [[ $(cat nsxt.json | jq -c -r .nsxt.network_backend.dhcp) == false ]]
        then
          cp userdata/backend.userdata.static userdata/backend.userdata
          jq -n \
          --arg count_app $((count_app*$(cat nsxt.json | jq .nsxt.backend_per_vcenter))) \
          --arg count $count \
          '{count_app: $count_app, count: $count}' | tee config.json >/dev/null
          python3 python/template.py template/backend_static.j2 config.json backend_static_$count.tf
          rm config.json
        fi
        #
        if [[ $(cat nsxt.json | jq -c -r .nsxt.network_backend.dhcp) == true ]]
        then
          cp userdata/backend.userdata.dhcp userdata/backend.userdata
          jq -n \
          --arg count_app $((count_app*$(cat nsxt.json | jq .nsxt.backend_per_vcenter))) \
          --arg count $count \
          '{count_app: $count_app, count: $count}' | tee config.json >/dev/null
          python3 python/template.py template/backend_dhcp.j2 config.json backend_dhcp_$count.tf
          rm config.json
        fi
        #
        #
        jq -n \
        --arg count $count \
        '{count: $count}' | tee config.json >/dev/null
        python3 python/template.py template/nsxt_policy_group.j2 config.json nsxt_policy_group_$count.tf
        rm config.json
        #
        count_app=$((count_app+1))
    fi
    #
    count=$((count+1))
  done
if [[ $beforeTfError == 1 ]]
then
  exit 1
fi