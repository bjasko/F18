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
#include "cre_all.ch"



FUNCTION ld_specifikacija_po_rj()

   cGodina  := gGodina
   cMjesecOd := cMjesecDo := gMjesec
   cObracun := " "
   qqRj := ""
   qqPrimanja := ""

   O_PARAMS
   PRIVATE cSection := "5", cHistory := " ", aHistory := {}

   cMjesecOd := Str( cMjesecOd, 2 )
   cMjesecDo := Str( cMjesecDo, 2 )
   cGodina   := Str( cGodina,4 )

   RPar( "p1", @cMjesecOd )
   RPar( "p2", @cMjesecDo )
   RPar( "p3", @cGodina   )
   RPar( "p8", @qqRj      )
   RPar( "p9", @cObracun  )
   RPar( "pA", @qqPrimanja )

   cMjesecOd := Val( cMjesecOd )
   cMjesecDo := Val( cMjesecDo )
   cGodina   := Val( cGodina  )
   qqRj      := PadR( qqRj, 40 )
   qqPrimanja := PadR( qqPrimanja, 100 )

   DO WHILE .T.
      Box( "#Uslovi za specifikaciju primanja po radnim jedinicama", 8, 75 )
      @ m_x + 2, m_y + 2   SAY "Radne jedinice (prazno-sve): "   GET qqRj PICT "@S20"
      @ m_x + 3, m_y + 2   SAY "Mjesec od: "                     GET cMjesecOd PICT "99"
      @ m_x + 3, Col() + 2 SAY "do"                              GET cMjesecDo PICT "99"
      @ m_x + 4, m_y + 2   SAY "Godina: "                        GET cGodina   PICT "9999"
      IF lViseObr
         @ m_x + 4, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN HelpObr( .T., cObracun ) VALID ValObr( .T., cObracun )
      ENDIF
      @ m_x + 5, m_y + 2   SAY8 "Šifre primanja (prazno-sve):"   GET qqPrimanja PICT "@S30"
      READ
      ESC_BCR
      BoxC()
      aUslRJ   := Parsiraj( qqRj, "IDRJ" )
      aUslPrim := Parsiraj( qqPrimanja, "cIDPRIM" )
      IF aUslRJ <> NIL
         EXIT
      ENDIF
   ENDDO

   cMjesecOd := Str( cMjesecOd, 2 )
   cMjesecDo := Str( cMjesecDo, 2 )
   cGodina   := Str( cGodina,4 )
   qqRj      := Trim( qqRj )
   qqPrimanja := Trim( qqPrimanja )

   WPar( "p1", cMjesecOd )
   WPar( "p2", cMjesecDo )
   WPar( "p3", cGodina   )
   WPar( "p8", qqRj      )
   RPar( "p9", cObracun  )
   WPar( "pA", qqPrimanja )

   SELECT PARAMS
   USE

   cMjesecOd := Val( cMjesecOd )
   cMjesecDo := Val( cMjesecDo )
   cGodina   := Val( cGodina  )

   napravi_pomocnu_tabelu()

   otvori_tabele()

   zapuj_pomocnu_tabelu()

   aPrim  := {}       // standardna primanja
   aPrimK := {}       // primanja kao npr. krediti

   SELECT tippr

   FOR i := 1 TO cLDPolja
      cIDPRIM := PadL( AllTrim( Str( i ) ), 2, "0" )
      IF &aUslPrim
         IF "SUMKREDITA" $ Ocitaj( F_TIPPR, cIdPrim, "formula" )
            AAdd( aPrimK, "I" + cIdPrim )
         ELSE
            AAdd( aPrim, "I" + cIdPrim )
         ENDIF
      ENDIF
   NEXT

   PRIVATE cFilt := ".t."
   IF !Empty( qqRJ )    ; cFilt += ( ".and." + aUslRJ )                ; ENDIF
   IF !Empty( cObracun ); cFilt += ( ".and. OBR==" + cm2str( cObracun ) ); ENDIF
   IF cMjesecOd != cMjesecDo
      cFilt := cFilt + ".and.mjesec>=" + cm2str( cMjesecOd ) + ;
         ".and.mjesec<=" + cm2str( cMjesecDo ) + ;
         ".and.godina=" + cm2str( cGodina )
   ELSE
      cFilt := cFilt + ".and.mjesec=" + cm2str( cMjesecOd ) + ;
         ".and.godina=" + cm2str( cGodina )
   ENDIF

   SELECT LD
   SET FILTER TO &cFilt
   GO TOP
   aRJ := {}
   DO WHILE !Eof()
      FOR i := 1 TO Len( aPrim )
         SELECT LD; nPom := &( aPrim[ i ] )
         SELECT LDT22; SEEK Right( aPrim[ i ], 2 ) + Space( 6 ) + LD->IDRJ
         IF Found()
            RREPLACE iznos WITH iznos + nPom
         ELSE
            APPEND BLANK
            REPLACE idprim  WITH Right( aPrim[ i ], 2 ), ;
               idkred  WITH Space( 6 ),;
               idrj    WITH LD->IDRJ,;
               iznos   WITH iznos + nPom
            IF AScan( aRJ, {| x| x[ 1 ] == idrj } ) <= 0
               AAdd( aRJ, { idrj, 0 } )
            ENDIF
         ENDIF
         SELECT LD
      NEXT
      FOR i := 1 TO Len( aPrimK )
         SELECT LD; cKljuc := Str( godina, 4 ) + Str( mjesec, 2 ) + idradn
         SELECT RADKR; SEEK cKljuc
         IF Found()
            DO WHILE !Eof() .AND. Str( godina, 4 ) + Str( mjesec, 2 ) + idradn == cKljuc
               cIdKred := idkred
               nPom := 0
               DO WHILE !Eof() .AND. Str( godina, 4 ) + Str( mjesec, 2 ) + idradn + idkred == cKljuc + cIdKred
                  nPom += placeno
                  SKIP 1
               ENDDO
               nPom := -nPom      // kredit je odbitak
               SELECT LDT22; SEEK Right( aPrimK[ i ], 2 ) + cIdKred + LD->IDRJ
               IF Found()
                  RREPLACE iznos WITH iznos + nPom
               ELSE
                  APPEND BLANK
                  REPLACE idprim  WITH Right( aPrimK[ i ], 2 ), ;
                     idkred  WITH cIdKred,;
                     idrj    WITH LD->IDRJ,;
                     iznos   WITH iznos + nPom
                  IF AScan( aRJ, {| x| x[ 1 ] == idrj } ) <= 0
                     AAdd( aRJ, { idrj, 0 } )
                  ENDIF
               ENDIF
               SELECT RADKR
            ENDDO
         ENDIF
      NEXT
      SELECT ld
      SKIP 1
   ENDDO

   START PRINT CRET
   gOstr := "D"; gTabela := 1
   cPrimanje := ""; nUkupno := 0
   nKol := 0

   aKol := { { "PRIMANJE", {|| cPrimanje }, .F., "C", 40, 0, 1, ++nKol } }

   // radne jedinice
   ASort( aRJ,,, {| x, y| x[ 1 ] < y[ 1 ] } )
   FOR i := 1 TO Len( aRJ )
      cPom := AllTrim( Str( i ) )
      AAdd( aKol, { "RJ " + aRJ[ i, 1 ], {|| aRJ[ &cPom., 2 ] }, .T., "N", 15, 2, 1, ++nKol  } )
   NEXT

   // ukupno
   AAdd( aKol, { "UKUPNO", {|| nUkupno }, .T., "N", 15, 2, 1, ++nKol } )

   P_10CPI
   ?? gnFirma
   ?
   ? "Mjesec: od", Str( cMjesecOd, 2 ) + ".", "do", Str( cMjesecDo, 2 ) + "."
   ?? "    Godina:", Str( cGodina, 4 )
   ?U "Obuhvaćene radne jedinice  :", IF( !Empty( qqRJ ), "'" + qqRj + "'", "SVE" )
   ?U "Obuhvaćena primanja (šifre):", "'" + qqPrimanja + "'"
   ?

   SELECT LDT22
   GO TOP

   StampaTabele( aKol,,, gTabela,, ;
      , "SPECIFIKACIJA PRIMANJA PO RADNIM JEDINICAMA", ;
      {|| formula_izvjestaja() }, IF( gOstr == "D",, -1 ),,,,, )

   FF
   END PRINT

   my_close_all_dbf()

   RETURN




