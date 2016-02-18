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


FUNCTION ld_specifikacija_po_rasponima_primanja()

   gnLMarg := 0
   gTabela := 1
   gOstr := "D"

   cIdRj := gRj
   cMjesec := gMjesec
   cGodina := gGodina
   cObracun := gObracun

   O_LD_RJ
   O_RADN
   O_LD

   PRIVATE cFormula := PadR( "UNETO", 40 )
   PRIVATE cNaziv := PadR( "UKUPNO NETO", 20 )

   cDod := "N"

   nDo1 := 85; nDo2 := 150; nDo3 := 200; nDo4 := 250; nDo5  := 300
   nDo6 := 0 ; nDo7 := 0  ; nDo8 := 0  ; nDo9 := 0  ; nDo10 := 0
   nDo11 := 0 ; nDo12 := 0  ; nDo13 := 0  ; nDo14 := 0  ; nDo15 := 0
   nDo16 := 0 ; nDo17 := 0  ; nDo18 := 0  ; nDo19 := 0  ; nDo20 := 0

   O_PARAMS
   PRIVATE cSection := "4", cHistory := " ", aHistory := {}

   RPar( "p1", @cNaziv )
   RPar( "p2", @cFormula )
   RPar( "p3", @nDo1 )
   RPar( "p4", @nDo2 )
   RPar( "p5", @nDo3 )
   RPar( "p6", @nDo4 )
   RPar( "p7", @nDo5 )
   RPar( "p8", @nDo6 )
   RPar( "p9", @nDo7 )
   RPar( "r0", @nDo8 )
   RPar( "r1", @nDo9 )
   RPar( "r2", @nDo10 )
   RPar( "r3", @nDo11 )
   RPar( "r4", @nDo12 )
   RPar( "r5", @nDo13 )
   RPar( "r6", @nDo14 )
   RPar( "r7", @nDo15 )
   RPar( "r8", @nDo16 )
   RPar( "r9", @nDo17 )
   RPar( "s0", @nDo18 )
   RPar( "s1", @nDo19 )
   RPar( "s2", @nDo20 )

   Box(, 19, 77 )

   @ m_x + 1, m_y + 2 SAY "Radna jedinica (prazno sve): "  GET cIdRJ
   @ m_x + 2, m_y + 2 SAY "Mjesec: "  GET  cMjesec  PICT "99"
   @ m_x + 2, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN HelpObr( .T., cObracun ) VALID ValObr( .T., cObracun )
   @ m_x + 3, m_y + 2 SAY "Godina: "  GET  cGodina  PICT "9999"

   @ m_x + 5, m_y + 2 SAY "Naziv raspona primanja: "  GET cNaziv
   @ m_x + 6, m_y + 2 SAY "Formula primanja      : "  GET cFormula PICT "@S20"

   @ m_x + 8, m_y + 2 SAY "             (0 - raspon se ne prikazuje)"
   @ m_x + 9, m_y + 2 SAY " 1. raspon do " GET nDo1 PICT "99999"
   @ m_x + 10, m_y + 2 SAY " 2. raspon do " GET nDo2 PICT "99999"
   @ m_x + 11, m_y + 2 SAY " 3. raspon do " GET nDo3 PICT "99999"
   @ m_x + 12, m_y + 2 SAY " 4. raspon do " GET nDo4 PICT "99999"
   @ m_x + 13, m_y + 2 SAY " 5. raspon do " GET nDo5 PICT "99999"
   @ m_x + 14, m_y + 2 SAY " 6. raspon do " GET nDo6 PICT "99999"
   @ m_x + 15, m_y + 2 SAY " 7. raspon do " GET nDo7 PICT "99999"
   @ m_x + 16, m_y + 2 SAY " 8. raspon do " GET nDo8 PICT "99999"
   @ m_x + 17, m_y + 2 SAY " 9. raspon do " GET nDo9 PICT "99999"
   @ m_x + 18, m_y + 2 SAY "10. raspon do " GET nDo10 PICT "99999"

   @ m_x + 9, m_y + 25 SAY "11. raspon do " GET nDo11 PICT "99999"
   @ m_x + 10, m_y + 25 SAY "12. raspon do " GET nDo12 PICT "99999"
   @ m_x + 11, m_y + 25 SAY "13. raspon do " GET nDo13 PICT "99999"
   @ m_x + 12, m_y + 25 SAY "14. raspon do " GET nDo14 PICT "99999"
   @ m_x + 13, m_y + 25 SAY "15. raspon do " GET nDo15 PICT "99999"
   @ m_x + 14, m_y + 25 SAY "16. raspon do " GET nDo16 PICT "99999"
   @ m_x + 15, m_y + 25 SAY "17. raspon do " GET nDo17 PICT "99999"
   @ m_x + 16, m_y + 25 SAY "18. raspon do " GET nDo18 PICT "99999"
   @ m_x + 17, m_y + 25 SAY "19. raspon do " GET nDo19 PICT "99999"
   @ m_x + 18, m_y + 25 SAY "20. raspon do " GET nDo20 PICT "99999"

   READ
   clvbox()
   ESC_BCR

   BoxC()

   WPar( "p1", cNaziv )
   WPar( "p2", cFormula )
   WPar( "p3", nDo1 )
   WPar( "p4", nDo2 )
   WPar( "p5", nDo3 )
   WPar( "p6", nDo4 )
   WPar( "p7", nDo5 )
   WPar( "p8", nDo6 )
   WPar( "p9", nDo7 )
   WPar( "r0", nDo8 )
   WPar( "r1", nDo9 )
   WPar( "r2", nDo10 )
   WPar( "r3", nDo11 )
   WPar( "r4", nDo12 )
   WPar( "r5", nDo13 )
   WPar( "r6", nDo14 )
   WPar( "r7", nDo15 )
   WPar( "r8", nDo16 )
   WPar( "r9", nDo17 )
   WPar( "s0", nDo18 )
   WPar( "s1", nDo19 )
   WPar( "s2", nDo20 )

   SELECT params
   USE

   tipprn_use()

   aRasponi := { nDo1, nDo2, nDo3, nDo4, nDo5, nDo6, nDo7, nDo8, nDo9,;
      nDo10, nDo11, nDo12, nDo13, nDo14, nDo15, nDo16, nDo17,;
      nDo18, nDo19, nDo20 }

   ASort( aRasponi )

   nLast := 0
   nRed := 0
   aKol := {}
   aUslRasp := {}
   nSumRasp := {}

   FOR i := 1 TO Len( aRasponi )
      IF aRasponi[ i ] > 0
         ++nRed

         AAdd( nSumRasp, 0 )

         cPomM := "nSumRasp[" + AllTrim( Str( nRed ) ) + "]"

         cPom77 := "{|| 'OD " + Str( nLast, 5 ) + " DO " + Str( aRasponi[ i ], 5 ) + "' }"
         IF nRed == 1
            AAdd( aKol, { AllTrim( cNaziv ), &cPom77., .F., "C", 40, 0, nRed, 1 } )
            AAdd( aKol, { "BROJ RADNIKA", {|| &cPomM.   }, .F., "N", 12, 0, nRed, 2 } )
         ELSE
            AAdd( aKol, { "", &cPom77., .F., "C", 40, 0, nRed, 1 } )
            AAdd( aKol, { "", {|| &cPomM.   }, .F., "N", 12, 0, nRed, 2 } )
         ENDIF

         AAdd( aUslRasp, { nLast, aRasponi[ i ] } )
         nLast := aRasponi[ i ]
      ENDIF
   NEXT

   IF Len( aKol ) < 2
      my_close_all_dbf()
      RETURN
   ENDIF

   ASort( aKol,,, {| x, y| 100 * x[ 8 ] + x[ 7 ] < 100 * y[ 8 ] + y[ 7 ] } )

   SELECT LD

   SET ORDER TO TAG ( TagVO( "1" ) )

   PRIVATE cFilt1 := ""

   cFilt1 := "GODINA==" + dbf_quote( cGodina ) + ".and.MJESEC==" + dbf_quote( cMjesec ) + ;
      IF( Empty( cIdRJ ), "", ".and.IDRJ==" + dbf_quote( cIdRJ ) )
   cFilt1 := StrTran( cFilt1, ".t..and.", "" )

   IF lViseObr .AND. !Empty( cObracun )
      cFilt1 += ( ".and. OBR==" + dbf_quote( cObracun ) )
   ENDIF

   IF cFilt1 == ".t."
      SET FILTER TO
   ELSE
      SET FILTER TO &cFilt1
   ENDIF

   GO TOP

   START PRINT CRET

   PRIVATE cIdPartner := "", cNPartnera := "", nUkRoba := 0, nUkIznos := 0

   ?? Space( gnLMarg )
   ??U "LD: Izvještaj na dan", DTOC( Date() )
   ? Space( gnLMarg )
   IspisFirme( "" )
   ? Space( gnLMarg )
   IF Empty( cidrj )
      ?? "Pregled za sve RJ ukupno:"
   ELSE
      ?? "RJ:", cIdRj + " - " + Ocitaj( F_LD_RJ, cIdRj, "naz" )
   ENDIF
   ?? "  Mjesec:", Str( cMjesec, 2 ) + IspisObr()
   ?? "    Godina:", Str( cGodina, 5 )

   StampaTabele( aKol, {|| NIL },, gTabela,, ;
      , "Specifikacija po rasponima primanja", ;
      {|| filter_specifikacija_raspon() }, IF( gOstr == "D",, -1 ),,,,, )

   FF
   ENDPRINT

   my_close_all_dbf()
   RETURN



STATIC FUNCTION filter_specifikacija_raspon()

   DO WHILE !Eof()
      nPrim := &( cFormula )
      FOR i := 1 TO Len( aUslRasp )
         IF nPrim > aUslRasp[ i, 1 ] .AND. nPrim <= aUslRasp[ i, 2 ]
            ++nSumRasp[i ]
         ENDIF
      NEXT
      SKIP 1
   ENDDO
   SKIP -1

   RETURN .T.
