#!/bin/bash
# export vcenter_credentials='{ "vcenter_credentials": [ {"username": "admin", "password": "password1"}, {"username": "admin", "password": "password2"}, {"username": "admin", "password": "password3"} ] }'
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
#echo $vcenter_credentials | jq -r . | tee vCenterCreds.json
IFS=$'\n'
count=0
count_app=0
for vcenter in $(cat nsxt.json | jq -c -r .nsxt.vcenters[])
  do
    export GOVC_DATACENTER=$(echo $vcenter | jq -r .dc)
    export GOVC_URL=$(echo $vcenter_credentials | jq -r ".vcenter_credentials[$count] .username"):$(echo $vcenter_credentials | jq -r ".vcenter_credentials[$count] .password")@$(echo $vcenter | jq -r .vsphere_server)
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
    echo "" | tee provider_vcenter$count.tf
    echo "provider \"vsphere\" {" | tee -a provider_vcenter$count.tf
    echo "  user                 = $(echo $vcenter_credentials | jq ".vcenter_credentials[$count] .username")" | tee -a provider_vcenter$count.tf
    echo "  password             = $(echo $vcenter_credentials | jq ".vcenter_credentials[$count] .password")" | tee -a provider_vcenter$count.tf
    echo "  vsphere_server       = $(echo $vcenter | jq .vsphere_server)" | tee -a provider_vcenter$count.tf
    echo "  alias                = \"vcenter$(echo $count)\""  | tee -a provider_vcenter$count.tf
    echo "  allow_unverified_ssl = true"  | tee -a provider_vcenter$count.tf
    echo "}" | tee -a provider_vcenter$count.tf
    echo "" | tee -a provider_vcenter$count.tf
    #
    #
    echo "" | tee vsphere_infrastructure$count.tf
    echo "provider \"vsphere\" {" | tee -a vsphere_infrastructure$count.tf
    echo "data \"vsphere_datacenter\" \"dc$count\" {" | tee vsphere_infrastructure$count.tf
    echo "  provider = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
    echo "  name = $(echo $vcenter | jq .dc)" | tee -a vsphere_infrastructure$count.tf
    echo "}" | tee -a vsphere_infrastructure$count.tf
    echo "" | tee -a vsphere_infrastructure$count.tf
    #
    echo "data \"vsphere_compute_cluster\" \"compute_cluster$count\" {" | tee -a vsphere_infrastructure$count.tf
    echo "  provider      = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
    echo "  name          = $(echo $vcenter | jq .cluster)" | tee -a vsphere_infrastructure$count.tf
    echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
    echo "}" | tee -a vsphere_infrastructure$count.tf
    echo "" | tee -a vsphere_infrastructure$count.tf
    #
    echo "data \"vsphere_datastore\" \"datastore$count\" {" | tee -a vsphere_infrastructure$count.tf
    echo "  provider      = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
    echo "  name          = $(echo $vcenter | jq .datastore)" | tee -a vsphere_infrastructure$count.tf
    echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
    echo "}" | tee -a vsphere_infrastructure$count.tf
    echo "" | tee -a vsphere_infrastructure$count.tf
    #
    echo "data \"vsphere_resource_pool\" \"pool$count\" {" | tee -a vsphere_infrastructure$count.tf
    echo "  provider      = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
    echo "  name          = $(echo $vcenter | jq .cluster)/Resources" | tee -a vsphere_infrastructure$count.tf
    echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
    echo "}" | tee -a vsphere_infrastructure$count.tf
    echo "" | tee -a vsphere_infrastructure$count.tf
    #
#    for cl in $(govc library.ls)
#    do
#      if [[ $(basename $cl) == $(cat nsxt.json | jq -r .nsxt.cl_se_name) ]]
#      then
#        echo "ERROR: There is a Content Library called $(basename $cl) which will conflict with this deployment - please remove it before trying another attempt"
#        beforeTfError=1
#      fi
#    done
    #
    echo "resource \"vsphere_content_library\" \"libraryAviSE$count\" {" | tee -a vsphere_infrastructure$count.tf
    echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
    echo "  name            = $(cat nsxt.json | jq .nsxt.cl_se_name)" | tee -a vsphere_infrastructure$count.tf
    echo "  storage_backing = [data.vsphere_datastore.datastore$count.id]" | tee -a vsphere_infrastructure$count.tf
    echo "}" | tee -a vsphere_infrastructure$count.tf
    echo "" | tee -a vsphere_infrastructure$count.tf
    #
