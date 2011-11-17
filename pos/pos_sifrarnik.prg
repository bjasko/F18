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


#include "pos.ch"

 
function P_Kase(cId,dx,dy)
private ImeKol
private Kol

SELECT (F_KASE)
if !used()
	O_KASE
endif

ImeKol:={}
AADD(ImeKol,{"Sifra/ID kase",{||id},"id"})
AADD(ImeKol,{"Naziv kase",{||Naz },"Naz"})
AADD(ImeKol,{"Lokacija kumulativa",{||pPath},"pPath"})
Kol:={1,2,3}

return PostojiSifra(F_KASE,1, 10, 77, "Sifarnik kasa/prodajnih mjesta", @cId, dx, dy)


 
function Id2Naz()
local nSel:=SELECT()

Pushwa()
select roba
HSEEK sast->id2
popwa()

return LEFT(roba->naz,25)

 
function LMarg()
return "   "


 
function P_Odj(cId,dx,dy)
private ImeKol
private Kol:={}

ImeKol:={{"ID ",{|| id },"id",{|| .t.},{|| vpsifra(wId)}},{PADC("Naziv",25),{|| naz},"naz"},{"Konto u KALK",{|| IdKonto},"IdKonto"}}

if gModul=="HOPS"
	AADD (ImeKol, { "Zaduzuje R/S",{|| PADC (ZADUZuje, 12)}, "Zaduzuje", {|| .T.}, {|| wZaduzuje $ "RS"} })
endif

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next
return PostojiSifra(F_ODJ,I_ID,10,40,"Sifarnik odjeljenja", @cId,dx,dy)


 
function P_Dio(cId,dx,dy)
private ImeKol
private Kol:={}

ImeKol:={{"ID ",{|| id },"id",{|| .t.},{|| vpsifra(wId)}},{PADC("Naziv",25),{|| naz},"naz"}}

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next
return PostojiSifra(F_DIO,I_ID,10,55,"Sifrarnik dijelova objekta",@cid,dx,dy)


 
function P_StRad(cId,dx,dy)
private ImeKol
private Kol:={}

ImeKol:={ { "ID ",  {|| id },       "id"  , {|| .t.}, {|| vpsifra(wId)}      },;
          { PADC("Naziv",15), {|| naz},       "naz"       },;
          { "Prioritet"     , {|| PADC(prioritet,9)}, "prioritet", {|| .T.}, {|| ("0" <= wPrioritet) .AND. (wPrioritet <= "3")} } ;
        }

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next
return PostojiSifra(F_STRAD,I_ID,10,55,"Sifrarnik statusa radnika",@cid,dx,dy)



function P_Osob(cId, dx, dy)
private ImeKol
private Kol:={}

ImeKol:={ { "ID ",          {|| id },    "id", {|| .t.}, {|| vpsifra(wId)} },;
          { PADC("Naziv",40), {|| naz},  "naz"    },;
          { "Korisn.sifra", {|| korsif}, "korsif" },;
          { "Status",       {|| status}, "status" };
        }

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next

return PostojiSifra(F_OSOB, I_ID2, 10, 55, "Sifrarnik osoblja", @cid, dx, dy, {|| EdOsob()})
return



 
function P_Uredj(cId, dx, dy)
private ImeKol
private Kol:={}

ImeKol:={ { "ID ",  {|| id },       "id"  , {|| .t.}, {|| vpsifra(wId)}      },;
          { PADC("Naziv",30), {|| naz},      "naz"       },;
          { "Port", {|| port},      "port"       };
        }

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next

return PostojiSifra(F_UREDJ,I_ID,10,55,"Sifrarnik uredjaja",@cid,dx,dy)



 
function P_MJTRUR(cId,dx,dy)
private ImeKol
private Kol:={}

ImeKol:={{ "Uredjaj",     {|| iduredjaj }, "IdUredjaj", {|| .t.}, {|| P_Uredj(wIdUredjaj)}},;
	 { "Odjeljenje",  {|| IdOdj },     "IdOdj"    , {|| .t.}, {|| P_Odj(wIdOdj)}},;
	 { "Dio objekta", {|| IdDio },     "IdDio"    , {|| .t.}, {|| P_Dio(wIdDio)}} ;
        }

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next
return PostojiSifra(F_MJTRUR, I_ID, 10, 55, "Sifrarnik parova uredjaj-odjeljenje", @cid, dx, dy)


 
function P_RobaIz(cId,dx,dy)
private ImeKol
private Kol:={}

ImeKol:={{"IdRoba",      {|| IdRoba }, "IdRoba", {|| .t.}, {|| P_Roba(wIdRoba)}},;
         {"Dio objekta", {|| IdDio },  "IdDio",  {|| .t.}, {|| P_Dio(wIdDio)}} ;
        }

for i:=1 to LEN(ImeKol)
	AADD(Kol,i)
next

return PostojiSifra(F_ROBAIZ,I_ID,10,55,"Sifrarnik iznimki kod izuzimanja robe",@cid,dx,dy)



function EdOsob()
local System:=(KLevel<L_UPRAVN)
local nVrati:=DE_CONT

