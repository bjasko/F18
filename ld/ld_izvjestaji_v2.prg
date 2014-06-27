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



FUNCTION TekRec()

   @ m_x + 1, m_y + 2 SAY RecNo()

   RETURN NIL


FUNCTION ObrM4()
   CLOSERET
   RETURN


FUNCTION ld_pregled_primanja_za_period()

   LOCAL nC1 := 20

   cIdRadn := Space( 6 )
   cIdRj := gRj
   cGodina := gGodina
   cObracun := gObracun

   O_LD_RJ
   O_RADN
   O_LD

   PRIVATE cTip := "  "
   cDod := "N"
   cKolona := Space( 20 )
   Box(, 6, 75 )
   cMjesecOd := cMjesecDo := gMjesec
   @ m_x + 1, m_y + 2 SAY "Radna jedinica (prazno-sve): "  GET cIdRJ
   @ m_x + 2, m_y + 2 SAY "Mjesec od: "  GET  cmjesecOd  PICT "99"
   @ m_x + 2, Col() + 2 SAY "do" GET cMjesecDO  PICT "99"
   IF lViseObr
      @ m_x + 2, Col() + 2 SAY "Obracun:" GET cObracun WHEN HelpObr( .T., cObracun ) VALID ValObr( .T., cObracun )
   ENDIF
   @ m_x + 3, m_y + 2 SAY "Godina: "  GET  cGodina  PICT "9999"
   @ m_x + 4, m_y + 2 SAY "Tip primanja: "  GET  cTip
   @ m_x + 5, m_y + 2 SAY "Prikaz dodatnu kolonu: "  GET  cDod PICT "@!" VALID cdod $ "DN"
   read; clvbox(); ESC_BCR
   IF cDod == "D"
      @ m_x + 6, m_y + 2 SAY "Naziv kolone:" GET cKolona
      READ
   ENDIF
   fRacunaj := .F.
   IF Left( cKolona, 1 ) = "="
      fRacunaj := .T.
      ckolona := StrTran( cKolona, "=", "" )
   ELSE
      ckolona := "radn->" + ckolona
   ENDIF
   BoxC()

   tipprn_use()

   SELECT tippr
   hseek ctip
   EOF CRET

   SELECT ld

   IF lViseObr .AND. !Empty( cObracun )
      SET FILTER TO obr == cObracun
   ENDIF

   SET ORDER TO tag ( TagVO( "4" ) )
   hseek Str( cGodina, 4 )

   EOF CRET

   nStrana := 0
   m := "----- ------ ---------------------------------- " + "-" + REPL( "-", Len( gPicS ) ) + " ----------- -----------"
   IF cdod == "D"
      IF Type( ckolona ) $ "UUIUE"
         Msg( "Nepostojeca kolona" )
         closeret
      ENDIF
   ENDIF
   bZagl := {|| ZPregPrimPer() }

   SELECT ld_rj; hseek ld->idrj; SELECT ld

   START PRINT CRET
   P_10CPI

   Eval( bZagl )

   nRbr := 0
   nT1 := nT2 := nT3 := nT4 := 0
   nC1 := 10

   DO WHILE !Eof() .AND.  cgodina == godina
      IF PRow() > RPT_PAGE_LEN; FF; Eval( bZagl ); ENDIF


      cIdRadn := idradn
      SELECT radn; hseek cidradn; SELECT ld

      wi&cTip := 0
      ws&cTip := 0

      IF fracunaj
         nKolona := 0
      ENDIF
      DO WHILE  !Eof() .AND. cgodina == godina .AND. idradn == cidradn
         Scatter()
         IF !Empty( cidrj ) .AND. _idrj <> cidrj
            skip; LOOP
         ENDIF
         IF cmjesecod > _mjesec .OR. cmjesecdo < _mjesec
            skip; LOOP
         ENDIF
         wi&cTip += _i&cTip
         IF ! ( lViseObr .AND. Empty( cObracun ) .AND. _obr <> "1" )
            ws&cTip += _s&cTip
         ENDIF
         IF fRacunaj
            nKolona += &cKolona
         ENDIF
         SKIP
      ENDDO

      IF wi&cTip <> 0 .OR. ws&cTip <> 0
         ? Str( ++nRbr, 4 ) + ".", cidradn, RADNIK
         nC1 := PCol() + 1
         IF tippr->fiksan == "P"
            @ PRow(), PCol() + 1 SAY ws&cTip  PICT "999.99"
         ELSE
            @ PRow(), PCol() + 1 SAY ws&cTip  PICT gpics
         ENDIF
         @ PRow(), PCol() + 1 SAY wi&cTip  PICT gpici
         nT1 += ws&cTip; nT2 += wi&cTip
         IF cdod == "D"
            IF fracunaj
               @ PRow(), PCol() + 1 SAY nKolona PICT gpici
            ELSE
               @ PRow(), PCol() + 1 SAY &ckolona
            ENDIF
         ENDIF

      ENDIF

      SELECT ld
   ENDDO

   IF PRow() > 60; FF; Eval( bZagl ); ENDIF
   ? m
   ? " UKUPNO:"
   @ PRow(), nC1 SAY  nT1 PICT gpics
   @ PRow(), PCol() + 1 SAY  nT2 PICT gpici
   ? m
   ?
   ? p_potpis()

   FF
   END PRINT
   my_close_all_dbf()
   RETURN



