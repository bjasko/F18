/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

CLASS FinBrutoBilans

   DATA hParams
   DATA DATA
   DATA zagl
   DATA klase

   VAR pict_iznos
   VAR tip
   // tip: 1 - subanaliticki
   // tip: 2 - analiticki
   // tip: 3 - sinteticki
   // tip: 4 - po grupama

   METHOD New()
   METHOD get_data()

   METHOD PRINT()
   METHOD print_txt()
   METHOD print_odt()

   METHOD create_r_export()
   METHOD fill_r_export()

   PROTECTED:

   VAR broj_stranice
   VAR txt_rpt_len

   METHOD print_b_rpt()

   METHOD set_bb_params()
   METHOD get_vars()
   METHOD gen_xml()

   METHOD init_params()
   METHOD set_txt_lines()
   METHOD zaglavlje_txt()

   METHOD rekapitulacija_klasa()

ENDCLASS


METHOD FinBrutoBilans:New( _tip_ )

   ::tip := 3
   ::klase := {}
   ::DATA := NIL
   ::broj_stranice := 0
   ::txt_rpt_len := 60
   ::init_params()

   IF _tip_ <> NIL
      ::tip := _tip_
   ENDIF

   RETURN SELF


METHOD FinBrutoBilans:init_params()

   ::hParams := hb_Hash()
   ::hParams[ "idfirma" ] := self_organizacija_id()
   ::hParams[ "datum_od" ] := CToD( "" )
   ::hParams[ "datum_do" ] := Date()
   ::hParams[ "konto" ] := ""
   ::hParams[ "valuta" ] := 1
   ::hParams[ "id_rj" ] := ""
   ::hParams[ "export_dbf" ] := .F.
   ::hParams[ "saldo_nula" ] := .F.
   ::hParams[ "txt" ] := .T.
   ::hParams[ "kolona_tek_prom" ] := .T.
   ::hParams[ "naziv" ] := ""
   ::hParams[ "odt_template" ] := ""
   ::hParams[ "varijanta" ] := "B"
   ::hParams[ "podklase" ] := .F.
   ::hParams[ "format" ] := "2"

   ::pict_iznos := AllTrim( gPicBHD )

   RETURN SELF


METHOD FinBrutoBilans:set_bb_params()

   download_template( "fin_bbl.odt", "11db1d0d324024423dc153f67b19e1495fddfe5900740458c98b5bdc52f01e3f" )

   DO CASE
   CASE ::tip == 1
      ::hParams[ "naziv" ] := "SUBANALITIČKI BRUTO BILANS"
      ::hParams[ "odt_template" ] := "fin_bbl.odt"
   CASE ::tip == 2
      ::hParams[ "naziv" ] := "ANALITIČKI BRUTO BILANS"
      ::hParams[ "odt_template" ] := "fin_bbl.odt"
   CASE ::tip == 3
      ::hParams[ "naziv" ] := "SINTETIČKI BRUTO BILANS"
      ::hParams[ "odt_template" ] := "fin_bbl.odt"
   CASE ::tip == 4
      ::hParams[ "naziv" ] := "BRUTO BILANS PO GRUPAMA"
      ::hParams[ "odt_template" ] := "fin_bbl.odt"
   ENDCASE

   RETURN SELF


METHOD FinBrutoBilans:print_b_rpt()

   DO CASE
   CASE ::tip == 1
      //IF ::hParams[ "pdf" ]
        fin_bb_subanalitika_pdf( ::hParams )
      //ELSE
      //  fin_bb_subanalitika_b( ::hParams )
      //ENDIF
   CASE ::tip == 2
      //IF ::hParams[ "pdf" ]
         fin_bb_analitika_pdf( ::hParams )
      //ELSE
      //   fin_bb_analitika_b( ::hParams )
      //ENDIF
   CASE ::tip == 3
      //IF ::hParams[ "pdf" ]
         fin_bb_sintetika_pdf( ::hParams )
      //ELSE
      //   fin_bb_sintetika_b( ::hParams )
      //ENDIF
   CASE ::tip == 4
      fin_bb_grupe_b( ::hParams )
   ENDCASE

   RETURN SELF


