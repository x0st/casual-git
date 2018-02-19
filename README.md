## What is that?
*casual-git* is a bash script that helps you to automate interaction with Git. It's a wrapper for Git.

It can:
- `git push` or `git pull` or `git log` or `git commit` or `git commit --amend --no-edit` by only pressing 4 keys
- `git push --force` or `git pull` + `git reset --hard origin/HEAD` by only pressing 5 keys
- switch to a branch if you only remember a part of the full name
- switch to one of branches matching a pattern
- make a commit containing long file names with no need to enter them at all
- fast and easily rebase onto a commit to modify its name or files

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
  m  - modify commit
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
The `S`/`s` `W`/`w` keys are available for pagination.
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
  m  - modify commit

  Enter a branch name or a part of name: t

  More than one git branch were found.
  Use the s|S and w|W keys on your keyboard for pagination.
  10 first branches are being shown.
  Please choose a desired branch.

  [0] API-2168-add-merchant-data-to-document
  [1] APII-1601-multiple-eventsubs-for-sametype
  [2] APII-2156-stripe-integration
  [3] APII-2157-extend-api-to-store-new-merchant-acc
  [4] APII-2168-payment-request-merchant-info
  [5] APII-2169-fix-bug-duplicate-payment
  [6] APII-2171-stripe-ach
  [7] Improvement_web_2689
  [8] Release_2.1.9.64_20140801_hotfix
  [9] Release_2.1.9.70_20140807_hotfix
  
Switched to branch 'feature/EGNYTE-20-watermarks-over-documents'
```

### Commit modification
The `S`/`s` `W`/`w` keys are available for pagination.
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
  m  - modify commit

  [0] b866b85a5 - test commit
  [1] 288c39853 - Add new weekly-report-statistic report
  [2] cf87c03e1 - added code to support xls and ppt formats
  [3] f1f7cc448 - fixed conditionalfields.php
  [4] 60c1b46c9 - changed conditional fields'
  [5] dd39e20b3 - fixed code to consider tls1.2
  [6] 80e8c1881 - bla bla
  [7] bb8dd1d15 - fixed function call in expired invite cron
  [8] 62eee0417 - fixed function call in expired invite cron
  [9] 45ee1676e - Merge branch 'master' into feature-active

```
