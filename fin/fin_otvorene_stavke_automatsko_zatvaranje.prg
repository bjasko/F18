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


FUNCTION fin_automatsko_zatvaranje_otvorenih_stavki( lAuto, cKto, cPtn )

   LOCAL _rec
   LOCAL  nDugBHD := 0, nPotBHD := 0
   LOCAL lOk := .T.
   LOCAL hParams
   LOCAL cIdFirma, cIdKonto, cIdPartner
   LOCAL nCntZatvoreno

   IF lAuto == nil
      lAuto := .F.
   ENDIF

   IF cPtn == nil
      cPtn := ""
   ENDIF

   IF cKto == nil
      cKto := ""
   ENDIF

   cIdFirma := gFirma
   cIdKonto := Space( 7 )
   cIdPartner := Space( 6 )

   IF lAuto
      cIdKonto := cKto
      cIdPartner := cPtn
      cPobSt := "D"
   ENDIF

   qqPartner := Space( 60 )
   picD := "@Z " + FormPicL( "9 " + gPicBHD, 18 )
   picDEM := "@Z " + FormPicL( "9 " + gPicDEM, 9 )

   O_PARTN
   O_KONTO

   IF !lAuto

      Box( "AZST", 6, 65, .F. )

      SET CURSOR ON

      cPobST := "N"

      @ m_x + 1, m_y + 2 SAY "AUTOMATSKO ZATVARANJE STAVKI"

      @ m_x + 3, m_y + 2 SAY "Firma "
      ?? gFirma, "-", AllTrim( gNFirma )

      @ m_x + 4, m_y + 2 SAY "Konto: " GET cIdKonto VALID P_KontoFin( @cIdKonto )
      @ m_x + 5, m_y + 2 SAY "Partner (prazno-svi): " GET cIdPartner ;
         VALID {|| Empty( cIdPartner ) .OR. P_Firma( @cIdPartner ) }
      @ m_x + 6, m_y + 2 SAY "Pobrisati stare markere zatv.stavki: " GET cPobSt PICT "@!" VALID cPobSt $ "DN"

      READ
      ESC_BCR

      BoxC()

   ENDIF

   cIdFirma := Left( cIdFirma, 2 )

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_suban_by_konto_partner( cIdFirma, cIdKonto, iif( Empty( cIdPartner ), NIL, cIdPartner ), NIL, "IdFirma,IdKonto,IdPartner,brdok" )
   MsgC()

   EOF CRET

   IF cPobSt == "D" .AND. Pitanje(, "Želite li zaista pobrisati markere ??", "N" ) == "D"
      IF !ponisti_markere_postojecih_stavki( cIdFirma, cIdKonto, cIdPart )
         RETURN .F.
      ENDIF
   ENDIF

   Box( "count", 1, 60, .F. )

   nCntZatvoreno := 0

   @ m_x + 1, m_y + 2 SAY "Zatvoreno:"
   @ m_x + 1, m_y + 12 SAY nCntZatvoreno

   EOF CRET

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fin_suban" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabelu fin_suban !#Prekidam operaciju zatvaranja stavki." )
      RETURN .F.
   ENDIF

   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto


      cIdPartner := IdPartner
      cBrDok := BrDok
      cOtvSt := " "
      nDugBHD := nPotBHD := 0
      nRbrStartBrDok :=  RecNo()
      DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto .AND. cIdPartner == IdPartner .AND. cBrDok == BrDok
         IF D_P = "1"
            nDugBHD += IznosBHD
            cOtvSt := "1"
         ELSE
            nPotBHD += IznosBHD
            cOtvSt := "1"
         ENDIF
         SKIP
      ENDDO

      IF Abs( Round( nDugBHD - nPotBHD, 3 ) ) <= gnLOSt .AND. cOtvSt == "1"

         GO nRbrStartBrDok
         @ m_x + 1, m_y + 2 SAY cIdKonto + "-" + cIdPartner + "/" + cBrDok
         @ m_x + 1, Col() + 2 SAY ++nCntZatvoreno PICT '99999'

         DO WHILE !Eof() .AND. cIdKonto = IdKonto .AND. cIdPartner == IdPartner .AND. cBrDok == BrDok

            _rec := dbf_get_rec()
            _rec[ "otvst" ] := "9"

            lOk := update_rec_server_and_dbf( "fin_suban", _rec, 1, "CONT" )

            IF !lOk
               EXIT
            ENDIF

            SKIP

         ENDDO

         log_write( "F18_DOK_OPER, automatsko zatvaranje stavki, OASIST, duguje: " + AllTrim( Str( nDugBHD, 12, 2 ) ) + ", potrazuje: " + AllTrim( Str( nPotBHD, 12, 2 ) ) + " firma: " + cIdFirma + " konto: " + cIdKonto, 2 )

      ENDIF

      IF !lOk
         EXIT
      ENDIF

   ENDDO

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fin_suban" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Greška sa opcijom automatskog zatvaranja stavki !#Operacija poništena." )
   ENDIF

   BoxC()

   my_close_all_dbf()

   RETURN lOk



STATIC FUNCTION ponisti_markere_postojecih_stavki( cIdFirma, cIdKonto, cIdPartner )

   LOCAL _rec
   LOCAL lRet := .F.
   LOCAL lOk := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fin_suban" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN lRet
   ENDIF

   Box(, 3, 65 )

   @ m_x + 1, m_y + 2 SAY8 "Brišem markere postojećih stavki tabele..."

   DO WHILE !Eof() .AND. idfirma == cidfirma .AND. cIdKonto = IdKonto

      IF !Empty( cIdPartner )
         IF ( cIdPartner <> idpartner )
            SKIP
            LOOP
         ENDIF
      ENDIF

      _rec := dbf_get_rec()
      _rec[ "otvst" ] := " "

      @ m_x + 2, m_y + 2 SAY "nalog: " + _rec[ "idvn" ] + "-" + AllTrim( _rec[ "brnal" ] ) + " / stavka: " + Str( _rec[ "rbr" ], 5, 0 )

      lOk := update_rec_server_and_dbf( "fin_suban", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SKIP

   ENDDO

   BoxC()

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "fin_suban" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
      lRet := .F.
   ENDIF

   RETURN lRet
