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


#include "f18.ch"


// ----------------------------------------------------
// otvori tabele prije azuriranja
// ----------------------------------------------------
STATIC FUNCTION _o_tbls()

   o_partner()
   O_MAT_PRIPR
   O_MAT_SUBAN
   O_MAT_PSUBAN
   O_MAT_ANAL
   O_MAT_PANAL
   O_MAT_SINT
   O_MAT_PSINT
   O_MAT_NALOG
   O_MAT_PNALOG
   o_roba()

   RETURN



// -------------------------------------------------------------
// razno-razne provjere dokumenta prije samog azuriranja
// -------------------------------------------------------------
STATIC FUNCTION _provjera_dokumenta()

   LOCAL _valid := .T.

   IF !_stampan_nalog()
      _valid := .F.
      RETURN _valid
   ENDIF

   IF !_ispravne_sifre()
      _valid := .F.
      RETURN _valid
   ENDIF

   RETURN _valid


// ---------------------------------------------------
// provjera sifara koristenih u dokumentu
// ---------------------------------------------------
STATIC FUNCTION _ispravne_sifre()

   LOCAL _valid := .T.

   // kontrola ispravnosti sifara artikala
   SELECT mat_psuban
   GO TOP

   DO WHILE !Eof()

      // provjeri prvo robu
      SELECT roba
      HSEEK mat_psuban->idroba

      IF !Found()
         Beep( 1 )
         Msg( "Stavka br." + mat_psuban->rbr + ": Nepostojeca sifra artikla!" )
         _valid := .F.
         EXIT
      ENDIF

      select_o_partner( mat_psuban->idpartner )

      IF !Found() .AND. !Empty( mat_psuban->idpartner )
         Beep( 1 )
         Msg( "Stavka br." + mat_psuban->rbr + ": Nepostojeca sifra partnera!" )
         _valid := .F.
         EXIT
      ENDIF

      SELECT mat_psuban
      SKIP 1

   ENDDO

   // pobrisi tabele ako postoji problem
   IF !_valid

      SELECT mat_psuban
      my_dbf_zap()
      SELECT mat_panal
      my_dbf_zap()
      SELECT mat_psint
      my_dbf_zap()

   ENDIF

   RETURN _valid


// -----------------------------------------------------
// da li je nalog stampan prije azuriranja
// -----------------------------------------------------
STATIC FUNCTION _stampan_nalog()

   LOCAL _valid := .T.

   SELECT mat_psuban
   IF reccount2() == 0
      _valid := .F.
   ENDIF

   SELECT mat_panal
   IF reccount2() == 0
      _valid := .F.
   ENDIF

   SELECT mat_psint
   IF reccount2() == 0
      _valid := .F.
   ENDIF

   IF !_valid
      Beep( 3 )
      Msg( "Niste izvrsili stampanje naloga ...", 10 )
   ENDIF

   RETURN _valid



// ----------------------------------------------------
// centralna funkcija za azuriranje mat naloga
// ----------------------------------------------------
FUNCTION azur_mat()

   IF Pitanje(, "Sigurno želite izvršiti ažuriranje (D/N)?", "N" ) == "N"
      RETURN
   ENDIF

   // otvori potrebne tabele
   _o_tbls()

   // napravi bazne provjere dokumenta prije azuriranja
   IF !_provjera_dokumenta()
      my_close_all_dbf()
      RETURN
   ENDIF

   // azuriraj u sql
   IF _mat_azur_sql()
      // azuriraj u dbf
      IF !_mat_azur_dbf()
         MsgBeep( "Problem sa azuriranjem mat/dbf !" )
      ENDIF
   ELSE
      MsgBeep( "Problem sa azuriranjem mat/sql !" )
   ENDIF

   my_close_all_dbf()

   RETURN


