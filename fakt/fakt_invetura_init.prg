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

#include "f18.ch"



FUNCTION TFrmInvItNew( oOwner )

   LOCAL oObj

   oObj := TFrmInvIt():new()
   oObj:oOwner := oOwner
   oObj:self := oObj
   oObj:lSilent := .F.
   oObj:lNovaStavka := .F.

   oObj:oOwner:lPartnerLoaded := .F.

   RETURN oObj





CREATE CLASS TFrmInvIt

   EXPORTED:
   VAR self
   VAR oOwner
   VAR lNovaStavka

   VAR nActionType
   VAR nCh
   VAR lSilent

   // form varijable
   VAR cIdRj
   VAR cIdVd
   VAR dDatDok
   VAR cBrDok
   VAR cValuta
   VAR cPartner
   VAR cMjesto
   VAR cAdresa
   VAR cValuta
   VAR nRbr
   VAR cIdRoba
   VAR nPKolicina
   VAR nKKolicina
   VAR nKKolPrijeEdita
   VAR nPKolicina
   VAR nCijena
   VAR nUkupno

   // caclulated values
   VAR nNaStanju

   METHOD newItem
   METHOD deleteItem
   METHOD open
   METHOD CLOSE
   METHOD nextItem
   METHOD loadFromTbl
   METHOD saveToTbl

   // when, validacija polja
   METHOD wheIdRoba
   METHOD vldIdRoba
   METHOD vldKKolicina
   METHOD wheKKolicina
   METHOD vldPKolicina
   METHOD vldRbr
   METHOD vldRj
   METHOD vldBrDok
   METHOD wheBrDok
   METHOD vldPartner
   METHOD whePartner
   METHOD getPartner
   METHOD sayPartner
   METHOD showArtikal

END CLASS



METHOD open()

   Box(, 20, 77 )
   SET CURSOR ON

   if ::lNovaStavka
      ::newItem()
   ELSE
      ::loadFromTbl()
   endif

   @ m_x + 1, Col() + 2   SAY " RJ:" GET ::cIdRj  PICT "@!" VALID ::vldRj()
   READ

   DO WHILE .T.
      @  m_x + 3, m_y + 40  SAY "Datum:"   GET ::dDatDok
      @  m_x + 3, m_y + Col() + 2  SAY "Broj:" GET ::cBrDok WHEN ::wheBrDok() VALID ::vldBrDok()

      if ::nRbr > 1
         ::sayPartner( 5 )
      ELSE
         ::getPartner( 5 )
      ENDIF

      @ m_x + 9, m_y + 2  SAY Valdomaca() + "/" + VAlPomocna() GET ::cValuta PICT "@!" VALID ::cValuta $ ValDomaca() + "#" + ValPomocna()

      READ
      ESC_RETURN 0
      IF fakt_dokument_postoji( ::cIdRj, ::cIdVd, ::cBrDok )
         MsgBeep( "Dokument vec postoji !!??" )
      ELSE
         EXIT
      ENDIF

   ENDDO

   @  m_x + 11, m_y + 2  SAY "R.br:" get ::nRbr PICTURE "9999"
   @  m_x + 11, Col() + 2  SAY "Artikal  " get ::cIdRoba PICT "@!S10" WHEN ::wheIdRoba() VALID ::vldIdRoba()
   @  m_x + 13, m_y + 2 SAY "Knjizna kolicina " GET ::nKKolicina PICT pickol WHEN ::wheKKolicina() VALID ::vldKKolicina()
   @  m_x + 13, Col() + 2 SAY "popisana kolicina " GET ::nPKolicina PICT pickol VALID ::vldPKolicina()

   READ

   IF ( LastKey() == K_ESC )
      RETURN 0
   ENDIF

   ::saveToTbl()

   RETURN 1


METHOD CLOSE

   BoxC()

   RETURN


METHOD newItem()

   SET ORDER TO TAG "1"
   SELECT fakt_pripr

   GO BOTTOM
   ::loadFromTbl()

   APPEND BLANK
   ++::nRbr

   ::cIdRoba := Space( Len( ::cIdRoba ) )
   ::nKKolicina := 0
   ::nPKolicina := 0
   ::nCijena := 0
   ::cIdVd := "IM"
   ::cIdRj := gFirma

   if ::nRbr == nil
      ::nRbr := 1
   ENDIF
   if ::nRbr < 2
      ::dDatDok := Date()
   ENDIF

   RETURN


