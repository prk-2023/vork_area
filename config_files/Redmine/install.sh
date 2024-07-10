podman network create --driver bridge redmine_network

podman volume create postgres-data

podman volume create redmine-data

podman container  run -d --name postgres  \
    --network redmine_network  \
    -v postgres-data:/var/lib/postgresql/data \
    --restart always -e POSTGRES_PASSWORD='day999' \
    -e POSTGRES_DB='redmine' postgres:latest


sleep 3

podman container run -d \
    --name redmine \
    --network redmine_network \
    -p 8080:3000 -e REDMINE_DB_POSTGRES='postgres' \
    -e REDMINE_DB_DATABASE='redmine' \
    -e REDMINE_DB_PASSWORD='day999'  redmine:latest


echo "open url: http://10.10.10.1:8080"


#TODO: Incorporate smpt server running in a container:
Step 1: Running an SMTP mail server container:
    Create a separate container for running an SMTP mail server, such as Postfix or Exim.
    Configure the mail server container to handle outgoing emails and relay them to the appropriate destination.
    Update the Redmine container to use the SMTP mail server container for sending emails.
    Configure Redmine to use the SMTP settings of the mail server container, including the hostname, port
    authentication credentials, and any other required settings.

Step 2: Update the redmine server with smtp info as below
podman container run -d \
    --name redmine \
    --network redmine_network \
    -p 8080:3000 \
    -e REDMINE_DB_POSTGRES='postgres' \
    -e REDMINE_DB_DATABASE='redmine' \
    -e REDMINE_DB_PASSWORD='day999' \
    -e SMTP_ADDRESS='mailserver' \
    -e SMTP_PORT='25' \
    -e SMTP_USER_NAME='your_username' \
    -e SMTP_PASSWORD='your_password' \
    redmine:latest

NOTE: make sure you start the email server before redmine starts

