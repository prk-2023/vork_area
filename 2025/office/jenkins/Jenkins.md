# Jenkins Overview:

Jenkins is an open-source automation server that is widely used for continuous integration (CI) and 
continuous delivery (CD) in software development. 

It automates parts of the software development lifecycle, especially around building, testing, and 
deploying applications. 

Jenkins helps to streamline development workflows by automating repetitive tasks and providing immediate 
feedback to developers when code changes are made.

### Key Features of Jenkins:

1. Continuous Integration (CI):

    - Jenkins automatically builds and tests code every time a change (commit) is made, ensuring that errors
      are caught early in the development cycle. 
      This helps developers integrate code changes more frequently and easily.
   
2. Pipeline Automation (CD):

    - Jenkins allows the creation of pipelines, which are automated workflows that manage the stages of a
      project's lifecycle. 
      Pipelines can include stages like code compilation, testing, deployment, and more.

3. Extensible and Plugin Support:

    - Jenkins has a vast ecosystem of plugins that can integrate with virtually any tool in the software 
      development lifecycle, such as Git, Docker, Kubernetes, Maven, Gradle, Slack, and many others.

    - You can extend Jenkins' functionality to include custom tools, version control systems, and more.

4. Distributed Builds:

    - Jenkins supports running builds on multiple machines, which can be useful for distributing workload 
      and speeding up the testing process by running tests in parallel.

5. Automation of Repetitive Tasks:

    - Tasks like building, testing, and deploying software can be automated with Jenkins, reducing the need 
      for manual intervention and minimizing human errors.

6. Real-Time Feedback:

    - Jenkins provides real-time feedback on the status of builds, allowing developers to see if their 
      changes break the build, if tests pass, and other key metrics. 
      This helps speed up the development process by ensuring early detection of issues.

7. Integration with Version Control:

    - Jenkins integrates seamlessly with version control systems (such as Git, SVN, and Mercurial), so that 
      it can trigger builds automatically based on code changes or commits.

8. Customizable Build and Test Environments:

    - You can configure Jenkins to work with custom build tools and test environments (e.g., specific OS 
      configurations, Docker containers, virtual machines).

9. Scalable:

    - Jenkins can be scaled horizontally by adding more build agents or nodes to distribute workloads. 
      This makes it ideal for large teams or projects requiring significant computational resources.

### Key Concepts in Jenkins:

1. Jobs:

    - A Jenkins "job" is a task or process that Jenkins performs, such as compiling code, running tests, or 
      deploying an application. 
      Jobs can be manually triggered or automatically triggered by events like a code commit.
   
2. Pipelines:

    - A pipeline is a series of automated steps that define the build, test, and deployment processes. 
      Pipelines can be defined using the Pipeline DSL (domain-specific language) or through a visual 
      interface.

3. Nodes:

    - A node is a machine where Jenkins runs jobs. 
      The Jenkins master node controls the Jenkins environment, while other nodes (called slaves) can 
      run jobs and help distribute the workload.

4. Build Triggers:

    - Jenkins can be configured to trigger jobs automatically. Common triggers include changes to a 
      source repository (e.g., a commit in Git), scheduled times (e.g., nightly builds), or manual trigger 
      by a user.

5. Build Artifacts:

    - These are the results or outputs of a build, such as compiled binaries, test reports, logs, and more. 
      Jenkins can archive these artifacts, allowing them to be reviewed or used in later stages of the 
      pipeline.

6. Freestyle Projects vs Pipeline Projects:

    - Freestyle projects: A simpler, UI-based way to configure Jenkins jobs.
    - Pipeline projects: More flexible and powerful, using code (via the Jenkinsfile) to define the 
      steps of the build, test, and deploy process.

7. Blue Ocean:

    - A modern, user-friendly interface for Jenkins that helps visualize pipelines and jobs in a more 
      streamlined, graphical way.

### How Jenkins Works in Practice:

1. Code Commit: 
    A developer commits changes to a version control system (e.g., Git).

2. Trigger Build: 
    Jenkins is configured to automatically trigger a build when it detects a code change in the repository.

3. Build and Test: 
    Jenkins executes the build and runs any automated tests to ensure the new changes don't break the app.

4. Report Results: 
    Jenkins provides feedback to the team via build status indicators, test results, logs, etc.

5. Deploy: 
    If the build passes all tests, Jenkins can automatically deploy the application to various environments,
    such as staging or production.

