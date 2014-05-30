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


#include "kalk.ch"


// generisanje dokumenta tipa IM
FUNCTION IM()

   LOCAL cNule := "N"

   lOsvjezi := .F.
   O_KALK_PRIPR
   GO TOP
   IF idvd == "IM"
      IF Pitanje(, "U kalk_pripremi je dokument IM. Generisati samo knjizne podatke?", "D" ) == "D"
         lOsvjezi := .T.
      ENDIF
   ENDIF

   O_KONTO
   O_TARIFA
   O_SIFK
   O_SIFV
   O_ROBA

   cSrSort := "N"

   IF lOsvjezi
 	
      cIdFirma := gFirma
      cIdKonto := kalk_pripr->idKonto
      dDatDok := kalk_pripr->datDok

   ELSE

      Box(, 10, 70 )
      cIdFirma := gFirma
      cIdKonto := PadR( "1310", gDuzKonto )
      dDatDok := Date()
      cArtikli := Space( 30 )
      cPosition := "2"
      cCijenaTIP := "1"
      cNule := "D"
      @ m_x + 1, m_Y + 2 SAY "Magacin:" GET  cIdKonto VALID P_Konto( @cIdKonto )
      @ m_x + 2, m_Y + 2 SAY "Datum:  " GET  dDatDok
      @ m_x + 3, m_Y + 2 SAY "Uslov po grupaciji robe"
      @ m_x + 4, m_Y + 2 SAY "(prazno-sve):" GET cArtikli
      @ m_x + 5, m_Y + 2 SAY "(Grupacija broj mjesta) :" GET cPosition
      @ m_x + 6, m_Y + 2 SAY "Cijene (1-VPC, 2-NC) :" GET cCijenaTIP VALID cCijenaTIP $ "12"
      @ m_x + 7, m_y + 2 SAY "sortirati po sifri dobavljaca :" GET cSRSort ;
         VALID cSRSort $ "DN" PICT "@!"
      @ m_x + 8, m_y + 2 SAY "generisati stavke sa stanjem 0 (D/N)" GET cNule ;
         PICT "@!" VALID cNule $ "DN"
      READ
      ESC_BCR
      BoxC()
   ENDIF

   O_KONCIJ
   O_KALK

   IF lOsvjezi
      PRIVATE cBrDok := kalk_pripr->brdok
   ELSE
      PRIVATE cBrDok := SljBroj( cIdFirma, "IM", 8 )
   ENDIF

   nRbr := 0
   SET ORDER TO TAG "3"


   MsgO( "Generacija dokumenta IM - " + cBrdok )

   SELECT koncij
   SEEK Trim( cIdKonto )

   SELECT kalk
   hseek cIdFirma + cIdKonto

   DO WHILE !Eof() .AND. cIdFirma + cIdKonto == field->idfirma + field->mkonto
	
      cIdRoba := field->idRoba
	
      IF !Empty( cArtikli ) .AND. At( SubStr( cIdRoba, 1, Val( cPosition ) ), AllTrim( cArtikli ) ) == 0
         SKIP
         LOOP
      ENDIF
	
      nUlaz := 0
      nIzlaz := 0
      nVPVU := 0
      nVPVI := 0
      nNVU := 0
      nNVI := 0
      nRabat := 0
	
      DO WHILE !Eof() .AND. cIdFirma + cIdKonto + cIdRoba == idFirma + mkonto + idroba
	  	
         IF dDatdok < field->datdok
            SKIP
            LOOP
         ENDIF
		
         RowVpvRabat( @nVpvU, @nVpvI, @nRabat )
		
         IF cCijenaTIP == "2"
            RowNC( @nNVU, @nNVI )
         ENDIF
		
         RowKolicina( @nUlaz, @nIzlaz )
	  	
         SKIP
      ENDDO

      IF cNule == "D" .OR. ;
            ( ( Round( nUlaz - nIzlaz, 4 ) <> 0 ) .OR. ( Round( nVpvU - nVpvI, 4 ) <> 0 ) )
		
         SELECT roba
         HSEEK cIdroba
		
         SELECT kalk_pripr

         IF lOsvjezi
            // trazi unutar dokumenta
            AzurPostojece( cIdFirma, cIdKonto, cBrDok, dDatDok, @nRbr, cIdRoba, nUlaz, nIzlaz, nVpvU, nVpvI, nNvU, nNvI )
         ELSE
            // dodaj, formira se novi dokument
            DodajImStavku( cIdFirma, cIdKonto, cBrDok, dDatDok, @nRbr, cIdRoba, nUlaz, nIzlaz, nVpvU, nVpvI, nNvU, nNvI )
			
         ENDIF
         SELECT kalk
	
      ELSEIF lOsvjezi
		
         // prije je ova stavka bila <>0 , sada je 0 pa je treba izbrisati
         SELECT kalk_pripr
         SET ORDER TO TAG "3"
         GO TOP
         SEEK cIdFirma + "IM" + cBrDok + cIdRoba
		
         IF Found()
            DELETE
         ENDIF
		
         SELECT KALK
	
      ENDIF

   ENDDO


   IF cSRSort == "D"

      msgo( "sortiram po SIFRADOB ..." )
	
      SELECT kalk_pripr

      SET RELATION TO idroba INTO ROBA
	
      INDEX ON idFirma + idvd + brdok + roba->sifradob TO "SDOB"
      GO TOP

      nRbr := 0

      DO WHILE !Eof()
         scatter()
         _rbr := RedniBroj( ++nRbr )
         my_rlock()
         gather()
         my_unlock()
         SKIP
      ENDDO
	
      msgc()

      SET RELATION TO

   ENDIF

   MsgC()

   my_close_all_dbf()

   RETURN



