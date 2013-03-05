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


// -------------------------------------
// -------------------------------------
function set_a_dbf_os()
local _alg

// kumulativne tabele
set_a_dbf_os_sii_promj( "os_promj", "PROMJ", F_PROMJ )
set_a_dbf_os_sii_promj( "sii_promj", "SII_PROMJ", F_SII_PROMJ )

// tabele sa strukturom sifarnika (id je primarni ključ)
// u našem slučaju to su i os i sii (glavne tabele)

//OS CREATE_INDEX("1", "id+idam+dtos(datum)", _alias )
_alg := hb_hash()
_alg["dbf_key_fields"] := {"id"}
_alg["dbf_tag"]        := "1"
_alg["sql_in" ]        := "ID"
_alg["dbf_key_block" ] := {|| field->id }


set_a_dbf_sifarnik("os_os", "OS" , F_OS, _alg )
set_a_dbf_sifarnik("sii_sii", "SII" , F_SII, _alg )

set_a_dbf_sifarnik("os_k1" , "K1" , F_K1 )
set_a_dbf_sifarnik("os_amort" , "AMORT" , F_AMORT )
set_a_dbf_sifarnik("os_reval" , "REVAL" , F_REVAL )

// temp epdv tabele - ne idu na server
set_a_dbf_temp( "os_invent", "INVENT", F_INVENT )

return




// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
static function set_a_dbf_os_sii_promj( table, alias, area )
local _item, _alg, _tbl 

_tbl := table

_item := hb_hash()

_item["alias"] := alias
_item["table"] := _tbl
_item["wa"]    := area

// temporary tabela - nema semafora
_item["temp"]  := .f.

_item["algoritam"] := {}

// algoritam 1 - default
// -------------------------------------------------------------------------------
_alg := hb_hash()
_alg["dbf_key_block"]  := {|| field->id + field->tip + DTOS(field->datum) + field->opis }
_alg["dbf_key_fields"] := { "id", "tip", "datum", "opis" }
_alg["sql_in"]         := " rpad(id, 10) || rpad(tip, 2) || to_char(datum, 'YYYYMMDD') || rpad(opis, 30)" 
_alg["dbf_tag"]        := "1"
AADD(_item["algoritam"], _alg)

_item["sql_order"] := "id, tip, datum, opis"

f18_dbfs_add(_tbl, @_item)

return .t.