METHOD FinBrutoBilans:get_vars()

   LOCAL _ok := .F.
   LOCAL _val := 1
   LOCAL nX := 1
   LOCAL _valuta := 1
   LOCAL _user := my_user()
   LOCAL _konto := PadR( fetch_metric( "fin_bb_konto", _user, "" ), 200 )
   LOCAL _dat_od := fetch_metric( "fin_bb_dat_od", _user, CToD( "" ) )
   LOCAL _dat_do := fetch_metric( "fin_bb_dat_do", _user, CToD( "" ) )
   LOCAL _var_ab := fetch_metric( "fin_bb_var_ab", _user, "B" )
   LOCAL _var_txt := fetch_metric( "fin_bb_var_txt", _user, "1" )
   LOCAL _tek_prom := fetch_metric( "fin_bb_kol_tek_promet", _user, "D" )
   LOCAL _saldo_nula := fetch_metric( "fin_bb_saldo_nula", _user, "D" )
   LOCAL _podklase := fetch_metric( "fin_bb_pod_klase", _user, "N" )
   LOCAL _format := fetch_metric( "fin_bb_format", _user, "2" )
   LOCAL _id_rj := Space( 6 )
   LOCAL lExportXLSX := "N"
   LOCAL _tip := 3
   LOCAL GetList := {}

   IF ::tip <> NIL
      _tip := ::tip
   ENDIF

   Box(, 20, 75 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "***** BRUTO BILANS *****"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "ODABERI VRSTU BILANSA:"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "[1] subanalitički [2] analitički [3] sintetički [4] po grupama :" GET _tip PICT "9"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "VRSTA ŠTAMPE:"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "[1] PDF [2] ODT-LO:" GET _var_txt PICT "@!" VALID _var_txt $ "12"

   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN _ok
   ENDIF

   IF _var_txt == "1" .OR. _var_txt == "3"
      _var_ab := "B"
   ELSE
      _var_ab := "A"
   ENDIF

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "**** USLOVI IZVJEŠTAJA:"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma "
   ?? self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Konta (prazno-sva):" GET _konto PICT "@!S40"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Za period od:" GET _dat_od
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET _dat_do

   ++nX
   IF _var_txt == "1"
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta izvještaja (A/B):" GET _var_ab PICT "@!" VALID _var_ab $ "AB"
   ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz stavki sa saldom 0 (D/N) ?" GET _saldo_nula VALID _saldo_nula $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz kolone tekući promet (D/N) ?" GET _tek_prom VALID _tek_prom $ "DN" PICT "@!"

   @ box_x_koord() + nX, Col() + 1 SAY8 "Klase unutar izvještaja (D/N) ?" GET _podklase VALID _podklase $ "DN" PICT "@!"

   IF gFinRj == "D"
      ++nX
      _id_rj := Space( 6 )
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Radna jedinica ( 999999-sve ): " GET _id_rj
   ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Format izvještaja (1 sa tekućim prometom, 2 - bez) ?" GET _format PICT "@S1" VALID _format $ "12"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Export u XLSX (D/N)?" GET lExportXLSX VALID lExportXLSX $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   IF _var_ab == "B" .AND. _var_txt == "2"
      _var_txt := "1"
   ENDIF

   set_metric( "fin_bb_konto", _user, AllTrim( _konto ) )
   set_metric( "fin_bb_dat_od", _user, _dat_od )
   set_metric( "fin_bb_dat_do", _user, _dat_do )
   set_metric( "fin_bb_saldo_nula", _user, _saldo_nula )
   set_metric( "fin_bb_kol_tek_promet", _user, _tek_prom )
   set_metric( "fin_bb_var_ab", _user, _var_ab )
   set_metric( "fin_bb_var_txt", _user, _var_txt )
   set_metric( "fin_bb_pod_klase", _user, _podklase )
   set_metric( "fin_bb_format", _user, _format )

   ::hParams[ "idfirma" ] := self_organizacija_id()
   ::hParams[ "konto" ] := AllTrim( _konto )
   ::hParams[ "datum_od" ] := _dat_od
   ::hParams[ "datum_do" ] := _dat_do
   ::hParams[ "valuta" ] := _valuta
   ::hParams[ "id_rj" ] := IF( Empty( _id_rj ), AllTrim( _id_rj ), _id_rj )
   ::hParams[ "export_dbf" ] := ( lExportXLSX == "D" )
   ::hParams[ "saldo_nula" ] := ( _saldo_nula == "D" )
   ::hParams[ "kolona_tek_prom" ] := ( _tek_prom == "D" )
   ::hParams[ "varijanta" ] := _var_ab
   ::hParams[ "podklase" ] := ( _podklase == "D" )
   ::hParams[ "format" ] := _format
   ::hParams[ "txt" ] := ( _var_txt == "1" )
   ::hParams[ "pdf" ] := ( _var_txt == "3" )

   ::tip := _tip

   ::set_bb_params()

   _ok := .T.

   RETURN _ok



METHOD FinBrutoBilans:get_data()

   LOCAL cQuery, _data, _where
   LOCAL _konto := ::hParams[ "konto" ]
   LOCAL _dat_od := ::hParams[ "datum_od" ]
   LOCAL _dat_do := ::hParams[ "datum_do" ]
   LOCAL _id_rj := ::hParams[ "id_rj" ]
   LOCAL _iznos_dug := "iznosbhd"
   LOCAL _iznos_pot := "iznosbhd"
   LOCAL _table := f18_sql_schema( "fin_suban" )
   LOCAL _date_field := "sub.datdok"

   IF ::tip == 2

      _table := f18_sql_schema( "fin_anal" )
      _date_field := "sub.datnal"

      _iznos_dug := "dugbhd"
      _iznos_pot := "potbhd"

   ELSEIF ::tip > 2

      _table := f18_sql_schema( "fin_sint" )
      _date_field := "sub.datnal"

      _iznos_dug := "dugbhd"
      _iznos_pot := "potbhd"

   ENDIF

   // valuta 1 = domaca
   IF ::hParams[ "valuta" ] == 2

      _iznos_dug := "iznosdem"
      _iznos_pot := "iznosdem"

      IF ::tip > 1
         _iznos_dug := "dugdem"
         _iznos_pot := "potdem"
      ENDIF

   ENDIF

   _where := "WHERE sub.idfirma = " + _filter_quote( self_organizacija_id() )
   _where += " AND " + _sql_date_parse( _date_field, _dat_od, _dat_do )

   IF !Empty( _konto )
      _where += " AND " + _sql_cond_parse( "sub.idkonto", _konto + " " )
   ENDIF

   IF ::tip == 1
      IF !Empty( _id_rj ) .AND. _id_rj <> REPLICATE("9", FIELD_LEN_FIN_RJ_ID )
         _where += " AND sub.idrj = " + sql_quote( _id_rj )
      ENDIF
   ENDIF

   cQuery := "SELECT "

   IF ::tip == 1 .OR. ::tip == 2
      cQuery += "sub.idkonto, "
   ELSEIF ::tip == 3
      cQuery += " rpad( sub.idkonto, 3 ) AS idkonto, "
   ELSEIF ::tip == 4
      cQuery += " rpad( sub.idkonto, 2 ) AS idkonto, "
   ENDIF

   IF ::tip == 1

      cQuery += "sub.idpartner, "

      cQuery += "SUM( CASE WHEN sub.d_p = '1' AND sub.idvn = '00' THEN sub." + _iznos_dug + " END ) as ps_dug, "
      cQuery += "SUM( CASE WHEN sub.d_p = '2' AND sub.idvn = '00' THEN sub." + _iznos_pot + " END ) as ps_pot, "

      IF ::hParams[ "kolona_tek_prom" ]
         cQuery += "SUM( CASE WHEN sub.d_p = '1' AND sub.idvn <> '00' THEN sub." + _iznos_dug + " END ) as tek_dug, "
         cQuery += "SUM( CASE WHEN sub.d_p = '2' AND sub.idvn <> '00' THEN sub." + _iznos_pot + " END ) as tek_pot, "
      ENDIF

      cQuery += "SUM( CASE WHEN sub.d_p = '1' THEN sub." + _iznos_dug + " END ) as kum_dug, "
      cQuery += "SUM( CASE WHEN sub.d_p = '2' THEN sub." + _iznos_pot + " END ) as kum_pot "

   ELSEIF ::tip > 1

      cQuery += "SUM( CASE WHEN sub.idvn = '00' THEN sub." + _iznos_dug + " END ) as ps_dug, "
      cQuery += "SUM( CASE WHEN sub.idvn = '00' THEN sub." + _iznos_pot + " END ) as ps_pot, "

      IF ::hParams[ "kolona_tek_prom" ]
         cQuery += "SUM( CASE WHEN sub.idvn <> '00' THEN sub." + _iznos_dug + " END ) as tek_dug, "
         cQuery += "SUM( CASE WHEN sub.idvn <> '00' THEN sub." + _iznos_pot + " END ) as tek_pot, "
      ENDIF

      cQuery += "SUM( sub." + _iznos_dug + " ) as kum_dug, "
      cQuery += "SUM( sub." + _iznos_pot + " ) as kum_pot "

   ENDIF

   cQuery += "FROM " + _table + " sub "

   cQuery += _where + " "

   IF ::tip == 1
      cQuery += "GROUP BY sub.idkonto, sub.idpartner "
      cQuery += "ORDER BY sub.idkonto, sub.idpartner "
   ELSEIF ::tip == 2
      cQuery += "GROUP BY sub.idkonto "
      cQuery += "ORDER BY sub.idkonto "
   ELSEIF ::tip == 3
      cQuery += "GROUP BY rpad( sub.idkonto, 3 ) "
      cQuery += "ORDER BY rpad( sub.idkonto, 3 ) "
   ELSEIF ::tip == 4
      cQuery += "GROUP BY rpad( sub.idkonto, 2 ) "
      cQuery += "ORDER BY rpad( sub.idkonto, 2 ) "
   ENDIF

   MsgO( "formiranje sql upita u toku ..." )
   _data := run_sql_query( cQuery )
   MsgC()

   IF sql_error_in_query( _data )
      MsgBeep( "SQL ERROR !?" )
      RETURN NIL
   ENDIF

   ::DATA := _data

   RETURN SELF




METHOD FinBrutoBilans:set_txt_lines()

   LOCAL _arr := {}
   LOCAL _tmp
   LOCAL oRPT := ReportCommon():new()

   // r.br
   _tmp := 4
   AAdd( _arr, { _tmp, PadC( "R.", _tmp ), PadC( "br.", _tmp ), PadC( "", _tmp ) } )

   IF ::tip == 4
      // grupa konta
      _tmp := 7
      AAdd( _arr, { _tmp, PadC( "GRUPA", _tmp ), PadC( "KONTA", _tmp ), PadC( "", _tmp ) } )
   ELSE
      // konto
      _tmp := 7
      AAdd( _arr, { _tmp, PadC( "KONTO", _tmp ), PadC( "", _tmp ), PadC( "", _tmp ) } )
   ENDIF

   IF ::tip == 1
      // partner
      _tmp := 6
      AAdd( _arr, { _tmp, PadC( "PART-", _tmp ), PadC( "NER", _tmp ), PadC( "", _tmp ) } )
      // naziv konto/partner
      _tmp := 40
      AAdd( _arr, { _tmp, PadC( "NAZIV KONTA ILI PARTNERA", _tmp ), PadC( "", _tmp ), PadC( "", _tmp ) } )
   ELSEIF ::tip == 2
      // naziv konto/partner
      _tmp := 40
      AAdd( _arr, { _tmp, PadC( "NAZIV ANALITIČKOG KONTA", _tmp ), PadC( "", _tmp ), PadC( "", _tmp ) } )
   ELSEIF ::tip == 3
      // naziv konto/partner
      _tmp := 40
      AAdd( _arr, { _tmp, PadC( "NAZIV SINTETIČKOG KONTA", _tmp ), PadC( "", _tmp ), PadC( "", _tmp ) } )
   ENDIF

   // pocetno stanje
   _tmp := ( Len( ::pict_iznos ) * 2 ) + 1
   AAdd( _arr, { _tmp, PadC( "POČETNO STANJE", _tmp ), PadC( REPL( "-", _tmp ), _tmp ), PadC( "DUGUJE     POTRAŽUJE", _tmp ) } )

   IF ::hParams[ "kolona_tek_prom" ]
      // tekuci promet
      AAdd( _arr, { _tmp, PadC( "TEKUĆI PROMET", _tmp ), PadC( REPL( "-", _tmp ), _tmp ), PadC( "DUGUJE     POTRAŽUJE", _tmp ) } )
   ENDIF

   // kumulativni promet
   AAdd( _arr, { _tmp, PadC( "KUMULATIVNI PROMET", _tmp ), PadC( REPL( "-", _tmp ), _tmp ), PadC( "DUGUJE     POTRAŽUJE", _tmp ) } )

   // saldo
   AAdd( _arr, { _tmp, PadC( "SALDO", _tmp ), PadC( REPL( "-", _tmp ), _tmp ), PadC( "DUGUJE     POTRAŽUJE", _tmp ) } )

   oRPT:zagl_arr := _arr

   ::zagl := hb_Hash()
   ::zagl[ "line" ] := oRPT:get_zaglavlje( 0 )

   oRPT:zagl_delimiter := "*"

   ::zagl[ "txt1" ] := hb_UTF8ToStr( oRPT:get_zaglavlje( 1, "*" ) )
   ::zagl[ "txt2" ] := hb_UTF8ToStr( oRPT:get_zaglavlje( 2, "*" ) )
   ::zagl[ "txt3" ] := hb_UTF8ToStr( oRPT:get_zaglavlje( 3, "*" ) )

   RETURN SELF




METHOD FinBrutoBilans:zaglavlje_txt()

   Preduzece()

   P_COND2

   ?
   ? "FIN: " + hb_UTF8ToStr( ::hParams[ "naziv" ] ) + " U VALUTI " + if( ::hParams[ "valuta" ] == 1, valuta_domaca_skraceni_naziv(), ValPomocna() )
   ?? " ZA PERIOD OD", ::hParams[ "datum_od" ], "-", ::hParams[ "datum_do" ]
   ?? " NA DAN: "
   ?? Date()
   ?? " (v.A)"

   @ PRow(), 100 SAY "Str:" + Str( ++::broj_stranice, 3 )

   ? ::zagl[ "line" ]
   ? ::zagl[ "txt1" ]
   ? ::zagl[ "txt2" ]
   ? ::zagl[ "txt3" ]
   ? ::zagl[ "line" ]

   RETURN SELF




METHOD FinBrutoBilans:gen_xml()

   LOCAL _xml := "data.xml"
   LOCAL _sint_len := 3
   LOCAL _kl_len := 1
   LOCAL _a_klase := {}
   LOCAL _klasa, nI, nCount
   LOCAL _u_ps_dug := _u_ps_pot := _u_kum_dug := _u_kum_pot := _u_tek_dug := _u_tek_pot := _u_sld_dug := _u_sld_pot := 0
   LOCAL _t_ps_dug := _t_ps_pot := _t_kum_dug := _t_kum_pot := _t_tek_dug := _t_tek_pot := _t_sld_dug := _t_sld_pot := 0
   LOCAL _tt_ps_dug := _tt_ps_pot := _tt_kum_dug := _tt_kum_pot := _tt_tek_dug := _tt_tek_pot := _tt_sld_dug := _tt_sld_pot := 0
   LOCAL _ok := .F.

   IF ::tip == 4
      _sint_len := 2
   ENDIF

   create_xml( my_home() + _xml )

   xml_subnode( "rpt", .F. )

   xml_subnode( "bilans", .F. )

   // header podaci
   xml_node( "firma", to_xml_encoding( self_organizacija_id() ) )
   xml_node( "naz", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "datum", DToC( Date() ) )
   xml_node( "datum_od", DToC( ::hParams[ "datum_od" ] ) )
   xml_node( "datum_do", DToC( ::hParams[ "datum_do" ] ) )

   IF !Empty( ::hParams[ "konto" ] )
      xml_node( "konto", to_xml_encoding( ::hParams[ "konto" ] ) )
   ELSE
      xml_node( "konto", to_xml_encoding( "- sva konta -" ) )
   ENDIF

   o_r_export()
   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   nCount := 0

   DO WHILE !Eof()

      __konto := _set_sql_record_to_hash( f18_sql_schema( "konto" ), field->idkonto )

      _klasa := Left( field->idkonto, _kl_len )

      xml_subnode( "klasa", .F. )

      xml_node( "id", to_xml_encoding( _klasa ) )

      IF __konto == NIL
         xml_node( "naz", AllTrim( field->idkonto ) + to_xml_encoding( hb_UTF8ToStr( " - Nepostojeći konto !" ) ) )
      ELSE
         xml_node( "naz", to_xml_encoding( AllTrim( __konto[ "naz" ] ) ) )
      ENDIF

      _t_ps_dug := _t_ps_pot := _t_kum_dug := _t_kum_pot := _t_tek_dug := _t_tek_pot := _t_sld_dug := _t_sld_pot := 0

      DO WHILE !Eof() .AND. Left( field->idkonto, _kl_len ) == _klasa

         _sint := Left( field->idkonto, _sint_len )
         __konto := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "konto", _sint )

         xml_subnode( "sint", .F. )

         xml_node( "id", to_xml_encoding( _sint ) )

         IF __konto == NIL
            xml_node( "naz", AllTrim( field->idkonto ) + to_xml_encoding( hb_UTF8ToStr( " - Nepostojeći konto !" ) ) )
         ELSE
            xml_node( "naz", to_xml_encoding( AllTrim( __konto[ "naz" ] ) ) )
         ENDIF

         _u_ps_dug := _u_ps_pot := _u_kum_dug := _u_kum_pot := _u_tek_dug := _u_tek_pot := _u_sld_dug := _u_sld_pot := 0

         DO WHILE !Eof() .AND. Left( field->idkonto, _sint_len ) == _sint

            xml_subnode( "item", .F. )

            xml_node( "rb", AllTrim( Str( ++nCount ) ) )
            xml_node( "kto", to_xml_encoding( field->idkonto ) )

            IF ::tip == 1

               xml_node( "part", to_xml_encoding( field->idpartner ) )

               IF !Empty( field->partner )
                  xml_node( "naz", to_xml_encoding( field->partner ) )
               ELSE
                  xml_node( "naz", to_xml_encoding( field->konto ) )
               ENDIF

            ELSEIF ::tip == 2 .OR. ::tip == 3

               xml_node( "part", "" )
               xml_node( "naz", to_xml_encoding( field->konto ) )

            ELSE

               xml_node( "part", "" )
               xml_node( "naz", "" )

            ENDIF

            xml_node( "ps_dug", AllTrim( Str( field->ps_dug, 12, 2 ) ) )
            xml_node( "ps_pot", AllTrim( Str( field->ps_pot, 12, 2 ) ) )

            xml_node( "tek_dug", AllTrim( Str( field->tek_dug, 12, 2 ) ) )
            xml_node( "tek_pot", AllTrim( Str( field->tek_pot, 12, 2 ) ) )

            xml_node( "kum_dug", AllTrim( Str( field->kum_dug, 12, 2 ) ) )
            xml_node( "kum_pot", AllTrim( Str( field->kum_pot, 12, 2 ) ) )

            xml_node( "sld_dug", AllTrim( Str( field->sld_dug, 12, 2 ) ) )
            xml_node( "sld_pot", AllTrim( Str( field->sld_pot, 12, 2 ) ) )

            _u_ps_dug += field->ps_dug
            _u_ps_pot += field->ps_pot
            _u_tek_dug += field->tek_dug
            _u_tek_pot += field->tek_pot
            _u_kum_dug += field->kum_dug
            _u_kum_pot += field->kum_pot
            _u_sld_dug += field->sld_dug
            _u_sld_pot += field->sld_pot

            _t_ps_dug += field->ps_dug
            _t_ps_pot += field->ps_pot
            _t_tek_dug += field->tek_dug
            _t_tek_pot += field->tek_pot
            _t_kum_dug += field->kum_dug
            _t_kum_pot += field->kum_pot
            _t_sld_dug += field->sld_dug
            _t_sld_pot += field->sld_pot

            _tt_ps_dug += field->ps_dug
            _tt_ps_pot += field->ps_pot
            _tt_tek_dug += field->tek_dug
            _tt_tek_pot += field->tek_pot
            _tt_kum_dug += field->kum_dug
            _tt_kum_pot += field->kum_pot
            _tt_sld_dug += field->sld_dug
            _tt_sld_pot += field->sld_pot

            _scan := AScan( _a_klase, {| VAR | VAR[ 1 ] == Left( _sint, 1 ) } )

            IF _scan == 0
               AAdd( _a_klase, { Left( _sint, 1 ), ;
                  field->ps_dug, ;
                  field->ps_pot, ;
                  field->tek_dug, ;
                  field->tek_pot, ;
                  field->kum_dug, ;
                  field->kum_pot, ;
                  field->sld_dug, ;
                  field->sld_pot } )
            ELSE

               _a_klase[ _scan, 2 ] := _a_klase[ _scan, 2 ] + field->ps_dug
               _a_klase[ _scan, 3 ] := _a_klase[ _scan, 3 ] + field->ps_pot
               _a_klase[ _scan, 4 ] := _a_klase[ _scan, 4 ] + field->tek_dug
               _a_klase[ _scan, 5 ] := _a_klase[ _scan, 5 ] + field->tek_pot
               _a_klase[ _scan, 6 ] := _a_klase[ _scan, 6 ] + field->kum_dug
               _a_klase[ _scan, 7 ] := _a_klase[ _scan, 7 ] + field->kum_pot
               _a_klase[ _scan, 8 ] := _a_klase[ _scan, 8 ] + field->sld_dug
               _a_klase[ _scan, 9 ] := _a_klase[ _scan, 9 ] + field->sld_pot

            ENDIF

            xml_subnode( "item", .T. )

            SKIP

         ENDDO

         IF ::tip < 3
            xml_node( "ps_dug", AllTrim( Str( _u_ps_dug, 12, 2 ) ) )
            xml_node( "ps_pot", AllTrim( Str( _u_ps_pot, 12, 2 ) ) )
            xml_node( "kum_dug", AllTrim( Str( _u_kum_dug, 12, 2 ) ) )
            xml_node( "kum_pot", AllTrim( Str( _u_kum_pot, 12, 2 ) ) )
            xml_node( "tek_dug", AllTrim( Str( _u_tek_dug, 12, 2 ) ) )
            xml_node( "tek_pot", AllTrim( Str( _u_tek_pot, 12, 2 ) ) )
            xml_node( "sld_dug", AllTrim( Str( _u_sld_dug, 12, 2 ) ) )
            xml_node( "sld_pot", AllTrim( Str( _u_sld_pot, 12, 2 ) ) )

         ENDIF

         xml_subnode( "sint", .T. )

      ENDDO

      xml_node( "ps_dug", AllTrim( Str( _t_ps_dug, 12, 2 ) ) )
      xml_node( "ps_pot", AllTrim( Str( _t_ps_pot, 12, 2 ) ) )
      xml_node( "kum_dug", AllTrim( Str( _t_kum_dug, 12, 2 ) ) )
      xml_node( "kum_pot", AllTrim( Str( _t_kum_pot, 12, 2 ) ) )
      xml_node( "tek_dug", AllTrim( Str( _t_tek_dug, 12, 2 ) ) )
      xml_node( "tek_pot", AllTrim( Str( _t_tek_pot, 12, 2 ) ) )
      xml_node( "sld_dug", AllTrim( Str( _t_sld_dug, 12, 2 ) ) )
      xml_node( "sld_pot", AllTrim( Str( _t_sld_pot, 12, 2 ) ) )

      xml_subnode( "klasa", .T. )

   ENDDO

   xml_node( "ps_dug", AllTrim( Str( _tt_ps_dug, 12, 2 ) ) )
   xml_node( "ps_pot", AllTrim( Str( _tt_ps_pot, 12, 2 ) ) )
   xml_node( "kum_dug", AllTrim( Str( _tt_kum_dug, 12, 2 ) ) )
   xml_node( "kum_pot", AllTrim( Str( _tt_kum_pot, 12, 2 ) ) )
   xml_node( "tek_dug", AllTrim( Str( _tt_tek_dug, 12, 2 ) ) )
   xml_node( "tek_pot", AllTrim( Str( _tt_tek_pot, 12, 2 ) ) )
   xml_node( "sld_dug", AllTrim( Str( _tt_sld_dug, 12, 2 ) ) )
   xml_node( "sld_pot", AllTrim( Str( _tt_sld_pot, 12, 2 ) ) )
   xml_subnode( "total", .F. )

   FOR nI := 1 TO Len( _a_klase )

      xml_subnode( "item", .F. )

      xml_node( "klasa", to_xml_encoding( _a_klase[ nI, 1 ] ) )
      xml_node( "ps_dug", AllTrim( Str( _a_klase[ nI, 2 ], 12, 2 ) ) )
      xml_node( "ps_pot", AllTrim( Str( _a_klase[ nI, 3 ], 12, 2 ) ) )
      xml_node( "tek_dug", AllTrim( Str( _a_klase[ nI, 4 ], 12, 2 ) ) )
      xml_node( "tek_pot", AllTrim( Str( _a_klase[ nI, 5 ], 12, 2 ) ) )
      xml_node( "kum_dug", AllTrim( Str( _a_klase[ nI, 6 ], 12, 2 ) ) )
      xml_node( "kum_pot", AllTrim( Str( _a_klase[ nI, 7 ], 12, 2 ) ) )
      xml_node( "sld_dug", AllTrim( Str( _a_klase[ nI, 8 ], 12, 2 ) ) )
      xml_node( "sld_pot", AllTrim( Str( _a_klase[ nI, 9 ], 12, 2 ) ) )

      xml_subnode( "item", .T. )

   NEXT

   xml_subnode( "total", .T. )
   xml_subnode( "bilans", .T. )
   xml_subnode( "rpt", .T. )
   close_xml()

   my_close_all_dbf()

   _ok := .T.

   RETURN _ok