METHOD deleteItem()

   my_delete_with_pack()

   RETURN


METHOD nextItem()

   SELECT fakt_pripr
   SKIP

   IF Eof()
      SKIP -1
      RETURN 0
   ENDIF
   ::loadFromTbl()

   RETURN 1



METHOD loadFromTbl()

   LOCAL aMemo

   SELECT fakt_pripr

   ::cIdRj := field->idFirma
   ::cIdVd := field->idTipDok
   ::cBrDok := field->brDok
   ::nRbr := RbrUNum( field->rBr )
   ::nPKolicina := field->kolicina
   ::cIdRoba := field->idRoba
   ::cValuta := field->dinDem
   ::dDatDok := field->datDok
   ::nKKolicina := Val( field->serBr )

   // partner nije ucitan
   IF !::oOwner:lPartnerLoaded
      if ::nRbr > 1
         // memo polje sa podacima partnera je popunjeno samo u prvoj stavci
         PushWA()
         GO TOP
      ENDIF
      aMemo := ParsMemo( field->txt )
      ::cPartner := ""
      ::cMjesto := ""
      ::cAdresa := ""
      IF Len( aMemo ) >= 5
         ::cPartner := aMemo[ 3 ]
         ::cAdresa := aMemo[ 4 ]
         ::cMjesto := aMemo[ 5 ]
      ENDIF
      ::oOwner:lPartnerLoaded := .T.
      if ::nRbr > 1
         PopWa()
      ENDIF
   ENDIF

   RETURN



METHOD saveToTbl()

   LOCAL cTxt

   SELECT fakt_pripr

   REPLACE idFirma WITH ::cIdRj
   REPLACE idTipDok WITH ::cIdVd
   REPLACE rBr WITH RedniBroj( ::nRbr, 3 )
   REPLACE kolicina WITH ::nPKolicina
   REPLACE idRoba WITH ::cIdRoba
   REPLACE brDok WITH ::cBrDok
   REPLACE dinDem WITH ::cValuta
   cTxt := ""
   AddTxt( @cTxt, "" )
   AddTxt( @cTxt, "" )
   AddTxt( @cTxt, ::cPartner )
   AddTxt( @cTxt, ::cAdresa )
   AddTxt( @cTxt, ::cMjesto )
   REPLACE txt WITH cTxt
   REPLACE serBr WITH Str( ::nKKolicina, 15, 4 )
   REPLACE datDok WITH ::dDatDok

   RETURN

STATIC FUNCTION AddTxt( cTxt, cStr )

   cTxt := cTxt + Chr( 16 ) + cStr + Chr( 17 )

   RETURN NIL

/* TFrmInvIt::vIdRj()
 *     Validacija radne jedinice
 */
METHOD vldRj()

   LOCAL cPom

   IF Empty( ::cIdRj )
      RETURN .F.
   ENDIF
   if ::cIdRj == gFirma
      RETURN .T.
   ENDIF

   cPom := ::cIdRj
   P_RJ( @cPom )
   ::cIdRj := cPom

   RETURN .T.

METHOD wheBrDok()
   RETURN .T.


METHOD vldRbr()
   RETURN .F.


METHOD vldBrDok()

   IF !Empty( ::cBrDok )
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF

/* TFrmInvIt::vldIdRoba()
 *     validacija IdRoba
 */

METHOD vldIdRoba()

   // {
   LOCAL cPom

   IF Len( Trim( ::cIdRoba ) ) < 10
      ::cIdroba := Left( ::cIdRoba, 10 )
   ENDIF

   cPom := ::cIdRoba
   P_Roba( @cPom )
   ::cIdRoba := cPom

   if ::lSilent
      @ m_x + 14, m_y + 28 SAY "TBr: "
      ?? roba->idtarifa, "PPP", Str( tarifa->opp, 7, 2 ) + "%", "PPU", Str( tarifa->ppp, 7, 2 )
   ENDIF

   SELECT fakt_pripr

   RETURN .T.
// }


/* TFrmInvIt::wheIdRoba()
 *     When (pred ulazak u) IdRoba
 */
