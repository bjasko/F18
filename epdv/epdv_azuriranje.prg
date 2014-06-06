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

FUNCTION azur_kif()
   RETURN azur_ku_ki( "KIF" )

FUNCTION azur_kuf()
   RETURN azur_ku_ki( "KUF" )


FUNCTION pov_kuf( nBrDok )
   RETURN pov_ku_ki( "KUF", nBrDok )

FUNCTION pov_kif( nBrDok )
   RETURN pov_ku_ki( "KIF", nBrDok )


FUNCTION azur_ku_ki( cTbl )

   LOCAL nBrDok
   LOCAL _rec
   PUBLIC __br_dok := 0

   IF cTbl == "KUF"
      epdv_otvori_kuf_tabele( .T. )
      nPArea := F_P_KUF
      nKArea := F_KUF
   ELSE
      epdv_otvori_kif_tabele( .T. )
      nPArea := F_P_KIF
      nKArea := F_KIF
   ENDIF

   Box(, 2, 60 )

   nCount := 0

   SELECT ( nPArea )
   IF RECCOUNT2() == 0
      RETURN 0
   ENDIF

   nNextGRbr := next_g_r_br( cTbl )

   SELECT ( nPArea )
   GO TOP

   IF ( field->br_dok == 0 )
      nNextBrDok := next_br_dok( cTbl )
      nBrdok := nNextBrDok
   ELSE
      nBrDok := field->br_dok
   ENDIF

   IF kuf_kif_azur_sql( cTbl, nNextGRbr, nBrDok )
	
      SELECT ( nPArea )
      GO TOP

      DO WHILE !Eof()
	
         set_global_memvars_from_dbf()
	
         _datum_2 := Date()
         _g_r_br := nNextGRbr
	
         _br_dok := nBrDok
         __br_dok := _br_dok

         ++nCount
         @ m_x + 1, m_y + 2 SAY PadR( "Dodajem P_KIF -> KUF " + Transform( nCount, "9999" ), 40 )
         @ m_x + 2, m_y + 2 SAY PadR( "   " + cTbl + " G.R.BR: " + Transform( nNextGRbr, "99999" ), 40 )

         nNextGRbr ++
	
         SELECT ( nKArea )
         APPEND BLANK

         _rec := get_dbf_global_memvars()
         dbf_update_rec( _rec )

         SELECT ( nPArea )
         SKIP
      ENDDO

   ELSE

      msgbeep( "Neuspješno ažuriranje epdv/sql !" )
      RETURN

   ENDIF

   SELECT ( nKArea )
   USE

   @ m_x + 1, m_y + 2 SAY8 PadR( "Brišem pripremu ...", 40 )

   SELECT ( nPArea )
   my_dbf_zap()

   USE

   IF ( cTbl == "KUF" )
      epdv_otvori_kuf_tabele( .T. )
   ELSE
      epdv_otvori_kif_tabele( .T. )
   endif

   BoxC()

   MsgBeep( "Ažuriran je " + cTbl + " dokument " + Str( __br_dok, 6, 0 ) )

   RETURN __br_dok



FUNCTION kuf_kif_azur_sql( tbl, next_g_rbr, next_br_dok )

   LOCAL lOk := .T.
   LOCAL record := hb_Hash()
   LOCAL _tbl_epdv
   LOCAL _i
   LOCAL _tmp_id
   LOCAL _ids := {}
   LOCAL __area

   IF tbl == "KIF"
      __area := F_P_KIF
   ELSEIF tbl == "KUF"
      __area := F_P_KUF
   ENDIF

   _tbl_epdv := "epdv_" + Lower( tbl )

   IF !f18_lock_tables( { _tbl_epdv } )
      RETURN .F.
   ENDIF

   lOk := .T.

   MsgO( "sql " + _tbl_epdv )
   sql_table_update( nil, "BEGIN" )

   IF lOk = .T.

      SELECT ( __area )
      GO TOP

      DO WHILE !Eof()

         record := dbf_get_rec()
         record[ "datum_2" ] := Date()
         record[ "br_dok" ] := next_br_dok
         record[ "g_r_br" ] := next_g_rbr

         IF tbl == "KIF"
            record[ "src_pm" ] := field->src_pm
         ENDIF

         _tmp_id := "#2" + PadL( AllTrim( Str( record[ "br_dok" ], 6 ) ), 6 )

         IF !sql_table_update( _tbl_epdv, "ins", record )
            lOk := .F.
            EXIT
         ENDIF

         SKIP

      ENDDO

      MsgC()

   ENDIF

   IF !lOk
      sql_table_update( nil, "ROLLBACK" )
   ELSE
      AAdd( _ids, _tmp_id )
      push_ids_to_semaphore( _tbl_epdv, _ids )
      sql_table_update( nil, "END" )
   ENDIF

   f18_free_tables( { _tbl_epdv } )

   RETURN lOk