METHOD FinBrutoBilans:print()

   IF Empty( ::hParams[ "konto" ] )
      IF !::get_vars()
         RETURN SELF
      ENDIF
   ENDIF

   IF ::hParams[ "varijanta" ] == "B"
      ::print_b_rpt()
      RETURN SELF
   ENDIF

   ::get_data()

   IF ::DATA == NIL
      RETURN SELF
   ENDIF

   ::create_r_export()
   ::fill_r_export()

   IF ::hParams[ "export_dbf" ]
      open_r_export_table()
      RETURN SELF
   ENDIF

   IF ::hParams[ "txt" ]
      ::print_txt()
   ELSE
      ::print_odt()
   ENDIF

   RETURN SELF


METHOD FinBrutoBilans:print_odt()

   LOCAL _template := "fin_bbl.odt"

   IF ::gen_xml()
      IF generisi_odt_iz_xml( _template )
         prikazi_odt()
      ENDIF
   ENDIF

   RETURN SELF



METHOD FinBrutoBilans:print_txt()

   LOCAL _line, _i_col
   LOCAL _a_klase := {}
   LOCAL _klasa, nI, nCount, _sint, _id_konto, _id_partner, __partn, __klasa, __sint, __konto
   LOCAL _u_ps_dug := _u_ps_pot := _u_kum_dug := _u_kum_pot := _u_tek_dug := _u_tek_pot := _u_sld_dug := _u_sld_pot := 0
   LOCAL _t_ps_dug := _t_ps_pot := _t_kum_dug := _t_kum_pot := _t_tek_dug := _t_tek_pot := _t_sld_dug := _t_sld_pot := 0
   LOCAL _tt_ps_dug := _tt_ps_pot := _tt_kum_dug := _tt_kum_pot := _tt_tek_dug := _tt_tek_pot := _tt_sld_dug := _tt_sld_pot := 0
   LOCAL _rbr := 0
   LOCAL _rbr_2 := 0
   LOCAL _rbr_3 := 0
   LOCAL _kl_len := 1
   LOCAL _sint_len := 3

   IF ::tip == 4
      // po grupama
      _sint_len := 2
   ENDIF

   // setuj zaglavlje i linije...
   ::set_txt_lines()

   _line := ::zagl[ "line" ]

   IF !start_print()
      RETURN .F.
   ENDIF

   ::zaglavlje_txt()

   o_r_export()
   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      _t_ps_dug := _t_ps_pot := _t_kum_dug := _t_kum_pot := _t_tek_dug := _t_tek_pot := _t_sld_dug := _t_sld_pot := 0

      _klasa := Left( field->idkonto, _kl_len )
      __klasa := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "konto", _klasa )

      DO WHILE !Eof() .AND. Left( field->idkonto, _kl_len ) == _klasa

         _u_ps_dug := _u_ps_pot := _u_kum_pot := _u_kum_dug := _u_tek_dug := _u_tek_pot := _u_sld_dug := _u_sld_pot := 0

         _sint := Left( field->idkonto, _sint_len )
         __sint := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "konto", _sint )

         DO WHILE !Eof() .AND. Left( field->idkonto, _sint_len ) == _sint

            IF !::hParams[ "saldo_nula" ] .AND. Round( field->kum_dug - field->kum_pot, 2 ) == 0
               SKIP
               LOOP
            ENDIF

            IF PRow() > ::txt_rpt_len
               FF
               ::zaglavlje_txt()
            ENDIF

            @ PRow() + 1, 0 SAY + + _rbr PICT "9999"
            @ PRow(), PCol() + 1 SAY field->idkonto

            IF ::tip < 4

               __konto := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "konto", field->idkonto )

               IF ::tip == 1
                  @ PRow(), PCol() + 1 SAY field->idpartner
                  __partn := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "partn", field->idpartner )
                  // ovdje mogu biti šifre koje nemaju partnera a da u sifarniku nemamo praznog zapisa
                  // znači __partn može biti NIL
               ENDIF

               IF ::tip == 1 .AND. !Empty( field->idpartner )
                  IF __partn <> NIL
                     _opis := __partn[ "naz" ]
                  ELSE
                     _opis := "Nema partnera " + field->idpartner + " !"
                  ENDIF
               ELSE
                  _opis := ""
               ENDIF

               // ako nema partnera kao opis će se koristiti naziv konta
               IF Empty( _opis )
                  IF __konto <> NIL
                     _opis := __konto[ "naz" ]
                  ELSE
                     _opis := AllTrim( field->idkonto ) + " - " + hb_UTF8ToStr( "nepostojeći konto - ERR" )
                  ENDIF
               ENDIF

               @ PRow(), PCol() + 1 SAY PadR( _opis, 40 )

            ENDIF

            _i_col := PCol() + 1

            @ PRow(), PCol() + 1 SAY field->ps_dug PICT ::pict_iznos
            @ PRow(), PCol() + 1 SAY field->ps_pot PICT ::pict_iznos

            IF ::hParams[ "kolona_tek_prom" ]
               @ PRow(), PCol() + 1 SAY field->tek_dug PICT ::pict_iznos
               @ PRow(), PCol() + 1 SAY field->tek_pot PICT ::pict_iznos
            ENDIF

            @ PRow(), PCol() + 1 SAY field->kum_dug PICT ::pict_iznos
            @ PRow(), PCol() + 1 SAY field->kum_pot PICT ::pict_iznos

            @ PRow(), PCol() + 1 SAY field->sld_dug PICT ::pict_iznos
            @ PRow(), PCol() + 1 SAY field->sld_pot PICT ::pict_iznos

            // totali sintetički...
            _u_ps_dug += field->ps_dug
            _u_ps_pot += field->ps_pot
            _u_kum_dug += field->kum_dug
            _u_kum_pot += field->kum_pot
            _u_tek_dug += field->tek_dug
            _u_tek_pot += field->tek_pot
            _u_sld_dug += field->sld_dug
            _u_sld_pot += field->sld_pot

            // totali po klasama
            _t_ps_dug += field->ps_dug
            _t_ps_pot += field->ps_pot
            _t_kum_dug += field->kum_dug
            _t_kum_pot += field->kum_pot
            _t_tek_dug += field->tek_dug
            _t_tek_pot += field->tek_pot
            _t_sld_dug += field->sld_dug
            _t_sld_pot += field->sld_pot

            // total ukupno
            _tt_ps_dug += field->ps_dug
            _tt_ps_pot += field->ps_pot
            _tt_kum_dug += field->kum_dug
            _tt_kum_pot += field->kum_pot
            _tt_tek_dug += field->tek_dug
            _tt_tek_pot += field->tek_pot
            _tt_sld_dug += field->sld_dug
            _tt_sld_pot += field->sld_pot

            // dodaj u matricu sa klasama, takodjer totale...
            _scan := AScan( _a_klase, {| VAR | VAR[ 1 ] == Left( _sint, 1 ) } )

            IF _scan == 0
               // dodaj novu stavku u matricu...
               AAdd( _a_klase, { Left( _sint, 1 ), ;
                  field->ps_dug, ;
                  field->ps_pot, ;
                  field->tek_dug, ;
                  field->tek_pot, ;
                  field->kum_dug, ;
                  field->kum_pot, ;
                  field->sld_dug, ;
                  field->sld_pot } )
            ELSE

               // dodaj na postojeci iznos...

               _a_klase[ _scan, 2 ] := _a_klase[ _scan, 2 ] + field->ps_dug
               _a_klase[ _scan, 3 ] := _a_klase[ _scan, 3 ] + field->ps_pot
               _a_klase[ _scan, 4 ] := _a_klase[ _scan, 4 ] + field->tek_dug
               _a_klase[ _scan, 5 ] := _a_klase[ _scan, 5 ] + field->tek_pot
               _a_klase[ _scan, 6 ] := _a_klase[ _scan, 6 ] + field->kum_dug
               _a_klase[ _scan, 7 ] := _a_klase[ _scan, 7 ] + field->kum_pot
               _a_klase[ _scan, 8 ] := _a_klase[ _scan, 8 ] + field->sld_dug
               _a_klase[ _scan, 9 ] := _a_klase[ _scan, 9 ] + field->sld_pot

            ENDIF

            SKIP

         ENDDO

         IF ::tip < 3

            // nova stranica i zaglavlje...
            IF PRow() + 3 > ::txt_rpt_len
               FF
               ::zaglavlje_txt()
            ENDIF

            // ispisi sintetiku....
            ? _line

            @ PRow() + 1, 2 SAY + + _rbr_2 PICT "9999"
            @ PRow(), PCol() + 1 SAY _sint

            IF __sint == NIL
               @ PRow(), PCol() + 1 SAY PadR( "Sintetika " + _sint, 40 )
            ELSE
               @ PRow(), PCol() + 1 SAY PadR( __sint[ "naz" ], 40 )
            ENDIF

            @ PRow(), _i_col SAY _u_ps_dug PICT ::pict_iznos
            @ PRow(), PCol() + 1 SAY _u_ps_pot PICT ::pict_iznos

            IF ::hParams[ "kolona_tek_prom" ]
               @ PRow(), PCol() + 1 SAY _u_tek_dug PICT ::pict_iznos
               @ PRow(), PCol() + 1 SAY _u_tek_pot PICT ::pict_iznos
            ENDIF

            @ PRow(), PCol() + 1 SAY _u_kum_dug PICT ::pict_iznos
            @ PRow(), PCol() + 1 SAY _u_kum_pot PICT ::pict_iznos

            @ PRow(), PCol() + 1 SAY _u_sld_dug PICT ::pict_iznos
            @ PRow(), PCol() + 1 SAY _u_sld_pot PICT ::pict_iznos

            ? _line

         ENDIF

      ENDDO

      // nova stranica i zaglavlje...
      IF PRow() + 3 > ::txt_rpt_len
         FF
         ::zaglavlje_txt()
      ENDIF

      // ispisi klasu
      ? _line

      @ PRow() + 1, 2 SAY + + _rbr_3 PICT "9999"
      @ PRow(), PCol() + 1 SAY _klasa

      IF ::tip < 3
         IF __klasa == NIL
            @ PRow(), PCol() + 1 SAY PadR( "Klasa " + _klasa, 40 )
         ELSE
            @ PRow(), PCol() + 1 SAY PadR( __klasa[ "naz" ], 40 )
         ENDIF
      ENDIF

      @ PRow(), _i_col SAY _t_ps_dug PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY _t_ps_pot PICT ::pict_iznos

      IF ::hParams[ "kolona_tek_prom" ]
         @ PRow(), PCol() + 1 SAY _t_tek_dug PICT ::pict_iznos
         @ PRow(), PCol() + 1 SAY _t_tek_pot PICT ::pict_iznos
      ENDIF

      @ PRow(), PCol() + 1 SAY _t_kum_dug PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY _t_kum_pot PICT ::pict_iznos

      @ PRow(), PCol() + 1 SAY _t_sld_dug PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY _t_sld_pot PICT ::pict_iznos

      ? _line

   ENDDO

   ::klase := _a_klase

   // nova stranica i zaglavlje...
   IF PRow() + 3 > ::txt_rpt_len
      FF
      ::zaglavlje_txt()
   ENDIF

   ? _line
   ? "UKUPNO"
   @ PRow(), _i_col SAY _tt_ps_dug PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _tt_ps_pot PICT ::pict_iznos

   IF ::hParams[ "kolona_tek_prom" ]
      @ PRow(), PCol() + 1 SAY _tt_tek_dug PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY _tt_tek_pot PICT ::pict_iznos
   ENDIF

   @ PRow(), PCol() + 1 SAY _tt_kum_dug PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _tt_kum_pot PICT ::pict_iznos

   @ PRow(), PCol() + 1 SAY _tt_sld_dug PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _tt_sld_pot PICT ::pict_iznos
   ? _line

   ::rekapitulacija_klasa()

   FF
   end_print()

   my_close_all_dbf()

   RETURN SELF




