#!/bin/bash

# export QT_DIR=c:/knowhowERP/Qt

# export QT_DIR=c:\\Qt\\4.7.4
# export QT_DIR_CYGWIN=/c/Qt/4.7.4

# export HB_WITH_GTALLEGRO=no
# export HB_WITH_ALLEGRO=no
# export HB_WITH_GTWVG=yes




# export HB_INC_COMPILE=c:\harbour\include

# HB_INC_MYSQL=C:\mysql\5.0\include
# HB_LIB_MYSQL=c:\mysql\5.0\lib\opt

CUR_DIR=`pwd`
export HB_INSTALL_PREFIX=$CUR_DIR/hbout

# export HB_WITH_CURL=C:\\MinGW\\build\\include
# export HB_WITH_QT=${QT_DIR}\\include

# export HB_WITH_PGSQL=C:\\PostgreSQL\\9.1\\include

# export HB_WITH_MYSQL=c:\\MySQL\\include

export HB_WITH_SQLITE3=yes


export PATH=$PATH:$HB_INSTALL_PREFIX/bin

function build_harbour {
cd harbour/harbour
make
make install
cd ../../
}


function build_f18_test {
export KNOWHOW_ERP_ROOT=$CUR_DIR
export HARBOUR_ROOT=$KNOWHOW_ERP_ROOT/hbout

let KH_PATH=`echo $PATH | grep -c $KNOWHOW_ERP_ROOT/bin`

if [[ $KH_PATH -eq 0 ]]; then
     # echo "knowhowERP not in path ($KH_PATH) dodajem"
     export PATH=$KNOWHOW_ERP_ROOT/bin:$KNOWHOW_ERP_ROOT/util:$HARBOUR_ROOT/bin:$PATH
else
     echo "knowhowERP already in path ($KH_PATH): $PATH"
fi

export HB_COMPILER=gcc

export HB_INC_INSTALL=$HARBOUR_ROOT/include
export HB_LIB_INSTALL=$HARBOUR_ROOT/lib

. ./build_test.sh
}

function create_roles {
USER="test1"
ret=`echo "select rolname from pg_roles where rolname='$USER'" | psql -t -h localhost -U postgres | grep -q $USER`

if [[ "$ret" == "0" ]]; then
   echo "$USER postoji"
else
  echo "create user $USER with password '$USER'" | psql -h localhost -U postgres
fi

SQL="create role admin"
echo $SQL | psql -U postgres


SQL="create role xtrole"
echo $SQL | psql -U postgres

SQL="grant xtrole TO test1 GRANTED BY postgres"
echo $SQL | psql -U postgres

SQL="grant xtrole TO admin GRANTED BY postgres"
echo $SQL | psql -U postgres
}

function create_databases {
#pg_dump -h localhost -U postgres f18_test > f18_test.sql
echo "CREATE database f18_test" | psql -U postgres
psql -U postgres f18_test < test/data/f18_test.sql
}


function install_jod_reports {

GCODE_URL_ROOT_F18=http://knowhow-erp-f18.googlecode.com/files
GCODE_URL_ROOT=http://knowhow-erp.googlecode.com/files

D_FILE=jodreports-cli.jar
wget -q -nc $GCODE_URL_ROOT_F18/$D_FILE

DEST=/opt/knowhowERP/util/

sudo mkdir -p $DEST
cp $D_FILE  $DEST
}

build_harbour

build_f18_test

create_roles
create_databases

#Xvfb :1 -screen 1 1024x768x16 &


install_jod_reports

#export DISPLAY=:1
./F18_test
