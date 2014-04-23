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


#include "epdv.ch"

STATIC dDatOd
STATIC dDatDo
STATIC cKalkPath
STATIC cSifPath
STATIC cTDSrc
STATIC nZaok
STATIC nZaok2
STATIC cIdTar
STATIC cIdPart
// setuj broj dokumenta
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

FUNCTION kalk_kif( dD1, dD2, cSezona )

   // {
   LOCAL nCount
   LOCAL cIdfirma

   IF cSezona == nil
      cSezona := ""
   ENDIF

   dDatOd := dD1
   dDatDo := dD2
   o_kif( .T. )

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
	
      IF g_src_modul( src ) == "KALK"
		
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
	
         // za jednu shema gen stavku formiraj kif
         gen_sg_item( cSezona )
		
      ENDIF
	
      SELECT sg_kif
      SKIP

   ENDDO


   // ------------------------------------------
   // ------------------------------------------

STATIC FUNCTION  gen_sg_item( cSezona )

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

   // za jedan dokument
   LOCAL dDMinD
   LOCAL dDMaxD

   LOCAL lSkip
   LOCAL nCijena
   LOCAL cBrFaktP

   // otvori kalk tabelu
   // ------------------------------------------


   cPomPath :=  "KALK"
   cPomSPath :=  ""

   SELECT ( F_KALK )
	
   cKalkPath := cPomPath
	
   IF Used()
      USE
   ENDIF
   my_use ( cPomPath )



   SELECT F_PARTN
   IF Used()
      USE
   ENDIF
   my_use ( "PARTN" )
   SET ORDER TO TAG "ID"
	
   SELECT F_ROBA
   IF Used()
      USE
   ENDIF
   my_use ( "ROBA" )
   SET ORDER TO TAG "ID"

   SELECT F_TARIFA
   IF Used()
      USE
   ENDIF
   my_use ( "TARIFA" )
   SET ORDER TO TAG "ID"

   SELECT F_SIFK
   IF Used()
      USE
   ENDIF
   my_use ( "SIFK" )
   SET ORDER TO TAG "ID"

   SELECT F_SIFV
   IF Used()
      USE
   ENDIF
   my_use ( "SIFV" )
   SET ORDER TO TAG "ID"


   SELECT KALK
   PRIVATE cFilter := ""

   cFilter :=  cm2str( dDatOd ) + " <= datdok .and. " + cm2str( dDatDo ) + ">= datdok"

   // setuj tip dokumenta
   cFilter :=  cFilter + ".and. IdVD == " + cm2str( cTdSrc )

   IF !Empty( cTarFilter )
      cFilter += ".and. " + cTarFilter
   ENDIF

   IF !Empty( cKtoFilter )
      cFilter +=  ".and. " + cKtoFilter
   ENDIF



   // "1","IdFirma+idtipdok+brdok+rbr+podbr"
   SET ORDER TO TAG "1"
   SET FILTER TO &cFilter

   GO TOP

   // prosetajmo kroz kalk tabelu
   nCount := 0
   DO WHILE !Eof()

      // napuni P_KIF i setuj mem vars
      // ----------------------------------------------
      SELECT p_kif
      Scatter()
      // ----------------------------------------------
	
      SELECT KALK

      dDMin := datdok
      dDMax := datdok
	
      // ove var moraju biti private da bi se mogle macro-om evaluirati
      PRIVATE _uk_b_pdv := 0
      PRIVATE _popust := 0

      // datumski period
      DO WHILE !Eof() .AND.  ( datdok == dDMax )

         SELECT kalk

         cBrdok := kalk->brdok
	
         cIdTipDok := kalk->idvd
         cIdFirma := kalk->IdFirma

         // datum kif-a
         _datum := kalk->datdok
         _id_part := kalk->idpartner
         _opis := cOpis

         IF !Empty( cIdPart )
            _id_part := cIdPart
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

         cPom := "KALK : " + cIdFirma + "-" + cIdTipDok + "-" + cBrDok
         @ m_x + 3, m_y + 2 SAY cPom
	
         cPom := "KALK cnt : " + Str( nCount, 6 )
         @ m_x + 4, m_y + 2 SAY cPom
	
	
	
         // tarifa koja se nalazi unutar dokumenta
         cDokTar := ""
	
	
         dDMinD := datdok
         dDMaxD := datdok

	
         // broj fakture partnera
         cBrFaktP := kalk->brfaktp

         DO WHILE !Eof() .AND. cBrDok == brdok .AND. cIdTipDok == IdVd .AND. cIdFirma == IdFirma
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
		

            // pozicioniraj se na artikal u sifranriku robe
            SELECT ROBA
            SEEK kalk->idroba
            SELECT KALK
            cDokTar := roba->idTarifa
		
            _id_tar := kalk->idTarifa
		
		
            IF cTDSrc $ "41#42"
               nCijena := mpc
               // u gornjoj cijeni je uracunat popust
               nPopust := 0
			
            ELSEIF cTdSrc $ "14#11"
               nCijena := vpc
               nPopust := rabatv
			
            ELSE
               nCijena := vpc
               nPopust := rabatv
            ENDIF

		

            _uk_b_pdv += Round( kolicina * ( nCijena * ( 1 - nPopust / 100 ) ), nZaok )
            _popust +=  Round( kolicina * ( nCijena *  nPopust / 100 ), nZaok )
		
            SELECT KALK
            SKIP
         ENDDO

	
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
	
      IF lSkip
         // vrati se gore
         SELECT KALK
         LOOP
      ENDIF
	
	
      _uk_b_pdv := Round( _uk_b_pdv, nZaok2 )
      _uk_popust := Round( _popust, nZaok2 )

      IF !Empty( cIdTar )
         // uzmi iz sg sifrarnika tarifu kojom treba setovati
         _id_tar := cIdTar
      ELSE
         // uzmi iz dokumenta
         _id_tar := cDokTar
      ENDIF

      IF !Empty( cSBrDok )
         _src_br := cSBrDok
         _src_br_2 := cSBrDok
      ELSE
			
         // broj dokumenta
         _src_br := cBrFaktP
         _src_br_2 := cBrFaktP
      ENDIF
	

	
      PRIVATE _uk_pdv :=  _uk_b_pdv * (  g_pdv_stopa( _id_tar ) / 100 )
	
      IF !Empty( cFormBPDV )
         _i_b_pdv := &cFormBPdv
      ELSE
         // nema formule koristi ukupan iznos bez pdv-a
         _i_b_pdv := _uk_b_pdv
      ENDIF
      _i_b_pdv := Round( _i_b_pdv, nZaok )
	
      IF !Empty( cFormPDV )
         _i_pdv := &cFormPdv
      ELSE
         // nema formule koristi ukupan iznos bez pdv-a
         _i_pdv :=  _uk_pdv
      ENDIF
      _i_pdv := Round( _i_pdv, nZaok )

      // snimi gornje podatke
      SELECT P_KIF
      APPEND BLANK
      Gather()
	

      SELECT KALK
   ENDDO

   RETURN
