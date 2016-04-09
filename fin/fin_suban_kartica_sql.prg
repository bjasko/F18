/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC LEN_VRIJEDNOST := 12
STATIC PIC_VRIJEDNOST := ""
STATIC _template
STATIC _my_xml


FUNCTION fin_suban_kartica_sql( otv_stavke )

   LOCAL _rpt_data := {}
   LOCAL _rpt_vars := hb_Hash()
   LOCAL _exported := .F.

   _my_xml := my_home() + "data.xml"
   _template := "fin_kart_brza.odt"

   IF otv_stavke == NIL
      otv_stavke := .F.
   ENDIF

   IF !_get_vars( @_rpt_vars )
      RETURN .F.
   ENDIF

   _rpt_data := _cre_rpt( _rpt_vars, otv_stavke )

   IF _rpt_data == NIL
      Msgbeep( "Problem sa generisanjem izvještaja !" )
      RETURN .F.
   ENDIF

   IF _rpt_vars[ "export_dbf" ] == "D"
      IF _export_dbf( _rpt_data, _rpt_vars )
         _exported := .T.
      ENDIF
   ENDIF

   IF _cre_xml( _rpt_data, _rpt_vars )

      IF _rpt_vars[ "brza" ] == "N"
         _template := "fin_kart_svi.odt"
      ENDIF

      IF generisi_odt_iz_xml( _template, _my_xml )
         prikazi_odt()
      ENDIF

   ENDIF

   IF _exported
      my_close_all_dbf()
      f18_open_mime_document( my_home() + "r_export.dbf" )
   ENDIF

   RETURN .T.


