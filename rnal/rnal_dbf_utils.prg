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


#include "rnal.ch"

// -------------------------------------------
// -------------------------------------------
FUNCTION m_adm()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. pregled artikala bez definisanih elemenata  " )
   AAdd( _opcexe, {|| rpt_artikli_bez_elemenata() } )

   IF is_fmkrules()
      AAdd( _opc, "2. FMK rules" )
      AAdd( _opcexe, {|| p_fmkrules( , , , aRuleSpec, bRuleBlock ) } )
   ENDIF
	
   f18_menu( "adm", .F., _izbor, _opc, _opcexe )

   RETURN



// ------------------------------------------------
// otvori tabele potrebne za rad sa RNAL
// lTemporary - .t. i pripremne tabele
// ------------------------------------------------
FUNCTION rnal_o_tables( lTemporary )

   IF lTemporary == nil
      lTemporary := .F.
   ENDIF

   rnal_o_sif_tables()

   O_FMKRULES

   O_DOCS
   O_DOC_IT
   O_DOC_IT2
   O_DOC_OPS
   O_DOC_LOG
   O_DOC_LIT

   IF lTemporary == .T.

      O__DOCS
      O__DOC_IT
      O__DOC_IT2
      O__DOC_OPS
      O__FND_PAR
	
   ENDIF

   RETURN

// -----------------------------------------
// otvara tabele sifrarnika
// -----------------------------------------
FUNCTION rnal_o_sif_tables()

   O_E_GROUPS
   O_E_GR_ATT
   O_E_GR_VAL
   O_ARTICLES
   O_ELEMENTS
   O_E_AOPS
   O_E_ATT
   O_CUSTOMS
   O_CONTACTS
   O_OBJECTS
   O_AOPS
   O_AOPS_ATT
   O_RAL
   O_SIFK
   O_SIFV
   O_ROBA

   RETURN



// -----------------------------
// otvori tabelu _TMP1
// -----------------------------
FUNCTION o_tmp1()

   SELECT ( F__TMP1 )
   USE
   my_use_temp( "_TMP1", my_home() + "_tmp1", .F., .T. )

   RETURN



// -----------------------------
// otvori tabelu _TMP2
// -----------------------------
FUNCTION o_tmp2()

   SELECT ( F__TMP2 )
   USE
   my_use_temp( "_TMP2", my_home() + "_tmp2", .F., .T. )

   RETURN


// -----------------------------------------
// konvert doc_no -> STR(doc_no, 10)
// -----------------------------------------
FUNCTION doc_str( nId )
   RETURN Str( nId, 10 )


// -----------------------------------------
// konvert doc_no -> STR(doc_no, 10)
// -----------------------------------------
FUNCTION docno_str( nId )
   RETURN Str( nId, 10 )


// -----------------------------------------
// konvert doc_op -> STR(doc_op, 4)
// -----------------------------------------
FUNCTION docop_str( nId )
   RETURN Str( nId, 4 )


// -----------------------------------------
// konvert doc_it -> STR(doc_it, 4)
// -----------------------------------------
FUNCTION docit_str( nId )
   RETURN Str( nId, 4 )



// -------------------------------------------
// setuje novi zapis u tabeli sifrarnika
// nId - id sifrarnika
// cIdField - naziv id polja....
// -------------------------------------------
FUNCTION _set_sif_id( nId, cIdField, lAuto, cont )

   LOCAL nTArea := Select()
   LOCAL nTime
   LOCAL cIndex
   LOCAL _rec
   PRIVATE GetList := {}

   IF lAuto == NIL
      lAuto := .F.
   ENDIF

   IF cIdField == "ART_ID"
      cIndex := "1"
   ELSE
      cIndex := "2"
   ENDIF

   IF cont == NIL
      cont := "CONT"
   ENDIF

   rnal_inc_id( @nId, cIdField, cIndex, lAuto )

   set_global_memvars_from_dbf()

   APPEND BLANK

   cIdField := "_" + cIdField

   &cIdField := nId

   _rec := get_dbf_global_memvars( NIL, .F. )

   update_rec_server_and_dbf( Alias(), _rec, 1, cont )

   SELECT ( nTArea )

   RETURN 1




