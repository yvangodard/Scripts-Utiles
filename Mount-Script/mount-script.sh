#! /bin/bash

scriptname=$(/usr/bin/basename "${0}")
scriptpdir=$(/usr/bin/dirname "${0}")
help="no"
version="Mount-Script α 0.1 -- 2014 -- godardyvan@gmail.com"

help () {
	echo -e "$version\n"
	echo -e "This tool is designed to mount a network sharepoint."
	echo -e "The network volume must be first correctly set in /etc/fstab."
	echo -e "This tool is licensed under the Creative Commons 4.0 BY NC SA licence."
	echo -e "\nDisclamer:"
	echo -e "This tool is provide without any support and guarantee."
	echo -e "\nSynopsis:"
	echo -e "./${scriptname} [-h] | -v <mountpoint>"
	echo -e "\t-h:               prints this help then exit"
	echo -e "Mandatory option:"
	echo -e "\t-v <mountpoint>:  the path to your mountpoint, as defined in /etc/fstab"
	exit 0
}

error () {
	echo -e "\n*** Error ***"
	echo -e ${1}
	echo -e "\n"${version}
	alldone 1
}

alldone () {
	exit ${1}
}

optsCount=0
while getopts "hv:" options
do
	case "$options" in
		h)	help="yes"
						;;
		v)	volume=${OPTARG}
			let optsCount=$optsCount+1
						;;
	esac
done

if [[ ${optsCount} != "1" ]]
	then
        help
        alldone 1
fi

if [[ ${help} = "yes" ]]
	then
	help
fi

# Test if mountpoint exist in /etc/fstab
cat /etc/fstab | grep ${volume} > /dev/null 2>&1
[ $? -ne 0 ] && error "The mountpoint '${volume}' doesn't exist in /etc/fstab"

# Test if mountpoint exists
if [ ! -d ${volume} ]
	then
	echo "The mountpoint '${volume}' doesn't exist. Trying to create with 'mkdir -p ${volume}'"
	mkdir -p ${volume}
	[ $? -ne 0 ] && error "Error while creating volume with 'mkdir -p ${volume}'"
fi

# Test if volume is mounted
mountpoint ${volume} > /dev/null 2>&1
if [ $? -ne 0 ]
	then
	mount ${volume}
	[ $? -ne 0 ] && error "Error while mounting volume '${volume}'"
fi

alldone 0