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


#include "f18.ch"


FUNCTION ld_platni_spisak()

   LOCAL nC1 := 20
   LOCAL cVarSort := "2"
   LOCAL lSviRadnici := .F.
   LOCAL cSviRadn := "N"
   LOCAL GetList := {}

   cIdRadn := Space( LEN_IDRADNIK )
   cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cObracun := gObracun

   o_ld_rj()
   o_ld_radn()
   // select_o_ld()

   cProred := "N"
   cPrikIzn := "D"
   nProcenat := 100
   nZkk := gZaok
   cDrugiDio := "D"
   cNaslov := ""
   // ISPLATA PLATA
   cNaslovTO := ""
   // ISPLATA TOPLOG OBROKA
   nIznosTO := 0
   // export za banku
   cZaBanku := "N"

   // uzmi parametre iz sql/db
   cVarSort := fetch_metric( "ld_platni_spisak_sortiranje", my_user(), cVarSort )
   cNaslov := fetch_metric( "ld_platni_spisak_naslov", my_user(), cNaslov )
   cNaslov := PadR( cNaslov, 90 )
   cNaslovTO := fetch_metric( "ld_platni_spisak_naslov_to", my_user(), cNaslovTO )
   cNaslovTO := PadR( cNaslovTO, 90 )

   Box(, 13, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve): "  GET cIdRJ
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Mjesec: "  GET  nMjesec  PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY "Obracun: "  GET  cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: "  GET  nGodina  PICT "9999"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prored:"   GET  cProred  PICT "@!"  VALID cProred $ "DN"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz iznosa:" GET cPrikIzn PICT "@!" VALID cPrikizn $ "DN"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Prikaz u procentu %:" GET nprocenat PICT "999.99"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Sortirati po (1-sifri,2-prezime+ime)"  GET cVarSort VALID cVarSort $ "12"  PICT "9"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Naslov izvjestaja"  GET cNaslov PICT "@S30"
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Naslov za topl.obrok"  GET cNaslovTO PICT "@S30"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Iznos (samo za topli obrok)"  GET nIznosTO PICT gPicI
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Izlistati sve radnike (D/N)"  GET cSviRadn PICT "@!" VALID cSviRadn $ "DN"

   READ

   clvbox()
   ESC_BCR
   IF nProcenat <> 100

      @ box_x_koord() + 12, box_y_koord() + 2 SAY "zaokruzenje" GET nZkk PICT "99"
      @ box_x_koord() + 13, box_y_koord() + 2 SAY "Prikazati i drugi spisak (za " + LTrim( Str( 100 - nProcenat, 6, 2 ) ) + "%-tni dio)" GET cDrugiDio VALID cDrugiDio $ "DN" PICT "@!"

      READ
   ELSE
      cDrugiDio := "N"
   ENDIF

   BoxC()

   // snimi parametre u sql/db
   set_metric( "ld_platni_spisak_sortiranje", my_user(), cVarSort )
   set_metric( "ld_platni_spisak_naslov", my_user(), cNaslov )
   cNaslov := AllTrim( cNaslov )
   set_metric( "ld_platni_spisak_naslov_to", my_user(), cNaslovTO )
   cNaslovTO := AllTrim( cNaslovTO )

   IF cSviRadn == "D"
      lSviRadnici := .T.
   ENDIF

   IF nIznosTO <> 0
      cNaslov := cNaslovTO
      qqImaTO := my_get_from_ini( "LD", "UslovImaTopliObrok", 'UPPER(RADN->K2)=="D"', KUMPATH )
   ENDIF

   IF !Empty( cNaslov )
      cNaslov += ( Space( 1 ) + _l( "za mjesec:" ) + Str( nMjesec, 2 ) + ". " + _l( "godine:" ) + Str( nGodina, 4 ) + "." )
   ENDIF

   // SELECT ld
   // CREATE_INDEX("LDi1","str(godina)+idrj+str(mjesec)+idradn","LD")
   // CREATE_INDEX("LDi2","str(godina)+str(mjesec)+idradn","LD")

   cObracun := Trim( cObracun )

   IF Empty( cIdRj )
      cIdRj := ""
      IF cVarSort == "1"
         // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
         // HSEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun
         seek_ld_2( NIL, nGodina, nMjesec, cObracun )

      ELSE
         seek_ld_2( cIdRj, nGodina, nMjesec, cObracun )
         Box(, 2, 30 )
         nSlog := 0
         cSort1 := "SortPrez(IDRADN)"
         cFilt := iif( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + ;
            iif( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
         cFilt += ".and. obr==" + _filter_quote( cObracun )
         INDEX ON &cSort1 TO "tmpld" FOR &cFilt
         BoxC()
         GO TOP
      ENDIF
   ELSE

      IF cVarSort == "1"
         // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "1" ) )
         // HSEEK Str( nGodina, 4 ) + cidrj + Str( nMjesec, 2 ) + cObracun
         seek_ld( cIdRj, nGodina, nMjesec, cObracun )
      ELSE
         seek_ld( cIdRj, nGodina, nMjesec, cObracun )
         Box(, 2, 30 )
         nSlog := 0
         cSort1 := "SortPrez(IDRADN)"
         cFilt := "IDRJ==cIdRj.and." + ;
            IF( Empty( nMjesec ), ".t.", "MJESEC==" + _filter_quote( nMjesec ) ) + ".and." + ;
            IF( Empty( nGodina ), ".t.", "GODINA==" + _filter_quote( nGodina ) )
         cFilt += ".and. obr=" + _filter_quote( cObracun )
         INDEX ON &cSort1 TO "tmpld" FOR &cFilt
         BoxC()
         GO TOP
      ENDIF
   ENDIF

   EOF CRET

   nStrana := 0

   m := "----- " + Replicate( "-", LEN_IDRADNIK ) + " ----------------------------------- ----------- -------------------------"
   bZagl := {|| ZPlatSp() }

   select_o_ld_rj( ld->idrj )
   SELECT ld

   START PRINT CRET

   nPocRec := RecNo()

   FOR nDio := 1 TO IF( cDrugiDio == "D", 2, 1 )

      IF nDio == 2
         GO ( nPocRec )
      ENDIF

      Eval( bZagl )

      nT1 := nT2 := nT3 := nT4 := 0
      nRbr := 0

      DO WHILE !Eof() .AND.  nGodina == godina .AND. idrj = cidrj .AND. nMjesec = mjesec .AND. !( ld_vise_obracuna() .AND. !Empty( cObracun ) .AND. obr <> cObracun )

         IF ld_vise_obracuna() .AND. Empty( cObracun )
            ScatterS( godina, mjesec, idrj, idradn )
         ELSE
            Scatter()
         ENDIF

         select_o_radn( _idradn )

         SELECT ld

         IF nIznosTO = 0
            // isplata plate
            IF !lSviRadnici .AND. !( Empty( radn->isplata ) .OR. radn->isplata = "BL" )
               SKIP
               LOOP
            ENDIF
         ELSE
            // isplata toplog obroka
            IF !( &qqImaTO )
               SKIP
               LOOP
            ENDIF
         ENDIF

         ? Str( ++nRbr, 4 ) + ".", idradn, RADNIK_PREZ_IME

         nC1 := PCol() + 1
         IF nIznosTO <> 0
            _uiznos := nIznosTO
         ENDIF
         IF cprikizn == "D"
            IF nProcenat <> 100
               IF nDio == 1
                  @ PRow(), PCol() + 1 SAY Round( _uiznos * nprocenat / 100, nzkk ) PICT gpici
               ELSE
                  @ PRow(), PCol() + 1 SAY Round( _uiznos, nzkk ) - Round( _uiznos * nprocenat / 100, nzkk ) PICT gpici
               ENDIF
            ELSE
               @ PRow(), PCol() + 1 SAY _uiznos PICT gpici
            ENDIF
         ELSE
            @ PRow(), PCol() + 1 SAY Space( Len( gpici ) )
         ENDIF

         @ PRow(), PCol() + 4 SAY Replicate( "_", 22 )

         IF cProred == "D"
            ?
         ENDIF

         nT1 += _usati
         nT2 += _uneto
         nT3 += _uodbici

         IF nProcenat <> 100
            IF nDio == 1
               nT4 += Round( _uiznos * nprocenat / 100, nzkk )
            ELSE
               nT4 += ( Round( _uiznos, nzkk ) - Round( _uiznos * nprocenat / 100, nzkk ) )
            ENDIF
         ELSE
            nT4 += _uiznos
         ENDIF

         SKIP
      ENDDO


      ? m
      ? Space( 1 ) + _l( "UKUPNO:" )

      IF cPrikIzn == "D"
         @ PRow(), nC1 SAY nT4 PICT gpici
      ENDIF

      ? m

      ? p_potpis()

      FF

   NEXT


   ENDPRINT

   my_close_all_dbf()

   RETURN .T.




FUNCTION ZPlatSp()

   ?
   P_12CPI

   ? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?

   IF Empty( cidrj )
      ? _l( "Pregled za sve RJ ukupno:" )
   ELSE
      ? _l( "RJ:" ), cIdRj, ld_rj->naz
   ENDIF

   ?? Space( 2 ) + _l( "Mjesec:" ), Str( nMjesec, 2 ) + IspisObr()
   ?? Space( 4 ) + _l( "Godina:" ), Str( nGodina, 5 )
   DevPos( PRow(), 74 )
   ?? _l( "Str." ), Str( ++nStrana, 3 )
   ?

   IF !Empty( cNaslov )
      ? PadC( AllTrim( cNaslov ), 90 )
      ? PadC( REPL( "-", Len( AllTrim( cNaslov ) ) ), 90 )
   ENDIF

   IF nProcenat <> 100
      ?
      ? _l( "Procenat za isplatu:" )
      IF nDio == 1
         @ PRow(), PCol() + 1 SAY nprocenat PICT "999.99%"
      ELSE
         @ PRow(), PCol() + 1 SAY 100 - nprocenat PICT "999.99%"
      ENDIF
      ?
   ENDIF

   ? m
   ? _l( "Rbr   Sifra           Naziv radnika               " ) + iif( cPrikIzn == "D", _l( "ZA ISPLATU" ), "          " ) + "         " + _l( "Potpis" )
   ? m

   RETURN .T.





// ----------------------------------------------
// formatiranje stringa ....
// ----------------------------------------------
FUNCTION FormatSTR( cString, nLen, lLeft, cFill )

   IF lLeft == nil
      lLeft := .F.
   ENDIF

   IF cFill == nil
      cFill := "0"
   ENDIF

   // formatiraj string na odredjenu duzinu
   cRet := PadR( cString, nLen )

   // zamjeni "." -> ","
   cRet := StrTran( cRet, ".", "," )

   IF lLeft == .T.
      cRet := PadL( AllTrim( cRet ), nLen, cFill )
   ENDIF

   RETURN cRet


// -----------------------------------------
// kreiranje fajla za eksport
// -----------------------------------------
FUNCTION CreateFileBanka( banka )

   LOCAL _file_name := ""

   IF banka == NIL .OR. Empty( banka )
      _file_name := "to.txt"
   ELSE
      _file_name := "to_" + AllTrim( banka ) + ".txt"
   ENDIF

   Box(, 5, 70 )

   cLokacija := PadR( my_home() + _file_name, 300 )
   cConstBrojTR := "56480 "
   cParKonv := "5"

   @ 1 + box_x_koord(), 2 + box_y_koord() SAY "PARAMETRI ***"
   @ 3 + box_x_koord(), 2 + box_y_koord() SAY "Sifra isplatioca tek.rac:" GET cConstBrojTR
   @ 4 + box_x_koord(), 2 + box_y_koord() SAY "Naziv fajla prenosa:" GET cLokacija PICT "@S30"
   @ 5 + box_x_koord(), 2 + box_y_koord() SAY "Konverzija znakova:" GET cParKonv

   READ

   BoxC()

   cConstBrojTR := FormatSTR( AllTrim( cConstBrojTR ), 6 )
   cLokacija := AllTrim( cLokacija )

   nH := FCreate( cLokacija )

   IF nH == -1
      MsgBeep( "Greska pri kreiranju fajla !" )
      RETURN
   ENDIF

   RETURN .T.



FUNCTION CloseFileBanka( nHnd )

   FClose( nHnd )

   RETURN .T.