// ------------------------------------------
// kreiranje tabele PRIVPATH + _TMP1
// ------------------------------------------
FUNCTION cre_tmp1( aFields )

   LOCAL cTbName := "_tmp1"

   IF Len( aFields ) == 0
      MsgBeep( "Nema definicije polja u matrici!" )
      RETURN
   ENDIF

   _del_tmp( my_home() + cTbName + ".dbf" )
   _del_tmp( my_home() + cTbName + ".cdx" )

   dbCreate( my_home() + cTbName + ".dbf", aFields )

   RETURN

// ------------------------------------------
// kreiranje tabele PRIVPATH + _TMP1
// ------------------------------------------
FUNCTION cre_tmp2( aFields )

   LOCAL cTbName := "_tmp2"

   IF Len( aFields ) == 0
      MsgBeep( "Nema definicije polja u matrici!" )
      RETURN
   ENDIF

   _del_tmp( my_home() + cTbName + ".dbf" )
   _del_tmp( my_home() + cTbName + ".cdx" )

   dbCreate( my_home() + cTbName + ".dbf", aFields )

   RETURN



// --------------------------------------------
// brisanje fajla
// --------------------------------------------
STATIC FUNCTION _del_tmp( cPath )

   IF File( cPath )
      FErase( cPath )
   ENDIF

   RETURN


// ----------------------------------------------
// promjena broja naloga
// servisna opcija, zasticena password-om
// ----------------------------------------------
FUNCTION ch_doc_no( old_doc )

   LOCAL _new_no := old_doc
   LOCAL _repl := .T.

   IF !SigmaSif( "PRBRNO" )
      RETURN .F.
   ENDIF

   Box(, 1, 50 )
   @ m_x + 1, m_y + 2 SAY "setuj novi broj:" GET _new_no
   READ
   BoxC()

   IF LastKey() == K_ESC
      msgbeep( "Prekinuta operacija !" )
      RETURN .F.
   ENDIF

   // prodji kroz tabele i promjeni broj
   // tabele su:
   //
   // - docs
   // - doc_it
   // - doc_it2
   // - doc_ops

   // odmah zamjeni u tabeli docs, jer se na njoj nalazis

   f18_lock_tables( { "docs", "doc_it", "doc_it2", "doc_ops" } )
   sql_table_update( nil, "BEGIN" )

   IF field->doc_no == old_doc
      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := _new_no
      update_rec_server_and_dbf( "docs", _rec, 1, "CONT" )
   ELSE
      _repl := .T.
   ENDIF

   IF _repl == .F.
      msgbeep( "Nisam nista zamjenio !!!" )
      RETURN .F.
   ENDIF

   // doc_it
   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( old_doc )

   IF Found()
      SET ORDER TO 0
      DO WHILE !Eof() .AND. field->doc_no == old_doc
         _rec := dbf_get_rec()
         _rec[ "doc_no" ] := _new_no
         update_rec_server_and_dbf( "docs", _rec, 1, "CONT" )
         SKIP
      ENDDO
   ENDIF

   // doc_it2
   SELECT doc_it2
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( old_doc )

   IF Found()
      SET ORDER TO 0
      DO WHILE !Eof() .AND. field->doc_no == old_doc
         _rec := dbf_get_rec()
         _rec[ "doc_no" ] := _new_no
         update_rec_server_and_dbf( "docs", _rec, 1, "CONT" )
         SKIP
      ENDDO
   ENDIF

   // doc_ops
   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( old_doc )

   IF Found()
      SET ORDER TO 0
      DO WHILE !Eof() .AND. field->doc_no == old_doc
         _rec := dbf_get_rec()
         _rec[ "doc_no" ] := _new_no
         update_rec_server_and_dbf( "docs", _rec, 1, "CONT" )
         SKIP
      ENDDO
   ENDIF

   f18_free_tables( { "docs", "doc_it", "doc_it2", "doc_ops" } )
   sql_table_update( nil, "END" )

   RETURN .T.


