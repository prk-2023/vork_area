# git bisect ( issue detection )
Below is an example of a Jenkins pipeline that utilizes Git Bisect for two cases:

- **Trigger manually**: Allows the user to trigger the pipeline manually when they need to bisect the 
  repository to find the commit that caused a failure.

- **Automated Git Bisect**: 
  Runs a fully automated bisect process, where Jenkins tries to automatically bisect the code to identify 
  the failing commit.

### Prerequisites:

1. **Git repository**: Ensure the repository is already cloned on the Jenkins machine or agent.
2. **Build Script**: A script or command that can be used to check whether a commit is good or bad 
   (e.g., running tests or other validation steps).

### Example Jenkinsfile

This pipeline will use two approaches for Git Bisect:

- A **manual trigger** where the user can specify which commits are good or bad.

- An **automated bisect** process that will automatically try to bisect the repository and figure out 
  which commit causes the failure.

```groovy
pipeline {
    agent any
    environment {
        // Git repository URL and branch
        GIT_REPO = 'https://github.com/your-repo/your-project.git'
        GIT_BRANCH = 'main'  // Change this to your desired branch
        BISPECTEST_SCRIPT = './test.sh'  // Command to test if the commit is good or bad
    }

    stages {
        stage('Checkout Repository') {
            steps {
                // Clone the Git repository
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Manual Git Bisect') {
            when {
                // Allow the manual trigger via input
                beforeAgent true
                expression { return params.RUN_MANUAL_BISECT }
            }
            steps {
                script {
                    echo 'Starting manual bisect...'
                    def bisectStatus = input message: 'Enter Bisect Status', parameters: [
                        string(name: 'GoodCommit', defaultValue: '', description: 'Enter the good commit hash'),
                        string(name: 'BadCommit', defaultValue: '', description: 'Enter the bad commit hash')
                    ]

                    // Execute Git bisect
                    sh "git bisect start ${bisectStatus['BadCommit']} ${bisectStatus['GoodCommit']}"
                    sh "git bisect run ${BISPECTEST_SCRIPT}"

                    // End the bisect once the commit is found
                    sh "git bisect reset"
                }
            }
        }

        stage('Automated Git Bisect') {
            when {
                // Trigger the automated bisect process
                beforeAgent true
                expression { return !params.RUN_MANUAL_BISECT }
            }
            steps {
                script {
                    echo 'Starting automated bisect...'
                    // Start bisecting, using a good commit hash (e.g., known stable commit) and a bad commit (e.g., current head)
                    sh "git bisect start HEAD $(git rev-list --max-parents=0 HEAD)"

                    // Automated bisect run command that tests each commit
                    sh "git bisect run ${BISPECTEST_SCRIPT}"

                    // Reset git bisect after finding the commit
                    sh "git bisect reset"
                }
            }
        }
    }

    parameters {
        booleanParam(
            name: 'RUN_MANUAL_BISECT',
            defaultValue: true,
            description: 'Trigger Git Bisect Manually?'
        )
    }
}
```

### Pipeline Breakdown:

#### 1. **Checkout Repository**:
The first stage clones the Git repository to the Jenkins workspace.

#### 2. **Manual Git Bisect**:
- This stage is triggered manually via Jenkins' **input** feature. 
    The user is prompted to input the **good** and **bad** commit hashes.

    - `git bisect start` is run with the **bad commit** (typically the failing commit) and the 
       **good commit** (a commit where the code was working).

    - `git bisect run` will run the test script (`test.sh` or a similar command) to check each commit 
       automatically.

- Once the bisect process is complete, the `git bisect reset` command is used to stop the bisect process 
  and return to the original HEAD.

#### 3. **Automated Git Bisect**:

- In this stage, Jenkins will automatically run the bisect process using `git bisect start`.

- The **bad commit** is assumed to be the current `HEAD`, and the **good commit** is the first parent commit 
  (`git rev-list --max-parents=0 HEAD` gives the first commit in the repository, which should be known to 
    be good).

- The `git bisect run` will automatically test each commit using the provided test script (`test.sh`).

- Once the bisect completes, the `git bisect reset` command will stop the bisect process.

#### 4. **Parameters**:
- The `RUN_MANUAL_BISECT` parameter is used to determine if the pipeline should run the **manual** bisect 
  process or the **automated** bisect process.
- When triggered manually, the user can choose to provide the **good** and **bad** commit hashes for 
  bisecting.
- If `RUN_MANUAL_BISECT` is false, the pipeline will run the automated bisect process.

---

### The `test.sh` Script:

The `test.sh` script (or whatever script/command you use) should return:
- **0** if the commit is **good** (i.e., no failure).
- **1** if the commit is **bad** (i.e., failure).

Here’s an example of what a simple `test.sh` script might look like:

```bash
#!/bin/bash

# Run your tests here
./run_tests.sh  # Replace with your actual test command

# Return 0 if the tests pass, 1 if they fail
if [ $? -eq 0 ]; then
  exit 0  # Good commit
else
  exit 1  # Bad commit
fi
```

### Triggering the Pipeline:

1. **Manual Bisect**: When you trigger the pipeline, the `RUN_MANUAL_BISECT` parameter will be set to 
   `true`, and you’ll be asked to provide the **good** and **bad** commit hashes via the input prompt.
2. **Automated Bisect**: If you set `RUN_MANUAL_BISECT` to `false`, Jenkins will automatically start the 
   bisecting process and test the commits without any input from you.

---

### Conclusion:

