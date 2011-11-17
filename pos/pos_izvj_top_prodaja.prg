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


function pos_top_narudzbe()
*{
LOCAL   aNiz := {}, cPor, cZaduz, aVrsteP
PRIVATE cIdPos, cRoba:=SPACE(60), dDat0, dDat1, nTop := 10, cSta := "I"
dDat0 := dDat1 := DATE ()

if IsPlanika()
	cPrikOnlyPar:="D"
endif

O_ODJ
O_KASE
O_SIFK
O_SIFV
O_ROBA
O_POS
O_POS_DOKS

aDbf := {}
AADD (aDbf, {"IdRoba",   "C", 10, 0})
AADD (aDbf, {"Kolicina", "N", 15, 3})
AADD (aDbf, {"Iznos",    "N", 20, 3})
AADD (aDbf, {"Iznos2",    "N", 20, 3})
AADD (aDbf, {"Iznos3",    "N", 20, 3})
NaprPom (aDbf)

my_use("pom", .t., "NEW")
index on IdRoba TAG ("1") to (PRIVPATH+"POM")
index on Descend (Str (Iznos,20,3)) TAG ("2") to (PRIVPATH+"POM")
index on Descend (Str (Kolicina,15,3)) TAG ("3") to (PRIVPATH+"POM")
index ON BRISANO TAG "BRISAN"
set order to 1

private cIdPOS := gIdPos
IF gVrstaRS <> "K"
  aNiz := { {"Prodajno mjesto","cIdPos","cidpos='X' .or. Empty(cIdPos).or.P_Kase(@cIdPos)",,} }
ENDIF
AADD (aNiz, {"Roba (prazno-sve)","cRoba",,"@!S30",})
AADD (aNiz, {"Pregled po Iznosu/Kolicini/Oboje (I/K/O)","cSta","cSta$'IKO'","@!",})
AADD (aNiz, {"Izvjestaj se pravi od datuma","dDat0",,,})
AADD (aNiz, {"                   do datuma","dDat1",,,})
AADD (aNiz, {"Koliko artikala ispisati?","nTop","nTop > 0",,})
if IsPlanika()
	AADD (aNiz, {"Prikazati samo artikle sa JMJ='PAR' (D/N) ?","cPrikOnlyPar","cPrikOnlyPar$'DN'","@!",})
endif
DO WHILE .t.
  IF !VarEdit(aNiz, 10,5,19,74,;
              'USLOVI ZA IZVJESTAJ "NAJPROMETNIJI ARTIKLI"',;
              "B1")
    CLOSERET
  ENDIF
  aUsl1:=Parsiraj(cRoba,"IdRoba","C")
  if aUsl1<>NIL.and.dDat0<=dDat1
    exit
  elseif aUsl1==NIL
    Msg("Kriterij za robu nije korektno postavljen!")
  else
    Msg("'Datum do' ne smije biti stariji nego 'datum od'!")
  endif
ENDDO // .t.

nTotal := 0

SELECT POS
IF !(aUsl1==".t.")
  set filter to &aUsl1
ENDIF

select pos_doks
set order to 2        // IdVd+DTOS (Datum)+Smjena

START PRINT CRET

ZagFirma()

? PADC ("NAJPROMETNIJI ARTIKLI", 40)
? padc ("-----------------------", 40)
? padc ("NA DAN: "+FormDat1 (gDatum), 40)
?
? PADC ("Za period od "+FormDat1 (dDat0)+ " do "+FormDat1 (dDat1), 40)
if IsPlanika() .and. cPrikOnlyPar=="D"
	? "Artikli kod kojih je JMJ='PAR'"
endif
?

TopNizvuci (VD_RN, dDat0)
TopNizvuci (VD_PRR, dDat0)

// stampa izvjestaja
SELECT POM
IF cSta $ "IO"
  ?
  ? PADC ("POREDAK PO IZNOSU", 40)
  ?
  ? PADR("ID ROBA", 10), PADR ("Naziv robe", 20), PADC ("Vrijednost ("+AllTrim(gDomValuta)+")",19)
  ? REPL("-", 10), REPL ("-", 20), REPL ("-", 19)
  nCnt := 1
  Set order to 2
  GO TOP
  WHILE ! Eof() .and. nCnt <= nTop
    select roba
    HSEEK POM->IdRoba
    if IsPlanika() .and. cPrikOnlyPar=="D" .and. roba->jmj<>"PAR" 
    	select POM
	skip
	loop
    endif
    ? roba->Id, LEFT (roba->Naz, 20), STR (POM->Iznos, 19, 2)
    SELECT POM
    nCnt ++
    SKIP
  END
ENDIF

IF cSta $ "KO"
  SELECT POM
  ?
  ? PADC ("POREDAK PO KOLICINI", 40)
  ?
  ? PADR("ID ROBA", 10), PADR ("Naziv robe", 20), PADC ("Kolicina",15)
  ? REPL("-", 10), REPL ("-", 20), REPL ("-", 15)
  nCnt := 1
  Set order to 3
  GO TOP
  WHILE ! Eof() .and. nCnt <= nTop
    select roba
    HSEEK POM->IdRoba
    if IsPlanika() .and. cPrikOnlyPar=="D" .and. roba->jmj<>"PAR" 
    	select POM
	skip
	loop
    endif
    ? roba->Id, LEFT (roba->Naz, 20), STR (POM->Kolicina, 15, 3)
    SELECT POM
    nCnt ++
    SKIP
  END
ENDIF
?
IF gVrstaRS == "K"
  PaperFeed ()
ENDIF
END PRINT
CLOSERET
*}