### Benefits of Using Jenkins:
- Faster Development: Continuous integration helps catch bugs early and reduces the time spent debugging.
- Consistency: Automates repetitive tasks and ensures the same process is followed each time.
- Collaboration: Developers get immediate feedback, which fosters better collaboration across teams.
- Error Reduction: Automation minimizes human errors in the testing and deployment process.

### Common Use Cases:

- Automated Testing: 
    Running unit tests, integration tests, and other checks automatically as part of the CI pipeline.

- Build Automation: 
    Compiling source code, generating artifacts, and packaging software for deployment.

- Deployment Automation: 
    Deploying code to development, staging, or production environments automatically after successful builds
    and tests.

- Performance Testing: 
    Running load or stress tests to ensure that the application performs well under varying conditions.


### Conclusion:

Jenkins is a powerful tool for automating the software development lifecycle, particularly CI/CD. 
Its ability to integrate with various tools, its scalability, and its wide use across the industry make it 
an essential tool for modern development practices. 
Whether you're working on a small project or a large enterprise application, Jenkins helps ensure that your 
software is tested, built, and deployed consistently and reliably.


# Install and Setup Jenkins for practice:


To practice Jenkins on a Linux machine or container (using Podman) for automating builds per commit, 
follow the steps outlined below. We'll break it into two parts: 
setting up Jenkins on a Linux machine and setting it up inside a Podman container.

---

### Part 1: Setting Up Jenkins on a Linux Machine

