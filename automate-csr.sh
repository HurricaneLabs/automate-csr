#!/bin/bash

# Instructions:
# 1. Fill out the lists of hosts and aliases as necessary below
# 2. Fill out the key size and subject template for the cert details
# 3. Switch to a new directory and run the script. All of the files
#    are created in the current working directory

# Host table. Use the header line below to fill this out. Don't
# forget to remove the example hosts
# FQDN:Local IP:Any NAT IP or vanity names separated by commas
HOSTS='
splunksh1.example.com:192.0.2.1:splunk.example.com,192.168.20.1
splunkes1.example.com:192.0.2.2:splunkes.example.com
splunkix1.example.com:192.0.2.3:
'

# Key size, this should be at least 2048, but 4096 is better.
keysize=4096

# Subject Template. These details often come from the customer, but
# sometimes we have to make it up ourselves also.
subjTmpl='/C=US/ST=Ohio/L=Independence/O=Hurricane Labs/OU=Splunk/CN='

### STOP. Everything else below here is the code.

openssl=`which openssl`
if [ -z "$openssl" ]; then
	echo "You must run this on a host with OpenSSL/LibreSSL CLI tools installed."
	exit 1;
fi

for hoststr in $HOSTS; do
	IFS=: read -ra host <<<"$hoststr"
	IFS=. read -ra fqdn <<<"${host[0]}"
        IFS=, read -ra aliases <<<"${host[2]}"
	echo "### ${fqdn[0]}"
	subjAltName="DNS:${host[0]},DNS:${fqdn[0]},IP:${host[1]}"
	for alias in $aliases; do
		echo "$alias" | egrep -q '^[0-9.]+$'
		if [ "$?" -eq "0" ]; then
			subjAltName="${subjAltName},IP:${alias}"
		else
			subjAltName="${subjAltName},DNS:${alias}"
		fi
	done
	openssl req -new -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nextendedKeyUsage=serverAuth,clientAuth\nsubjectAltName=${subjAltName}")) -extensions SAN -reqexts SAN -out ${fqdn[0]}.csr -subj "$subjTmpl${host[0]}/" -nodes -newkey rsa:${keysize} -keyout ${fqdn[0]}.key
done
