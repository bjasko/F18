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


#include "rnal.ch"


STATIC __doc_no
STATIC __doc_stat
STATIC __doc_desc


// -------------------------------------------
// azuriranje dokumenta u kumulativnu bazu
// cDesc - opis kod azuriranja
// -------------------------------------------
FUNCTION doc_insert( cDesc )

   LOCAL _ok := .T.

   IF cDesc == nil
      cDesc := ""
   ENDIF

   rnal_o_tables( .T. )

   // skloni filtere
   SELECT _docs
   SET FILTER TO

   SELECT _doc_it
   SET FILTER TO

   SELECT _doc_it2
   SET FILTER TO

   SELECT _doc_ops
   SET FILTER TO

   // provjeri sve prije azuriranja
   IF !_provjeri_prije_azuriranja()
      MsgBeep( "Redni brojevi u nalogu nisu ispravni, provjeriti !" )
      RETURN 0
   ENDIF

   SELECT _docs
   GO TOP

   IF RECCOUNT2() == 0
      RETURN 0
   ENDIF

   __doc_desc := cDesc
   __doc_no := _docs->doc_no
   __doc_stat := _docs->doc_status

   IF __doc_stat < 3 .AND. !rnal_doc_no_exist( __doc_no )

      MsgBeep( "Nalog " + AllTrim( Str( __doc_no ) ) + " nije moguce azurirati !!!#Status dokumenta = " + AllTrim( Str( __doc_stat ) ) )

      // resetuj dokument broj
      SELECT _docs

      fill__doc_no( 0, .T. )

      SELECT _docs
      GO TOP

      msgbeep( "Ponovite operaciju stampe i azuriranja naloga !" )

      RETURN 0

   ENDIF


   // azuriranje naloga u toku...
   // lokuj sve tabele

   // probaj prvo docs lokovati....
   IF !f18_lock_tables( { "docs" } )
      MsgBeep( "Tabele zauzete... ponovite ponovo.... lock docs !!!" )
      RETURN 0
   ENDIF

   // ----- pocetak transakcije
   // lock ostalih tabela....
   IF !f18_lock_tables( { "doc_it", "doc_it2", "doc_ops", "doc_log", "doc_lit" } )
      MsgBeep( "Ne mogu lock-ovati tabele !!!!" )
      RETURN 0
   ENDIF

   sql_table_update( nil, "BEGIN" )

   MsgO( "Azuriranje naloga u toku..." )

   Beep( 1 )

   // doc busy....
   IF __doc_stat == 3

      // napravi deltu dokumenta
      doc_delta( __doc_no, __doc_desc )

      // brisi dokument iz kumulativa
      doc_erase( __doc_no )

      // zavrsi trenutnu transakciju
      sql_table_update( nil, "END" )
      // zapocni novu transakciju
      // kako bi ovo sto je i izbrisano bilo vidljivo
      sql_table_update( nil, "BEGIN" )

      O_DOCS

   ENDIF

   // azuriranje tabele _DOCS
   _ok := _docs_insert( __doc_no  )

   // azuriranje tabele _DOC_IT
   IF _ok
      _ok := _doc_it_insert( __doc_no )
   ENDIF

   // azuriranje tabele _DOC_IT2
   IF _ok
      _ok := _doc_it2_insert( __doc_no )
   ENDIF

   // azuriranje tabele _DOC_OPS
   IF _ok
      _ok := _doc_op_insert( __doc_no )
   ENDIF

   IF _ok
      // setuj marker dokumenta
      set_doc_marker( __doc_no, 0, "CONT" )
      IF __doc_stat <> 3
         // logiraj promjene na dokumentu
         doc_logit( __doc_no )
      ENDIF

      f18_free_tables( { "docs", "doc_it", "doc_it2", "doc_ops", "doc_log", "doc_lit" } )
      sql_table_update( nil, "END" )

      // logiranje
      log_write( "F18_DOK_OPER: rnal, azuriranje dokumenta broj: " + AllTrim( Str( __doc_no ) ) + ;
         ", status: " + AllTrim( Str( __doc_stat ) ), 2 )

   ELSE

      f18_free_tables( { "docs", "doc_it", "doc_it2", "doc_ops", "doc_log", "doc_lit" } )
      sql_table_update( nil, "ROLLBACK" )

      MsgC()

      // nesto se nije azuriralo ok !
      // ostavljam dokument u pripremi...

      // ako je sta ostalo na serveru ili u dbf-u brisi !
      doc_erase( __doc_no )

      beep( 3 )

      rnal_o_tables( .T. )

      MsgBeep( "Azuriranje naloga nije uspjesno !" )

      RETURN 0

   ENDIF

   // ------ kraj transakcije

   // sve je ok brisi pripremu
   SELECT _docs
   my_dbf_zap()

   SELECT _doc_it
   my_dbf_zap()

   SELECT _doc_it2
   my_dbf_zap()

   SELECT _doc_ops
   my_dbf_zap()

   USE

   Beep( 1 )

   rnal_o_tables( .T. )

   MsgC()

   RETURN 1


