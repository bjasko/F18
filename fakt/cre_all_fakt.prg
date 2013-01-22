/* 
 * This file is part of the bring.out knowhow ERP, a free and open source 
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "fmk.ch"
#include "cre_all.ch"

// ---------------------------
// ---------------------------
function cre_all_fakt( ver )
local aDbf
local _alias, _table_name
local _created
local _tbl

aDbf:={}
AADD(aDBf,{ 'idfirma'   , 'C' ,   2 ,  0 })
AADD(aDBf,{ 'idtipdok'  , 'C' ,   2 ,  0 })
AADD(aDBf,{ 'brdok'     , 'C' ,  12 ,  0 })
AADD(aDBf,{ 'datdok'    , 'D' ,   8 ,  0 })
AADD(aDBf,{ 'IDPARTNER' , 'C' ,   6 ,  0 })
AADD(aDBf,{ 'DINDEM'    , 'C' ,   3 ,  0 })
AADD(aDBf,{ 'zaokr'     , 'N' ,   1 ,  0 })
AADD(aDBf,{ 'Rbr'       , 'C' ,   3 ,  0 })
AADD(aDBf,{ 'PodBr'     , 'C' ,   2 ,  0 })
AADD(aDBf,{ 'IDROBA'    , 'C' ,  10 ,  0 })
AADD(aDBf,{ 'IDROBA_J'  , 'C' ,  10 ,  0 })
AADD(aDBf,{ 'SerBr'     , 'C' ,  15 ,  0 })
AADD(aDBf,{ 'KOLICINA'  , 'N' ,  14 ,  5 })
AADD(aDBf,{ 'Cijena'    , 'N' ,  14 ,  5 })
AADD(aDBf,{ 'Rabat'     , 'N' ,   8 ,  5 })
AADD(aDBf,{ 'Porez'     , 'N' ,   9 ,  5 })
AADD(aDBf,{ 'K1'        , 'C' ,   4 ,  0 })
AADD(aDBf,{ 'K2'        , 'C' ,   4 ,  0 })
AADD(aDBf,{ 'M1'        , 'C' ,   1 ,  0 })
AADD(aDBf,{ 'TXT'       , 'M' ,  10 ,  0 })
AADD(aDBf,{ 'IDVRSTEP'  , 'C' ,   2 ,  0 })

// TODO: #29781
AADD(aDBf,{ 'IDPM'      , 'C' ,  15 ,  0 })
AADD(aDBf,{ 'FISC_RN'   , 'I' ,   4 ,  0 })
AADD(aDBf,{ 'C1'        , 'C' ,  20 ,  0 })
AADD(aDBf,{ 'C2'        , 'C' ,  20 ,  0 })
AADD(aDBf,{ 'C3'        , 'C' ,  20 ,  0 })
AADD(aDBf,{ 'N1'        , 'N' ,  10 ,  3 })
AADD(aDBf,{ 'N2'        , 'N' ,  10 ,  3 })

_alias := "FAKT"
_table_name := "fakt_fakt"

IF_NOT_FILE_DBF_CREATE

// 0.8.3
if ver["current"] > 0 .and. ver["current"] < 00803
  
  for each _tbl in { _table_name, "fakt_pripr" }
   modstru( {"*" + _tbl, ;
   "C FISC_RN N 10 0 FISC_RN I 4 0",  ;
   "D OPIS C 120 0", ;
   "D DOK_VEZA C 150 0" ;
    })
  next

endif

// 0.09.00
if ver["current"] > 00000 .and. ver["current"] < 00900
  for each _tbl in { _table_name, "fakt_pripr", "fakt_doks", "fakt_doks2", "fakt_pripr_atributi" }
   modstru( {"*" + _tbl, ;
   "C BRDOK C 8 0 BRDOK C 12 0"  ;
    })
  next
endif

IF_C_RESET_SEMAPHORE

CREATE_INDEX("1", "IdFirma+idtipdok+brdok+rbr+podbr", _alias)
CREATE_INDEX("2", "IdFirma+dtos(datDok)+idtipdok+brdok+rbr", _alias)
CREATE_INDEX("3", "idroba+dtos(datDok)", _alias)
CREATE_INDEX("6", "idfirma+idpartner+idroba+idtipdok+dtos(datdok)", _alias)
CREATE_INDEX("7", "idfirma+idpartner+idroba+dtos(datdok)", _alias)
CREATE_INDEX("8", "datdok", _alias)
CREATE_INDEX("IDPARTN","idpartner", _alias)

// ----------------------------------------------------------------------------
// fakt_pripr
// ----------------------------------------------------------------------------

_alias := "FAKT_PRIPR"
_table_name := "fakt_pripr"

IF_NOT_FILE_DBF_CREATE

CREATE_INDEX("1", "IdFirma+idtipdok+brdok+rbr+podbr", _alias)
CREATE_INDEX("2", "IdFirma+dtos(datdok)", _alias)
CREATE_INDEX("3", "IdFirma+idroba+rbr", _alias)

// fakt_pripr9
// opcija smece
_alias := "FAKT_PRIPR9"
_table_name := "fakt_pripr9"

IF_NOT_FILE_DBF_CREATE
 
CREATE_INDEX("1","IdFirma+idtipdok+brdok+rbr+podbr", _alias)
CREATE_INDEX("2","IdFirma+dtos(datdok)", _alias)
CREATE_INDEX("3","IdFirma+idroba+rbr", _alias)

// ----------------------------------------------------------------------------
// _fakt
// ----------------------------------------------------------------------------
_alias := "_FAKT"
_table_name := "fakt__fakt"

IF_NOT_FILE_DBF_CREATE

CREATE_INDEX("1", "IdFirma+idtipdok+brdok+rbr+podbr", _alias)


// fakt objekti
aDbf:={}
AADD(aDBf,{ 'ID'   , 'C' ,   10 ,  0 })
AADD(aDBf,{ 'NAZ'  , 'C' ,  100 ,  0 })

_alias := "FAKT_OBJEKTI"
_table_name := "fakt_objekti"

IF_NOT_FILE_DBF_CREATE

IF_C_RESET_SEMAPHORE

CREATE_INDEX( "ID", "ID", _alias )
CREATE_INDEX( "NAZ", "NAZ", _alias )

// fakt pripr atributi
aDbf:={}
AADD(aDBf,{ 'IDFIRMA'   , 'C' ,   2 ,  0 })
AADD(aDBf,{ 'IDTIPDOK'  , 'C' ,   2 ,  0 })
AADD(aDBf,{ 'BRDOK'     , 'C' ,  12 ,  0 })
AADD(aDBf,{ 'RBR'       , 'C' ,   3 ,  0 })
AADD(aDBf,{ 'ATRIBUT'   , 'C' ,  50 ,  0 })
AADD(aDBf,{ 'VALUE'     , 'C' , 250 ,  0 })

_alias := "FAKT_ATRIB"
_table_name := "fakt_pripr_atributi"

IF_NOT_FILE_DBF_CREATE

CREATE_INDEX("1", "idfirma + idtipdok + brdok + rbr + atribut", _alias )

// -------------------------------------------

_alias := "UPL"
_table_name := "fakt_upl"

aDBf:={}
AADD(aDBf,{'DATUPL'     ,'D', 8,0})
AADD(aDBf,{'IDPARTNER'  ,'C', 6,0})
AADD(aDBf,{'OPIS'       ,'C',30,0})
AADD(aDBf,{'IZNOS'      ,'N',12,2})

IF_NOT_FILE_DBF_CREATE

IF_C_RESET_SEMAPHORE

CREATE_INDEX("1", "IDPARTNER+DTOS(DATUPL)", _alias)
CREATE_INDEX("2", "IDPARTNER", _alias)

// -------------------------------------------

_alias := "FTXT"
_table_name := "fakt_ftxt"

aDbf:={}
AADD(aDBf,{'ID'  ,'C',  2 ,0})
AADD(aDBf,{'NAZ' ,'C',340 ,0})
	
IF_NOT_FILE_DBF_CREATE

IF_C_RESET_SEMAPHORE

CREATE_INDEX("ID","ID", _alias)


// -------------- fakt_doks --------------------------

aDbf:={}
AADD(aDBf, { 'idfirma'             , 'C' ,   2 ,  0 })
AADD(aDBf, { 'idtipdok'            , 'C' ,   2 ,  0 })
AADD(aDBf, { 'brdok'               , 'C' ,  12 ,  0 })
AADD(aDBf, { 'PARTNER'             , 'C' ,  30 ,  0 })
AADD(aDBf, { 'DATDOK'              , 'D' ,   8 ,  0 })
AADD(aDBf, { 'DINDEM'              , 'C' ,   3 ,  0 })
AADD(aDBf, { 'Iznos'               , 'N' ,  12 ,  3 })
AADD(aDBf, { 'Rabat'               , 'N' ,  12 ,  3 })
AADD(aDBf, { 'Rezerv'              , 'C' ,   1 ,  0 })
AADD(aDBf, { 'M1'                  , 'C' ,   1 ,  0 })
AADD(aDBf, { 'IDPARTNER'           , 'C' ,   6 ,  0 })
AADD(aDBf, { 'IDVRSTEP'            , 'C' ,   2 ,  0 })
AADD(aDBf, { 'DATPL'               , 'D' ,   8 ,  0 })
AADD(aDBf, { 'IDPM'                , 'C' ,  15 ,  0 })

AADD(aDBf, { 'OPER_ID'             , 'N' ,   3 ,  0 })
AADD(aDBf, { 'FISC_RN'             , 'N' ,  10 ,  0 })
AADD(aDBf, { 'DAT_ISP'             , 'D' ,   8 ,  0 })
AADD(aDBf, { 'DAT_VAL'             , 'D' ,   8 ,  0 })
AADD(aDBf, { 'DAT_OTPR'            , 'D' ,   8 ,  0 })

_alias := "FAKT_DOKS"
_table_name := "fakt_doks"

IF_NOT_FILE_DBF_CREATE

// 0.4.3
if ver["current"] > 0 .and. ver["current"] < 0403
    modstru({"*" + _table_name, "A FISC_ST N 10 0"})
endif

// 0.5.0
if ver["current"] > 0 .and. ver["current"] < 0500
    modstru({"*" + _table_name, "C PARTNER C 30 0 PARTNER C 100 0"})
    modstru({"*" + _table_name, "C OPER_ID N 3 0 OPER_ID N 10 0"})
endif

// 0.09.01
if ver["current"] > 00000 .and. ver["current"] < 00901
  for each _tbl in { "fakt_doks" }
   modstru( {"*" + _tbl, ;
       "D DOK_VEZA C 150 0"  ;
  })
  next
endif

IF_C_RESET_SEMAPHORE

create_index("1",  "IdFirma+idtipdok+brdok", _alias)
create_index("1D", "DTOS(DatDok)+IdFirma+idtipdok+brdok", _alias)
create_index("2",  "IdFirma+idtipdok+partner", _alias)
create_index("3",  "partner", _alias)
create_index("4",  "idtipdok", _alias)
create_index("5",  "datdok", _alias)
create_index("6",  "IdFirma+idpartner+idtipdok", _alias)



// ---------------- fakt_doks2 -------------------

_alias := "FAKT_DOKS2"
_table_name := "fakt_doks2"

aDbf:={}
AADD(aDBf,{ "IDFIRMA"      , "C" ,   2 ,  0 })
AADD(aDBf,{ "IDTIPDOK"     , "C" ,   2 ,  0 })
AADD(aDBf,{ "BRDOK"        , "C" ,  12 ,  0 })
AADD(aDBf,{ "K1"           , "C" ,  15 ,  0 })
AADD(aDBf,{ "K2"           , "C" ,  15 ,  0 })
AADD(aDBf,{ "K3"           , "C" ,  15 ,  0 })
AADD(aDBf,{ "K4"           , "C" ,  20 ,  0 })
AADD(aDBf,{ "K5"           , "C" ,  20 ,  0 })
AADD(aDBf,{ "N1"           , "N" ,  15 ,  2 })
AADD(aDBf,{ "N2"           , "N" ,  15 ,  2 })
	
IF_NOT_FILE_DBF_CREATE

IF_C_RESET_SEMAPHORE

CREATE_INDEX("1","IdFirma+idtipdok+brdok", _alias)

return .t.
