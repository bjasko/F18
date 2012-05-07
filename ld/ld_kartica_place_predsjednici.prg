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


#include "ld.ch"

static DUZ_STRANA := 64


// -------------------------------------------------
// nova varijanta kartica plate
// -------------------------------------------------
function kartplp( cIdRj, cMjesec, cGodina, cIdRadn, cObrac, aNeta )
local nKRedova
local cDoprSpace := SPACE(3)
local cTprLine 
local cDoprLine 
local cMainLine 
local _a_benef
private cLMSK := "" 

cTprLine := _gtprline()
cDoprLine := _gdoprline(cDoprSpace)
cMainLine := _gmainline()

// koliko redova ima kartica
nKRedova := kart_redova()

Eval(bZagl)

cUneto := "D"
nRRsati := 0 
nOsnNeto := 0
nOsnOstalo := 0
nLicOdbitak := ld->ulicodb
nKoefOdbitka := radn->klo
cRTipRada := g_tip_rada( ld->idradn, ld->idrj )

? cTprLine
? cLMSK+ Lokal(" Vrsta                  Opis         sati/iznos             ukupno")
? cTprLine

for i:=1 to cLDPolja
    
    cPom := padl(alltrim(str(i)),2,"0")
    
    select tippr
    seek cPom
    
    if tippr->(FIELDPOS("TPR_TIP")) <> 0
        // uzmi osnovice
        if tippr->tpr_tip == "N"
            nOsnNeto += _i&cPom
        elseif tippr->tpr_tip == "2"
            nOsnOstalo += _i&cPom
        elseif tippr->tpr_tip == " "
            // standardni tekuci sistem
            if tippr->uneto == "D"
                nOsnNeto += _i&cPom
            else
                nOsnOstalo += _i&cPom
            endif
        endif
    else
        // standardni tekuci sistem
        if tippr->uneto == "D"
            nOsnNeto += _i&cPom
        else
            nOsnOstalo += _i&cPom
        endif
    endif
    
    if tippr->uneto=="N" .and. cUneto=="D"
        
        cUneto := "N"
        
        ? cTprLine
        ? cLMSK+Lokal("Ukupna oporeziva primanja:")
        @ prow(),nC1+8  SAY  _USati  pict gpics
        ?? SPACE(1) + Lokal("sati")
        @ prow(),60+LEN(cLMSK) SAY _UNeto pict gpici
        ?? "",gValuta
        ? cTprLine
    
    endif
    
    if tippr->(found()) .and. tippr->aktivan=="D"

        if _i&cpom<>0 .or. _s&cPom<>0
    
            cTpNaz := tippr->naz

            ? cLMSK+tippr->id+"-"+padr(cTpNaz,len(tippr->naz)),tippr->opis
            nC1:=pcol()
            
            if tippr->fiksan $ "DN"
                
                @ prow(),pcol()+8 SAY _s&cPom  pict gpics
                ?? " s"
                @ prow(),60+LEN(cLMSK) say _i&cPom pict gpici
            
            elseif tippr->fiksan=="P"
                
                @ prow(),pcol()+8 SAY _s&cPom  pict "999.99%"
                @ prow(),60+LEN(cLMSK) say _i&cPom        pict gpici
            elseif tippr->fiksan=="B"
                
                @ prow(),pcol()+8 SAY _s&cPom  pict "999999"; ?? " b"
                @ prow(),60+LEN(cLMSK) say _i&cPom        pict gpici
            elseif tippr->fiksan=="C"
                
                @ prow(),60+LEN(cLMSK) say _i&cPom        pict gpici
            endif
        endif
    endif
next

select (F_POR)
    
if !used()
    O_POR
endif
    
select (F_DOPR)

if !used()
    O_DOPR
endif
    
select (F_KBENEF)
    
if !used()
    O_KBENEF
endif

nBO := 0
nBFO := 0
nBSaTr := 0
nTrosk := 0

nOsnZaBr := nOsnNeto
    
nBo := bruto_osn( nOsnZaBr, cRTipRada, nLicOdbitak )

// bruto placa iz neta...

? cMainLine
? cLMSK + "1. BRUTO NAKNADA :  ", bruto_isp( nOsnZaBr, cRTipRada, nLicOdbitak )

@ prow(),60+LEN(cLMSK) SAY nBo pict gpici
    
? cMainLine
    
?

// razrada doprinosa ....
? cLmSK + cDoprSpace + Lokal("Obracun doprinosa:")
    
select dopr
go top
    
nPom := 0
nDopr := 0
nUkDoprIz := 0
nC1 := 20 + LEN(cLMSK)
    
