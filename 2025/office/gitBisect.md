# Git Bisect:


Git Bisect:

    A powerful tool in Git that helps you find the specific commit that introduced a bug or broke a feature 
    in your codebase. 

    It works by performing a binary search through the commit history, helping you quickly narrow down the 
    range of commits where the problem was introduced. 
    Instead of manually testing each commit one by one, Git Bisect automates this process, significantly 
    reducing the time it takes to identify the problematic commit.

### How Git Bisect Works:

1. Start the Bisect Process:

    - You tell Git that you're starting a bisect process by specifying two commits:
        - A **bad commit**, which is the commit where the bug is currently present (usually latest commit
          or a known broken commit).

        - A **good commit**, which is a commit where the bug was not present (typically the last known 
          working commit).

2. Git Bisect Performs Binary Search:

    - Git will automatically check out a commit in the middle of the range between the good and bad commits,
      and then it will prompt you to test this commit.

    - You run your tests or manually check if the bug is present in this commit.

3. Mark Commit as Good or Bad:

    - After testing the commit:
        - If the bug is **not present** in the commit, you mark it as **good** (`git bisect good`).
        - If the bug **is present** in the commit, you mark it as **bad** (`git bisect bad`).
  
4. Narrow Down the Range:

    - Based on whether you marked the commit as good or bad, Git will narrow the search down to half of the 
      remaining commits and prompt you to test another commit in the middle of the new range.

    - This process continues, with Git halving the number of commits to check each time, until it identifies 
      the exact commit that introduced the problem.

5. Finish Bisect:

    - Once the problematic commit is found, Git will display it, and you can review the commit to understand
      what changes caused the issue.

    - After identifying the commit, you can use `git bisect reset` to stop the bisect process and return to 
      the branch where you started.


### Steps to Use Git Bisect:

1. Start the Bisect Process:


   ```bash
   $ git bisect start
   ```

2. Mark the Bad Commit:
   - Mark the commit where the bug is present (typically the current commit):

   ```bash
   $ git bisect bad
   ```

3. Mark the Good Commit:

   - Mark a known good commit where the bug was not present. You can specify a commit hash or use `HEAD~n` to refer to previous commits:
   ```bash
   $ git bisect good <commit_hash>
   ```

4. Test and Mark Commits:

   - Git will automatically check out a commit in the middle of the range. 
     Test this commit, then mark it as either **good** or **bad**.

   ```bash
   git bisect good   # If the commit works fine
   git bisect bad    # If the commit has the bug
   ```

5. Repeat:

    - Continue the process of testing and marking commits until Git identifies the commit that introduced 
      the issue.

6. End the Bisect Session:

   - Once Git has found the problematic commit, you can reset your working directory to the original branch:

   ```bash
   $ git bisect reset
   ```

### Example:

Let's say you're trying to find the commit that broke a feature. 
The current commit (HEAD) is broken, and you know the feature was working fine 10 commits ago. 
You can use `git bisect` to quickly pinpoint the exact commit.

1. Start the bisect process:
   ```bash
   $ git bisect start
   ```

2. Mark the current commit as bad:
   ```bash
   $ git bisect bad
   ```

3. Mark the last known good commit:
   ```bash
   $ git bisect good HEAD~10
   ```

4. Git will check out a commit in the middle of the range (e.g., HEAD~5). You then test it.

   - If the bug is present, you mark it as bad:
     ```bash
     $ git bisect bad
     ```
   - If the bug is not present, you mark it as good:
     ```bash
     $ git bisect good
     ```

5. Git will continue the binary search, halving the range each time, until it identifies the commit that 
   introduced the bug.

### Benefits of Using Git Bisect:

- **Efficiency**: 
    Instead of manually checking each commit, Git Bisect uses binary search to reduce the number of commits 
    you need to check.

- **Automation**: 
    You can script the testing process to automatically mark commits as good or bad based on automated test 
    results, making the process even faster.

- **Speed**: 
    It allows you to quickly pinpoint the specific commit responsible for a bug, saving time in debugging.

### Example Output:

```bash
$ git bisect start
$ git bisect bad
$ git bisect good HEAD~10
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[commit_hash] is the first bad commit
```

In this example, Git identifies the problematic commit and reports it, allowing you to review the changes 
introduced in that commit.

**Note**: 
Git Bisect is particularly useful when you don't know exactly when a bug was introduced but you have a 
range of commits to work with. 
It helps save time in isolating issues in large codebases.


