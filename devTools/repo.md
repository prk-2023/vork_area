# Repo

## **Repo Command**

Repo is a version control system developed by Google, specifically designed for managing large, distributed 
projects with multiple Git repositories. 

It was created to simplify the process of managing Android's open-source codebase, which consists of 
hundreds of Git repositories.

Repo is built on top of Git and extends its functionality to manage multiple repositories as a single
entity. 

It provides a unified interface for managing these repositories, making it easier to track changes, manage 
dependencies, and perform operations across multiple projects.

### Some key features of Repo include:

1. **Multi-repo management**: Repo allows you to manage multiple Git repositories as a single entity, making
   it easier to track changes and manage dependencies across projects.

2. **Manifest files**: Repo uses manifest files to define the structure of the project, including the
   repositories, branches, and tags.

3. **Syncing and updating**: Repo provides commands to sync and update the project, ensuring that all
   repositories are up-to-date and consistent.

### Key differences between Repo and Git:

1. **Multi-repo management**: Repo is designed to manage multiple Git repositories as a single entity, while
   Git is designed to manage a single repository.

2. **Manifest files**: Repo uses manifest files to define the project structure, while Git uses a `.git`
   directory to manage the repository.

3. **Syncing and updating**: Repo provides commands to sync and update the project, while Git provides
   commands to fetch, pull, and push changes to a single repository.

4. **Purpose**: Repo is designed for managing large, distributed projects with multiple Git repositories,
   while Git is designed for managing a single repository.


### Here's a rough analogy to help illustrate the difference:

* Git is like a single file folder, where you store and manage your documents.

* Repo is like a file cabinet, you store and manage multiple file folders(repositories) as a single entity.

## Setting up a Repo

Step-by-Step guide to setting up a Repo:

1. **Install Repo**: Download/Install the Repo tool in PATH,  from the official Android Open Source Project

2. **Create a new directory**: Create a new directory for your project, e.g., `myproject`.

3. **Initialize the Repo**: Navigate to the `myproject` directory and run the command 
    
    `repo init -u \<manifest-url\>`. 

    Replace `\<manifest-url\>` with the URL of your manifest file (we'll create this file later).

4. **Sync the Repo**: Run the command `repo sync` to download all the repositories specified in the manifest
   file.

### **Creating a Manifest File**

A manifest file is an XML file that defines the structure of your project, including the repositories, 
branches, and tags. 

Here's an example of a simple manifest file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="origin" fetch="https://github.com/myusername/" />
  <project name="myproject" path="myproject" remote="origin" revision="master" />
  <project name="mylibrary" path="mylibrary" remote="origin" revision="dev" />
</manifest>
```
Manifest file:

* `\<remote\>`: Defines a remote repository, including its name and URL.
* `\<project\>`: Defines a project, including its name/path/remote repository/and revision (branch or tag).

Create a manifest file, follow these steps:

1. **Create a new file**: Create a new file with a `.xml` extension, e.g., `mymanifest.xml`.

2. **Add the XML header**: Add the XML header 
    `\<?xml version="1.0" encoding="UTF-8"?\>` to the top of the file.

3. **Define the manifest**: Define the manifest element `\<manifest\>`.

4. **Add remote repositories**: Add `\<remote\>` elements to define the remote repositories you want to
   include in your project.

5. **Add projects**: Add `\<project\>` elements to define the projects you want to include in your manifest.

6. **Save the file**: Save the manifest file to a location accessible by your Repo.

**Example Use Case**

Suppose you have two Git repositories: `myproject` and `mylibrary`. 

You want to create a Repo that includes both repositories and tracks the `master` branch of `myproject` 
and the `dev` branch of `mylibrary`.

Here's an example manifest file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="origin" fetch="https://github.com/myusername/" />
  <project name="myproject" path="myproject" remote="origin" revision="master" />
  <project name="mylibrary" path="mylibrary" remote="origin" revision="dev" />
</manifest>
```
To set up the Repo, navigate to the `myproject` directory and run the command 
`repo init -u https://github.com/myusername/mymanifest.xml`. 

Then, run `repo sync` to download both repositories and track the specified branches.

That's it! You now have a Repo set up with a manifest file that includes two Git repositories.


### Fetching the project from other PC or developer:

- Install repo tool on the developer system.

- create a new folder and navigate into the new folder.

- Initalize the repository:

    `repo init -u ssh://usename@server:/path/to/myproject/mymanifest.xml`

    or 

    `repo init -u https://github.com/myusername/myproject.xml` ( replace the URL of the manifest file)

- sync the repo: This is to download all the projects specified in the manifest file.

    `repo sync`


### Creating a mirror of remote:

- create and navigate a new folder 
- init the repo that is to be mirrored:

    ` repo init -u https://github.com/username/myproject.xml `

- mirror the repo: ( make sure u have enough diskspace for large projects )
    `repo mirror`


