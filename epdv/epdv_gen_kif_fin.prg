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


STATIC dDatOd
STATIC dDatDo
STATIC cFinPath
STATIC cSifPath
STATIC cTDSrc
STATIC nZaok
STATIC nZaok2
STATIC cIdTar
STATIC cIdPart
STATIC cSBRdok
STATIC cOpis

// kategorija partnera
// 1-pdv obv
// 2-ne pdv obvz
STATIC cKatP

// kategorija partnera 2
// 1-fed
// 2-rs
// 3-bd
STATIC cKatP2

// razbij po danima
STATIC cRazbDan

FUNCTION fin_kif( dD1, dD2, cSezona )

   LOCAL nCount
   LOCAL cIdfirma

   IF cSezona == nil
      cSezona := ""
   ENDIF

   dDatOd := dD1
   dDatDo := dD2

   epdv_otvori_kif_tabele( .T. )

   SELECT F_SG_KIF
   IF !Used()
      O_SG_KIF
   ENDIF

   SELECT F_ROBA
   IF !Used()
      O_ROBA
   ENDIF

   SELECT sg_kif
   GO TOP
   nCount := 0

   DO WHILE !Eof()

      nCount ++

      IF Upper( aktivan ) == "N"
         SKIP
         LOOP
      ENDIF

      @ m_x + 1, m_y + 2 SAY "SG_KIF : " + Str( nCount )

      IF g_src_modul( src ) == "FIN"

         cTdSrc := td_src

         // set id tarifu u kif dokumentu
         cIdTar := s_id_tar
         cIdPart := s_id_part

         cKatP := kat_p
         cKatP2 := kat_p_2

         cOpis := naz

         cRazbDan := razb_dan

         // setuj broj dokumenta
         cSBRdok := s_br_dok

         PRIVATE cFormBPdv := form_b_pdv
         PRIVATE cFormPdv := form_pdv


         PRIVATE cTarFormula := ""
         PRIVATE cTarFilter := ""

         PRIVATE cKtoFormula := ""
         PRIVATE cKtoFilter := ""


         IF ";" $ id_tar
            cTarFilter := Parsiraj( id_tar, "IdTarifa" )
            cTarFormula := ""

         ELSEIF ( "(" $ id_tar ) .AND. ( ")" $ id_tar )
            // zadaje se formula
            cTarFormula := id_tar
            cTarFilter := ""
         ELSE
            cTarFilter := ""
            cTarFormula := ""
         ENDIF

         IF ";" $ id_kto
            cKtoFilter := Parsiraj( id_kto, AllTrim( id_kto_naz ) )
            cKtoFormula := ""

         ELSEIF ( "(" $ id_kto ) .AND. ( ")" $ id_kto )
            // zadaje se formula
            cKtoFormula := id_kto
            cKtoFilter := ""
         ELSE
            cKtoFilter := ""
            cKtoFormula := ""
         ENDIF

         nZaok := zaok
         nZaok2 := zaok2

         gen_fin_kif_item( cSezona )

      ENDIF

      SELECT sg_kif
      SKIP

   ENDDO



FUNCTION close_open_fin_epdv_tables()

   O_SUBAN

   // radi manipulacije kod generisanja kif-a tabela SUBAN se otvara i kao drugi ALIAS
   SELECT ( F_TMP_1 )
   IF !Used()
      my_use_temp( "SUBAN_2", my_home() + "fin_suban", .F., .F. )
   ENDIF
   SELECT suban_2
   SET ORDER TO TAG "4"

   close_open_kuf_kif_sif()

   RETURN


