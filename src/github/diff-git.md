
# Getting the difference between two repositories

How can we get the difference between two git repositories?

The scenario: We have a repo_a and repo_b. The latter was created as a copy of repo_a. There have been parallel development in both the repositories afterwards. Is there a way we can list the differences of the current versions of these two repositories?

## Answer

In repo_a:

```bash
git remote add -f b path/to/repo_b.git
git remote update
git diff master remotes/b/master
git remote rm b
```

