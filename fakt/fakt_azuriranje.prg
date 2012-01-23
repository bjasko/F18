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

#include "fakt.ch"

function o_fakt_edit(cVar2)

if glRadNal
    select F_RNAL
    if !used()
        O_RNAL
    endif
endif

if glDistrib = .t.
    select F_RELAC
    if !used()
        O_RELAC
        O_VOZILA
        O_KALPOS
    endif
endif

select F_VRSTEP
if !used()
    O_VRSTEP
endif

select F_OPS
if !used()
    O_OPS
endif

select F_KONTO
if !used()
    O_KONTO
endif

select F_SAST
if !used()
    O_SAST
endif

select F_PARTN
if !used()
    O_PARTN
endif

select F_ROBA
if !used()
    O_ROBA
endif

if (PCount()==0)
    select F_PRIPR
    if !used()
        O_FAKT_S_PRIPR
    endif
    select F_FAKT
    if !used()
        O_FAKT
    endif
else
    select F_FAKT
    if !used()
        O_PFAKT
    endif
endif

select F_FTXT
if !used()
    O_FTXT
endif

select F_TARIFA
if !used()
    O_TARIFA
endif

select F_VALUTE
if !used()
    O_VALUTE
endif

select F_FAKT_DOKS2
if !used()
    O_FAKT_DOKS2
endif

select F_FAKT_DOKS
if !used()
    O_FAKT_DOKS
endif

select F_RJ
if !used()
    O_RJ
endif

select F_SIFK
if !used()
    O_SIFK
endif

select F_SIFV
if !used()
    O_SIFV
endif

select fakt_pripr
set order to tag "1"
go top

return nil



/*! \fn SpojiDuple()
 *  \brief Spajanje duplih artikala unutar jednog dokumenta
 */

function SpojiDuple()
local cIdRoba
local nCnt 
local nKolicina
local cSpojiti 
local nTrec

select fakt_pripr

cSpojiti:="N"

if gOcitBarkod
    set order to tag "3"
    go top
    do while !eof()
            nCnt:=0
            cIdRoba:=idroba
            nKolicina:=0
            do while !eof() .and. idroba==cIdRoba
                nKolicina+=kolicina
                nCnt++
                skip
            enddo
            
        if (nCnt>1) // imamo duple!!!
                if cSpojiti=="N"
                    if Pitanje(,"Spojiti duple artikle ?","N")=="D"
                            cSpojiti:="D"
                    else
                            cSpojiti:="0"
                    endif
                endif
                
            if cSpojiti=="D"
                    seek _idfirma + cIdRoba // idi na prvu stavku
                    replace kolicina with nKolicina
                    skip
                    do while !eof() .and. idroba==cIdRoba
                        replace kolicina with 0  
                    // ostale stavke imaju kolicinu 0
                        skip
                    enddo
                endif

            endif
    enddo
endif

if cSpojiti="D"
    select fakt_pripr
    go top
    do while !eof()
            skip
            nTrec:=RecNo()
            skip -1
            
        // markirano za brisanje
        if (field->kolicina=0)  
                delete
            endif
            go nTrec
    enddo
endif

select fakt_pripr
set order to tag "1"
go top

return


/*! \fn SrediRbrFakt()
 *  \brief Sredi redni broj
 */
function SrediRbrFakt()
local nRbr:=0
local nRbrStari:=0
local cPom:=0
local cDok:=""

O_FAKT_S_PRIPR
GO TOP

cDok:=idfirma+idtipdok+brdok

do while !eof()
    Scatter()
    cPom:=_rbr
    if (cDok != _idfirma+_idtipdok+_brdok)
        nRbrStari:=0
        nRbr:=0
    endif
    if nRbrStari==RbrUnum(_rbr)
        _rbr:=RedniBroj(nRbr)
    else
        ++nRbr
        _rbr:=RedniBroj(nRbr)
    endif
        
    Gather()
        
    nRbrStari:=RbrUnum(cPom)
    cDok:=idfirma+idtipdok+brdok
    skip 1
enddo

//close all

return 0


// -------------------------------------------------------------------
// azuriranje u dbf tabele
// -------------------------------------------------------------------
static function fakt_azur_dbf( id_firma, id_tip_dok, br_dok, lSilent )
local _a_memo
local _fakt_totals
local _fakt_doks_data
local _fakt_doks2_data

select fakt_pripr
go top
seek id_firma + id_tip_dok + br_dok

Box("#Proces azuriranja u toku",3,60)

// azuriramo prvo u tabelu FAKT 
do while !EOF() .and. field->idfirma == id_firma ;
        .and. field->idtipdok == id_tip_dok ;
        .and. field->brdok == br_dok

    select fakt_pripr
    
    Scatter()

    select fakt
    AppBlank2( .f., .f. )   
      
    Gather2()

    select fakt_pripr
    skip

enddo

