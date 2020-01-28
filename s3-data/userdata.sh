#! /usr/bin/env bash
set -ex

# SCRIPT FOR: Amazon Linux 2 AMI

# requires IAM service role with permissions: 
# {
#    "PolicyVersion": {
#        "Document": {
#            "Version": "2012-10-17",
#            "Statement": [
#                {
#                    "Sid": "VisualEditor0",
#                    "Effect": "Allow",
#                    "Action": [
#                        "s3:PutObject",
#                        "s3:GetObject",
#                        "s3:ListBucket"
#                    ],
#                    "Resource": [
#                        "arn:aws:s3:::launchcode-gisdevops-cert-authority/*",
#                        "arn:aws:s3:::launchcode-gisdevops-cert-authority"
#                    ]
#                }
#            ]
#        }
#    }
# }

# -- ENV VARS -- #
BUCKET_NAME=launchcode-gisdevops-cert-authority
# -- END ENV VARS -- #

# Install Java
yum update -y && yum install -y java-1.8.0-openjdk.x86_64

# Create cert-authority user and config
useradd -M cert-authority
mkdir /opt/cert-authority
mkdir /etc/opt/cert-authority
mkdir /etc/opt/cert-authority/keystore
chown -R cert-authority:cert-authority /opt/cert-authority
chmod 700 /opt/cert-authority

# Write Cert Authority App config file
cat << EOF > /etc/opt/cert-authority/cert-authority.config
CERT_ALIAS=app
SERVER_PORT=443
KEYSTORE_PATH=/etc/opt/cert-authority/keystore/keystore.jks
TRUSTSTORE_PATH=/etc/opt/cert-authority/keystore/truststore.jks
EOF

# Write systemd unit file
cat << EOF > /etc/systemd/system/cert-authority.service
[Unit]
Description=Certificate Authority Sample Application
After=syslog.target

[Service]
# must be run as root to expose port 443
User=root
EnvironmentFile=/etc/opt/cert-authority/cert-authority.config
ExecStart=/usr/bin/java -jar /opt/cert-authority/app.jar
SuccessExitStatus=143
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# pull jar and make executable
aws s3 cp "s3://${BUCKET_NAME}/app.jar" /opt/cert-authority/app.jar
chmod +x /opt/cert-authority/app.jar

# switch to keystore dir for remaining ops
cd /etc/opt/cert-authority/keystore

# pull and run make file
aws s3 cp "s3://${BUCKET_NAME}/Makefile" Makefile

# get public DNS and IP for hostname
# https://unix.stackexchange.com/questions/24355/is-there-a-way-to-get-the-public-dns-address-of-an-instance
PUBLIC_DNS_NAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

make all HOST_ALIAS=app HOSTNAME=$PUBLIC_DNS_NAME HOST_IP=$PUBLIC_IP CLIENTNAME=student-cert

# upload CA and client certs to install locally
aws s3 cp ca.crt "s3://${BUCKET_NAME}/certs/"
aws s3 cp student-cert.crt "s3://${BUCKET_NAME}/certs/"

systemctl enable cert-authority
systemctl start cert-authority
