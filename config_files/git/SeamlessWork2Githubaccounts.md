# How to seamlessly work with multiple GitHub accouts from a single development machine:



To seamlessly work with multiple GitHub accounts (e.g., `user1` and `user2`) from a single development 
machine, you can set up separate SSH keys for each account. Here's how you can do that on your Linux PC:

### Step-by-Step Guide:

1. **Generate SSH Keys for Both Accounts:**

   Open a terminal and create separate SSH keys for each GitHub account.

   **For `user1`:**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "user1@example.com"
   ```
   When prompted for the file to save the key, specify a different file name to distinguish it from the 
   default key (e.g., `id_rsa_user1`):
   ```
   Enter file in which to save the key (/home/your-user/.ssh/id_rsa): /home/your-user/.ssh/id_rsa_user1
   ```

   **For `user2`:**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "user2@example.com"
   ```
   Similarly, save it with a distinct file name:
   ```
   Enter file in which to save the key (/home/your-user/.ssh/id_rsa): /home/your-user/.ssh/id_rsa_user2
   ```

2. **Add SSH Keys to the SSH Agent:**

   Start the SSH agent if it's not running:
   ```bash
   eval "$(ssh-agent -s)"
   ```

   Add both SSH private keys to the agent:

   **For `user1`:**
   ```bash
   ssh-add ~/.ssh/id_rsa_user1
   ```

   **For `user2`:**
   ```bash
   ssh-add ~/.ssh/id_rsa_user2
   ```

3. **Add SSH Keys to GitHub Accounts:**

   Copy each public key to the clipboard and add them to the respective GitHub accounts.

   **For `user1`:**
   ```bash
   cat ~/.ssh/id_rsa_user1.pub
   ```

   Copy the output and go to **GitHub > Settings > SSH and GPG Keys > New SSH Key**, and paste it there.

   **For `user2`:**
   ```bash
   cat ~/.ssh/id_rsa_user2.pub
   ```

   Similarly, go to **GitHub > Settings > SSH and GPG Keys > New SSH Key** for `user2` and paste it.

4. **Configure SSH to Use Different Keys for Each Account:**

   Edit (or create) the SSH configuration file (`~/.ssh/config`) to specify which key should be used for 
   each GitHub account.

   ```bash
   nano ~/.ssh/config
   ```

   Add the following configuration for `user1` and `user2`:

   ```ssh
   # GitHub for user1
   Host github.com-user1
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_rsa_user1

   # GitHub for user2
   Host github.com-user2
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_rsa_user2
   ```

   This configuration tells SSH to use the appropriate key depending on which GitHub account you're 
   interacting with.

5. **Clone Repositories Using the Correct Host:**

   When cloning repositories, use the custom host specified in your SSH config.

   **For `user1`:**
   ```bash
   git clone git@github.com-user1:user1/repository-name.git
   ```

   **For `user2`:**
   ```bash
   git clone git@github.com-user2:user2/repository-name.git
   ```

   This ensures that the correct SSH key is used for each repository.

6. **Ensure Correct SSH Key for Existing Repositories:**

   If you already have repositories cloned and need to update them to use the correct SSH key, you can 
   modify the remote URL to point to the appropriate `Host`.

   **For `user1`:**
   ```bash
   git remote set-url origin git@github.com-user1:user1/repository-name.git
   ```

   **For `user2`:**
   ```bash
   git remote set-url origin git@github.com-user2:user2/repository-name.git
   ```

### Summary:
- You create separate SSH keys for each GitHub account.
- Add both keys to the SSH agent.
- Associate each key with its respective GitHub account.
- Use an SSH configuration file to specify which key should be used for each account.
- Clone repositories using the appropriate host names (`github.com-user1` or `github.com-user2`).
  
By following these steps, you can seamlessly push and pull from both GitHub accounts without conflicts, 
even on the same machine.
