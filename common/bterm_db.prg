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


#include "fmk.ch"

// -------------------------------------------------------
// Setuj matricu sa poljima tabele dokumenata TERM
// -------------------------------------------------------
static function _sTblTerm(aDbf)

AADD(aDbf,{"barkod",  "C", 13, 0})
AADD(aDbf,{"idroba",  "C", 10, 0})
AADD(aDbf,{"kolicina", "N", 15, 5})
AADD(aDbf,{"status", "N", 2, 0})

// status
// 0 - nema robe u sifrarniku
// 1 - roba je tu

return


// --------------------------------------------------------
// Kreiranje temp tabele, te prenos zapisa iz text fajla 
// "cTextFile" u tabelu 
//  - param cTxtFile - txt fajl za import
// --------------------------------------------------------
function Txt2TTerm( cTxtFile )
local cDelimiter := ";"
local aDbf := {}
local _o_file

cTxtFile := ALLTRIM( cTxtFile )

// prvo kreiraj tabelu temp
close all

// polja tabele TEMP.DBF
_sTblTerm( @aDbf )

// kreiraj tabelu
_creTemp( aDbf, .t. )

O_ROBA
O_TEMP

if !File(f18_ime_dbf("TEMP"))
	MsgBeep("Ne mogu kreirati fajl TEMP.DBF!")
	return
endif

// zatim iscitaj fajl i ubaci podatke u tabelu

_o_file := TFileRead():New( cTxtFile )
_o_file:Open()

if _o_file:Error()
	MsgBeep( _o_file:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
	return
endif

// prodji kroz svaku liniju i insertuj zapise u temp.dbf

while _o_file:MoreToRead()
	
	// uzmi u cText liniju fajla
	cVar := hb_strtoutf8( _o_file:ReadLine() )

	if EMPTY(cVar)
		loop
	endif

	aRow := csvrow2arr( cVar, cDelimiter ) 
	
	// struktura podataka u txt-u je
	// [1] - barkod
	// [2] - kolicina
	
	// pa uzimamo samo sta nam treba
	cTmp := PADR( ALLTRIM( aRow[1] ), 13 )
	nTmp := VAL ( ALLTRIM( aRow[2] ) )
	
	select roba
	set order to tag "BARKOD"
	go top
	seek cTmp

	if FOUND()
		cRoba_id := field->id
		nStatus := 1
	else
		cRoba_id := ""
		nStatus := 0
	endif

	// selektuj temp tabelu
	select temp
	// dodaj novi zapis
	append blank

	replace barkod with cTmp
	replace idroba with cRoba_id
	replace kolicina with nTmp
	replace status with nStatus

enddo

_o_file:Close()

select temp

MsgBeep("Import txt => temp - OK")

return


// ----------------------------------------------------------------
// Kreira tabelu PRIVPATH\TEMP.DBF prema definiciji polja iz aDbf
// ----------------------------------------------------------------
static function _creTemp( aDbf, lIndex )

cTmpTbl := "TEMP"

if lIndex == nil
	lIndex := .t.
endif

if File( f18_ime_dbf( cTmpTbl ) ) .and. ( FErase( f18_ime_dbf( cTmpTbl ) ) == -1 )
		MsgBeep("Ne mogu izbrisati TEMP.DBF!")
    	ShowFError()
endif

DbCreate2(cTmpTbl, aDbf)

if lIndex 
	create_index("1","barkod", cTmpTbl )
	create_index("2","idroba", cTmpTbl )
	create_index("3","STR(status)", cTmpTbl )
endif

return