// to je bilo jednostavno ! idemo sada na tabelu fakt_doks
select fakt_pripr
go top
seek id_firma + id_tip_dok + br_dok

// dodaj zapis u fakt_doks
select fakt_doks
set order to tag "1"
hseek fakt_pripr->idfirma + fakt_pripr->idtipdok + fakt_pripr->brdok
if !Found()
    AppBlank2(.f.,.f.)
endif

// dodaj zapis i u fakt_doks2   
select fakt_doks2
set order to tag "1"
hseek fakt_pripr->idfirma + fakt_pripr->idtipdok + fakt_pripr->brdok
if !Found()
    AppBlank2( .f., .f. )
endif

// daj mi podatke za tabelu fakt_doks   
_fakt_doks_data := get_fakt_doks_data( fakt_pripr->idfirma, fakt_pripr->idtipdok, fakt_pripr->brdok )

// ubaci podatke u tabelu fakt_doks
select fakt_doks
    
_field->IdFirma   := _fakt_doks_data["id_firma"]
_field->BrDok     := _fakt_doks_data["br_dok"]
_field->Rezerv    := _fakt_doks_data["rezerv"]
_field->DatDok    := _fakt_doks_data["dat_dok"]
_field->IdTipDok  := _fakt_doks_data["id_tip_dok"]
_field->Partner   := _fakt_doks_data["partner"]
_field->dindem    := _fakt_doks_data["din_dem"]
_field->IdPartner := _fakt_doks_data["id_partner"]
_field->idpm      := _fakt_doks_data["id_pm"]
_field->IdVrsteP  := _fakt_doks_data["id_vrste_p"]
_field->dok_veza  := _fakt_doks_data["dok_veza"]
_field->oper_id   := _fakt_doks_data["oper_id"]
_field->fisc_rn   := _fakt_doks_data["fisc_rn"]
_field->dat_isp   := _fakt_doks_data["dat_isp"]
_field->dat_otpr  := _fakt_doks_data["dat_otpr"]
_field->dat_val   := _fakt_doks_data["dat_val"]
_field->DatPl     := _fakt_doks_data["dat_val"]
    
if ( fakt_doks->m1 == "Z" )
    // skidam zauzece i dobijam normalan dokument
    // REPLACE m1 WITH " " -- isto kao i gore
    _field->m1 := " "
endif

// izracunaj totale za fakturu
_fakt_totals := calculate_fakt_total( fakt_pripr->idfirma, fakt_pripr->idtipdok, fakt_pripr->brdok )
    
select fakt_doks
// ubaci u fakt_doks totale
_field->Iznos := _fakt_totals["iznos"] 
_field->Rabat := _fakt_totals["rabat"]

// dodaj stavke i u fakt_doks2      
_fakt_doks2_data := get_fakt_doks2_data( fakt_pripr->idfirma, fakt_pripr->idtipdok, fakt_pripr->brdok )

select fakt_doks2

_field->idfirma := _fakt_doks2_data["id_firma"]
_field->brdok := _fakt_doks2_data["br_dok"]
_field->idtipdok := _fakt_doks2_data["id_tip_dok"]
_field->k1 := _fakt_doks2_data["k1"]
_field->k2 := _fakt_doks2_data["k2"]
_field->k3 := _fakt_doks2_data["k3"]
_field->k4 := _fakt_doks2_data["k4"]
_field->k5 := _fakt_doks2_data["k5"]
_field->n1 := _fakt_doks2_data["n1"]
_field->n2 := _fakt_doks2_data["n2"]
    
if Logirati(goModul:oDataBase:cName,"DOK","AZUR")
    EventLog(nUser, goModul:oDataBase:cName, "DOK", "AZUR", nil,nil,nil,nil,"","","dokument: " + fakt_pripr->idfirma + ;
            "-" + fakt_pripr->idtipdok + "-" + fakt_pripr->brdok, fakt_pripr->datdok, Date(),"","Azuriranje dokumenta")
endif
    
select fakt_pripr

BoxC()

return .t.

static function _fakt_partner_memo( a_memo )
local _return := ""
    
// priprema podatke za upis u polje "doks->partner"

if LEN( a_memo ) >= 5
    _return := TRIM( a_memo[3] ) + " " + TRIM( a_memo[4] ) + "," + TRIM( a_memo[5] )
endif

_return := PADR( _return, FAKT_DOKS_PARTNER_LENGTH )
    
return _return



// vraca hash matricu za fakt_doks2
function get_fakt_doks2_data( id_firma, id_tip_dok, br_dok )
local _fakt_data := hb_hash()
local _memo 

select fakt_pripr
go top
seek id_firma + id_tip_dok + br_dok

_fakt_data["id_firma"] := field->idfirma
_fakt_data["br_dok"] := field->brdok
_fakt_data["id_tip_dok"] := field->idtipdok

_memo := ParsMemo( field->txt )
    