// generisanje dokumenta tipa IM razlike na osnovu postojece inventure
FUNCTION gen_im_razlika()

   O_KONTO

   Box(, 8, 70 )
   cIdFirma := gFirma
   cIdKonto := PadR( "1310", gDuzKonto )
   dDatDok := Date()
   cArtikli := Space( 30 )
   cPosition := "2"
   cCijenaTIP := "1"
   cOldBrDok := Space( 8 )
   @ m_x + 1, m_Y + 2 SAY "Magacin:" GET  cIdKonto VALID P_Konto( @cIdKonto )
   @ m_x + 2, m_Y + 2 SAY "Datum:  " GET  dDatDok
   @ m_x + 3, m_Y + 2 SAY "Uslov po grupaciji robe"
   @ m_x + 4, m_Y + 2 SAY "(prazno-sve):" GET cArtikli
   @ m_x + 5, m_Y + 2 SAY "(Grupacija broj mjesta) :" GET cPosition
   @ m_x + 6, m_Y + 2 SAY "Cijene (1-VPC, 2-NC) :" GET cCijenaTIP VALID cCijenaTIP $ "12"
   @ m_x + 8, m_Y + 2 SAY "Na osnovu dokumenta " + cIdFirma + "-IM" GET cOldBrDok
   READ
   ESC_BCR
   BoxC()

   IF Pitanje(, "Generisati inventuru magacina (D/N)", "D" ) == "N"
      RETURN
   ENDIF

   cIdVd := "IM"

   // kopiraj postojecu IM u pript
   IF cp_dok_pript( cIdFirma, cIdVd, cOldBrDok ) == 0
      RETURN
   ENDIF

   O_TARIFA
   O_SIFK
   O_SIFV
   O_ROBA
   O_KALK_PRIPR
   O_PRIPT
   O_KONCIJ
   O_KALK_DOKS
   O_KALK

   PRIVATE cBrDok := SljBroj( cIdFirma, "IM", 8 )

   SELECT kalk
   SET ORDER TO TAG "3"

   nRbr := 0

   MsgO( "Generacija dokumenta IM - " + cBrdok )


   SELECT koncij
   SEEK Trim( cIdKonto )

   SELECT kalk
   hseek cIdFirma + cIdKonto

   DO WHILE !Eof() .AND. cIdFirma + cIdKonto == field->idfirma + field->mkonto
	
      cIdRoba := field->idRoba
	
      SELECT pript
      SET ORDER TO TAG "2"
      hseek cIdFirma + cIdVd + cOldBrDok + cIdRoba
	
      // ako sam nasao prekoci ovaj zapis
      IF Found()
         SELECT kalk
         SKIP
         LOOP
      ENDIF
	
      SELECT kalk
	
      IF !Empty( cArtikli ) .AND. At( SubStr( cIdRoba, 1, Val( cPosition ) ), AllTrim( cArtikli ) ) == 0
         SKIP
         LOOP
      ENDIF
	
      nUlaz := 0
      nIzlaz := 0
      nVPVU := 0
      nVPVI := 0
      nNVU := 0
      nNVI := 0
      nRabat := 0
      DO WHILE !Eof() .AND. cIdFirma + cIdKonto + cIdRoba == idFirma + mkonto + idroba
         IF dDatdok < field->datdok
            SKIP
            LOOP
         ENDIF
         RowVpvRabat( @nVpvU, @nVpvI, @nRabat )
         IF cCijenaTIP == "2"
            RowNC( @nNVU, @nNVI )
         ENDIF
         RowKolicina( @nUlaz, @nIzlaz )
         SKIP
      ENDDO

      IF ( Round( nUlaz - nIzlaz, 4 ) <> 0 ) .OR. ( Round( nVpvU - nVpvI, 4 ) <> 0 )
         SELECT roba
         HSEEK cIdroba
         SELECT kalk_pripr
         DodajImStavku( cIdFirma, cIdKonto, cBrDok, dDatDok, @nRbr, cIdRoba, nUlaz, nIzlaz, nVpvU, nVpvI, nNvU, nNvI, .T. )
			
         SELECT kalk
      ENDIF
   ENDDO

   MsgC()

   my_close_all_dbf()

   RETURN



