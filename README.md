## What is that?
*casual-git* is just a bash script that helps you to automate interaction with Git. It's a wrapper for Git.

It can:
- `git push` or `git pull` or `git log` or `git commit` or `git commit --amend --no-edit` by only pressing 4 keys
- `git push --force` or `git pull` + `git reset --hard origin/HEAD` by only pressing 5 keys
- switch to a branch if you only remember a part of the full name
- switch to one of branches matching a pattern
- make a commit  containing long file names with no need to enter them at all

```
  d  - push
  f  - push --force
  p  - pull
  o  - pull --force
  c  - commit
  a  - commit --amend
  s  - commit --smart
  l  - log --pretty
  h  - checkout --smart
```

It is hardcoded to work with *origin* only .

## How to install
1. `git clone https://github.com/x0st/casual-git`
2. `cd casual-git`
3. `make`
4. Invoke the `gh` command within git repositories to open `casual-git`

## Some examples of usage

### Smart commit
```
  d  - push
  f  - push --force
  p  - pull
  o  - pull --force
  c  - commit
  a  - commit --amend
  s  - commit --smart
  l  - log --pretty
  h  - checkout --smart
  
  Delete files from the next commit: 
  [-1] new file: test1
  
  Add files to the next commit: 
  [1] modified:  gulpfile.js
  [2] modified:  package.json
  [3] untracked: test
  
  Enter file numbers separating by spaces: -1 2 3
  
  Enter a comment: my commit
```

### Smart branch switching
```
  d  - push
  f  - push --force
  p  - pull
  o  - pull --force
  c  - commit
  a  - commit --amend
  s  - commit --smart
  l  - log --pretty
  h  - checkout --smart
  
  Enter a branch name or a part of name: ma
  
  More than one git branch were found. 
  10 first branches are shown. 
  Please choose a desired branch. 
  
  [0] feature/EGNYTE-20-watermarks-over-documents
  [1] master
  [2] masterfix/EGNYTE-21-big-files-merge
  [3] masterfix/EGNYTE-26
  [4] masterfix/EGNYTE-29-big-files-merge
  [5] masterfix/EGNYTE-33
  [6] masterfix/EGNYTE-41
  
Switched to branch 'feature/EGNYTE-20-watermarks-over-documents'
```
