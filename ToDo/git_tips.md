# Git tips and tricks

### how to delete a single or multiple commits from middle.


Ex: how to remove "commit 2" from the below git log

   ```
   $ git log
   d00d335 commit C19: Support abc
   36603da commit 5
   a489bf4 commit 4
   8dd32e0 commit 3
   1e2c9f7 commit 2
   e409087 commit 1
   ```


To remove commit 2 from your Git history, you can use **`git rebase`** interactively. 
Interactive rebasing allows you to modify commits, reorder them, or even remove them entirely from the history.

Here's a step-by-step guide to removing commit 2:

### Steps to Remove Commit 2 Using Interactive Rebase

1. **Start Interactive Rebase**:
   First, you need to determine how far back commit 2 is from the current `HEAD`. Looking at your `git log`,
   commit 2 is the second-to-last commit (before the most recent commit on `HEAD`), so you’ll rebase back 
   to **commit 3**.

   Run the following command to start an interactive rebase for the last 6 commits 
   (since you have 6 commits listed):
   
   ```bash
   git rebase -i HEAD~6
   ```

2. **Edit the Rebase List**:
   After running the above command, your default editor will open with a list of commits, something like this:

   ```
   pick e409087 commit 1
   pick 1e2c9f7 commit 2
   pick 8dd32e0 commit 3
   pick a489bf4 commit 4
   pick 36603da commit 5
   pick d00d335 commit C19: Support abc
   ```

3. **Remove Commit 2**:
   In the list, locate **commit 2** (the line with `1e2c9f7 commit 2`). To remove it, simply delete that 
   line. After deletion, the file will look like this:

   ```
   pick e409087 commit 1
   pick 8dd32e0 commit 3
   pick a489bf4 commit 4
   pick 36603da commit 5
   pick d00d335 commit C19: Support abc
   ```

4. **Save and Close the Editor**:
   After removing the line corresponding to commit 2, save the file and close the editor. 
   In most editors, you can save and exit with:
   - **Vim**: Press `Esc`, then type `:wq` and press Enter.
   - **Nano**: Press `Ctrl+X`, then `Y`, and press Enter.

5. **Resolve Any Conflicts (if any)**:
   After closing the editor, Git will attempt to rebase the commits. 
   If there are any conflicts (for example, if commit 2 modified files that other commits also modify), 
   Git will stop and ask you to resolve the conflicts.

   To resolve conflicts:
   - Open the conflicted files.
   - Resolve the conflicts manually.
   - After resolving, stage the changes using:
     ```bash
     git add <conflicted-file>
     ```
   - Continue the rebase:
     ```bash
     git rebase --continue
     ```

6. **Complete the Rebase**:
   After resolving any conflicts (if there were any), the rebase will complete, and commit 2 will be 
   removed from your Git history.

7. **Force Push to Remote (if necessary)**:
   If you've already pushed these commits to a remote repository (as suggested by the `origin/myproj` 
   branch), you'll need to force-push the rebased branch to update the remote history:

   ```bash
   git push origin encoder --force
   ```

   **Note:** Force pushing rewrites history, so use this carefully, especially if other people are working 
   on the same branch.

---

### Summary
- Use **interactive rebase** (`git rebase -i HEAD~6`) to open the commit list.
- Delete the line corresponding to commit 2.
- Save and close the editor.
- Resolve conflicts if necessary and continue the rebase (`git rebase --continue`).
- Force-push the changes to the remote repository if needed (`git push --force`).

This will effectively remove commit 2 from the history.