// --------------------------------------------------
// provjera prije azuriranja dokumenta...
// --------------------------------------------------
STATIC FUNCTION _provjeri_prije_azuriranja()

   LOCAL _ok := .T.
   LOCAL _t_area := Select()
   LOCAL _tmp

   // stavke naloga ....
   SELECT _doc_it
   GO TOP

   DO WHILE !Eof()

      _tmp := field->doc_it_no

      SKIP 1

      IF _tmp == field->doc_it_no
         GO TOP
         SELECT ( _t_area )
         _ok := .F.
         RETURN _ok
      ENDIF

   ENDDO

   GO TOP

   // dodatne stavke naloga....

   // operacije naloga ....

   SELECT ( _t_area )

   RETURN _ok



// --------------------------------------------------
// azuriranje DOCS
// --------------------------------------------------
STATIC FUNCTION _docs_insert( nDoc_no )

   LOCAL _rec
   LOCAL _ok := .T.

   SELECT _docs
   SET ORDER TO TAG "1"
   GO TOP

   _rec := dbf_get_rec()

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF !Found()
      APPEND BLANK
   ENDIF

   _ok := update_rec_server_and_dbf( "docs", _rec, 1, "CONT" )

   SET ORDER TO TAG "1"

   RETURN _ok


// ------------------------------------------
// azuriranje tabele _DOC_IT
// ------------------------------------------
STATIC FUNCTION _doc_it_insert( nDoc_no )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL _ok := .T.

   SELECT _doc_it

   IF RECCOUNT2() == 0
      RETURN _ok
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

      _rec := dbf_get_rec()

      SELECT doc_it

      APPEND BLANK

      _ok := update_rec_server_and_dbf( "doc_it", _rec, 1, "CONT" )

      SELECT _doc_it

      IF !_ok
         RETURN _ok
      ENDIF

      SKIP

   ENDDO

   RETURN _ok

// ------------------------------------------
// azuriranje tabele _DOC_IT2
// ------------------------------------------
STATIC FUNCTION _doc_it2_insert( nDoc_no )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL _ok := .T.

   SELECT _doc_it2

   IF RECCOUNT2() == 0
      RETURN _ok
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

      _rec := dbf_get_rec()

      SELECT doc_it2

      APPEND BLANK

      _ok := update_rec_server_and_dbf( "doc_it2", _rec, 1, "CONT" )

      SELECT _doc_it2

      IF !_ok
         RETURN _ok
      ENDIF

      SKIP

   ENDDO

   RETURN _ok





// ------------------------------------------
// azuriranje tabele _DOC_OP
// ------------------------------------------
STATIC FUNCTION _doc_op_insert( nDoc_no )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL _ok := .T.

   SELECT _doc_ops

   IF RECCOUNT2() == 0
      RETURN _ok
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

      // ako ima operacija...
      IF field->aop_id + field->aop_att_id <> 0

         _rec := dbf_get_rec()

         SELECT doc_ops
         APPEND BLANK

         _ok := update_rec_server_and_dbf( "doc_ops", _rec, 1, "CONT" )

      ENDIF

      SELECT _doc_ops

      IF !_ok
         RETURN _ok
      ENDIF

      SKIP

   ENDDO

   RETURN _ok



