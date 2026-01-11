# Self-Hosting a Git Server via SSH

While commercial hosting services (GitHub, GitLab, Bitbucket) are popular for their UI and ease of use, 
they are not strictly necessary. 

For individuals and companies demanding **full sovereignty** over their digital assets, a private SSH server 
is all you need.

## The Core Concept

A standard SSH server is inherently a Git server. 

Git uses the SSH protocol to tunnel data securely between the client and the server.

### Requirements

* **SSH Server (OpenSSH):** Handles authentication and encrypted data transfer.
* **Git:** Installed on both the server and the local machine.

---

## Setting Up Your Remote Repository

### 1. Understanding the "Bare" Repository

In a local development folder, Git stores version history in a hidden `.git` folder. 
However, a server repository should be **bare**. 

A bare repository has no working directory (you can't run `git checkout` inside it); it only contains the 
versioning data.

**On the Server:**

```bash
# Create a directory for your project
mkdir -p /srv/git/MyGitProject.git
cd /srv/git/MyGitProject.git

# Initialize as a bare repository
git init --bare

```

### 2. The Relationship Between Folders

| Feature | Standard Repository (`git init`) | Bare Repository (`git init --bare`) |
| --- | --- | --- |
| **Purpose** | Local development/coding | Server-side storage/hub |
| **Editable Files** | Yes (Working tree present) | No (Only Git metadata) |
| **Structure** | Contains `.git` folder | The folder *is* the contents of `.git` |

---

## Client Usage

Once the bare repository is initialized on the server, any client with SSH access can interact with it.

```bash
# On the Client machine:
# Clone the repository using the server's IP or hostname
git clone user@server_ip:/srv/git/MyGitProject.git

# Work as usual
cd MyGitProject
touch main.c
git add main.c
git commit -m "Initial commit"

# Push back to the server
git push origin main

```

---

## Professional Management: The "git" User

In a production environment, you shouldn't give every developer your personal SSH password. 
Instead, it is common practice to create a single user named `git`.

1. **Create a 'git' user:** This user handles all repository ownership.
2. **Authorized Keys:** Instead of passwords, developers add their public keys to `/home/git/.ssh/authorized_keys`.
3. **Restricted Shell:** To prevent developers from logging into the server as a full shell user 
   (as seen in your GitHub example), change their shell to `git-shell`.

```bash
# On the server, restrict the git user to git commands only
chsh -s $(which git-shell) git

```

Now, if a user tries to `ssh git@yourserver.com`, they will receive a message stating: 

*"Hi! You've successfully authenticated, but interactive shell access is forbidden,"*

Exactly like GitHub.

---

### Further Reading

For advanced protocol configurations (including HTTP/S setup), refer to **Chapter 4 of the Pro Git Book: 
"Git on the Server"**.


A bash script to be run on your server. 
It creates the directory, initializes the bare repository, and sets the ownership to your `git` user.

---

### The Repository Creation Script (`create-git-repo.sh`)

```bash
#!/bin/bash

# Configuration: Update this path to where you want your repos stored
GIT_DIR="/srv/git"
GIT_USER="git"

if [ -z "$1" ]; then
    echo "Usage: ./create-git-repo.sh <repo-name>"
    exit 1
fi

REPO_NAME="$1"

# Ensure repo ends in .git for standard convention
if [[ ! "$REPO_NAME" =~ \.git$ ]]; then
    REPO_NAME="$REPO_NAME.git"
fi

FULL_PATH="$GIT_DIR/$REPO_NAME"

# 1. Create the directory
if [ -d "$FULL_PATH" ]; then
    echo "Error: Repository $REPO_NAME already exists!"
    exit 1
fi

sudo mkdir -p "$FULL_PATH"

# 2. Initialize the bare repository
sudo git init --bare "$FULL_PATH"

# 3. Fix permissions so the 'git' user owns it
sudo chown -R $GIT_USER:$GIT_USER "$FULL_PATH"

echo "------------------------------------------------"
echo "Success! Your bare repository is ready at:"
echo "$FULL_PATH"
echo ""
echo "Clients can now clone it using:"
echo "git clone $GIT_USER@$(hostname -I | awk '{print $1}'):$FULL_PATH"
echo "------------------------------------------------"

```

---

### How to use this script:

1. **Save the file:** Create the file on your server (e.g., `nvim create-git-repo.sh`).
2. **Make it executable:** Run `chmod +x create-git-repo.sh`.
3. **Run it:** Whenever you need a new project, just type:
```bash
./create-git-repo.sh my-new-app

```



### Why we use `git-shell`

As you noted with your GitHub example, security is paramount. 
When you add users to your server via SSH keys, you don't want them browsing your server's `/etc` or `/home`
directories.

By setting the user's shell to `git-shell`, you effectively "lock" them into only being able to run 
`git push`, `git pull`, and `git clone`. 
If they try to SSH in normally, the connection will simply drop after authentication, keeping your server 
secure.

## SSH Key Authentication:

Setting up SSH key-based authentication is the "final piece" step.
It makes your Git server behave exactly like GitHub—secure, fast, and password-free.

---

### How SSH Key Authentication Works

Instead of a password, your client and the server perform a "handshake" using a pair of cryptographic keys:
A **Public Key** (which you share with the server) and a **Private Key** (which stays safely on your machine).

#### Step 1: Generate your Keys (on your Local PC)

If you haven't done this already, open your terminal then do the below:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"

```

*Press Enter through the prompts to save the file in the default location (`~/.ssh/id_ed25519`).*


#### Step 2: Push your Public Key to the Server

You need to add your **Public Key** (`.pub`) to the `authorized_keys` file of the `git` user on your server.

**The easiest way (from your Local PC):**

```bash
ssh-copy-id git@your_server_ip

```

*(If `ssh-copy-id` isn't available, you can manually copy the text inside your `~/.ssh/id_ed25519.pub` file 
  and paste it into `/home/git/.ssh/authorized_keys` on the server.)*

---

### Step 3: Lockdown for Security (The GitHub Style)

To ensure users can only use Git and cannot log in to a command prompt (shell), you must change their 
default shell to `git-shell`.

**On the Server:**

1. Check if `git-shell` is in your shells list:
```bash
cat /etc/shells

```
*If you don't see `/usr/bin/git-shell` (or similar), find where it is with `which git-shell` and add that 
 path to `/etc/shells`.*

2. Change the shell for the `git` user:
```bash
sudo chsh -s $(which git-shell) git

```



### The Result

Now, when you try to log in via SSH:

```bash
ssh git@your_server_ip

```

The server will respond with:

> *Fatal: Interactive git shell is not allowed.*

However, your Git commands will work perfectly:

```bash
git clone git@your_server_ip:/srv/git/project.git  # No password required!

```

---

### Summary Table: Your Self-Hosted Git Stack

| Component | Responsibility |
| --- | --- |
| **OpenSSH** | The gatekeeper (handles the secure tunnel). |
| **`authorized_keys`** | The guest list (who is allowed in). |
| **`git-shell`** | The bouncer (restricts users to Git commands only). |
| **Bare Repos** | The storage (pure versioning data). |

## Managing multiple Users via `.ssh/authorized_keys` 

When you have a team, everyone shares the same `git` system user on the server, but they each use their own 
unique **SSH Key**. 

This allows you to grant or revoke access to individuals without ever sharing a single password.

### Managing Multiple Users via `authorized_keys`

The `/home/git/.ssh/authorized_keys` file acts as your "Access Control List." Each line in this file 
represents one user's public key.

To add a new team member:

1. Ask them to send you their `id_ed25519.pub` file.
2. Append their key to the end of your `authorized_keys` file:
```bash
cat user_b_key.pub >> /home/git/.ssh/authorized_keys

```


#### Pro-Tip: Identifying Keys

To keep track of whose key is whose, you can add a comment at the end of each line in the `authorized_keys` 
file (usually the email address provided during key generation):

```text
ssh-ed25519 AAAAC3Nza...v673Z user-a@company.com
ssh-ed25519 AAAAC3Nza...b219X user-b@company.com

```


### Advanced: Restricting Access per Repository

By default, any user in the `authorized_keys` file has access to **every** repository owned by the `git` 
user. 

If you need more granular control (e.g., *User A can see Project 1, but not Project 2*), you have two main 
paths:

### Option 1: Linux Permissions (The Manual Way)

You can create different Linux groups for different projects and add users to those groups. 
However, this becomes very difficult to manage as the team grows.

### Option 2: Gitolite (The Professional Way)

If your requirements get complex, most people use **Gitolite**. 
It is a perl-based layer that sits on top of SSH.

* **How it works:** You manage permissions by editing a special "admin" git repository.
* **Capabilities:** You can define rules like:
* `RW+` (Read/Write/Delete) for Senior Devs.
* `R` (Read Only) for Interns.
* Specific access to certain branches only.



---

### The "Final" Setup Checklist

1. **Server:** Has `git` and `openssh-server` installed.
2. **User:** A dedicated `git` user with its shell set to `git-shell`.
3. **Security:** All developers' public keys are in `/home/git/.ssh/authorized_keys`.
4. **Storage:** Repositories are initialized with `--bare` and owned by the `git` user.



