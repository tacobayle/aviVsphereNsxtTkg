#!/usr/bin/env python3
# The shebang above is to tell the shell which interpreter to use. This make the file executable without "python3" in front of it (otherwise I had to use python3 pyvmc.py)
# I also had to change the permissions of the file to make it run. "chmod +x pyVMC.py" did the trick.
# I also added "export PATH="MY/PYVMC/DIRECTORY":$PATH" (otherwise I had to use ./pyvmc.y)
# For git BASH on Windows, you can use something like this #!/C/Users/usr1/AppData/Local/Programs/Python/Python38/python.exe

# Python Client for VMware Cloud on AWS

################################################################################
### Copyright (C) 2019-2020 VMware, Inc.  All rights reserved.
### SPDX-License-Identifier: BSD-2-Clause
################################################################################


"""

Welcome to PyVMC ! 

VMware Cloud on AWS API Documentation is available at: https://code.vmware.com/apis/920/vmware-cloud-on-aws
CSP API documentation is available at https://console.cloud.vmware.com/csp/gateway/api-docs
vCenter API documentation is available at https://code.vmware.com/apis/366/vsphere-automation


You can install python 3.8 from https://www.python.org/downloads/windows/ (Windows) or https://www.python.org/downloads/mac-osx/ (MacOs).

You can install the dependent python packages locally (handy for Lambda) with:
pip3 install requests or pip3 install requests -t . --upgrade
pip3 install configparser or pip3 install configparser -t . --upgrade
pip3 install PTable or pip3 install PTable -t . --upgrade

With git BASH on Windows, you might need to use 'python -m pip install' instead of pip3 install

"""

import requests                         # need this for Get/Post/Delete
import configparser                     # parsing config file
import time
import sys
import os
import json
from prettytable import PrettyTable

#config = configparser.ConfigParser()
#config.read("./config.ini")
strProdURL      = 'https://vmc.vmware.com'
strCSPProdURL   = 'https://console.cloud.vmware.com'
Refresh_Token   = sys.argv[1]
ORG_ID          = sys.argv[2]
SDDC_ID         = sys.argv[3]




class data():
    sddc_name       = ""
    sddc_status     = ""
    sddc_region     = ""
    sddc_cluster    = ""
    sddc_hosts      = 0
    sddc_type       = ""

def getAccessToken(myKey):
    """ Gets the Access Token using the Refresh Token """
    params = {'refresh_token': myKey}
    headers = {'Content-Type': 'application/json'}
    response = requests.post('https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize', params=params, headers=headers)
    jsonResponse = response.json()
    access_token = jsonResponse['access_token']
    return access_token

