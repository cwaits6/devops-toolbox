# Git Remote Migration

Update all repo `origin` URLs when moving from one Git host to another
(e.g., GitLab → GitHub, GitLab (old host) → GitLab (new host)).

Works with HTTPS (`https://host/...`) and SSH (`git@host:...`).
Replaces only the hostname — protocol, user, path stay the same.

## Setup

Edit the variables at the top of the script:

OLD_HOST="myoldgithost.com"
NEW_HOST="mynewgithost.com"
ROOT_DIR="$HOME/repos"
DRY_RUN=false

## Usage

### macOS/Linux
chmod +x git-remote-migrate.sh
./git-remote-migrate.sh

### Windows
.\git-remote-migrate.ps1

## Dry Run

Preview changes only:

DRY_RUN=true ./git-remote-migrate.sh
$DryRun = $true; .\git-remote-migrate.ps1

## Example Output

✔ /home/user/repos/project-a
    git@gitlabold.com:team/project-a.git
 -> git@gitlabnew.com:team/project-a.git

## Notes

- Finds all `.git` repos under ROOT_DIR.
- Changes only if OLD_HOST is in the URL.
- Works with GitLab, GitHub, Gitea, Bitbucket.
- Optional: enable `insteadOf` at the bottom for global rewrite.