do case
	case Ch==K_CTRL_N
		if gSamoProdaja=="D"
         		MsgBeep("SamoProdaja=D#Nemate ovlastenje za ovu opciju !")
         		nVrati:=DE_CONT
      		else
      			if System
         			Scatter()
         			_korsif:=space(6)
         			if GetOsob(.t.)<>K_ESC
           				// azuriranje OSOB.DBF
           				_korsif:=CryptSC(_korsif)
           				APPEND BLANK
					sql_append()
           				Gather()
           				GathSql()
					sql_azur(.t.)
					nVrati:=DE_REFRESH
         			endif
      			endif
      		endif
  	case Ch==K_F2
      		if gSamoProdaja=="D"
             		MsgBeep("SamoProdaja=D#Nemate ovlastenje za ovu opciju !")
             		nVrati:=DE_CONT
      		else
      			if System
          			Scatter()
          			_korsif:=CryptSC(_korsif)
          			if GetOsob(.f.)<>K_ESC
            				// azuriranje OSOB.DBF
            				_korsif:=CryptSC(_korsif)
            				Gather()
					GathSql()
					sql_azur(.t.)
            				nVrati:=DE_REFRESH
          			endif
      			endif
      		endif
  	case Ch==K_CTRL_T
     		if gSamoProdaja=="D"
         		MsgBeep("Nemate ovlastenje za ovu opciju !")
         		nVrati:=DE_CONT
     		else
     			if System
      				if Pitanje(,"Izbrisati korisnika "+ trim(naz) +":"+CryptSC(korsif)+" D/N ?","N")=="D"
       					// azuriranje OSOB.DBF
         				SELECT osob
         				DELETE
         				sql_delete()
         				nVrati:=DE_REFRESH
      				endif
     			endif
     		endif
  	case Ch==K_ESC .or. Ch==K_ENTER
     		nVrati:=DE_ABORT
endcase

if ch==K_ALT_R .or. ch==K_ALT_S .or. ch==K_CTRL_N .or. ch==K_F2 .or. ch==K_F4 .or. ch==K_CTRL_A .or. ch==K_CTRL_T .or. ch==K_ENTER
	ch:=0
endif
return nVrati



function GetOsob(fNovi)
local cLevel

Box("",4,60,.f.,"Unos novog korisnika,sifre")
SET CURSOR ON
if fNovi.or.KLevel=="0"
	@ m_x+1,m_y+2 SAY "Sifra radnika (ID)." GET _id VALID vpsifra(_id)
else
	@ m_x+1,m_y+2 SAY "Sifra radnika (ID). "+_id
endif
@ m_x+2,m_y+2 SAY "Ime radnika........" GET _naz
read

SELECT strad
HSEEK gStRad
cLevel:=strad->prioritet

SELECT strad
HSEEK _status
select osob

// level tekuceg korisnika > level
if (cLevel>strad->prioritet)  
	MsgBeep("Ne mozete mjenjati sifru")
else
	@ m_x+3,m_y+2 SAY "Sifra.............." GET _korsif PICTURE "@!" VALID vpsifra2(_korsif,_id)
 	@ m_x+4,m_y+2 SAY "Status............." GET _status VALID P_STRAD(@_status)
endif

READ
BoxC()
return lastkey()



static function VPSifra2(cSifra,cIme)
local lRet:=.t.
local nObl:=SELECT()

if EMPTY(cSifra)
	Beep (3)
   	return (.f.)
endif

//O_KORISN
//GO TOP
//do while !eof()
//	if (korisn->sif==CryptSC(cSifra).and. korisn->ime!=cIme)
  //  		BEEP(3)
    //		lRet:=.f.
    //		EXIT
  	//endif
  	//SKIP 1
//enddo
//USE
//SELECT (nObl)
return lRet




function PomMenu1(aNiz)
local xP:=ROW()
local yP:=COL()
local xN
local yN
local dP:=LEN(aNiz)+1
local sP:=0

AEVAL(aNiz,{|x| IF(LEN(x[1]+x[2])>sP,sP:=LEN(x[1]+x[2]),)})
sP+=3
xN:=IF(xP>11,xP-dP,xP+1)
yN:=IF(yP>39,yP-sP,yP+1)
Prozor1(xN,yN,xN+dP,yN+sP-1,"POMOC")

for i:=1 to dP-1
	@ xN+i,yN+1 SAY PADR(aNiz[i,1]+"-"+aNiz[i,2],sP-2)
next

@ xP,yP SAY ""

return




function P_Barkod(cBK)
local fRet:=.f.
local nRec:=recno()

PushWa()
set order to tag "BARKOD"
seek cBK
if !empty(cBK) .and. found() .and. nRec<>RECNO()
	MsgBeep("Isti barkod pridruzen je sifri: "+id+" ??!")
       	PopWa()
       	return .f.
endif

// trazi alternativne sifre
if !empty(cBK)
	cID:=""
   	ImaUSifV("ROBA","BARK", cBK, @cId)
   	if !empty(cID)
     		select roba
		set order to tag "ID"
		seek cId  // nasao sam sifru !!
     		MsgBeep("Isti barkod pridruzen je sifri: "+id+" ??!")
     		PopWa()
     		return .f.
   	endif
endif

PopWa()
return .t.