// -------------------------------------------
// procedura povrata dokumenta u pripremu...
// -------------------------------------------
FUNCTION doc_2__doc( nDoc_no )

   rnal_o_tables( .T. )

   SELECT docs
   SET FILTER TO
   SELECT doc_it
   SET FILTER TO
   SELECT doc_it2
   SET FILTER TO
   SELECT doc_ops
   SET FILTER TO

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF !Found()
      MsgBeep( "Nalog " + AllTrim( Str( nDoc_no ) ) + " ne postoji !!!" )
      SELECT _docs
      RETURN 0
   ENDIF

   SELECT _docs

   IF RECCOUNT2() > 0
      MsgBeep( "U pripremi vec postoji dokument#ne moze se izvrsiti povrat#operacija prekinuta !" )
      RETURN 0
   ENDIF

   MsgO( "Vrsim povrat dokumenta u pripremu...." )

   // markiraj da je dokument busy
   set_doc_marker( nDoc_no, 3 )

   // povrat maticne tabele RNAL
   _docs_erase( nDoc_no )

   // povrat stavki RNST
   _doc_it_erase( nDoc_no )

   // povrat stavki RNST
   _doc_it2_erase( nDoc_no )

   // povrat operacija RNOP
   _doc_op_erase( nDoc_no )


   SELECT docs
   USE

   rnal_o_tables( .T. )

   MsgC()

   RETURN 1


// ----------------------------------------
// markiranje statusa dokumenta busy
// nDoc_no - dokument broj
// nMarker - 0, 1, 2, 3, 4, 5
// ----------------------------------------
FUNCTION set_doc_marker( nDoc_no, nMarker, cont )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL nTArea

   nTArea := Select()

   IF cont == NIL
      cont := "FULL"
   ENDIF

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()

      _rec := dbf_get_rec()
      _rec[ "doc_status" ] := nMarker

      update_rec_server_and_dbf( "docs", _rec, 1, cont )

   ENDIF

   SELECT ( nTArea )

   RETURN



// ------------------------------------
// provjerava da li je dokument zauzet
// ------------------------------------
FUNCTION is_doc_busy()

   LOCAL lRet := .F.

   IF field->doc_status == 3
      lRet := .T.
   ENDIF

   RETURN lRet


// -------------------------------------
// provjerava da li je dokument rejected
// -------------------------------------
FUNCTION is_doc_rejected()

   LOCAL lRet := .F.

   IF field->doc_status == 2
      lRet := .T.
   ENDIF

   RETURN lRet



// ----------------------------------------------
// povrat dokumenta iz tabele DOCS
// ----------------------------------------------
STATIC FUNCTION _docs_erase( nDoc_no )

   LOCAL _rec

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()

      SELECT docs

      _rec := dbf_get_rec()

      SELECT _docs

      APPEND BLANK

      dbf_update_rec( _rec )

   ENDIF

   SELECT docs

   RETURN


// ----------------------------------------------
// povrat tabele DOC_IT
// ----------------------------------------------
STATIC FUNCTION _doc_it_erase( nDoc_no )

   LOCAL _rec

   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no )

   IF Found()

      // dodaj u pripremu dokument
      DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

         SELECT doc_it

         _rec := dbf_get_rec()

         SELECT _doc_it

         APPEND BLANK

         dbf_update_rec( _rec )

         SELECT doc_it

         SKIP
      ENDDO
   ENDIF

   SELECT doc_it

   RETURN


// ----------------------------------------------
// povrat tabele DOC_IT2
// ----------------------------------------------
STATIC FUNCTION _doc_it2_erase( nDoc_no )

   LOCAL _rec

   SELECT doc_it2
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no )

   IF Found()

      // dodaj u pripremu dokument
      DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

         SELECT doc_it2

         _rec := dbf_get_rec()

         SELECT _doc_it2

         APPEND BLANK

         dbf_update_rec( _rec )

         SELECT doc_it2

         SKIP
      ENDDO
   ENDIF

   SELECT doc_it2

   RETURN