// -----------------------------------------------------------
// -----------------------------------------------------------
METHOD FinBrutoBilans:rekapitulacija_klasa()

   LOCAL _line
   LOCAL _kl_ps_dug := _kl_ps_pot := _kl_tek_dug := _kl_tek_pot := _kl_sld_dug := _kl_sld_pot := 0
   LOCAL _kl_kum_dug := _kl_kum_pot := 0

   // nova stranica i zaglavlje...
   IF PRow() + Len( ::klase ) + 10 > ::txt_rpt_len
      FF
      ::zaglavlje_txt()
   ENDIF

   ?
   ? "REKAPITULACIJA PO KLASAMA NA DAN: "
   ?? Date()
   ? _line := "--------- --------------- --------------- --------------- --------------- --------------- ---------------"
   ? hb_UTF8ToStr( "*        *          POČETNO STANJE       *        KUMULATIVNI PROMET     *            SALDO             *" )
   ? "  KLASA   ------------------------------- ------------------------------- -------------------------------"
   ? hb_UTF8ToStr( "*        *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *     DUGUJE    *    POTRAŽUJE *" )
   ? _line

   FOR nI := 1 TO Len( ::klase )

      @ PRow() + 1, 4 SAY ::klase[ nI, 1 ]

      // ps dug / ps pot
      @ PRow(), 10 SAY ::klase[ nI, 2 ] PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY ::klase[ nI, 3 ] PICT ::pict_iznos

      // kum dug / tek pot
      @ PRow(), PCol() + 1 SAY ::klase[ nI, 6 ] PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY ::klase[ nI, 7 ] PICT ::pict_iznos

      // sld dug / sld pot
      @ PRow(), PCol() + 1 SAY ::klase[ nI, 8 ] PICT ::pict_iznos
      @ PRow(), PCol() + 1 SAY ::klase[ nI, 9 ] PICT ::pict_iznos

      _kl_ps_dug += ::klase[ nI, 2 ]
      _kl_ps_pot += ::klase[ nI, 3 ]

      _kl_kum_dug += ::klase[ nI, 6 ]
      _kl_kum_pot += ::klase[ nI, 7 ]

      _kl_sld_dug += ::klase[ nI, 8 ]
      _kl_sld_pot += ::klase[ nI, 9 ]

   NEXT

   ? _line
   ? "UKUPNO:"
   @ PRow(), 10 SAY _kl_ps_dug PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _kl_ps_pot PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _kl_kum_dug PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _kl_kum_pot PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _kl_sld_dug PICT ::pict_iznos
   @ PRow(), PCol() + 1 SAY _kl_sld_pot PICT ::pict_iznos
   ? _line

   RETURN SELF