STATIC FUNCTION _get_vars( rpt_vars )

   LOCAL _brza := fetch_metric( "fin_kart_brza", my_user(), "D" )
   LOCAL _konto := fetch_metric( "fin_kart_konto", my_user(), "" )
   LOCAL _partner := fetch_metric( "fin_kart_partner", my_user(), "" )
   LOCAL _brdok := fetch_metric( "fin_kart_broj_dokumenta", my_user(), PadR( "", 200 ) )
   LOCAL _idvn := fetch_metric( "fin_kart_broj_dokumenta", my_user(), PadR( "", 200 ) )
   LOCAL _datum_od := fetch_metric( "fin_kart_datum_od", my_user(), CToD( "" ) )
   LOCAL _datum_do := fetch_metric( "fin_kart_datum_do", my_user(), CToD( "" ) )
   LOCAL _opcina := fetch_metric( "fin_kart_opcina", my_user(), PadR( "", 200 ) )
   LOCAL _tip_val := fetch_metric( "fin_kart_tip_valute", my_user(), 1 )
   LOCAL _export_dbf := fetch_metric( "fin_kart_export_dbf", my_user(), "N" )
   LOCAL _nula := fetch_metric( "fin_kart_saldo_nula", my_user(), "D" )
   LOCAL _box_name := "SUBANALITIČKA KARTICA (LO)"
   LOCAL _box_x := 21
   LOCAL _box_y := 65
   LOCAL _x := 1

   O_SIFK
   O_SIFV
   O_KONTO
   O_PARTN

   Box( "#" + _box_name, _box_x, _box_y )

   SET CURSOR ON

   ++ _x
   @ m_x + _x, m_y + 2 SAY "Brza kartica (D/N)" GET _brza PICT "@!" VALID _brza $ "DN"
   READ

   ++ _x
   ++ _x
   @ m_x + _x, m_y + 2 SAY "Firma "
   ?? gFirma, "-", AllTrim( gNFirma )

   ++ _x
   ++ _x
   IF _brza = "D"

      _konto := PadR( _konto, 7 )
      _partner := PadR( _partner, Len( partn->id ) )

      @ m_x + _x, m_y + 2 SAY "Konto   " GET _konto VALID !Empty( _konto ) .AND. P_KontoFin( @_konto )
      ++ _x
      @ m_x + _x, m_y + 2 SAY "Partner " GET _partner VALID Empty( _partner ) .OR. ;
         RTrim( _partner ) == ";" .OR. P_Firma( @_partner ) PICT "@!"

   ELSE

      _konto := PadR( _konto, 200 )
      _partner := PadR( _partner, 200 )

      @ m_x + _x, m_y + 2 SAY "Konto   " GET _konto PICT "@!S50"
      ++ _x
      @ m_x + _x, m_y + 2 SAY "Partner " GET _partner PICT "@!S50"

   ENDIF

   ++ _x
   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Kartica za domaću/stranu valutu (1/2):" GET _tip_val PICT "9"

   ++ _x
   ++ _x
   @ m_x + _x, m_y + 2 SAY "Datum dokumenta od:" GET _datum_od
   @ m_x + _x, Col() + 2 SAY "do" GET _datum_do VALID _datum_od <= _datum_do

   ++ _x
   ++ _x
   @ m_x + _x, m_y + 2 SAY "Uslov za vrstu naloga (prazno-sve):" GET _idvn PICT "@!S20"

   ++ _x
   @ m_x + _x, m_y + 2 SAY "Uslov za broj veze (prazno-svi):" GET _brdok PICT "@!S20"

   ++ _x
   @ m_x + _x, m_y + 2 SAY8 "Općina (prazno-sve):" GET _opcina PICT "@!S20"

   ++ _x
   ++ _x
   @ m_x + _x, m_y + 2 SAY "Prikaz kartica sa saldom nula (D/N)?" GET _nula VALID _nula $ "DN" PICT "@!"

   ++ _x
   ++ _x
   @ m_x + _x, m_y + 2 SAY "Eksport kartice u DBF (D/N)?" GET _export_dbf PICT "@!" VALID _export_dbf $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fin_kart_brza", my_user(), _brza )
   set_metric( "fin_kart_konto", my_user(), _konto )
   set_metric( "fin_kart_partner", my_user(), _partner )
   set_metric( "fin_kart_broj_dokumenta", my_user(), _brdok )
   set_metric( "fin_kart_broj_dokumenta", my_user(), _idvn )
   set_metric( "fin_kart_datum_od", my_user(), _datum_od )
   set_metric( "fin_kart_datum_do", my_user(), _datum_do )
   set_metric( "fin_kart_tip_valute", my_user(), _tip_val )
   set_metric( "fin_kart_export_dbf", my_user(), _export_dbf )
   set_metric( "fin_kart_saldo_nula", my_user(), _nula )

   rpt_vars[ "brza" ] := _brza
   rpt_vars[ "konto" ] := _konto
   rpt_vars[ "partner" ] := _partner
   rpt_vars[ "brdok" ] := _brdok
   rpt_vars[ "idvn" ] := _idvn
   rpt_vars[ "datum_od" ] := _datum_od
   rpt_vars[ "datum_do" ] := _datum_do
   rpt_vars[ "opcina" ] := _opcina
   rpt_vars[ "valuta" ] := _tip_val
   rpt_vars[ "export_dbf" ] := _export_dbf
   rpt_vars[ "saldo_nula" ] := _nula

   RETURN .T.


