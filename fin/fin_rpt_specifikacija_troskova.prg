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


/*
// izvjestaj specifikacija troskova
// fuelboss - specifican

FUNCTION r_spec_tr()

   LOCAL dD_from
   LOCAL dD_to
   LOCAL cKtoList
   LOCAL cKtoListZ
   LOCAL cSp_ld
   LOCAL cGroup
   LOCAL cKonto
   LOCAL cTxt
   LOCAL cLine
   PRIVATE nLD_ras := 0
   PRIVATE nLD_pri := 0
   PRIVATE nLD_bruto := 0
   PRIVATE nFIN_ras := 0
   PRIVATE nFIN_pri := 0
   PRIVATE nKALK_pri := 0
   PRIVATE nKALK_ras := 0

   o_konto()
   --o_rj()

   // uslovi izvjestaja
   IF g_vars( @dD_from, @dD_to, @cGroup, @cKtoListZ, @cKtoList, @cSp_ld ) == 0
      RETURN .F.
   ENDIF


   IF !start_print()
      RETURN .F.
   ENDIF

   __r_head( dD_from, dD_to )


   ? "1) stavke koje ne uticu na rekapitulaciju:"
   ?

   // prvo uzmi podatke iz fin-a samo za pregled
   __gen2_fin( dD_from, dD_to, cGroup, cKtoList )

   ?
   ? "2) stavke koje uticu na rekapitulaciju:"
   ?

   // zatim uzmi podatke iz fin-a koji uticu na zbir
   __gen_fin( dD_from, dD_to, cGroup, cKtoListZ )

   ?

   // daj konto za kalk
   cKonto := _g_gr_kto( cGroup )

   // uzmi podatke kalk-a
   __gen_kalk( dD_from, dD_to, cKonto )

   ?

   IF cSp_ld == "D"
      __get_ld( dD_from, cGroup )
   ENDIF

   cLine := ""
   cTxt := ""

   cLine += Replicate( "-", 20 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   cTxt += PadR( "SEKCIJA", 20 )
   cTxt += Space( 1 )
   cTxt += PadL( "PRIHOD", 12 )
   cTxt += Space( 1 )
   cTxt += PadL( "RASHOD", 12 )
   cTxt += Space( 1 )
   cTxt += PadL( "UKUPNO", 12 )

   P_10CPI

   ?
   ? "------------------------"
   ? "REKAPITULACIJA TROSKOVA:"
   ? cLine
   ? cTxt
   ? cLine

   ? PadR( "1) place", 20 )
   ? PadL( "bruto:", 20 )
   @ PRow(), PCol() + 1 SAY Str( 0, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nLD_bruto, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( 0 - nLD_bruto, 12, 2 )
   ? PadL( "10.5% od bruta:", 20 )
   nTmpBr := ( nLD_bruto * 0.105 )
   @ PRow(), PCol() + 1 SAY Str( 0, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nTmpBr, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( 0 - nTmpBr, 12, 2 )
   ? PadL( "ostali troskovi:", 20 )
   @ PRow(), PCol() + 1 SAY Str( 0, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nLD_ras, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( 0 - nLD_ras, 12, 2 )


   ? PadR( "2) roba - materijal", 20 )
   @ PRow(), PCol() + 1 SAY Str( nKALK_pri, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nKALK_ras, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nKALK_pri - nKALK_ras, 12, 2 )

   ? PadR( "3) finansije", 20 )
   @ PRow(), PCol() + 1 SAY Str( nFIN_pri, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nFIN_ras, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nFIN_pri - nFIN_ras, 12, 2 )

   ? cLine

   ? PadR( "UKUPNO:", 20 )

   nTO_prih := ( nLD_pri + nKALK_pri + nFIN_pri )
   nTO_rash := ( nLD_ras + nTmpBr + nLD_bruto + nKALK_ras + nFIN_ras )

   // prihodi total
   @ PRow(), PCol() + 1 SAY Str( nTO_prih, 12, 2 )
   // rashodi total
   @ PRow(), PCol() + 1 SAY Str( nTO_rash, 12, 2 )
   // ukupno prihodi - rashodi
   @ PRow(), PCol() + 1 SAY Str( nTO_prih - nTO_rash, 12, 2 )

   ? cLine

   FF
   end_print()

   RETURN


// ---------------------------------------------
// vraca konto grupe
// ---------------------------------------------
STATIC FUNCTION _g_gr_kto( cId )

   LOCAL xRet := ""
   LOCAL nTArea := Select()

  -- o_rj()
  -- SELECT rj
  -- SEEK cId

   IF Found()
      xRet := field->konto
   ENDIF

   SELECT ( nTArea )

   RETURN xRet


// ---------------------------------------------
// vraca konto grupe
// ---------------------------------------------
STATIC FUNCTION _g_gr_naz( cId )

   LOCAL xRet := ""
   LOCAL nTArea := Select()

  -- o_rj()
--   SELECT rj
   SEEK cId

   IF Found()
      xRet := AllTrim( field->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN xRet


// ---------------------------------------------
// vraca naziv konta
// ---------------------------------------------
STATIC FUNCTION _g_kt_naz( cId )

   LOCAL xRet := ""
   LOCAL nTArea := Select()

   o_konto()
--   SELECT konto
   SEEK cId

   IF Found()
      xRet := AllTrim( field->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN xRet


// ---------------------------------------------
// vraca naziv partnera
// ---------------------------------------------
STATIC FUNCTION _g_pt_naz( cId )

   LOCAL xRet := ""
   LOCAL nTArea := Select()

--   o_partner()
--   SELECT partn
  -- SEEK cId

   IF Found()
      xRet := AllTrim( field->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN xRet



// ---------------------------------------------
// header izvjestaja
// ---------------------------------------------
STATIC FUNCTION __r_head( dD_from, dD_to )

   ?
   ? "PREGLED TROSKOVA PO OBJEKTIMA ZA PERIOD: " + DToC( dD_from ) + ;
      "-" + DToC( dD_to )
   ?

   RETURN


// --------------------------------------------------
// generisi podatke iz fin-a
// --------------------------------------------------
STATIC FUNCTION __gen_fin( dD_from, dD_to, cGroup, cKtoList )

   LOCAL cFilter := ""
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdKonto
   LOCAL cIdPartner

   // partner dug/pot/saldo
   LOCAL nP_dug := 0
   LOCAL nP_pot := 0
   LOCAL nP_saldo := 0

   // konto dug/pot/saldo
   LOCAL nK_dug := 0
   LOCAL nK_pot := 0
   LOCAL nK_saldo := 0

   // total dug/pot/saldo
   LOCAL nT_dug := 0
   LOCAL nT_pot := 0
   LOCAL nT_saldo := 0

   LOCAL nRbr := 0
   LOCAL nP_col := 50
   LOCAL nK_col := 30

   LOCAL cTxt := ""
   LOCAL cLine := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "konto", 7 )
   cTxt += Space( 1 )
   cTxt += PadR( "part.", 6 )
   cTxt += Space( 1 )
   cTxt += PadR( "naziv", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "duguje", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "potrazuje", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "saldo", 12 )

   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 7 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 6 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 40 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   ? "FIN :: stanje objekta " + cGroup + ;
      " od " + DToC( dD_from ) + " do " + DToC( dD_to )

   P_COND

   ? cLine
   ? cTxt
   ? cLine

   o_suban()
   SELECT suban
   SET ORDER TO TAG "1"
   GO TOP

   // radna jedinica
   cFilter += "idrj=" + dbf_quote( cGroup )

   // datumski period
   cFilter += ".and. datdok >= CTOD('" + ;
      DToC( dD_from ) + ;
      "') .and. datdok <= CTOD('" + ;
      DToC( dD_to ) + ;
      "')"

   IF !Empty( AllTrim( cKtoList ) )
      cFilter += ".and." + PARSIRAJ( AllTrim( cKtoList ), "idkonto" )
   ENDIF

   SET FILTER to &cFilter
   GO TOP
   --HSEEK cIdFirma

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma

      cIdKonto := field->idkonto
      nK_dug := 0
      nK_pot := 0
      nK_saldo := 0

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma ;
            .AND. field->idkonto == cIdKonto

         cIdPartner := field->idpartner

         nP_dug := 0
         nP_pot := 0
         nP_saldo := 0

         DO WHILE !Eof() .AND. field->idfirma == cIdFirma ;
               .AND. field->idkonto == cIdKonto ;
               .AND. field->idpartner == cIdPartner

            // duguje/potrazuje
            IF field->d_p == "1"
               nP_dug += field->IznosBHD
            ELSE
               nP_pot += field->IznosBHD
            ENDIF

            SKIP

         ENDDO

         nP_saldo := ( nP_dug - nP_pot )

         IF PRow() > 61 + dodatni_redovi_po_stranici()
            FF
         ENDIF

         // ne prikazuj podatke ako su 0
         IF Round( nP_saldo, 2 ) == 0
            LOOP
         ENDIF

         ? PadL( AllTrim( Str( ++nRbr, 4 ) ) + ".", 5 )

         @ PRow(), PCol() + 1 SAY cIdKonto
         @ PRow(), PCol() + 1 SAY cIdPartner

         IF Empty( cIdPartner )
            @ PRow(), nK_col := PCol() + 1 SAY PadR( _g_kt_naz( cIdKonto ), 40 )
         ELSE
            @ PRow(), nK_col := PCol() + 1 SAY PadR( _g_pt_naz( cIdPartner ), 40 )
         ENDIF

         // duguje
         @ PRow(), nP_col := PCol() + 1 SAY Str( nP_dug, 12, 2 )
         // potrazuje
         @ PRow(), PCol() + 1 SAY Str( nP_pot, 12, 2 )
         // saldo
         @ PRow(), PCol() + 1 SAY Str( nP_saldo, 12, 2 )

         // saldo po kontu
         nK_dug += nP_dug
         nK_pot += nP_pot
         nK_saldo += nP_saldo

         // total ...
         nT_dug += nP_dug
         nT_pot += nP_pot
         nT_saldo += nP_saldo

         IF Left( cIdKonto, 1 ) == "6"
            // prihod je na 6-ci
            nFIN_pri += Abs( nP_saldo )
         ELSE
            // ovo je rashod
            nFIN_ras += nP_saldo
         ENDIF

      ENDDO

      ? cLine
      ? "ukupno konto " + cIdKonto
      @ PRow(), nK_col SAY PadR( _g_kt_naz( cIdKonto ), 40 )
      @ PRow(), nP_col SAY Str( nK_dug, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nK_pot, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nK_saldo, 12, 2 )
      ? cLine

   ENDDO

   // ispisi total...

   ? "UKUPNO:"
   @ PRow(), nP_col SAY Str( nT_dug, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_pot, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_saldo, 12, 2 )

   ? cLine

   RETURN


// --------------------------------------------------
// generisi podatke iz fin-a unakrsno
// --------------------------------------------------
STATIC FUNCTION __gen2_fin( dD_from, dD_to, cGroup, cKtoList )

   LOCAL cFilter := ""
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdKonto
   LOCAL cIdPartner

   // partner dug/pot/saldo
   LOCAL nP_dug := 0
   LOCAL nP_pot := 0
   LOCAL nP_saldo := 0

   // konto dug/pot/saldo
   LOCAL nK_dug := 0
   LOCAL nK_pot := 0
   LOCAL nK_saldo := 0

   // total dug/pot/saldo
   LOCAL nT_dug := 0
   LOCAL nT_pot := 0
   LOCAL nT_saldo := 0

   LOCAL nRbr := 0
   LOCAL nP_col := 50
   LOCAL nK_col := 30

   LOCAL cTxt := ""
   LOCAL cLine := ""

   cTxt += PadR( "r.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "konto", 7 )
   cTxt += Space( 1 )
   cTxt += PadR( "part.", 6 )
   cTxt += Space( 1 )
   cTxt += PadR( "naziv", 40 )
   cTxt += Space( 1 )
   cTxt += PadR( "duguje", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "potrazuje", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "saldo", 12 )

   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 7 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 6 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 40 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   ? "FIN :: stanje po objektu " + cGroup + ;
      " od " + DToC( dD_from ) + " do " + DToC( dD_to )

   P_COND

   ? cLine
   ? cTxt
   ? cLine

   o_suban()
   SELECT suban
   SET ORDER TO TAG "2"
   // idfirma+idpartner+idkonto

   // radna jedinica
   cFilter += "idrj=" + dbf_quote( cGroup )

   // datumski period
   cFilter += ".and. datdok >= CTOD('" + ;
      DToC( dD_from ) + ;
      "') .and. datdok <= CTOD('" + ;
      DToC( dD_to ) + ;
      "')"

   IF !Empty( AllTrim( cKtoList ) )
      cFilter += ".and." + PARSIRAJ( AllTrim( cKtoList ), "idkonto" )
   ENDIF

   SET FILTER to &cFilter
   GO TOP
   --HSEEK cIdFirma

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma

      cIdPartner := field->idpartner

      nP_dug := 0
      nP_pot := 0
      nP_saldo := 0

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma ;
            .AND. field->idpartner == cIdPartner

         cIdKonto := field->idkonto
         nK_dug := 0
         nK_pot := 0
         nK_saldo := 0

         DO WHILE !Eof() .AND. field->idfirma == cIdFirma ;
               .AND. field->idkonto == cIdKonto ;
               .AND. field->idpartner == cIdPartner

            // duguje/potrazuje
            IF field->d_p == "1"
               nK_dug += field->IznosBHD
            ELSE
               nK_pot += field->IznosBHD
            ENDIF

            SKIP

         ENDDO

         nK_saldo := ( nK_dug - nK_pot )

         IF PRow() > 61 + dodatni_redovi_po_stranici()
            FF
         ENDIF

         // ne prikazuj podatke ako su 0
         IF Round( nK_saldo, 2 ) == 0
            LOOP
         ENDIF

         ? PadL( AllTrim( Str( ++nRbr, 4 ) ) + ".", 5 )

         @ PRow(), PCol() + 1 SAY cIdKonto
         @ PRow(), PCol() + 1 SAY cIdPartner

         IF Empty( cIdPartner )
            @ PRow(), nK_col := PCol() + 1 SAY PadR( _g_kt_naz( cIdKonto ), 40 )
         ELSE
            @ PRow(), nK_col := PCol() + 1 SAY PadR( _g_pt_naz( cIdPartner ), 40 )
         ENDIF

         // duguje
         @ PRow(), nP_col := PCol() + 1 SAY Str( nK_dug, 12, 2 )
         // potrazuje
         @ PRow(), PCol() + 1 SAY Str( nK_pot, 12, 2 )
         // saldo
         @ PRow(), PCol() + 1 SAY Str( nK_saldo, 12, 2 )

         // saldo po kontu
         nP_dug += nK_dug
         nP_pot += nK_pot
         nP_saldo += nK_saldo

         // total ...
         nT_dug += nK_dug
         nT_pot += nK_pot
         nT_saldo += nK_saldo

      ENDDO

      // ? cLine
      // ? "ukupno partner " + cIdPartner
      // @ prow(), nK_col SAY PADR( _g_pt_naz( cIdPartner ), 40)
      // @ prow(), nP_col SAY STR( nP_dug, 12, 2 )
      // @ prow(), pcol()+1 SAY STR( nP_pot, 12, 2 )
      // @ prow(), pcol()+1 SAY STR( nP_saldo, 12, 2 )
      // ? cLine

   ENDDO

   // ispisi total...

   ? cLine
   ? "UKUPNO:"
   @ PRow(), nP_col SAY Str( nT_dug, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_pot, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_saldo, 12, 2 )

   ? cLine

   RETURN .T.



// --------------------------------------------------
// generisi podatke iz kalk-a
// --------------------------------------------------
STATIC FUNCTION __gen_kalk( dD_from, dD_to, cKto )

   LOCAL cPath := StrTran( KUMPATH, "FIN", "KALK" )
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cLine
   LOCAL cTxt
   LOCAL nIzlNV
   LOCAL nUlNV
   LOCAL nUlKol
   LOCAL nIzKol
   LOCAL nKolicina

   SELECT ( 102 )
   USE ( cPath + SLASH + "kalk" ) ALIAS "ka_exp"

   SELECT ka_exp
   // mkonto
   SET ORDER TO TAG "3"
   GO TOP

   SEEK cIdFirma + cKto

   nIzlNV := 0
   nUlNV := 0
   nUlKol := 0
   nIzKol := 0
   nKolicina := 0

   // prodji kroz KALK za ovaj konto...

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma ;
         .AND. field->mkonto == cKto

      // provjeri datum
      IF field->datdok > dD_to .OR. field->datdok < dD_from
         SKIP
         LOOP
      ENDIF

      IF field->mu_i == "1"

         IF !( field->idvd $ "12#22#94" )
            nKolicina := field->kolicina - field->gkolicina - field->gkolicin2
            nUlKol += nKolicina
            nUlNv += Round( field->nc * ( field->kolicina - field->gkolicina - field->gkolicin2 ), gZaokr )
         ELSE
            nKolicina := -field->kolicina
            nIzlKol += nKolicina
            nIzlNV -= Round( field->nc * field->kolicina, gZaokr )
         ENDIF

      ELSEIF field->mu_i == "5"

         nKolicina := field->kolicina
         nIzlKol += nKolicina
         nIzlNV += Round( field->nc * field->kolicina, gZaokr )

      ELSEIF field->mu_i == "8"

         nKolicina := -field->kolicina
         nIzlKol += nKolicina
         nIzlNV += Round( field->nc * ( -kolicina ), gZaokr )
         nKolicina := -field->kolicina
         nUlKol += nKolicina
         nUlKol += Round( -nc * ( field->kolicina - gkolicina - gkolicin2 ), gZaokr )
      ENDIF

      // select kalk
      SKIP

   ENDDO

   // sada imam podatke, ispisi ih...

   cLine := ""
   cTxt := ""

   cLine += Replicate( "-", 7 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 60 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   cTxt += PadR( "objekat", 7 )
   cTxt += Space( 1 )
   cTxt += PadR( "naziv", 60 )
   cTxt += Space( 1 )
   cTxt += PadR( "NV ulaz", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "NV izlaz", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "NV stanje", 12 )

   P_10CPI

   ? "KALK :: stanje objekta", cKto, "od " + DToC( dD_from ) + ;
      " do " + DToC( dD_to )

   P_COND

   // ispisi zaglavlje
   ? cLine
   ? cTxt
   ? cLine

   ? cKto
   @ PRow(), PCol() + 1 SAY PadR( _g_kt_naz( cKto ), 60 )
   @ PRow(), PCol() + 1 SAY Str( nUlNV, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nIzlNV, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUlNV - nIzlNV, 12, 2 )
   ? cLine

   nKALK_ras += ( nUlNv - nIzlNV )

   RETURN




// -------------------------------------------
// vraca linije i header
// -------------------------------------------
STATIC FUNCTION _g_ld_line( cLine )

   cLine := Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 30 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 8 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   cTxt := PadR( "R.br", 5 )
   cTxt += Space( 1 )
   cTxt += PadR( "Ime i prezime radnika", 30 )
   cTxt += Space( 1 )
   cTxt += PadR( "Sati", 8 )
   cTxt += Space( 1 )
   cTxt += PadR( "Bruto", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Neto", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Dopr.PIO", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Dopr.ZDR", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Dopr.NEZ", 12 )
   cTxt += Space( 1 )
   cTxt += PadR( "Porez", 12 )

   IF ld_exp->tp_1 <> 0
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( "dp-1", 12 )
   ENDIF
   IF ld_exp->tp_2 <> 0
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( "dp-2", 12 )
   ENDIF
   IF ld_exp->tp_3 <> 0
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( "dp-3", 12 )
   ENDIF
   IF ld_exp->tp_4 <> 0
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( "dp-4", 12 )
   ENDIF
   IF ld_exp->tp_5 <> 0
      cLine += Space( 1 )
      cLine += Replicate( "-", 12 )
      cTxt += Space( 1 )
      cTxt += PadR( "dp-5", 12 )
   ENDIF

   ? cLine
   ? cTxt
   ? cLine

   RETURN


// ----------------------------------------------------------
// printanje reporta iz ld-a
// ----------------------------------------------------------
STATIC FUNCTION __get_ld( dD_from, cGroup )

   LOCAL cLine
   LOCAL nU_sati := 0
   LOCAL nU_bruto := 0
   LOCAL nU_neto := 0
   LOCAL nU_d_pio := 0
   LOCAL nU_d_nez := 0
   LOCAL nU_d_zdr := 0
   LOCAL nU_i_por := 0
   LOCAL nU_o_por := 0
   LOCAL nU_tp_1 := 0
   LOCAL nU_tp_2 := 0
   LOCAL nU_tp_3 := 0
   LOCAL nU_tp_4 := 0
   LOCAL nU_tp_5 := 0
   LOCAL nT_sati := 0
   LOCAL nT_bruto := 0
   LOCAL nT_neto := 0
   LOCAL nT_d_pio := 0
   LOCAL nT_d_nez := 0
   LOCAL nT_d_zdr := 0
   LOCAL nT_i_por := 0
   LOCAL nT_o_por := 0
   LOCAL nT_tp_1 := 0
   LOCAL nT_tp_2 := 0
   LOCAL nT_tp_3 := 0
   LOCAL nT_tp_4 := 0
   LOCAL nT_tp_5 := 0
   LOCAL nCol := 15
   LOCAL cPath := StrTran( my_home(), "FIN", "LD" )

   SELECT ( 101 )
   USE ( cPath + SLASH + "r_export" ) ALIAS "ld_exp"
  -- INDEX ON group + idradn + Str( godina, 4 ) + Str( mjesec, 2 ) TAG "1"
   SELECT ld_exp
   SET ORDER TO TAG "1"
   GO TOP

   P_10CPI

   ? "LD :: pregled utroska za grupu:", cGroup, Str( Month( dD_from ) ) ;
      + "/" + Str( Year( dD_from ) )

   P_COND2

   _g_ld_line( @cLine )

   nCnt := 0
   DO WHILE !Eof()

      // n.str
      IF PRow() > 64
         FF
      ENDIF

      cGr_id := field->group
      cGr_naz := field->gr_naz

      nU_sati := 0
      nU_bruto := 0
      nU_neto := 0
      nU_d_pio := 0
      nU_d_nez := 0
      nU_d_zdr := 0
      nU_i_por := 0
      nU_o_por := 0
      nU_tp_1 := 0
      nU_tp_2 := 0
      nU_tp_3 := 0
      nU_tp_4 := 0
      nU_tp_5 := 0

      ? Space( 1 ), "Objekat: ", ;
         "(" + cGr_id + ")", ;
         PadR( cGr_naz, 30 )

      DO WHILE !Eof() .AND. field->group == cGr_id

         // n.str
         IF PRow() > 64
            FF
         ENDIF

         ? PadL( AllTrim( Str( ++nCnt ) ) + ".", 5 )
         @ PRow(), PCol() + 1 SAY PadR( field->r_naz, 30 )
         @ PRow(), nCol := PCol() + 1 SAY Str( field->sati, 8, 2 )
         @ PRow(), PCol() + 1 SAY Str( field->bruto, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( field->neto, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_pio, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_zdr, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_nez, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( field->izn_por, 12, 2 )

         IF field->tp_1 <> 0
            @ PRow(), PCol() + 1 SAY Str( field->tp_1, 12, 2 )
         ENDIF
         IF field->tp_2 <> 0
            @ PRow(), PCol() + 1 SAY Str( field->tp_2, 12, 2 )
         ENDIF
         IF field->tp_3 <> 0
            @ PRow(), PCol() + 1 SAY Str( field->tp_3, 12, 2 )
         ENDIF
         IF field->tp_4 <> 0
            @ PRow(), PCol() + 1 SAY Str( field->tp_4, 12, 2 )
         ENDIF
         IF field->tp_5 <> 0
            @ PRow(), PCol() + 1 SAY Str( field->tp_5, 12, 2 )
         ENDIF

         nU_sati += field->sati
         nU_bruto += field->bruto
         nU_neto += field->neto
         nU_d_pio += field->dop_pio
         nU_d_nez += field->dop_nez
         nU_d_zdr += field->dop_zdr
         nU_i_por += field->izn_por
         nU_o_por += field->osn_por
         nU_tp_1 += field->tp_1
         nU_tp_2 += field->tp_2
         nU_tp_3 += field->tp_3
         nU_tp_4 += field->tp_4
         nU_tp_5 += field->tp_5

         nT_sati += field->sati
         nT_bruto += field->bruto
         nT_neto += field->neto
         nT_d_pio += field->dop_pio
         nT_d_nez += field->dop_nez
         nT_d_zdr += field->dop_zdr
         nT_i_por += field->izn_por
         nT_o_por += field->osn_por
         nT_tp_1 += field->tp_1
         nT_tp_2 += field->tp_2
         nT_tp_3 += field->tp_3
         nT_tp_4 += field->tp_4
         nT_tp_5 += field->tp_5

         SKIP
      ENDDO

      // total po grupi....
      ? cLine
      ? PadL( "Ukupno " + cGr_id + ":", 25 )
      @ PRow(), nCol SAY Str( nU_sati, 8, 2 )
      @ PRow(), PCol() + 1 SAY Str( nU_bruto, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nU_neto, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nU_d_pio, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nU_d_zdr, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nU_d_nez, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nU_i_por, 12, 2 )

      IF nU_tp_1 <> 0
         @ PRow(), PCol() + 1 SAY Str( nU_tp_1, 12, 2 )
      ENDIF
      IF nU_tp_2 <> 0
         @ PRow(), PCol() + 1 SAY Str( nU_tp_2, 12, 2 )
      ENDIF
      IF nU_tp_3 <> 0
         @ PRow(), PCol() + 1 SAY Str( nU_tp_3, 12, 2 )
      ENDIF
      IF nU_tp_4 <> 0
         @ PRow(), PCol() + 1 SAY Str( nU_tp_4, 12, 2 )
      ENDIF
      IF nU_tp_5 <> 0
         @ PRow(), PCol() + 1 SAY Str( nU_tp_5, 12, 2 )
      ENDIF

      ?

   ENDDO

   // total za sve....
   ? cLine
   ? "UKUPNO: "
   @ PRow(), nCol SAY Str( nT_sati, 8, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_bruto, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_neto, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_d_pio, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_d_zdr, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_d_nez, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_i_por, 12, 2 )

   IF nT_tp_1 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_tp_1, 12, 2 )
   ENDIF
   IF nT_tp_2 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_tp_2, 12, 2 )
   ENDIF
   IF nT_tp_3 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_tp_3, 12, 2 )
   ENDIF
   IF nT_tp_4 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_tp_4, 12, 2 )
   ENDIF
   IF nT_tp_5 <> 0
      @ PRow(), PCol() + 1 SAY Str( nT_tp_5, 12, 2 )
   ENDIF

   ? cLine

   // ukalkulisi u rashod

   nLD_bruto += nT_bruto
   nLD_ras += ( nT_tp_1 + nT_tp_2 + nT_tp_3 + nT_tp_4 + nT_tp_5 )

   RETURN


// -------------------------------------------------------
// uslovi reporta
// -------------------------------------------------------
STATIC FUNCTION g_vars( dD_from, dD_to, cGroup, cKtoListZ, cKtoList, ;
      cSpecLd )

   LOCAL nRet := 1
   LOCAL nBoxX := 10
   LOCAL nBoxY := 65
   LOCAL nX := 1
   LOCAL nTArea := Select()

   dD_from := Date() -30
   dD_to := Date()
   cSpecLD := "D"
   cKtoList := Space( 200 )
   cKtoListZ := Space( 200 )
   cGroup := Space( 6 )

   o_params()
   PRIVATE cSection := "S"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   RPar( "d1", @dD_from )
   RPar( "d2", @dD_to )
   RPar( "ld", @cSpecLD )
   RPar( "kl", @cKtoList )
   RPar( "kz", @cKtoListZ )
   RPar( "gr", @cGroup )

   Box(, nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Za period od:" GET dD_From
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET dD_to

   ++ nX
   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Grupa:" GET cGroup ;
      VALID p_rj( @cGroup )

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Specifikacija LD (D/N)?" GET cSpecLd ;
      VALID cSpecLd $ "DN" PICT "@!"

   ++ nX
   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "FIN konta   - lista    (uticu na zbir):" ;
      GET cKtoListZ ;
      PICT "@S20"

   ++ nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "FIN konta   - lista (ne uticu na zbir):" ;
      GET cKtoList ;
      PICT "@S20"


   READ
   BoxC()

   IF LastKey() == K_ESC
      nRet := 0
      RETURN nRet
   ENDIF

   // write params
   WPar( "d1", dD_from )
   WPar( "d2", dD_to )
   WPar( "ld", cSpecLD )
   WPar( "kl", cKtoList )
   WPar( "kz", cKtoListZ )
   WPar( "gr", cGroup )

   SELECT params
   USE

   SELECT ( nTArea )

   RETURN nRet


*/
