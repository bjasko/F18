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


#include "kalk.ch"


function IP()
O_KONTO
O_TARIFA
O_SIFK
O_SIFV
O_ROBA

Box(,4,50)

cIdFirma:=gFirma
cIdkonto:=padr("1320",7)
dDatDok:=date()
cNulirati:="N"

@ m_x+1,m_Y+2 SAY "Prodavnica:" GET  cidkonto valid P_Konto(@cidkonto)
@ m_x+2,m_Y+2 SAY "Datum     :  " GET  dDatDok
@ m_x+3,m_Y+2 SAY "Nulirati lager (D/N)" GET cNulirati VALID cNulirati $ "DN" PICT "@!"

read
ESC_BCR

BoxC()

O_KONCIJ
O_kalk_pripr
O_KALK
private cBrDok:=SljBroj(cidfirma,"IP",8)

nRbr:=0
set order to tag "4"

MsgO("Generacija dokumenta IP - "+cbrdok)

select koncij
seek trim(cidkonto)
select kalk

hseek cidfirma+cidkonto

do while !eof() .and. cidfirma+cidkonto==idfirma+pkonto

    cIdRoba:=Idroba
    nUlaz:=nIzlaz:=0
    nMPVU:=nMPVI:=nNVU:=nNVI:=0
    nRabat:=0
    
    select roba
    hseek cidroba
    
    select kalk
    
    do while !eof() .and. cidfirma+cidkonto+cidroba==idFirma+pkonto+idroba

        if ddatdok<datdok  // preskoci
            skip
            loop
        endif
    
        if roba->tip $ "UT"
            skip
            loop
        endif

        if pu_i=="1"
            nUlaz+=kolicina-GKolicina-GKolicin2
            nMPVU+=mpcsapp*kolicina
            nNVU+=nc*kolicina

        elseif pu_i=="5"  .and. !(idvd $ "12#13#22")
            nIzlaz+=kolicina
            nMPVI+=mpcsapp*kolicina
            nNVI+=nc*kolicina

        elseif pu_i=="5"  .and. (idvd $ "12#13#22")    
            // povrat
            nUlaz-=kolicina
            nMPVU-=mpcsapp*kolicina
            nNvu-=nc*kolicina

        elseif pu_i=="3"    // nivelacija
            nMPVU+=mpcsapp*kolicina

        elseif pu_i=="I"
            nIzlaz+=gkolicin2
            nMPVI+=mpcsapp*gkolicin2
            nNVI+=nc*gkolicin2
        endif
        skip
    enddo

    if (round(nulaz-nizlaz,4)<>0) .or. (round(nmpvu-nmpvi,4)<>0)
        select roba
        hseek cidroba
        select kalk_pripr
        scatter()
        append ncnl
        _idfirma:=cidfirma; _idkonto:=cidkonto; _pkonto:=cidkonto; _pu_i:="I"
        _idroba:=cidroba; _idtarifa:=roba->idtarifa
        _idvd:="IP"; _brdok:=cbrdok

        _rbr:=RedniBroj(++nrbr)
        _kolicina:=_gkolicina:=nUlaz-nIzlaz
        if cNulirati == "D"
            _kolicina := 0
        endif
        _datdok:=_DatFaktP:=ddatdok
        _ERROR:=""
        _fcj:=nmpvu-nmpvi // stanje mpvsapp
        if round(nulaz-nizlaz,4)<>0
            _mpcsapp:=round((nMPVU-nMPVI)/(nulaz-nizlaz),3)
            _nc:=round((nnvu-nnvi)/(nulaz-nizlaz),3)
        else
            _mpcsapp:=0
        endif
        Gather2()
        select kalk
    endif

enddo

MsgC()

close all
return


// ---------------------------------------------------------------------------
// inventurno stanje artikla 
// ---------------------------------------------------------------------------
function kalk_ip_roba( id_konto, id_roba, dat_dok, kolicina, nc, fc, mpcsapp )
local _t_area := SELECT()
local _ulaz, _izlaz, _mpvu, _mpvi, _rabat, _nvu, _nvi

_ulaz := 0
_izlaz := 0
_mpvu := 0
_mpvi := 0
_rabat := 0
_nvu := 0
_nvi := 0

kolicina := 0
nc := 0
fc := 0
mpcsapp := 0

select roba
hseek id_roba

if roba->tip $ "UI"
    select ( _t_area )
    return
endif

select kalk
set order to tag "4"
hseek gFirma + id_konto + id_roba 

