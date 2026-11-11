# How to create an empty brach

Create an empty branch like this

```bash
git checkout --orphan BRANCH-NAME
git rm -rf .
```

Then push it to your repo

```bash
git push -u origin BRANCH-NAME
```