#    IFS=$'\n'
#    for seg in $(cat nsxt.json | jq -c -r .nsxt.serviceEngineGroup)
#    do
#      govc folder.create /$(echo $vcenter | jq .dc)/vm/$(echo $seg | jq .vcenter_folder) > /dev/null 2>&1 || true
#    done
    #
#    echo "resource \"vsphere_folder\" \"folderSE$count\" {" | tee -a vsphere_infrastructure$count.tf
#    echo "  provider      = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
#    echo "  count         = length(var.nsxt.serviceEngineGroup)" | tee -a vsphere_infrastructure$count.tf
#    echo "  path          = var.nsxt.serviceEngineGroup[count.index].vcenter_folder" | tee -a vsphere_infrastructure$count.tf
#    echo "  type          = \"vm\"" | tee -a vsphere_infrastructure$count.tf
#    echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
#    echo "}" | tee -a vsphere_infrastructure$count.tf
#    echo "" | tee -a vsphere_infrastructure$count.tf
    #
    if [[ $(echo $vcenter | jq -r .avi) == true ]]
      then
        IFS=$'\n'
#        echo ""
#        echo "++++++++++++++++++++++++++++++++"
#        echo "Checking for VM conflict name..."
#        for vm in $(govc find / -type m)
#        do
#          if [[ $(basename $vm) == jump ]]
#          then
#            echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
#            beforeTfError=1
#          fi
#          if [[ $(basename $vm) == $(basename $(cat nsxt.json | jq -r .nsxt.aviOva) .ova)-* ]] # need to be checked
#          then
#            echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
#            beforeTfError=1
#          fi
#        done
        #
        govc folder.create /$(echo $vcenter | jq -r .dc)/vm/$(cat nsxt.json | jq -r .nsxt.folder_avi) > /dev/null 2>&1 || true
#        echo "govc folder.create /$(echo $vcenter | jq -r .dc)/vm/$(cat nsxt.json | jq -r .nsxt.folder_avi) > /dev/null 2>&1 || true"
        #
        echo "data \"vsphere_network\" \"networkMgmt$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  name          = var.nsxt.network_management.name" | tee -a vsphere_infrastructure$count.tf
        echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        echo "data \"vsphere_folder\" \"folderController\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  path = \"$(echo $vcenter | jq -r .dc)/vm/$(cat nsxt.json | jq -r .nsxt.folder_avi)\"" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