// --------------------------------------------------
// azuriranje mat naloga u sql bazu
// --------------------------------------------------
STATIC FUNCTION _mat_azur_sql()

   LOCAL _ok := .T.
   LOCAL _ids := {}
   LOCAL _record
   LOCAL _tmp_id, _log_info
   LOCAL _tbl_suban
   LOCAL _tbl_anal
   LOCAL _tbl_sint
   LOCAL _tbl_nalog
   LOCAL nI
   LOCAL _ids_suban := {}
   LOCAL _ids_sint := {}
   LOCAL _ids_anal := {}
   LOCAL _ids_nalog := {}
   LOCAL hParams

   _tbl_suban := "mat_suban"
   _tbl_anal  := "mat_anal"
   _tbl_nalog := "mat_nalog"
   _tbl_sint  := "mat_sint"

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { _tbl_suban, _tbl_anal, _tbl_sint, _tbl_nalog } )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "ERROR lock tabele" )
      RETURN .F.
   ENDIF

   MsgO( "sql mat_suban" )

   _record := hb_Hash()

   SELECT mat_psuban
   GO TOP


   _record := dbf_get_rec()
   _tmp_id := _record[ "idfirma" ] + _record[ "idvn" ] + _record[ "brnal" ]
   _log_info := _record[ "idfirma" ] + "-" + _record[ "idvn" ] + "-" + _record[ "brnal" ]
   AAdd( _ids_suban, "#2" + _tmp_id )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "mat_suban -> server: " + _tmp_id
   DO WHILE !Eof()

      _record := dbf_get_rec()
      IF !sql_table_update( "mat_suban", "ins", _record )
         _Ok := .F.
         EXIT
      ENDIF

      SKIP
   ENDDO


   MsgC()


   // idi dalje, na anal ... ako je ok
   IF _ok == .T.


      SELECT mat_panal
      GO TOP

      MsgO( "sql mat_anal" )
      _record := dbf_get_rec()
      _tmp_id := _record[ "idfirma" ] + _record[ "idvn" ] + _record[ "brnal" ]
      AAdd( _ids_anal, "#2" + _tmp_id )

      DO WHILE !Eof()
         _record := dbf_get_rec()
         IF !sql_table_update( "mat_anal", "ins", _record )
            lOk := .F.
            EXIT
         ENDIF
         SKIP
      ENDDO

      MsgC()

   ENDIF


   // idi dalje, na sint ... ako je ok
   IF _ok == .T.

      MsgO( "sql mat_sint" )

      SELECT mat_psint
      GO TOP

      _record := dbf_get_rec()
      _tmp_id := _record[ "idfirma" ] + _record[ "idvn" ] + _record[ "brnal" ]
      AAdd( _ids_sint, "#2" + _tmp_id )

      DO WHILE !Eof()

         _record := dbf_get_rec()
         IF !sql_table_update( "mat_sint", "ins", _record )
            lOk := .F.
            EXIT
         ENDIF
         SKIP
      ENDDO

      MsgC()

   ENDIF


   // idi dalje, na nalog ... ako je ok
   IF _ok == .T.

      MsgO( "sql mat_nalog" )

      _record := hb_Hash()

      SELECT mat_pnalog


      GO TOP

      _record := dbf_get_rec()
      _tmp_id := _record[ "idfirma" ] + _record[ "idvn" ] + _record[ "brnal" ]
      AAdd( _ids_nalog, _tmp_id )

      DO WHILE !Eof()

         _record := dbf_get_rec()
         IF !sql_table_update( "mat_nalog", "ins", _record )
            lOk := .F.
            EXIT
         ENDIF
         SKIP
      ENDDO


   ENDIF

   IF ! _ok
      // vrati sve promjene...
      run_sql_query( "ROLLBACK" )
   ELSE
      // dodaj ids
      AAdd( _ids, _tmp_id )

      push_ids_to_semaphore( _tbl_suban, _ids_suban )
      push_ids_to_semaphore( _tbl_anal,  _ids_anal  )
      push_ids_to_semaphore( _tbl_sint,  _ids_sint  )
      push_ids_to_semaphore( _tbl_nalog, _ids_nalog )


      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { _tbl_suban, _tbl_anal, _tbl_sint, _tbl_nalog }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER: mat, azuriranje dokumenta: " + _log_info, 2 )

   ENDIF

   RETURN _ok




// --------------------------------------------------
// azuriranje mat naloga u dbf
// --------------------------------------------------
STATIC FUNCTION _mat_azur_dbf()

   LOCAL _ret := .T.
   LOCAL _vars

   Box(, 7, 30, .F. )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "ANALITIKA"
   SELECT mat_panal
   GO TOP

   DO WHILE !Eof()

      _vars := dbf_get_rec()
      SELECT mat_anal
      APPEND BLANK

      dbf_update_rec( _vars )

      SELECT mat_panal
      SKIP

   ENDDO

   SELECT mat_panal
   my_dbf_zap()

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "SINTETIKA"
   SELECT mat_psint
   GO TOP

   DO WHILE !Eof()

      _vars := dbf_get_rec()

      SELECT mat_sint
      APPEND BLANK

      dbf_update_rec( _vars )

      SELECT mat_psint
      SKIP

   ENDDO

   SELECT mat_psint
   my_dbf_zap()

   @ box_x_koord() + 5, box_y_koord() + 2 SAY "NALOZI"
   SELECT mat_pnalog
   GO TOP

   DO WHILE !Eof()

      _vars := dbf_get_rec()

      SELECT mat_nalog
      APPEND BLANK

      dbf_update_rec( _vars )

      SELECT mat_pnalog
      SKIP

   ENDDO

   SELECT mat_pnalog
   my_dbf_zap()

   @ box_x_koord() + 7, box_y_koord() + 2 SAY "SUBANALITIKA"
   SELECT mat_psuban
   GO TOP

   DO WHILE !Eof()

      _vars := dbf_get_rec()

      SELECT mat_suban
      APPEND BLANK

      dbf_update_rec( _vars )

      SELECT mat_psuban
      SKIP

   ENDDO

   SELECT mat_psuban
   my_dbf_zap()

   SELECT mat_pripr
   my_dbf_zap()

   Inkey( 2 )

   BoxC()

   RETURN _ret
