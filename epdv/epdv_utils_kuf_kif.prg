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

// ------------------------------------------------
// otvori tabele potrebne za ispravku kuf-a
// ------------------------------------------------
function o_kuf(lPriprema)

if lPriprema == nil
	lPriprema := .f.
endif

select F_TARIFA
if !used()
	O_TARIFA
endif

select F_PARTN
if !used()
	O_PARTN
endif

select F_KUF
if !used()
	O_KUF
endif

if lPriprema == .t.
SELECT (F_P_KUF)

if !used()
	O_P_KUF
endif
endif


return


// ------------------------------------------------
// otvori tabele potrebne za ispravku kif-a
// ------------------------------------------------
function o_kif(lPriprema)

if lPriprema == nil
	lPriprema := .f.
endif

select F_TARIFA
if !used()
	O_TARIFA
endif

select F_PARTN
if !used()
	O_PARTN
endif

select F_KIF
if !used()
	O_KIF
endif

if lPriprema == .t.
SELECT (F_P_KIF)

if !used()
	O_P_KIF
endif
endif


return



// ------------------------
// ------------------------
function next_r_br(cTblName)

PushWa()
do case
	case cTblName == "P_KUF"
		SELECT p_kuf
	case cTblName == "P_KIF"
		SELECT p_kif
	
endcase

SET ORDER TO TAG "BR_DOK"
GO BOTTOM
nLastRbr := r_br
PopWa()
return nLastRbr + 1


// ------------------------
// ------------------------
function next_g_r_br(cTblName)

PushWa()
do case
	case cTblName == "KUF"
		SELECT kuf
	case cTblName == "KIF"
		SELECT kif
	
endcase

SET ORDER TO TAG "G_R_BR"

GO BOTTOM
nLastRbr := g_r_br
PopWa()
return nLastRbr + 1


// -----------------------------
// -----------------------------
function next_br_dok(cTblName)
local nLastBrDok


PushWa()
do case
	case cTblName == "KUF"
		SELECT kuf
	case cTblName == "KIF"
		SELECT kif
	
endcase

SET ORDER TO TAG "BR_DOK"

GO BOTTOM
nLastBrDok := br_dok
PopWa()

return nLastBrdok + 1


// ------------------------
// ------------------------
function rn_g_r_br(cTblName)
local nRbr, _rec
local _table := "epdv_kuf"

// TAG: datum : "dtos(datum)+src_br_2"

my_close_all_dbf()

do case
	case cTblName == "KUF"
		O_KUF
        _table := "epdv_kuf"
	case cTblName == "KIF"
		O_KIF
	    _table := "epdv_kif"
endcase

nRbr := 1
SET ORDER TO TAG "DATUM"

GO TOP

if !FLOCK()
	MsgBeep("Ne mogu zakljucati bazu " + cTblName + ;
	 "## renumeracije nije izvrsena !")
	 my_close_all_dbf()
endif	 

Box( , 2, 35)

f18_lock_tables({_table})
sql_table_update( nil, "BEGIN" )

do while !eof()

	@ m_x+1, m_y+2 SAY "Renumeracija: G_R_BR " + STR(nRbr, 4, 0)

    _rec := dbf_get_rec()
    _rec["g_r_br"] := nRbr
    update_rec_server_and_dbf( _table, _rec, 1, "CONT" )

	nRbr ++
	
    SKIP

enddo

f18_free_tables({_table})
sql_table_update( nil, "END" )

BoxC()

my_close_all_dbf()
return 

