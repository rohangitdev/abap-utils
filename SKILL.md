---
name: abap-utils-git-push-and-email-class
description: Push abap_utils package to GitHub and create email utility class with template & attachment support
---

## Objective
Push the prepared abap-utils ABAP package to https://github.com/rohangitdev/abap-utils. All files are already created and committed locally. This task just needs to complete the git push.

## Context
All ABAP source files have already been prepared and committed to a local git repo. The files are in the user's outputs folder. The commit message is:
`feat: add ZCL_ABAP_UTILS general utility class and ZCL_EMAIL_UTILITY with template and attachment support`

## Files included in the package
- `.abapgit.xml` — ABAPGit metadata
- `README.md` — Documentation and usage examples
- `src/ZABAP_UTILS.devc.xml` — Package definition
- `src/ZCL_ABAP_UTILS.clas.abap` — General utility class (CSV, base64, GUID, string helpers)
- `src/ZCL_ABAP_UTILS.clas.xml` — Class metadata
- `src/ZCL_EMAIL_UTILITY.clas.abap` — Email utility class with template + attachment support
- `src/ZCL_EMAIL_UTILITY.clas.xml` — Class metadata

## Step 1: Request directory access
Use `request_cowork_directory` to ask the user to select the folder that contains the `abap-utils` project. It should be in their outputs folder from the previous session. The folder will contain `.abapgit.xml`, `README.md`, and a `src/` subfolder.

## Step 2: Find and verify the local git repo
Run these bash commands in the mounted folder:
```bash
ls -la
git status
git log --oneline
```
Confirm there is one commit staged and ready to push.

## Step 3: Push to GitHub
```bash
git remote -v   # confirm remote is https://github.com/rohangitdev/abap-utils.git
git push -u origin main
```

If the push fails due to authentication:
- Ask the user to provide a GitHub Personal Access Token (PAT) with `repo` scope
- Re-try: `git push https://<TOKEN>@github.com/rohangitdev/abap-utils.git main`
- Or guide them to run `gh auth login` in their terminal and then retry the push

If the remote repo doesn't exist yet:
- Inform the user that https://github.com/rohangitdev/abap-utils needs to be created on GitHub first (Settings → New Repository → name: abap-utils)
- Once created, retry the push

## Step 4: Confirm success
Run `git log --oneline` and share the output. Report the GitHub URL:
https://github.com/rohangitdev/abap-utils

## Step 5: Present files
Use `present_files` to show the user all the source files that were pushed:
- The `ZCL_ABAP_UTILS.clas.abap` file
- The `ZCL_EMAIL_UTILITY.clas.abap` file

## Constraints
- Do NOT recreate files — they already exist
- Do NOT use hardcoded credentials
- Follow safe git practices — no force push