_fakt_data["k1"] := if( LEN( _memo ) >= 11, _memo[11], "" )
_fakt_data["k2"] := if( LEN( _memo ) >= 12, _memo[12], "" )
_fakt_data["k3"] := if( LEN( _memo ) >= 13, _memo[13], "" )
_fakt_data["k4"] := if( LEN( _memo ) >= 14, _memo[14], "" )
_fakt_data["k5"] := if( LEN( _memo ) >= 15, _memo[15], "" )
_fakt_data["n1"] := if( LEN( _memo ) >= 16, VAL( ALLTRIM( _memo[16] ) ), 0 )
_fakt_data["n2"] := if( LEN( _memo ) >= 17, VAL( ALLTRIM( _memo[17] ) ), 0 )

return _fakt_data





function get_fakt_doks_data( id_firma, id_tip_dok, br_dok )
local _fakt_data := hb_hash()
local _memo 

select fakt_pripr
go top
seek id_firma + id_tip_dok + br_dok

_fakt_data["id_firma"] := field->idfirma
_fakt_data["br_dok"] := field->brdok
_fakt_data["id_tip_dok"] := field->idtipdok
_fakt_data["dat_dok"] := field->datdok

_memo := ParsMemo( field->txt )
    
_fakt_data["din_dem"] := field->dindem
    
if ( field->idtipdok $ "10#20#27" .and. field->serbr = "*" )
    _fakt_data["rezerv"] := "*"
else
    _fakt_data["rezerv"] := " "
endif

_fakt_data["partner"] := _fakt_partner_memo( _memo )
_fakt_data["id_partner"] := field->idpartner
_fakt_data["id_pm"] := field->idpm
    
_fakt_data["dok_veza"] := field->dok_veza
_fakt_data["oper_id"] := getUserId()

_fakt_data["fisc_rn"] := field->fisc_rn

_fakt_data["dat_isp"] := if( LEN( _memo ) >= 7, CToD( _memo[7] ), CToD("") )
_fakt_data["dat_otpr"] := if( LEN( _memo ) >= 7, CToD( _memo[7] ), CToD("") )
_fakt_data["dat_val"] := if( LEN( _memo ) >= 9, CToD( _memo[9] ), CToD("") )

_fakt_data["id_vrste_p"] := field->idvrstep

return _fakt_data



// ----------------------------------------------------------
// kalkulise ukupno za fakturu
// ----------------------------------------------------------
function calculate_fakt_total( id_firma, id_tipdok, br_dok )
local _fakt_total := hb_hash()
local _cij_sa_por := 0
local _rabat := 0
local _uk_sa_rab := 0
local _uk_rabat := 0 
local _dod_por := 0
local _din_dem

select fakt_pripr
go top
seek id_firma + id_tipdok + br_dok
    
_din_dem := field->dindem

do while !eof() .and. field->idfirma == id_firma ;
            .and. field->idtipdok == id_tipdok ;
            .and. field->brdok == br_dok
        
    if _din_dem == LEFT( ValBazna(), 3 )
        
        _cij_sa_por := ROUND( field->kolicina * field->cijena * ;
                        PrerCij() * ( 1 - field->rabat / 100), ZAOKRUZENJE )
        
        _rabat := ROUND( field->kolicina * field->cijena * ;
                    PrerCij() * field->rabat / 100 , ZAOKRUZENJE )
        
        _dod_por := ROUND( _cij_sa_por * field->porez / 100, ZAOKRUZENJE )
        
    else
        
        _cij_sa_por := ROUND( field->kolicina * field->cijena * ;
                        PrerCij() / UBaznuValutu(field->datdok) * ;
                        ( 1 - field->Rabat / 100), ZAOKRUZENJE ) 
        
        _rabat := ROUND( field->kolicina * field->cijena * ;
                        PrerCij() / UBaznuValutu( field->datdok ) * ;
                        field->rabat / 100 , ZAOKRUZENJE )
        
        _dod_por := ROUND( _cij_sa_por * field->porez / 100, ZAOKRUZENJE )
        
    endif
        
    _uk_sa_rab += _cij_sa_por + _dod_por
    _uk_rabat += _rabat

    skip

enddo

_fakt_total["iznos"] := _uk_sa_rab
_fakt_total["rabat"] := _uk_rabat
 
return _fakt_total




// --------------------------------------------------------------
// azuriranje u sql tabele
// --------------------------------------------------------------
static function fakt_azur_sql( id_firma, id_tip_dok, br_dok )
local lOk
local record := hb_hash()
local _tbl_fakt
local _tbl_doks
local _tbl_doks2
local _i
local _tmp_id
local _ids := {}
local _fakt_doks_data
local _fakt_doks2_data
local _fakt_totals

_tbl_fakt := "fakt_fakt"
_tbl_doks := "fakt_doks"
_tbl_doks2 := "fakt_doks2"

lock_semaphore( _tbl_fakt, "lock" )
lock_semaphore( _tbl_doks, "lock" )
lock_semaphore( _tbl_doks2, "lock" )