STATIC FUNCTION _cre_rpt( rpt_vars, otv_stavke )

   LOCAL _brza, _konto, _partner, _brdok, _idvn, _opcina
   LOCAL _datum_od, _datum_do, _tip_valute, _saldo_nula
   LOCAL _qry, _table
   LOCAL _fld_iznos
   LOCAL _nula_cond := ""

   IF otv_stavke == NIL
      otv_stavke := .F.
   ENDIF

   _brza := rpt_vars[ "brza" ]
   _konto := rpt_vars[ "konto" ]
   _partner := rpt_vars[ "partner" ]
   _brdok := rpt_vars[ "brdok" ]
   _idvn := rpt_vars[ "idvn" ]
   _datum_od := rpt_vars[ "datum_od" ]
   _datum_do := rpt_vars[ "datum_do" ]
   _opcina := rpt_vars[ "opcina" ]
   _tip_valute := rpt_vars[ "valuta" ]
   _saldo_nula := rpt_vars[ "saldo_nula" ]

   _fld_iznos := "s.iznosbhd"

   IF _tip_valute == 2
      _fld_iznos := "s.iznosdem"
   ENDIF

   IF _saldo_nula == "D"
      _nula_cond := ""
   ENDIF

   _qry := "SELECT s.idkonto, k.naz as konto_naz, s.idpartner, p.naz as partn_naz, s.idvn, s.brnal, s.rbr, s.brdok, s.datdok, s.datval, s.opis, " + ;
      "( CASE WHEN s.d_p = '1' THEN " + _fld_iznos + " ELSE 0 END ) AS duguje, " + ;
      "( CASE WHEN s.d_p = '2' THEN " + _fld_iznos + " ELSE 0 END ) AS potrazuje " + ;
      "FROM " + F18_PSQL_SCHEMA_DOT + "fin_suban s " + ;
      "JOIN " + F18_PSQL_SCHEMA_DOT + "partn p ON s.idpartner = p.id " + ;
      "JOIN " + F18_PSQL_SCHEMA_DOT + "konto k ON s.idkonto = k.id " + ;
      "WHERE idfirma = " + sql_quote( gfirma )

   _qry += " AND " + _sql_date_parse( "s.datdok", _datum_od, _datum_do )

   IF _brza == "D"
      _qry += " AND " + _sql_cond_parse( "s.idkonto", _konto )
      IF !Empty( _partner )
         _qry += " AND " + _sql_cond_parse( "s.idpartner", _partner )
      ENDIF
   ELSE
      IF !Empty( _konto )
         _qry += " AND " + _sql_cond_parse( "s.idkonto", _konto )
      ENDIF
      IF !Empty( _partner )
         _qry += " AND " + _sql_cond_parse( "s.idpartner", _partner )
      ENDIF
   ENDIF

   IF !Empty( _brdok )
      _qry += " AND " + _sql_cond_parse( "s.brdok", _brdok )
   ENDIF

   IF !Empty( _idvn )
      _qry += " AND " + _sql_cond_parse( "s.idvn", _idvn )
   ENDIF

   IF !Empty( _opcina )
      _qry += " AND " + _sql_cond_parse( "p.idops", _opcina )
   ENDIF

   _qry += " ORDER BY s.idkonto, s.idpartner, s.datdok, s.brnal"

   MsgO( "formiranje sql upita u toku ..." )
   _table := run_sql_query( _qry )
   MsgC()

   IF sql_error_in_query( _table )
      RETURN NIL
   ENDIF

   RETURN _table



STATIC FUNCTION _export_dbf( table, rpt_vars )

   LOCAL oRow, _struct
   LOCAL _rec

   IF table:LastRec() == 0
      RETURN .F.
   ENDIF

   _struct := fin_kartica_dbf_struct()
   t_exp_create( _struct )

   O_R_EXP

   FOR _i := 1 TO table:LastRec()

      oRow := table:GetRow( _i )

      SELECT r_export
      APPEND BLANK

      _rec := dbf_get_rec()

      _rec[ "id_konto" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idkonto" ) ) )
      _rec[ "naz_konto" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "konto_naz" ) ) )
      _rec[ "id_partn" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idpartner" ) ) )
      _rec[ "naz_partn" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "partn_naz" ) ) )
      _rec[ "vrsta_nal" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idvn" ) ) )
      _rec[ "broj_nal" ] := oRow:FieldGet( oRow:FieldPos( "brnal" ) )
      _rec[ "nal_rbr" ] := oRow:FieldGet( oRow:FieldPos( "rbr" ) )
      _rec[ "broj_veze" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "brdok" ) ) )
      _rec[ "dat_nal" ] := oRow:FieldGet( oRow:FieldPos( "datdok" ) )
      _rec[ "dat_val" ] := oRow:FieldGet( oRow:FieldPos( "datval" ) )
      _rec[ "opis_nal" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "opis" ) ) )
      _rec[ "duguje" ] := oRow:FieldGet( oRow:FieldPos( "duguje" ) )
      _rec[ "potrazuje" ] := oRow:FieldGet( oRow:FieldPos( "potrazuje" ) )
      _rec[ "saldo" ] := oRow:FieldGet( oRow:FieldPos( "saldo" ) )

      dbf_update_rec( _rec )

   NEXT

   SELECT r_export
   USE

   RETURN .T.