METHOD FinBrutoBilans:fill_r_export()

   LOCAL nCount := 0
   LOCAL oRow, hRec
   LOCAL __konto, __partn
   LOCAL _id_konto, _id_partn

   o_r_export()
   SET ORDER TO TAG "1"

   ::data:goTo( 1 )

   MsgO( "Formiranje tabele r_export ..." )

   DO WHILE !::data:Eof()

      oRow := ::data:GetRow()

      _id_konto := query_row( oRow, "idkonto" )
      __konto := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "konto", _id_konto )

      IF ::tip == 1
         _id_partn := query_row( oRow, "idpartner" )
         __partn := _set_sql_record_to_hash( F18_PSQL_SCHEMA_DOT + "partn", _id_partn )
      ENDIF

      SELECT r_export
      APPEND BLANK
      hRec := dbf_get_rec()

      IF __konto <> NIL .AND. !Empty( __konto[ "naz" ] )
         hRec[ "konto" ] := PadR( __konto[ "naz" ], 60 )
      ELSE
         hRec[ "konto" ] := "?????????????"
      ENDIF

      hRec[ "idkonto" ] := _id_konto

      IF ::tip == 1
         hRec[ "idpartner" ] := _id_partn
         IF !Empty( _id_partn ) .AND. __partn <> NIL
            hRec[ "partner" ] := PadR( __partn[ "naz" ], 100 )
         ELSE
            hRec[ "partner" ] := ""
         ENDIF
      ENDIF

      hRec[ "ps_dug" ] := query_row( oRow, "ps_dug" )
      hRec[ "ps_pot" ] := query_row( oRow, "ps_pot" )

      IF ::hParams[ "kolona_tek_prom" ]
         hRec[ "tek_dug" ] := query_row( oRow, "tek_dug" )
         hRec[ "tek_pot" ] := query_row( oRow, "tek_pot" )
      ELSE
         hRec[ "tek_dug" ] := 0
         hRec[ "tek_pot" ] := 0
      ENDIF

      hRec[ "kum_dug" ] := query_row( oRow, "kum_dug" )
      hRec[ "kum_pot" ] := query_row( oRow, "kum_pot" )

      hRec[ "sld_dug" ] := hRec[ "kum_dug" ] - hRec[ "kum_pot" ]

      IF hRec[ "sld_dug" ] >= 0
         hRec[ "sld_pot" ] := 0
      ELSE
         hRec[ "sld_pot" ] := - hRec[ "sld_dug" ]
         hRec[ "sld_dug" ] := 0
      ENDIF

      ++nCount

      dbf_update_rec( hRec )

      ::data:SKIP()

   ENDDO

   MsgC()

   my_close_all_dbf()

   RETURN nCount




