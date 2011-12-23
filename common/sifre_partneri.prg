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

function cre_partn()
local aDbf := {}

AADD(aDBf, { 'ID'                  , 'C' ,   6 ,  0 })
add_f_mcode(@aDbf)
AADD(aDBf, { 'NAZ'                 , 'C' , 250 ,  0 })
AADD(aDBf, { 'NAZ2'                , 'C' ,  25 ,  0 })
AADD(aDBf, { '_KUP'                , 'C' ,   1 ,  0 })
AADD(aDBf, { '_DOB'                , 'C' ,   1 ,  0 })
AADD(aDBf, { '_BANKA'              , 'C' ,   1 ,  0 })
AADD(aDBf, { '_RADNIK'             , 'C' ,   1 ,  0 })
AADD(aDBf, { 'PTT'                 , 'C' ,   5 ,  0 })
AADD(aDBf, { 'MJESTO'              , 'C' ,  16 ,  0 })
AADD(aDBf, { 'ADRESA'              , 'C' ,  24 ,  0 })
AADD(aDBf, { 'ZIROR'               , 'C' ,  22 ,  0 })
AADD(aDBf, { 'DZIROR'              , 'C' ,  22 ,  0 })
AADD(aDBf, { 'TELEFON'             , 'C' ,  12 ,  0 })
AADD(aDBf, { 'FAX'                 , 'C' ,  12 ,  0 })
AADD(aDBf, { 'MOBTEL'              , 'C' ,  20 ,  0 })

if !file(f18_ime_dbf("partn"))
    dbcreate2('partn', aDbf)
    reset_semaphore_version("partn")
    my_use("partn")
	close all 
endif

if !file(f18_ime_dbf("_partn"))
        dbcreate2('_partn', aDbf)
endif
CREATE_INDEX("ID", "id", "partn")
CREATE_INDEX("NAZ", "NAZ", "partn")

CREATE_INDEX("ID", "id", "_partn")

index_mcode("", "partn")

set_sifk_partn_bank()

return .t.


// ---------------------------------
// ---------------------------------
function p_partneri(cId, dx, dy)
local cN2Fin
local i
local cRet

PushWa()

PRIVATE ImeKol
PRIVATE Kol

SELECT (F_PARTN)

if !used()
	O_PARTN
else
   SET ORDER TO TAG "ID"
endif

ImeKol:={}

AADD(ImeKol, { PADR("ID", 6),   {|| id },  "id" , {|| .t.}, {|| vpsifra(wid)}    })
AADD(ImeKol, { PADR("Naziv", 35),  {|| padr(naz, 35) },  "naz"} )

cN2Fin := IzFMkIni('FIN', 'PartnerNaziv2','N')

if cN2Fin=="D"
 AADD(ImeKol, { PADR("Naziv2", 25), {|| naz2},     "naz2"      } )
endif

AADD(ImeKol, { PADR("PTT", 5),      {|| PTT},     "ptt"      } )
AADD(ImeKol, { PADR("Mjesto", 16),  {|| MJESTO},  "mjesto"   } )
AADD(ImeKol, { PADR("Adresa", 24),  {|| ADRESA},  "adresa"   } )

AADD(ImeKol, { PADR("Ziro R ", 22), {|| ZIROR},   "ziror"  , {|| .t.},{|| .t. }  } )

Kol:={}

if IzFMkIni('SifPartn','DZIROR','N')=="D"
 if partn->(fieldpos("DZIROR")) <> 0
   AADD (ImeKol,{ padr("Dev ZR", 22 ), {|| DZIROR}, "Dziror" })
 endif
endif


if IzFMKINI('SifPartn','Telefon','D')=="D"
 AADD(Imekol,{ PADR("Telefon",12),  {|| TELEFON}, "telefon"  } )
endif

if IzFMKINI('SifPartn','Fax','D')=="D"
if partn->(fieldpos("FAX"))<>0
  AADD (ImeKol,{ padr("Fax",12 ), {|| fax}, "fax" })
endif
endif

if IzFMKINI('SifPartn','MOBTEL','D')=="D"
if partn->(fieldpos("MOBTEL")) <> 0
  AADD (ImeKol,{ padr("MobTel", 20 ), {|| mobtel}, "mobtel" })
endif
endif

if partn->(fieldpos("ID2")) <> 0
  AADD (ImeKol,{ padr("Id2", 6 ), {|| id2}, "id2" })
endif