FUNCTION pov_ku_ki( cTbl, nBrDok )

   LOCAL _del_rec, _ok
   LOCAL _rec
   LOCAL _p_area
   LOCAL _k_area
   LOCAL _cnt
   LOCAL _table

   IF ( cTbl == "KUF" )
      epdv_otvori_kuf_tabele( .T. )
      _p_area := F_P_KUF
      _k_area := F_KUF
      _table := "epdv_kuf"
   ELSE
      epdv_otvori_kif_tabele( .T. )
      _p_area := F_P_KIF
      _k_area := F_KIF
      _table := "epdv_kif"
   ENDIF

   _cnt := 0

   SELECT ( _k_area )
   SET ORDER TO TAG "BR_DOK"
   SEEK Str( nBrdok, 6, 0 )


   IF !Found()
      SELECT ( _p_area )
      RETURN 0
   ENDIF

   SELECT ( _p_area )
   IF RECCOUNT2() > 0
      MsgBeep( "U pripremi postoji dokument#Ne može se izvršiti povrat#operacija prekinuta !" )
      RETURN -1
   ENDIF

   Box(, 2, 60 )
   SELECT ( _k_area )

   DO WHILE !Eof() .AND. ( br_dok == nBrDok )
	
      ++ _cnt
      @ m_x + 1, m_y + 2 SAY PadR( "P_" + cTbl +  " -> " + cTbl + " :" + Transform( _cnt, "9999" ), 40 )
	
      SELECT ( _k_area )
      _rec := dbf_get_rec()
	
      SELECT ( _p_area )
      APPEND BLANK
      dbf_update_rec( _rec )
	
      SELECT ( _k_area )
      SKIP
   ENDDO

   IF ( cTbl == "KUF" )
      epdv_otvori_kuf_tabele( .T. )
   ELSE
      epdv_otvori_kif_tabele( .T. )
   endif

   SELECT ( _k_area )
   SET ORDER TO TAG "BR_DOK"
   SEEK Str( nBrdok, 6, 0 )

   _del_rec := dbf_get_rec()

   _ok := .T.

   MsgO( "del " + cTbl )

   _ok := delete_rec_server_and_dbf( _table, _del_rec, 2, "FULL" )

   MsgC()

   IF !_ok
      MsgBeep( "Operacija brisanja dokumenta nije uspješna, dokument: " + AllTrim( Str( nBrDok ) ) )
   ENDIF

   SELECT ( _k_area )
   USE

   IF ( cTbl == "KUF" )
      epdv_otvori_kuf_tabele( .T. )
   ELSE
      epdv_otvori_kif_tabele( .T. )
   endif

   BoxC()

   IF _ok
      MsgBeep( "Izvršen je povrat dokumenta " + Str( nBrDok, 6, 0 ) + " u pripremu" )
   ENDIF

   RETURN nBrDok


FUNCTION epdv_renumeracija_rbr( cTbl, lShow )

   LOCAL _rec

   IF lShow == nil
      lShow := .T.
   ENDIF

   IF cTbl == "P_KUF"
      SELECT F_P_KUF
      IF !Used()
         O_P_KUF
      ENDIF
	
   ELSEIF cTbl == "P_KIF"
      SELECT F_P_KIF
	
      SELECT F_P_KIF
      IF !Used()
         O_P_KIF
      ENDIF
   ENDIF

   SET ORDER TO TAG "datum"
   GO TOP
   nRbr := 1

   DO WHILE !Eof()
      _rec := dbf_get_rec()
      _rec[ "r_br" ] := nRbr
      dbf_update_rec( _rec )
      ++nRbr
      SKIP
   ENDDO

   IF lShow
      MsgBeep( "Renumeracija pripreme završena" )
   ENDIF

   RETURN


FUNCTION renm_g_rbr( cTbl, lShow )

   LOCAL nRbr, _rec
   LOCAL nLRbr

   IF lShow == nil
      lShow := .T.
   ENDIF

   IF cTbl == "KUF"
      SELECT F_KUF
      IF !Used()
         O_KUF
      ENDIF
	
   ELSEIF cTbl == "P_KIF"
      SELECT F_KIF
	
      SELECT F_KIF
      IF !Used()
         O_KIF
      ENDIF
   ENDIF

   SET ORDER TO TAG "l_datum"

   SET SOFTSEEK ON
   SEEK "DZ"
   SKIP -1
   IF lock == "D"
      nLRbr := g_r_br
   ELSE
      nLRbr := 0
   ENDIF

   PRIVATE cFilter := "!(lock == 'D')"

   SET FILTER TO &cFilter
   GO TOP

   Box(, 3, 60 )
   nRbr := nLRbr
   DO WHILE !Eof()

      ++nRbr
      @ m_x + 1, m_y + 2 SAY cTbl + ":" + Str( nRbr, 8, 0 )
      _rec := dbf_get_rec()
      _rec[ "g_r_br" ] := nRbr
      dbf_update_rec( _rec )
	
      ++nRbr
      SKIP
   ENDDO
   BoxC()

   USE

   IF lShow
      MsgBeep( cTbl + " : G.Rbr renumeracija izvršena" )
   ENDIF

   RETURN
