# git-cron

Simple Docker image to clone Git repositories and pull from them periodically.

## Setup

Repositories can be defined by using environment variables in the form `CRON_REPO_<name>=<url>`, e.g. 
`CRON_REPO_myrepo=https://github.com/githubtraining/hellogitworld.git`

Repositories will be cloned under `/repos/<name>`. In the previous example, the repository would be 
cloned in `/repos/my_repo`. The `/repos` directory should be mounted as a volume
if persistence is desired.

Update frequency can be set using the `CRON_EXPRESSION` environment variable (default: `*/30 * * * *`). 

## Limitations

* Only public repositories can be cloned (there are no authentication mechanisms).
* Since subdirectory names are derived from those of the environment variables, only valid shell variable name
characters can be used (e.g., no `-`).