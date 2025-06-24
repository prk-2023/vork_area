# Git how to merge a testing branch with master branch

1. Create a testing branch from master:

```
git  checkout master
git pull origin master
git checkout -b testing

```
this will set the remote in the testing branch ( nothing has to be done for this )
For some reason if you need to set the remote manually use the below commands

```
git branch --set-upstream-to=origin/testing testing
```

2. (optional )If you want to 'push' the new branch to remote repo

```
git push -u origin testing 
```

3. To move the changes/fixes to the testing branch to master there are 3 ways:

- Use merge :most straight forward and commonly used 
```
# Make sure your working directory is clean
git checkout master
git pull origin master  # Get the latest changes from remote
git merge testing       # Merge changes from testing
git push origin master  # Push merged changes back to remote
```    
This will create a merge commit (unless it's fast-forward merge ) preserving the history from testing.

- Use cherry-pick a specific patch from testing
If you only want to apply specific commits (not the whole branch), use cherry-pick:

```
git checkout master
git pull origin master
git cherry-pick <commit-hash>
git push origin master
```
NOTE: This method is useful if you want to apply just one patch or a subset of commits from testing.

-  **Rebase testing onto master and fast-forward**:
This keeps a linear history but rewrites commits:

```
git checkout testing
git rebase master
# Resolve any conflicts during rebase if they appear
git checkout master
git merge testing  # Will be fast-forward if no new commits on master
git push origin master

```
NOTE: This is cleaner for history but should only be done on local or personal branches — avoid it for
public/shared branches unless you coordinate with your team.

| Method         | Use Case                                     | Preserves History | Rewrites History |
| -------------- | -------------------------------------------- | ----------------- | ---------------- |
| Merge          | Bring all changes from `testing` to `master` | ✅ Yes             | ❌ No             |
| Cherry-pick    | Bring only specific commits                  | ✅ Yes (partial)   | ❌ No             |
| Rebase + Merge | Keep history clean and linear                | ❌ No              | ✅ Yes            |


# Explanation of  rebase method:
---

### 1. `git checkout testing`

* **What it does:**
  Switches your working directory to the `testing` branch where your new patch/commits are.

* **Why:**
  Because you want to **rebase** the changes on top of the latest `master` branch.

---

### 2. `git rebase master`

* **What it does:**
  Reapplies the commits from `testing` **on top of** the current `master` branch.

* **How it works:**
  Git temporarily "rewinds" the commits in `testing`, moves your branch pointer to `master`, and then 
  reapplies your `testing` commits one-by-one as if they were new changes made after `master`.

* **Why:**
  This makes your `testing` branch look like it was developed starting from the latest `master` branch —
  creating a **linear history** without merge commits.

* **Note:**
  If your changes and `master` changes affect the same parts of the code, you might get **conflicts** here 
  that you’ll need to resolve manually.

---

### 3. `# Resolve any conflicts during rebase if they appear`

* **What it means:**
  If there are conflicts during the rebase, Git will pause and ask you to manually fix the conflicting files.

* **How to resolve:**

  * Open the files with conflicts, fix them.
  * Run `git add <fixed-files>`
  * Then continue the rebase with `git rebase --continue`
  * Repeat until all conflicts are resolved and rebase completes.

---

### 4. `git checkout master`

* **What it does:**
  Switches your working directory back to the `master` branch.

* **Why:**
  You want to bring the rebased commits from `testing` into `master`.

---

### 5. `git merge testing  # Will be fast-forward if no new commits on master`

* **What it does:**
  Merges the `testing` branch into `master`.

* **Why:**
  Since you rebased `testing` onto `master`, `master` is behind `testing` but has no new commits of its own.
  So Git can do a **fast-forward merge**, which simply moves the `master` branch pointer forward to match 
  `testing`.

* **Result:**
  The `master` branch now includes all your new patches from `testing`, with a clean, linear history.

---

### 6. `git push origin master`

* **What it does:**
  Pushes your updated local `master` branch to the remote repository (e.g., GitHub).

* **Why:**
  To update the remote `master` branch with the new changes you integrated.

---

### recap:

This workflow rebases your feature branch on the latest `master` to maintain a clean history, then 
fast-forwards `master` to include your changes — avoiding merge commits and making the commit log neat and 
linear.

