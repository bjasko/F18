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
#include "achoice.ch"
#include "fileio.ch"


function SC_START(oApp, lSezone)
local cImeDbf
local _i
public gAppSrv

if !oApp:lStarted  
    RDDSETDEFAULT( RDDENGINE )
    ? "startujem oApp:db()"
    oApp:initdb()
endif

SetgaSDbfs()

set_global_vars_0()

gModul   := oApp:cName
gVerzija := oApp:cVerzija

gAppSrv := .f.

if mpar37("/APPSRV", oApp)
    ? "Pokrecem App Serv ..."
    gAppSrv := .t.
endif

SetNaslov(oApp)

oApp:oDatabase:lAdmin:=.t.

CreGParam()

set_global_vars_0_prije_prijave()

// inicijalizacija, prijava
InitE( oApp )

set_global_vars_0_nakon_prijave()

if oApp:lTerminate
    return
endif

oApp:oDatabase:setgaDbfs()

oApp:oDatabase:install()

KonvTable()

if lSezone
    oApp:oDatabase:loadSezonaRadimUSezona()
    if gAppSrv
        ? "Pokrecem App Serv ..."
        oApp:setGVars()
        gAppSrv:=.t.
        oApp:srv()
    endif
    oApp:oDatabase:radiUSezonskomPodrucju(mpar37("/XN",oApp))
    gProcPrenos:="D"
else
    if gAppSrv
        cPars:=mparstring(oApp)
        cKom:="{|| RunAppSrv("+cPars+")}"
        ? "Pokrecem App Serv ..."
        gAppSrv:=.t.
        oApp:SetGVars()
        Eval(&cKom)
    endif
endif 

IniPrinter()

if (lSezone .and. mpar37("/XN",oApp))
    SetOznNoGod()
endif

gReadOnly := .f.

SET EXCLUSIVE OFF

//Setuj globalne varijable varijable modula 
oApp:setGVars()

oApp:oDataBase:setSigmaBD( IzFmkIni("Svi","SigmaBD","c:"+SLASH+"sigma",EXEPATH) )

return

/*! \fn ISC_START(oApp, lSezone)
 *  \brief Aktiviranje "install" programskog modula"
 */

function ISC_START(oApp, lSezone)

RDDSETDEFAULT(RDDENGINE)

set exclusive on
oApp:oDatabase:lAdmin:=.t.

@ 10,30 SAY ""

CreSystemDB()
    
set_global_vars_0_nakon_prijave(.f.)

oApp:oDatabase:loadSezonaRadimUSezona()
oApp:oDatabase:radiUSezonskomPodrucju()
  
oApp:setGVars()

@ 10,20 SAY ""

if Pitanje(,"Izvrsiti instalaciju fajlova (D/N) ?","N")=="D"
    oApp:oDatabase:kreiraj()
endif

gPrinter := "R"

O_GPARAMS
O_PARAMS

gMeniSif:=.f.
gValIz:="280 "
gValU:="000 "
gKurs:="1"
  
private cSection:="1"
private cHistory:=" "
private aHistory:={}

RPar("px",@gPrinter)
RPar("vi",@gValIz)
RPar("vu",@gValU)
RPar("vk",@gKurs)

select params
use

select gparams
private cSection:="P"
private cHistory:=gPrinter
private aHistory:={}

RPar_Printer()

gPTKONV:="0"
gPicSif:="V"
gcDirekt:="V"
gSKSif:="D"
gPFont:="Arial"

private cSection:="1", cHistory:=" "; aHistory:={}

Rpar("pt",@gPTKonv)
Rpar("pS",@gPicSif)
Rpar("SK",@gSKSif)
Rpar("DO",@gcDirekt)
Rpar("Ad",@gArhDir)
Rpar("FO",@gPFont)

select gparams
use

Beep(1)

IBatchRun(oApp)

@ 10,30 SAY ""
oApp:oDatabase:mInstall()

return



/*! \fn IBatchRun(oApp)
 *  \brief Batch funkcije za kreiranje baze podataka
 *  \todo Sve batch funkcije prebaciti u appsrv kompomentu 
 */

function IBatchRun(oApp)


if mpar37("/XM",oApp)
      oApp:oDatabase:modstruAll()
endif

if mpar37("/APPSRV",oApp)
        cKom:="{|| RunAppSrv() }"
        ? "Pokrecem App Serv ..."
        Eval(&cKom)
endif

if mpar37("/B",oApp)
       BrisipaK(.t.)
       CreSystemDb()
       oApp:oDatabase:kreiraj()
endif

if mpar37("/I",oApp)
       oApp:oDatabase:kreiraj()
endif

if mpar37("/R",oApp)
       Reindex(.t.)
endif

if mpar37("/P",oApp)
       Pakuj(.t.)
endif

if mpar37("/M",oApp)
       RunMods(.t.)
endif

return


// --------------------------------------------------------
// --------------------------------------------------------
function SetNaslov(oApp)



gNaslov:= oApp:cName + " F18, " + oApp:cPeriod 

return


// -------------------------------------------------
// -------------------------------------------------
function InitE(oApp)

if (oApp:cKorisn<>nil .and. oApp:cSifra==nil)

    ? "Koristenje:  ImePrograma "
    ? "             ImePrograma ImeKorisnika Sifra"
    ?
    quit

endif

AFILL(h,"")

nOldCursor:=IIF(readinsert(),2,1)

if !gAppSrv
  standardboje()
