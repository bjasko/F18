/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR m, GetList, m_x, m_y
MEMVAR gDUFRJ, gTroskovi
MEMVAR cIdFirma, cIdKonto, fk1, fk2, fk3, fk4, cK1, cK2, cK3, cK4
MEMVAR qqKonto, qqPartner
MEMVAR nStr
MEMVAR gPicBHD, gPicDEM, picDEM, picBHD, lOtvoreneStavke
MEMVAR dDatOd, dDatDo
FIELD iznosbhd, iznosdem, d_p, otvst, idpartner, idfirma, idkonto, datdok, datval, brdok, brnal

FUNCTION fin_suban_kartica( lOtvst ) // param lOtvst  - .t. otvorene stavke

   LOCAL cBrza := "D"
   LOCAL nC1 := 37
   LOCAL nSirOp := 20
   LOCAL nCOpis := 0
   LOCAL cOpis := ""
   LOCAL cBoxName
   LOCAL dPom := CToD( "" )
   LOCAL cOpcine := Space( 20 )
   LOCAL cExpDbf := "N"
   LOCAL aExpFields
   LOCAL __vr_nal
   LOCAL __br_nal
   LOCAL __br_veze
   LOCAL __r_br
   LOCAL __dat_val
   LOCAL __dat_nal
   LOCAL __opis
   LOCAL __p_naz
   LOCAL cKontoNaziv
   LOCAL nDuguje
   LOCAL nPotrazuje
   LOCAL _fin_params := fin_params()
   LOCAL _fakt_params := fakt_params()
   LOCAL cLibreOffice := "N"
   LOCAL nX := 2
   LOCAL bZagl  :=  {|| zagl_suban_kartica( cBrza ) }
   LOCAL lKarticaNovaStrana := .F.
   LOCAL nTmp
   LOCAL cOrderBy
   LOCAL lPrviProlaz
   LOCAL cIdVnIzvod := "61"
   LOCAL cSpojiDP := "2" // spoji potrazuje - uplate = 2, spoji dugovanja = 1
   LOCAL lSpojiUplate := .F., nSpojeno := 0
   LOCAL pRegex, aMatch
   LOCAL oPDF, xPrintOpt
   LOCAL bEvalSubanKartFirma, bEvalSubanKartKonto, bEvalSubanKartPartner
   LOCAL nPDugBHD, nPPotBHD, nPDugDEM, nPPotDEM   // prethodni promet
   LOCAL nDugBHD, nPotBHD, nDugDEM, nPotDEM
   LOCAL nZDugBHD, nZPotBHD, nZDugDEM, nZPotDEM // zatvorene stavke
   LOCAL cPredhodniPromet // 1 - bez, 2 - sa
   LOCAL hRec
   LOCAL cBrDokFilter

   PRIVATE fK1 := _fin_params[ "fin_k1" ]
   PRIVATE fK2 := _fin_params[ "fin_k2" ]
   PRIVATE fK3 := _fin_params[ "fin_k3" ]
   PRIVATE fK4 := _fin_params[ "fin_k4" ]

   PRIVATE cIdFirma := self_organizacija_id()
   PRIVATE lOtvoreneStavke := lOtvSt
   PRIVATE c1K1Z := "N"
   PRIVATE picBHD := FormPicL( gPicBHD, 16 )
   PRIVATE picDEM := FormPicL( gPicDEM, 12 )

   // PRIVATE cSazeta := "N"
   PRIVATE cK14 := "2" // default prikazati datval

   cDinDem := "1"
   dDatOd := CToD( "" )
   dDatDo := CToD( "" )
   cKumul := "1"
   cPredhodniPromet := "1"
   qqKonto := ""
   qqPartner := ""
   qqBrDok := Space( 40 )
   qqNazKonta := Space( 40 )

   IF PCount() == 0
      lOtvoreneStavke := .F.
   ENDIF

   cKumul := fetch_metric( "fin_kart_kumul", my_user(), cKumul )
   cPredhodniPromet := fetch_metric( "fin_kart_predhodno_stanje", my_user(), cPredhodniPromet )
   cBrza := fetch_metric( "fin_kart_brza", my_user(), cBrza )
   // cSazeta := fetch_metric( "fin_kart_sazeta", my_user(), cSazeta )
   cIdFirma := fetch_metric( "fin_kart_org_id", my_user(), cIdFirma )
   qqKonto := fetch_metric( "fin_kart_konto", my_user(), qqKonto )
   qqPartner := fetch_metric( "fin_kart_partner", my_user(), qqPartner )
   qqBrDok := fetch_metric( "fin_kart_broj_dokumenta", my_user(), qqBrDok )
   dDatOd := fetch_metric( "fin_kart_datum_od", my_user(), dDatOd )
   dDatDo := fetch_metric( "fin_kart_datum_do", my_user(), dDatDo )
   cDinDem := fetch_metric( "fin_kart_valuta", my_user(), cDinDem )
   c1K1Z := fetch_metric( "fin_kart_kz", my_user(), c1K1Z )
   cK14 := fetch_metric( "fin_kart_k14", my_user(), cK14 )
   cIdFirma := self_organizacija_id()

   cK1 := "9"
   cK2 := "9"
   cK3 := "99"
   cK4 := "99"

   IF gDUFRJ == "D"
      cIdRj := Space( 60 )
   ELSE
      cIdRj := "999999"
   ENDIF

   cFunk := "99999"
   cFond := "9999"

   PRIVATE cRasclaniti := "N"
   PRIVATE cIdVN := Space( 40 )

   cBoxName := "SUBANALITIČKA KARTICA"

   IF lOtvoreneStavke
      cBoxName += " - OTVORENE STAVKE"
   ENDIF

   Box( "#" + cBoxName, 25, 65 )

   SET CURSOR ON
   @ m_x + nX, m_y + 2 SAY "LibreOffice kartica (D/N) ?" GET cLibreOffice PICT "@!"
   READ

   IF cLibreOffice == "D"
      BoxC()
      RETURN fin_suban_kartica_sql( lOtvSt )
   ENDIF

   kartica_otvori_tabele()

   ++nX
   @ m_x + ( ++nX ), m_y + 2 SAY "BEZ/SA kumulativnim prometom  (1/2):" GET cKumul
   @ m_x + ( ++nX ), m_y + 2 SAY "BEZ/SA prethodnim prometom (1/2):" GET cPredhodniPromet
   @ m_x + ( ++nX ), m_y + 2 SAY "Brza kartica (D/N)" GET cBrza PICT "@!" VALID cBrza $ "DN"
   // @ m_x + nX, Col() + 2 SAY8 "Sažeta kartica (bez opisa) D/N" GET cSazeta  PICT "@!" VALID cSazeta $ "DN"
   READ

   DO WHILE .T.

      IF gDUFRJ == "D"
         cIdFirma := PadR( self_organizacija_id() + ";", 30 )
         @ m_x + ( ++nX ), m_y + 2 SAY "Firma: " GET cIdFirma PICT "@!S20"
      ELSE

         @ m_x + ( ++nX ), m_y + 2 SAY "Firma "
         ?? self_organizacija_id(), "-", self_organizacija_naziv()
      ENDIF

      IF cBrza == "D"
         qqKonto := PadR( qqKonto, 7 )
         qqPartner := PadR( qqPartner, Len( partn->id ) )
         @ m_x + ( ++nX ), m_y + 2 SAY "Konto  " GET qqKonto  VALID P_KontoFin( @qqKonto )
         @ m_x + ( ++nX ), m_y + 2 SAY "Partner" GET qqPartner VALID Empty( qqPartner ) .OR. RTrim( qqPartner ) == ";" .OR. p_partner( @qqPartner ) PICT "@!"
      ELSE
         qqKonto := PadR( qqkonto, 100 )
         qqPartner := PadR( qqPartner, 100 )
         @ m_x + ( ++nX ), m_y + 2 SAY "Konto  " GET qqKonto  PICTURE "@!S50"
         @ m_x + ( ++nX ), m_y + 2 SAY "Partner" GET qqPartner PICTURE "@!S50"
      ENDIF

      @ m_x + ( ++nX ), m_y + 2 SAY "Datum dokumenta od:" GET dDatod
      @ m_x + nX, Col() + 2 SAY "do" GET dDatDo   VALID dDatOd <= dDatDo
      @ m_x + ( ++nX ), m_y + 2 SAY "Uslov za vrstu naloga (prazno-sve)" GET cIdVN PICT "@!S20"

      IF fin_dvovalutno()
         @ m_x + ( ++nX ), m_y + 2 SAY "Kartica za " + AllTrim( ValDomaca() ) + "/" + AllTrim( ValPomocna() ) + "/" + AllTrim( ValDomaca() ) + "-" + AllTrim( ValPomocna() ) + " (1/2/3)"  GET cDinDem VALID cDinDem $ "123"
      ELSE
         cDinDem := "1"
      ENDIF

      @ m_x + ( ++nX ), m_y + 2 SAY "Prikaz  K1-K4 (1); Dat.Valute (2); oboje (3)" + iif( _fin_params[ "fin_tip_dokumenta" ], "; nista (4)", "" )  GET cK14 VALID cK14 $ "123" + iif( _fin_params[ "fin_tip_dokumenta" ], "4", "" )

      cRasclaniti := "N"

      IF gFinRJ == "D"
         @ m_x + ( ++nX ), m_y + 2 SAY8 "Raščlaniti po RJ/FUNK/FOND; "  GET cRasclaniti PICT "@!" VALID cRasclaniti $ "DN"
      ENDIF

      UpitK1K4( 14 )

      @ Row() + 1, m_y + 2 SAY8 "Uslov za broj veze: " GET qqBrDok PICT "@!S30"
      @ Row() + 1, m_y + 2 SAY8 "(prazno-svi; 61_SP_2-spoji uplate za naloge tipa 61;"
      @ Row() + 1, m_y + 2 SAY8 " **_SP_2 - kupci spojiti uplate za sve vrste naloga; "
      @ Row() + 1, m_y + 2 SAY8 " **_SP_1 - dobavljači spojiti plaćanja za sve vrste naloga)"
      IF cBrza <> "D"
         @ Row() + 1, m_y + 2 SAY8 "Uslov za naziv konta (prazno-svi) " GET qqNazKonta PICT "@!S20"
      ENDIF

      @ Row() + 1, m_y + 2 SAY8 "Općina (prazno-sve):" GET cOpcine
      @ Row() + 1, m_y + 2 SAY "Svaka kartica treba da ima zaglavlje kolona ? (D/N)"  GET c1k1z PICT "@!" VALID c1k1z $ "DN"
      @ Row() + 1, m_y + 2 SAY "Export kartice u dbf ? (D/N)"  GET cExpDbf PICT "@!" VALID cExpDbf $ "DN"

      READ
      ESC_BCR

      IF cExpDbf == "D"
         aExpFields := fin_suban_export_dbf_struct()
         create_dbf_r_export( aExpFields )
      ENDIF


      pRegex := hb_regexComp( "(..)_SP_(\d)" )
      aMatch := hb_regex( pRegex, qqBrDok )
      IF Len( aMatch ) > 0 // aMatch[1]="61_SP_2", aMatch[2]=61, aMatch[3]=2
         cIdVnIzvod :=  aMatch[ 2 ]
         cSpojiDP := aMatch[ 3 ]
         lSpojiUplate := .T.
      ENDIF

      IF !( cK14 $ "123" ) // .AND. ( cSazeta == "D" .OR. gNW == "D" )
         cK14 := "3"
      ENDIF
      // IF cSazeta == "N"
      IF cDinDem == "3"
         nC1 := 59 + iif( _fin_params[ "fin_tip_dokumenta" ], 17, 0 )
      ELSE
         nC1 := 63 + iif( _fin_params[ "fin_tip_dokumenta" ], 17, 0 )
      ENDIF
      // ENDIF

      IF cDinDem == "3"
         cKumul := "1"
      ENDIF

      aUsl3 := parsiraj( cIdVN, "IDVN", "C" )

      IF gDUFRJ == "D"
         aUsl4 := Parsiraj( cIdFirma, "IdFirma" )
         aUsl5 := Parsiraj( cIdRJ, "IdRj" )
      ENDIF

      aNK := Parsiraj( qqNazKonta, "UPPER(naz)", "C" )

      IF cBrza == "D"
         IF aUsl3 <> NIL .AND. iif( gDUFRJ == "D", aUsl4 <> NIL .AND. aUsl5 <> NIL, .T. )
            EXIT
         ENDIF
      ELSE
         qqKonto := Trim( qqKonto )
         qqPartner := Trim( qqPartner )
         aUsl1 := parsiraj( qqKonto, "IdKonto", "C" )
         aUsl2 := parsiraj( qqPartner, "IdPartner", "C" )

         IF  aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. aUsl3 <> NIL .AND. iif( gDUFRJ == "D", aUsl4 <> NIL .AND. aUsl5 <> NIL, .T. )
            EXIT
         ENDIF
      ENDIF

   ENDDO
   BoxC()

   // IF cSazeta == "D"
   // PRIVATE picBHD := FormPicL( gPicBHD, 14 )
   // ENDIF

   set_metric( "fin_kart_kumul", my_user(), cKumul )
   set_metric( "fin_kart_predhodno_stanje", my_user(), cPredhodniPromet )
   set_metric( "fin_kart_brza", my_user(), cBrza )
   // set_metric( "fin_kart_sazeta", my_user(), cSazeta )
   set_metric( "fin_kart_org_id", my_user(), cIdFirma )
   set_metric( "fin_kart_konto", my_user(), qqKonto )
   set_metric( "fin_kart_partner", my_user(), qqPartner )
   set_metric( "fin_kart_broj_dokumenta", my_user(), qqBrDok )
   set_metric( "fin_kart_datum_od", my_user(), dDatOd )
   set_metric( "fin_kart_datum_do", my_user(), dDatDo )
   set_metric( "fin_kart_valuta", my_user(), cDinDem )
   set_metric( "fin_kart_kz", my_user(), c1K1Z )
   set_metric( "fin_kart_k14", my_user(), cK14 )


   IF !lSpojiUplate
      cBrDokFilter := Parsiraj( qqBrDok, "UPPER(BRDOK)", "C" )
   ELSE
      qqBrDok := ""
   ENDIF

   cIdFirma := Trim( cIdFirma )

   IF cDinDem == "3"
      // IF cSazeta == "D"
      // m := "-- -------- ---------- -------- -------- -------------- -------------- -------------- ------------ ------------ ------------"
      // ELSE
      IF _fin_params[ "fin_tip_dokumenta" ] .AND. cK14 == "4"
         m := "-- -------- ---- ---------------- ---------- -------- ---------------- ---------------- ---------------- --------------- ------------- ------------ ------------"
      ELSEIF _fin_params[ "fin_tip_dokumenta" ]
         m := "-- -------- ---- ---------------- ---------- -------- -------- ---------------- ---------------- ---------------- --------------- ------------- ------------ ------------"
      ELSE
         m := "-- -------- ---- ---------- -------- -------- ---------------- ---------------- ---------------- --------------- ------------- ------------ ------------"
      ENDIF
      // ENDIF
   ELSEIF cKumul == "1"
      // IF cSazeta == "D"
      // m := "-- -------- ---------- -------- -------- -------------- -------------- --------------"
      // ELSE
      IF _fin_params[ "fin_tip_dokumenta" ]
         m := "-- -------- ---- ---------------- ---------- -------- -------- -------------------- ---------------- ----------------- ---------------"
      ELSE
         m := "-- -------- ---- ---------- -------- -------- -------------------- ---------------- ----------------- ---------------"
      ENDIF
      // ENDIF
   ELSE
      // IF cSazeta == "D"
      // m := "-- -------- ---------- -------- -------- -------------- ------------- --------------- -------------- --------------"
      // ELSE
      IF _fin_params[ "fin_tip_dokumenta" ] .AND. cK14 == "4"
         m := "-- -------- ---- ---------------- ---------- -------- -------------------- ---------------- ----------------- ---------------- ----------------- ---------------"
      ELSEIF _fin_params[ "fin_tip_dokumenta" ]
         m := "-- -------- ---- ---------------- ---------- -------- -------- -------------------- ---------------- ----------------- ---------------- ----------------- ---------------"
      ELSE
         m := "-- -------- ---- ---------- -------- -------- -------------------- ---------------- ----------------- ---------------- ----------------- ---------------"
      ENDIF
      // ENDIF
   ENDIF

   lVrsteP := .F.

   cOrderBy := "IdFirma,IdKonto,IdPartner,datdok,otvst,idvn,d_p,brdok"

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   IF cBrza == "D"
      IF RTrim( qqPartner ) == ";"
         find_suban_by_konto_partner( cIdFirma, qqKonto, NIL, NIL, cOrderBy )
      ELSE
         find_suban_by_konto_partner( cIdFirma, qqKonto, qqPartner, NIL, cOrderBy )
      ENDIF
   ELSE
      o_sql_suban_kto_partner( cIdFirma )
   ENDIF

   GO TOP
   MsgC()

   IF _fakt_params[ "fakt_vrste_placanja" ]
      lVrsteP := .T.
      O_VRSTEP
   ENDIF

   SELECT SUBAN

   CistiK1k4()

   cFilter := ".t." + iif( !Empty( cIdVN ), ".and." + aUsl3, "" ) + ;
      iif( cBrza == "N", ".and." + aUsl1 + ".and." + aUsl2, "" ) + ;
      iif( Empty( dDatOd ) .OR. cPredhodniPromet == "2", "", ".and.DATDOK>=" + dbf_quote( dDatOd ) ) + ;
      iif( Empty( dDatDo ), "", ".and.DATDOK<=" + dbf_quote( dDatDo ) ) + ;
      iif( fk1 .AND. Len( ck1 ) <> 0, ".and.k1=" + dbf_quote( ck1 ), "" ) + ;
      iif( fk2 .AND. Len( ck2 ) <> 0, ".and.k2=" + dbf_quote( ck2 ), "" ) + ;
      iif( fk3 .AND. Len( ck3 ) <> 0, ".and.k3=ck3", "" ) + ;
      iif( fk4 .AND. Len( ck4 ) <> 0, ".and.k4=" + dbf_quote( ck4 ), "" ) + ;
      iif( gFinRj == "D" .AND. Len( cIdrj ) <> 0, iif( gDUFRJ == "D", ".and." + aUsl5, ".and.idrj=" + dbf_quote( cIdRJ ) ), "" ) + ;
      iif( gTroskovi == "D" .AND. Len( cFunk ) <> 0, ".and.funk=" + dbf_quote( cFunk ), "" ) + ;
      iif( gTroskovi == "D" .AND. Len( cFond ) <> 0, ".and.fond=" + dbf_quote( cFond ), "" ) // + ;


   IF !lSpojiUplate .AND. !Empty( qqBrDok )
      cFilter += ( ".and." + cBrDokFilter )
   ENDIF

   cFilter := StrTran( cFilter, ".t..and.", "" )

   IF Len( cIdFirma ) < 2 .OR. gDUFRJ == "D"
      SET INDEX TO
      IF cRasclaniti == "D"
         INDEX ON idkonto + idpartner + idrj + funk + fond TO SUBSUB for &cFilter
      ELSEIF cBrza == "D" .AND. RTrim( qqPartner ) == ";"
         INDEX ON IdKonto + DToS( DatDok ) + idpartner TO SUBSUB for &cFilter
      ELSE
         INDEX ON IdKonto + IdPartner + DToS( DatDok ) + BrNal + Str( RBr, 5, 0 ) TO SUBSUB for &cFilter
      ENDIF
   ELSE
      IF cRasclaniti == "D"
         SET INDEX TO
         INDEX ON idfirma + idkonto + idpartner + idrj + funk + fond TO SUBSUB for &cFilter
      ELSE
         IF cfilter == ".t."
            SET FILTER TO
         ELSE
            SET FILTER to &cFilter
         ENDIF
      ENDIF
   ENDIF

   GO TOP

   EOF RET

   nStr := 0

   nSviD := 0
   nSviP := 0
   nSviD2 := 0
   nSviP2 := 0


   IF !is_legacy_ptxt()
      oPDF := PDFClass():New()
      xPrintOpt := hb_Hash()
      xPrintOpt[ "tip" ] := "PDF"
      xPrintOpt[ "layout" ] := "portrait"
      xPrintOpt[ "font_size" ] := 7
      xPrintOpt[ "opdf" ] := oPDF
      xPrintOpt[ "left_space" ] := 0
   ENDIF
   IF !start_print( xPrintOpt )
      RETURN .F.
   ENDIF


   prikaz_k1_k4_rj()

   cIdKonto := field->IdKonto

   bEvalSubanKartFirma := {|| !Eof() .AND. iif( gDUFRJ != "D", field->IdFirma == cIdFirma, .T. ) }
   bEvalSubanKartKonto := {|| !Eof() .AND. cIdKonto == field->IdKonto .AND. iif( gDUFRJ != "D", field->IdFirma == cIdFirma, .T. ) }
   bEvalSubanKartPartner :=  {|| !Eof() .AND. cIdKonto == field->IdKonto .AND. ( cIdPartner == hb_UTF8ToStr( field->IdPartner ) ;
      .OR. ( cBrza == "D" .AND. RTrim( qqPartner ) == ";" ) ) ;
      .AND. Rasclan() .AND. iif( gDUFRJ != "D", IdFirma == cIdFirma, .T. ) }


   Eval( bZagl )

   DO WHILE Eval( bEvalSubanKartFirma )

      nKonD := 0
      nKonP := 0
      nKonD2 := 0
      nKonP2 := 0
      cIdKonto := IdKonto
