/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_oPDF
STATIC s_nRobaNazivSirina := 34

MEMVAR aPorezi
MEMVAR cPKonto, cMKonto, cIdPartner, cBrFaktP  // ,dDatFaktP
MEMVAR cIdFirma, cIdVd, cBrDok

FUNCTION kalk_stampa_dok_11( lKalkZaPOS )

   LOCAL nCol0 := 0
   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL lVPC := .F.
   LOCAL nVPC, nUVPV, nTVPV
   LOCAL bZagl, xPrintOpt, cNaslov
   LOCAL cLinija
   LOCAL nTot1, nTot1b, nTot2, nTotVPV, nTotMarzaVP, nTotMarzaMP, nTot5, nTot6, nTot7
   LOCAL nTot4c

   PRIVATE aPorezi
   PRIVATE nMarza, nMarza2

   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   // dDatFaktP := kalk_pripr->DatFaktP
   cPKonto := kalk_pripr->pkonto
   cMKonto := kalk_pripr->mkonto

   IF lKalkZaPOS == NIL
      lKalkZaPOS := .F.
   ENDIF

   cNaslov := "OTPREMNICA PRODAVNICA " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   SELECT kalk_pripr

   cLinija := "--- ---------- " + Replicate( "-", s_nRobaNazivSirina + 5 ) + " ---------- ---------- " + "---------- ---------- " +  "---------- ---------- "  + "---------- ---------- ---------- --------- -----------"

   select_o_koncij( kalk_pripr->mkonto )
   lVPC := is_magacin_evidencija_vpc( kalk_pripr->mkonto )

   SELECT kalk_pripr
   bZagl := {|| zagl_11( cLinija ) }
   Eval( bZagl )

   select_o_koncij( kalk_pripr->pkonto )
   SELECT kalk_pripr

   nTot1 := nTot1b := nTot2 := nTotVPV := nTotMarzaVP := nTotMarzaMP := nTot5 := nTot6 := nTot7 := 0
   nTot4c := 0

   aPorezi := {}
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD

      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      Scatter()
      IF lVPC
         nVPC := vpc_magacin_rs( .T. )
         SELECT kalk_pripr
         _VPC := nVPC
      ENDIF

      kalk_Marza_11( NIL, .F. ) // ne diraj _VPC
      nMarza := _marza
      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idRoba, @aPorezi, field->idtarifa )
      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcSaPP, field->nc )
      nPor1 := aIPor[ 1 ]

      check_nova_strana( bZagl, s_oPDF )
      nTot1 +=  ( nU1 := FCJ * Kolicina   )
      nTot1b += ( nU1b := NC * Kolicina  )
      nTot2 +=  ( nU2 := Prevoz * Kolicina   )
      nTotVPV +=  ( nU3 := _VPC * kolicina )
      nTotMarzaVP +=  ( nU4 := nMarza * Kolicina )
      nTotMarzaMP +=  ( nU4b := nMarza2 * Kolicina )
      nTot5 +=  ( nU5 := MPC * Kolicina )
      nTot6 +=  ( nU6 := ( nPor1 ) * Kolicina )
      nTot7 +=  ( nU7 := MPcSaPP * Kolicina )

      @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
      @ PRow(), PCol() + 1 SAY IdRoba
      @ PRow(), PCol() + 1 SAY PadR( ROBA->naz, s_nRobaNazivSirina ) + "(" + ROBA->jmj + ")"
      @ PRow(), PCol() + 1  SAY kalk_pripr->Kolicina             PICTURE PicCDEM

      nCol0 := PCol() + 1
      @ PRow(), PCol() + 1 SAY FCJ                  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY VPC                  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY Prevoz               PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY _VPC                   PICTURE piccdem() // _VPC
      @ PRow(), PCol() + 1 SAY nMarza               PICTURE piccdem()  // marza vp
      @ PRow(), PCol() + 1 SAY nMarza2              PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY MPC                  PICTURE piccdem()
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY aPorezi[ POR_PDV ]     PICTURE picproc()
      @ PRow(), PCol() + 1 SAY nPor1                PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY MPCSAPP              PICTURE piccdem()
      // =========  red 2 ===================
      @ PRow() + 1, 4 SAY IdTarifa + roba->tip
      @ PRow(), PCol() + 1 SAY "   " + ROBA->barkod
      @ PRow(), nCol0    SAY  kalk_pripr->fcj * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  kalk_pripr->nc * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  kalk_pripr->prevoz * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  _VPC * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  nMarza * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(), nMPos := PCol() + 1 SAY  nMarza2 * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  kalk_pripr->mpc * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(), nCol1    SAY aPorezi[ POR_PDV ]   PICTURE picproc()
      @ PRow(),  PCol() + 1 SAY  nU6             PICTURE piccdem()
      @ PRow(),  PCol() + 1 SAY  nU7             PICTURE piccdem()

      // red 3
      IF Round( kalk_pripr->nc, 5 ) <> 0
         @ PRow() + 1, nMPos SAY ( nMarza2 / nc ) * 100  PICTURE picproc()
      ENDIF

      SKIP

   ENDDO

   check_nova_strana( bZagl, s_oPDF )
   ? cLinija
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol0      SAY  nTot1        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTot1b       PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTot2        PICTURE       picdem()

   nMarzaVP := nTotMarzaVP
   @ PRow(), PCol() + 1   SAY  nTotVPV        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTotMarzaVP        PICTURE       picdem()

   @ PRow(), PCol() + 1   SAY  nTotMarzaMP        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTot5        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  Space( Len( picproc() ) )
   @ PRow(), PCol() + 1   SAY  nTot6        PICTURE        picdem()
   @ PRow(), PCol() + 1   SAY  nTot7        PICTURE        picdem()
   ? cLinija

   nTot5 := nTot6 := nTot7 := 0
   kalk_pripr_rekap_tarife()
   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl_11( cLine )

