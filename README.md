# seaflow-realtime-dbs

This repository contains [popcycle](https://github.com/seaflow-uw/popcycle) database files for realtime monitoring of SeaFlow instrument deployments.

Each database file contains filtering and classification parameters for a single SeaFlow instrument on a research cruise.
It should contain populated tables for

* metadata information with cruise and serial (the `metadata` table)
* filtering parameters (the `filter` table)
* classification parameters (the `gating` and `poly` tables)
* a filtering plan (the `filter_plan` table)
* a classification plan ( the `gating_plan` table)

All other tables should be empty.

Each database file should be placed in the `dbs` subdirectory
and filenames should be formatted as `<cruise>_<instrument serial>.db`,
matching the `metadata` table.

Direct commits into main are prohibited.
All modifications must be made through pull requests.

To upload a new database file to this repository,
first create and checkout a new branch in a locally cloned copy of the repository.
It's a good idea to start from `main` and make sure it's up to date with `origin` before creating the new branch.
In this example the local branch will be called `KM2206-2022-06-13`.

```sh
git checkout main
git pull
git checkout -b KM2206-2022-06-13
```

Make modifications to an existing or new database file,
test that file with `.github/workflows/validate-dbs.R`,
then commit and push those changes.

```sh
Rscript .github/workflows/validate-dbs.R KM2206_740.db KM2206_130.db
# ...
# No errors
git add KM2206_740.db KM2206_130.db
git commit -m 'Modify KM2206 740 and 130 filt params to account for change in FSC PMT'
git push -u KM2206-2022-06-13 origin
```

Then, from either the github web interface or using the `gh` cli tool, create a pull request to `main` from this branch.
This will trigger automated tests (`.github/workflows/validate-dbs.R`) to make sure the database is compliant with the scheme laid out above
and that the database can be used to filter and classify the `popcycle` test data set.

The github actions for automated tests are defined in`.github/workflows/`.
To confirm that all tests passed, examine the action workflow in the Actions tab of the github repository.

Once all tests have passed the branch will be automatically merged into `main`.
