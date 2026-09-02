# Manage Multiple Git servers:


Managing more than two GitHub accounts using SSH requires generating distinct key pairs for each account,
mapping them via custom host aliases in your SSH config file, and utilizing `IdentitiesOnly yes` to prevent
key overflow errors.

1. **Generate Distinct SSH Keys:** Terminal.
Open your terminal and generate a unique Ed25519 key pair for each account, replacing the email and
filenames accordingly:

```bash
ssh-keygen -t ed25519 -C "personal@example.com" -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C "work@example.com" -f ~/.ssh/id_ed25519_work
ssh-keygen -t ed25519 -C "sideproject@example.com" -f ~/.ssh/id_ed25519_side

```


2. **Add Public Keys to GitHub:** Web Dashboard.
Copy each public key (`.pub`) to your clipboard and paste them into their respective GitHub accounts under
**Settings > SSH and GPG keys > New SSH key**:

```bash
cat ~/.ssh/id_ed25519_personal.pub
# (Repeat for work and side keys)

```


3. **Configure the SSH Config File:** ~/.ssh/config.
Create or open your SSH config file (`~/.ssh/config`) and set up unique `Host` aliases for each account
pointing to `github.com`:

```text
# Account 1: Personal
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

# Account 2: Work
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes

# Account 3: Side Project
Host github.com-side
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_side
  IdentitiesOnly yes

```


4. **Register Keys with the SSH Agent:** Terminal.
Add your private keys to the local SSH agent:

```bash
ssh-add ~/.ssh/id_ed25519_personal
ssh-add ~/.ssh/id_ed25519_work
ssh-add ~/.ssh/id_ed25519_side

```


5. **Clone Repositories Using Host Aliases:** Git Usage.
When cloning a repository, substitute standard `github.com` with the custom `Host` alias you defined in your
config.

For example, for your work account:

```bash
git clone git@github.com-work:work-username/repo-name.git

```

For an existing local repository, update its remote URL manually:

```bash
git remote set-url origin git@github.com-work:work-username/repo-name.git

```


--- 
## Other Git servers:

This exact same SSH aliasing concept works for any Git server, including GitLab, Bitbucket, Azure DevOps,
and self-hosted instances like Gitea or GitHub Enterprise.

**Multi-Server SSH Configuration Example**
To use different keys for different services or multiple accounts on the same service (e.g., a personal and
work GitLab account), define unique `Host` aliases and point the `HostName` to the respective server domain.

```text
# Personal GitLab Account
Host gitlab.com-personal
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab_personal
  IdentitiesOnly yes

# Corporate GitLab Server
Host gitlab.mycompany.com
  HostName gitlab.mycompany.com
  User git
  IdentityFile ~/.ssh/id_ed25519_company
  IdentitiesOnly yes

# Bitbucket Account
Host bitbucket.org-personal
  HostName bitbucket.org
  User git
  IdentityFile ~/.ssh/id_ed25519_bitbucket
  IdentitiesOnly yes

```

**Key Adjustments for Other Services**

* **User Name:** Almost all major Git hosting providers use `git` as the SSH user (`User git`), but always
  verify the provider's documentation.
* **Cloning URLs:** Replace the standard domain in your clone command with your custom `Host` alias just
  like you did for GitHub:
```bash
git clone git@gitlab.com-personal:username/repo.git

```

---

## Managing Multiple Git Identities (`.gitconfig`)

When working with multiple accounts, servers, and email addresses, managing your Git author identity (`user.name` and `user.email`) manually for every repository becomes tedious. Git's **Conditional Includes** (`includeIf`) feature allows you to automate this based on your local directory structure.

**1. Create Your Global Configuration File:** `~/.gitconfig`
Set up a global fallback identity and conditional rules that load specific profile files depending on where a repository is located on your machine:

```ini
#Global fallback identity
[user]
    name = Default Name
    email = default@example.com

# Apply xyz configuration for repositories inside designated xyz folders
[includeIf "gitdir:~/projects/xyz1/"]
    path = ~/.gitconfig-xyz

[includeIf "gitdir:~/projects/new-xyz/"]
    path = ~/.gitconfig-xyz

# Apply abc configuration for repositories inside the abc folder
[includeIf "gitdir:~/projects/abc/"]
    path = ~/.gitconfig-abc

```

*(Note: The trailing slash `/` in `gitdir:` is critical to ensure Git matches all subdirectories within those paths).*

**2. Create the Specific Profile Files:**
Create the individual configuration files in your home directory to define the correct credentials for each project scope.

Create `~/.gitconfig-xyz`:

```ini
[user]
    name = User One
    email = user1@xyz.com

```

Create `~/.gitconfig-abc`:

```ini
[user]
    name = User Two
    email = user2@abc.com

```

**3. Verify Your Configuration:**
Navigate into any repository within your designated project folders and run the following command to confirm Git is automatically applying the correct email address:

```bash
git config user.email

```

```

```