/*
   IF cIdvd == "11"
      ??U "ZADUŽENJE PRODAVNICE IZ MAGACINA"
   ELSEIF cIdVd == "12"
      ??U "POVRAT IZ PRODAVNICE U MAGACIN"
   ELSEIF cIdVd == "13"
      ??U "POVRAT IZ PRODAVNICE U MAGACIN RADI ZADUZENJA DRUGE PRODAVNICE"
   ENDIF
*/

   select_o_partner( cIdPartner )
   ? "OTPREMNICA Broj:", cBrFaktP  // , "Datum:", dDatFaktP

   // IF cIdvd == "11"
   select_o_konto( cPKonto )
   ?  _u( "Prodavnica zadužuje :" ), cPKonto, "-", AllTrim( konto->naz )
   select_o_konto( cMKonto )
   ?  _u( "Magacin razdužuje   :" ), cMKonto, "-", AllTrim( konto->naz )
   // ELSE
   // select_o_konto( cPKonto )
   // ?  "Storno Prodavnica zadužuje :", cPKonto, "-", AllTrim( konto->naz )
   // select_o_konto( cMKonto )
   // ?  "Storno Magacin razdužuje   :", cMKonto, "-", AllTrim( konto->naz )
   // ENDIF

   ? cLine
   ?U "*R *          *                ROBA                   * Količina *  NAB.CJ  *    NC    *  TROSAK  *   VP.CJ  *  MARŽA   *  MARŽA   * PROD.CJ  *   PDV %  *   PDV   * PROD.CJ  *"
   ?U "*BR*          *                                       *          *   U VP   *          *   U MP   *          *   VP     *   MP     * BEZ PDV  *          *         *  SA PDV  *"
   ?U "*  *          *                                       *          *          *          *          *          *          *          *          *          *         *          *"
   ? cLine

   RETURN .T.
