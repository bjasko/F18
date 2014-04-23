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

#include "fmk.ch"


FUNCTION refresh_me( a_dbf_rec, lSilent, lFromMyUse )

   LOCAL _wa, _del, _cnt, _msg_1, _msg_2
   LOCAL _dbf_pack_algoritam

   IF lSilent == NIL
      lSilent := .T.
   ENDIF

   IF lFromMyUse == NIL
      lFromMyUse := .F.
   ENDIF

   IF a_dbf_rec[ "chk0" ]
      RETURN .F.
   ENDIF

   _wa := a_dbf_rec[ "wa" ]
   set_a_dbf_rec_chk0( a_dbf_rec[ "table" ] )


   _msg_1 := "START refresh_me: " + a_dbf_rec[ "alias" ] + " / " + a_dbf_rec[ "table" ]
   IF ! lSilent
      Box( "#Molimo sačekajte...", 7, 60 )
      @ m_x + 1, m_y + 2 SAY _msg_1
   ENDIF

   log_write( "stanje dbf " +  _msg_1, 8 )

   IF ! lFromMyUse
      // 2) synchro
      SELECT ( _wa )
      my_use( a_dbf_rec[ "alias" ], a_dbf_rec[ "alias" ] )
      USE
   ENDIF

   // 3) ponovo otvori nakon sinhronizacije
   dbf_open_temp( a_dbf_rec, @_cnt, @_del )
   USE

   _msg_1 := "nakon sync: " +  a_dbf_rec[ "alias" ] + " / " + a_dbf_rec[ "table" ]
   _msg_2 := "cnt = " + AllTrim( Str( _cnt, 0 ) ) + " / " + AllTrim( Str( _del, 0 ) )

   IF ! lSilent
      @ m_x + 4, m_y + 2 SAY _msg_1
      @ m_x + 5, m_y + 2 SAY _msg_2
   ENDIF

   log_write( "stanje nakon sync " + _msg_1 + " " + _msg_2, 8 )

   // 4) uradi check i fix ako treba
   //
   // _cnt - _del je broj aktivnih dbf zapisa, dajemo taj info check_recno funkciji
   // ako se utvrti greska uradi full sync
   check_recno_and_fix( a_dbf_rec[ "table" ], _cnt - _del, .T. )

   USE
   _msg_1 := a_dbf_rec[ "alias" ] + " / " + a_dbf_rec[ "table" ]
   _msg_2 := "cnt = "  + AllTrim( Str( _cnt, 0 ) ) + " / " + AllTrim( Str( _del, 0 ) )


   IF ! lSilent
      @ m_x + 4, m_y + 2 SAY _msg_1
      @ m_x + 5, m_y + 2 SAY _msg_2

      BoxC()
   ENDIF

   log_write( "END refresh_me " +  _msg_1 + " " + _msg_2, 8 )

   if hocu_li_pakovati_dbf(_cnt, _del)
     pakuj_dbf( a_dbf_rec, .T. )
   endif

   IF ! lSilent
      BoxC()
   ENDIF

   RETURN .T.


STATIC FUNCTION dbf_open_temp( a_dbf_rec, cnt, del )

   SELECT ( a_dbf_rec[ "wa" ] )
   my_use_temp( a_dbf_rec[ "alias" ], my_home() + a_dbf_rec[ "table" ], .F., .F. )

   SET DELETED OFF

   SET ORDER TO TAG "DEL"
   COUNT TO del
   cnt := RecCount()

   USE
   SET DELETED ON

   RETURN