do while !EOF() .and. field->idfirma == gFirma .and. field->pkonto == id_konto .and. field->idroba == id_roba

    if dat_dok < field->datdok  
        // preskoci
        skip
        loop
    endif
    
    if field->pu_i == "1"
        _ulaz += field->kolicina - field->gkolicina - field->gkolicin2
        _mpvu += field->mpcsapp * field->kolicina
        _nvu += field->nc * field->kolicina

    elseif field->pu_i == "5" .and. !( field->idvd $ "12#13#22" )
        _izlaz += field->kolicina
        _mpvi += field->mpcsapp * field->kolicina
        _nvi += field->nc * field->kolicina

    elseif field->pu_i == "5" .and. ( field->idvd $ "12#13#22" )      
        // povrat
        _ulaz -= field->kolicina
        _mpvu -= field->mpcsapp * field->kolicina
        _nvu -= field->nc * field->kolicina

    elseif field->pu_i == "3"   
        // nivelacija
        _mpvu += field->mpcsapp * field->kolicina

    elseif field->pu_i == "I"
        _izlaz += field->gkolicin2
        _mpvi += field->mpcsapp * field->gkolicin2
        _nvi += field->nc * field->gkolicin2
    endif
    
    skip

enddo
 

if ROUND( _ulaz - _izlaz, 4 ) <> 0
    kolicina := _ulaz - _izlaz
    fcj := _mpvu - _mpvi 
    mpcsapp := ROUND( ( _mpvu - _mpvi ) / ( _ulaz - _izlaz ), 3 )
    nc := ROUND( ( _nvu - _nvi ) / ( _ulaz - _izlaz ), 3 )
endif
 
return




