# Deploy and run Jenkins 


## 1. **Run Jenkins in a Podman Container**

   Use the official Jenkins image from Docker Hub and run it with Podman:
   ```bash
   podman run -d \
     -p 8080:8080 \
     -p 50000:50000 \
     --name jenkins \
     jenkins/jenkins:lts
   ```

   - `-d` runs Jenkins in detached mode.
   - `-p 8080:8080` maps the container’s port 8080 to the host’s port 8080.
   - `-p 50000:50000` is used for agent connections.
   - `--name jenkins` gives the container a name (optional).

## 2. **Access Jenkins Web Interface in Container**
   Once the container is running, you can access Jenkins in the same way as on a host machine, by navigating to:
   ```
   http://localhost:8080
   ```

## 3. **Unlock Jenkins in the Container**
   To get the Jenkins unlock key in the container, run the following:
   ```bash
   podman exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

   Copy the password and use it to unlock Jenkins on the web interface.

