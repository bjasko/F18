#!/bin/bash

MODULES="main fin kalk fakt os ld virm epdv rnal kadev test common"
MODULES="$MODULES core_ui2 core_dbf core_sql  reporting  semafori"


#export F18_GT_QTC=1

echo "====== INFO: ======"
echo ">> debug:" 
echo "export F18_DEBUG=1"
echo ">>console:"
echo "export F18_GT_CONSOLE=1"

#export F18_FIN=1
#export F18_KALK=1
#export F18_FAKT=1
#export F18_FIN_OSTAVKE=1
#export F18_POS=1
#export F18_EPDV=1
#export F18_CORE_ONLY=1
#export F18_OS=1
#export F18_LD=1
#export F18_VIRM=1

export HB_QT_MAJOR_VER=5