FUNCTION ZPregPrimPer()

   P_12CPI
   ? Upper( Trim( gTS ) ) + ":", gnFirma
   ?
   ? "Pregled primanja za period od", cMjesecOd, "do", cMjesecDo, "mjesec " + IspisObr()
   ?? cGodina
   ?
   IF Empty( cIdRj )
      ? "Pregled za sve RJ ukupno:"
   ELSE
      ? "RJ:", cIdRj, ld_rj->naz
   ENDIF
   ?? Space( 4 ), "Str.", Str( ++nStrana, 3 )
   ?
   ? "Pregled za tip primanja:", ctip, tippr->naz

   ? m
   ? " Rbr  Sifra           Naziv radnika               " + iif( tippr->fiksan == "P", " %  ", "Sati" ) + "      Iznos"
   ? m





FUNCTION ZSRO()

   P_COND
   ? Upper( gTS ) + ":", gnFirma
   ?
   IF Empty( cidrj )
      ? "Pregled za sve RJ ukupno:"
   ELSE
      ? "RJ:", cidrj, ld_rj->naz
   ENDIF
   ?? "  Mjesec:", Str( cmjesec, 2 ) + IspisObr()
   ?? "    Godina:", Str( cGodina, 5 )
   DevPos( PRow(), 74 )
   ?? "Str.", Str( ++nStrana, 3 )
   IF !Empty( cvposla )
      ? "Vrsta posla:", cvposla, "-", vposla->naz
   ENDIF
   IF !Empty( cKBenef )
      ? "Stopa beneficiranog r.st:", ckbenef, "-", kbenef->naz, ":", kbenef->iznos
   ENDIF
   ? m
   ? " Rbr * Sifra*         Naziv radnika            *  Sati *   Neto    *  Odbici   * ZA ISPLATU*"
   ? "     *      *                                  *       *           *           *           *"
   ? m

   RETURN



FUNCTION SortOpSt( cId )

   LOCAL cVrati := "", nArr := Select()

   SELECT RADN
   HSEEK cId
   cVrati := IdOpsSt
   SELECT ( nArr )

   RETURN cVrati



FUNCTION IzracDopr( cDopr, nKLO, cTipRada, nSpr_koef )

   LOCAL nArr := Select(), nDopr := 0, nPom := 0, nPom2 := 0, nPom0 := 0, nBO := 0, nBFOsn := 0
   LOCAL _a_benef := {}

   IF nKLO == nil
      nKLO := 0
   ENDIF

   IF cTipRada == nil
      cTipRada := ""
   ENDIF

   IF nSPr_koef == nil
      nSPr_koef := 0
   ENDIF

   ParObr( mjesec, godina, IF( lViseObr, cObracun, ), cIdRj )

   IF gVarObracun == "2"

      nBo := bruto_osn( Max( _UNeto, PAROBR->prosld * gPDLimit / 100 ), cTipRada, nKlo, nSPr_koef )

      IF UBenefOsnovu()

         IF !Empty( gBFForm )
            gBFForm := StrTran( gBFForm, "_", "" )
         ENDIF

         nBFOsn := bruto_osn( _UNeto - IF( !Empty( gBFForm ), &gBFForm, 0 ), cTipRada, nKlo, nSPr_koef )

         _benef_st := BenefStepen()
         add_to_a_benef( @_a_benef, AllTrim( radn->k3 ), _benef_st, nBFOsn )

      ENDIF

      IF cTipRada $ " #I#N"
         // minimalni bruto osnov
         IF calc_mbruto()
            nBo := min_bruto( nBo, ld->usati )
         ENDIF
      ENDIF

   ELSE
      nBo := round2( parobr->k3 / 100 * Max( _UNeto, PAROBR->prosld * gPDLimit / 100 ), gZaok2 )
   ENDIF

   SELECT DOPR
   GO TOP

   DO WHILE !Eof()

      IF gVarObracun == "2"
         IF cTipRada $ "I#N" .AND. Empty( dopr->tiprada )
            // ovo je uredu !
         ELSEIF dopr->tiprada <> cTipRada
            SKIP 1
            LOOP
         ENDIF
      ENDIF

      IF !( id $ cDopr )
         SKIP 1
         LOOP
      ENDIF

      PozicOps( DOPR->poopst )   // ? mozda ovo rusi koncepciju zbog sorta na LD-u

      IF !ImaUOp( "DOPR", DOPR->id )
         SKIP 1
         LOOP
      ENDIF

      IF !Empty( dopr->idkbenef )
         // beneficirani
         nPom := Max( dlimit, Round( iznos / 100 * get_benef_osnovica( _a_benef, dopr->idkbenef ), gZaok2 ) )
      ELSE
         nPom := Max( dlimit, Round( iznos / 100 * nBO, gZaok2 ) )
      ENDIF

      IF Round( iznos, 4 ) = 0 .AND. dlimit > 0
         // fuell boss
         // kartica plate
         nPom := 1 * dlimit
      ENDIF

      nDopr += nPom

      // resetuj matricu a_benef, posto nam treba za radnika
      _a_benef := {}

      SKIP 1

   ENDDO

   SELECT ( nArr )

   RETURN ( nDopr )


FUNCTION SortPre2()
   RETURN ( RADN->( naz + ime + imerod ) + idradn )






