#!/bin/bash
echo "####################################"
echo "# Defining Variables               #"
echo "####################################"
CAFILE=/CHANGEME/k5scripts/ca.crt
SERVERCERTFILE=/CHANGEME/k5scripts/server.crt
SERVERKEYFILE=/CHANGEME/k5scripts/server.key
DHFILE=/home/CHANGEME/dh2048.pem
VPN_NW_NAME="VPN NETWORK"
VPN_SN_NAME="VPN SUBNET"
VPN_ROUTER_NAME=VPN_ROUTER
VPN_CIDR="x.x.x.x/24"
VPN_CIDR_GW=x.x.x.1
AZ=uk-1a
VPN_NAME=VPN_Service
SSL_NAME=VPN_SSL_Service
CLIENT_CIDR="x.x.x.x/24"
EXT_NET_ID="XXXXCHANGEMEXXXX"
credential_name=SSL-VPN_VPNCredential
root_ca_name=ca
server_cert_name=server
server_key_name=server_key
dh_name=dh
DNS=\"X.X.X.X\",\"X.X.X.X\"
ADMIN_STATE_UP=true
echo "####################################"
echo "#      Variables Defined           #"
echo "#                                  #"
echo "####################################"
echo "####################################"
echo "#   Processing Cert Files          #"
echo "####################################"
ca_process=$(cat $CAFILE)
servercert_process=$(cat $SERVERCERTFILE)
serverkey_process=$(cat $SERVERKEYFILE)
dhfile_process=$(cat $DHFILE)
echo "####################################"
echo "# Creating Stores                  #"
echo "####################################"
#echo $ca_process
ca_secret_ref=$(curl $KEYMANAGEMENT/v1/$PROJECT_ID/secrets -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d '
{"name":"'"$root_ca_name"'","payload":"'"$ca_process"'","payload_content_type":"text/plain"}' | cut -d '"' -f4)
servercert_secret_ref=$(curl $KEYMANAGEMENT/v1/$PROJECT_ID/secrets -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d '
{"name":"'"$server_cert_name"'","payload": "'"$servercert_process"'","payload_content_type":"text/plain"}' | cut -d '"' -f4)
serverkey_secret_ref=$(curl $KEYMANAGEMENT/v1/$PROJECT_ID/secrets -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d '
{"name":"'"$server_key_name"'","payload": "'"$serverkey_process"'","payload_content_type":"text/plain"}' | cut -d '"' -f4)
dh_secret_ref=$(curl $KEYMANAGEMENT/v1/$PROJECT_ID/secrets -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d '
{"name":"'"$dh_name"'","payload": "'"$dhfile_process"'","payload_content_type":"text/plain"}' | cut -d '"' -f4)


container_name=$(curl $KEYMANAGEMENT/v1/$PROJECT_ID/containers -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d'
{
"name":"'"$credential_name"'",
"type":"generic",
"secret_refs":[
{
"name":"ca",
"secret_ref": "'"$ca_secret_ref"'"
},
{
"name":"server_certificate",
"secret_ref": "'"$servercert_secret_ref"'"
},
{
"name":"server_key",
"secret_ref": "'"$serverkey_secret_ref"'"
},
{
"name":"dh",
"secret_ref": "'"$dh_secret_ref"'"
}
]
}' | cut -d '"' -f4 | cut -d'/' -f7)
echo $container_name

echo "####################################"
echo "#      Stores Created              #"
echo "####################################"
echo "####################################"
echo "#      Create Network              #"
echo "####################################"
network_id=$(curl $NETWORK/v2.0/networks -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d'
{
"network": {"name":"'"$VPN_NW_NAME"'","availability_zone":"'"$AZ"'"}
}
' | jq -r '.network.id')

subnet_id=$(curl $NETWORK/v2.0/subnets -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d'
{
"subnet": {
"name":"'"$VPN_SN_NAME"'",
"network_id":"'"$network_id"'",
"cidr":"'"$VPN_CIDR"'",
"dns_nameservers":['$DNS'],
"ip_version":4,
"gateway_ip":"'"$VPN_CIDR_GW"'",
"availability_zone":"'"$AZ"'"}
}
' | jq -r '.subnet.id')


router_id=$(curl $NETWORK/v2.0/routers -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d'
{
"router": {
"name":"'"$VPN_ROUTER_NAME"'",
"tenant_id":"'"$TENANT_ID"'",
"availability_zone":"'"$AZ"'"}
}
' | jq -r '.router.id')

curl $NETWORK/v2.0/routers/$router_id -X PUT -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d'
{
"router": {
"external_gateway_info":{"network_id":"'"$EXT_NET_ID"'"}}}
' | jq

# Attach router to subnet and trap the port number
port_id=$(curl $NETWORK/v2.0/routers/$router_id/add_router_interface -X PUT -H "X-Auth-Token: $OS_Auth_Token" -H "Content-Type: application/json" -d'
{
"subnet_id": "'"$subnet_id"'"}' | jq -r '.port_id')

floatingip=$(curl -k -s $NETWORK/v2.0/floatingips -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "content-Type:application/json" -d '
{"floatingip": {"floating_network_id":"'"$EXT_NET_ID"'", "port_id":"'"$port_id"'", "availability_zone": "'"$AZ"'"}}
' | jq -r '.floatingip.floating_ip_address') 
echo "####################################"
echo "#      Network Created             #"
echo "####################################"
echo "####################################"
echo "#      Create VPN                  #"
echo "####################################"
vpn_id=$(curl -k -s $NETWORK/v2.0/vpn/vpnservices -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "content-Type:application/json" -d '
{"vpnservice": {
"subnet_id":"'"$subnet_id"'", 
"router_id":"'"$router_id"'",
"name":"'"$VPN_NAME"'",
"admin_state_up":"'"$ADMIN_STATE_UP"'",
"availability_zone": "'"$AZ"'"}}
' | jq -r '.vpnservice.id') 

ssl_id=$(curl -k -s $NETWORK/v2.0/vpn/ssl-vpn-connections -X POST -H "X-Auth-Token: $OS_Auth_Token" -H "content-Type:application/json" -d '
{"ssl_vpn_connection": {
"name":"'"$SSL_NAME"'",
"client_address_pool_cidr":"'"$CLIENT_CIDR"'",
"credential_id":"'"$container_name"'",
"vpnservice_id":"'"$vpn_id"'",
"admin_state_up":"'"$ADMIN_STATE_UP"'",
"protocol":"tcp",
"availability_zone": "'"$AZ"'"}}
' | jq -r '.ssl_vpn_connection.id')
echo "####################################"
echo "#      VPN Created                 #"
echo "####################################"
