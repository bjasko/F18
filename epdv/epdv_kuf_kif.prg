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

// -------------------------------------------
// azuriranje kufa
// -------------------------------------------
function azur_kif()
return azur_ku_ki("KIF")

// -------------------------------------------
// azuriranje kif-a
// -------------------------------------------
function azur_kuf()
return azur_ku_ki("KUF")


// -------------------------------------------
// povrat kuf dokument
// -------------------------------------------
function pov_kuf( nBrDok )
return pov_ku_ki("KUF", nBrDok )

// -------------------------------------------
// povrat kif dokument
// -------------------------------------------
function pov_kif(nBrDok)
return pov_ku_ki("KIF", nBrDok)


// -------------------------------------------
// -------------------------------------------
function azur_ku_ki(cTbl)
local nBrDok
public _br_dok := 0

if cTbl == "KUF"
	o_kuf(.t.)
	// privatno podrucje
	nPArea := F_P_KUF
	
	// kumulativ 
	nKArea := F_KUF
else
	o_kif(.t.)
	nPArea := F_P_KIF
	nKArea := F_KIF
endif


Box(, 2, 60)

nCount := 0

SELECT (nPArea)
if RECCOUNT2() == 0
	return 0
endif

nNextGRbr:= next_g_r_br(cTbl)


SELECT (nPArea)
GO TOP

// novi dokument je u pripremi i nema uopste postavljen
// broj dokumenta
if (br_dok == 0)
	nNextBrDok := next_br_dok(cTbl)
	nBrdok := nNextBrDok
else
	nBrDok := br_dok
endif

// azuriraj u sql bazu
if kuf_kif_azur_sql( cTbl, nNextGRbr, nBrDok )
	
	select (nPArea)
	go top

	// azuriraj podatke u dbf
	do while !eof()
	
		Scatter()
	
		// datum azuriranja
		_datum_2 := DATE()
		_g_r_br := nNextGRbr
	
		_br_dok := nBrDok
	
		++nCount
		@ m_x+1, m_y+2 SAY PADR("Dodajem P_KIF -> KUF " + transform(nCount, "9999"), 40)
		@ m_x+2, m_y+2 SAY PADR("   "+ cTbl +" G.R.BR: " + transform(nNextGRbr, "99999"), 40)

		nNextGRbr ++
	
		SELECT (nKArea)
		APPEND BLANK
		Gather()

		select (nPArea)
		SKIP
	enddo

else

	msgbeep("Neuspjesno azuriranje epdv/sql !")
	return 

endif

SELECT (nKArea)
use

@ m_x+1, m_y+2 SAY PADR("Brisem pripremu ...", 40)

// sve je ok brisi pripremu
SELECT (nPArea)
zap
use

if (cTbl == "KUF")
	o_kuf(.t.)
else
	o_kuf(.t.)
endif	

BoxC()

MsgBeep("Azuriran je " + cTbl + " dokument " + STR( _br_dok, 6, 0) )

return _br_dok



// azuriranje kuf, kif tabela u sql
function kuf_kif_azur_sql( tbl, next_g_rbr, next_br_dok )
local lOk := .t.
local record := hb_hash()
local _tbl_epdv
local _i
local _tmp_id
local _ids := {}
local __area

if tbl == "KIF"
	__area := F_P_KIF
elseif tbl == "KUF"
	__area := F_P_KUF
endif

// npr. LOWER( "KUF" )
_tbl_epdv := "epdv_" + LOWER( tbl )

for _i := 1 to SEMAPHORE_LOCK_RETRY_NUM

	// provjeri fakt
	if get_semaphore_status( _tbl_epdv ) == "lock"
		Msgbeep( "tabela zakljucana: " + _tbl_epdv )
		hb_IdleSleep( SEMAPHORE_LOCK_RETRY_IDLE_TIME )
	else
		lock_semaphore( _tbl_epdv, "lock" )
	endif

next

lOk := .t.

if lOk = .t.

  // azuriraj kuf
  MsgO( "sql " + _tbl_epdv )

  select ( __area )
  go top

  if tbl == "KUF"
  		sql_epdv_kuf_update("BEGIN")
  elseif tbl == "KIF"
  		sql_epdv_kif_update("BEGIN")
  endif

  do while !eof()
	  
   record["datum"] := field->datum
   record["datum_2"] := DATE()
   record["src"] := field->src
   record["td_src"] := field->td_src
   record["src_2"] := field->src_2
   record["id_tar"] := field->id_tar
   record["id_part"] := field->id_part
   record["part_idbr"] := field->part_idbr
   record["part_kat"] := field->part_kat
   record["src_td"] := field->src_td
   record["src_br"] := field->src_br
   record["src_veza_b"] := field->src_veza_b
   record["src_br_2"] := field->src_br_2
   record["r_br"] := field->r_br
   record["br_dok"] := next_br_dok
   record["g_r_br"] := next_g_rbr
   record["lock"] := field->lock
   record["kat"] := field->kat
   record["kat_2"] := field->kat_2
   record["opis"] := field->opis
   record["i_b_pdv"] := field->i_b_pdv
   record["i_pdv"] := field->i_pdv
   record["i_v_b_pdv"] := field->i_v_b_pdv
   record["i_v_pdv"] := field->i_v_pdv
   record["status"] := field->status
   record["kat_p"] := field->kat_p
   record["kat_p_2"] := field->kat_p_2

   if tbl == "KIF"
   		record["src_pm"] := field->src_pm
   endif
               
   _tmp_id := PADR( ALLTRIM( STR( record["br_dok"], 6 ) ), 6 ) 
   
   if tbl == "KUF"
   	    if !sql_epdv_kuf_update( "ins", record )
       		lOk := .f.
       		exit
   		endif
   elseif tbl == "KIF"
   	    if !sql_epdv_kif_update( "ins", record )
       		lOk := .f.
       		exit
   		endif
   endif

   skip

  enddo

  MsgC()

