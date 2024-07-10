#podman network create --driver bridge redmine_network

#podman volume create postgres-data

#podman volume create redmine-data

podman  start  postgres 


sleep 3

#podman start redmine 
podman start redmine4.2 


echo "open url: http://10.10.10.1:8080"
