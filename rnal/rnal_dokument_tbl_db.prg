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


// ----------------------------------
// brisanje print tabela
// ----------------------------------
FUNCTION d_rpt_dbfs()

   my_close_all_dbf()

   // t_docit.dbf
   FErase( my_home() + "t_docit.dbf" )
   FErase( my_home() + "t_docit.cdx" )

   // t_docit2.dbf
   FErase( my_home() + "t_docit2.dbf" )
   FErase( my_home() + "t_docit2.cdx" )

   // t_docop.dbf
   FErase( my_home() + "t_docop.dbf" )
   FErase( my_home() + "t_docop.cdx" )

   // t_pars.dbf
   FErase( my_home() + "t_pars.dbf" )
   FErase( my_home() + "t_pars.cdx" )

   RETURN 1


// ------------------------------------
// kreiranje print tabela
// ------------------------------------
FUNCTION t_rpt_create()

   LOCAL cT_DOCIT := "t_docit.dbf"
   LOCAL cT_DOCIT2 := "t_docit2.dbf"
   LOCAL cT_DOCOP := "t_docop.dbf"
   LOCAL cT_PARS := "t_pars.dbf"
   LOCAL aT_DOCIT := {}
   LOCAL aT_DOCIT2 := {}
   LOCAL aT_DOCOP := {}
   LOCAL aT_PARS := {}

   // brisi tabele....
   IF d_rpt_dbfs() == 0
      MsgBeep( "Greska: brisanje pomocnih tabela !" )
      RETURN .F.
   ENDIF

   // kreiraj T_DOCIT
   IF !File( my_home() + cT_DOCIT )
      g_docit_fields( @aT_DOCIT )
      dbcreate2( my_home() + cT_DOCIT, aT_DOCIT )
   ENDIF

   // kreiraj T_DOCIT2
   IF !File( my_home() + cT_DOCIT2 )
      g_docit2_fields( @aT_DOCIT2 )
      dbcreate2( my_home() + cT_DOCIT2, aT_DOCIT2 )
   ENDIF

   // kreiraj T_DOCOP
   IF !File( my_home() + cT_DOCOP )
      g_docop_fields( @aT_DOCOP )
      dbcreate2( my_home() + cT_DOCOP, aT_DOCOP )
   ENDIF

   // kreiraj T_PARS
   IF !File( my_home() + cT_PARS )
      g_pars_fields( @aT_PARS )
      dbcreate2( my_home() + cT_PARS, aT_PARS )
   ENDIF

   // kreiraj indexe
   // T_DOCIT
   // ---------------------------
   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(art_id,10)", "T_DOCIT" )
   CREATE_INDEX( "2", "STR(doc_no,10)+STR(doc_gr_no,2)+STR(doc_it_no,4)+STR(art_id,10)", "T_DOCIT" )
   CREATE_INDEX( "3", "STR(doc_no,10)+art_sh_des", "T_DOCIT" )
   CREATE_INDEX( "4", "STR(art_id,10)", "T_DOCIT" )
   CREATE_INDEX( "5", "art_sh_des", "T_DOCIT" )

   // T_DOCIT2
   // -----------------------------
   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(it_no,4)+art_id", "T_DOCIT2" )
   CREATE_INDEX( "2", "art_id", "T_DOCIT2" )

   // T_DOCOP
   // -----------------------------
   CREATE_INDEX( "1", "STR(doc_no,10)+STR(doc_it_no,4)+STR(doc_el_no,4)+STR(doc_op_no,4)", "T_DOCOP" )

   // T_PARS
   // -----------------------------
   CREATE_INDEX( "id_par", "id_par", "T_PARS" )

   RETURN .T.