if partn->(fieldpos("IdOps")) <> 0
  AADD (ImeKol,{ padr("Opstina", 6 ), {|| idOps}, "idOps" })
endif


if partn->(fieldpos("_kup")) <> 0
	
	AADD(ImeKol, { "kup?", {|| _kup }, "_kup", ;
		{|| .t.}, {|| _v_dn( w_kup ) }})

	AADD(ImeKol, { "dob?", {|| " " + _dob + " " }, "_dob", ;
		{|| .t.}, {|| _v_dn( w_dob ) }, nil, nil, nil, nil, 20 } )

	AADD(ImeKol, { "banka?", {|| " " + _banka + " " }, "_banka", ;
		{|| .t.}, {|| _v_dn( w_banka ) }, nil, nil, nil, nil, 30 } )

	AADD(ImeKol, { "radnik?", {|| " " + _radnik + " " }, "_radnik", ;
		{|| .t.}, {|| _v_dn( w_radnik ) }, nil, nil, nil, nil, 40 } )

endif


FOR i := 1 TO LEN(ImeKol)
	AADD(Kol, i)
NEXT

select (F_SIFK)
if !used()
    O_SIFK
endif

select (F_SIFV)
if !useD()
    O_SIFV
endif

select sifk
set order to tag "ID"
seek "PARTN"

do while !eof() .and. ID="PARTN"

 AADD (ImeKol, {  IzSifKNaz("PARTN", SIFK->Oznaka) })
 AADD (ImeKol[Len(ImeKol)], &( "{|| ToStr(IzSifk('PARTN','" + sifk->oznaka + "')) }" ) )
 AADD (ImeKol[Len(ImeKol)], "SIFK->" + SIFK->Oznaka )

 if sifk->edkolona > 0
   for ii:=4 to 9
      AADD( ImeKol[Len(ImeKol)], NIL  )
   next
   AADD( ImeKol[Len(ImeKol)], sifk->edkolona  )
 else
   for ii:=4 to 10
      AADD( ImeKol[Len(ImeKol)], NIL  )
   next
 endif

 // postavi picture za brojeve
 if sifk->Tip == "N"
   if f_decimal > 0
     ImeKol [Len(ImeKol),7] := replicate("9", sifk->duzina - sifk->f_decimal-1 )+"."+replicate("9",sifk->f_decimal)
   else
     ImeKol [Len(ImeKol),7] := replicate("9", sifk->duzina )
   endif
 endif

 AADD  (Kol, iif( sifk->UBrowsu='1', ++i, 0) )

 skip
enddo

cRet := PostojiSifra(F_PARTN, 1, maxrows() - 15, maxcols() - 15, "Lista Partnera", @cId, dx, dy, {|Ch| k_handler(Ch)},,,,, {"ID"})

PopWa()

return cRet

// ---------------------------------- 
// ---------------------------------- 
static function k_handler(Ch)
LOCAL cSif:=PARTN->id, cSif2:=""

if Ch==K_CTRL_T .and. gSKSif=="D"

   // provjerimo da li je sifra dupla
   PushWA()
   SET ORDER TO TAG "ID"
   SEEK cSif
   SKIP 1
   cSif2 := PARTN->id
   PopWA()

endif

RETURN DE_CONT

// ----------------------------------------------
// ----------------------------------------------
function P_Firma(cId, dx, dy)

return P_Partneri(@cId, @dx, @dy)


// -------------------------------------
// validacija polja P_TIP
// -------------------------------------
static function _v_dn( cDn )
local lRet := .f.

if UPPER(cDN) $ " DN"
	lRet := .t.
endif

if lRet == .f.
	msgbeep("Unjeti D ili N")
endif

return lRet


// --------------------------------------------------------
// funkcija vraca .t. ako je definisana grupa partnera
// --------------------------------------------------------
function p_group()
local lRet:=.f.

O_SIFK
select sifk
set order to tag "ID"
go top
seek "PARTN"
do while !eof() .and. ID="PARTN"
	if field->oznaka == "GRUP"
		lRet := .t.
		exit
	endif
	skip
enddo
return lRet



// -----------------------------------
// -----------------------------------
function p_set_group(set_field)
private Opc:={}
private opcexe:={}
private Izbor