endif

if !lOk

	// vrati sve nazad...  	
	if tbl == "KUF"
		sql_epdv_kuf_update("ROLLBACK")
	elseif tbl == "KIF"
		sql_epdv_kif_update("ROLLBACK")
	endif

else
	
	// napravi update-e
	// zavrsi transakcije 
 
	AADD( _ids, _tmp_id )

	update_semaphore_version( _tbl_epdv, .t. )
	push_ids_to_semaphore( _tbl_epdv, _ids ) 
  	
	if tbl == "KUF"
		sql_epdv_kuf_update("END")
	elseif tbl == "KIF"
		sql_epdv_kif_update("END")
	endif

endif

lock_semaphore( _tbl_epdv, "free" )

return lOk



// -------------------------------------------
// povrat kuf/kif dokumenata u pripremu
// -------------------------------------------
function pov_ku_ki(cTbl, nBrDok)


if (cTbl == "KUF")
	o_kuf(.t.)
	// privatno podrucje
	nPArea := F_P_KUF
	
	// kumulativ 
	nKArea := F_KUF
else
	o_kif(.t.)
	nPArea := F_P_KIF
	nKArea := F_KIF
endif



nCount := 0


SELECT (nKArea)
set order to tag "BR_DOK"
seek STR(nBrdok, 6, 0)


if !found()
	SELECT (nPArea)
	return 0
endif

SELECT (nPArea)
if RECCOUNT2()>0
	MsgBeep("U pripremi postoji dokument#ne moze se izvrsiti povrat#operacija prekinuta !")
	return -1
endif


Box(, 2, 60)
SELECT (nKArea)
// dodaj u pripremu dokument
do while !eof() .and. (br_dok == nBrDok)
	
	++nCount
	@ m_x+1, m_y+2 SAY PADR("P_" + cTbl+  " -> " + cTbl + " :" + transform(nCount, "9999"), 40)
	

	SELECT (nKArea)
	// setuj mem vars _
	Scatter()
	
	SELECT (nPArea)
	// dodaj zapis
	APPEND BLANK
	// memvars -> db
	Gather()
	
	// kumulativ tabela
	SELECT (nKArea)
	SKIP	
enddo

// vrati sam dokument, sada mogu  dokument izbrisati iz kumulativa
seek STR(nBrdok, 6, 0)
do while !eof() .and. (br_dok == nBrDok)
	
	SKIP
	// sljedeci zapis
	nTRec := RECNO()
	SKIP -1
	
	++nCount
	@ m_x+1, m_y+2 SAY PADR("Brisem " + cTbl + transform(nCount, "9999"), 40)
	
	DELETE
	// idi na sljedeci
	go nTRec
	
enddo

SELECT (nKArea)
use


if (cTbl == "KUF")
	o_kuf(.t.)
else
	o_kif(.t.)
endif	

BoxC()

MsgBeep("Izvrsen je povrat dokumenta " + STR( nBrDok, 6, 0) + " u pripremu" )

return nBrDok


// --------------------------------------
// renumeracija rednih brojeva - priprema
// --------------------------------------
function renm_rbr(cTbl, lShow)

if lShow == nil
	lShow := .t.
endif

if cTbl == "P_KUF"
	SELECT F_P_KUF
	if !used()
		O_P_KUF
	endif
	
elseif cTbl == "P_KIF"
	SELECT F_P_KIF
	
	SELECT F_P_KIF
	if !used()
		O_P_KIF
	endif
endif

SET ORDER TO TAG "datum"
// "datum" - "dtos(datum)+src_br_2"
GO TOP
nRbr := 1
do while !eof()
	replace r_br with nRbr
	++nRbr
	SKIP
enddo

if lShow
	MsgBeep("Renumeracija izvrsena")
endif

return


// --------------------------------------
// renumeracija rednih brojeva - priprema
// --------------------------------------
function renm_g_rbr(cTbl, lShow)
local nRbr
local nLRbr

if lShow == nil
	lShow := .t.
endif

if cTbl == "KUF"
	SELECT F_KUF
	if !used()
		O_KUF
	endif
	
elseif cTbl == "P_KIF"
	SELECT F_KIF
	
	SELECT F_KIF
	if !used()
		O_KIF
	endif
endif

SET ORDER TO TAG "l_datum"
// "l_datum" - "lock+tos(datum)+src_br_2"

SET SOFTSEEK ON
SEEK "DZ" 
SKIP -1
if lock == "D"
	// postljednji zauzet broj
	nLRbr := g_r_br
else
	nLRbr := 0
endif

PRIVATE cFilter := "!(lock == 'D')"

// iskljuci lockovane slogove 
SET FILTER TO &cFilter
GO TOP

Box(,3, 60)
nRbr:= nLRbr
do while !eof()

 	++nRbr
	@ m_x+1, m_y+2 SAY cTbl + ":" + STR(nRbr, 8, 0)	
	
	replace g_r_br with nRbr
	
	++nRbr
	SKIP
enddo
BoxC()

USE

if lShow
	MsgBeep( cTbl + " : G.Rbr Renumeracija izvrsena")
endif

return