// -----------------------------------------------
// setovanje polja tabele T_DOCIT
// -----------------------------------------------
STATIC FUNCTION g_docit_fields( aArr )

   AAdd( aArr, { "doc_gr_no", "N",   2,  0 } )
   AAdd( aArr, { "doc_no", "N",  10,  0 } )
   AAdd( aArr, { "doc_it_no", "N",   4,  0 } )
   AAdd( aArr, { "art_id", "N",  10,  0 } )
   AAdd( aArr, { "art_sh_des", "C", 150,  0 } )
   AAdd( aArr, { "art_desc", "C", 250,  0 } )
   AAdd( aArr, { "full_desc", "C", 250,  0 } )
   AAdd( aArr, { "doc_it_qtt", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_hei", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_h2", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_wid", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_w2", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_typ", "C",  1,  0 } )
   AAdd( aArr, { "doc_it_alt", "N",  15,  5 } )
   AAdd( aArr, { "doc_acity", "C",  50,  0 } )
   AAdd( aArr, { "doc_it_sch", "C",   1,  0 } )
   AAdd( aArr, { "doc_it_des", "C", 150,  0 } )
   AAdd( aArr, { "doc_it_tot", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_tm", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_zwi", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_zw2", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_zhe", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_zh2", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_net", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_bru", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_pos", "C",  20,  0 } )
   AAdd( aArr, { "it_lab_pos", "C",  20,  0 } )
   AAdd( aArr, { "print", "C",  1,  0 } )

   RETURN .T.

// setovanje polja tabele T_DOCOP
STATIC FUNCTION g_docop_fields( aArr )

   AAdd( aArr, { "doc_no", "N",  10,  0 } )
   AAdd( aArr, { "doc_op_no", "N",   4,  0 } )
   AAdd( aArr, { "doc_it_no", "N",   4,  0 } )
   AAdd( aArr, { "doc_el_no", "N",   4,  0 } )
   AAdd( aArr, { "doc_el_des", "C", 150,  0 } )
   AAdd( aArr, { "aop_id", "N",  10,  0 } )
   AAdd( aArr, { "aop_desc", "C", 150,  0 } )
   AAdd( aArr, { "aop_att_id", "N",  10,  0 } )
   AAdd( aArr, { "aop_att_de", "C", 150,  0 } )
   AAdd( aArr, { "doc_op_des", "C", 150,  0 } )
   AAdd( aArr, { "aop_value", "C", 150,  0 } )
   AAdd( aArr, { "aop_vraw", "C", 150,  0 } )

   RETURN .T.


// setovanje polja tabele T_DOCIT2
STATIC FUNCTION g_docit2_fields( aArr )

   AAdd( aArr, { "doc_no", "N",  10,  0 } )
   AAdd( aArr, { "doc_it_no", "N",   4,  0 } )
   AAdd( aArr, { "it_no", "N",   4,  0 } )
   AAdd( aArr, { "art_id", "C",  10,  0 } )
   AAdd( aArr, { "art_desc", "C", 250,  0 } )
   AAdd( aArr, { "doc_it_qtt", "N",  15,  5 } )
   AAdd( aArr, { "doc_it_q2", "N",  15,  5 } )
   AAdd( aArr, { "jmj", "C",   3,  0 } )
   AAdd( aArr, { "jmj_art", "C",   3,  0 } )
   AAdd( aArr, { "doc_it_pri", "N",  15,  5 } )
   AAdd( aArr, { "descr", "C", 200,  5 } )

   RETURN .T.



// setovanje polja tabele T_PARS
STATIC FUNCTION g_pars_fields( aArr )

   AAdd( aArr, { "id_par", "C",   3, 0 } )
   AAdd( aArr, { "opis", "C", 200, 0 } )

   RETURN .T.


// dodaj u tabelu T_PARS
FUNCTION add_tpars( cId_par, cOpis )

   LOCAL lFound
   LOCAL nTArea := Select()

   SELECT F_T_PARS
   IF !Used()
      O_T_PARS
      SET ORDER TO TAG "ID_PAR"
   ENDIF

   SELECT t_pars
   GO TOP

   SEEK cId_par

   IF !Found()
      APPEND BLANK
   ENDIF

   RREPLACE id_par WITH cId_par, opis WITH cOpis

   Select( nTArea )

   RETURN .T.


// isprazni print tabele
FUNCTION t_rpt_empty()

   O_T_DOCOP
   SELECT t_docop
   my_dbf_zap()

   O_T_DOCIT
   SELECT t_docit
   my_dbf_zap()

   O_T_DOCIT2
   SELECT t_docit2
   my_dbf_zap()

   O_T_PARS
   SELECT t_pars
   my_dbf_zap()

   RETURN .T.


// otvori print tabele
FUNCTION t_rpt_open()

   O_T_PARS
   O_T_DOCOP
   O_T_DOCIT
   O_T_DOCIT2

   RETURN .T.


/*
 vrati vrijednost polja opis iz tabele T_PARS po id kljucu
 */

FUNCTION g_t_pars_opis( cId_param )

   LOCAL xRet

   SELECT F_T_PARS
   IF !Used()
      O_T_PARS
   ENDIF

   SELECT t_pars
   SET ORDER TO TAG "id_par"
   GO TOP
   SEEK cId_param

   IF !Found()
      RETURN "-"
   ENDIF

   xRet := RTrim( opis )

   RETURN xRet


// dodaj stavke u tabelu T_DOCIT2
FUNCTION a_t_docit2( nDoc_no, nDoc_it_no, nIt_no, cArt_id, cArt_desc, ;
      nDoc_it_qtty, nDoc_it_q2, cJmj, cJmjArt, nDoc_it_price, ;
      nDescr )

   O_T_DOCIT2
   SELECT t_docit2

   APPEND BLANK

   REPLACE doc_no WITH nDoc_no
   REPLACE doc_it_no WITH nDoc_it_no
   REPLACE it_no WITH nIt_no
   REPLACE art_id WITH cArt_id
   REPLACE art_desc WITH cArt_desc
   REPLACE doc_it_qtt WITH nDoc_it_qtty
   REPLACE doc_it_q2 WITH nDoc_it_q2
   REPLACE jmj WITH cJmj
   REPLACE jmj_art WITH cJmjArt
   REPLACE doc_it_pri WITH nDoc_it_price
   REPLACE descr WITH nDescr

   RETURN .T.



// dodaj stavke u tabelu T_RNST
FUNCTION a_t_docit( nDoc_no, nDoc_gr_no, nDoc_it_no, nArt_id, cArt_desc, ;
      cArt_sh_desc, cOrigDesc, ;
      cDoc_it_schema, cDoc_it_desc, cDoc_it_type, ;
      nDoc_it_qtty, nDoc_it_heigh, nDoc_it_width, ;
      nDoc_it_h2, nDoc_it_w2, ;
      nDoc_it_altt, ;
      cDoc_it_city, ;
      nDoc_it_total, nDoc_it_tm, nGNHeigh, nGNWidth, ;
      nGnH2, nGNW2, ;
      nNeto, nBruto, cDoc_it_pos, cIt_lab_pos )

   O_T_DOCIT
   SELECT t_docit
   APPEND BLANK
   REPLACE doc_gr_no WITH nDoc_gr_no
   REPLACE doc_no WITH nDoc_no
   REPLACE doc_it_no WITH nDoc_it_no
   REPLACE art_id WITH nArt_id
   REPLACE art_desc WITH cArt_desc
   REPLACE full_desc WITH cOrigDesc
   REPLACE art_sh_des WITH cArt_sh_desc
   REPLACE doc_it_qtt WITH nDoc_it_qtty
   REPLACE doc_it_hei WITH nDoc_it_heigh
   REPLACE doc_it_h2 WITH nDoc_it_h2
   REPLACE doc_it_wid WITH nDoc_it_width
   REPLACE doc_it_w2 WITH nDoc_it_w2
   REPLACE doc_it_typ WITH cDoc_it_type
   REPLACE doc_it_alt WITH nDoc_it_altt
   REPLACE doc_acity WITH cDoc_it_city
   REPLACE doc_it_tot WITH nDoc_it_total
   REPLACE doc_it_tm WITH nDoc_it_tm
   REPLACE doc_it_sch WITH cDoc_it_schema
   REPLACE doc_it_des WITH cDoc_it_desc
   // printanje stavki iz tabele "D" - printaj, "N" - ne printaj
   REPLACE PRINT WITH "D"
   REPLACE doc_it_pos WITH cDoc_it_pos
   REPLACE it_lab_pos WITH cIt_lab_pos

   IF nGNHeigh <> nil
      REPLACE doc_it_zhe WITH nGNHeigh
      REPLACE doc_it_zh2 WITH nGNH2
      REPLACE doc_it_zwi WITH nGNWidth
      REPLACE doc_it_zw2 WITH nGNW2
      REPLACE doc_it_net WITH nNeto
      REPLACE doc_it_bru WITH nBruto
   ENDIF

   RETURN .T.


// dodaj stavke u tabelu T_DOCOP
FUNCTION a_t_docop( nDoc_no, nDoc_op_no, nDoc_it_no, ;
      nDoc_el_no, cDoc_el_desc, ;
      nAop_id, cAop_desc, ;
      nAop_att_id, cAop_att_desc, ;
      cDoc_op_desc, ;
      cAop_value, cAop_vraw )

   O_T_DOCOP
   SELECT t_docop
   APPEND BLANK

   REPLACE doc_no WITH nDoc_no
   REPLACE doc_op_no WITH nDoc_op_no
   REPLACE doc_it_no WITH nDoc_it_no
   REPLACE doc_el_no WITH nDoc_el_no
   REPLACE doc_el_des WITH cDoc_el_desc
   REPLACE aop_id WITH nAop_id
   REPLACE aop_desc WITH cAop_desc
   REPLACE aop_att_id WITH nAop_att_id
   REPLACE aop_att_de WITH cAop_att_desc
   REPLACE doc_op_des WITH cDoc_op_desc
   REPLACE aop_value WITH cAop_value
   REPLACE aop_vraw WITH cAop_vraw

   RETURN