def getConnectedAccounts(tenantid, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = strProdURL + "/vmc/api/orgs/" + tenantid + "/account-link/connected-accounts"
    response = requests.get(myURL, headers=myHeader)
    jsonResponse = response.json()
    orgtable = PrettyTable(['OrgID'])
    orgtable.add_row([tenantid])
    print(str(orgtable))
    table = PrettyTable(['Account Number','id'])
    for i in jsonResponse:
        table.add_row([i['account_number'],i['id']])
    return table

def getCompatibleSubnets(tenantid,sessiontoken,linkedAccountId,region):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = strProdURL + "/vmc/api/orgs/" + tenantid + "/account-link/compatible-subnets"
    params = {'org': tenantid, 'linkedAccountId': linkedAccountId,'region': region}
    response = requests.get(myURL, headers=myHeader,params=params)
    jsonResponse = response.json()
    vpc_map = jsonResponse['vpc_map']
    table = PrettyTable(['vpc','description'])
    subnet_table = PrettyTable(['vpc_id','subnet_id','subnet_cidr_block','name','compatible'])
    for i in vpc_map:
        myvpc = jsonResponse['vpc_map'][i]
        table.add_row([myvpc['vpc_id'],myvpc['description']])
        for j in myvpc['subnets']:
            subnet_table.add_row([j['vpc_id'],j['subnet_id'],j['subnet_cidr_block'],j['name'],j['compatible']])
    print(table)
    return subnet_table

def getSDDCS(tenantid, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = strProdURL + "/vmc/api/orgs/" + tenantid + "/sddcs"
    response = requests.get(myURL, headers=myHeader)
    jsonResponse = response.json()
    orgtable = PrettyTable(['OrgID'])
    orgtable.add_row([tenantid])
    print(str(orgtable))
    table = PrettyTable(['Name', 'Cloud', 'Status', 'Hosts', 'ID'])
    for i in jsonResponse:
        hostcount = 0
        myURL = strProdURL + "/vmc/api/orgs/" + tenantid + "/sddcs/" + i['id']
        response = requests.get(myURL, headers=myHeader)
        mySDDCs = response.json()

        clusters = mySDDCs['resource_config']['clusters']
        if clusters:
            hostcount = 0
            for c in clusters:
                hostcount += len(c['esx_host_list'])
        table.add_row([i['name'], i['provider'],i['sddc_state'], hostcount, i['id']])
    return table


#-------------------- Show hosts in an SDDC
def getCDChosts(sddcID, tenantid, sessiontoken):

    myHeader = {'csp-auth-token': sessiontoken}
    myURL = strProdURL + "/vmc/api/orgs/" + tenantid + "/sddcs/" + sddcID

    response = requests.get(myURL, headers=myHeader)

    # grab the names of the CDCs
    jsonResponse = response.json()

    # get the vC block (this is a bad hack to get the rest of the host name
    # shown in vC inventory)
    cdcID = jsonResponse['resource_config']['vc_ip']
    cdcID = cdcID.split("vcenter")
    cdcID = cdcID[1]
    cdcID = cdcID.split("/")
    cdcID = cdcID[0]

    # get the hosts block
    clusters = jsonResponse['resource_config']['clusters']
    table = PrettyTable(['Cluster', 'Name', 'Status', 'ID'])
    for c in clusters:
        for i in c['esx_host_list']:
            hostName = i['name'] + cdcID
            table.add_row([c['cluster_name'], hostName, i['esx_state'], i['esx_id']])
    print(table)
    return

#-------------------- Display the users in our org
def showORGusers(tenantid, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    #using @ as our search term...
    myURL = strCSPProdURL + "/csp/gateway/am/api/orgs/" + tenantid + "/users/search?userSearchTerm=%40"
    response = requests.get(myURL, headers=myHeader)
    jsonResponse = response.json()
    if str(response.status_code) != "200":
        print("\nERROR: " + str(jsonResponse))
    else:
        # get the results block
        users = jsonResponse['results']
        table = PrettyTable(['First Name', 'Last Name', 'User Name'])
        for i in users:
            table.add_row([i['user']['firstName'],i['user']['lastName'],i['user']['username']])
        print(table)
    return

def getSDDCVPNInternetIP(proxy_url, sessiontoken):
    """ Gets the Public IP used for VPN by the SDDC """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "cloud-service/api/v1/infra/sddc-user-config"
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    vpn_internet_IP = json_response['vpn_internet_ips'][0]
    return vpn_internet_IP

def getSDDCState(org_id, sddc_id, sessiontoken):
    """ Gets the overall status of the SDDDC """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = "{}/vmc/api/orgs/{}/sddcs/{}".format(strProdURL, org_id, sddc_id)
    response = requests.get(myURL, headers=myHeader)
    sddc_state = response.json()
    table = PrettyTable(['Name', 'Id', 'Status', 'Type', 'Region', 'Deployment Type'])
    table.add_row([sddc_state['name'], sddc_state['id'], sddc_state['sddc_state'], sddc_state['sddc_type'], sddc_state['resource_config']['region'], sddc_state['resource_config']['deployment_type']])
    return table

def getNSXTproxy(org_id, sddc_id, sessiontoken):
    """ Gets the Reverse Proxy URL """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = "{}/vmc/api/orgs/{}/sddcs/{}".format(strProdURL, org_id, sddc_id)
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    proxy_url = json_response['resource_config']['nsx_api_public_endpoint_url']
    return proxy_url

def getSDDCnetworks(proxy_url, sessiontoken):
    """ Gets the SDDC Networks """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/segments")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_networks = json_response['results']
    table = PrettyTable(['Name', 'id', 'Type', 'Network', 'Default Gateway'])
    table_extended = PrettyTable(['Name', 'id','Tunnel ID'])
    for i in sddc_networks:
        if ( i['type'] == "EXTENDED"):
            table_extended.add_row([i['display_name'], i['id'], i['l2_extension']['tunnel_id']])
        elif ( i['type'] == "DISCONNECTED"):
            table.add_row([i['display_name'], i['id'], i['type'],"-", "-"])
        else: 
            table.add_row([i['display_name'], i['id'], i['type'], i['subnets'][0]['network'], i['subnets'][0]['gateway_address']])
    print("Routed Networks:")
    print(table)
    print("Extended Networks:")
    print(table_extended)

def newSDDCnetworks(proxy_url, sessiontoken, display_name, gateway_address, dhcp_range, domain_name, routing_type):
    """ Creates a new SDDC Network. L2 VPN networks are not currently supported. """
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/segments/" + display_name)
    # print(myURL)
    if routing_type == "DISCONNECTED" :
        json_data = {
                "subnets":[{"gateway_address":gateway_address}],
                "type":routing_type,
                "display_name":display_name,
                "advanced_config":{"connectivity":"OFF"},
                "id":display_name
                }
        response = requests.put(myURL, headers=myHeader, json=json_data)
        json_response_status_code = response.status_code
        if json_response_status_code == 200 :
            print("The following network has been created:")
            table = PrettyTable(['Name', 'Gateway', 'Routing Type'])
            table.add_row([display_name, gateway_address, routing_type])
            return table
        else :
            print("There was an error. Try again.")
            return
    else:
        if dhcp_range == "none" :
            json_data = {
                "subnets":[{"gateway_address":gateway_address}],
                "type":routing_type,
                "display_name":display_name,
                "advanced_config":{"connectivity":"ON"},
                "id":display_name
                }
            response = requests.put(myURL, headers=myHeader, json=json_data)
            json_response_status_code = response.status_code
            if json_response_status_code == 200 :
                print("The following network has been created:")
                table = PrettyTable(['Name', 'Gateway', 'Routing Type'])
                table.add_row([display_name, gateway_address, routing_type])
                return table
            else :
                print("There was an error. Try again.")
                return
        else :
            json_data = {
                "subnets":[{"dhcp_ranges":[dhcp_range],
                "gateway_address":gateway_address}],
                "type":routing_type,
                "display_name":display_name,
                "domain_name":domain_name,
                "advanced_config":{"connectivity":"ON"},
                "id":display_name
                }
            response = requests.put(myURL, headers=myHeader, json=json_data)
            json_response_status_code = response.status_code
            if json_response_status_code == 200 :
                print("The following network has been created:")
                table = PrettyTable(['Name', 'Gateway', 'DHCP', 'Domain Name', 'Routing Type'])
                table.add_row([display_name, gateway_address, dhcp_range, domain_name, routing_type])
                return table
            else :
                print("There was an error. Try again.")
                return

def newSDDCStretchednetworks(proxy_url, sessiontoken, display_name, tunnel_id, l2vpn_path):
    """ Creates a new stretched/extended Network. """
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/segments/" + display_name)
    print(myURL)
    json_data = {
                "type":"EXTENDED",
                "display_name":display_name,
                "id":display_name,
                "advanced_config":{"connectivity":"ON"},
                "l2_extension": {
                "l2vpn_paths": [
                l2vpn_path
                ],
                "tunnel_id": tunnel_id}
    }
    print(json_data)
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    if json_response_status_code == 200 :
        print("The following network has been created:")
        table = PrettyTable(['Name', 'Tunnel ID', 'Routing Type'])
        table.add_row([display_name, tunnel_id, "extended"])
        return table
    else :
        print("There was an error. Try again.")
        return

def removeSDDCNetworks(proxy_url, sessiontoken, network_id):
    """ Remove an SDDC Network """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/segments/" + network_id)
    response = requests.delete(myURL, headers=myHeader)
    json_response = response.status_code
    # print(json_response)
    # Unfortunately, the response status code is always 200 whether or not we delete an existing or non-existing network segment.
    if json_response == 200 :
        print("The network " + network_id + " has been deleted")
    else :
        print("There was an error. Try again.")
    return

def getSDDCNAT(proxy_url, sessiontoken):
    """ Gets the SDDC Nat Rules """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    json_response_status_code = response.status_code
    if json_response_status_code == 200:
        sddc_NAT = json_response['results']
        table = PrettyTable(['ID', 'Name', 'Public IP', 'Ports', 'Internal IP', 'Enabled?'])
        for i in sddc_NAT:
            if 'destination_network' in i:
                table.add_row([i['id'], i['display_name'], i['destination_network'], i['translated_ports'], i['translated_network'], i['enabled']])
            else:
                table.add_row([i['id'], i['display_name'], i['translated_network'], "any", i['source_network'], i['enabled']])
        return table
    else:
        print("There was an issue. Try again.")
        return

def getSDDCNATStatistics(proxy_url, sessiontoken, nat_id):
    ### Displays stats for a specific NAT rule. Note the results are a table with 2 entries.  ###
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules/" + nat_id + "/statistics" )
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    json_response = response.json()
    json_response_status_code = response.status_code
    if json_response_status_code == 200:
        sddc_NAT_stats = json_response['results'][0]['rule_statistics']
        table = PrettyTable(['NAT Rule', 'Active Sessions', 'Total Bytes', 'Total Packets'])
        for i in sddc_NAT_stats:
            #  For some reason, the API returns an entry with null values and one with actual data. So I am removing this entry. 
            if (i['active_sessions'] == 0) and (i['total_bytes'] == 0) and (i['total_packets'] == 0):
                # What this code does is simply check if all entries are empty and skip (pass below) before writing the stats.
                pass
            else:
                table.add_row([nat_id, i['active_sessions'], i['total_bytes'], i['total_packets']])
        return table
    else:
        print("There was an issue.")
        return

def newSDDCNAT(proxy_url, sessiontoken, display_name, action, translated_network, source_network, service, translated_port, logging, status):
    """ Creates a new NAT rule """
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules/" + display_name)
    if action == "any" or action == "REFLEXIVE":
        json_data = {
        "action": "REFLEXIVE",
        "translated_network": translated_network,
        "source_network": source_network,
        "sequence_number": 0,
        "logging": logging,
        "enabled": status,
        "scope":["/infra/labels/cgw-public"],
        "firewall_match":"MATCH_INTERNAL_ADDRESS",
        "id": display_name}
        response = requests.put(myURL, headers=myHeader, json=json_data)
        json_response_status_code = response.status_code
        return json_response_status_code
    else:
        json_data = {
        "action": "DNAT",
        "destination_network": translated_network,
        "translated_network": source_network,
        "translated_ports": translated_port,
        "service":("/infra/services/"+service),
        "sequence_number": 0,
        "logging": logging,
        "enabled": status,
        "scope":["/infra/labels/cgw-public"],
        "firewall_match":"MATCH_INTERNAL_ADDRESS",
        "id": display_name}
        response = requests.put(myURL, headers=myHeader, json=json_data)
        json_response_status_code = response.status_code
        return json_response_status_code

def removeSDDCNAT(proxy_url, sessiontoken, id):
    """ Remove a NAT rule """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules/" + id)
    response = requests.delete(myURL, headers=myHeader)
    return response

def getSDDCVPN(proxy_url, sessiontoken):
    """ Gets the configured Site-to-Site VPN """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/sessions")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    json_response_status_code = response.status_code
    if json_response_status_code == 200:
        sddc_VPN = json_response['results']
        table = PrettyTable(['Name', 'ID', 'Local Address', 'Remote Address'])
        for i in sddc_VPN:
            table.add_row([i['display_name'], i['id'], i['local_endpoint_path'].strip("/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/local-endpoints/"), i['peer_address']])
        return table
    else:
        print("There was an issue.")
        return

def removeSDDCVPN(proxy_url, sessiontoken, id):
    """ Remove a VPN session rule """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/sessions/" + id)
    response = requests.delete(myURL, headers=myHeader)
    return response

def newSDDCIPSecVpnIkeProfile(proxy_url, sessiontoken, display_name):
    """ Creates the configured IPSec VPN Ike Profile """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/ipsec-vpn-ike-profiles/" + display_name)
    print("PUT API call to "+myURL)
    json_data = {
    "resource_type":"IPSecVpnIkeProfile",
    "display_name": display_name,
    "id": display_name,
    "encryption_algorithms":["AES_128"],
    "digest_algorithms":["SHA2_256"],
    "dh_groups":["GROUP14"],
    "ike_version":"IKE_V2"
    }
    print("Payload Content:")
    print(json_data)
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCIPSecVpnIkeProfile(proxy_url, sessiontoken, id):
    """ Remove a VPN session rule """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/ipsec-vpn-ike-profiles/" + id)
    response = requests.delete(myURL, headers=myHeader)
    return response

def newSDDCIPSecVpnTunnelProfile(proxy_url, sessiontoken, display_name):
    """ Creates the configured IPSec VPN Tunnel Profile """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/ipsec-vpn-tunnel-profiles/" + display_name)
    print("PUT API call to "+myURL)
    json_data = {
    "resource_type":"IPSecVpnTunnelProfile",
    "display_name": display_name,
    "id": display_name,
    "encryption_algorithms":["AES_GCM_128"],
    "digest_algorithms":[],
    "dh_groups":["GROUP14"],
    "enable_perfect_forward_secrecy":True
    }
    print("Payload Content:")
    print(json_data)
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCIPSecVpnTunnelProfile(proxy_url, sessiontoken, id):
    """ Remove a VPN Tunnel Profile  rule """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/ipsec-vpn-tunnel-profiles/" + id)
    response = requests.delete(myURL, headers=myHeader)
    return response

def newSDDCIPSecVpnSession(proxy_url, sessiontoken, display_name, endpoint, peer_ip):
    """ Creates the configured IPSec VPN Tunnel Profile """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/sessions/" + display_name)
    print("PUT API call to "+myURL)
    json_data = {
    "resource_type":"RouteBasedIPSecVpnSession",
    "display_name": display_name,
    "id": display_name,
    "tcp_mss_clamping":{"direction":"NONE"},
    "peer_address":peer_ip,
    "peer_id":peer_ip,
    "psk":"None",
    "tunnel_profile_path": ("/infra/ipsec-vpn-tunnel-profiles/" + display_name),
    "ike_profile_path":("/infra/ipsec-vpn-ike-profiles/" + display_name),
    "local_endpoint_path":"/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/local-endpoints/" + endpoint,
    "tunnel_interfaces":[
        {
        "ip_subnets":[
            {
                "ip_addresses":[
                    "169.254.31.249"
                ],
                "prefix_length":30
            }
        ]
        }]
    }
    print("Payload Content:")
    print(json_data)
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code   

def newSDDCL2VPN(proxy_url, sessiontoken, display_name):
    """ Creates the configured L2 VPN """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l2vpn-services/default/sessions/" + display_name)
    print("PUT API call to "+myURL)
    json_data = {
    "transport_tunnels": [
        "/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/sessions/" + display_name
    ],
    "resource_type": "L2VPNSession",
    "id": display_name,
    "display_name": "L2VPN",
}
    print("Payload Content:")
    print(json_data)
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCL2VPN(proxy_url, sessiontoken, id):
    """ Remove a L2VPN """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l2vpn-services/default/sessions/" + id)
    response = requests.delete(myURL, headers=myHeader)
    return response

def getSDDCVPNIpsecProfiles(proxy_url, sessiontoken):
    """ Gets the VPN IKE IPSecProfiles """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/ipsec-vpn-ike-profiles")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_VPN_ipsec_profiles = json_response['results']
    table = PrettyTable(['Name', 'ID', 'IKE Version', 'Digest', 'DH Group', 'Encryption'])
    for i in sddc_VPN_ipsec_profiles:
        table.add_row([i['display_name'], i['id'], i['ike_version'], i['digest_algorithms'], i['dh_groups'], i['encryption_algorithms']])
    return table

def getSDDCVPNIpsecTunnelProfiles(proxy_url, sessiontoken):
    """ Gets the IPSec tunnel Profiles """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/ipsec-vpn-tunnel-profiles")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_VPN_ipsec_tunnel_profiles = json_response['results']
    table = PrettyTable(['Name', 'ID', 'Digest', 'DH Group', 'Encryption'])
    for i in sddc_VPN_ipsec_tunnel_profiles:
        table.add_row([i['display_name'], i['id'], i['digest_algorithms'], i['dh_groups'], i['encryption_algorithms']])
    return table

def getSDDCL2VPNServices(proxy_url, sessiontoken):
    """ Gets the L2VPN services """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l2vpn-services/default")
    response = requests.get(myURL, headers=myHeader)
    i = response.json()
    table = PrettyTable(['Name', 'ID', 'mode'])
    table.add_row([i['display_name'], i['id'], i['mode']])
    return table

def getSDDCL2VPNSession(proxy_url, sessiontoken):
    """ Gets the L2VPN sessions """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l2vpn-services/default/sessions")
    response = requests.get(myURL, headers=myHeader)
    i = response.json()
    sddc_l2vpn_sessions = i['results']
    table = PrettyTable(['Name', 'ID', 'Enabled?'])
    for i in sddc_l2vpn_sessions:
        table.add_row([i['display_name'], i['id'], i['enabled']])
    return table

def getSDDCL2VPNSessionPath(proxy_url, sessiontoken):
    """ Gets the L2VPN sessions """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l2vpn-services/default/sessions")
    response = requests.get(myURL, headers=myHeader)
    i = response.json()
    sddc_l2vpn_path = i['results'][0]['path']
    return sddc_l2vpn_path


def getSDDCVPNIpsecEndpoints(proxy_url, sessiontoken):
    """ Gets the IPSec Local Endpoints """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/local-endpoints")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_VPN_ipsec_endpoints = json_response['results']
    table = PrettyTable(['Name', 'ID', 'Address'])
    for i in sddc_VPN_ipsec_endpoints:
        table.add_row([i['display_name'], i['id'], i['local_address']])
    return table

def getSDDCCGWRule(proxy_url, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/gateway-policies/default/rules")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_CGWrules = json_response['results']
    table = PrettyTable(['id', 'Name','Source','Destination', 'Action', 'Applied To', 'Sequence Number'])
    for i in sddc_CGWrules:
        # a, b and c are used to strip the infra/domain/cgw terms from the strings for clarity.
        a = i['source_groups']
        a = [z.replace('/infra/domains/cgw/groups/','') for z in a]
        a = [z.replace('/infra/tier-0s/vmc/groups/','') for z in a]
        b= i['destination_groups']
        b = [z.replace('/infra/domains/cgw/groups/','') for z in b]
        b = [z.replace('/infra/tier-0s/vmc/groups/','') for z in b]
        c= i['scope']
        c = [z.replace('/infra/labels/cgw-','') for z in c]
        table.add_row([i['id'], i['display_name'], a, b, i['action'], c, i['sequence_number']])
    return table

def getSDDCDFWExcludList (proxy_url, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/settings/firewall/security/exclude-list")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_DFWExcludeMember = json_response['members']
    return sddc_DFWExcludeMember
#     table = PrettyTable(['id', 'Name','Source','Destination', 'Action', 'Applied To', 'Sequence Number'])
#     for i in sddc_CGWrules:
#         # a, b and c are used to strip the infra/domain/cgw terms from the strings for clarity.
#         a = i['source_groups']
#         a = [z.replace('/infra/domains/cgw/groups/','') for z in a]
#         a = [z.replace('/infra/tier-0s/vmc/groups/','') for z in a]
#         b= i['destination_groups']
#         b = [z.replace('/infra/domains/cgw/groups/','') for z in b]
#         b = [z.replace('/infra/tier-0s/vmc/groups/','') for z in b]
#         c= i['scope']
#         c = [z.replace('/infra/labels/cgw-','') for z in c]
#         table.add_row([i['id'], i['display_name'], a, b, i['action'], c, i['sequence_number']])
#     return table

def setSDDCDFWExcludList (proxy_url, sessiontoken, groups):
    #myHeader = {'csp-auth-token': sessiontoken}
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    myURL = (proxy_url_short + "policy/api/v1/infra/settings/firewall/security/exclude-list")
    exclusion_payload = {"members": groups}
    response = requests.patch(myURL, headers=myHeader, data=json.dumps(exclusion_payload))
    json_response_status_code = response.status_code
    return json_response_status_code


def getSDDCMGWRule(proxy_url, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/mgw/gateway-policies/default/rules")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_MGWrules = json_response['results']
    table = PrettyTable(['ID', 'Name', 'Source', 'Destination', 'Services', 'Action', 'Sequence Number'])
    for i in sddc_MGWrules:
        # a and b are used to strip the infra/domain/mgw terms from the strings for clarity.
        a = i['source_groups']
        a = [z.replace('/infra/domains/mgw/groups/','') for z in a]
        b= i['destination_groups']
        b = [z.replace('/infra/domains/mgw/groups/','') for z in b]
        c = i['services']
        c = [z.replace('/infra/services/','') for z in c]
        table.add_row([i['id'], i['display_name'], a, b, c, i['action'], i['sequence_number']])
    return table

def getSDDCDFWSection(proxy_url, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/security-policies/")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_DFWsection = json_response['results']
    table = PrettyTable(['id', 'Name','Category', 'Sequence Number'])
    for i in sddc_DFWsection:
        table.add_row([i['id'], i['display_name'], i['category'], i['sequence_number']])
    return table

def newSDDCDFWSection(proxy_url, sessiontoken, display_name, category):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/security-policies/" + display_name)
    json_data = {
    "resource_type":"SecurityPolicy",
    "display_name": display_name,
    "id": display_name,
    "category": category,
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCDFWSection(proxy_url, sessiontoken, section_id):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/security-policies/" + section_id)
    response = requests.delete(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    return json_response_status_code

def getSDDCDFWRule(proxy_url, sessiontoken, section):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/security-policies/" + section + "/rules")
    response = requests.get(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    if json_response_status_code != 200:
        print("No section found.")
    else:
        json_response = response.json()
        sddc_DFWrules = json_response['results']
        table = PrettyTable(['ID', 'Name', 'Source', 'Destination', 'Services', 'Action', 'Sequence Number'])
        for i in sddc_DFWrules:
            # a and b are used to strip the infra/domain/mgw terms from the strings for clarity.
            a = i['source_groups']
            a = [z.replace('/infra/domains/cgw/groups/','') for z in a]
            a = [z.replace('/infra/tier-0s/vmc/groups/','') for z in a]
            b= i['destination_groups']
            b = [z.replace('/infra/domains/cgw/groups/','') for z in b]
            b = [z.replace('/infra/tier-0s/vmc/groups/','') for z in b]
            c = i['services']
            c = [z.replace('/infra/services/','') for z in c]
            table.add_row([i['id'], i['display_name'], a, b, c, i['action'], i['sequence_number']])
        return table

def newSDDCDFWRule(proxy_url, sessiontoken, display_name, source_groups, destination_groups, services, action, section, sequence_number):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/security-policies/" + section + "/rules/" + display_name)
    json_data = {
    "action": action,
    "destination_groups": destination_groups,
    "direction": "IN_OUT",
    "disabled": False,
    "display_name": display_name,
    "id": display_name,
    "ip_protocol": "IPV4_IPV6",
    "logged": False,
    "profiles": [ "ANY" ],
    "resource_type": "Rule",
    "services": services,
    "source_groups": source_groups,
    "sequence_number": sequence_number
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCDFWRule(proxy_url, sessiontoken, section, rule_id):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/security-policies/" + section + "/rules/" + rule_id)
    response = requests.delete(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    return json_response_status_code

def newSDDCCGWRule(proxy_url, sessiontoken, display_name, source_groups, destination_groups, services, action, scope, sequence_number):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/gateway-policies/default/rules/" + display_name)
    json_data = {
    "action": action,
    "destination_groups": destination_groups,
    "direction": "IN_OUT",
    "disabled": False,
    "display_name": display_name,
    "id": display_name,
    "ip_protocol": "IPV4_IPV6",
    "logged": False,
    "profiles": [ "ANY" ],
    "resource_type": "Rule",
    "scope": scope,
    "services": services,
    "source_groups": source_groups,
    "sequence_number": sequence_number
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    print(response)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCCGWRule(proxy_url, sessiontoken, rule_id):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/cgw/gateway-policies/default/rules/" + rule_id)
    response = requests.delete(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    return json_response_status_code


def newSDDCMGWRule(proxy_url, sessiontoken, display_name, source_groups, destination_groups, services, action, sequence_number):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/mgw/gateway-policies/default/rules/" + display_name)
    json_data = {
    "action": action,
    "destination_groups": destination_groups,
    "direction": "IN_OUT",
    "disabled": False,
    "display_name": display_name,
    "id": display_name,
    "ip_protocol": "IPV4_IPV6",
    "logged": False,
    "profiles": [ "ANY" ],
    "resource_type": "Rule",
    "scope": ["/infra/labels/mgw"],
    "services": services,
    "source_groups": source_groups,
    "sequence_number": sequence_number
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCMGWRule(proxy_url, sessiontoken, rule_id):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/domains/mgw/gateway-policies/default/rules/" + rule_id)
    response = requests.delete(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    return json_response_status_code


def getSDDCVPNSTATS(proxy_url, sessiontoken, tunnelID):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/sessions/" + tunnelID + "/statistics")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_VPN_statistics = json_response['results'][0]['policy_statistics'][0]['tunnel_statistics']
    table = PrettyTable(['Status', 'Packets In', 'Packets Out'])
    for i in sddc_VPN_statistics:
        table.add_row([i['tunnel_status'], i['packets_in'], i['packets_out']])
    return table

def getSDDCVPNServices(proxy_url, sessiontoken, vpn_id):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/ipsec-vpn-services/default/sessions/" + vpn_id)
    response = requests.get(myURL, headers=myHeader)
    print(myURL)
    i = response.json()
    print(i)
    table = PrettyTable(['Name', 'Id', 'Peer'])
    table.add_row([i['display_name'], i['id'], i['peer_address']])
    return table

def getSDDCPublicIP(proxy_url, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/public-ips")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_public_ips = json_response['results']
    table = PrettyTable(['IP', 'id', 'Notes'])
    for i in sddc_public_ips:
        table.add_row([i['ip'], i['id'], i['display_name']])
    return table

def setSDDCPublicIP(proxy_url, sessiontoken, notes, ip_id):
    """ Update the description of an existing  public IP for compute workloads."""
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/public-ips/" + ip_id)
    json_data = {
    "display_name" : notes
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def newSDDCPublicIP(proxy_url, sessiontoken, notes):
    """ Gets a new public IP for compute workloads. Requires a description to be added to the public IP."""
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    myURL = (proxy_url_short + "cloud-service/api/v1/infra/public-ips/" + notes)
    json_data = {
    "display_name" : notes
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def removeSDDCPublicIP(proxy_url, sessiontoken, ip_id):
    """ Removes a public IP. """
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/public-ips/" + ip_id)
    response = requests.delete(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    return json_response_status_code


def getSDDCMTU(proxy_url,sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/external/config")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_MTU = json_response['intranet_mtu']
    return sddc_MTU

def setSDDCMTU(proxy_url,sessiontoken,mtu):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/external/config")
    json_data = {
    "intranet_mtu" : mtu
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def getSDDCShadowAccount(proxy_url,sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/accounts")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_shadow_account = json_response['shadow_account']
    return sddc_shadow_account

def getSDDCBGPAS(proxy_url,sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/direct-connect/bgp")
    response = requests.get(myURL, headers=myHeader)
    SDDC_BGP = response.json()
    SDDC_BGP_AS = SDDC_BGP['local_as_num']
    return SDDC_BGP_AS

def setSDDCBGPAS(proxy_url,sessiontoken,asn):
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = (proxy_url_short + "cloud-service/api/v1/infra/direct-connect/bgp")
    json_data = {
    "local_as_num": asn
    }
    response = requests.patch(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code
    
def getSDDCBGPVPN(proxy_url,sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/direct-connect/bgp")
    response = requests.get(myURL, headers=myHeader)
    SDDC_BGP = response.json()
    SDDC_BGP_VPN = SDDC_BGP['route_preference']
    
    if SDDC_BGP_VPN == "VPN_PREFERRED_OVER_DIRECT_CONNECT":
        return "The preferred path is over VPN, with Direct Connect as a back-up."
    else:
        return "The preferred path is over Direct Connect, with VPN as a back-up."


def getSDDCConnectedVPC(proxy_url,sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/linked-vpcs")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_connected_vpc = json_response['results'][0]
    mySecondURL = (proxy_url + "/cloud-service/api/v1/infra/linked-vpcs/" + sddc_connected_vpc['linked_vpc_id'] + "/connected-services")
    response_second = requests.get(mySecondURL, headers=myHeader)
    sddc_connected_vpc_services = response_second.json()
    table = PrettyTable(['Customer-Owned Account', 'Connected VPC ID', 'Subnet', 'Availability Zone', 'ENI', 'Service Access'])
    table.add_row([sddc_connected_vpc['linked_account'], sddc_connected_vpc['linked_vpc_id'], sddc_connected_vpc['linked_vpc_subnets'][0]['cidr'], sddc_connected_vpc['linked_vpc_subnets'][0]['availability_zone'], sddc_connected_vpc['active_eni'],sddc_connected_vpc_services['results'][0]['enabled']])
    return table

def setSDDCConnectedServices(proxy_url,sessiontoken, value):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/cloud-service/api/v1/infra/linked-vpcs")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_connected_vpc = json_response['results'][0]
    mySecondURL = (proxy_url + "/cloud-service/api/v1/infra/linked-vpcs/" + sddc_connected_vpc['linked_vpc_id'] + "/connected-services/s3")
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    json_data = {
    "name": "s3" ,
    "enabled": value
    }
    thirdresponse = requests.put(mySecondURL, headers=myHeader, json=json_data)
    json_response_status_code = thirdresponse.status_code
    return json_response_status_code

def getSDDCGroups(proxy_url,sessiontoken,gw):
    """ Gets the SDDC Groups. Use 'mgw' or 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups"
    # print(myURL)
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    # print(json_response)
    sddc_group = json_response['results']
    table = PrettyTable(['ID', 'Name'])
    for i in sddc_group:
        table.add_row([i['id'], i['display_name']])
    # print(table)
    return table

def getSDDCGroup(proxy_url,sessiontoken,gw,group_id):
    """ Gets a single SDDC Group. Use 'mgw' or 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    # Checking for groups with defined criteria with the following command. 
    if 'expression' in json_response:
        group_criteria = json_response['expression'][0]
        if group_criteria["resource_type"] == "IPAddressExpression":
            group_IP_list = group_criteria['ip_addresses']
            print("The group " + group_id + " is based on the IP addresses criteria:")
            # print(group_IP_list,sep='\n') would work best with Python3.
            print(group_IP_list)
        elif group_criteria["resource_type"] == "ExternalIDExpression":
            group = json_response['expression']
            if group[0]['member_type'] == "VirtualMachine":
                myNewURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id + "/members/virtual-machines"
                new_response = requests.get(myNewURL, headers=myHeader)
                new_second_response = new_response.json()
                new_second_extra = new_second_response['results']
                new_table = PrettyTable(['Name'])
                for i in new_second_extra:
                    new_table.add_row([i['display_name']])
                print("\n The following Virtual Machines are part of the Group.")
                print(new_table)        
        elif group_criteria["resource_type"] == "Condition":
            group = json_response['expression']
            print("The group " + group_id + " is based on these criteria:")
            table = PrettyTable(['Member Type', 'Key', 'Operator', 'Value'])
            for i in group:
                table.add_row([i['member_type'], i['key'], i['operator'], i['value']])
            print(table)
            if group[0]['member_type'] == "VirtualMachine":
                myNewURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id + "/members/virtual-machines"
                new_response = requests.get(myNewURL, headers=myHeader)
                new_second_response = new_response.json()
                new_second_extra = new_second_response['results']
                new_table = PrettyTable(['Name'])
                for i in new_second_extra:
                    new_table.add_row([i['display_name']])
                print("\n The following Virtual Machines are part of the Group.")
                print(new_table)
            else:
                myNewURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id + "/members/ip-addressesa"
                new_response = requests.get(myNewURL, headers=myHeader)
                new_second_response = new_response.json()
                new_second_extra = new_second_response['results']
                new_table = PrettyTable(['Name'])
                for i in new_second_extra:
                    new_table.add_row([i['display_name']])
                print("\n The following IP addresses are part of the Group.")
                print(new_table)
        else:
            print("Incorrect syntax. Try again.")
    else:
        print("This group has no criteria defined.")
    return

def removeSDDCGroup(proxy_url, sessiontoken, gw, group_id):
    """ Remove an SDDC Group """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id
    response = requests.delete(myURL, headers=myHeader)
    json_response = response.status_code
    print(json_response)
    if json_response == 200 :
        print("The group " + group_id + " has been deleted")
    else :
        print("There was an error. Try again.")
    return json_response

def newSDDCGroupIPaddress(proxy_url,sessiontoken,gw,group_id,ip_addresses):
    """ Creates a single SDDC Group based on IP addresses. Use 'mgw' or 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id
    json_data = {
    "expression" : [ {
      "ip_addresses" : ip_addresses,
      "resource_type" : "IPAddressExpression"
    } ],
    "id" : group_id,
    "display_name" : group_id,
    "resource_type" : "Group"}
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def newSDDCGroupCriteria(proxy_url,sessiontoken,gw,group_id,member_type,key,operator,value):
    """ Creates a single SDDC Group based on a criteria. Use 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id
    json_data = {
    "expression" : [ {
      "member_type" : member_type,
      "key" : key,
      "operator" : operator,
      "value" : value,
      "resource_type" : "Condition"
    } ],
    "id" : group_id,
    "display_name" : group_id,
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

def getVMExternalID(proxy_url,sessiontoken,vm_name):
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    VMlist_url = (proxy_url_short + "policy/api/v1/infra/realized-state/enforcement-points/vmc-enforcementpoint/virtual-machines")
    response = requests.get(VMlist_url, headers=myHeader)
    response_dictionary = response.json()
    extracted_dictionary = response_dictionary['results']
    # Below, we're extracting the Python dictionary for the specific VM and then we extract the external_ID/ Instance UUID from the dictionary.
    extracted_VM = next(item for item in extracted_dictionary if item["display_name"] == vm_name)
    extracted_VM_external_id = extracted_VM['external_id']
    return extracted_VM_external_id

def getVMs(proxy_url,sessiontoken):
    """ Gets a list of all compute VMs, with their power state and their external ID. """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    VMlist_url = (proxy_url_short + "policy/api/v1/infra/realized-state/enforcement-points/vmc-enforcementpoint/virtual-machines")
    response = requests.get(VMlist_url, headers=myHeader)
    response_dictionary = response.json()
    extracted_dictionary = response_dictionary['results']
    table = PrettyTable(['Display_Name', 'Status', 'External_ID'])
    for i in extracted_dictionary:
        table.add_row([i['display_name'], i['power_state'], i['external_id']])
    return table

def newSDDCGroupGr(proxy_url,sessiontoken,gw,group_id,member_of_group):
    """ Creates a single SDDC group and adds 'member_of_group' to the group membership"""
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id
    # Example JSON data
    #json_data = {
    #"expression" : [ {
    #    "paths": [ "/infra/domains/cgw/groups/Group1", "/infra/domains/cgw/groups/Group2"],
    #    "resource_type": "PathExpression",
    #    "parent_path": "/infra/domains/cgw/groups/" + group_id
    #} ],
    #"extended_expression": [],
    #"id" : group_id,
    #"resource_type" : "Group",
    #"display_name" : group_id,
    #}

    # Split the group members into a list
    group_list = member_of_group.split(',')
    group_list_with_path = []
    for item in group_list:
        group_list_with_path.append('/infra/domains/cgw/groups/' + item)

    #The data portion of the expression key is a dictionar
    expression_data = {}
    expression_data["paths"] = group_list_with_path
    expression_data["resource_type"] = "PathExpression"
    expression_data["parent_path"] = "/infra/domains/cgw/groups/" + group_id

    #The expression key itself is a list
    expression_list = []
    expression_list.append(expression_data)

    #Build the JSON object
    json_data = {}
    json_data["expression"] = expression_list
    json_data["extended_expression"] = []
    json_data["id"] = group_id
    json_data["resource_type"] = "Group"
    json_data["display_name"] = group_id

    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    print(response.text)
    return json_response_status_code

def newSDDCGroupVM(proxy_url,sessiontoken,gw,group_id,vm_list):
    """ Creates a single SDDC Group based on a list of VM external_id. Use 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups/" + group_id
    json_data = {
    "expression" : [ {
        "member_type" : "VirtualMachine",
        "external_ids" : vm_list,
        "resource_type" : "ExternalIDExpression"
    } ],
    "id" : group_id,
    "display_name" : group_id,
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code
    
def getSDDCServices(proxy_url,sessiontoken):
    """ Gets the SDDC Services """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/services"
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_services = json_response['results']
    table = PrettyTable(['ID', 'Name'])
    for i in sddc_services:
        table.add_row([i['id'], i['display_name']])
    return table

def getSDDCService(proxy_url,sessiontoken,service_id):
    """ Gets the SDDC Services """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/services/" + service_id 
    response = requests.get(myURL, headers=myHeader)
    json_response_status_code = response.status_code
    if json_response_status_code != 200:
        print("This service does not exist.")
    else:
        json_response = response.json()
        service_entries = json_response['service_entries']
        table = PrettyTable(['ID', 'Name', 'Protocol', 'Source Ports', 'Destination Ports'])
        for i in service_entries:
            table.add_row([i['id'], i['display_name'], i['l4_protocol'], i['source_ports'], i['destination_ports']])
        return table

def newSDDCService(proxy_url,sessiontoken,service_id,service_entries):
    """ Create a new SDDC Service based on service_entries """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/services/" + service_id 
    json_data = {
    "service_entries":service_entries,
    "id" : service_id,
    "display_name" : service_id,
    }
    response = requests.put(myURL, headers=myHeader, json=json_data)
    json_response_status_code = response.status_code
    return json_response_status_code

# def newSDDCServiceEntry(proxy_url,sessiontoken,service_entry_id,source_port,destination_port,l4_protocol):
#    """ Create a new SDDC Service Entry """
#    myHeader = {'csp-auth-token': sessiontoken}
#    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
#    # removing 'sks-nsxt-manager' from proxy url to get correct URL
#    myURL = proxy_url_short + "policy/api/v1/infra/services/" + service_id
#    json_data = {
#    "l4_protocol": l4_protocol,
#    "source_ports": source_port_list,
#    "destination_ports" : destination_port_list,
#    "resource_type" : "L4PortSetServiceEntry",
#    "id" : service_entry_id,
#    "display_name" : service_entry_id     }


def removeSDDCService(proxy_url, sessiontoken,service_id):
    """ Remove an SDDC Service """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/services/" + service_id
    response = requests.delete(myURL, headers=myHeader)
    json_response = response.status_code
    print(json_response)
    if json_response == 200 :
        print("The group " + service_id + " has been deleted")
    else :
        print("There was an error. Try again.")
    return


def getSDDCDNS_Zones(proxy_url,sessiontoken):
    """ Gets the SDDC Zones """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/dns-forwarder-zones"
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_dns = json_response['results']
    table = PrettyTable(['ID', 'Name','DNS Domain Names','upstream_servers'])
    for i in sddc_dns:
        table.add_row([i['id'], i['display_name'], i['dns_domain_names'], i['upstream_servers']])
    return table

def getSDDCDNS_Services(proxy_url,sessiontoken,gw):
    """ Gets the DNS Services. Use 'mgw' or 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    # removing 'sks-nsxt-manager' from proxy url to get correct URL
    myURL = proxy_url_short + "policy/api/v1/infra/tier-1s/" + gw + "/dns-forwarder"
    response = requests.get(myURL, headers=myHeader)
    sddc_dns_service = response.json()
    table = PrettyTable(['ID', 'Name', 'Listener IP'])
    table.add_row([sddc_dns_service['id'], sddc_dns_service['display_name'], sddc_dns_service['listener_ip']])
    return table

def createLotsNetworks(proxy_url, sessiontoken,network_number):
    """ Creates lots of networks! """
    myHeader = {"Content-Type": "application/json","Accept": "application/json", 'csp-auth-token': sessiontoken}
    for x in range(0,network_number):
        display_name = "network-name"+str(x)
        myURL = (proxy_url + "/policy/api/v1/infra/tier-1s/cgw/segments/" + display_name)
    #  '/tier-1s/cgw' might only be applicable for multi tier-1s architecture. To be confirmed.
    # print(myURL)
        json_data = {
                "subnets":[{"gateway_address":"10.200."+str(x)+".1/24"}],
                "type":"ROUTED",
                "display_name":display_name,
                "advanced_config":{"connectivity":"ON"},
                "id":"network-test"+str(x)
                }
        response = requests.put(myURL, headers=myHeader, json=json_data)
        json_response_status_code = response.status_code

def getSDDCT0routes(proxy_url, session_token):
    myHeader = {'csp-auth-token': session_token}
    myURL = "{}/policy/api/v1/infra/tier-0s/vmc/routing-table?enforcement_point_path=/infra/sites/default/enforcement-points/vmc-enforcementpoint".format(proxy_url)
    response = requests.get(myURL, headers=myHeader)
    # pretty_data = json.dumps(response.json(), indent=4)
    # print(pretty_data)
    json_response = response.json()
    count = json_response['results'][1]['count']
    for i in range (int(count)):
        print("---------------------------------------")
        print ("Route type:     " + json_response['results'][1]['route_entries'][i]['route_type'])
        print ("Network:        " + json_response['results'][1]['route_entries'][i]['network'])
        print ("Admin distance: " + str(json_response['results'][1]['route_entries'][i]['admin_distance']))
        print ("Next hop:       " + json_response['results'][1]['route_entries'][i]['next_hop'])

def getSDDCEdgeCluster(proxy_url, sessiontoken):
    """ Gets the Edge Cluster ID """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/sites/default/enforcement-points/vmc-enforcementpoint/edge-clusters")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    edge_cluster_id = json_response['results'][0]['id']
    return edge_cluster_id

def getSDDCEdgeNodes(proxy_url, sessiontoken, edge_cluster_id,edge_id):
    """ Gets the Edge Nodes Path """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = proxy_url + "/policy/api/v1/infra/sites/default/enforcement-points/vmc-enforcementpoint/edge-clusters/" + edge_cluster_id + "/edge-nodes"
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    json_response_status_code = response.status_code
    if json_response_status_code == 200:
        edge_path = json_response['results'][edge_id]['path']
        return edge_path
    else:
        print("fail")
    
def getSDDCInternetStats(proxy_url, sessiontoken, edge_path):
    ### Displays counters for egress interface ###
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/interfaces/public-0/statistics?edge_path=" + edge_path + "&enforcement_point_path=/infra/sites/default/enforcement-points/vmc-enforcementpoint")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    json_response_status_code = response.status_code
    if json_response_status_code == 200:
        total_bytes = json_response['per_node_statistics'][0]['tx']['total_bytes']
        return total_bytes      
    else:
        print("fail")

# --------------------------------------------
# ---------------- Main ----------------------
# --------------------------------------------

intent_name = sys.argv[1].lower()
session_token = getAccessToken(Refresh_Token)
proxy = print(os.environ['TF_VAR_nsx_server'])
username = print(os.environ['TF_VAR_nsx_username'])
password = print(os.environ['TF_VAR_nsx_password'])

if intent_name == "append-exclude-list":
    member_list = getSDDCDFWExcludList(proxy,session_token)
    member_list.append(sys.argv[5])
    new_exclude_list = setSDDCDFWExcludList(proxy,session_token, member_list)
    if new_exclude_list == 200:
        print("\n The new exclusion list has been updated.")
    else:
        print("Incorrect syntax. Try again.")