This pipeline provides two ways to use Git Bisect in Jenkins:
1. **Manual bisect** allows the user to specify the good and bad commits for bisecting.
2. **Automated bisect** allows Jenkins to automatically run the bisect process by testing commits from a 
   known good commit to the current bad commit.

You can customize the `test.sh` script and the parameters as needed to suit your project's specific testing 
and build setup.


# Location of test.sh script:

When Jenkins is running inside a container (such as using **Podman** or **Docker**), the `test.sh` 
script (or any other custom script) can be placed in several places. 

Here are the options for where to put the `test.sh` script:

### Option 1: **Inside the Jenkins Workspace (Preferred)**

The most common and simplest approach is to place the `test.sh` script in the repository you're working with.
This way, it becomes part of your repository, and Jenkins can easily access it from the workspace during 
the pipeline execution.

#### Steps:

1. **Add `test.sh` to Your Git Repository**:
   - Place the `test.sh` script in the root directory (or a subdirectory) of your project repository.
   
   For example, place `test.sh` in the root of your repository:
   ```bash
   your-repo/
   ├── test.sh
   └── ... other files ...
   ```

2. **Update the Pipeline to Use the Script**:
   In your Jenkinsfile (inside the pipeline script), you can call it using the relative path (i.e., `./test.sh`):

   ```bash
   sh './test.sh'
   ```

   - This works because Jenkins clones your repository into the workspace, and the `test.sh` script is 
     available in the workspace when running the pipeline.

---

### Option 2: **Inside the Jenkins Container (Container File System)**

If you want the `test.sh` script to be available globally within the Jenkins container (so that it’s not 
tied to a specific repository), you can copy it into the container’s file system.

#### Steps:
1. **Copy the `test.sh` Script into the Jenkins Container**:
   You can copy the `test.sh` script into the running Jenkins container using `podman cp` or `docker cp`:

   ```bash
   podman cp ./test.sh jenkins-container:/var/jenkins_home/test.sh
   ```

   Replace `jenkins-container` with the actual container name or ID.

   - **Path Explanation**: `/var/jenkins_home` is the default Jenkins home directory inside the container 
     (where Jenkins stores configurations and jobs). You can place the `test.sh` script here or in any 
     directory inside the container.

2. **Access the Script from the Pipeline**:
   When the script is placed inside the container at a known location (e.g., `/var/jenkins_home/test.sh`), 
   you can reference it in the Jenkinsfile like this:

   ```bash
   sh '/var/jenkins_home/test.sh'
   ```

   - However, be aware that this method makes the `test.sh` script container-specific. 
   If you recreate the container, you'll need to re-copy the script, or you might want to automate this in 
   your container setup.

---

### Option 3: **Mounting a Volume**

Another option is to mount a volume (from your host machine) that contains the `test.sh` script into the 
Jenkins container. This approach is useful if you don't want to manually copy the script into the container 
every time.

#### Steps:
1. **Create a directory on your host machine** and place the `test.sh` script in it:
   ```bash
   mkdir -p /path/to/test-scripts
   cp ./test.sh /path/to/test-scripts/test.sh
   ```

2. **Mount the directory as a volume** when starting the Jenkins container:
   ```bash
   podman run -d -p 8080:8080 -p 50000:50000 \
     -v /path/to/test-scripts:/var/jenkins_home/test-scripts \
     --name jenkins jenkins/jenkins:lts
   ```

3. **Access the Script from the Pipeline**:
   In the pipeline, you can refer to the mounted directory and use the script:
   ```bash
   sh '/var/jenkins_home/test-scripts/test.sh'
   ```

   - This ensures that the `test.sh` script is always available and persistent across Jenkins container 
     restarts.

---

### Option 4: **Using a Custom Docker Image with the Script**

If you have a custom Docker or Podman image for Jenkins, you can bake the `test.sh` script into the image 
during the image build process.

#### Steps:
1. **Create a Dockerfile for Your Custom Jenkins Image**:
   If you don’t have one, create a `Dockerfile` to extend the official Jenkins image and add the script:

```Dockerfile
    FROM jenkins/jenkins:lts

    # Copy test.sh into the image
    COPY test.sh /usr/local/bin/test.sh
    
    #Make sure it's executable
    RUN chmod +x /usr/local/bin/test.sh
   ```

2. **Build the Custom Image**:
   Build the Docker or Podman image:
   ```bash
   docker build -t custom-jenkins-image .
   ```

3. **Run the Container Using Your Custom Image**:
   Run the Jenkins container using the custom image that already contains the `test.sh` script.

   ```bash
   podman run -d -p 8080:8080 -p 50000:50000 --name jenkins custom-jenkins-image
   ```

4. **Access the Script from the Pipeline**:
   Since the script is already in the image, you can simply reference it:
   ```bash
   sh '/usr/local/bin/test.sh'
   ```

   - This ensures that the `test.sh` script is always available when the container starts.

---

### Conclusion

The best place to store the `test.sh` script depends on your setup and workflow. Here are the recommendations:

1. **For Simplicity**: 
    Place the `test.sh` script in the **Git repository** itself. This allows Jenkins to access it directly
    from the workspace.

2. **For Global Access within Jenkins Container**: Copy the script into the **Jenkins container’s 
   file system** using `podman cp`.

3. **For Persistent Storage**: Use a **volume mount** to ensure the script is always available, even if the 
    container is restarted.

4. **For Customization**: Embed the script in a **custom Docker or Podman image**.

The first option (placing `test.sh` inside your Git repository) is usually the most flexible and portable, as it keeps everything version-controlled and tied to the project.