lOk := .t.

if lOk = .t.

  // azuriraj fakt
  MsgO("sql fakt_fakt")

  select fakt_pripr
  go top
  seek id_firma + id_tip_dok + br_dok

  sql_fakt_fakt_update("BEGIN")

  do while !eof() .and. field->idfirma == id_firma ;
                    .and. field->idtipdok == id_tip_dok ;
                    .and. field->brdok == br_dok
 
   record["id_firma"] := field->idfirma
   record["id_tip_dok"] := field->idtipdok
   record["br_dok"] := field->brdok
   record["r_br"] := VAL(field->Rbr)
   record["dat_dok"] := field->datdok
   record["id_partner"] := field->idpartner
   record["din_dem"] := field->dindem
   record["zaokr"] := field->zaokr
   record["pod_br"] := VAL( field->podbr )
   record["id_roba"] := field->idroba
   record["ser_br"] := field->serbr
   record["kolicina"] := field->kolicina
   record["cijena"] := field->cijena
   record["rabat"] := field->rabat
   record["porez"] := field->porez
   record["txt"] := field->txt
   record["k1"] := field->k1
   record["k2"] := field->k2
   record["m1"] := field->m1
   record["id_vrste_p"] := field->idvrstep
   record["id_pm"] := field->idpm
   record["c1"] := field->c1
   record["c2"] := field->c2
   record["c3"] := field->c3
   record["n1"] := field->n1
   record["n2"] := field->n2
   record["opis"] := field->opis
   record["dok_veza"] := field->dok_veza
               
   _tmp_id := record["id_firma"] + record["id_tip_dok"] + ALLTRIM( record["br_dok"] )
   
   if !sql_fakt_fakt_update( "ins", record )
       lOk := .f.
       exit
   endif
    
   skip

  enddo

  MsgC()

endif


if lOk = .t.
 
   // azuriraj doks...
  MsgO("sql fakt_doks")

  // izracunaj totale za fakturu
  _fakt_totals := calculate_fakt_total( id_firma, id_tip_dok, br_dok )
  // daj mi podatke za tabelu doks  
  _fakt_doks_data := get_fakt_doks_data( id_firma, id_tip_dok, br_dok )
  
  record := hb_hash()

  sql_fakt_doks_update("BEGIN")

  record["id_firma"] := _fakt_doks_data["id_firma"]
  record["id_tip_dok"] := _fakt_doks_data["id_tip_dok"]
  record["br_dok"] := _fakt_doks_data["br_dok"]
  record["dat_dok"] := _fakt_doks_data["dat_dok"]
  record["partner"] := _fakt_doks_data["partner"]
  record["id_partner"] := _fakt_doks_data["id_partner"]
  record["din_dem"] := _fakt_doks_data["din_dem"]

  record["iznos"] := _fakt_totals["iznos"]
  record["rabat"] := _fakt_totals["rabat"]

  record["rezerv"] := _fakt_doks_data["rezerv"]
  record["m1"] := " "
  record["id_vrste_p"] := _fakt_doks_data["id_vrste_p"]
  record["dat_pl"] := _fakt_doks_data["dat_val"]
  record["id_pm"] := _fakt_doks_data["id_pm"]
  record["dok_veza"] := _fakt_doks_data["dok_veza"]
  record["oper_id"] := _fakt_doks_data["oper_id"]
  record["fisc_rn"] := _fakt_doks_data["fisc_rn"]
  record["dat_isp"] := _fakt_doks_data["dat_isp"]
  record["dat_otpr"] := _fakt_doks_data["dat_otpr"]
  record["dat_val"] := _fakt_doks_data["dat_val"]
 
  if !sql_fakt_doks_update( "ins", record )
       lOk := .f.
  endif
   
  MsgC()

endif


if lOk = .t.
 
  // azuriraj doks2...
  MsgO("sql fakt_doks2")

  // daj mi podatke za fakt_doks2
  _fakt_doks2_data := get_fakt_doks2_data( id_firma, id_tip_dok, br_dok )
  
  record := hb_hash()

  sql_fakt_doks2_update("BEGIN")

  record["id_firma"] := _fakt_doks2_data["id_firma"]
  record["id_tip_dok"] := _fakt_doks2_data["id_tip_dok"]
  record["br_dok"] := _fakt_doks2_data["br_dok"]
  record["k1"] := _fakt_doks2_data["k1"]
  record["k2"] := _fakt_doks2_data["k2"]
  record["k3"] := _fakt_doks2_data["k3"]
  record["k4"] := _fakt_doks2_data["k4"]
  record["k5"] := _fakt_doks2_data["k5"]
  record["n1"] := _fakt_doks2_data["n1"]
  record["n2"] := _fakt_doks2_data["n2"]

  if !sql_fakt_doks2_update( "ins", record )
       lOk := .f.
  endif
   
  MsgC()

endif