METHOD FinBrutoBilans:create_r_export()

   LOCAL _dbf := {}

   AAdd( _dbf, { "idkonto", "C", 7, 0 } )
   AAdd( _dbf, { "konto", "C", 60, 0 } )

   IF ::tip == 1
      AAdd( _dbf, { "idpartner", "C", 6, 0 } )
      AAdd( _dbf, { "partner", "C", 100, 0 } )
   ENDIF

   AAdd( _dbf, { "ps_dug", "N", 18, 2 } )
   AAdd( _dbf, { "ps_pot", "N", 18, 2 } )

   AAdd( _dbf, { "tek_dug", "N", 18, 2 } )
   AAdd( _dbf, { "tek_pot", "N", 18, 2 } )

   AAdd( _dbf, { "kum_dug", "N", 18, 2 } )
   AAdd( _dbf, { "kum_pot", "N", 18, 2 } )

   AAdd( _dbf, { "sld_dug", "N", 18, 2 } )
   AAdd( _dbf, { "sld_pot", "N", 18, 2 } )

   IF !create_dbf_r_export( _dbf )
      RETURN .F.
   ENDIF

   o_r_export()

   IF ::tip == 1
      INDEX ON ( idkonto + idpartner ) TAG "1"
   ELSE
      INDEX ON ( idkonto ) TAG "1"
   ENDIF

   RETURN SELF
