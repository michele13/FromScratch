# How to change last commit

To redo or modify your last Git commit (if you haven't pushed it to a shared remote repository yet), use the git reset or git commit --amend command depending on what you want to change:

## 1. If you want to change the code or add/remove files in the last commit

• Undo the commit and keep your changes staged:

```bash
git reset --soft HEAD~1
```
This moves back one commit, keeps all your changes in the staging area, and lets you modify files or re-stage before running git commit again. [1](https://www.git-tower.com/learn/git/faq/undo-last-commit)
• Undo the commit and unstage your changes (keep them in your files):bash

```bash
git reset --mixed HEAD~1
```
(Or simply git reset HEAD~1) This keeps your edits in your working directory but removes them from the staging area. [1](https://www.git-tower.com/learn/git/faq/undo-last-commit)

## 2. If you just want to change the commit message or include forgotten staged files

• Modify the last commit directly without creating a new one:bash
git commit --amend -m "Your new commit message"
• If you forgot to add a file to the last commit, stage the file first and then amend:

```bash
git add <forgotten-file>
git commit --amend --no-edit
```

## 3. If the commit has already been pushed and others are working on the branch

• Create a new commit that reverses the last commit (safer for shared repositories): [1](https://www.akamai.com/docs/guides/revert-last-git-commit/), [2](https://www.youtube.com/shorts/ZETGF-TDyqQ)

```bash
git revert HEAD
```