/*! \fn TopNizvuci(cIdVd,dDat0)
 *  \brief Punjenje pomocne baze realizacijom po robama
 */

function TopNizvuci(cIdVd,dDat0)
*{
  select pos_doks
  Seek cIdVd+DTOS (dDat0)
  do While !Eof() .and. pos_doks->IdVd==cIdVd .and. pos_doks->Datum <= dDat1

    IF (Klevel>"0" .and. pos_doks->idpos="X") .or. ;
        (pos_doks->IdPos="X" .and. AllTrim(cIdPos)<>"X") .or. ;
        (!Empty(cIdPos) .and. pos_doks->IdPos<>cIdPos)
       Skip; Loop
    EndIF


    SELECT POS
    Seek pos_doks->(IdPos+IdVd+dtos(datum)+BrDok)
    While !Eof() .and. POS->(IdPos+IdVd+dtos(datum)+BrDok)==pos_doks->(IdPos+IdVd+dtos(datum)+BrDok)

      select roba; hseek pos->idroba
      select odj; hseek roba->idodj
      nNeplaca:=0
      if right(odj->naz,5)=="#1#0#"  // proba!!!
       nNeplaca:=pos->(Kolicina*Cijena)
      elseif right(odj->naz,6)=="#1#50#"
       nNeplaca:=pos->(Kolicina*Cijena)/2
      endif
      if gPopVar="P"; nNeplaca+=pos->(kolicina*NCijena); endif

      SELECT POM ; Hseek POS->IdRoba
      IF !FOUND ()
        APPEND BLANK
        REPLACE IdRoba   WITH POS->IdRoba, ;
                Kolicina WITH POS->Kolicina, ;
                Iznos    WITH POS->Kolicina*POS->Cijena,;
                iznos3   with nNeplaca
         if gPopVar=="P"
                replace iznos2   with pos->ncijena*pos->kolicina
         endif
      ELSE
        REPLACE Kolicina WITH Kolicina+POS->Kolicina, ;
                Iznos WITH Iznos+POS->Kolicina*POS->Cijena,;
                iznos3 with iznos3+nNePlaca
       if gPopVar=="P"
                replace iznos2   with iznos2 + pos->ncijena*pos->kolicina
       endif
      END
      SELECT POS
      SKIP
    EndDO
    select pos_doks
    SKIP
  EndDO
return
*}