/*
      IF cBrza == "D"
         IF IdKonto <> qqKonto .OR. IdPartner <> qqPartner .AND. RTrim( qqPartner ) != ";"
            EXIT
         ENDIF
      ENDIF
*/
      IF !Empty( qqNazKonta )
         SELECT konto
         HSEEK cIdKonto
         IF !( &( aNK ) )
            SELECT suban
            SKIP 1
            LOOP
         ELSE
            SELECT suban
         ENDIF
      ENDIF

      DO WHILE Eval( bEvalSubanKartKonto )

         cKontoNaziv := ""
         __p_naz := ""

         nPDugBHD := 0
         nPPotBHD := 0
         nPDugDEM := 0
         nPPotDEM := 0  // prethodni promet
         nDugBHD := 0
         nPotBHD := 0
         nDugDEM := 0
         nPotDEM := 0

         nZDugBHD := 0 // zatvorene stavke
         nZPotBHD := 0
         nZDugDEM := 0
         nZPotDEM := 0

         cIdPartner := hb_UTF8ToStr( field->IdPartner )
         nTarea := Select()

         IF !Empty( cOpcine )
            SELECT partn
            SEEK cIdPartner
            IF ! ( Found() .AND. field->id == cIdPartner .AND. AllTrim( field->idops ) $ AllTrim( cOpcine ) )
               SELECT ( nTarea )
               SKIP
               LOOP
            ENDIF
         ENDIF

         SELECT ( nTarea )

         IF cRasclaniti == "D"
            cRasclan := field->idrj + field->funk + field->fond
         ELSE
            cRasclan := ""
         ENDIF

         // IF cBrza == "D"
         // IF IdKonto <> qqKonto
         // EXIT
         // ENDIF
         // ENDIF

         check_nova_strana( bZagl, oPdf, .F., 6 )

         ? m
         ? "KONTO:  "
         @ PRow(), PCol() + 1 SAY cIdKonto

         SELECT KONTO
         HSEEK cIdKonto
         cKontoNaziv := field->naz

         @ PRow(), PCol() + 2 SAY cKontoNaziv
         ? "Partner: "
         @ PRow(), PCol() + 1 SAY iif( cBrza == "D" .AND. RTrim( qqPartner ) == ";", ":  SVI", cIdPartner )
         IF cRasclaniti == "D"
            SELECT rj
            SET ORDER TO TAG "ID"
            SEEK cRasclan
            ? "        "
            @ PRow(), PCol() + 1 SAY Left( cRasclan, 6 ) + "/" + SubStr( cRasclan, 7, 5 ) + "/" + SubStr( cRasclan, 12 ) + " / " + Ocitaj( F_RJ, Left( cRasclan, 6 ), "NAZ" )
            SELECT konto
         ENDIF

         IF !( cBrza == "D" .AND. RTrim( qqPartner ) == ";" )
            SELECT PARTN
            HSEEK cIdPartner
            __p_naz := field->naz
            @ PRow(), PCol() + 1 SAY AllTrim( field->naz )
            @ PRow(), PCol() + 1 SAY AllTrim( field->naz2 )
            @ PRow(), PCol() + 1 SAY field->ZiroR
         ENDIF

         SELECT SUBAN

         check_nova_strana( bZagl, oPdf )

         IF c1K1z != "D"
            ? m
         ENDIF

         lPrviProlaz := .T.  // prvi prolaz

         DO WHILE Eval( bEvalSubanKartPartner )

            IF check_nova_strana( bZagl, oPdf, .F., 6, 0 )

               ? m
               ?U "KONTO: "
               @ PRow(), PCol() + 1 SAY cIdKonto
               SELECT KONTO
               HSEEK cIdKonto
               @ PRow(), PCol() + 2 SAY naz
               ?U "Partner: "
               @ PRow(), PCol() + 1 SAY iif( cBrza == "D" .AND. RTrim( qqPartner ) == ";", ":  SVI", cIdPartner )
               IF !( cBrza == "D" .AND. RTrim( qqPartner ) == ";" )
                  SELECT PARTN
                  HSEEK cIdPartner
                  @ PRow(), PCol() + 1 SAY AllTrim( partn->naz )
                  @ PRow(), PCol() + 1 SAY AllTrim( partn->naz2 )
                  @ PRow(), PCol() + 1 SAY AllTrim( partn->ZiroR )
               ENDIF
               ??U "  "
               @ PRow(), PCol() + 1 SAY Left( cRasclan, 6 ) + "/" + SubStr( cRasclan, 7, 5 ) + "/" + SubStr( cRasclan, 12 )
               SELECT SUBAN
               ? m
            ENDIF

            IF cPredhodniPromet == "2" .AND. lPrviProlaz
               lPrviProlaz := .F.

               DO WHILE  Eval( bEvalSubanKartPartner ) .AND. ( dDatOd > field->DatDok )

                  IF lOtvoreneStavke .AND. OtvSt == "9"
                     IF field->d_P == "1"
                        nZDugBHD += field->iznosbhd
                        nZDugDEM += field->iznosdem
                     ELSE
                        nZPotBHD += field->iznosbhd
                        nZPotDEM += field->iznosdem
                     ENDIF
                  ELSE
                     IF field->d_P == "1"
                        nPDugBHD += field->iznosbhd
                        nPDugDEM += field->iznosdem
                     ELSE
                        nPPotBHD += field->iznosbhd
                        nPPotDEM += field->iznosdem
                     ENDIF
                  ENDIF
                  SKIP
               ENDDO  // prethodni promet

               ? "PROMET DO "; ?? dDatOd
               // IF cSazeta == "D"
               // IF cDinDem == "3"
               // @ PRow(), 36 SAY ""
               // ELSE
               // @ PRow(), 36 SAY ""
               // ENDIF
               // ELSE
               IF cDinDem == "3"
                  IF _fin_params[ "fin_tip_dokumenta" ]
                     @ PRow(), 58 + iif( cK14 == "4", 8, 17 ) SAY ""
                  ELSE
                     @ PRow(), 58 SAY ""
                  ENDIF
               ELSE
                  IF _fin_params[ "fin_tip_dokumenta" ]
                     @ PRow(), 62 + iif( cK14 == "4", 8, 17 ) SAY ""
                  ELSE
                     @ PRow(), 62 SAY ""
                  ENDIF
               ENDIF
               // ENDIF

               nC1 := PCol() + 1
               IF cDinDem == "1"
                  @ PRow(), PCol() + 1 SAY nPDugBHD PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nPPotBHD PICTURE picBHD
                  nDugBHD += nPDugBHD
                  nPotBHD += nPPotBHD
               ELSEIF cDinDem == "2"   // devize
                  @ PRow(), PCol() + 1 SAY nPDugDEM PICTURE picbhd
                  @ PRow(), PCol() + 1 SAY nPPotDEM PICTURE picbhd
                  nDugDEM += nPDugDEM
                  nPotDEM += nPPotDEM
               ELSEIF cDinDem == "3"   // devize
                  @ PRow(), PCol() + 1 SAY nPDugBHD PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nPPotBHD PICTURE picBHD
                  nDugBHD += nPDugBHD
                  nPotBHD += nPPotBHD
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
                  @ PRow(), PCol() + 1 SAY nPDugDEM PICTURE picdem
                  @ PRow(), PCol() + 1 SAY nPPotDEM PICTURE picdem
                  nDugDEM += nPDugDEM
                  nPotDEM += nPPotDEM
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picdem
               ENDIF

               IF cKumul == "2"  // sa kumulativom
                  IF cDinDem == "1"
                     @ PRow(), PCol() + 1 SAY nDugBHD PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picbhd
                  ELSE
                     @ PRow(), PCol() + 1 SAY nDugDEM PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picbhd
                  ENDIF
               ENDIF

               IF cDinDem == "1"  // KM
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
               ELSEIF cDinDem == "2"
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd
               ENDIF

               IF !Eval( bEvalSubanKartPartner )
                  LOOP
               ENDIF

            ENDIF

            hRec := dbf_get_rec()
            nSpojeno := 0
            DO WHILE lSpojiUplate .AND. hRec[ "datdok" ] == field->datdok .AND. hRec[ "otvst" ] == field->otvst .AND. ;
                  field->idvn == hRec[ "idvn" ] .AND. field->d_p == hRec[ "d_p" ] .AND. ;
                  ( field->idvn == cIdVnIzvod .OR. cIdVnIzvod == "**" ) .AND. field->d_p == cSpojiDP .AND. ;
                  Eval( bEvalSubanKartPartner )

               IF nSpojeno > 0
                  hRec[ "iznosbhd" ] += field->iznosbhd
                  hRec[ "iznosdem" ] += field->iznosdem
                  hRec[ "opis" ] := iif( cSpojiDP == "2", "uplate", "placanja" ) + " na dan " + DToC( field->datdok )
                  hRec[ "brdok" ] := iif( hRec[ "otvst" ] == "9", "Z", "O" ) + "-" + DToC( field->datdok )
               ENDIF
               nSpojeno ++
               SKIP
            ENDDO

            IF nSpojeno > 0
               SKIP -1
            ENDIF

            IF !( lOtvoreneStavke .AND. hRec[ "otvst" ] == "9" )


               __vr_nal := hRec[ "idvn" ]
               __br_nal := hRec[ "brnal" ]
               __r_br := hRec[ "rbr" ]
               __dat_nal := hRec[ "datdok" ]
               __dat_val := fix_dat_var( hRec[ "datval" ], .T. )
               __opis := hRec[ "opis" ]
               __br_veze := hRec[ "brdok" ]


               ? hRec[ "idvn" ] // ---- POCETAK STAVKE KARTICE ----
               @ PRow(), PCol() + 1 SAY hRec[ "brnal" ]
               // IF cSazeta == "N"
               @ PRow(), PCol() + 1 SAY hRec[ "rbr" ] PICT "99999"
               IF _fin_params[ "fin_tip_dokumenta" ]
                  @ PRow(), PCol() + 1 SAY hRec[ "idtipdok" ]
                  SELECT TDOK
                  HSEEK SUBAN->IdTipDok
                  @ PRow(), PCol() + 1 SAY PadR( tdok->naz, 13 )
               ENDIF
               // ENDIF

               SELECT SUBAN

               @ PRow(), PCol() + 1 SAY PadR( hRec[ "brdok" ], 10 )
               @ PRow(), PCol() + 1 SAY hRec[ "datdok" ]

               IF cK14 == "1"
                  @ PRow(), PCol() + 1 SAY hRec[ "k1" ] + "-" + hRec[ "k2" ] + "-" + K3Iz256( hRec[ "k3" ] ) + hRec[ "k4" ]
               ELSEIF cK14 == "2"
                  @ PRow(), PCol() + 1 SAY get_datval_field()
               ELSEIF cK14 == "3"
                  nC7 := PCol() + 1
                  @ PRow(), nc7 SAY get_datval_field()
               ENDIF

               // IF cSazeta == "N"
               IF cDinDem == "3"
                  nSirOp := 16
                  nCOpis := PCol() + 1
                  @ PRow(), PCol() + 1 SAY PadR( cOpis := AllTrim( hRec[ "opis" ] ), 16 )
               ELSE
                  nSirOp := 20
                  nCOpis := PCol() + 1
                  @ PRow(), PCol() + 1 SAY PadR( cOpis := AllTrim( hRec[ "opis" ] ), 20 )
               ENDIF
               // ENDIF

               nC1 := PCol() + 1
            ENDIF

            IF cDinDem == "1"

               IF lOtvoreneStavke .AND. hRec[ "otvst" ] == "9"
                  IF hRec[ "d_p" ] == "1"
                     nZDugBHD += hRec[ "iznosbhd" ]   // zatvorena stavka
                  ELSE
                     nZPotBHD += hRec[ "iznosbhd" ]
                  ENDIF
               ELSE

                  IF hRec[ "d_p" ] == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ] PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY 0 PICT picBHD
                     nDugBHD += hRec[ "iznosbhd" ]
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0 PICT picBHD
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ] PICTURE picBHD
                     nPotBHD += hRec[ "iznosbhd" ]
                  ENDIF

                  IF cKumul == "2"   // kumulativni promet
                     @ PRow(), PCol() + 1 SAY nDugBHD PICT picbhd
                     @ PRow(), PCol() + 1 SAY nPotBHD PICT picbhd
                  ENDIF
               ENDIF

            ELSEIF cDinDem == "2" // dvovalutno

               IF lOtvoreneStavke .AND. hRec[ "otvst" ] == "9"
                  IF hRec[ "d_p" ] == "1"
                     nZDugDEM += hRec[ "iznosdem" ]
                  ELSE
                     nZPotDEM += hRec[ "iznosdem" ]
                  ENDIF
               ELSE
                  IF hRec[ "d_p" ] == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY 0 PICTURE picbhd
                     nDugDEM += IznosDEM
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picbhd
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picbhd
                     nPotDEM += hRec[ "iznosdem" ]
                  ENDIF
                  IF cKumul == "2" // kumulativni promet
                     @ PRow(), PCol() + 1 SAY nDugDEM PICT picbhd
                     @ PRow(), PCol() + 1 SAY nPotDEM PICT picbhd
                  ENDIF

               ENDIF

            ELSEIF cDinDem == "3"

               IF lOtvoreneStavke .AND. hRec[ "otvst" ] == "9"
                  IF hRec[ "d_p" ] == "1"
                     nZDugBHD += hRec[ "iznosbhd" ]
                     nZDugDEM += hRec[ "iznosdem" ]
                  ELSE
                     nZPotBHD += hRec[ "iznosbhd" ]
                     nZPotDEM += hRec[ "iznosdem" ]
                  ENDIF
               ELSE  // otvorene stavke
                  IF D_P == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ]PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picBHD
                     nDugBHD += hRec[ "iznosbhd" ]
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosbhd" ] PICTURE picBHD
                     nPotBHD += hRec[ "iznosbhd" ]
                  ENDIF
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
                  IF D_P == "1"
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picdem
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picdem
                     nDugDEM += hRec[ "iznosdem" ]
                  ELSE
                     @ PRow(), PCol() + 1 SAY 0        PICTURE picdem
                     @ PRow(), PCol() + 1 SAY hRec[ "iznosdem" ] PICTURE picdem
                     nPotDEM += hRec[ "iznosdem" ]
                  ENDIF
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picdem
               ENDIF
            ENDIF

            IF !( lOtvoreneStavke .AND. hRec[ "otvst" ] == "9" )
               IF cDinDem = "1"
                  @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
               ELSEIF cDinDem == "2"
                  @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd
               ENDIF

               IF cK14 == "3"
                  @ PRow() + 1, nC7 SAY hRec[ "k1" ] + "-" + hRec[ "k2" ] + "-" + K3Iz256( hRec[ "k3" ] ) + hRec[ "k4" ]
                  IF gFinRj == "D"
                     @ PRow(), PCol() + 1 SAY "RJ:" + hRec[ "idrj" ]
                  ENDIF
                  IF gTroskovi == "D"
                     @ PRow(), PCol() + 1 SAY "Funk.:" + hRec[ "funk" ]
                     @ PRow(), PCol() + 1 SAY "Fond.:" + hRec[ "fond" ]
                  ENDIF
               ENDIF
            ENDIF
            fin_print_ostatak_opisa( @cOpis, nCOpis, {|| check_nova_strana( bZagl, oPDF ) }, nSirOp )

            IF cExpDbf == "D" .AND. !( lOtvoreneStavke .AND. hRec[ "otvst" ] == "9" )

               IF  hRec[ "d_p" ] == "1"
                  nDuguje := hRec[ "iznosbhd" ]
                  nPotrazuje := 0
               ELSE
                  nDuguje := 0
                  nPotrazuje :=  hRec[ "iznosbhd" ]
               ENDIF

               fin_suban_add_item_to_r_export( cIdKonto, cKontoNaziv, cIdPartner, __p_naz, __vr_nal, __br_nal, __r_br, ;
                  __br_veze, __dat_nal, __dat_val, __opis, nDuguje, nPotrazuje, ( nDuguje - nPotrazuje ) )
            ENDIF

            SKIP 1
         ENDDO

         check_nova_strana( bZagl, oPdf, .F., 3 )

         ? M
         ? "UKUPNO:" + cIdkonto + iif( cBrza == "D" .AND. RTrim( qqPartner ) == ";", "", " - " + cIdPartner )

         IF cRasclaniti == "D"
            @ PRow(), PCol() + 1 SAY Left( cRasclan, 6 ) + "/" + SubStr( cRasclan, 7, 5 ) + "/" + SubStr( cRasclan, 12 ) + " / " + Ocitaj( F_RJ, Left( cRasclan, 6 ), "NAZ" )
         ENDIF

         IF cDinDem == "1"
            @ PRow(), nC1      SAY nDugBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
            IF cKumul == "2"
               @ PRow(), PCol() + 1 SAY nDugBHD PICT picbhd
               @ PRow(), PCol() + 1 SAY nPotBHD PICT picbhd
            ENDIF
            @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
         ELSEIF cDinDem == "2"
            @ PRow(), nC1      SAY nDugDEM PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picBHD
            IF cKumul == "2"
               @ PRow(), PCol() + 1 SAY nDugDEM PICT picbhd
               @ PRow(), PCol() + 1 SAY nPotDEM PICT picbhd
            ENDIF
            @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd
         ELSEIF  cDinDem == "3"
            @ PRow(), nC1      SAY nDugBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd

            @ PRow(), PCol() + 1      SAY nDugDEM PICTURE picdem
            @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picdem
            @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picdem
         ENDIF


         IF lOtvoreneStavke
            ? "Promet zatvorenih stavki:"
            IF cDinDem == "1"
               @ PRow(), nC1      SAY nZDugBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZPotBHD PICTURE picBHD
               IF cKumul == "2"
                  @ PRow(), PCol() + 1 SAY nZDugBHD PICT picbhd
                  @ PRow(), PCol() + 1 SAY nZPotBHD PICT picbhd
               ENDIF
               @ PRow(), PCol() + 1 SAY nZDugBHD - nZPotBHD PICT picbhd

            ELSEIF cDinDem == "2"
               @ PRow(), nC1      SAY nZDugDEM PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZPotDEM PICTURE picBHD
               IF cKumul == "2"
                  @ PRow(), PCol() + 1 SAY nZDugDEM PICT picbhd
                  @ PRow(), PCol() + 1 SAY nZPotDEM PICT picbhd
               ENDIF
               @ PRow(), PCol() + 1 SAY nZDugDEM - nZPotDEM PICT picbhd
            ELSEIF  cDinDem == "3"
               @ PRow(), nC1      SAY nZDugBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZPotBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nZDugBHD - nZPotBHD PICT picbhd

               @ PRow(), PCol() + 1 SAY nZDugDEM PICTURE picdem
               @ PRow(), PCol() + 1 SAY nZPotDEM PICTURE picdem
               @ PRow(), PCol() + 1 SAY nZDugDEM - nZPotDEM PICT picdem
            ENDIF
         ENDIF

         ? M

         nKonD += nDugBHD;  nKonP += nPotBHD
         nKonD2 += nDugDEM; nKonP2 += nPotDEM

         IF _fin_params[ "fin_k1" ] .AND. !Len( ck3 ) = 0 .AND. cBrza == "D" .AND. ;
               my_get_from_ini( "FIN", "LimitiPoUgovoru_PoljeK3", "N", SIFPATH ) == "D"
            nLimit  := Abs( Ocitaj( F_ULIMIT, k3iz256( ck3 ) + cIdPartner, "f_limit" ) )
            nSLimit := Abs( nDugBHD - nPotBHD )
            ? "------------------------------"
            ? "LIMIT PO K3  :", TRANS( nLimit, "999999999999.99" )
            ? "SALDO PO K3  :", TRANS( nSLimit, "999999999999.99" )
            ? "R A Z L I K A:", TRANS( nLimit - nSLimit, "999999999999.99" )
            ? "------------------------------"
         ENDIF

         check_nova_strana( bZagl, oPdf, .F., 0, 1 )

      ENDDO // konto

      IF cBrza == "N"

         check_nova_strana( bZagl, oPdf, .F., 3 )
         ? M
         ?U "UKUPNO ZA KONTO: " + cIdKonto
         IF cDinDem == "1"
            @ PRow(), nC1            SAY nKonD  PICTURE picBHD
            @ PRow(), PCol() + 1       SAY nKonP  PICTURE picBHD
            IF cKumul == "2"
               @ PRow(), PCol() + 1       SAY nKonD  PICTURE picBHD
               @ PRow(), PCol() + 1       SAY nKonP  PICTURE picBHD
            ENDIF
            @ PRow(), PCol() + 1  SAY nKonD - nKonP PICT picbhd
         ELSEIF cDinDem == "2"
            @ PRow(), nC1            SAY nKonD2 PICTURE picBHD
            @ PRow(), PCol() + 1       SAY nKonP2 PICTURE picBHD
            IF cKumul == "2"
               @ PRow(), PCol() + 1       SAY nKonD2 PICTURE picBHD
               @ PRow(), PCol() + 1       SAY nKonP2 PICTURE picBHD
            ENDIF
            @ PRow(), PCol() + 1  SAY nKonD2 - nKonP2 PICT picbhd
         ELSEIF cDinDem == "3"
            @ PRow(), nC1            SAY nKonD  PICTURE picBHD
            @ PRow(), PCol() + 1       SAY nKonP  PICTURE picBHD
            @ PRow(), PCol() + 1  SAY nKonD - nKonP PICT picbhd
            @ PRow(), PCol() + 1       SAY nKonD2 PICTURE picdem
            @ PRow(), PCol() + 1       SAY nKonP2 PICTURE picdem
            @ PRow(), PCol() + 1  SAY nKonD2 - nKonP2 PICT picdem

         ENDIF
         ? M


         IF lKarticaNovaStrana
            check_nova_strana( bZagl, oPDF, .T. )
         ELSE
            check_nova_strana( bZagl, oPDF, .F., 0, 1 ) // dodaj 1 prazan red
         ENDIF


      ENDIF

      nSviD += nKonD; nSviP += nKonP
      nSviD2 += nKonD2; nSviP2 += nKonP2

   ENDDO

   IF cBrza == "N"

      check_nova_strana( bZagl, oPdf, .F., 4 )
      ? M
      ?U "UKUPNO ZA SVA KONTA:"
      IF cDinDem == "1"
         @ PRow(), nC1       SAY nSviD        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviP        PICTURE picBHD
         IF cKumul == "2"
            @ PRow(), PCol() + 1  SAY nSviD        PICTURE picBHD
            @ PRow(), PCol() + 1  SAY nSviP        PICTURE picBHD
         ENDIF
         @ PRow(), PCol() + 1  SAY nSviD - nSviP  PICTURE picBHD
      ELSEIF cDinDem == "2"
         @ PRow(), nC1       SAY nSviD2        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviP2        PICTURE picBHD
         IF cKumul == "2"
            @ PRow(), PCol() + 1  SAY nSviD2       PICTURE picBHD
            @ PRow(), PCol() + 1  SAY nSviP2       PICTURE picBHD
         ENDIF
         @ PRow(), PCol() + 1  SAY nSviD2 - nSviP2 PICTURE picBHD
      ELSEIF cDinDem == "3"
         @ PRow(), nC1       SAY nSviD        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviP        PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviD - nSviP  PICTURE picBHD
         @ PRow(), PCol() + 1  SAY nSviD2        PICTURE picdem
         @ PRow(), PCol() + 1  SAY nSviP2        PICTURE picdem
         @ PRow(), PCol() + 1  SAY nSviD2 - nSviP2 PICTURE picdem
      ENDIF
      ? M
      ?

   ENDIF

   end_print( xPrintOpt )

   IF cExpDbf == "D"
      my_close_all_dbf()
      open_r_export_table()
   ENDIF

   my_close_all_dbf()

   RETURN .T.


