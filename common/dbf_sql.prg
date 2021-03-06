/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/*
 lNoLock - ne zakljucavaj
*/

FUNCTION dbf_update_rec( hRec, lNoLock )

   LOCAL _key
   LOCAL _field_b
   LOCAL cMsg
   LOCAL _a_dbf_rec
   LOCAL lSql := ( my_rddName() == "SQLMIX" )

   IF lNoLock == NIL
      lNoLock := .F.
   ENDIF

   IF !Used()
      cMsg := "dbf_update_rec - nema otvoren dbf"
      log_write( cMsg, 1 )
      Alert( cMsg )
      // QUIT_1
      RETURN .F.
   ENDIF

   IF lNoLock .OR. my_rlock()

      _a_dbf_rec := get_a_dbf_rec( Alias(), .F. )

      FOR EACH _key in hRec:Keys


         IF field_in_blacklist( _key, _a_dbf_rec[ "blacklisted" ] )  // blacklistovano polje
            LOOP
         ENDIF


         IF FieldPos( _key ) == 0 // replace polja
            cMsg := RECI_GDJE_SAM + " dbf field " + _key + " ne postoji u " + Alias()
            // Alert(cMsg)
            log_write( cMsg, 1 )
         ELSE
            _field_b := FieldBlock( _key )

            // napuni field sa vrijednosti
            IF ValType( hRec[ _key ] ) == "C" .AND. lSql .AND. F18_SQL_ENCODING == "UTF8"
               hRec[ _key ] := hb_StrToUTF8( hRec[ _key ] )  // proklete_kvacice - konvertuj SQLMix record u UTF-8
            ENDIF
            Eval( _field_b, hRec[ _key ] )

         ENDIF

      NEXT

      IF !lNoLock
         my_unlock()
      ENDIF
   ELSE
      MsgBeep( "Ne mogu rlock-ovati:" + Alias() )
      RETURN .F.
   ENDIF

   RETURN .T.
