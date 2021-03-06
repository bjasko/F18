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

STATIC l_new_it
STATIC __doc
STATIC __doc_it_no


// --------------------------------------------
// pregled dodatni stavki naloga
// --------------------------------------------
FUNCTION box_it2( nDoc_no, nDoc_it_no )

   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL GetList := {}
   LOCAL nTArea := Select()

   PRIVATE kol
   PRIVATE imekol

   docit2_kol( @imekol, @kol )

   SELECT _doc_it2

   __doc := nDoc_no
   __doc_it_no := nDoc_it_no

   Box(, 17, 70 )

   // opcije
   @ box_x_koord() + 16, box_y_koord() + 2 SAY "<c+N> nova stavka  <F2> ispravka  <c+T> brisi stavku "
   @ box_x_koord() + 17, box_y_koord() + 2 SAY "<c+F9> brisi sve "

   my_browse( "it2", 15, 70, {| Ch| it2_handler() }, "Unos dodatni stavki naloga", "",,,,, 1 )

   BoxC()

   SELECT ( nTArea )

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN


// -----------------------------------------------------
// key handler
// -----------------------------------------------------
STATIC FUNCTION it2_handler()

   LOCAL nRet := DE_CONT

   DO CASE
   CASE ( Ch == K_F2 )

      IF field->doc_it_no <> 0 .AND. ;
            e_doc_it2( __doc, __doc_it_no, .F. ) <> 0
         nRet := DE_REFRESH
      ENDIF

   CASE ( Ch == K_CTRL_N )

      IF e_doc_it2( __doc, __doc_it_no, .T. ) <> 0
         nRet := DE_REFRESH
      ENDIF

   CASE ( Ch == K_CTRL_T )

      IF Pitanje(, "Izbrisati stavku ?", "N" ) == "D"
         SELECT _doc_it2
         my_rlock()
         DELETE
         my_unlock()
         my_dbf_pack()
         nRet := DE_REFRESH
      ENDIF

   CASE ( Ch == k_ctrl_f9() )

      IF Pitanje(, "Izbrisati kompletnu tabelu ?", "N" ) == "D"
         IF Pitanje(, "Sigurni 100% ?", "N" ) == "D"
            SELECT _doc_it2
            my_dbf_zap()
            nRet := DE_REFRESH
         ENDIF
      ENDIF

   ENDCASE

   RETURN nRet


// ---------------------------------------------
// setuje matricu kolona tabele _DOC_IT2
// ---------------------------------------------
STATIC FUNCTION docit2_kol( aImeKol, aKol )

   LOCAL i

   aImeKol := {}
   aKol := {}

   AAdd( aImeKol, { "Stavka", {|| doc_it_no }, "it_no" } )
   AAdd( aImeKol, { "R.br", {|| it_no }, "it_no" } )
   AAdd( aImeKol, { "Artikal", {|| art_id }, "art_id" } )
   AAdd( aImeKol, { "Kol.", {|| doc_it_qtt }, "doc_it_qtt" } )
   AAdd( aImeKol, { "Duzina", {|| doc_it_q2 }, "doc_it_q2" } )
   AAdd( aImeKol, { "JMJ", {|| jmj }, "jmj" } )
   AAdd( aImeKol, { "RJM", {|| jmj_art }, "jmj_art" } )
   AAdd( aImeKol, { "Cijena", {|| doc_it_pri }, "doc_it_pri" } )
   AAdd( aImeKol, { "Opis", {|| sh_desc }, "sh_desc" } )
   AAdd( aImeKol, { "Napomene", {|| descr }, "descr" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.


// ------------------------------------------
// unos ispravka dodatni stavki naloga....
// nDoc_no - dokument broj
// lNew - nova stavka .t. or .f.
// ------------------------------------------
FUNCTION e_doc_it2( nDoc_no, nDoc_it_no, lNew )

   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL nGetBoxX := 18
   LOCAL nGetBoxY := 70
   LOCAL cBoxNaz := "unos nove stavke"
   LOCAL nRet := 0
   LOCAL nFuncRet := 0
   LOCAL _rec
   PRIVATE GetList := {}

   __doc := nDoc_no
   __doc_it_no := nDoc_it_no

   IF lNew == nil
      lNew := .T.
   ENDIF

   l_new_it := lNew

   IF l_new_it == .F.
      cBoxNaz := "ispravka stavke"
   ENDIF

   SELECT _doc_it2

   Box(, nGetBoxX, nGetBoxY, .F., "Unos stavki naloga" )

   set_opc_box( nGetBoxX, 50 )

   // say top, bottom
   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadL( "***** " + cBoxNaz, nGetBoxY - 2 )
   @ box_x_koord() + nGetBoxX, box_y_koord() + 2 SAY PadL( "(*) popuna obavezna", nGetBoxY - 2 ) COLOR "BG+/B"

   DO WHILE .T.

      set_global_memvars_from_dbf()

      nFuncRet := _e_box_it2( nGetBoxX, nGetBoxY )

      IF nFuncRet == 1

         SELECT _doc_it2

         IF l_new_it
            APPEND BLANK
         ENDIF

         _rec := get_hash_record_from_global_vars( NIL, .F. )

         dbf_update_rec( _rec )

         IF l_new_it
            LOOP
         ENDIF

      ENDIF

      BoxC()
      SELECT _doc_it2

      nRet := RECCOUNT2()

      EXIT

   ENDDO

   SELECT _doc_it2

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN nRet


// -------------------------------------------------
// forma za unos podataka
// cGetDOper , D - unesi dodatne operacije...
// -------------------------------------------------
STATIC FUNCTION _e_box_it2( nBoxX, nBoxY )

   LOCAL nX := 1
   LOCAL nLeft := 21
   LOCAL cPicQtty := "999999.999"
   LOCAL cPicPrice := "999999.99"
   LOCAL __roba

   IF l_new_it
      _doc_no := __doc
      _doc_it_no := __doc_it_no
      _it_no := inc_docit2( __doc, __doc_it_no )
      _jmj := "KOM"
      _jmj_art := ""
      _doc_it_q2 := 0
      _doc_it_qtt := 0
   ENDIF

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Stavka naloga (*)", nLeft ) GET _doc_it_no ;
      VALID {|| if( l_new_it, _it_no := inc_docit2( _doc_no, _doc_it_no ), .T. ), .T. }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "r.br stavke (*)", nLeft ) GET _it_no PICT "9999"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "F18 ARTIKAL (*):", nLeft ) GET _art_id ;
      VALID {|| p_roba( @_art_id ), __roba := g_roba_hash( _art_id ), ;
      _doc_it_pri := get_hash_value( __roba, "vpc", 0 ), ;
      show_it( g_roba_desc( _art_id ) + ".." + "[" + AllTrim( Upper( get_hash_value( __roba, "jmj", "" ) ) ) + "]", 35 ), ;
      IF( __roba == NIL, .F., .T. ) } ;
      WHEN set_opc_box( nBoxX, 50, "uzmi sifru iz F18/roba" )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Jedinica mjere (*):", nLeft + 3 ) GET _jmj ;
      PICT "@!S3" ;
      VALID {|| _jmj_art := Upper( get_hash_value( __roba, "jmj", "" ) ), !Empty( _jmj ), valid_repro_jmj( _jmj, _jmj_art ) } ;
      WHEN set_opc_box( nBoxX, 50, "Unositi komadno ili u originalnoj jmj ?" )

   READ
   ESC_RETURN 0

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "kolicina (*):", nLeft + 3 ) GET _doc_it_qtt ;
      PICT cPicQtty ;
      WHEN set_opc_box( nBoxX, 50, "koliko komada se isporučuje ?" )

   // provjeriti da li je jedinica mjere artikla metrička
   // ako jeste otključaj polje za unos dužine
   // u slučaju da je
   IF jmj_is_metric( _jmj_art ) .AND. ( _jmj == "KOM" )
      @ box_x_koord() + nX, Col() + 1 SAY hb_UTF8ToStr( "dužina [mm] (*):" ) GET _doc_it_q2 ;
         PICT cPicQtty ;
         WHEN set_opc_box( nBoxX, 50, "repromaterijal je metrički, unesi dužinu u mm" )
   ELSE
      @ box_x_koord() + nX, Col() + 1 SAY PadR( "", 28 )
   ENDIF

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "cijena:", nLeft + 3 ) GET _doc_it_pri ;
      PICT cPicPrice WHEN set_opc_box( nBoxX, 50, "opciono cijena" )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "opis:", nLeft ) GET _sh_desc ;
      PICT "@S40" ;
      WHEN set_opc_box( nBoxX, 50, "opis vezan za samu stavku" )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "napomena:", nLeft ) GET _descr ;
      PICT "@S40" ;
      WHEN set_opc_box( nBoxX, 50, "dodatne napomene vezane za samu stavku" )


   READ
   ESC_RETURN 0

   RETURN 1




