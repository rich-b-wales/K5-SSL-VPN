# K5-SSL-VPN
#DISCLAIMER#
Please use this scripts as they were intended. This is my first journey into the world of scripting. Coming from a Windows Architecture background could mean that the scripts are not as optimised as they could be. This script has been based on the following article https://cloudknowhow.wordpress.com/2017/03/10/ssl-vpn/ (Credit Ian Purvis)
###########

Scope: To automatically create a SSL VPN Service on the Fujitsu K5 Service
Pre-Reqs:
  1.) Access to K5
  2.) The CA has been set up in line with the above guidance article
  3.) The following fre available in the execution platform
      ca.crt
      <<servername>>.crt
      <<serername>>.key
      dh2048.pem
  4.) The file servername.crt is amended so that the only text contained is the actual certificate (NB Use a proper text editor for those Windows fans out there :-) ) e.g.
      ---- BEGIN CERTIFICATE----
      #########################
      -----END CERTIFICATE----
  5.) Environment setup script has been run. My version can be found in my utility library.

Script Preparation
1.) Prior to running the script build_vpn.sh ensure that the variables are set in line with your environment specifics. 

Script Logic
The script performs the following tasks
1.) Loads all the certificates into the key repository
2.) Creates a key container.
3.) Creates a network for VPN accessible devices
      Network -> Subnet -> ROUTER -> Associates Router to Ext Network -> Adds Router to Subnet ->  Adds a Floating/Global IP
4.) Creates a VPN service
      VPN Serivce -> SSL VPN Service.
      
Script Execution
The script executes with no variables. 

POST Execution
Record the Global IP address and then configure the client to utilise the tunnel.