// ------------------------------------------------------------
// resetuje brojač dokumenta ako smo pobrisali dokument
// ------------------------------------------------------------
FUNCTION rnal_reset_doc_no( doc_no )

   LOCAL _param
   LOCAL _broj := 0

   // param: rnal_doc_no
   _param := "rnal_doc_no"
   _broj := fetch_metric( _param, nil, _broj )

   IF doc_no == _broj
      -- _broj
      // smanji globalni brojac za 1
      set_metric( _param, nil, _broj )
   ENDIF

   RETURN



// ------------------------------------------------------------------
// rnal, uzimanje novog broja za rnal dokument
// ------------------------------------------------------------------
FUNCTION rnal_novi_broj_dokumenta()

   LOCAL _broj := 0
   LOCAL _broj_doks := 0
   LOCAL _param
   LOCAL _tmp, _rest
   LOCAL _ret := ""
   LOCAL _t_area := Select()

   // param: rnal_doc_no
   _param := "rnal_doc_no"

   _broj := fetch_metric( _param, nil, _broj )

   // konsultuj i doks uporedo
   O_DOCS
   SET ORDER TO TAG "1"
   GO TOP
   SEEK "X"
   SKIP -1

   _broj_doks := field->doc_no

   // uzmi sta je vece, doks broj ili globalni brojac
   _broj := Max( _broj, _broj_doks )

   // uvecaj broj
   ++ _broj

   // upisi ga u globalni parametar
   set_metric( _param, nil, _broj )

   SELECT ( _t_area )

   RETURN _broj



// ------------------------------------------------------------
// provjerava da li dokument postoji na strani servera
// ------------------------------------------------------------
FUNCTION rnal_doc_no_exist( doc_no )

   LOCAL _exist := .F.
   LOCAL _qry, _qry_ret, _table
   LOCAL _server := pg_server()

   _qry := "SELECT COUNT(*) FROM fmk.rnal_docs WHERE doc_no = " + _sql_quote( doc_no )
   _table := _sql_query( _server, _qry )
   _qry_ret := _table:FieldGet( 1 )

   IF _qry_ret > 0
      _exist := .T.
   ENDIF

   RETURN _exist



// ------------------------------------------------------------
// setuj broj dokumenta u pripremi ako treba !
// ------------------------------------------------------------
FUNCTION rnal_set_broj_dokumenta( doc_no )

   LOCAL _null_brdok

   SELECT _docs
   GO TOP

   _null_brdok := 0

   IF field->doc_no <> _null_brdok
      // nemam sta raditi, broj je vec setovan
      RETURN .F.
   ENDIF

   // daj mi novi broj dokumenta
   doc_no := rnal_novi_broj_dokumenta()

   RETURN .T.



// ------------------------------------------------------------
// setovanje parametra brojaca na admin meniju
// ------------------------------------------------------------
FUNCTION rnal_set_param_broj_dokumenta()

   LOCAL _param
   LOCAL _broj := 0
   LOCAL _broj_old

   Box(, 2, 60 )

   // param: rnal_doc_no
   _param := "rnal_doc_no"
   _broj := fetch_metric( _param, nil, _broj )
   _broj_old := _broj

   @ m_x + 2, m_y + 2 SAY "Zadnji broj dokumenta:" GET _broj PICT "9999999999"

   READ

   BoxC()

   IF LastKey() != K_ESC
      // snimi broj u globalni brojac
      IF _broj <> _broj_old
         set_metric( _param, nil, _broj )
      ENDIF
   ENDIF

   RETURN
