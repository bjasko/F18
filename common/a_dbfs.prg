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

static __f18_dbfs := nil

// -------------------------------
// -------------------------------
function set_a_dbfs()
local _dbf_fields, _sql_order
local _alg

public gaDbfs := {}

__f18_dbfs := hb_hash()


set_a_dbf_fin()

set_a_dbf_sifarnici()

set_a_dbf_sifk_sifv()

set_a_dbf_sifarnici()




set_a_dbfs_legacy()

return


// -------------------------------------------------------------
// -------------------------------------------------------------
function set_a_dbf_sifarnici()

 set_a_dbf_sifarnik("f18_rules"  , "FMKRULES"  , F_FMKRULES  )
 set_a_dbf_sifarnik("ops"        , "OPS"       , F_OPS        )
 set_a_dbf_sifarnik("banke"      , "BANKE"     , F_BANKE      )

return


// -------------------------------------------------------
// -------------------------------------------------------
function set_a_dbf_sifk_sifv()
local _alg

_alg := hb_hash()
_alg["dbf_key_fields"] := { "id", "oznaka" } 
_alg["dbf_tag"]        := "ID"
_alg["sql_in" ]        := "rpad(id,8) || rpad(oznaka,4)"
_alg["dbf_key_block" ] := {|| field->id  + field->oznaka}

set_a_dbf_sifarnik("sifk"       , "SIFK"      , F_SIFK       ,  _alg)


_alg := hb_hash()
_alg["dbf_key_fields"] := { "id", "oznaka", "idsif", "naz" } 
_alg["dbf_tag"]        := "ID"
_alg["sql_in" ]        := "rpad(id,8) || rpad(oznaka,4) || rpad(idsif,15) || rpad(naz,50)"
_alg["dbf_key_block" ] := {|| field->id + field->oznaka + field->idsif + field->naz}

set_a_dbf_sifarnik("sifv"       , "SIFV"      , F_SIFV       , _alg)

return


// ------------------------------------
// dodaj stavku u f18_dbfs
// ------------------------------------
function f18_dbfs_add(_tbl, _item)

__f18_dbfs[_tbl] := _item
return .t.



function f18_dbfs()
return __f18_dbfs


// ----------------------------------------------------
// sifarnici su svi na isti fol
// ----------------------------------------------------
function set_a_dbf_sifarnik(dbf_table, alias, wa, dbf_key_fields)
local _alg, _item

_item := hb_hash()

_item["alias"] := alias
_item["table"] := dbf_table
_item["wa"]    := wa

_item["temp"]  := .f.

_item["algoritam"] := {}

_alg := hb_hash()

if dbf_key_fields == NIL
   _alg["dbf_key_fields"] := {"id"}
   _alg["dbf_tag"]        := "ID"
   _alg["sql_in" ]        := "id"
   _alg["dbf_key_block" ] := {|| field->id }
else
   _alg["dbf_key_fields"] := dbf_key_fields
endif


AADD(_item["algoritam"], _alg)

   
f18_dbfs_add(dbf_table, @_item)
return .t.



// -------------------------------------------------------
// tbl - dbf_table ili alias
// -------------------------------------------------------
function get_a_dbf_rec(tbl)
local _rec, _keys, _dbf_tbl, _key

_dbf_tbl := "x"

if HB_HHASKEY(__f18_dbfs, tbl)
   _dbf_tbl := tbl

else
   // probaj preko aliasa
   for each _key IN __f18_dbfs:Keys
      if VALTYPE(tbl) == "N"

        // zadana je workarea
        if __f18_dbfs[_key]["wa"] == tbl
            _dbf_tbl := _key
        endif

      else 

        if __f18_dbfs[_key]["alias"] == UPPER(tbl)
            _dbf_tbl := _key
        endif

      endif    
   next 
endif

if HB_HHASKEY(__f18_dbfs, _dbf_tbl)
    // preferirani set parametara
    _rec := __f18_dbfs[_dbf_tbl]
else
    // legacy
    _rec := get_a_dbf_rec_legacy(tbl)
endif


// nije zadano - ja cu na osnovu strukture dbf-a
//  napraviti dbf_fields
if !HB_HHASKEY(_rec, "dbf_fields")
   set_dbf_fields_from_struct(@_rec)
endif

return _rec

// ----------------------------------------------
// setujem "sql_order" hash na osnovu 
// gaDBFS[_pos][6]
// rec["dbf_fields"]
// ----------------------------------------------
function sql_order_from_key_fields(key_fields)
local _i, _len
local _sql_order

// primjer: key_fields = {{"godina", 4}, "idrj", {"mjesec", 2}

_len := LEN(key_fields)

_sql_order := ""
for _i := 1 to _len

   if VALTYPE(key_fields[_i]) == "A"
      _sql_order += key_fields[_i, 1]
   else
      _sql_order += key_fields[_i]
   endif

   if _i < _len
      _sql_order += ","
   endif
next
   
return _sql_order    
   

// ----------------------------------------------
// setujem "dbf_fields" hash na osnovu stukture
// dbf-a 
// rec["dbf_fields"]
// ----------------------------------------------
function set_dbf_fields_from_struct(rec)
local _struct, _i
local _opened := .t.
local _fields :={}

SELECT (rec["wa"])

if !used()
    dbUseArea( .f., "DBFCDX", my_home() + rec["table"], rec["alias"], .t. , .f.)
    _opened := .t.
endif

_struct := DBSTRUCT()

for _i := 1 to LEN(_struct)
   AADD(_fields, LOWER(_struct[_i, 1]))
next

rec["dbf_fields"] := _fields

if _opened
   USE
endif

return .t.