if !lOk

    // vrati sve nazad...   
    sql_fakt_fakt_update("ROLLBACK")
    sql_fakt_doks_update("ROLLBACK")
    sql_fakt_doks2_update("ROLLBACK")
    
else
    
    // napravi update-e
    // zavrsi transakcije 
 
    AADD( _ids, _tmp_id )

    update_semaphore_version( _tbl_doks, .t. )
    push_ids_to_semaphore( _tbl_doks, _ids ) 
    sql_fakt_doks_update("END")
    
    update_semaphore_version( _tbl_doks2, .t. )
    push_ids_to_semaphore( _tbl_doks2, _ids ) 
    sql_fakt_doks2_update("END")
    
    update_semaphore_version( _tbl_fakt, .t. )
    push_ids_to_semaphore( _tbl_fakt, _ids ) 
    sql_fakt_fakt_update("END")

endif

lock_semaphore( _tbl_fakt, "free" )
lock_semaphore( _tbl_doks, "free" )
lock_semaphore( _tbl_doks2, "free" )

return lOk



// -----------------------------------------------------------
// pravi fakt, protudokumente
// -----------------------------------------------------------
static function fakt_protu_dokumenti( cPrj )
local lVecPostoji := .f.
local cKontrol2Broj
local lProtu := .f.

if ( gProtu13 == "D" .and. ;
    fakt_pripr->idtipdok == "13" .and. ;
    Pitanje(,"Napraviti protu-dokument zaduzenja prodavnice","D")=="D")
    
    if (gVar13 == "2" .and. gVarNum == "1")
        cPRj := RJIzKonta(fakt_pripr->idpartner + " ")
    else
        O_RJ
        Box(,2,50)
            cPRj:=IzFMKIni("FAKT","ProtuDokument13kiIdeNaRJ","P1",KUMPATH)
            @ m_x+1,m_y+2 SAY "RJ - objekat:" GET cPRj valid P_RJ(@cPRJ) pict "@!"
            read
        BoxC()
        select rj
        use
    endif
        
    lVecPostoji := .f.
    // prvo da provjerimo ima li isti broj dokumenta u DOKS
    cKontrol2Broj := fakt_pripr->(cPRJ+"01"+TRIM(brdok)+"/13")
    select fakt_doks
    seek cKontrol2Broj
        
    if Found()
        lVecPostoji:=.t.
    else
        // ako nema u DOKS, 
        // provjerimo ima li isti broj dokumenta u FAKT
        select fakt
        seek cKontrol2Broj
        if Found()
            lVecPostoji:=.t.
        endif
    endif
        
    if lVecPostoji
        Msg("Vec postoji dokument pod brojem "+fakt_pripr->(cPRJ+"-01-"+TRIM(brdok)+"/13"),4)
        close all
        return .f.
    endif

    lProtu := .t.

endif

return lProtu




// --------------------------------------------------
// centralna funkcija za azuriranje fakture
// --------------------------------------------------
function azur_fakt( lSilent )
local _a_fakt_doks
local __id_firma
local __br_dok
local __id_tip_dok

if ( lSilent == nil)
    lSilent := .f.
endif

if ( !lSilent .and. Pitanje( ,"Sigurno zelite izvrsiti azuriranje (D/N) ?", "N" ) == "N" )
    return
endif

o_fakt_edit()

select fakt_pripr
use
O_FAKT_PRIPR

// ubaci mi matricu sve dokumente iz pripreme
_a_fakt_doks := _fakt_dokumenti()

// generisi protu dokumente
// ovo jos treba vidjeti koristi li se ??????????
//lProtuDokumenti := fakt_protu_dokumenti( @cPrj )

msgo("Azuriranje dokumenata u toku ...")

// prodji kroz matricu sa dokumentima i azuriraj ih
for _i := 1 to LEN( _a_fakt_doks )

    __id_firma := _a_fakt_doks[ _i, 1 ]
    __id_tip_dok := _a_fakt_doks[ _i, 2 ]
    __br_dok := _a_fakt_doks[ _i, 3 ]
    
    if fakt_azur_sql( __id_firma, __id_tip_dok, __br_dok  )
    
        if !fakt_azur_dbf( __id_firma, __id_tip_dok, __br_dok )
            msgc()
            MsgBeep("Neuspjesno FAKT/DBF azuriranje !?")
            return
        endif

    else
        msgc()
        MsgBeep("Neuspjesno FAKT/SQL azuriranje !?")
        return
    endif

next

msgc()

// prenos podataka fakt
fakt_prenos_modem()

select fakt_pripr

msgo("brisem pripremu....")

// provjeri sta treba pobrisati iz pripreme
if LEN( _a_fakt_doks ) > 1
    fakt_izbrisi_azurirane( _a_fakt_doks )
else
    
    // izbrisi pripremu
    ZAP
    __dbpack()

endif

msgc()
    
close all

return _a_fakt_doks

// vise dokumenata u pripremi
static function _fakt_dokumenti()
local _fakt_doks := {}
local _id_firma
local _id_tip_dok
local _br_dok

