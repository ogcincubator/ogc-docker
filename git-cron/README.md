# git-cron

Simple Docker image to clone Git repositories and pull from them periodically.

## Setup

Repositories can be defined by using environment variables in the form `CRON_REPO_<name>=<url>[ <subdir>]`, e.g. 
`CRON_REPO_myrepo=https://github.com/githubtraining/hellogitworld.git my-repo`. 

Repositories will be cloned under `/repos/<name>`, unless `subdir` is passed (note the space before `subdir`).
In the previous example, the repository would be cloned in `/repos/my-repo`
(`/repos/myrepo` if the trailing ` my-repo` were omitted).
The `/repos` directory should be mounted as a volume if persistence is desired.

Update frequency can be set using the `CRON_EXPRESSION` environment variable (default: `*/30 * * * *`). 

## Limitations

* Only public repositories can be cloned (there are no authentication mechanisms).