FUNCTION fin_suban_export_dbf_struct()

   LOCAL aDbf := {}

   AAdd( aDbf, { "id_konto", "C", 7, 0 }  )
   AAdd( aDbf, { "naz_konto", "C", 100, 0 }  )
   AAdd( aDbf, { "id_partn", "C", 6, 0 }  )
   AAdd( aDbf, { "naz_partn", "C", 50, 0 }  )
   AAdd( aDbf, { "vrsta_nal", "C", 2, 0 }  )
   AAdd( aDbf, { "broj_nal", "C", 8, 0 }  )
   AAdd( aDbf, { "nal_rbr", "N", 6, 0 }  )
   AAdd( aDbf, { "broj_veze", "C", 10, 0 }  )
   AAdd( aDbf, { "dat_nal", "D", 8, 0 }  )
   AAdd( aDbf, { "dat_val", "D", 8, 0 }  )
   AAdd( aDbf, { "opis_nal", "C", 100, 0 }  )
   AAdd( aDbf, { "duguje", "N", 15, 5 }  )
   AAdd( aDbf, { "potrazuje", "N", 15, 5 }  )
   AAdd( aDbf, { "saldo", "N", 15, 5 }  )

   RETURN aDbf


STATIC FUNCTION fin_suban_add_item_to_r_export( cKonto, cK_naz, cPartn, cP_naz, cVn, cBr, nRbr, cBrVeze, dDatum, dDatVal, cOpis, nDug, nPot, nSaldo )

   LOCAL nTArea := Select()

   O_R_EXP
   SELECT r_export

   APPEND BLANK
   REPLACE field->id_konto WITH cKonto
   REPLACE field->naz_konto with ( cK_naz )
   REPLACE field->id_partn WITH cPartn
   REPLACE field->naz_partn with ( cP_naz )
   REPLACE field->vrsta_nal WITH cVn
   REPLACE field->broj_nal WITH cBr
   REPLACE field->nal_rbr WITH nRbr
   REPLACE field->broj_veze with ( cBrVeze )
   REPLACE field->dat_nal WITH dDatum
   REPLACE field->dat_val WITH fix_dat_var( dDatVal, .T. )
   REPLACE field->opis_nal with ( cOpis )
   REPLACE field->duguje WITH nDug
   REPLACE field->potrazuje WITH nPot
   REPLACE field->saldo WITH nSaldo

   SELECT ( nTArea )

   RETURN .T.



