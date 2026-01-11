# Git hosting Services:

If you have a ssh server then you don't need any Git Hosting servers that are available for you. People
prefer to use the freely available server to avoid management, manpower. 

This document would help indivuduals and companies that prefer to have full control and management of
there digital data. 

To have your own secure self hosting Git server, all you need is to install the following packages and
configure as per the requirements
- SSH server 
- Git 

A SSH server is already a GIT server: We can demonstrate this as below:

Step 1:  
For regular version control of a project under "MyGitProject" is done by issuing 
```bash 
$ cd MyGitProject; git init 
Initialized empty Git repository in /tmp/MyGitPeoject/.git/
ls .git
config  description  HEAD  hooks  info  objects  refs
```
All the version control related files are stored under .git/ folder. 

Now to make this project directory accessible over network in the fastest secure possible way is to make
it accessible over "ssh" which would require ssh client to access the version control files. This is done
as below: 

```bash 
$ git init --bare MyGitProject 
ls .git
config  description  HEAD  hooks  info  objects  refs
```

```mermaid 
Server 1:
$ git init --bare MyGitProject
Initialized empty Git repository in /tmp/MyGitProject/

$ ls MyGitProject
config  description  HEAD  hooks  info  objects  refs
```
- The option "--bare" pushes the contents of .git/ folder into the project folder and now we can think of
  ssh as ssh url which can be accessed remotely by putting in the credentials. 

- git does by supporting such ssh urls and allows the users to remotely clone, push to the remote server.

```bash 
Clinet:
$ git clone user@server_ip:/tmp/MyGitProject 
$ cd MyGitProject; touch hello.c 
$ git add hello.c 
$ git commit -m"Hello file"
$ git push origin main 

```
For additional details Look @ the 4th chapter of the Git Book. 
Git on the server - The protocols.

Git also support HTTP but that requires additional setup, the beauty of ssh is it already has
authentication and other.
This is how most of the Git Service work.
You can ssh to your github account:
```bash 
$ ssh git@github.com
PTY allocation request failed on channel 0
Hi prk-2023! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.

```

Which shows that github is basically a SSH server without a shell service for users.