STATIC FUNCTION gen_fin_kif_item( cSezona )

   LOCAL cPomPath
   LOCAL cPomSPath
   LOCAL cDokTar
   LOCAL xDummy
   LOCAL nCount
   LOCAL cPom
   LOCAL cPartRejon
   LOCAL lPdvObveznik
   LOCAL lIno
   LOCAL dDMin
   LOCAL dDMax
   LOCAL dDMinD
   LOCAL dDMaxD
   LOCAL nZ1
   LOCAL nZ2
   LOCAL nZ3
   LOCAL nZ4
   LOCAL nZ5
   LOCAL lSkip
   LOCAL lSkip2
   LOCAL nIznos
   LOCAL cOpisSuban
   LOCAL nRecNoSuban

   close_open_fin_epdv_tables()

   SELECT SUBAN
   PRIVATE cFilter := ""

   cFilter :=  dbf_quote( dDatOd ) + " <= datdok .and. " + dbf_quote( dDatDo ) + ">= datdok"

   // setuj tip dokumenta
   IF !Empty( cTdSrc )
      IF Len( Trim( cTdSrc ) ) == 1
         // ako se stavi "B " onda se uzimaju svi nalozi koji pocinju
         // sa B
         cFilter :=  cFilter + ".and. IdVN = " + dbf_quote( Trim( cTdSrc ) )
      ELSE
         cFilter :=  cFilter + ".and. IdVN == " + dbf_quote( cTdSrc )
      ENDIF
   ENDIF

   IF !Empty( cTarFilter )
      cFilter += ".and. " + cTarFilter
   ENDIF

   IF !Empty( cKtoFilter )
      cFilter +=  ".and. " + cKtoFilter
   ENDIF

   // "4","idFirma+IdVN+BrNal+Rbr",KUMPATH+"SUBAN"
   SET ORDER TO TAG "4"
   SET FILTER TO &cFilter

   GO TOP

   // prosetajmo kroz suban tabelu
   nCount := 0
   DO WHILE !Eof()

      // napuni P_KIF i setuj mem vars
      // ----------------------------------------------
      SELECT p_kif
      Scatter()
      // ----------------------------------------------

      SELECT SUBAN

      dDMin := datdok
      dDMax := datdok

      // ove var moraju biti private da bi se mogle macro-om evaluirati
      PRIVATE _iznos := 0

      // datumski period
      DO WHILE !Eof() .AND.  ( datdok == dDMax )

         SELECT suban

         cBrdok := suban->brnal
         cIdTipDok := suban->IdVn
         cIdFirma := suban->IdFirma

         nRecnoSuban := suban->( RecNo() )
         // datum kif-a
         _datum := suban->datdok
         _id_part := suban->idpartner
         _opis := cOpis

         // ##opis## je djoker - zamjenjuje se sa opisom koji se nalazi u
         // stavci
         cOpisSuban := AllTrim( suban->opis )
         _opis := StrTran( _opis, "##opis##", cOpisSuban )

         IF !Empty( cIdPart )
            IF ( AllTrim( Upper( cIdPart ) ) == "#TD#" )
               // trazi dobavljaca
               _id_part := trazi_dob ( suban->( RecNo() ), ;
                  suban->idfirma, suban->idvn, suban->brnal, ;
                  suban->brdok, suban->rbr )
            ELSE
               _id_part := cIdPart
            ENDIF
         ENDIF

         lIno := IsIno( _id_part )
         lPdvObveznik := IsPdvObveznik( _id_part )

         lSkip := .F.
         DO CASE

         CASE cKatP == "1"

            // samo pdv obveznici
            IF lIno
               lSkip := .T.
            ENDIF

            IF !lPdvObveznik
               lSkip := .T.
            ENDIF

         CASE cKatP == "2"

            IF lPdvObveznik
               lSkip := .T.
            ENDIF

            // samo ne-pdv obveznici, ako je ino preskoci
            IF lIno
               lSkip := .T.
            ENDIF

         CASE cKatP == "3"
            // ino
            IF !lIno
               lSkip := .T.
            ENDIF

         ENDCASE

         cPartRejon := part_rejon( _id_part )

         DO CASE

         CASE cKatP2 == "1"
            // samo federacija
            IF !( ( cPartRejon == " " ) .OR. ( cPartRejon == "1" ) )
               lSkip := .T.
            ENDIF

         CASE cKatP2 == "2"
            // nije rs, preskoci
            IF !( cPartRejon == "2" )
               lSkip := .T.
            ENDIF

         CASE cKatP2 == "3"
            // nije bd, preskoci
            IF !( cPartRejon == "3" )
               lSkip := .T.
            ENDIF
         ENDCASE

         nCount ++

         cPom := "SUBAN : " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok
         @ m_x + 3, m_y + 2 SAY cPom

         cPom := "SUBAN cnt : " + Str( nCount, 6 )
         @ m_x + 4, m_y + 2 SAY cPom



         // tarifa koja se nalazi unutar dokumenta
         cDokTar := ""

         dDMinD := datdok
         dDMaxD := datdok

         // do while !eof() .and. cBrDok == brnal .and. cIdTipDok == IdVN .and. cIdFirma == IdFirma

         // zadaje se formula za tarifu
         lSkip2 := .F.
         IF !Empty( cTarFormula )
            IF ! &( cTarFormula )
               // npr. ABS(trazi_kto("5431")>0)
               lSkip2 := .T.
               SKIP
               LOOP
            ENDIF

         ENDIF

         IF lSkip
            SKIP
            LOOP
         ENDIF

         // na nivou dokumenta utvrdi min max datum
         IF dDMinD > datdok
            dDMinD := datdok
         ENDIF

         IF dDMaxD < datdok
            dDMaxD := datdok
         ENDIF

         // na nivou dat opsega utvrdi min max datum
         IF dDMin > datdok
            dDMinD := datdok
         ENDIF

         IF dDMax < datdok
            dDMax := datdok
         ENDIF


         IF d_p == "1"
            nIznos := iznosbhd
         ELSE
            nIznos := -iznosbhd
         ENDIF

         // broj veze
         cBrDok := brdok

         _iznos += nIznos

         SELECT SUBAN
         SKIP

         // enddo


         IF ( cRazbDan == "D" )
            // razbij po danima
            IF dDMinD <> dDMaxD
               MsgBeep( "U dokumentu " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok + "  se nalaze datumi " + DToC( dDMaxD ) + "-" + DToC( dDMaxD ) + "##" + ;
                  "To nije uredu je se promet razbija po danima !!!" )
            ENDIF

         ENDIF

         IF cRazbDan <> "D"
            // nije po danima
            // za jedan dokument se uzima
            EXIT
            // ako pak jeste "D" onda se vrti u petlji
         ENDIF

         // datumski interval
      ENDDO

      // za datum uzmi datum dokumenta ili najveci datum gore pronadjen
      _datum := dDMax

      IF lSkip .OR. lSkip2
         // vrati se gore
         SELECT SUBAN
         LOOP
      ENDIF

      PRIVATE _uk_pdv :=  0
      PushWA()
      // --------------------------------------------------------------
      SELECT SUBAN
      GO ( nRecNoSuban )

      _iznos := Round( _iznos, nZaok2 )

      IF !Empty( cIdTar )
         // uzmi iz sg sifrarnika tarifu kojom treba setovati
         _id_tar := cIdTar
      ELSE
         // uzmi iz dokumenta
         _id_tar := cDokTar
      ENDIF

      DO CASE
      CASE AllTrim( cSBrDok ) == "#EXT#"
         // extractuj ako je empty cBrDok
         IF Empty( cBrDok )
            // ako nije stavljen broj dokumenta
            // izvuci oznaku iz opisa
            _src_br := extract_oznaka( cOpisSuban )
            _src_br_2 := _src_br
         ELSE
            _src_br := cBrDok
            _src_br_2 := cBrDok
         ENDIF

      CASE !Empty( cSBrDok )
         _src_br := cSBrDok
         _src_br_2 := cSBrDok
      OTHERWISE

         // broj dokumenta
         _src_br := cBrDok
         _src_br_2 := cBrDok
      ENDCASE


      IF !Empty( cFormBPDV )
         _i_b_pdv := &cFormBPdv
      ELSE
         // nema formule koristi ukupan iznos bez pdv-a
         _i_b_pdv := _iznos / 1.17
      ENDIF
      _i_b_pdv := Round( _i_b_pdv, nZaok )

      IF !Empty( cFormPDV )
         _i_pdv := &cFormPdv
      ELSE
         // nema formule koristi ukupan iznos bez pdv-a
         _i_pdv :=  _iznos / 1.17 * 0.17
      ENDIF
      _i_pdv := Round( _i_pdv, nZaok )
      // ----------------------------------------------------------
      PopWa()

      // snimi gornje podatke
      SELECT P_KIF
      APPEND BLANK
      Gather()

      SELECT SUBAN

   ENDDO

   RETURN


