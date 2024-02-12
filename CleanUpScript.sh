#!/bin/bash

LOG_FILE="/Library/Logs/TrellixProductCleanup.log"
mclog()
{
   echo "[${USER}][`date`] - ${*}" >> ${LOG_FILE}
}

# Check the path of this script
PACKAGE_DIRECTORY="`pwd`"
APP_DIR="/Applications/McAfeeSystemExtensions.app"
TRELLIX_APP_DIR="/Applications/TrellixSystemExtensions.app"
System_extensions_path="/Applications/McAfeeSystemExtensions.app/Contents/MacOS/McAfeeSystemExtensions"
mclog "Cleanup Started"

if [[ $EUID -ne 0 ]]; 
  then
		mclog "This script must be run with sudo or root privilege, Re-run with sudo privilege."
        exit 1
 fi

McAfee_Network_Extension="com.mcafee.CMF.networkextension"
McAfee_Endpoint_Extension="com.mcafee.CMF.endpointsecurity"
Network_version_number=`systemextensionsctl list | grep -i "$McAfee_Network_Extension" | grep -i activated | awk '{ print $5 }' | cut -d/ -f2 | awk -F')' '{print $1}'`
Endpoint_version_number=`systemextensionsctl list | grep -i "$McAfee_Network_Extension" | grep -i activated | awk '{ print $5 }' | cut -d/ -f2 | awk -F')' '{print $1}'`

# Function to Check if Endpoint Extension is Installed
Check_for_Network_extension()
{
    Network_Extension=`systemextensionsctl list | grep -i "$McAfee_Network_Extension" | grep -i activated | awk '{ print $5 }' | cut -d/ -f2 | awk -F')' '{print $1}'`
    if [ -z $Network_Extension ]
        then
            Network_Extension=0
        else
            Network_Extension=1
    fi
        mclog "Network_Extension = $Network_Extension"
        echo $Network_Extension

}
# Function to Check if Endpoint Extension is Installed
Check_for_Endpoint_extension()
{
    Endpoint_Extension=`systemextensionsctl list | grep -i "$McAfee_Endpoint_Extension" | grep -i activated | awk '{ print $5 }' | cut -d/ -f2 | awk -F')' '{print $1}'`
    if [ -z $Endpoint_Extension ]
        then
            Endpoint_Extension=0
        else
            Endpoint_Extension=1
    fi
        mclog "Endpoint_Extension = $Endpoint_Extension"
        echo $Endpoint_Extension

}


# Function to Force Upgrade Endpoint Security Extension
Upgrade_Endpoint_Extension()
{
mclog "Forcing Upgrade of Endpoint Extension"
sudo ${System_extensions_path} INSTALL ${McAfee_Endpoint_Extension} 2>&1
}

# Function to Force Upgrade Network Extension
Upgrade_Network_Extension()
{
mclog "Forcing Upgrade of Network Extension"
sudo ${System_extensions_path} INSTALL ${McAfee_Network_Extension} 2>&1
}

# Function to Copy McAfee SystemExtensions Application to /Applications
Copy_Application()
{
mclog "Copying App to /Applications"
     sudo tar -xvf McAfeeSystemExtensions.zip
     sudo cp -R ./McAfeeSystemExtensions.app /Applications/
     sudo chmod -R 755 /Applications/McAfeeSystemExtensions.app
     sudo chown -R root:admin /Applications/McAfeeSystemExtensions.app
     sudo xattr -r -d com.apple.quarantine /Applications/McAfeeSystemExtensions.app
}
# Function to Copy Trellix SystemExtensions Application to /Applications
Copy_trellix_Application()
{
    mclog "Copying Trellix App to /Applications"
     sudo tar -xvf TrellixSystemExtensions.zip
     sudo cp -R ./TrellixSystemExtensions.app /Applications/
     sudo chmod -R 755 /Applications/TrellixSystemExtensions.app
     sudo chown -R root:admin /Applications/TrellixSystemExtensions.app
     sudo xattr -r -d com.apple.quarantine /Applications/TrellixSystemExtensions.app
}

Network_extension_exists=$(Check_for_Network_extension)
Endpoint_extension_exists=$(Check_for_Endpoint_extension)

#Check for extension and its version number is less than 315 and copy application 
if [ $Network_extension_exists -eq 1 ] || [ $Endpoint_extension_exists -eq 1 ]
then
    if [[ "$Network_version_number" -lt 315 || "$Endpoint_version_number" -lt 315 ]]
        then
            if [ ! -s $APP_DIR ]
                then
                    mclog "No existing McAfeeSystemExtensions.app found in /Applications. Adding it"
                    Copy_Application
                    mclog "Upgrading network and endpoint extensions"
                    Upgrade_Network_Extension
                    Upgrade_Endpoint_Extension
                else
                    mclog "Found Existing Application in /Applications. Continuing"
            fi
    fi
fi

#Copy Trellix system extensions app if it's not there in /Applications
if [ ! -e ${TRELLIX_APP_DIR} ]
    then
        mclog "Copying TrellixSystemextensions app as its not present in the /Applications"
        Copy_trellix_Application
fi
        
mclog "Executing Cleanup Tool"
cd $PACKAGE_DIRECTORY
sudo chmod a+x TrellixCleanUpTool
sudo xattr -cr TrellixCleanUpTool
sudo ./TrellixCleanUpTool 
mclog "Completed Cleanup Tool Execution"

#Check and remove mcafee systemextension application if present
if [ -e ${APP_DIR} ]
   then
        mclog "Removing Copied app from Applications"
        sudo rm -rf $APP_DIR
fi

#Check and remove trellix systemextension application if present
if [ -e ${TRELLIX_APP_DIR} ]
    then
        mclog "Removing Trellix Copied app from Applications"
        sudo rm -rf $TRELLIX_APP_DIR
fi

#To remove Endpoint app icon,if it remains.
if [ -e /Applications/McAfee\ Endpoint\ Security\ for\ Mac.app ]
    then
        sudo rm -rf /Applications/McAfee\ Endpoint\ Security\ for\ Mac.app
fi

mclog "Cleanup Completed"