endif

SET KEY K_INS  TO ToggleINS()
SET MESSAGE TO 24 CENTER
SET DATE GERMAN
SET SCOREBOARD OFF

SET CONFIRM ON

SET WRAP ON
SET ESCAPE ON
SET SOFTSEEK ON
// naslovna strana

if gAppSrv
  ? gNaslov, oApp:cVerzija  
  Prijava(oApp, .f. )
  return
endif

NaslEkran(.t.)
ToggleIns()
ToggleIns()

@ 10,35 SAY ""
// prijava

if !oApp:lStarted
  if (oApp:cKorisn<>nil .and. oApp:cSifra<>nil)
   if oApp:cP3<>nil 
     Prijava(oApp,.f.)  // bez prijavnog Box-a
   else
     Prijava(oApp)
     PokreniInstall(oApp)
   endif
  else
   Prijava(oApp)
  endif
endif

say_database_info()
return nil



function PokreniInstall(oApp)

local cFile
local lPitaj

lPitaj:=.f.

cFile:=oApp:oDatabase:cDirPriv

if (cFile==nil)
  return
endif

if !IsDirectory(cFile)
  lPitaj:=.t.
endif

cFile:=oApp:oDatabase:cDirSif
if !IsDirectory(cFile)
  lPitaj:=.t.
endif

cFile:=oApp:oDatabase:cDirKum
if !IsDirectory(cFile)
  lPitaj:=.t.
endif

if lPitaj
  if Pitanje(,"Pokrenuti instalacijsku proceduru ?","D")=="D"
    oApp:oDatabase:install()
  endif
endif

return



function mpar37(x, oApp)


// proslijedjeni su parametri
lp3:=oApp:cP3
lp4:=oApp:cP4
lp5:=oApp:cP5
lp6:=oApp:cP6
lp7:=oApp:cP7

return ( (lp3<>NIL .and. upper(lp3)==x) .or. (lp4<>NIL .and. upper(lp4)==x) .or. ;
         (lp5<>NIL .and. upper(lp5)==x) .or. (lp6<>NIL .and. upper(lp6)==x) .or. ;
         (lp7<>NIL .and. upper(lp7)==x) )



function mpar37cnt(oApp)

local nCnt:=0

if oApp:cP3<>nil
  ++nCnt
endif
if oApp:cP4<>nil
  ++nCnt
endif
if oApp:cP5<>nil
  ++nCnt
endif
if oApp:cP6<>nil
  ++nCnt
endif
if oApp:cP7<>nil
  ++nCnt
endif

return nCnt


function mparstring(oApp)

local cPars
cPars:=""

if oApp:cP3<>NIL
  cPars+="'"+oApp:cP3+"'"
endif
if oApp:cP4<>NIL
  if !empty(cPars); cPars+=", ";endif
  cPars+="'"+oApp:cP4+"'"
endif
if oApp:cP5<>NIL
  if !empty(cPars); cPars+=", ";endif
  cPars+="'"+oApp:cP5+"'"
endif
if oApp:cP6<>NIL
  if !empty(cPars); cPars+=", ";endif
  cPars+="'"+oApp:cP6+"'"
endif
if oApp:cP7<>NIL
  if !empty(cPars); cPars+=", ";endif
  cPars+="'"+oApp:cP7+"'"
endif

return cPars





/*! \fn Prijava(oApp,lScreen)
 *  \brief Prijava korisnika pri ulasku u aplikaciju
 *  \todo Prijava je primjer klasicne kobasica funkcije ! Razbiti je.
 *  \todo prijavu na osnovu scshell.ini izdvojiti kao posebnu funkciju
 */
 
function Prijava(oApp, lScreen)


local i
local nRec
local cKontrDbf
local cCD

local cPom
local cPom2
local lRegularnoZavrsen

if lScreen==nil
  lScreen:=.t.
endif


@ 3,4 SAY ""
if (gfKolor=="D" .and. ISCOLOR())
  Normal:="GR+/B,R/N+,,,N/W"
else
  Normal:="W/N,N/W,,,N/W"
endif

if !oApp:lStarted
  if lScreen
    //korisn->nk napustiti
    //PozdravMsg(gNaslov, gVerzija, korisn->nk)
    //lGreska:=.f.
    PozdravMsg(gNaslov, gVerzija, .f.)
  endif
endif

if (gfKolor=="D" .and. ISCOLOR())
  Normal := "W/B,R/N+,,,N/W"
else
  Normal := "W/N,N/W,,,N/W"
endif

CLOSERET
return nil

static function PrijRunInstall(m_sif, cKom)


if m_sif=="I"
  cKom:=cKom:="I"+gModul+" "+ImeKorisn+" "+CryptSC(sifrakorisn)
endif
if m_sif=="IM"
  cKom+="  /M"
endif
if m_sif=="II"
  cKom+="  /I"
endif
if m_sif=="IR"
  cKom+="  /R"
endif
if m_sif=="IP"
  cKom+="  /P"
endif
if m_sif=="IB"
  cKom+="  /B"
endif
RunInstall(cKom)

return


function RunInstall(cKom)

local lIB

lIB:=.f.

if (cKom==nil)
  cKom:=""
endif

//MsgBeep("cKom="+cKom)
if (" /B" $ cKom)
  goModul:cP7:="/B"
  lIb:=.t.
endif
goModul:oDatabase:install()

if (lIB)
  goModul:cP7:=""
  lIB:=.f.
endif