#### 1. **Install Java Development Kit (JDK)**
   Jenkins requires Java to run, so the first step is installing JDK (we'll use OpenJDK).

   - For Ubuntu/Debian-based distributions, run:
     ```bash
     sudo apt update
     sudo apt install openjdk-11-jdk -y
     ```

   - For CentOS/RHEL-based distributions, run:
     ```bash
     sudo yum install java-11-openjdk-devel -y
     ```

   To verify the installation, run:
   ```bash
   java -version
   ```

#### 2. **Install Jenkins**
   You can download and install Jenkins using the package manager.

   For Ubuntu/Debian:
   ```bash
   sudo apt update
   sudo apt install wget gnupg -y
   wget -q -O - https://pkg.jenkins.io/jenkins.io.key | sudo tee /etc/apt/trusted.gpg.d/jenkins.asc
   sudo sh -c 'echo deb http://pkg.jenkins.io/debian/ stable main > /etc/apt/sources.list.d/jenkins.list'
   sudo apt update
   sudo apt install jenkins -y
   ```

   For CentOS/RHEL:
   ```bash
   sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
   sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
   sudo yum install jenkins -y
   ```

#### 3. **Start Jenkins**
   Once installed, start Jenkins:
   ```bash
   sudo systemctl start jenkins
   ```

   Enable Jenkins to start on boot:
   ```bash
   sudo systemctl enable jenkins
   ```

#### 4. **Access Jenkins Web Interface**
   Jenkins should now be running on port 8080 by default. You can access the web interface by navigating to:
   ```
   http://<your-server-ip>:8080
   ```

   - For a local machine, use `http://localhost:8080`.

#### 5. **Unlock Jenkins**
   During the first run, Jenkins asks for an unlock key. Find it by running:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   Copy the password and paste it into the Jenkins unlock page.

#### 6. **Install Suggested Plugins**
   After unlocking Jenkins, it will prompt you to install plugins. Choose the "Install suggested plugins" option.

#### 7. **Create Admin User**
   You will be prompted to create an admin user for Jenkins after the plugins installation.

---

### Part 2: Set Up Jenkins in a Podman Container

If you want to run Jenkins in a Podman container instead of directly on your Linux machine, follow these steps:

#### 1. **Install Podman**
   - For Ubuntu/Debian:
     ```bash
     sudo apt update
     sudo apt install podman -y
     ```

   - For CentOS/RHEL:
     ```bash
     sudo yum install podman -y
     ```

   To verify, run:
   ```bash
   podman --version
   ```

#### 2. **Run Jenkins in a Podman Container**

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

#### 3. **Access Jenkins Web Interface in Container**
   Once the container is running, you can access Jenkins in the same way as on a host machine, by 
   navigating to:
   ```
   http://localhost:8080
   ```

#### 4. **Unlock Jenkins in the Container**
   To get the Jenkins unlock key in the container, run the following:
   ```bash
   podman exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

   Copy the password and use it to unlock Jenkins on the web interface.

---

### Part 3: Set Up Jenkins to Build on Each Commit

Once Jenkins is up and running, you can automate builds for every commit by following these steps:

#### 1. **Create a New Job**

   - Go to the Jenkins web interface.
   - Click on `New Item` in the left sidebar.
   - Select `Freestyle project` (or `Pipeline` if you want more advanced control).
   - Give it a name (e.g., "Automated Build").
   - Click `OK`.

#### 2. **Configure the Job to Build on GitHub Push**
   To trigger a build on each commit, integrate Jenkins with a Git repository.

   - Under `Source Code Management`, choose `Git`.
   - Enter the URL of your Git repository (e.g., `https://github.com/username/repository.git`).
   - Optionally, add credentials if the repository is private.

#### 3. **Configure Build Triggers**

   - Under `Build Triggers`, select `GitHub hook trigger for GITScm polling` if you're using GitHub.

   Alternatively, you can use the `Poll SCM` option to check for changes at regular intervals. In this case, enter a cron expression like `H/5 * * * *` to check every 5 minutes.

#### 4. **Set Up GitHub Webhook**
   
   To trigger Jenkins builds on push, create a webhook in your GitHub repository.

   - Go to your GitHub repository.
   - Click on `Settings` > `Webhooks` > `Add webhook`.
   - In the "Payload URL" field, enter your Jenkins URL followed by `/github-webhook/`, for example:
     ```
     http://<your-server-ip>:8080/github-webhook/
     ```
   - Set the content type to `application/json` and select the `Just the push event` option.
   - Click `Add webhook`.

#### 5. **Configure Build Steps**

   Under the `Build` section, add build steps, such as:

   - `Execute shell` to run build commands:
     ```bash
     echo "Building project..."
     ./build.sh  # Replace with your build script
     ```

#### 6. **Save and Run the Job**

   Save your job configuration, and now Jenkins will automatically run builds when commits are pushed to your GitHub repository.

---

### Example Simple `build.sh` Script:
Here's a very simple example of a `build.sh` script for a Node.js project:

```bash
#!/bin/bash

# Install dependencies
npm install

# Run tests
npm test

# Build the project
npm run build
```

---

### Conclusion
That's how you set up Jenkins on a Linux machine or in a Podman container to automate builds on each commit. By connecting Jenkins with your Git repository and configuring webhooks, you can trigger builds for each commit, ensuring continuous integration for your project.



# Jenkins with Gerrit developement:

To set up Jenkins with a **Gerrit** development environment (i.e., triggering builds based on changes 
pushed to Gerrit), you’ll need to integrate Jenkins with Gerrit. integration

Gerrit is a web-based code review system that allows users to review, approve, and merge changes before 
they are committed to the main repository.

The steps for setting up Jenkins with Gerrit are similar to those for GitHub, but there are some key 
differences in the setup for integration, specifically around using **Gerrit triggers** and **Gerrit hooks**.

---

### Part 1: Install Jenkins (as previously explained)

If you haven't set up Jenkins yet, follow the earlier instructions on installing Jenkins on a Linux machine 
or in a Podman container.

---

### Part 2: Install and Configure Gerrit Trigger Plugin in Jenkins

1. **Install Gerrit Trigger Plugin**
   - Go to **Jenkins Dashboard** > **Manage Jenkins** > **Manage Plugins**.
   - Search for **Gerrit Trigger Plugin** in the **Available** tab.
   - Install the plugin and restart Jenkins if required.

2. **Create a New Job**
   - After installing the plugin, go to **New Item** > **Freestyle Project** (or **Pipeline** for more advanced control).
   - Give it a name, such as `Automated Build for Gerrit`, and click **OK**.

3. **Configure Gerrit Trigger**
   - In the job configuration, scroll down to the **Build Triggers** section.
   - Check the **Gerrit Trigger** option.
   - In the **Gerrit Trigger** section, configure the following:
     - **Gerrit Server**: Click on the **Add Gerrit Server** button to add your Gerrit server.
     - **Name**: Give the Gerrit server a name (e.g., `Gerrit`).
     - **Gerrit Hostname**: Provide the Gerrit server's hostname or IP address (e.g., `gerrit.example.com`).
     - **Gerrit Port**: Default Gerrit port is 29418 (unless customized).
     - **Username**: Enter a username with the appropriate access permissions to query the Gerrit server.
     - **Password**: Provide the authentication token for the Gerrit user (this could be a password or SSH key depending on the authentication method).
     - **Event Types**: Select the events that will trigger Jenkins builds. Common ones include:
       - `Patchset Created`: Triggers a build when a patchset is created.
       - `Change Merged`: Triggers a build when a change is merged.
       - `Draft Published`: Triggers a build when a draft change is published.

4. **Configure Build Steps**
   - Under the **Build** section of the job, you can configure your build steps. For example, for a simple Node.js project, you might use:
     ```bash
     npm install
     npm test
     npm run build
     ```

5. **Save the Configuration**
   - Once you've configured your build steps and triggers, click **Save** to save the job.

---

### Part 3: Set Up Gerrit to Trigger Jenkins Builds

To trigger Jenkins builds on Gerrit changes, you need to set up Gerrit to notify Jenkins when events occur. This is done using **Gerrit Hooks**.

1. **Install the Gerrit Trigger Hook**
   - Download the **Gerrit Trigger Plugin** and set it up in Gerrit:
     - Gerrit will provide a **Jenkins GitHub webhook** URL when you configure it. Copy this URL.

2. **Add Gerrit Trigger to Gerrit Configuration**
   - Gerrit has a feature called **Webhooks** to notify external systems (like Jenkins). You can configure a webhook to notify Jenkins whenever a change is created, updated, or merged.

   To configure Gerrit, run the following on the Gerrit server:

   - Log into the Gerrit server.
   - Add the webhook for your Jenkins instance:
     ```bash
     gerrit set-reviewers --url=http://<your-jenkins-server>:8080/gerrit-webhook/ --username=<username> --password=<password> <your-gerrit-project>
     ```

     Replace `<your-jenkins-server>`, `<username>`, `<password>`, and `<your-gerrit-project>` with the appropriate values.

---

### Part 4: Configure SSH Keys for Gerrit (Optional)

If you’re using SSH keys to authenticate Jenkins with Gerrit, follow these steps:

1. **Generate an SSH Key for Jenkins**
   - On the Jenkins machine, generate a new SSH key pair:
     ```bash
     ssh-keygen -t rsa -b 4096 -C "jenkins@gerrit.com" -f /var/lib/jenkins/.ssh/id_rsa
     ```
   
2. **Add Public Key to Gerrit**
   - Copy the contents of the generated public key (`/var/lib/jenkins/.ssh/id_rsa.pub`) to the **Gerrit SSH keys** section under **Settings** > **SSH Keys**.

3. **Configure Jenkins to Use the Key**
   - Ensure that Jenkins uses the private key (`/var/lib/jenkins/.ssh/id_rsa`) to authenticate to Gerrit by configuring it in the **Jenkins SSH** settings.

---

### Part 5: Set Up a Gerrit Webhook for Jenkins

In order for Gerrit to notify Jenkins when there are new commits, changes, or merges, you will need to create a **Webhook** in Gerrit.

1. **Go to Gerrit**:
   - Navigate to **Gerrit Settings** > **Webhooks**.

2. **Add the Webhook URL**:
   - Add the Jenkins webhook URL that was generated when you configured the Gerrit Trigger Plugin in Jenkins (e.g., `http://<your-jenkins-server>:8080/gerrit-webhook/`).

3. **Set the Events to Trigger on**:
   - In the webhook configuration, you can select which events should trigger Jenkins jobs. Typically, you'd choose:
     - **Patchset Created**
     - **Change Merged**
     - **Draft Published**

4. **Save the Webhook**:
   - After entering the details, save the webhook configuration.

---

### Example: Sample `build.sh` Script

Here’s an example of a `build.sh` script that can be used in Jenkins to build a Node.js project:

```bash
#!/bin/bash

# Install dependencies
npm install

# Run tests
npm test

# Build the project
npm run build
```

---

### Final Considerations:
- **Security**: Ensure your Jenkins server is secured, especially when accessing Gerrit and other external systems.
- **SSH Keys**: If you're using SSH authentication for Gerrit, make sure Jenkins can securely access the repository via SSH keys.
- **Jenkins Logs**: Monitor Jenkins logs for any issues with the Gerrit integration or build failures.
- **Test the Integration**: Once everything is set up, push a change to Gerrit to test if Jenkins is triggered for the build.

---

### Conclusion

By following the steps outlined above, you can easily set up **Jenkins with Gerrit** to automate builds based on changes in a Gerrit repository. This setup enables continuous integration, allowing Jenkins to automatically trigger builds and tests for each commit pushed to Gerrit, ensuring a streamlined development workflow.
