# New Github Repository


## Create a new repository on the command line

```bash
echo "# FromScratch" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:michele13/FromScratch.git
git push -u origin main
```

## ...or push an existing repository from the command line

```bash
git remote add origin git@github.com:michele13/FromScratch.git
git branch -M main
git push -u origin main
```

