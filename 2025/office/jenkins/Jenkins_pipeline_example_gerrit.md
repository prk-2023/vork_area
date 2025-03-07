Q1. Generate a tutorial for learning to write jenkins pipeline ( from a linux machine )
   - use podman to deploy Jenkins
   - Create a gerrit trigger per commit build pipeline
   - how limit a build to be triggerd only if the commit is related to a folder "meta-example/recipe-graphics/" 

Ans:>
---
### Jenkins Pipeline Tutorial: Using Podman, Gerrit Trigger, and Folder Filtering

In this tutorial, we'll walk through setting up Jenkins on a Linux machine using Podman, creating a Gerrit trigger for building a pipeline on commit, and limiting the pipeline to only trigger builds for changes in the `meta-example/recipe-graphics/` folder.

#### Prerequisites

- Linux machine (any distribution should work)
- **Podman** installed
- **Gerrit** server set up and connected with Jenkins
- **Jenkins** installed via Podman

#### Part 1: Setting Up Jenkins with Podman

First, we need to install and set up Jenkins using Podman. This will allow us to run Jenkins in a containerized environment.

1. **Install Podman** (if you don’t have it installed already):
   - For **Ubuntu** or **Debian**:
     ```bash
     sudo apt update
     sudo apt install -y podman
     ```

   - For **CentOS** or **RHEL**:
     ```bash
     sudo yum install -y podman
     ```

2. **Run Jenkins in a Podman container**:
   The official Jenkins Docker image can be used with Podman since Podman supports Docker images.
   ```bash
   podman run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts
   ```

   This command will:
   - Pull the Jenkins LTS image.
   - Run Jenkins in a detached container.
   - Expose Jenkins on ports 8080 (for web interface) and 50000 (for agent communication).

3. **Access Jenkins**:
   Once the container is running, access Jenkins by visiting `http://localhost:8080` in your browser. You’ll be prompted to unlock Jenkins.

   - To get the initial admin password, run the following command:
     ```bash
     podman logs jenkins
     ```

   - Copy the password and enter it into the web interface to complete the setup.

#### Part 2: Install Required Jenkins Plugins

You’ll need the following Jenkins plugins:
- **Gerrit Trigger Plugin**: For triggering builds based on changes in Gerrit.
- **Pipeline Plugin**: To write Jenkins pipelines.
- **Git Plugin**: To check out the code from your repository.

1. Go to **Manage Jenkins > Manage Plugins**.
2. Search for the plugins listed above and install them.

#### Part 3: Create a Jenkins Pipeline Job

Now that Jenkins is set up, let’s create a Jenkins pipeline job that will be triggered by Gerrit changes.

1. **Create a new pipeline job**:
   - In Jenkins, go to the homepage and click on **New Item**.
   - Name your job (e.g., `gerrit-trigger-pipeline`).
   - Select **Pipeline** and click **OK**.

2. **Configure the Gerrit Trigger**:
   - In the job configuration page, scroll down to **Gerrit Trigger**.
   - Enable **Trigger on change events**.
   - Under **Gerrit project**, specify the project/repository to watch (e.g., `project-name`).
   - Under **Branch**, specify the branch for the trigger (e.g., `refs/heads/master` or any other branch).

3. **Configure the Pipeline script**:
   Scroll to the **Pipeline** section and enter the following script to define the pipeline.

#### Part 4: Pipeline Script Example

Here’s a simple example of a Jenkinsfile pipeline script that triggers a build only when changes occur in the `meta-example/recipe-graphics/` folder.

```groovy
pipeline {
    agent any

    triggers {
        gerrit(triggerOn: 'change-merged', gerritProject: 'project-name') // Trigger on merged changes
    }

    stages {
        stage('Check for Folder Change') {
            steps {
                script {
                    // Get the list of changed files from Gerrit
                    def changedFiles = sh(script: "git diff --name-only ${GERRIT_COMMITTER_REVISION}~1 ${GERRIT_COMMITTER_REVISION}", returnStdout: true).trim().split("\n")
                    
                    // Filter the files to check if any are in the 'meta-example/recipe-graphics/' folder
                    def folderChanged = changedFiles.any { it.startsWith('meta-example/recipe-graphics/') }

                    // If no files in the folder changed, abort the build
                    if (!folderChanged) {
                        currentBuild.result = 'SUCCESS'
                        error("No changes in 'meta-example/recipe-graphics/' folder, skipping build.")
                    }
                }
            }
        }

        stage('Build') {
            when {
                expression { return currentBuild.result != 'SUCCESS' }  // Only run this stage if no errors in the folder check
            }
            steps {
                // Add your build commands here, e.g., build the application or run tests
                echo 'Building the project...'
            }
        }
    }
}
```

#### Explanation of the Pipeline:

1. **Gerrit Trigger**:
   - The `gerrit` block triggers the build whenever a change is merged into the specified project.
   
2. **Check for Folder Change**:
   - We use `git diff` to find the files changed in the latest commit.
   - If any of the files are within the `meta-example/recipe-graphics/` folder, the pipeline proceeds to the build stage.
   - If no changes are found in this folder, the pipeline will abort, skipping the build.

3. **Build Stage**:
   - This is where the actual build or deployment commands would go. In this example, it's just a placeholder echo statement.

#### Part 5: Set Up the Gerrit Trigger in Jenkins

1. **Configure the Gerrit Server**:
   - Go to **Manage Jenkins > Configure System**.
   - Scroll to **Gerrit Trigger** settings.
   - Set up your **Gerrit Server** connection by specifying the host URL and authentication details.

2. **Link the Gerrit Trigger Plugin to the Job**:
   - When configuring the job, select the Gerrit trigger settings (as mentioned above) to tie the job to the Gerrit project.

#### Part 6: Testing

1. **Push Changes to Gerrit**:
   - Make a commit in the `meta-example/recipe-graphics/` folder.
   - Push the change to Gerrit.

2. **Verify Build in Jenkins**:
   - The Jenkins job should be triggered and a build should begin if the change is related to the specified folder. If no change is made in that folder, the build will be skipped.

---

### Conclusion

You’ve now set up Jenkins with Podman, configured a Gerrit trigger, and added a filter to only trigger the build when changes occur in a specific folder (`meta-example/recipe-graphics/`). This setup ensures that Jenkins only runs builds for relevant changes, optimizing your CI/CD workflow.