/*
 *     Postavlja uslov za partnera (npr. Telefon('417'))
 *   param: cTel  - Broj telefona
 */

FUNCTION Telefon( cTel )

   LOCAL nSelect

   nSelect := Select()
   SELECT partn
   HSEEK hb_UTF8ToStr( suban->idpartner )
   SELECT ( nSelect )

   RETURN ( partn->telefon == cTel )




FUNCTION zagl_suban_kartica( cBrza )

   LOCAL _fin_params := fin_params()

   IF is_legacy_ptxt()
      ?
   ENDIF

   IF c1K1z == NIL
      c1K1z := "N"
   ENDIF

   Preduzece()
   IF cDinDem == "3"  .OR. cKumul == "2"
      P_COND2
   ELSE
      P_COND
   ENDIF
   IF lOtvoreneStavke
      ?U "FIN: KARTICA OTVORENIH STAVKI "
   ELSE
      ?U "FIN: SUBANALITIČKA KARTICA ZA "
   ENDIF

   ?? iif( cDinDem == "1", ValDomaca(), iif( cDinDem == "2", ValPomocna(), ValDomaca() + "-" + ValPomocna() ) ), " NA DAN:", Date()

   IF cBrza != "D"
      ??U " KONTO: ", cIdKonto
   ENDIF

   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ??U " ZA PERIOD: ", dDatOd, "-", dDatDo
   ENDIF
   IF !Empty( qqBrDok )
      ?U "Izvještaj pravljen po uslovu za broj veze/računa: '" + Trim( qqBrDok ) + "'"
   ENDIF

   IF is_legacy_ptxt()
      @ PRow(), PCol() + 10 SAY "Str:" + Str( ++nStr, 5 )
   ENDIF

   SELECT SUBAN

   IF cDinDem == "3"
      // IF cSazeta == "D"
      // ?  "----------- --------------------------- ---------------------------- -------------- -------------------------- ------------"
      // ?  "*NALOG     *    D O K U M E N T        *      PROMET  " + ValDomaca() + "          *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO   *"
      // ?  "----------- ------------------- -------- -----------------------------     " + ValDomaca() + "     * -------------------------    " + ValPomocna() + "    *"
      // ?  "*V.* BR    *   BROJ   * DATUM  *" + iif( cK14 == "1", " K1-K4 ", " VALUTA" ) + "*     DUG     *      POT     *              *      DUG    *   POT      *           *"
      // ?  "*N.*       *          *        *       *                            *              *             *            *           *"
      // ELSE
      IF _fin_params[ "fin_tip_dokumenta" ] .AND. cK14 == "4"
         ? "----------------- ----------------------------------------------------- --------------------------------- -------------- -------------------------- -------------"
         ? "*  NALOG         *               D  O  K  U  M  E  N  T                *          PROMET  " + ValDomaca() + "           *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO    *"
         ? "----------------- ------------------------------------ ---------------- ----------------------------------      " + ValDomaca() + "    * --------------------------    " + ValPomocna() + "    *"
         ? "*V.*BR     * R.  *     TIP I      *   BROJ   *  DATUM *    OPIS        *     DUG       *       POT       *              *      DUG    *   POT      *            *"
         ? "*N.*       * Br. *     NAZIV      *          *        *                *               *                 *              *             *            *            *"
      ELSEIF _fin_params[ "fin_tip_dokumenta" ]
         ? "----------------- -------------------------------------------------------------- --------------------------------- -------------- -------------------------- -------------"
         ? "*  NALOG         *                       D  O  K  U  M  E  N  T                 *          PROMET  " + ValDomaca() + "           *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO    *"
         ? "----------------- ------------------------------------ -------- ---------------- ----------------------------------      " + ValDomaca() + "    * --------------------------    " + ValPomocna() + "    *"
         ? "*V.*BR     *  R. *     TIP I      *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    OPIS        *     DUG       *       POT       *              *      DUG    *   POT      *            *"
         ? "*N.*       *  Br.*     NAZIV      *          *        *        *                *               *                 *              *             *            *            *"
      ELSE
         ? "----------------- --------------------------------------------- --------------------------------- -------------- -------------------------- -------------"
         ? "*  NALOG         *           D O K U M E N T                   *          PROMET  " + ValDomaca() + "           *    SALDO     *       PROMET  " + ValPomocna() + "       *   SALDO    *"
         ? "----------------- ------------------- -------- ---------------- ----------------------------------      " + ValDomaca() + "    * --------------------------    " + ValPomocna() + "    *"
         ? "*V.*BR     *  R. *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    OPIS        *     DUG       *       POT       *              *      DUG    *   POT      *            *"
         ? "*N.*       *  Br.*          *        *        *                *               *                 *              *             *            *            *"
      ENDIF
      // ENDIF

   ELSEIF cKumul == "1"

      // IF cSazeta == "D"
      // ?U "------------ ---------------------------- --------------------------- ---------------"
      // ?U "* NALOG     *      D O K U M E N T       *       P R O M E T         *    SALDO     *"
      // ?U "------------ ------------------- -------- ---------------------------               *"
      // ?U "*V.*BR  *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    DUGUJE   *   POTRAŽUJE  *             *"
      // ?U "*N.*    *          *        *        *            *              *              *"
      // ELSE
      IF _fin_params[ "fin_tip_dokumenta" ]
         ?U  "----------------- ------------------------------------------------------------------ ---------------------------------- ---------------"
         ?U  "*  NALOG         *                       D  O  K  U  M  E  N  T                     *           P R O M E T            *    SALDO     *"
         ?U  "----------------- ------------------------------------ -------- -------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R.  *     TIP I      *  BROJ    *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    OPIS            *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br. *     NAZIV      *          *        *        *                    *               *                  *              *"
      ELSE
         ?U  "----------------- ------------------------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG         *            D O K U M E N T                      *           P R O M E T            *    SALDO     *"
         ?U  "----------------- ------------------- -------- -------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R.  *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    OPIS            *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br. *          *        *        *                    *               *                  *              *"
      ENDIF
      // ENDIF
   ELSE
      // IF cSazeta == "D"
      // ?U  "------------ ---------------------------- --------------------------- ----------------------------- ---------------"
      // ?U  "* NALOG     *    D O K U M E N T         *        P R O M E T        *      K U M U L A T I V      *    SALDO     *"
      // ?U  "------------ ------------------- -------- --------------------------- ------------------------------              *"
      // ?U  "*V.*BR      *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*   DUGUJE   *  POTRAŽUJE   *    DUGUJE    *  POTRAŽUJE   *              *"
      // ?  "*N.*        *          *        *        *            *              *              *              *              *"
      // ELSE
      IF _fin_params[ "fin_tip_dokumenta" ] .AND. cK14 == "4"
         ?U  "---------------- --------------------------------------------------------- ---------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG        *               D  O  K  U  M  E  N  T                    *           P R O M E T            *           K U M U L A T I V      *    SALDO     *"
         ?U  "---------------- ------------------------------------ -------------------- ---------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R. *     TIP I      *   BROJ   *  DATUM *    OPIS            *    DUGUJE     *    POTRAŽUJE     *    DUGUJE     *    POTRA¦UJE     *              *"
         ?U  "*N.*       * Br.*     NAZIV      *          *        *                    *               *                  *               *                  *              *"
      ELSEIF _fin_params[ "fin_tip_dokumenta" ]
         ?U  "---------------- ------------------------------------------------------------------ ---------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG        *                       D  O  K  U  M  E  N  T                     *           P R O M E T            *           K U M U L A T I V      *    SALDO     *"
         ?U  "---------------- ------------------------------------ -------- -------------------- ---------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     * R. *     TIP I      *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    OPIS            *    DUGUJE     *    POTRAŽUJE     *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       * Br.*     NAZIV      *          *        *        *                    *               *                  *               *                  *              *"
      ELSE
         ?U  "----------------- ------------------------------------------------- ---------------------------------- ---------------------------------- ---------------"
         ?U  "*  NALOG         *            D O K U M E N T                      *           P R O M E T            *           K U M U L A T I V      *    SALDO     *"
         ?U  "----------------- ------------------- -------- -------------------- ---------------------------------- ----------------------------------               *"
         ?U  "*V.*BR     *  R. *   BROJ   *  DATUM *" + iif( cK14 == "1", " K1-K4  ", " VALUTA " ) + "*    OPIS            *    DUGUJE     *    POTRAZUJE     *    DUGUJE     *    POTRAŽUJE     *              *"
         ?U  "*N.*       *  Br.*          *        *        *                    *               *                  *               *                  *              *"
      ENDIF
      // ENDIF
   ENDIF
   ? m

   RETURN .T.




/*
 *  Rasclanjuje SUBAN->(IdRj+Funk+Fond)
 */

FUNCTION Rasclan()

   IF cRasclaniti == "D"
      RETURN cRasclan == suban->( idrj + funk + fond )
   ELSE
      RETURN .T.
   ENDIF



/*
     Validacija firme - unesi firmu po referenci
     cIdfirma  - id firme
 */

FUNCTION V_Firma( cIdFirma )

   p_partner( @cIdFirma )
   cIdFirma := Trim( cIdFirma )
   cIdFirma := Left( cIdFirma, 2 )

   RETURN .T.



/*
   Prelomi(nDugX,nPotX)
 */
FUNCTION Prelomi( nDugX, nPotX )

   IF ( ndugx - npotx ) > 0
      nDugX := nDugX - nPotX
      nPotX := 0
   ELSE
      nPotX := nPotX - nDugX
      nDugX := 0
   ENDIF

   RETURN .T.

STATIC FUNCTION kartica_otvori_tabele()

   my_close_all_dbf()

   O_KONTO
   O_PARTN
   O_SIFK
   O_SIFV
   O_RJ
   // o_suban()
   O_TDOK

   RETURN .T.