// ----------------------------------------------
// ----------------------------------------------
STATIC FUNCTION zav_tr( nZ1, nZ2, nZ3, nZ4, nZ5 )

   LOCAL Skol := 0
   LOCAL nPPP := 0
   LOCAL gKalo := "0"

   SELECT SUBAN

   IF gKalo == "1"
      Skol := Kolicina - GKolicina - GKolicin2
   ELSE
      Skol := Kolicina
   ENDIF

   nPPP := 1

   IF TPrevoz == "%"
      nPrevoz := Prevoz / 100 * FCj2
   ELSEIF TPrevoz == "A"
      nPrevoz := Prevoz
   ELSEIF TPrevoz == "U"
      IF skol <> 0
         nPrevoz := Prevoz / SKol
      ELSE
         nPrevoz := 0
      ENDIF
   ELSE
      nPrevoz := 0
   ENDIF
   nZ1 := nPrevoz

   IF TCarDaz == "%"
      nCarDaz := CarDaz / 100 * FCj2
   ELSEIF TCarDaz == "A"
      nCarDaz := CarDaz
   ELSEIF TCarDaz == "U"
      IF skol <> 0
         nCarDaz := CarDaz / SKol
      ELSE
         nCarDaz := 0
      ENDIF
   ELSE
      nCarDaz := 0
   ENDIF
   nZ2 := nCarDaz

   IF TZavTr == "%"
      nZavTr := ZavTr / 100 * FCj2
   ELSEIF TZavTr == "A"
      nZavTr := ZavTr
   ELSEIF TZavTr == "U"
      IF skol <> 0
         nZavTr := ZavTr / SKol
      ELSE
         nZavTr := 0
      ENDIF
   ELSE
      nZavTr := 0
   ENDIF
   nZ3 := nZavTr


   IF TBankTr == "%"
      nBankTr := BankTr / 100 * FCj2
   ELSEIF TBankTr == "A"
      nBankTr := BankTr
   ELSEIF TBankTr == "U"
      IF skol <> 0
         nBankTr := BankTr / SKol
      ELSE
         nBankTr := 0
      ENDIF
   ELSE
      nBankTr := 0
   ENDIF
   nZ4 := nBankTr

   IF TSpedTr == "%"
      nSpedTr := SpedTr / 100 * FCj2
   ELSEIF TSpedTr == "A"
      nSpedTr := SpedTr
   ELSEIF TSpedTr == "U"
      IF skol <> 0
         nSpedTr := SpedTr / SKol
      ELSE
         nSpedTr := 0
      ENDIF
   ELSE
      nSpedTr := 0
   ENDIF
   nZ5 := nSpedTr

   RETURN