select fakt_pripr
go top

do while !EOF()
    
    _id_firma := field->idfirma
    _id_tip_dok := field->idtipdok
    _br_dok := field->brdok
    
    do while !EOF() .and. ( field->idfirma + field->idtipdok + field->brdok ) == ;
            ( _id_firma + _id_tip_dok + _br_dok )
        // preskoci sve stavke
        skip
    enddo
    
    // provjeri da li u fakt_doks postoji ovaj dokument ve¿ ?
    select fakt_doks
    go top  
    seek _id_firma + _id_tip_dok + _br_dok

    if !FOUND()
        // ne postoji, dodajem ga u matricu
        AADD( _fakt_doks, { _id_firma, _id_tip_dok, _br_dok } )
    endif

    select fakt_pripr

enddo

return _fakt_doks



// ---------------------------------------------------------------------------
// izbrisi azurirane dokumente iz pripreme na osnovu matrice a_data
// ---------------------------------------------------------------------------
static function fakt_izbrisi_azurirane( a_data )
local nRecNo

select fakt_pripr
go top
do while !eof()
    skip 1
    nRecNo := RecNo()
    skip -1
    if ( ASCAN( a_data, field->idfirma + field->idtipdok + field->brdok ) = 0 )
        delete
    endif
    go (nRecNo)
enddo
            
__dbpack()
            
return



// provjeri duple stavke u pripremi za vise dokumenata
function prov_duple_stavke() 
local cSeekDok
local lDocExist:=.f.

select fakt_pripr
go top

// provjeri duple dokumente
do while !EOF()
    cSeekDok := fakt_pripr->(idfirma + idtipdok + brdok)
    if dupli_dokument(cSeekDok)
        lDocExist := .t.
        exit
    endif
    select fakt_pripr
    skip
enddo

// postoje dokumenti dupli
if lDocExist
    MsgBeep("U pripremi su se pojavili dupli dokumenti!")
    if Pitanje(,"Pobrisati duple dokumente (D/N)?", "D")=="N"
        MsgBeep("Dupli dokumenti ostavljeni u tabeli pripreme!#Prekidam operaciju azuriranja!")
        return 1
    else
        Box(,1,60)
            cKumPripr := "P"
            @ m_x+1, m_y+2 SAY "Zelite brisati stavke iz kumulativa ili pripreme (K/P)" GET cKumPripr VALID !Empty(cKumPripr) .or. cKumPripr $ "KP" PICT "@!"
            read
        BoxC()
        
        if cKumPripr == "P"
            // brisi pripremu
            return prip_brisi_duple()
        else
            // brisi kumulativ
            return kum_brisi_duple()
        endif
    endif
endif

return 0



// brisi stavke iz pripreme koje se vec nalaze u kumulativu
function prip_brisi_duple()
local cSeek
select fakt_pripr
go top

do while !EOF()
    cSeek := fakt_pripr->(idfirma + idtipdok + brdok)
    
    if dupli_dokument(cSeek)
        // pobrisi stavku
        select fakt_pripr
        delete
    endif
    
    select fakt_pripr
    skip
enddo

return 0


// brisi stavke iz kumulativa koje se vec nalaze u pripremi
function kum_brisi_duple()
local cSeek
select fakt_pripr
go top

cKontrola := "XXX"

do while !EOF()
    
    cSeek := fakt_pripr->(idfirma + idtipdok + brdok)
    
    if cSeek == cKontrola
        skip
        loop
    endif
    
    if dupli_dokument(cSeek)
        
        // provjeri da li je tabela zakljucana
        select fakt_doks
        
        if !FLock()
            Msg("DOKS datoteka je zauzeta ", 3)
            return 1
        endif
        
        MsgO("Brisem stavke iz kumulativa ... sacekajte trenutak!")
        // brisi doks
        set order to tag "1"
        go top
        seek cSeek
        if Found()
            do while !eof() .and. fakt_doks->(idfirma+idtipdok+brdok) == cSeek
                    skip 1
                nRec:=RecNo()
                skip -1
                    DbDelete2()
                    go nRec
                enddo
            endif
        
        // brisi iz fakt
        select fakt
        set order to tag "1"
        go top
        seek cSeek
        if Found()
            do while !EOF() .and. fakt->(idfirma + idtipdok + brdok) == cSeek
                
                skip 1
                nRec:=RecNo()
                skip -1
                DbDelete2()
                go nRec
            enddo
        endif
        MsgC()
    endif
    
    cKontrola := cSeek
    
    select fakt_pripr
    skip
enddo

return 0


// ------------------------------------------
// ------------------------------------------
function dupli_dokument(cSeek)
select fakt_doks
set order to tag "1"
go top
seek cSeek
if Found()
    if gMreznoNum == "D"
        if m1 == "Z"
            return .f.
        endif
    endif
    return .t.