#        for cl in $(govc library.ls)
#        do
#          if [[ $(basename $cl) == $(cat nsxt.json | jq -r .nsxt.cl_avi_name) ]]
#          then
#            echo "ERROR: There is a Content Library called $(basename cl) which will conflict with this deployment - please remove it before trying another attempt"
#            beforeTfError=1
#          fi
#        done
        echo "resource \"vsphere_content_library\" \"libraryAvi$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
        echo "  name            = $(cat nsxt.json | jq .nsxt.cl_avi_name)" | tee -a vsphere_infrastructure$count.tf
        echo "  storage_backing = [data.vsphere_datastore.datastore$count.id]" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        echo "resource \"vsphere_content_library_item\" \"avi$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
        echo "  name            = \"$(basename $(cat nsxt.json | jq -r .nsxt.aviOva))\"" | tee -a vsphere_infrastructure$count.tf
        echo "  library_id      = vsphere_content_library.libraryAvi$count.id" | tee -a vsphere_infrastructure$count.tf
        echo "  file_url        = $(cat nsxt.json | jq .nsxt.aviOva)" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        echo "resource \"vsphere_content_library_item\" \"ubuntuJump$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
        echo "  name            = \"$(basename $(cat nsxt.json | jq -r .nsxt.ubuntuJump))\"" | tee -a vsphere_infrastructure$count.tf
        echo "  library_id      = vsphere_content_library.libraryAvi$count.id" | tee -a vsphere_infrastructure$count.tf
        echo "  file_url        = $(cat nsxt.json | jq .nsxt.ubuntuJump)" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        #
        echo "resource \"vsphere_virtual_machine\" \"controller\" {" | tee controller$count.tf
        echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a controller$count.tf
        echo "  count            = (var.nsxt.controller.cluster == true ? 3 : 1)" | tee -a controller$count.tf
        echo "  name             = \"\${split(\".ova\", basename(var.nsxt.aviOva))[0]}-\${count.index}\"" | tee -a controller$count.tf
        echo "  datastore_id      = data.vsphere_datastore.datastore$count.id" | tee -a controller$count.tf
        echo "  resource_pool_id  = data.vsphere_resource_pool.pool$count.id" | tee -a controller$count.tf
        echo "  folder           = data.vsphere_folder.folderController.path" | tee -a controller$count.tf
        echo "" | tee -a controller$count.tf
        echo "  network_interface {" | tee -a controller$count.tf
        echo "    network_id = data.vsphere_network.networkMgmt$count.id" | tee -a controller$count.tf
        echo "  }" | tee -a controller$count.tf
        echo "" | tee -a controller$count.tf
        echo "  num_cpus = var.nsxt.controller.cpu" | tee -a controller$count.tf
        echo "  memory = var.nsxt.controller.memory" | tee -a controller$count.tf
        echo "  wait_for_guest_net_timeout = var.nsxt.controller.wait_for_guest_net_timeout" | tee -a controller$count.tf
        echo "  guest_id = \"guestid-\${split(\".ova\", basename(var.nsxt.aviOva))[0]}-\${count.index}\"" | tee -a controller$count.tf
        echo "" | tee -a controller$count.tf
        echo "  disk {" | tee -a controller$count.tf
        echo "    size             = var.nsxt.controller.disk" | tee -a controller$count.tf
        echo "    label            = \"controller-\${split(\".ova\", basename(var.nsxt.aviOva))[0]}-\${count.index}.lab_vmdk\"" | tee -a controller$count.tf
        echo "    thin_provisioned = true" | tee -a controller$count.tf
        echo "  }" | tee -a controller$count.tf
        echo "  clone {" | tee -a controller$count.tf
        echo "    template_uuid = vsphere_content_library_item.avi$count.id" | tee -a controller$count.tf
        echo "  }" | tee -a controller$count.tf
        if [[ $(cat nsxt.json | jq -c -r .nsxt.controller.dhcp) == false ]]
        then
          echo "  vapp {" | tee -a controller$count.tf
          echo "    properties = {" | tee -a controller$count.tf
          echo "      \"mgmt-ip\"     = cidrhost(var.nsxt.network_management.defaultGateway, element(var.nsxt.network_management.avi_ctrl_mgmt_ips, count.index))" | tee -a controller$count.tf
          echo "      \"mgmt-mask\"   = cidrnetmask(var.nsxt.network_management.defaultGateway)" | tee -a controller$count.tf
          echo "      \"default-gw\"  = split(\"/\", var.nsxt.network_management.defaultGateway)[0]" | tee -a controller$count.tf
          echo "    }" | tee -a controller$count.tf
          echo "  }" | tee -a controller$count.tf
        fi
        echo "}" | tee -a controller$count.tf
        #
        #
        if [[ $(cat nsxt.json | jq -c -r .nsxt.controller.dhcp) == false ]]
        then
          cp userdata/jump.userdata.static userdata/jump.userdata
          echo "data \"template_file\" \"jump$count\" {" | tee -a jump$count.tf
          echo "vars = {" | tee -a jump$count.tf
          echo "  pubkey        = file(var.jump.public_key_path)" | tee -a jump$count.tf
          echo "  aviSdkVersion = var.jump.aviSdkVersion" | tee -a jump$count.tf
          echo "  ansibleVersion = var.ansible.version" | tee -a jump$count.tf
          echo "  username = var.jump.username" | tee -a jump$count.tf
          echo "  ip = cidrhost(var.nsxt.network_management.defaultGateway, var.nsxt.network_management.jump_ip)" | tee -a jump$count.tf
          echo "  mask = split(\"/\", var.nsxt.network_management.defaultGateway)[1]" | tee -a jump$count.tf
          echo "  defaultGw = split(\"/\", var.nsxt.network_management.defaultGateway)[0]" | tee -a jump$count.tf
          echo "  netplanFile = var.jump.netplanFile" | tee -a jump$count.tf
          echo "  dns = var.nsxt.network_management.dns" | tee -a jump$count.tf
          echo "  }" | tee -a jump$count.tf
          echo "}" | tee -a jump$count.tf
          echo "" | tee -a jump$count.tf
        fi
        if [[ $(cat nsxt.json | jq -c -r .nsxt.controller.dhcp) == true ]]
        then
          cp userdata/jump.userdata.dhcp userdata/jump.userdata
          echo "data \"template_file\" \"jumpbox_userdata\" {" | tee -a jump$count.tf
          echo "vars = {" | tee -a jump$count.tf
          echo "  pubkey        = file(var.jump.public_key_path)" | tee -a jump$count.tf
          echo "  aviSdkVersion = var.jump.aviSdkVersion" | tee -a jump$count.tf
          echo "  ansibleVersion = var.ansible.version" | tee -a jump$count.tf
          echo "  username = var.jump.username" | tee -a jump$count.tf
          echo "  }" | tee -a jump$count.tf
          echo "}" | tee -a jump$count.tf
          echo "" | tee -a jump$count.tf
        fi
        echo "resource \"vsphere_virtual_machine\" \"jump\" {" | tee -a jump$count.tf
        echo "  provider          = vsphere.vcenter$(echo $count)" | tee -a jump$count.tf
        echo "  name              = \"jump\"" | tee -a jump$count.tf
        echo "  datastore_id      = data.vsphere_datastore.datastore$count.id" | tee -a jump$count.tf
        echo "  resource_pool_id  = data.vsphere_resource_pool.pool$count.id" | tee -a jump$count.tf
        echo "  folder            = data.vsphere_folder.folderController.path" | tee -a jump$count.tf
        echo "  network_interface {" | tee -a jump$count.tf
        echo "    network_id = data.vsphere_network.networkMgmt$count.id" | tee -a jump$count.tf
        echo "  }" | tee -a jump$count.tf
        echo "  num_cpus = var.jump.cpu" | tee -a jump$count.tf
        echo "  memory = var.jump.memory" | tee -a jump$count.tf
        echo "  wait_for_guest_net_routable = var.jump.wait_for_guest_net_routable" | tee -a jump$count.tf
        echo "  guest_id = \"guestid-jump\"" | tee -a jump$count.tf
        echo "  disk {" | tee -a jump$count.tf
        echo "    size             = var.jump.disk" | tee -a jump$count.tf
        echo "    label            = \"jump.lab_vmdk\"" | tee -a jump$count.tf
        echo "    thin_provisioned = true" | tee -a jump$count.tf
        echo "  }" | tee -a jump$count.tf
        echo "  cdrom {" | tee -a jump$count.tf
        echo "    client_device = true" | tee -a jump$count.tf
        echo "  }" | tee -a jump$count.tf
        echo "  clone {" | tee -a jump$count.tf
        echo "    template_uuid = vsphere_content_library_item.ubuntuJump$count.id" | tee -a jump$count.tf
        echo "  }" | tee -a jump$count.tf
        echo "  vapp {" | tee -a jump$count.tf
        echo "    properties = {" | tee -a jump$count.tf
        echo "      hostname    = \"jump\"" | tee -a jump$count.tf
        echo "      public-keys = file(var.jump.public_key_path)" | tee -a jump$count.tf
        echo "      user-data   = base64encode(data.template_file.jump$count.rendered)" | tee -a jump$count.tf
        echo "    }" | tee -a jump$count.tf
        echo "  }" | tee -a jump$count.tf
        echo "}" | tee -a jump$count.tf
    fi
    #
    #
    #
    if [[ $(echo $vcenter | jq -r .application) == true ]]
      then
        #
        IFS=$'\n'