// -------------------------------------------
// uvecaj broj stavke naloga
// -------------------------------------------
STATIC FUNCTION inc_docit2( nDoc_no, nDoc_it_no )

   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL nRet := 0

   SELECT _doc_it2
   GO TOP
   SET ORDER TO TAG "1"
   SEEK doc_str( nDoc_no ) + docit_str( nDoc_it_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. ;
         field->doc_it_no == nDoc_it_no
      nRet := field->it_no
      SKIP
   ENDDO

   nRet += 1

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN nRet


// ----------------------------------------------
// vraca opis robe
// ----------------------------------------------
FUNCTION g_roba_desc( cId )

   LOCAL cDescr := ""
   LOCAL nTArea := Select()

   SELECT ( F_ROBA )
   IF !Used()
      o_roba()
   ENDIF

   select_o_roba( cId )

   IF Found()
      cDescr := AllTrim( roba->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN cDescr




// ----------------------------------------------
// vraca cijenu robe
// ----------------------------------------------
FUNCTION g_roba_price( cId )

   LOCAL nPrice
   LOCAL nTArea := Select()

   //SELECT ( F_ROBA )
   //IF !Used()
   //    o_roba()
   //ENDIF

   select_o_roba( cId )

   IF Found()
      nPrice := roba->vpc
   ENDIF

   SELECT ( nTArea )

   RETURN nPrice


// ---------------------------------------------------------------
// vraca vrijednosti iz hash matrice
//
// primjer:
//      hash["test"] := 1
//      get_hash_value( hash, "test", 0 ) => 1
//      get_hash_value( hash, "xzxx", 0 ) => 0
// ---------------------------------------------------------------
STATIC FUNCTION get_hash_value( hash, key, default_value )

   IF hash == NIL
      RETURN default_value
   ENDIF

   IF hb_hHasKey( hash, key )
       RETURN hash[ key ]
   ELSE
       RETURN default_value
   ENDIF




// ---------------------------------------------------------------
// vraca hash matricu sa podacima iz tabele roba
// ---------------------------------------------------------------
FUNCTION g_roba_hash( id_roba )

   LOCAL _hash

   _hash := _set_sql_record_to_hash( f18_sql_schema( "roba" ), id_roba )

   IF VALTYPE( _hash ) $ "U" .AND. _hash == NIL
       RETURN NIL
   ENDIF

   RETURN _hash