endif
select fakt
set order to tag "1"
go top
seek cSeek
if Found()
    return .t.
endif
return .f.

// --------------------------------------
// OdrediNBroj(_idfirma,_idtipdok)
// ---------------------------------------- 
function OdrediNbroj(_idfirma, _idtipdok)
local cNBrDok:=""

O_FAKT_DOKS
select fakt_doks
set order to tag "1"
go top

if (gVarNum=="2".and._idtipdok=="13")
    seek _idfirma+_idtipdok+PADL(ALLTRIM(STR(VAL(ALLTRIM(SUBSTR(_idpartner,4))))), 2, "0") + CHR(238)
    skip -1
    do while !bof() .and. _idfirma==idfirma.and._idtipdok==idtipdok.and.LEFT(_idpartner,6)==LEFT(idpartner,6).and.SUBSTR(brdok,6,2)!=PADL(ALLTRIM(STR(MONTH(_datdok))),2,"0")
        skip -1
    enddo
else
    seek _idfirma+_idtipdok+"È"
    skip -1

    if (_idtipdok $ "10#11" .and. ;
        !EMPTY(SUBSTR(brdok,gNumDio+1)) .and. ;
        ( IzFmkIni("FAKT","Brojac11BezEkstenzije","N",KUMPATH)=="D" ;
        .or. gFc_use == "D" ))

        do while !bof() .and. _idfirma==idfirma .and. _idtipdok==idtipdok .and. !Empty(SUBSTR(brdok,gNumDio+1))
                skip -1
        enddo

    endif
endif

if (_idtipdok<>idtipdok .or. _idfirma<>idfirma .or. LEFT(_idpartner,6) <> LEFT(idpartner, 6) .and. (gVarNum=="2" .and. _idtipdok=="13"))
    if (gVarNum=="2".and._idtipdok=="13")
            cNBrDok:=PADL(ALLTRIM(STR(VAL(ALLTRIM(SUBSTR(_idpartner,4))))),2,"0")+"01/"+PADL(ALLTRIM(STR(MONTH(_datdok))),2,"0")
    else
            cNBrDok:=UBrojDok(1, gNumDio,"")
    endif
else
    if (gVarNum=="2".and._idtipdok=="13")
            cNBrDok:=SljBrDok13(brdok,MONTH(_datdok), _idpartner)
    else
            cNBrDok:=UBrojDok( val(left(brdok,gNumDio))+1, gNumDio, right(brdok,len(brdok)-gNumDio))
    endif
endif

cNBrDok:=padr(cNBrDok, 8)

return cNBrDok

// -------------------------------------------------------
//  FaNoviBroj(cIdFirma, cIdTiDdok)
//  Odredi novi broj Fakt-dokumenta 
//  Ne pokriva specif. slucajeve "a-la" Nijagara ...
// ------------------------------------------------------- 
function FaNovibroj(cIdFirma, cIdTipDok)
local cBrdok
local cPom
local cDesniDio
local nPom
local nDesniDio

cBrDok:=""

O_FAKT_DOKS
select fakt_doks
set order to tag "1"
go top

seek cIdFirma+cIdTipDok+CHR(254)
skip -1

if ( (field->idtipdok) <> cIdTipDok ) .or. ((field->idfirma) <> cIdFirma )
    cBrDok:=UBrojDok(1,gNumDio,"")
    return cBrDok
endif

cPom:=LEFT(field->brDok,gNumDio)
nPom:=VAL(cPom)+1
nDesniDio:=LEN(field->brDok)-gNumDio
cDesniDio:=RIGHT(field->brDok, nDesniDio)
cBrDok:= UBrojDok( nPom, gNumDio, cDesniDio)

return cBrDok



// ------------------------------------------------
// ------------------------------------------------
function BrisiPripr()

cSecur:=SecurR(KLevel,"BRISIGENDOK")

// fakt_pripr->m1
if (m1="X" .and. ImaSlovo("X",cSecur))   
    Beep(1)
    Msg("Dokument izgenerisan, ne smije se brisati !!",0)
    return DE_CONT
endif

if !(ImaPravoPristupa(goModul:oDataBase:cName,"DOK","BRISANJE" ))
    MsgBeep(cZabrana)
    return DE_CONT
endif


