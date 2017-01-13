/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


// ----------------------------------------------
// pregled promjena na racunu
// ----------------------------------------------
FUNCTION PrPromRn()

   qqIDVN  := "I1;I2;"
   qqKonto := "2000;"
   dOd     := dDo := Date()
   cNazivFirme := self_organizacija_naziv()

   PRIVATE picBHD := FormPicL( gPicBHD, 16 )
   PRIVATE picDEM := FormPicL( gPicDEM, 12 )

   O_PARAMS
   PRIVATE cSection := "o", cHistory := " ", aHistory := {}
   RPar( "q1", @qqIDVN )
   RPar( "q2", @qqKonto )
   RPar( "q3", @dOd )
   RPar( "q4", @dDo )
   RPar( "q5", @cNazivFirme )
   SELECT PARAMS; USE

   qqIDVN      := PadR( qqIDVN, 60 )
   qqKonto     := PadR( qqKonto, 60 )
   cNazivFirme := PadR( cNazivFirme, 60 )

   Box( "#PREGLED PROMJENA NA RACUNU", 8, 75 )
   DO WHILE .T.
      @ m_x + 2, m_y + 2 SAY "Vrste naloga za knjizenje izvoda:" GET qqIDVN  PICT "@S20"
      @ m_x + 3, m_y + 2 SAY "Konto/konta ziro racuna         :" GET qqKonto PICT "@S20"
      @ m_x + 4, m_y + 2 SAY "Period od datuma:" GET dOd
      @ m_x + 4, Col() + 2 SAY "do datuma:" GET dDo
      @ m_x + 5, m_y + 2 SAY "Puni naziv firme:" GET cNazivFirme PICT "@S35"
      READ; ESC_BCR
      aUsl1 := Parsiraj( qqIDVN, "IDVN" )
      aUsl2 := Parsiraj( qqKonto, "IDKONTO" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL; EXIT; ENDIF
   ENDDO
   BoxC()

   qqIDVN      := Trim( qqIDVN      )
   qqKonto     := Trim( qqKonto     )
   cNazivFirme := Trim( cNazivFirme )

   O_PARAMS
   PRIVATE cSection := "o", cHistory := " ", aHistory := {}
   WPar( "q1", qqIDVN )
   WPar( "q2", qqKonto )
   WPar( "q3", dOd )
   WPar( "q4", dDo )
   WPar( "q5", cNazivFirme )
   SELECT PARAMS; USE

   O_KONTO
   O_PARTN
   o_suban()



   cFilter := aUsl1
   IF !Empty( dOd ); cFilter += ( ".and. DATDOK>=" + dbf_quote( dOd ) ); ENDIF
   IF !Empty( dDo ); cFilter += ( ".and. DATDOK<=" + dbf_quote( dDo ) ); ENDIF

   cSort := "dtos(datdok)"
   INDEX ON &cSort TO "SUBTMP" FOR &cFilter
   // SET FILTER TO &cFilter

   nDug := 0
   nPot := 0

   m := "------ -------- " + REPL( "-", FIELD_PARTNER_ID_LENGTH ) + " " + REPL( "-", 40 ) + " " + REPL( "-", 16 )
   z := "R.BR. * DATUM  *" + PadC( "PARTN.", FIELD_PARTNER_ID_LENGTH ) + "*" + PadC( "NAZIV PARTNERA ILI OPIS PROMJENE", 40 ) + "*" + PadC( "UPLATA KM", 16 )


   IF !start_print()
      RETURN .F.
   ENDIF
   nStranica := 0
   ZagPPR( "U" )

   nCnt := 0

   GO TOP
   DO WHILE !Eof()

      IF PRow() > 60 + dodatni_redovi_po_stranici()
         FF
         ZagPPR( "U" )
      ENDIF

      IF &aUsl2
         SKIP 1
         LOOP
      ENDIF

      IF d_p == "2"
         ? Str( ++nCnt, 6 ), RedIspisa()
         nPot += iznosbhd
      ENDIF

      SKIP

   ENDDO

   ? m
   ? "UKUPNO UPLATE" + PadL( Transform( nPot, picbhd ), 67 )
   ? m

   ?

   IF PRow() > 60 + dodatni_redovi_po_stranici()
      FF
      ZagPPR( "I" )
   ELSE
      ? "PREGLED ISPLATA:"
      ? m; ? z; ? m
   ENDIF

   nCnt := 0

   GO TOP
   DO WHILE !Eof()

      IF PRow() > 60 + dodatni_redovi_po_stranici()
         FF
         ZagPPR( "I" )
      ENDIF

      IF &aUsl2
         SKIP 1
         LOOP
      ENDIF

      IF d_p == "1"
         ? Str( ++nCnt, 6 ), RedIspisa()
         nDug += iznosbhd
      ENDIF

      SKIP

   ENDDO

   ? m
   ? "UKUPNO ISPLATE" + PadL( Transform( nDug, picbhd ), 66 )
   ? m

   FF
   end_print()

   CLOSERET

   RETURN



/* RedIspisa()
 *
 */

FUNCTION RedIspisa()

   LOCAL cVrati := ""

   cVrati := DToC( datdok ) + " " + idpartner + " "
   IF Empty( idpartner )
      cVrati += PadR( opis, 40 )
   ELSE
      cVrati += PadR( Ocitaj( F_PARTN, idpartner, "naz" ), 40 )
   ENDIF
   cVrati += ( " " + Transform( iznosbhd, picbhd ) )

   RETURN cVrati



/* ZagPPR(cI)
 *     Zaglavlje pregleda promjena na racunu
 *   param: cI
 */
FUNCTION ZagPPR( cI )

   ? cNazivFirme
   ? PadL( "Str." + AllTrim( Str( ++nStranica ) ), 80 )
   ? PadC(  "PREGLED PROMJENA NA RACUNU", 80 )
   ? PadC( "ZA PERIOD " + DToC( dOd ) + " - " + DToC( dDo ), 80 )
   ?
   IF cI == "U"
      ? "PREGLED UPLATA:"
   ELSE
      ? "PREGLED ISPLATA:"
   ENDIF
   ? m; ? z; ? m

   RETURN
