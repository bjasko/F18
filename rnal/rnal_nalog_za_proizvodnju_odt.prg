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

STATIC PIC_VRIJEDNOST := ""
STATIC LEN_VRIJEDNOST := 12

FUNCTION rnal_nalog_za_proizvodnju_odt()

   LOCAL _groups := {}
   LOCAL _params
   LOCAL _cnt := 0
   LOCAL _doc_no, _doc_gr
   LOCAL _ok := .F.
   LOCAL _template := "nalprg.odt"
   LOCAL _po_grupama := .T.

   download_template( "nalprg.odt", "51ad3aa8eb08836029345a48189e9acf08da758113b4346e542cfb980997eb19" )
   t_rpt_open()

   SELECT t_docit
   SET ORDER TO TAG "2"
   GO TOP
   _doc_no := field->doc_no

   DO WHILE !Eof() .AND. field->doc_no == _doc_no
      _doc_gr := field->doc_gr_no
      DO WHILE !Eof() .AND. field->doc_no == _doc_no .AND. field->doc_gr_no == _doc_gr
         SKIP
      ENDDO
      ++_cnt
      AAdd( _groups, { _doc_gr, _cnt } )
   ENDDO

   SELECT t_docit
   GO TOP

   procitaj_parametre_naloga( @_params, Len( _groups ) )

   IF !kreiraj_xml_fajl( _groups, _params )
      RETURN _ok
   ENDIF

   SELECT t_docit
   USE
   SELECT t_docop
   USE
   SELECT t_pars
   USE

   IF Len( _groups ) == 1 .AND. _groups[ 1, 1 ] == 0
      _po_grupama := .F.
   ENDIF

   IF generisi_odt_iz_xml( _template )
      prikazi_odt()
   ENDIF

   my_close_all_dbf()

   _ok := .T.

   RETURN _ok



STATIC FUNCTION procitaj_parametre_naloga( params, groups_total )

   LOCAL _tmp

   params := hb_Hash()

   _tmp := Val( g_t_pars_opis( "N10" ) )
   params[ "ttotal" ] := _tmp
   params[ "rekap_materijala" ] := ( AllTrim( g_t_pars_opis( "N20" ) ) == "D" )

   _tmp := g_t_pars_opis( "N13" )
   params[ "nalog_operater" ] := _tmp
   _tmp := getfullusername( f18_get_user_id( f18_user() ) )
   params[ "nalog_print_operater" ] := _tmp
   _tmp := PadR( Time(), 5 )
   params[ "nalog_print_vrijeme" ] := _tmp

   params[ "nalog_broj" ] := g_t_pars_opis( "N01" )
   params[ "nalog_naziv" ] := "NALOG ZA PROIZVODNJU br."
   params[ "nalog_grupa_total" ] := AllTrim( Str( groups_total ) )
   params[ "nalog_grupa" ] := AllTrim( Str( 1 ) )
   params[ "nalog_datum" ] := g_t_pars_opis( "N02" )
   params[ "nalog_vrijeme" ] := g_t_pars_opis( "N12" )
   params[ "nalog_isp_datum" ] := g_t_pars_opis( "N03" )
   params[ "nalog_isp_vrijeme" ] := g_t_pars_opis( "N04" )
   params[ "nalog_prioritet" ] := g_t_pars_opis( "N05" )
   params[ "nalog_isp_mjesto" ] := g_t_pars_opis( "N07" )
   params[ "nalog_dod_opis" ] := g_t_pars_opis( "N08" )
   params[ "nalog_kratki_opis" ] := g_t_pars_opis( "N15" )
   params[ "nalog_objekat_id" ] := g_t_pars_opis( "P20" )
   params[ "nalog_objekat_naziv" ] := g_t_pars_opis( "P21" )
   params[ "nalog_vrsta_placanja" ] := g_t_pars_opis( "N06" )
   params[ "nalog_placeno" ] := g_t_pars_opis( "N10" )
   params[ "nalog_placanje_opis" ] := g_t_pars_opis( "N11" )
   params[ "nalog_tip" ] := g_t_pars_opis( "N21" )
   params[ "nalog_status" ] := g_t_pars_opis( "N22" )

   params[ "firma_naziv" ] := AllTrim( gFNaziv )
   params[ "kupac_id" ] := g_t_pars_opis( "P01" )
   params[ "kupac_naziv" ] := g_t_pars_opis( "P02" )
   params[ "kupac_adresa" ] := g_t_pars_opis( "P03" )
   params[ "kupac_telefon" ] := g_t_pars_opis( "P04" )
   params[ "kontakt_id" ] := g_t_pars_opis( "P10" )
   params[ "kontakt_naziv" ] := g_t_pars_opis( "P11" )
   params[ "kontakt_telefon" ] := g_t_pars_opis( "P12" )
   params[ "kontakt_opis" ] := g_t_pars_opis( "P13" )
   params[ "kontakt_opis_2" ] := g_t_pars_opis( "N09" )

   RETURN .T.