FUNCTION AzurPostojece( cIdFirma, cIdKonto, cBrDok, dDatDok, nRbr, cIdRoba, nUlaz, nIzlaz, nVpvU, nVpvI, nNvU, nNvI, cSrSort )

   IF cSrSort == nil
      cSrSort := "N"
   ENDIF

   IF cSrSort == "D"
      SET ORDER TO "SDOB"
   ELSE
      SET ORDER TO TAG "3"
   ENDIF

   GO TOP
   SEEK cIdFirma + "IM" + cBrDok + cIdRoba

   IF Found()
      Scatter()
      _gkolicina := nUlaz - nIzlaz
      _ERROR := ""
      // knjizno stannje
      _fcj := nVpvu - nVpvi
      my_rlock()
      Gather()
      my_unlock()
   ELSE
      GO BOTTOM
      nRbr := Val( AllTrim( field->rbr ) )
      Scatter()
      APPEND NCNL
      _idfirma := cIdFirma
      _idkonto := cIdKonto
      _mkonto := cIdKonto
      _mu_i := "I"
      _idroba := cIdroba
      _idtarifa := roba->idTarifa
      _idvd := "IM"
      _brdok := cBrdok
      _rbr := RedniBroj( ++nRbr )
      _kolicina := nUlaz - nIzlaz
      _gkolicina := nUlaz - nIzlaz
      _DatDok := dDatDok
      _DatFaktP := dDatdok
      _ERROR := ""
      _fcj := nVpvU - nVpvI
      IF Round( nUlaz - nIzlaz, 4 ) <> 0
         _vpc := Round( ( nVPVU - nVPVI ) / ( nUlaz - nIzlaz ), 3 )
      ELSE
         _vpc := 0
      ENDIF
      IF Round( nUlaz - nIzlaz, 4 ) <> 0
         _nc := Round( ( nNvU - nNvI ) / ( nUlaz - nIzlaz ), 3 )
      ELSE
         _nc := 0
      ENDIF

      Gather2()
   ENDIF

   RETURN



STATIC FUNCTION DodajImStavku( cIdFirma, cIdKonto, cBrDok, dDatDok, nRbr, cIdRoba, nUlaz, nIzlaz, nVpvU, nVpvI, nNcU, nNcI, lKolNula, cSrSort )

   IF cSrSort == nil
      cSrSort := "N"
   ENDIF

   IF lKolNula == nil
      lKolNula := .F.
   ENDIF

   Scatter()
   APPEND NCNL
   _IdFirma := cIdFirma
   _IdKonto := cIdKonto
   _mKonto := cIdKonto
   _mU_I := "I"
   _IdRoba := cIdroba
   _IdTarifa := roba->idtarifa
   _IdVd := "IM"
   _Brdok := cBrdok
   _RBr := RedniBroj( ++nRbr )
   _kolicina := _gkolicina := nUlaz - nIzlaz

   IF lKolNula // ako je lKolNula setuj na 0 popisanu kolicinu
      _kolicina := 0
   ENDIF

   _datdok := dDatDok
   _DatFaktP := dDatdok
   _ERROR := ""
   _fcj := nVpvu - nVpvi

   IF Round( nUlaz - nIzlaz, 4 ) <> 0
      _vpc := Round( ( nVPVU - nVPVI ) / ( nUlaz - nIzlaz ), 3 )
   ELSE
      _fcj := 0
      _vpc := 0
   ENDIF

   IF Round( nUlaz - nIzlaz, 4 ) <> 0 .AND. nNcI <> NIL .AND. nNcU <> nil
      _nc := Round( ( nNcU - nNcI ) / ( nUlaz - nIzlaz ), 3 )
   ELSE
      _nc := 0
   ENDIF

   Gather2()

   RETURN



FUNCTION RowKolicina( nUlaz, nIzlaz )

   IF field->mu_i == "1" .AND. !( field->idVd $ "12#22#94" )
      nUlaz += field->kolicina - field->gkolicina - field->gkolicin2
   ELSEIF field->mu_i == "1" .AND. ( field->idVd $ "12#22#94" )
      nIzlaz -= field->kolicina
   ELSEIF field->mu_i == "5"
      nIzlaz += field->kolicina
   ELSEIF mu_i == "3"
      // nivelacija
   ENDIF

   RETURN


FUNCTION RowVpvRabat( nVpvU, nVpvI, nRabat )

   IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
      nVPVU += vpc * ( kolicina - gkolicina - gkolicin2 )
   ELSEIF mu_i == "5"
      nVPVI += vpc * kolicina
      nRabat += vpc * rabatv / 100 * kolicina
   ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )
      // povrat
      nVPVI -= vpc * kolicina
      nRabat -= vpc * rabatv / 100 * kolicina
   ELSEIF mu_i == "3"
      nVPVU += vpc * kolicina
   ENDIF

   RETURN



/*! \fn RowNC(nNcU, nNcI)
 *  \brief Popunjava polja NC
 */

FUNCTION RowNC( nNcU, nNcI )

   IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
      nNcU += nc * ( kolicina - gkolicina - gkolicin2 )
   ELSEIF mu_i == "5"
      nNcI += nc * kolicina
   ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )
      // povrat
      nNcI -= nc * kolicina
   ELSEIF mu_i == "3"
      nNcU += nc * kolicina
   ENDIF

   RETURN
