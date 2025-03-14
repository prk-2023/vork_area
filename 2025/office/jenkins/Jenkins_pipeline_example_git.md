### Tutorial: Setting Up Jenkins Pipeline with Podman and Auto-Pulling a Git Repository

This tutorial will guide you through the process of:

1. Deploying Jenkins using **Podman** (a Docker alternative).
2. Writing a Jenkins pipeline that automatically pulls a Git repository every time there's a new commit.

---

### **Step 1: Install Podman on Linux**

#### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y podman
```

#### On Fedora:
```bash
sudo dnf install -y podman
```
---

### **Step 2: Running Jenkins with Podman**

Now that you have **Podman** installed, let’s pull and run the Jenkins container. 
We'll use the official Jenkins Docker image.

1. **Pull the Jenkins Docker Image:**

```bash
podman pull jenkins/jenkins:lts
```

2. **Run the Jenkins Container:**

```bash
podman run -d \
  -p 8080:8080 \
  -p 50000:50000 \
  --name jenkins \
  -v /var/jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

This command will run the Jenkins container in the background:

- `-p 8080:8080` maps the host port 8080 to the container port 8080 (Jenkins web interface).
- `-p 50000:50000` maps the host port 50000 to the Jenkins agent port.
- `-v /var/jenkins_home:/var/jenkins_home` mounts a persistent volume for Jenkins data, so your 
   Jenkins settings and builds are saved.

3. **Access Jenkins:**
   Open your browser and go to `http://localhost:8080`. The Jenkins setup wizard will be available. 

   - You will be prompted to retrieve the Jenkins unlock key from the logs. Use the following command to 
     get the key:

   ```bash
   podman logs jenkins
   ```

   - Copy the key and paste it into the setup wizard.

4. **Install Suggested Plugins**: After unlocking Jenkins, follow the wizard to install the suggested 
   plugins and create an admin user.

---

### **Step 3: Install Git Plugin for Jenkins**

To interact with a Git repository in Jenkins, you'll need to install the **Git plugin**.

1. Go to **Manage Jenkins** → **Manage Plugins**.
2. Select the **Available** tab, search for **Git**, and then install it.
3. After installation, restart Jenkins to apply the changes.

---

### **Step 4: Configure Git in Jenkins**

Next, we need to configure Jenkins to access the Git repository. This involves providing your Git credentials.

1. Go to **Manage Jenkins** → **Configure System**.
2. Scroll down to the **Git** section, and set the **Path to Git executable** 
    (it’s typically `/usr/bin/git`, but it depends on your system).
3. Under **Credentials**, click **Add** to create a new credential for Git access 
   (ex: using SSH or HTTP with username/password). You’ll need your Git repository access credentials for this.

---

### **Step 5: Create a New Pipeline Job**

Now that Jenkins is set up, we will create a pipeline that automatically pulls the latest changes from a 
Git repository.

1. From the Jenkins dashboard, click **New Item**.
2. Enter a name for the project and select **Pipeline**. Then, click **OK**.
3. In the **Pipeline** section, configure your pipeline script.

---

### **Step 6: Writing the Jenkins Pipeline Script**

The pipeline will automatically pull the latest changes from a Git repository whenever there is a commit. 
Here's an example pipeline script:

```groovy
pipeline {
    agent any

    environment {
        // Git repository URL
        GIT_REPO_URL = 'https://github.com/yourusername/your-repository.git'
        // Git credentials ID in Jenkins (if needed)
        GIT_CREDENTIALS_ID = 'your-jenkins-credentials-id'
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    // Pull the latest commit from the Git repository
                    git branch: 'main', url: "${GIT_REPO_URL}", credentialsId: "${GIT_CREDENTIALS_ID}"
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Building the project (optional)'
            }
        }
    }

    triggers {
        // Polling the Git repository for changes
        pollSCM('* * * * *')  // This cron expression checks for changes every minute
    }
}
```

### Explanation of the pipeline:

- **environment block**: 
    This block defines environment variables for the Git repository URL and Git credentials.
  
- **stages block**: 
  - **Clone Repository**: 
    The `git` command is used to clone the repository. The `credentialsId` refers to the Git credentials 
    you added earlier.

  - **Build**: This is a placeholder stage. You can replace this with your actual build steps 
    (e.g., `mvn clean install` for Maven projects).

- **triggers block**:
  - **pollSCM('* * * * *')**: 
    This cron expression tells Jenkins to check for changes in the Git repository every minute. 
    If there is a new commit, Jenkins will automatically pull the changes.

---

### **Step 7: Running the Pipeline**

Once you’ve created the pipeline, you can trigger it manually for the first time by clicking on 
**Build Now**. After that, Jenkins will automatically trigger the pipeline based on changes to the 
Git repository.

---

### **Conclusion**

You’ve now successfully:

- Deployed Jenkins using Podman on your Linux machine.
- Created a Jenkins pipeline that automatically pulls the latest changes from a Git repository whenever 
  there is a new commit.

This setup helps in automating the process of keeping your Jenkins workspace updated with the latest code, 
making it easier to test and build the latest version of your project.

Let me know if you need any more details or have further questions!