STATIC FUNCTION kreiraj_xml_fajl( groups, params )

   LOCAL _ok := .F.
   LOCAL nI, _group_id
   LOCAL _groups_count, _groups_total
   LOCAL _doc_rbr
   LOCAL _doc_it_type
   LOCAL _rekap := .F.
   LOCAL _qtty_total := 0
   LOCAL _count
   LOCAL _t_total
   LOCAL _xml := my_home() + "data.xml"
   LOCAL _picdem := "999999999.99"
   LOCAL _a_items := {}

   PIC_VRIJEDNOST := PadL( AllTrim( Right( _picdem, LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )

   create_xml( _xml )

   xml_subnode( "nalozi", .F. )

   xml_node( "fdesc", to_xml_encoding( params[ "firma_naziv" ] ) )
   xml_node( "tip", params[ "nalog_tip" ] )
   xml_node( "no", params[ "nalog_broj" ] )

   IF params[ "nalog_tip" ] == "NP"
      xml_node( "desc", to_xml_encoding( "NEUSKLADJEN PROIZVOD br." ) )
   ELSE
      xml_node( "desc", to_xml_encoding( params[ "nalog_naziv" ] ) )
   ENDIF

   xml_node( "gr_total", params[ "nalog_grupa_total" ] )
   xml_node( "date", params[ "nalog_datum" ] )
   xml_node( "time", params[ "nalog_vrijeme" ] )
   xml_node( "d_date", params[ "nalog_isp_datum" ] )
   xml_node( "d_time", params[ "nalog_isp_vrijeme" ] )
   xml_node( "d_place", to_xml_encoding( params[ "nalog_isp_mjesto" ] ) )
   xml_node( "prior", to_xml_encoding( params[ "nalog_prioritet" ] ) )
   xml_node( "desc_2", to_xml_encoding( params[ "nalog_dod_opis" ] ) )
   xml_node( "desc_3", to_xml_encoding( params[ "nalog_kratki_opis" ] ) )
   xml_node( "ob_id", to_xml_encoding( params[ "nalog_objekat_id" ] ) )
   xml_node( "ob_desc", to_xml_encoding( params[ "nalog_objekat_naziv" ] ) )
   xml_node( "oper", to_xml_encoding( params[ "nalog_operater" ] ) )
   xml_node( "oper_print", to_xml_encoding( params[ "nalog_print_operater" ] ) )
   xml_node( "pr_time", params[ "nalog_print_vrijeme" ] )
   xml_node( "vrpl", params[ "nalog_vrsta_placanja" ] )
   xml_node( "stat", to_xml_encoding( params[ "nalog_status" ] ) )

   xml_node( "cust_id", to_xml_encoding( params[ "kupac_id" ] ) )
   xml_node( "cust_desc", to_xml_encoding( params[ "kupac_naziv" ] ) )
   xml_node( "cust_adr", to_xml_encoding( params[ "kupac_adresa" ] ) )
   xml_node( "cust_tel", to_xml_encoding( params[ "kupac_telefon" ] ) )
   xml_node( "cont_id", to_xml_encoding( params[ "kontakt_id" ] ) )
   xml_node( "cont_desc", to_xml_encoding( params[ "kontakt_naziv" ] ) )
   xml_node( "cont_tel", to_xml_encoding( params[ "kontakt_telefon" ] ) )
   xml_node( "cont_desc_2", to_xml_encoding( params[ "kontakt_opis" ] ) )
   xml_node( "cont_desc_3", to_xml_encoding( params[ "kontakt_opis_2" ] ) )

   FOR nI := 1 TO Len( groups )

      _a_items := {}

      xml_subnode( "nalog", .F. )

      _group_id := groups[ nI, 1 ]

      params[ "nalog_grupa" ] := AllTrim( Str( _group_id ) )
      params[ "nalog_grupa_naziv" ] := get_art_docgr( _group_id )
      xml_node( "gr_no", params[ "nalog_grupa" ] )
      xml_node( "gr_desc", to_xml_encoding( params[ "nalog_grupa_naziv" ] ) )

      xml_node( "pg_no", AllTrim( Str( nI ) ) )
      xml_node( "pg_total", AllTrim( Str( Len( groups ) ) ) )

      SELECT t_docit
      SET ORDER TO TAG "2"
      GO TOP

      _doc_no := field->doc_no

      SEEK docno_str( _doc_no ) + Str( _group_id, 2 )

      _art_id := 0
      _art_tmp := 0

      _l_opis_artikla := .F.
      _l_opis_stavke := .F.

      _opis_stavke := ""
      _opis_stavke_tmp := ""

      _doc_rbr := 0
      _qtty_total := 0
      _count := 0

      DO WHILE !Eof() .AND. field->doc_no == _doc_no .AND. field->doc_gr_no == _group_id

         AAdd( _a_items, { field->doc_no, field->doc_it_no } )

         xml_subnode( "item", .F. )

         _art_id := field->art_id
         _item_type := field->doc_it_typ

         xml_node( "no", AllTrim( Str( ++_doc_rbr ) ) )

         IF !Empty( field->art_desc )
            xml_node( "desc", to_xml_encoding( AllTrim( field->art_desc ) ) )
         ELSE
            xml_node( "desc", to_xml_encoding( AllTrim( "-||-" ) ) )
         ENDIF

         SELECT t_docop
         SET ORDER TO TAG "1"
         GO TOP
         SEEK docno_str( t_docit->doc_no ) + docit_str( t_docit->doc_it_no )

         DO WHILE !Eof() .AND. field->doc_no == t_docit->doc_no ;
               .AND. field->doc_it_no == t_docit->doc_it_no

            _el_no := field->doc_el_no
            _el_desc := 1
            _el_count := 0

            xml_subnode( "element", .F. )

            xml_node( "no", AllTrim( Str( field->doc_el_no ) ) )
            xml_node( "desc", to_xml_encoding( AllTrim( field->doc_el_des ) ) )

            DO WHILE !Eof() .AND. field->doc_no == t_docit->doc_no ;
                  .AND. field->doc_it_no == t_docit->doc_it_no ;
                  .AND. field->doc_el_no == _el_no

               xml_subnode( "oper", .F. )

               _el_desc := 0

               IF !Empty( field->aop_desc ) .AND. AllTrim( field->aop_desc ) <> "?????"
                  xml_node( "cnt", AllTrim( Str( ++_el_count ) ) )
                  xml_node( "op_desc", to_xml_encoding( field->aop_desc ) )
               ELSE
                  xml_node( "cnt", AllTrim( Str( 0 ) ) )
                  xml_node( "op_desc", "" )
               ENDIF

               IF !Empty( field->aop_att_de ) .AND. AllTrim( field->aop_att_de ) <> "?????"
                  xml_node( "att_desc", to_xml_encoding( AllTrim( field->aop_att_de ) ) )
                  xml_node( "att_val", to_xml_encoding( AllTrim( field->aop_value ) ) )
               ELSE
                  xml_node( "att_desc", "" )
                  xml_node( "att_val", "" )
               ENDIF

               IF !Empty( field->doc_op_des )
                  xml_node( "notes", to_xml_encoding( AllTrim( field->doc_op_des ) ) )
               ELSE
                  xml_node( "notes", "" )
               ENDIF

               xml_subnode( "oper", .T. )

               SELECT t_docop
               SKIP

            ENDDO

            xml_subnode( "element", .T. )

         ENDDO

         SELECT t_docit

         IF _item_type == "R"
            xml_node( "type", "fi" )

            IF Round( field->doc_it_wid + field->doc_it_hei, 2 ) == 0
               xml_node( "w", "" )
               xml_node( "h", "" )
            ELSE
               xml_node( "h", "" )
               IF Round( field->doc_it_wid, 2 ) == Round( field->doc_it_hei, 2 )
                  xml_node( "w", show_number( field->doc_it_wid, PIC_VRIJEDNOST ) )
               ELSE
                  xml_node( "w", show_number( field->doc_it_wid, PIC_VRIJEDNOST ) + ", " + show_number( field->doc_it_hei, PIC_VRIJEDNOST ) )
               ENDIF
            ENDIF

         ELSEIF _item_type == "S"
            xml_node( "type", "shp" )
            xml_node( "w", show_number( field->doc_it_wid, PIC_VRIJEDNOST ) )
            xml_node( "h", show_number( field->doc_it_hei, PIC_VRIJEDNOST ) )
         ELSE

            xml_node( "type", "std" )
            xml_node( "w", show_number( field->doc_it_wid, PIC_VRIJEDNOST ) )
            xml_node( "h", show_number( field->doc_it_hei, PIC_VRIJEDNOST ) )

         ENDIF

         xml_node( "kol", show_number( field->doc_it_qtt, PIC_VRIJEDNOST ) )
         _qtty_total += field->doc_it_qtt

         _tmp := ""
         _opis_stavke := ""
         _l_opis_stavke := .F.

         IF !Empty( field->doc_it_des ) ;
               .OR. field->doc_it_alt <> 0 ;
               .OR. ( field->doc_it_sch == "D" )

            _tmp := "Napomene: " + AllTrim( field->doc_it_des )

            IF field->doc_it_sch == "D"
               _tmp += " "
               _tmp += "(SHEMA U PRILOGU)"
            ENDIF

            IF field->doc_it_alt <> 0

               IF !Empty( field->doc_acity )
                  _tmp += " "
                  _tmp += "Montaza: "
                  _tmp += AllTrim( field->doc_acity )
               ENDIF

               _tmp += ", "
               _tmp += "nadmorska visina = " + AllTrim( Str( field->doc_it_alt, 12, 2 ) ) + " m"

            ENDIF

            _opis_stavke := _tmp
            _tmp := ""

            IF ( AllTrim( _opis_stavke_tmp ) <> AllTrim( _opis_stavke ) ) .OR. ( _art_tmp <> _art_id )
               _l_opis_stavke := .T.
            ENDIF

         ENDIF

         IF _l_opis_stavke
            xml_node( "note", to_xml_encoding( _opis_stavke )  )
         ELSE
            xml_node( "note", "" )
         ENDIF

         xml_subnode( "item", .T. )

         SELECT t_docit
         SKIP

         _opis_stavke_tmp := _opis_stavke
         _art_tmp := _art_id

         ++_count

      ENDDO

      xml_node( "qtty", show_number( _qtty_total, PIC_VRIJEDNOST ) )

      _xml_repromaterijal( _a_items, groups, _group_id, params )

      xml_subnode( "nalog", .T. )

   NEXT

   xml_subnode( "nalozi", .T. )

   close_xml()

   _ok := .T.

   RETURN _ok



FUNCTION _xml_repromaterijal( a_items, groups, group_id, params )

   LOCAL nDbfArea := Select()
   LOCAL nTrec := RecNo()
   LOCAL _doc_no, _doc_it_no, nI

   SELECT t_docit2
   GO TOP

   IF RECCOUNT2() == 0 .OR. !params[ "rekap_materijala" ]
      RETURN
   ENDIF

   xml_subnode( "rekap", .F. )

   FOR nI := 1 TO Len( a_items )

      _doc_no := a_items[ nI, 1 ]
      _doc_it_no := a_items[ nI, 2 ]

      IF Len( groups ) > 1 .AND. group_id <> rnal_zadnja_grupa_stavke( _doc_no, _doc_it_no )
         LOOP
      ENDIF

      SELECT t_docit2
      SET ORDER TO TAG "1"
      GO TOP
      SEEK docno_str( _doc_no ) + docit_str( _doc_it_no )

      DO WHILE !Eof() .AND. field->doc_no == _doc_no .AND. field->doc_it_no == _doc_it_no

         SELECT t_docit
         SEEK docno_str( _doc_no ) + docit_str( _doc_it_no )

         IF field->PRINT == "N"
            SELECT t_docit2
            SKIP
            LOOP
         ENDIF

         SELECT t_docit2

         xml_subnode( "item", .F. )

         xml_node( "no", "(" + AllTrim( Str( field->doc_it_no ) ) + ")/" + AllTrim( Str( field->it_no ) ) )
         xml_node( "id", to_xml_encoding( AllTrim( field->art_id ) ) )
         xml_node( "desc", to_xml_encoding( AllTrim( field->art_desc ) ) )
         xml_node( "notes", to_xml_encoding( AllTrim( field->descr ) ) )
         xml_node( "qtty", repro_qtty_str( field->doc_it_qtt, field->doc_it_q2 ) )

         xml_subnode( "item", .T. )

         SKIP

      ENDDO

   NEXT

   xml_subnode( "rekap", .T. )

   SELECT ( nDbfArea )
   SET ORDER TO TAG "2"
   GO ( nTrec )

   RETURN



FUNCTION repro_qtty_str( kol, duzina )

   LOCAL _str := ""

   _str := AllTrim( Str( kol, 12, 2 ) )

   IF duzina > 0
      _str += " x " + AllTrim( Str( duzina, 12, 2 ) ) + " (mm)"
   ENDIF

   RETURN _str



FUNCTION rnal_zadnja_grupa_stavke( doc_no, doc_it_no )

   LOCAL _group := 1
   LOCAL nDbfArea := Select()

   SELECT t_docit
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( doc_no ) + docit_str( doc_it_no )

   DO WHILE !Eof() .AND. field->doc_no == doc_no .AND. field->doc_it_no == doc_it_no
      IF field->doc_gr_no > _group
         _group := field->doc_gr_no
      ENDIF
      SKIP
   ENDDO

   SELECT ( nDbfArea )

   RETURN _group
