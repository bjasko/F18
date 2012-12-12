# F18 knowhowERP

[![Build
Status](https://secure.travis-ci.org/knowhow/F18_knowhow.png?branch=master)](https://travis-ci.org/knowhow/F18_knowhow)

## dev environment

### database init

#### Mac OSX ([Postgres.app](http://postgresapp.com))

kreiranje inicijalnih rola (test1, test2, admin):

    scripts/init_postgresql.sh `whoami`

kreiranje f18_test baze:

    export DB=f18_test
    echo "create database ${DB}" | psql -h localhost
    psql -h localhost ${DB} < test/data/${DB}.sql 
    echo "SELECT u2.knowhow_package_version('fmk')" | psql -h localhost ${DB} 

### build

<pre>
$ source scripts/(ubuntu | mac | win)_set_envars.sh
$
$ echo --- build debug ----
$ ./build.sh
$ ./F18
$ 
$ echo --- build test exe ---
$ ./build_test.sh
$ ./F18_test
$ .
$ echo --- build release (no debug) exe ---
$ ./build_release.sh
$ ./F18
</pre>


## Nakon db upgrade-a

### 1) Nove verzije [migracijskih skripti](https://github.com/knowhow/fmk/blob/master/publish.sh)

    fmk$ git tag 4.5.2
    fmk$ ./publish.sh  ## -> f18_db_migrate_package_4.5.2.gz
    fmk$ git push origin master --tags
 

### 2) Publish migracijsku skriptu na "knowhow-erp-f18 downloads"

publish na (google code](http://code.google.com/p/knowhow-erp-f18/downloads/list?can=2&q=db+migrate) aktuelnu verziju:

    http://code.google.com/p/knowhow-erp-f18/downloads/detail?name=f18_db_migrate_package_4.5.2.gz

### 3) Update LATEST_VERSIONS

Postaviti aktuelnu verziju u [LATEST_VERSIONS](https://github.com/knowhow/F18_knowhow/blob/master/LATEST_VERSIONS#L1)

F18_knowhow$ cat LATEST_VERSIONS | grep f18_db_migrate
    
     f18_db_migrate_package 4.5.2 gz

### 4) Travis - update test data

[Update test database for travis](https://github.com/knowhow/F18_knowhow/blob/master/TRAVIS.md)