do while !eof()
    
    if dopr->tiprada <> "P"
        skip
        loop
    endif

    if dopr->(FIELDPOS("DOP_TIP")) <> 0
            
        if dopr->dop_tip == "N" .or. dopr->dop_tip == " " 
            nOsn := nOsnNeto
        elseif dopr->dop_tip == "2"
            nOsn := nOsnOstalo
        elseif dopr->dop_tip == "P"
            nOsn := nOsnNeto + nOsnOstalo
        endif
        
    endif
        
    PozicOps(DOPR->poopst)
    
    IF !ImaUOp("DOPR",DOPR->id) .or. !lPrikSveDopr .and. !DOPR->ID $ cPrikDopr
        SKIP 1
        LOOP
    ENDIF
        
    if right(id,1)=="X"
        ? cDoprLine
    endif
        
    ? cLMSK + cDoprSpace + id, "-", naz
    @ prow(),pcol()+1 SAY iznos pict "99.99%"
        
    if empty(idkbenef) 
        // doprinos udara na neto
        @ prow(),pcol()+1 SAY nBo pict gpici
        nC1:=pcol()+1
        @ prow(),pcol()+1 SAY nPom:=max(dlimit,round(iznos/100*nBO,gZaok2)) pict gpici
            
        if dopr->id == "1X"
            nUkDoprIz += nPom
        endif

    else
        nPom0:=ASCAN(_a_benef,{|x| x[1]==idkbenef})
        if nPom0<>0
            nPom2:=_a_benef[nPom0,3]
        else
            nPom2:=0
        endif
        if round(nPom2,gZaok2)<>0
            @ prow(),pcol()+1 SAY nPom2 pict gpici
            nC1:=pcol()+1
            nPom:=max(dlimit,round(iznos/100*nPom2,gZaok2))
            @ prow(),pcol()+1 SAY nPom pict gpici
        endif
    endif
        
    if right(id,1)=="X"
            
        ? cDoprLine
        ?
        nDopr += nPom
        
    endif
        
    if !lSkrivena .and. prow()>57+gPStranica
        FF
    endif
        
    skip 1
        
enddo


nOporDoh := nBo - nUkDoprIz

// oporezivi dohodak ......
    
? cMainLine
?  cLMSK + Lokal("2. NETO IZNOS NAKNADE ( bruto - dopr.IZ )")
@ prow(),60+LEN(cLMSK) SAY nOporDoh pict gpici

? cMainLine
    
nPorOsnovica := ( nOporDoh )
    
// ako je negativna onda je 0
if nPorOsnovica < 0
    nPorOsnovica := 0
endif

// razrada poreza na platu ....
// u ovom dijelu idu samo porezi na bruto TIP = "B"

? cLMSK + Lokal("3. AKONTACIJA POREZA NA DOHODAK")

select por
go top
    
nPom:=0
nPor:=0
nC1:=30 + LEN(cLMSK)
nPorOl:=0
    
do while !eof()
    
    // vrati algoritam poreza
    cAlgoritam := get_algoritam()
        
    PozicOps( POR->poopst )
        
    IF !ImaUOp("POR",POR->id)
        SKIP 1
        LOOP
    ENDIF
        
    // sracunaj samo poreze na bruto
    if por->por_tip <> "B"
        skip 
        loop
    endif
    
    // obracunaj porez
    aPor := obr_por( por->id, nPorOsnovica, 0 )
        
    // ispisi porez
    nPor += isp_por( aPor, cAlgoritam, cLMSK, .t., .t. )
        
    skip 1
enddo

@ prow(),60+LEN(cLMSK) SAY nPor pict gpici

// ukupno za isplatu ....
nZaIsplatu := ( nOporDoh - nPor ) 
    
?

? cMainLine
? cLMSK + Lokal("UKUPNO ZA ISPLATU ( 4 - 5 )")
@ prow(),60+LEN(cLMSK) SAY nZaIsplatu pict gpici

? cMainLine

if !lSkrivena .and. prow()>55+gPStranica
    FF
endif

?
    
// if prow()>31
if gPotp <> "D"
    if pcount()==0
        FF
    endif
endif
    

// potpis na kartici
kart_potpis()

// obrada sekvence za kraj papira

// skrivena kartica
if lSkrivena
    if prow()<nKRSK+5
        nPom:=nKRSK-PROW()
        FOR i:=1 TO nPom
            ?
        NEXT
    else
        FF
    endif
// 2 kartice na jedan list N - obavezno FF
elseif c2K1L == "N"
    FF
// ako je prikaz bruto D obavezno FF
elseif gPrBruto == "D"
    FF
// nova kartica novi list - obavezno FF
elseif lNKNS
    FF
// druga kartica takodjer FF
elseif (nRBRKart%2 == 0) 
    FF
// prva kartica, ali druga ne moze stati
elseif (nRBRKart%2 <> 0) .and. (DUZ_STRANA - prow() < nKRedova )
    --nRBRKart
    FF
endif

return


