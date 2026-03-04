# How to work on Github repo

## Working on a cloned repo

Imagine you just cloned a repo with this command:

```bash
git clone https://www.github.com/michele13/debian-live-cockpit
```
You have made some changes but you can't push them because github does not allow password authentication anymore.
To update your repo online you first need to change the remote origin url, like this:

```bash
git remote set-url origin git@github.com:michele13/debian-live-cockpit.git
```

## New Github Repository

### Create a new repository on the command line

```bash
echo "# FromScratch" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:michele13/FromScratch.git
git push -u origin main
```

### ...or push an existing repository from the command line

```bash
git remote add origin git@github.com:michele13/FromScratch.git
git branch -M main
git push -u origin main
```