if Pitanje(, "Zelite li izbrisati pripremu !!????","N")=="D"
    
    if gcF9usmece == "D"

        select fakt_pripr
        go top
    
        cIdFirma:=IdFirma
        cIdTipDok:=IdTipDok
        cBrDok:=BrDok
      
        // baci dokument u smece umjesto da ga 
        // trajno izbrises
        // lSilent = .t.

        azuriraj_smece( .t. )
    
        select fakt_pripr

    else

        SELECT F_FAKT_DOKS

        if !used()
            O_FAKT_DOKS
        endif

        select fakt_pripr

        go top

        do while !eof()
            cIdFirma:=IdFirma
            cIdTipDok:=IdTipDok
            cBrDok:=BrDok
            select fakt_doks
            hseek fakt_pripr->IdFirma+fakt_pripr->IdTipDok+fakt_pripr->BrDok
            if (Found() .and. (fakt_doks->M1=="Z"))
                // dokument zapisan samo u DOKS-u
                _rec := dbf_get_rec()
                delete_rec_server_and_dbf( ALIAS(), _rec )
            endif
            select fakt_pripr
            skip
            do while !eof() .and. (idfirma==cIdFirma) .and. (idtipdok==cIdTipDok) .and. (BrDok==BrDok)
                skip
            enddo
        enddo

        select fakt_pripr
        zap

    endif


    // logiraj ako je potrebno brisanje dokumenta iz pripreme !
    if Logirati(goModul:oDataBase:cName,"DOK","BRISANJE")
    
    cOpis := "dokument: " + cIdFirma + "-" + cIdTipDok + "-" + ALLTRIM(cBrDok)

    EventLog(nUser, goModul:oDataBase:cName, "DOK", "BRISANJE", ;
        nil, nil, nil, nil, ;
        "","", cOpis, DATE(), DATE(), "", ;
        "Brisanje kompletnog dokumenta iz pripreme")
    endif

endif

return


/*! \fn KomIznosFakt()
 *  \brief Kompletiranje iznosa fakture pomocu usluga
 */
 
function KomIznosFakt()
*{
local nIznos:=0
local cIdRoba

O_SIFK
O_SIFV
O_FAKT_S_PRIPR
O_TARIFA
O_ROBA

cIdRoba:=SPACE(LEN(id))

Box("#KOMPLETIRANJE IZNOSA FAKTURE POMOCU USLUGA",5,75)
    @ m_x+2, m_y+2 SAY "Sifra usluge:" GET cIdRoba VALID P_Roba(@cIdRoba) PICT "@!"
    @ m_x+3, m_y+2 SAY "Zeljeni iznos fakture:" GET nIznos PICT picdem
    read
    ESC_BCR
BoxC()

select roba
hseek cIdRoba
select tarifa
hseek roba->idtarifa
select fakt_pripr

nDug2:=0
nRab2:=0
nPor2:=0

KonZbira(.f.)

go bottom

Scatter()

append blank

_idroba:=cIdRoba
_kolicina:=IF(nDug2-nRab2+nPor2>nIznos,-1,1)
_rbr:=STR(RbrUnum(_Rbr)+1,3)
_cijena:=ABS(nDug2-nRab2+nPor2-nIznos)
_rabat:=0 
_porez:=0

if !(_idtipdok $ "11#15#27")
    _porez:=if( ROBA->tip=="U",tarifa->ppp,tarifa->opp)
    _cijena:=_cijena/(1+_porez/100)
endif

_txt:=Chr(16)+ROBA->naz+Chr(17)

Gather()

MsgBeep("Formirana je dodatna stavka. Vratite se tipkom <Esc> u pripremu"+"#i prekontrolisite fakturu!")

CLOSERET


// ---------------------------------------------------
// generisi storno dokument u pripremi
// ---------------------------------------------------
function storno_dok( cIdFirma, cIdTipDok, cBrDok )
local cNoviBroj 

if Pitanje(,"Formirati storno dokument ?","D") == "N"
    return
endif

O_FAKT_PRIPR
select fakt_pripr

if fakt_pripr->(RECCOUNT2()) <> 0
    msgbeep("Priprema nije prazna !!!")
    return
endif


O_FAKT
O_FAKT_DOKS
O_ROBA
O_PARTN

cNoviBroj := ALLTRIM(cBrDok) + "/S"

if LEN( ALLTRIM( cNoviBroj ) ) > 8
    
    // otkini prva dva karaktera
    // da moze stati "/S"
    cNoviBroj := RIGHT( ALLTRIM( cBrDok ), 6 ) + "/S"

endif

nCnt := 0

select fakt_doks
set order to tag "1"
go top
seek cIdFirma + cIdTipDok + cBrDok

nFiscal := 0
if gFc_use == "D"
    nFiscal := field->fisc_rn
endif

select fakt
set order to tag "1"
go top
seek cIdFirma + cIdTipDok + cBrDok

do while !EOF() .and. field->idfirma == cIdFirma ;
        .and. field->idtipdok == cIdTipDok ;
        .and. field->brdok == cBrDok
    
    
    scatter()

    select fakt_pripr
    append blank
    
    gather()

    replace field->kolicina with ( field->kolicina * -1 )
    replace field->brdok with cNoviBroj
    replace field->datdok with DATE()
    
    if gFc_use == "D"
        replace field->fisc_rn with nFiscal
    endif

    select fakt
    skip

    ++ nCnt

enddo

if nCnt > 0
    msgbeep("Formiran je dokument " + cIdFirma + "-" + ;
        cIdTipDok + "-" + ALLTRIM(cNoviBroj) + ;
        " u pripremi !")
endif

return





