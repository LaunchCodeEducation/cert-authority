# this file has been customized to support a deployed application

# all original credit to: https://www.baeldung.com/x-509-authentication-in-spring-security
# original Makefile: https://github.com/eugenp/tutorials/blob/71b7954aed845bae4786d002e57fbc7cbcce0564/spring-security-modules/spring-security-x509/keystore/Makefile

# defaults, can be passed as args in any make call to override
PASSWORD=launchcode
KEYSTORE=keystore.jks
TRUSTSTORE=truststore.jks
HOST_ALIAS=localhost
HOSTNAME=localhost
HOST_IP=127.0.0.1
CLIENTNAME=student-cert
CLIENT_PRIVATE_KEY="${CLIENTNAME}_pk"

# CN = Common Name
# OU = Organization Unit
# O  = Organization Name
# L  = Locality Name
# ST = State Name
# C  = Country (2-letter Country Code)
# E  = Email
DNAME_CA='CN=The LaunchCode Foundation Certificate Authority,OU=launchcode.org,O=The LaunchCode Foundation,L=St. Louis,ST=Missouri,C=US'
# For server certificates, the Common Name (CN) must be the hostname
DNAME_HOST='CN=$(HOSTNAME),OU=launchcode.org,O=The LaunchCode Foundation,L=St. Louis,ST=Missouri,C=US'
DNAME_CLIENT='CN=$(CLIENTNAME),OU=launchcode.org,O=The LaunchCode Foundation,L=St. Louis,ST=Missouri,C=US'


all:	clean create-keystore add-host create-truststore add-client

create-keystore:
	# Generate a certificate authority (CA)
	keytool -genkey -alias ca -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) -ext BC=ca:true \
	    -keyalg RSA -keysize 4096 -sigalg SHA512withRSA -keypass $(PASSWORD) \
	    -validity 3650 -dname $(DNAME_CA) \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)

add-host:
	# Generate a host certificate
	keytool -genkey -alias $(HOST_ALIAS) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP)  \
	    -keyalg RSA -keysize 4096 -sigalg SHA512withRSA -keypass $(PASSWORD) \
	    -validity 3650 -dname $(DNAME_HOST) \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)
	# Generate a host certificate signing request
	keytool -certreq -alias $(HOST_ALIAS) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) -ext BC=ca:true \
	    -keyalg RSA -keysize 4096 -sigalg SHA512withRSA \
	    -validity 3650 -file "$(HOSTNAME).csr" \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)
	# Generate signed certificate with the certificate authority
	keytool -gencert -alias ca -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) \
	    -validity 3650 -sigalg SHA512withRSA \
	    -infile "$(HOSTNAME).csr" -outfile "$(HOSTNAME).crt" -rfc \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)
	# Import signed certificate into the keystore
	keytool -import -trustcacerts -alias $(HOST_ALIAS) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) \
	    -file "$(HOSTNAME).crt" \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)

export-authority:
	# Export certificate authority
	keytool -export -alias ca -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) -file ca.crt -rfc \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)


create-truststore: export-authority
	# Import certificate authority into a new truststore
	keytool -import -trustcacerts -noprompt -alias ca -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) -file ca.crt \
	    -keystore $(TRUSTSTORE) -storepass $(PASSWORD)

add-client:
	# Generate client certificate
	keytool -genkey -alias $(CLIENT_PRIVATE_KEY) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) \
	    -keyalg RSA -keysize 4096 -sigalg SHA512withRSA -keypass $(PASSWORD) \
	    -validity 3650 -dname $(DNAME_CLIENT) \
	    -keystore $(TRUSTSTORE) -storepass $(PASSWORD)
	# Generate a host certificate signing request
	keytool -certreq -alias $(CLIENT_PRIVATE_KEY) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) -ext  BC=ca:true \
	    -keyalg RSA -keysize 4096 -sigalg SHA512withRSA \
	    -validity 3650 -file "$(CLIENTNAME).csr" \
	    -keystore $(TRUSTSTORE) -storepass $(PASSWORD)
	# Generate signed certificate with the certificate authority
	keytool -gencert -alias ca -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) \
	    -validity 3650 -sigalg SHA512withRSA \
	    -infile "$(CLIENTNAME).csr" -outfile "$(CLIENTNAME).crt" -rfc \
	    -keystore $(KEYSTORE) -storepass $(PASSWORD)
	# Import signed certificate into the truststore
	keytool -import -noprompt -trustcacerts -alias $(CLIENTNAME) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) \
	    -file "$(CLIENTNAME).crt" \
	    -keystore $(TRUSTSTORE) -storepass $(PASSWORD)
	# Export private certificate for importing into a browser
	keytool -importkeystore -srcalias $(CLIENT_PRIVATE_KEY) -ext san=dns:$(HOSTNAME),ip:$(HOST_IP) \
	    -srckeystore $(TRUSTSTORE) -srcstorepass $(PASSWORD) \
	    -destkeystore "$(CLIENTNAME).p12" -deststorepass $(PASSWORD) \
	    -deststoretype PKCS12
	# Delete client private key as truststore should not contain any private keys
	keytool -delete -alias $(CLIENT_PRIVATE_KEY) \
		-keystore $(TRUSTSTORE) -storepass $(PASSWORD)

clean:
	# Remove generated artifacts
	find . \( -name "$(CLIENTNAME)*" -o -name "$(HOSTNAME)*" -o -name "$(KEYSTORE)" -o -name "$(TRUSTSTORE)" -o -name ca.crt \) -type f -exec rm -f {} \;