#        echo ""
#        echo "++++++++++++++++++++++++++++++++"
#        echo "Checking for VM conflict name..."
#        for vm in $(govc find / -type m)
#        do
#          if [[ $(basename $vm) == backend-* ]]
#          then
#            echo "ERROR: There is a VM called $(basename $vm) which will conflict with this deployment - please remove it before trying another attempt"
#            beforeTfError=1
#          fi
#        done
        #
#        for cl in $(govc library.ls)
#        do
#          if [[ $(basename $cl) == $(cat nsxt.json | jq -c -r .nsxt.cl_app_name) ]]
#          then
#            echo "ERROR: There is a Content Library called $(basename cl) which will conflict with this deployment - please remove it before trying another attempt"
#            beforeTfError=1
#          fi
#        done
        # govc folder.create /$(cat nsxt.json | jq -r .nsxt.vcenter.dc)/vm/$(echo $vcenter | jq .folder_application) > /dev/null 2>&1 || true
        echo "govc folder.create /$(cat nsxt.json | jq -c -r .nsxt.vcenter.dc)/vm/$(echo $vcenter | jq .folder_application) > /dev/null 2>&1 || true"
        #
#        echo "resource \"vsphere_folder\" \"folderApp$count\" {" | tee -a vsphere_infrastructure$count.tf
#        echo "  provider      = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
#        echo "  path          = $(echo $vcenter | jq .folder_application)" | tee -a vsphere_infrastructure$count.tf
#        echo "  type          = \"vm\"" | tee -a vsphere_infrastructure$count.tf
#        echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
#        echo "}" | tee -a vsphere_infrastructure$count.tf
#        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        echo "resource \"vsphere_content_library\" \"App$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
        echo "  name            = $(cat nsxt.json | jq -c .nsxt.cl_app_name)" | tee -a vsphere_infrastructure$count.tf
        echo "  storage_backing = [data.vsphere_datastore.datastore$count.id]" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        echo "resource \"vsphere_content_library_item\" \"ubuntu$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  provider        = vsphere.vcenter$(echo $count)" | tee -a vsphere_infrastructure$count.tf
        echo "  name            = \"ubuntu\"" | tee -a vsphere_infrastructure$count.tf
        echo "  library_id      = vsphere_content_library.App$count.id" | tee -a vsphere_infrastructure$count.tf
        echo "  file_url        = $(cat nsxt.json | jq .nsxt.ubuntuApp)" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        echo "data \"vsphere_network\" \"networkBackend$count\" {" | tee -a vsphere_infrastructure$count.tf
        echo "  name          = var.nsxt.network_backend.name" | tee -a vsphere_infrastructure$count.tf
        echo "  datacenter_id = data.vsphere_datacenter.dc$count.id" | tee -a vsphere_infrastructure$count.tf
        echo "}" | tee -a vsphere_infrastructure$count.tf
        echo "" | tee -a vsphere_infrastructure$count.tf
        #
        #
        echo "data \"template_file\" \"backend$count\" {" | tee backend$count.tf
        echo "  count = $(cat nsxt.json | jq .nsxt.backend_per_vcenter)" | tee -a backend$count.tf
        echo "  template = file(\"userdata/backend.userdata\")" | tee -a backend$count.tf
        echo "  vars = {" | tee -a backend$count.tf
        echo "    defaultGw          = split(\"/\", var.nsxt.network_backend.defaultGateway)[0]" | tee -a backend$count.tf
        echo "    pubkey             = file(var.jump.public_key_path)" | tee -a backend$count.tf
        echo "    ip                 = cidrhost("var.nsxt.network_backend.defaultGateway", count.index + $((count_app*$(cat nsxt.json | jq .nsxt.backend_per_vcenter))))" | tee -a backend$count.tf
        echo "    subnetMask         = split(\"/\", var.nsxt.network_backend.defaultGateway)[1]" | tee -a backend$count.tf
        echo "    netplanFile        = var.backend.netplanFile" | tee -a backend$count.tf
        echo "    dnsMain            = var.backend.dnsMain" | tee -a backend$count.tf
        echo "    dnsSec             = var.backend.dnsSec" | tee -a backend$count.tf
        echo "    url_demovip_server = var.backend.url_demovip_server" | tee -a backend$count.tf
        echo "    username           = var.backend.username" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "}" | tee -a backend$count.tf
        #
        #
        echo "resource \"vsphere_virtual_machine\" \"backend$count\" {" | tee -a backend$count.tf
        echo "  provider          = vsphere.vcenter$(echo $count)" | tee -a backend$count.tf
        echo "  count             = $(cat nsxt.json | jq -r .nsxt.backend_per_vcenter)" | tee -a backend$count.tf
        echo "  name              = \"backend-\${count.index}\"" | tee -a backend$count.tf
        echo "  datastore_id      = data.vsphere_datastore.datastore$count.id" | tee -a backend$count.tf
        echo "  resource_pool_id  = data.vsphere_resource_pool.pool$count.id" | tee -a backend$count.tf
        echo "  folder            = vsphere_folder.folderApp$count.path" | tee -a backend$count.tf
        echo "  network_interface {" | tee -a backend$count.tf
        echo "    network_id = data.vsphere_network.networkBackend$count.id" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "  num_cpus = var.backend.cpu" | tee -a backend$count.tf
        echo "  memory = var.backend.memory" | tee -a backend$count.tf
        echo "  wait_for_guest_net_routable = var.backend.wait_for_guest_net_routable" | tee -a backend$count.tf
        echo "  guest_id = \"guestid-backend-\${count.index}\"" | tee -a backend$count.tf
        echo "  disk {" | tee -a backend$count.tf
        echo "    size             = var.backend.disk" | tee -a backend$count.tf
        echo "    label            = \"backend-\${count.index}.lab_vmdk\"" | tee -a backend$count.tf
        echo "    thin_provisioned = true" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "  cdrom {" | tee -a backend$count.tf
        echo "    client_device = true" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "  clone {" | tee -a backend$count.tf
        echo "    template_uuid = vsphere_content_library_item.ubuntu$count.id" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "  vapp {" | tee -a backend$count.tf
        echo "    properties = {" | tee -a backend$count.tf
        echo "      hostname    = \"backend-\${count.index}\"" | tee -a backend$count.tf
        echo "      public-keys = file(var.jump.public_key_path)" | tee -a backend$count.tf
        echo "      user-data   = base64encode(data.template_file.backend$count[count.index].rendered)" | tee -a backend$count.tf
        echo "    }" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "  connection {" | tee -a backend$count.tf
        echo "    host        = cidrhost(\"var.nsxt.network_backend.defaultGateway\", count.index + $((count_app*$(cat nsxt.json | jq .nsxt.backend_per_vcenter))))" | tee -a backend$count.tf
        echo "    type        = \"ssh\"" | tee -a backend$count.tf
        echo "    agent       = false" | tee -a backend$count.tf
        echo "    user        = var.backend.username" | tee -a backend$count.tf
        echo "    private_key = file(var.jump.private_key_path)" | tee -a backend$count.tf
        echo "    }" | tee -a backend$count.tf
        echo "" | tee -a backend$count.tf
        echo "  provisioner \"remote-exec\" {" | tee -a backend$count.tf
        echo "    inline      = [" | tee -a backend$count.tf
        echo "      \"while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done\"" | tee -a backend$count.tf
        echo "    ]" | tee -a backend$count.tf
        echo "  }" | tee -a backend$count.tf
        echo "}" | tee -a backend$count.tf
        #
        #
        echo "resource \"nsxt_policy_group\" \"backend$count\" {" | tee -a nsxt_pool$count.tf
        echo "  display_name = \"EasyAvi - Backend - vCenter$count\"" | tee -a nsxt_pool$count.tf
        echo "  criteria {" | tee -a nsxt_pool$count.tf
        echo "    condition {" | tee -a nsxt_pool$count.tf
        echo "      key = \"Tag\"" | tee -a nsxt_pool$count.tf
        echo "      member_type = \"VirtualMachine\"" | tee -a nsxt_pool$count.tf
        echo "      operator = \"EQUALS\"" | tee -a nsxt_pool$count.tf
        echo "      value = \"EasyAvi - Backend - vCenter$count\"" | tee -a nsxt_pool$count.tf
        echo "    }" | tee -a nsxt_pool$count.tf
        echo "  }" | tee -a nsxt_pool$count.tf
        echo "}" | tee -a nsxt_pool$count.tf
        echo "" | tee -a nsxt_pool$count.tf
        #
        echo "resource \"nsxt_vm_tags\" \"backend$count\" {" | tee -a nsxt_pool$count.tf
        echo "  count = var.nsxt.backend_per_vcenter - 1" | tee -a nsxt_pool$count.tf
        echo "  instance_id = vsphere_virtual_machine.backend$count[count.index].id" | tee -a nsxt_pool$count.tf
        echo "  tag {" | tee -a nsxt_pool$count.tf
        echo "    tag   = \"EasyAvi - Backend - vCenter$count\"" | tee -a nsxt_pool$count.tf
        echo "  }" | tee -a nsxt_pool$count.tf
        echo "}" | tee -a nsxt_pool$count.tf
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