METHOD wheIdRoba()

   PRIVATE GetList

   ::cIdRoba := PadR( ::cIdroba, goModul:nDuzinaSifre )

   RETURN .T.


/* TFrmInvIt::getPartner(int nRow)
 *     Uzmi Podatke partnera
 */
METHOD getPartner( nRow )

   @  m_x + nRow, m_y + 2  SAY "Partner " get ::cPartner  PICTURE "@S30" WHEN ::whePartner() VALID ::vldPartner()
   @  m_x + nRow + 1, m_y + 2  SAY "        " get ::cAdresa  PICTURE "@"
   @  m_x + nRow + 2, m_y + 2  SAY "Mjesto  " get ::cMjesto  PICTURE "@"

   RETURN

/* TFrmInvIt::sayPartner(int nRow)
 *     Odstampaj podatke o partneru
 */

// void TFrmInvIt::sayPartner(int nRow)
// {
METHOD sayPartner( nRow )

   @  m_x + nRow, m_y + 2  SAY "Partner "
   ??::cPartner
   @  m_x + nRow + 1, m_y + 2  SAY "        "
   ?? ::cAdresa
   @  m_x + nRow + 2, m_y + 2  SAY "Mjesto  "
   ?? ::cMjesto

   RETURN
// }

/* TFrmInvIt::whePartner()
 *     When Partner polja
 */
METHOD whePartner()

   // {

   ::cPartner := PadR( ::cPartner, 30 )
   ::cAdresa := PadR( ::cAdresa, 30 )
   ::cMjesto := PadR( ::cMjesto, 30 )

   RETURN .T.
// }

/* TFrmInvIt::vldPartner()
 *     Validacija nakon unosa Partner polja - vidi je li sifra
 */
METHOD vldPartner()

   // {
   LOCAL cSif
   LOCAL nPos

   cSif := Trim( ::cPartner )

   IF ( Right( cSif, 1 ) = "." .AND. Len( csif ) <= 7 )
      nPos := RAt( ".", cSif )
      cSif := Left( cSif, nPos - 1 )
      P_Firma( PadR( cSif, 6 ) )
      ::cPartner := PadR( partn->naz, 30 )

      IF my_get_from_ini( 'FAKT', 'NaslovPartnTelefon', 'D' ) == "D"
         ::cMjesto := ::cMjesto + ", Tel:" + Trim( partn->telefon )
      ENDIF

      ::cAdresa := PadR( partn->adresa, 30 )
      ::cMjesto := PadR( partn->mjesto, 30 )

   ENDIF

   RETURN  .T.
// }


/* TFrmInvIt::vldPKolicina()
 *     Validacija Popisane Kolicine
 */

METHOD vldPKolicina()

   // {
   LOCAL cRjTip
   LOCAL nUl
   LOCAL nIzl
   LOCAL nRezerv
   LOCAL nRevers

   RETURN .T.


/* TFrmInvIt::vldKKolicina()
 *     Validacija Knjizne Kolicine
 */
METHOD vldKKolicina()

   if ::nKKolPrijeEdita <> ::nKKolicina
      MsgBeep( "Zasto mjenjate knjiznu kolicinu ??" )
      IF Pitanje(, "Ipak to zelite uciniti ?", "N" ) == "N"
         ::nKKolicina := ::nKKolPrijeEdita
      ENDIF
   ENDIF

   RETURN .T.


/* TFrmInvIt::wheKKolicina()
 *     Prije ulaska u polje Knjizne Kolicine
 */
METHOD wheKKolicina()

   ::nKKolPrijeEdita := ::nKKolicina

   RETURN .T.

/* TFrmInvIt::showArtikal()
 *     Pokazi podatke o artiklu na formi ItemInventure
 */

METHOD showArtikal()

   @ m_x + 17, m_y + 1   SAY "Artikal: "
   ?? ::cIdRoba
   ?? "(" + roba->jmj + ")"

   @ m_x + 18, m_y + 1   SAY "Stanje :"
   @ m_x + 18, Col() + 1 SAY ::nNaStanju PICTURE pickol

   @ m_x + 19, m_y + 1   SAY "Tarifa : "
   ?? roba->idtarifa

   RETURN