// generacija inventure - razlike postojece inventure
function gen_ip_razlika()
*{
O_KONTO

Box(,4,50)
	cIdFirma:=gFirma
	cIdkonto:=padr("1320",7)
	dDatDok:=date()
	cOldBrDok:=SPACE(8)
	cIdVd := "IP"
	@ m_x+1,m_Y+2 SAY "Prodavnica:" GET cIdKonto valid P_Konto(@cIdKonto)
	@ m_x+2,m_Y+2 SAY "Datum do  :" GET dDatDok
	@ m_x+3,m_y+2 SAY "Dokument " + cIdFirma + "-" + cIdVd GET cOldBrDok
	read
	ESC_BCR
BoxC()

if Pitanje(,"Generisati inventuru (D/N)","D") == "N"
	return
endif

// prvo izvuci postojecu inventuru u PRIPT
if cp_dok_pript(cIdFirma, cIdVd, cOldBrDok) == 0
	return
endif

O_TARIFA
O_SIFK
O_SIFV
O_ROBA
O_KONCIJ
O_kalk_pripr
O_PRIPT
O_KALK

private cBrDok:=SljBroj(cIdFirma, "IP", 8)

nRbr:=0
set order to tag "4"

MsgO("Generacija dokumenta IP - " + cBrDok)

select koncij
seek trim(cIdKonto)
select kalk
hseek cIdFirma + cIdKonto
do while !eof() .and. cIdFirma + cIdKonto == idfirma + pkonto
	cIdRoba:=Idroba
	
	select pript
	set order to tag "2"
	hseek cIdFirma+"IP"+cOldBrDok+cIdRoba
	
	// ako nadjes dokument u pript prekoci ga u INVENTURI!!!	
	if Found()
		select kalk
		skip
		loop
	endif
	
	nUlaz:=nIzlaz:=0
	nMPVU:=nMPVI:=nNVU:=nNVI:=0
	nRabat:=0
	select roba
	hseek cidroba
	select kalk
	do while !eof() .and. cidfirma+cidkonto+cidroba==idFirma+pkonto+idroba
		if ddatdok<datdok  // preskoci
      			skip
      			loop
  		endif
  		if roba->tip $ "UT"
      			skip
      			loop
  		endif
		
		if pu_i=="1"
    			nUlaz+=kolicina-GKolicina-GKolicin2
    			nMPVU+=mpcsapp*kolicina
    			nNVU+=nc*kolicina
  		elseif pu_i=="5"  .and. !(idvd $ "12#13#22")
    			nIzlaz+=kolicina
    			nMPVI+=mpcsapp*kolicina
    			nNVI+=nc*kolicina
  		elseif pu_i=="5"  .and. (idvd $ "12#13#22")    
    			// povrat
    			nUlaz-=kolicina
    			nMPVU-=mpcsapp*kolicina
    			nnvu-=nc*kolicina
  		elseif pu_i=="3"    // nivelacija
   			nMPVU+=mpcsapp*kolicina
		elseif pu_i=="I"
    			nIzlaz+=gkolicin2
    			nMPVI+=mpcsapp*gkolicin2
    			nNVI+=nc*gkolicin2
  		endif
  		skip
	enddo

	if (round(nulaz-nizlaz,4)<>0) .or. (round(nmpvu-nmpvi,4)<>0)
		select roba
		hseek cidroba
 		select kalk_pripr
 		scatter()
 		append ncnl
 		_idfirma:=cidfirma
		_idkonto:=cidkonto
		_pkonto:=cidkonto
		_pu_i:="I"
 		_idroba:=cidroba
		_idtarifa:=roba->idtarifa
 		_idvd:="IP"
		_brdok:=cbrdok
		_rbr:=RedniBroj(++nrbr)
		// kolicinu odmah setuj na 0
		_kolicina:=0
		// popisana kolicina je trenutno stanje
		_gkolicina:=nUlaz-nIzlaz
		_datdok:=_DatFaktP:=ddatdok
		_ERROR:=""
		_fcj:=nmpvu-nmpvi // stanje mpvsapp
 		if round(nulaz-nizlaz,4)<>0
  			_mpcsapp:=round((nMPVU-nMPVI)/(nulaz-nizlaz),3)
  			_nc:=round((nnvu-nnvi)/(nulaz-nizlaz),3)
 		else
  			_mpcsapp:=0
 		endif
 		Gather2()
 		select kalk
	endif
enddo
MsgC()

closeret
return



function Get1_IP()
local nFaktVPC

_DatFaktP:=_datdok
_DatKurs:=_DatFaktP
private aPorezi:={}

 @ m_x+8,m_y+2   SAY "Konto koji zaduzuje" GET _IdKonto valid  P_Konto(@_IdKonto,24) pict "@!"
 if gNW<>"X"
   @ m_x+8,m_y+35  SAY "Zaduzuje: "   GET _IdZaduz  pict "@!" valid empty(_idZaduz) .or. P_Firma(@_IdZaduz,24)
 endif
 read; ESC_RETURN K_ESC

 @ m_x+10,m_y+66 SAY "Tarif.br->"
 if lKoristitiBK
 	@ m_x+11,m_y+2   SAY "Artikal  " GET _IdRoba pict "@!S10" when {|| _idRoba:=PADR(_idRoba,VAL(gDuzSifIni)),.t.} valid VRoba()
 else
 	@ m_x+11,m_y+2   SAY "Artikal  " GET _IdRoba pict "@!" valid VRoba()
 endif
 @ m_x+11,m_y+70 GET _IdTarifa when gPromTar=="N" valid P_Tarifa(@_IdTarifa)

 read; ESC_RETURN K_ESC

 if lKoristitiBK
 	_idRoba:=Left(_idRoba,10)
 endif
 
 IF !empty(gMetodaNC)
    KNJIZST()
 ENDIF
 select TARIFA
 hseek _IdTarifa  // postavi TARIFA na pravu poziciju
 select kalk_pripr  // napuni tarifu

 DuplRoba()
 @ m_x+13,m_y+2   SAY "Knjizna kolicina " GET _GKolicina PICTURE PicKol  ;
    when {|| iif(gMetodaNC==" ",.t.,.f.)}
 @ m_x+13,col()+2 SAY "Popisana Kolicina" GET _Kolicina VALID VKol() PICTURE PicKol

 if IsPDV()
   @ m_x+15,m_y+2    SAY "P.CIJENA (SA PDV)" GET _mpcsapp pict picdem
 else
   @ m_x+15,m_y+2    SAY "CIJENA (MPCSAPP)" GET _mpcsapp pict picdem
 endif
 @ m_x+17,m_y+2    SAY "NABAVNA CIJENA  " GET _nc pict picdem

 read; ESC_RETURN K_ESC

 // _fcj - knjizna prodajna vrijednost
 // _fcj3 - knjizna nabavna vrijednost
_gkolicin2:=_gkolicina-_kolicina   // ovo je kolicina izlaza koja nije proknjizena
_MKonto:="";_MU_I:=""     // inventura
_PKonto:=_Idkonto;      _PU_I:="I"
nStrana:=3
return lastkey()
*}


static function VKol()
*{
local lMoze:=.t.
if (glZabraniVisakIP)
	if (_kolicina>_gkolicina)
		MsgBeep("Ne dozvoljavam evidentiranje viska na ovaj nacin!")
		lMoze:=.f.
	endif
endif
return lMoze
*}