// -----------------------------------------------------------
// trazi dobavljaca za trosak - mora biti u blizini - iznad ili
// ispod samog troska
// -----------------------------------------------------------
STATIC FUNCTION trazi_dob( nRecNo, cIdFirma, cIdVn, cBrNal, cBrDok, nRbr )

   LOCAL i

   PushWA()

   SELECT suban_2

   FOR i := -2 TO 2

      // idi na zadati slog ...
      GO ( nRecNo )
      // pa onda skoci dva unazad i dva unaprijed ...
      SKIP i


      cKto := Left( idkonto, 3 )

      IF ( cKto $ AllTrim( gL_kto_dob ) ) .AND. ( IdFirma ==  cIdFirma ) .AND. ( IdVn == cIdVn ) .AND. ( BrNal == cBrNal ) .AND. ( BrDok == cBrDok )
         // dobavljac
         // ili kreditor
         cIdPartner := idpartner

         PopWa()
         RETURN cIdPartner
      ENDIF

   NEXT

   // nema nista - nisam nista nasao
   PopWa()

   RETURN ""


// ---------------------------------
// ekstraktuje oznaku koja se nalazi
// na kraju stringa
// "SPEDITER 16/06 => "16/06"
// "FAKT.DOB.16/06 => "16/06"
// ---------------------------------
STATIC FUNCTION extract_oznaka( cOpis )

   LOCAL i, nLen, cPom, cChar

   cPom := ""

   cOpis := Trim( cOpis )
   nLen := Len( cOpis )
   FOR i := nLen TO 1 STEP -1
      cChar := SubStr( cOpis, i, 1 )
      IF cChar $ " ."
         EXIT
      ELSE
         cPom := cChar + cPom
      ENDIF
   NEXT

   RETURN cPom
