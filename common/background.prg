/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "fmk.ch"
#include "hbthread.ch"

THREAD STATIC _log_db_handle := NIL
THREAD STATIC _db_thread_id := NIL

FUNCTION db_trehad_id()
   RETURN _db_thread_id

FUNCTION init_threads()

   LOCAL _main_thread

   _main_thread   :=  hb_threadSelf()
   _db_thread_id  :=  hb_threadStart(  hb_bitOr( HB_THREAD_INHERIT_PUBLIC, HB_THREAD_MEMVARS_COPY ), @_db_thread_fn() )
   // --------------

   RETURN

// SELECT F_PARTN
// if used()
/*
  hb_detach( , {|| refresh_partn() }}

    //hb_dbRequest( [<cAlias>], [<lFreeArea>], [<@xCargo>], [<lWait>] )
   hb_dbRequest( , , @_result, .t. )
   ? "work area atached, used() =>", used(), alias()

   ? "query result:", eval( _result )
   close
   return
*/
// endif

// ---------------------
// ---------------------
FUNCTION _db_thread_fn()

   LOCAL _query_b
   LOCAL _result
   LOCAL _i
   LOCAL _area, _alias
   LOCAL _arr
   LOCAL _used

   IF ( _log_db_handle :=  FCreate( "F18_2.log" ) ) == -1
      ? "Cannot create log file: F18_2.log"
      QUIT_1
   ENDIF


   _arr := gADBFs
   // a_dbfs()

   log_write_db( my_home() )

   DO WHILE .T.

      FOR _i := 1 TO Len( _arr )
         _area := _arr[ _i, 1 ]
         _alias := _arr[ _i, 2 ]

         SELECT ( _area )

         BEGIN SEQUENCE WITH {| err| err:cargo := { ProcName( 1 ), ProcName( 2 ), ProcLine( 1 ), ProcLine( 2 ) }, Break( err ) }
            _used := .F.
            IF Used()
               log_write_db( "_db_thread USED!:" + to_str( Time() ) + " / " + to_str( _i ) + " : "  + to_str( _area ) + " : " + to_str( _alias ) )
            ELSE
               log_write_db( "_db_thread :" + to_str( Time() ) + " / " + to_str( _i ) + " : "  + to_str( _area ) + " : " + to_str( _alias ) )
               my_use( _alias )
               USE
            ENDIF
         recover using _err
            log_write_db( "belaj: " + to_str( _alias ) + " :" +  to_str( _err:cargo[ 1 ] ) + " / " + to_str( _err:cargo[ 3 ] ) )
            log_write_db( "     : " + to_str( _alias ) + " :" +  to_str( _err:cargo[ 2 ] ) + " / " + to_str( _err:cargo[ 4 ] ) )
         END SEQUENCE
      NEXT

      // hb_dbDetach( , {|| _result})
      // endif
      // ? "thread_db end"

      hb_idleSleep( 5 )

   ENDDO

   RETURN


STATIC FUNCTION refresh_partn()

   RETURN .T.


FUNCTION log_write_db( cMsg )

   FWrite( _log_db_handle, cMsg + hb_eol() )

   RETURN
