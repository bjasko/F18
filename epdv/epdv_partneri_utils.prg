/* 
 * This file is part of the bring.out FMK, a free and open source 
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "epdv.ch"


// ----------------------------------------------
// napuni sifrarnik sifk  sa poljem za unos 
// podatka o pripadnosti rejonu
//   1 - federacija
//   2 - rs
//   3 - distrikt brcko
// ---------------------------------------------
function epdv_set_sif_partneri()
local lFound
local cSeek
local cNaz
local cId


SELECT (F_SIFK)

if !used()
	O_SIFK
endif

SET ORDER TO TAG "ID"
//id+SORT+naz

cId := PADR("PARTN", 8) 
cNaz := PADR("1-FED,2-RS 3-DB", LEN(naz))
cSeek :=  cId + "09" + cNaz


SEEK cSeek   

if !FOUND()
    APPEND BLANK
    _rec := dbf_get_rec()
    _rec["id"] := cId
    _rec["naz"] := cNaz
    _rec["oznaka"] := "REJO"
    _rec["sort"] := "09"
    _rec["tip"] := "C"
    _rec["duzina"] := 1
    _rec["veza"] := "1"

    if !update_rec_server_and_dbf("sifk", _rec, fields, where_block) 
        delete_with_rlock()
    endif
endif