// ----------------------------------------------
// povrat tabele DOC_OP
// ----------------------------------------------
STATIC FUNCTION _doc_op_erase( nDoc_no )

   LOCAL _rec

   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no )

   IF Found()

      // dodaj u pripremu dokument
      DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

         SELECT doc_ops
         _rec := dbf_get_rec()

         SELECT _doc_ops
         APPEND BLANK
         dbf_update_rec( _rec )

         SELECT doc_ops

         SKIP
      ENDDO

   ENDIF

   SELECT doc_ops

   RETURN



// -----------------------------------------------
// brisi sve vezano za dokument iz kumulativa
// -----------------------------------------------
STATIC FUNCTION doc_erase( nDoc_no )

   LOCAL _del_rec

   // DOCS
   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "docs", _del_rec, 1, "CONT" )
   ENDIF

   // DOC_IT
   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "doc_it", _del_rec, 2, "CONT" )
   ENDIF

   // DOC_IT2
   SELECT doc_it2
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "doc_it2", _del_rec, 2, "CONT" )
   ENDIF

   // DOC_OP
   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "doc_ops", _del_rec, 2, "CONT" )
   ENDIF

   RETURN 1



// --------------------------------------------
// da li postoji dokument u tabeli
// --------------------------------------------
FUNCTION doc_exist( nDoc_no )

   LOCAL nArea
   LOCAL lRet := .F.

   nArea := Select()

   SELECT DOCS
   SET ORDER TO TAG "A"
   GO TOP
   SEEK d_busy() + docno_str( nDoc_no )

   IF Found() .AND. docs->doc_no == nDoc_no
      lRet := .T.
   ENDIF

   SET ORDER TO TAG "1"
   SELECT ( nArea )

   RETURN lRet




// ----------------------------------------------
// napuni pripremne tabele sa brojem naloga
// ----------------------------------------------
FUNCTION fill__doc_no( nDoc_no, lForce )

   LOCAL nTRec
   LOCAL nTArea
   LOCAL nAPPRec
   LOCAL _rec

   IF lForce == nil
      lForce := .F.
   ENDIF

   // ako je broj 0 ne poduzimaj nista....
   IF ( nDoc_no == 0 .AND. lForce == .F. )
      RETURN
   ENDIF

   nTArea := Select()
   nTRec := RecNo()

   // _DOCS
   SELECT _docs
   SET ORDER TO TAG "1"
   GO TOP

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   IF Empty( _rec[ "doc_time" ] )
      _rec[ "doc_time" ] := PadR( Time(), 5 )
   ENDIF

   dbf_update_rec( _rec )

   // _DOC_IT
   SELECT _doc_it
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()

      SKIP
      nAPPRec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := nDoc_no
      dbf_update_rec( _rec )

      GO ( nAPPRec )
   ENDDO

   // _DOC_IT2
   SELECT _doc_it2
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()

      SKIP
      nAPPRec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := nDoc_no
      dbf_update_rec( _rec )

      GO ( nAPPRec )
   ENDDO

   // _DOC_OPS
   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()

      SKIP
      nAPPRec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := nDoc_no
      dbf_update_rec( _rec )

      GO ( nAPPRec )
   ENDDO

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN


// -----------------------------------------
// formira string za _doc_status - opened
// -----------------------------------------
STATIC FUNCTION d_opened()
   RETURN Str( 0, 2 )

// -----------------------------------------
// formira string za _doc_status - closed
// -----------------------------------------
STATIC FUNCTION d_closed()
   RETURN Str( 1, 2 )

// -----------------------------------------
// formira string za _doc_status - rejected
// -----------------------------------------
STATIC FUNCTION d_rejected()
   RETURN Str( 2, 2 )

// -----------------------------------------
// formira string za _doc_status - busy
// -----------------------------------------
STATIC FUNCTION d_busy()
   RETURN Str( 3, 2 )
