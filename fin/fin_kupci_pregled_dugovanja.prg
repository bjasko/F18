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



FUNCTION fin_kupci_pregled_dugovanja()

   LOCAL i
   LOCAL oReport, cSql
   LOCAL cIdKonto := PadR( "21", 7 )
   LOCAL cIdPartner := Space( 6 )
   LOCAL dDatOd := CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) )
   LOCAL dDatDo := Date()
   LOCAL cAvans := "N"

   Box(, 5, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2  SAY "Datum od " GET dDatOd
   @ box_x_koord() + 1, Col() + 2 SAY "do" GET dDatDo
   @ box_x_koord() + 3, box_y_koord() + 2  SAY "Konto% duguje: " GET cIdKonto
   @ box_x_koord() + 4, box_y_koord() + 2  SAY "Partner% (prazno svi): " GET cIdPartner
   @ box_x_koord() + 5, box_y_koord() + 2  SAY8 "Prikaz kupaca koji su u avansu D/N?" GET cAvans PICT "@!" VALID cAvans $ "DN"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   download_template( "kupci_pregled_dugovanja.xlsx", "cec90f10beff71ca9ac3f487b7d1734dca727b1953c3bb8d3683313a25b35e27" )
   
   oReport := YargReport():New( "kupci_pregled_dugovanja", "xlsx", "Header#BandSql1" )
   cSql := "select * from sp_dugovanja("
   cSql += sql_quote( dDatOd ) + ","
   cSql += sql_quote( dDatDo ) + ","
   cSql += sql_quote( Trim( cIdKonto ) + "%" ) + ","
   cSql += sql_quote( Trim( cIdPartner ) + "%" ) + ")"

   IF cAvans == "N"
      cSql += " WHERE i_ukupno>0"
   ELSE
      cSql += " WHERE i_ukupno<>0 "
   ENDIF

   // cSql += " WHERE i_ukupno"+to_xml_encoding("<>")+"0"
   // cSql += " AND idkonto=" + to_xml_encoding(sql_quote( Padr( "2110", 7) ))
   oReport:aSql := { cSql }

/*   oReport:aRecords := {}


   FOR i := 1 TO 1000
      hRec := hb_Hash()
      hRec[ "partner_id" ] := "000" + AllTrim( Str ( i ) )
      hRec[ "partner_naz" ] := "naz " + Str( i )
      hRec[ "i_ukupno" ] := i

      AAdd( oReport:aRecords, hRec )
   NEXT
*/
   oReport:run()

   RETURN .T.