FUNCTION fin_kartica_dbf_struct()

   LOCAL aDbf := {}

   AAdd( aDbf, { "id_konto", "C", 7, 0 }  )
   AAdd( aDbf, { "naz_konto", "C", 100, 0 }  )
   AAdd( aDbf, { "id_partn", "C", 6, 0 }  )
   AAdd( aDbf, { "naz_partn", "C", 50, 0 }  )
   AAdd( aDbf, { "vrsta_nal", "C", 2, 0 }  )
   AAdd( aDbf, { "broj_nal", "C", 8, 0 }  )
   AAdd( aDbf, { "nal_rbr", "C", 4, 0 }  )
   AAdd( aDbf, { "broj_veze", "C", 10, 0 }  )
   AAdd( aDbf, { "dat_nal", "D", 8, 0 }  )
   AAdd( aDbf, { "dat_val", "D", 8, 0 }  )
   AAdd( aDbf, { "opis_nal", "C", 100, 0 }  )
   AAdd( aDbf, { "duguje", "N", 15, 5 }  )
   AAdd( aDbf, { "potrazuje", "N", 15, 5 }  )
   AAdd( aDbf, { "saldo", "N", 15, 5 }  )

   RETURN aDbf



STATIC FUNCTION _cre_xml( table, rpt_vars )

   LOCAL _i, oRow, oItem
   LOCAL PIC_VRIJEDNOST := PadL( AllTrim( Right( PicDem, LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )
   LOCAL _u_dug1 := 0
   LOCAL _u_dug2 := 0
   LOCAL _u_pot1 := 0
   LOCAL _u_pot2 := 0
   LOCAL _u_saldo1 := 0
   LOCAL _u_saldo2 := 0
   LOCAL _val
   LOCAL _id_konto, _id_partner
   LOCAL _t_rec
   LOCAL _saldo_nula := rpt_vars[ "saldo_nula" ]

   IF table:LastRec() == 0
      RETURN .F.
   ENDIF

   open_xml( _my_xml )

   xml_head()

   xml_subnode( "kartica", .F. )

   xml_node( "f_id", gFirma )
   xml_node( "f_naz", to_xml_encoding( gNFirma ) )
   xml_node( "f_mj", to_xml_encoding( gMjStr ) )

   xml_node( "datum", DToC( Date() ) )
   xml_node( "datum_od", DToC( rpt_vars[ "datum_od" ] ) )
   xml_node( "datum_do", DToC( rpt_vars[ "datum_do" ] ) )

   IF rpt_vars[ "valuta" ] == 1
      xml_node( "val", "KM" )
   ELSE
      xml_node( "val", "EUR" )
   ENDIF

   table:GoTo(1)

   DO WHILE !table:Eof()

      oItem := table:GetRow()
      _t_rec := table:RecNo()

      _id_konto := oItem:FieldGet( oItem:FieldPos( "idkonto" ) )
      _id_partner := oItem:FieldGet( oItem:FieldPos( "idpartner" ) )

      IF _saldo_nula == "N"
         IF _fin_kartica_saldo_nula( table, _id_konto, _id_partner )
            LOOP
         ELSE
            table:GoTo( _t_rec )
         ENDIF
      ENDIF

      xml_subnode( "kartica_item", .F. )

      xml_node( "konto", to_xml_encoding( hb_UTF8ToStr( _id_konto ) ) )

      IF !Empty( _id_konto )
         _naz_konto := _sql_get_value( "konto", "naz", { { "id", AllTrim( _id_konto ) } } )
      ELSE
         _naz_konto := ""
      ENDIF

      xml_node( "konto_naz", to_xml_encoding( _naz_konto ) )
      xml_node( "partner", to_xml_encoding( hb_UTF8ToStr( _id_partner ) ) )
      IF !Empty( _id_partner )
         _naz_partner := _sql_get_value( "partn", "naz", { { "id", AllTrim( _id_partner ) } } )
      ELSE
         _naz_partner := ""
      ENDIF

      xml_node( "partner_naz", to_xml_encoding( _naz_partner ) )

      _u_pot1 := 0
      _u_dug1 := 0
      _u_saldo1 := 0

      DO WHILE !table:Eof() .AND. table:FieldGet( table:FieldPos( "idkonto" ) ) == _id_konto ;
            .AND. table:FieldGet( table:FieldPos( "idpartner" ) ) == _id_partner

         oRow := table:GetRow()

         xml_subnode( "row", .F. )

         _val := oRow:FieldGet( oRow:FieldPos( "idvn" ) )
         xml_node( "vn", to_xml_encoding( hb_UTF8ToStr( _val ) ) )

         _val := oRow:FieldGet( oRow:FieldPos( "brnal" ) )
         xml_node( "broj", _val )

         _val := oRow:FieldGet( oRow:FieldPos( "rbr" ) )
         xml_node( "rbr", _val )

         _val := oRow:FieldGet( oRow:FieldPos( "brdok" ) )
         xml_node( "veza", to_xml_encoding( hb_UTF8ToStr( _val ) ) )

         _val := oRow:FieldGet( oRow:FieldPos( "datdok" ) )
         xml_node( "datum", DToC( _val ) )

         _val := oRow:FieldGet( oRow:FieldPos( "datval" ) )
         xml_node( "datval", DToC( _val ) )

         _val := oRow:FieldGet( oRow:FieldPos( "opis" ) )
         xml_node( "opis", to_xml_encoding( hb_UTF8ToStr( _val ) ) )

         _val := oRow:FieldGet( oRow:FieldPos( "duguje" ) )
         xml_node( "dug", show_number( _val, PIC_VRIJEDNOST ) )
         _u_dug1 += _val

         _val := oRow:FieldGet( oRow:FieldPos( "potrazuje" ) )
         xml_node( "pot", show_number( _val, PIC_VRIJEDNOST ) )
         _u_pot1 += _val

         _val := oRow:FieldGet( oRow:FieldPos( "duguje" ) ) - oRow:FieldGet( oRow:FieldPos( "potrazuje" ) )
         _u_saldo1 += _val
         xml_node( "saldo", show_number( _u_saldo1, PIC_VRIJEDNOST ) )

         xml_subnode( "row", .T. )

         table:Skip()

      ENDDO

      xml_node( "dug", show_number( _u_dug1, PIC_VRIJEDNOST ) )
      xml_node( "pot", show_number( _u_pot1, PIC_VRIJEDNOST ) )
      xml_node( "saldo", show_number( _u_saldo1, PIC_VRIJEDNOST ) )

      xml_subnode( "kartica_item", .T. )

   ENDDO

   xml_subnode( "kartica", .T. )

   close_xml()

   RETURN .T.


STATIC FUNCTION _fin_kartica_saldo_nula( table, _konto, _partner )

   LOCAL _ret := .F.
   LOCAL _u_saldo := 0
   LOCAL oRow

   DO WHILE !table:Eof() .AND. table:FieldGet( table:FieldPos( "idkonto" ) ) == _konto ;
         .AND. table:FieldGet( table:FieldPos( "idpartner" ) ) == _partner

      oRow := table:GetRow()

      _dug := oRow:FieldGet( oRow:FieldPos( "duguje" ) )
      _pot := oRow:FieldGet( oRow:FieldPos( "potrazuje" ) )

      _u_saldo += ( _dug - _pot )

      table:Skip()

   ENDDO

   IF Round( _u_saldo, 2 ) == 0
      _ret := .T.
   ENDIF

   RETURN _ret