AADD(Opc, "VP  - veleprodaja          ")
AADD(opcexe, {|| set_field := "VP ", Izbor := 0 } )
AADD(Opc, "AMB - ambulantna dostava  ")
AADD(opcexe, {|| set_field := "AMB", Izbor := 0 } )
AADD(Opc, "SIS - sistemska kuca      ")
AADD(opcexe, {|| set_field := "SIS", Izbor := 0 } )
AADD(Opc, "OST - ostali      ")
AADD(opcexe, {|| set_field := "OST", Izbor := 0 } )

Izbor:=1
Menu_Sc("pgr")

m_x := 1
m_y := 5

return .t.
*}

// vraca opis grupe
function gr_opis(cGroup)
local cRet
do case
	case cGroup == "AMB"
		cRet := "ambulantna dostava"
	case cGroup == "SIS"
		cRet := "sistemska obrada"
	case cGroup == "VP "
	 	cRet := "veleprodaja"
	case cGroup == "OST"
		cRet := "ostali"
	otherwise
		cRet := ""
endcase

return cRet


// -----------------------------------
// -----------------------------------
function p_gr(xVal, nX, nY)
local cRet := ""
local cPrn := ""

cRet := gr_opis(xVal)
cPrn := SPACE(2) + "-" + SPACE(1) + cRet

@ nX, nY+25 SAY SPACE(40)
@ nX, nY+25 SAY cPrn

return .t.


// da li partner 'cPartn' pripada grupi 'cGroup'
function p_in_group(cPartn, cGroup)
local cSifKVal
cSifKVal := IzSifK("PARTN", "GRUP", cPartn, .f.)

if cSifKVal == cGroup
	return .t.
endif

return .f.

// -----------------------------
// get partner fax
// -----------------------------
function g_part_fax(cIdPartner)
local cFax

PushWa()

SELECT F_PARTN
if !used()
	O_PARTN
endif
SEEK cIdPartner
if !found()
 cFax := "!NOFAX!"
else
 cFax := fax
endif

PopWa()

return cFax

// -----------------------------
// get partner naziv + mjesto
// -----------------------------
function g_part_name(cIdPartner)
local cRet

PushWa()

SELECT F_PARTN
if !used()
	O_PARTN
endif
SEEK cIdPartner
if !found()
 cRet := "!NOPARTN!"
else
 cRet := TRIM(LEFT(naz,25)) + " " + TRIM(mjesto)
endif

PopWa()

return cRet


// ------------------------------------
// da li je partner kupac ???
// ------------------------------------
function is_kupac( cId )
local cFld := "_KUP"

if _ck_status( cId, cFld ) 
	return .t.
endif

return .f.

// ------------------------------------
// da li je partner dobavljac ???
// ------------------------------------
function is_dobavljac( cId )
local cFld := "_DOB"

if _ck_status( cId, cFld ) 
	return .t.
endif

return .f.

// ------------------------------------
// da li je partner banka ???
// ------------------------------------
function is_banka( cId )
local cFld := "_BANKA"

if _ck_status( cId, cFld ) 
	return .t.
endif

return .f.


// ------------------------------------
// da li je partner radnik ???
// ------------------------------------
function is_radnik( cId )
local cFld := "_RADNIK"

if _ck_status( cId, cFld ) 
	return .t.
endif

return .f.


// --------------------------------------------
// provjerava status polja cFld
// --------------------------------------------
static function _ck_status( cId, cFld )
local lRet := .f.
local nSelect := SELECT()

O_PARTN
select partn
seek cId

if partn->(FIELDPOS(cFld)) <> 0
	if &cFld $ "Dd"
		lRet := .t.
	endif
else
	lRet := .t.
endif

select (nSelect)

return lRet


// ----------------------------
// ----------------------------
function set_sifk_partn_bank()
local lFound
local cSeek
local cNaz
local cId


SELECT (F_SIFK)

if !used()
	O_SIFK
endif

SET ORDER TO TAG "ID"
// id + SORT + naz

cId := PADR("PARTN", SIFK_LEN_DBF) 
cNaz := PADR("Banke", LEN(naz))
cSeek :=  cId + "05" + cNaz

SEEK cSeek   

if !FOUND()
    APPEND BLANK
    _rec := dbf_get_rec()
    _rec["id"] := cId
    _rec["naz"] := cNaz
    _rec["oznaka"] := "BANK"
    _rec["sort"] := "05"
    _rec["tip"] := "C"
    _rec["duzina"] := 16
    _rec["veza"] := "N"

    if !update_rec_server_and_dbf("sifk", _rec) 
        delete_with_rlock()
    endif
endif

return .t.