STATIC FUNCTION zapuj_pomocnu_tabelu()

   SELECT ldt22
   my_dbf_zap()

   RETURN



STATIC FUNCTION otvori_tabele()

   O_TIPPR
   O_KRED
   O_RADKR
   SET ORDER TO TAG "1"
   O_LD_RJ
   O_RADN
   O_LD
   O_LDT22
   SET ORDER TO TAG "1"

   SELECT ld

   RETURN



STATIC FUNCTION napravi_pomocnu_tabelu()

   LOCAL _alias, _table_name, aDbf

   _alias := "LDT22"
   _table_name := "ldt22"

   aDbf := {    { "IDPRIM",  "C",  2, 0 },;
      { "IDKRED",  "C",  6, 0 },;
      { "IDRJ",  "C",  2, 0 },;
      { "IZNOS",  "N", 18, 4 } ;
      }

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idprim+idkred+idrj", _alias )

   RETURN



STATIC FUNCTION formula_izvjestaja()

   LOCAL i, nPos, cIdPrim, cIdKred, cIdRj

   IF Empty( idkred )
      cPrimanje := idprim + "-" + Ocitaj( F_TIPPR, idprim, "naz" )
   ELSE
      cPrimanje := idprim + "-" + idkred + "-" + Ocitaj( F_KRED, idkred, "naz" )
   ENDIF
   cIdPrim := idprim
   cIdKred := idkred
   FOR i := 1 TO Len( aRJ ); aRJ[ i, 2 ] := 0; NEXT
   nUkupno := 0
   DO WHILE !Eof() .AND. cIdPrim + cIdKred == idprim + idkred
      cIdRJ := idrj
      nPos := AScan( aRJ, {| x| x[ 1 ] == cIdRj } )
      DO WHILE !Eof() .AND. cIdPrim + cIdKred + cIdRj == idprim + idkred + idrj
         aRJ[ nPos, 2 ] += iznos
         nUkupno     += iznos
         SKIP 1
      ENDDO
   ENDDO
   SKIP -1

   RETURN .T.


