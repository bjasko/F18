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

STATIC __nvar
STATIC __doc_no

FUNCTION rnal_specifikacija_poslovodja( nVar )

   LOCAL _params

   IF nVar == nil
      nVar := 0
   ENDIF

   __nVar := nVar

   IF parametri_izvjestaja( @_params ) == 0
      RETURN .F.
   ENDIF

   generisi_specifikaciju_u_pomocnu_tabelu( _params )

   IF _params["txt_rpt"]
      printaj_specifikaciju_txt( _params )
   ELSE
      printaj_specifikaciju_odt( _params )
   ENDIF

   RETURN .T.


STATIC FUNCTION parametri_izvjestaja( params )

   LOCAL _ret := 1
   LOCAL _box_x := 18
   LOCAL _box_y := 70
   LOCAL _x := 1
   LOCAL _statusi, _tip_datuma
   LOCAL _dat_od, _dat_do, _group, _operater, _txt

   PRIVATE GetList := {}

   _statusi := fetch_metric( "rnal_spec_posl_status", NIL, "N" )
   _txt := fetch_metric( "rnal_spec_posl_tip_rpt", my_user(), 2 )
   _tip_datuma := fetch_metric( "rnal_spec_posl_tip_datuma", my_user(), 2 )

   _dat_od := danasnji_datum()
   _dat_do := _dat_od
   _group := 0
   _operater := 0

   Box(, _box_x, _box_y )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "*** Specifikacija radnih naloga za poslovođe"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Datum od:" GET _dat_od
   @ box_x_koord() + _x, Col() + 1 SAY "do:" GET _dat_do

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Operater (0 - svi op.):" GET _operater VALID {|| _operater == 0  } PICT "9999999999"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "*** Selekcija grupe artikala "

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(1) - rezano          (4) - IZO"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "(2) - kaljeno         (5) - LAMI"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "(3) - brušeno         (6) - emajlirano"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Grupa artikala (0 - sve grupe):" GET _group VALID _group >= 0 .AND. _group < 7 PICT "9"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Gledati statuse 'realizovano' (D/N) ?" GET _statusi VALID _statusi $ "DN" PICT "@!"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Gledati datum naloga ili datum isporuke (1/2) ?" GET _tip_datuma PICT "9"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Tip izvještaja TXT / LibreOffice (1/2) ?" GET _txt PICT "9" VALID _txt > 0 .AND. _txt < 3

   READ

   BoxC()

   IF LastKey() == K_ESC
      _ret := 0
      RETURN _ret
   ENDIF

   set_metric( "rnal_spec_posl_status", NIL, _statusi )
   set_metric( "rnal_spec_posl_tip_datuma", my_user(), _tip_datuma )
   set_metric( "rnal_spec_posl_tip_rpt", my_user(), _txt )

   params := hb_Hash()
   params[ "datum_od" ] := _dat_od
   params[ "datum_do" ] := _dat_do
   params[ "tip_datuma" ] := _tip_datuma
   params[ "group" ] := _group
   params[ "operater" ] := _operater
   params[ "gledaj_statuse" ] := _statusi
   params[ "txt_rpt" ] := ( _txt == 1 )

   params[ "idx" ] := "D1"

   IF _tip_datuma == 2
      params[ "idx" ] := "D2"
   ENDIF

   RETURN _ret



STATIC FUNCTION generisi_specifikaciju_u_pomocnu_tabelu( params )

   LOCAL nDoc_no
   LOCAL nArt_id
   LOCAL aArtArr := {}
   LOCAL nCount := 0
   LOCAL cCust_desc, cObjekatIsporuke
   LOCAL nScan
   LOCAL ii
   LOCAL cAop
   LOCAL cAopDesc
   LOCAL aGrCount := {}
   LOCAL nGr1
   LOCAL nGr2
   LOCAL cDoc_div := ""


   cre_tmp1( definicija_pomocne_tabele() )
   o_tmp1()

   rnal_o_tables( .F. )
   postavi_filter_na_dokumente( params )

   my_use_refresh_stop()

   Box(, 1, 50 )

   SELECT docs
   DO WHILE !Eof()

      nDoc_no := field->doc_no
      __doc_no := nDoc_no

      cCust_desc := AllTrim( g_cust_desc( docs->cust_id ) )

      IF "NN" $ cCust_desc
         cCust_desc := cCust_Desc + "/" + ;
            AllTrim( g_cont_desc( docs->cont_id ) )
      ENDIF

      cDoc_stat := get_status_dokumenta( docs->doc_status )
      cDoc_oper := getusername( docs->operater_i )
      cDoc_prior := s_priority( docs->doc_priori )
      cObjekatIsporuke := g_obj_desc( docs->obj_id, .T. )

      use_sql_doc_log( nDoc_no )
      SEEK docno_str( nDoc_no )
      cLog := ""
      DO WHILE !Eof() .AND. field->doc_no == nDoc_no
         cLog := DToC( field->doc_log_da )
         cLog += " / "
         cLog += AllTrim( field->doc_log_ti )
         cLog += " : "
         cLog += AllTrim( field->doc_log_de )
         select doc_log
         SKIP
      ENDDO

      IF "Inicij" $ cLog
         cLog := ""
      ELSE
         cLog := hb_Utf8ToStr( cLog )
      ENDIF

      SELECT doc_it
      SET ORDER TO TAG "1"
      SEEK docno_str( nDoc_no )
      DO WHILE !Eof() .AND. field->doc_no == nDoc_no

         nArt_id := field->art_id
         nDoc_it_no := field->doc_it_no
         nQtty := field->doc_it_qtt
         aArtDesc := {}
         rnal_matrica_artikla( nArt_id, @aArtDesc )
         //_glass_count := broj_stakala( aArtDesc, nQtty )

         // check group of item
         // "0156" itd...
         cIt_group := set_art_docgr( nArt_id, nDoc_no, nDoc_it_no, .F. )
         cDiv := AllTrim( Str( Len( cIt_group ) ) )
         cDoc_div := "(" + cDiv + "/" + cDiv + ")"
         cAop := " "

         SELECT doc_ops
         SET ORDER TO TAG "1"
         SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no )
         aAop := {}
         DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_it_no == nDoc_it_no
            cAopDesc := AllTrim( g_aop_desc( field->aop_id ) )
            nScan := AScan( aAop, {| xVal| xVal[ 1 ] == cAopDesc } )
            IF nScan == 0
               AAdd( aAop, { cAopDesc } )
            ENDIF
            SELECT doc_ops
            SKIP
         ENDDO

         cAop := ""
         IF Len( aAop ) > 0
            FOR ii := 1 TO Len( aAop )
               IF ii <> 1
                  cAop += "#"
               ENDIF
               cAop += aAop[ ii, 1 ]
            NEXT
         ENDIF

         lIsLami := is_lami( aArtDesc )

         IF lIsLami == .T.
            IF !Empty( cAop )
               cAop += "#"
            ENDIF
            cAop += "lami-rg"
         ENDIF

         SELECT doc_it
         cItem := AllTrim( g_art_desc( nArt_id ) )
         cItemAop := cAop
         nGr1 := Val( SubStr( cIt_group, 1, 1 ) )

         SELECT doc_it
         SKIP
      ENDDO

      SELECT docs
      dodaj_u_pomocnu_tabelu( nDoc_no, ;
                  cCust_desc, ;
                  docs->doc_date, ;
                  docs->doc_dvr_da, ;
                  docs->doc_dvr_ti, ;
                  cDoc_stat, ;
                  cDoc_prior, ;
                  cDoc_div, ;
                  docs->doc_desc, ;
                  docs->doc_sh_des, ;
                  cDoc_oper, ;
                  0, get_broj_stakala( nDoc_no ), ;
                  cItem, ;
                  cItemAop, ;
                  nGr1, ;
                  cLog, ;
                  cObjekatIsporuke )

     IF Len( cIt_group ) > 1
                  FOR xx := 1 TO Len( cIt_group )
                     IF Val( SubStr( cIt_group, xx, 1 ) ) == nGr1
                        LOOP
                     ENDIF
                     dodaj_u_pomocnu_tabelu( nDoc_no, ;
                        cCust_desc, ;
                        docs->doc_date, ;
                        docs->doc_dvr_da, ;
                        docs->doc_dvr_ti, ;
                        cDoc_stat, ;
                        cDoc_prior, ;
                        cDoc_div, ;
                        docs->doc_desc, ;
                        docs->doc_sh_des, ;
                        cDoc_oper, ;
                        0, get_broj_stakala( nDoc_no ), ;
                        cItem, ;
                        cItemAop, ;
                        Val( SubStr( cIt_group, xx, 1 ) ), ;
                        cLog, ;
                        cObjekatIsporuke )
                  NEXT
      ENDIF

      ++ nCount
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "datum isp./nalog broj: " + DToC( docs->doc_dvr_da ) + " / " + AllTrim( Str( nDoc_no ) )
      SELECT docs
      SKIP

   ENDDO

   BoxC()
   my_use_refresh_start()

   RETURN .T.


STATIC FUNCTION postavi_filter_na_dokumente( params )

   LOCAL _filter := ""
   LOCAL _date := "doc_date"
   LOCAL _dat_od := params[ "datum_od" ]
   LOCAL _dat_do := params[ "datum_do" ]
   LOCAL _tip_datuma := params[ "tip_datuma" ]
   LOCAL _group := params[ "group" ]
   LOCAL _oper := params[ "operater" ]
   LOCAL _idx := params[ "idx" ]
   LOCAL _statusi := params[ "gledaj_statuse" ]

   IF _tip_datuma == 2
      _date := "doc_dvr_da"
   ELSE
      _date := "doc_date"
   ENDIF

   IF _statusi == "N"
      _filter += "( doc_status == 0 .or. doc_status > 2 )"
   ELSE
      _filter += "( doc_status == 0 .or. doc_status == 4 ) "
   ENDIF

   _filter += " .and. DTOS( " + _date + " ) >= " + _filter_quote( DToS( _dat_od ) )
   _filter += " .and. DTOS( " + _date + " ) <= " + _filter_quote( DToS( _dat_do ) )

   IF _oper <> 0
      _filter += " .and. ALLTRIM( STR( operater_i ) ) == " + dbf_quote( AllTrim( Str( _oper ) ) )
   ENDIF

   SELECT docs
   SET ORDER TO tag &_idx
   SET FILTER to &_filter
   GO TOP

   RETURN



STATIC FUNCTION printaj_specifikaciju_odt( params )

   LOCAL cTemplate := "specnalp.odt"
   LOCAL i
   LOCAL ii
   LOCAL nScan
   LOCAL aItemAop
   LOCAL cPom
   LOCAL cXml := my_home() + "data.xml"
   LOCAL _group := params[ "group" ]
   LOCAL cObjekat, cPrioritet, cStat, cOper, cDescr

download_template( "specnalp.odt", "bed30593b51aff30920179333346e46d3a0a8b992463d88232d4391f1902d2c5" )
   SELECT _tmp1

   IF RecCount() == 0
       MsgBeep("Ne postoje traženi podaci !")
       RETURN .F.
   ENDIF

   GO TOP

   create_xml( cXml )
   xml_subnode( "spec", .F. )

   xml_node( "date", DToC( DATE() ) )
   xml_node( "per_od", DToC( params["datum_od"] ) )
   xml_node( "per_do", DToC( params["datum_do"] ) )

   DO WHILE !Eof()

      IF _group <> 0
         IF field->it_group <> _group
            SKIP
            loop
         ENDIF
      ENDIF

      nDoc_no := field->doc_no
      cCustDesc := field->cust_desc
      cDate := DToC( field->doc_date ) + "/" + ;
         DToC( field->doc_dvr_d )

      cDescr := AllTrim( field->doc_prior ) + " - " + ;
         AllTrim( field->doc_stat ) + " - " + ;
         AllTrim( field->doc_oper ) + " - (" + ;
         AllTrim( field->doc_sdesc ) + " )"

      nCount := 0
      nTotQtty := 0
      nTotGlQtty := field->GLASS_QTTY
      cItemAop := ""
      aItemAop := {}
      nScan := 0

      DO WHILE !Eof() .AND. field->doc_no == nDoc_no

         ++ nCount
         //nTotQtty += field->qtty
         //nTotGlQtty += field->glass_qtty

         cItemAop := AllTrim( field->doc_aop )
         IF !Empty( cItemAop )
            aPom := TokToNiz( cItemAop, "#" )
            FOR ii := 1 TO Len( aPom )
               nScan := AScan( aItemAop, ;
                  {| xVar| aPom[ ii ] == xVar[ 1 ] } )
               IF nScan = 0
                  AAdd( aItemAop, { aPom[ ii ] } )
               ENDIF
            NEXT
         ENDIF

         cDiv := AllTrim( field->doc_div )
         cLog := AllTrim( field->doc_log )
         cObjekat := ALLTRIM(field->doc_obj)
         cPrioritet := AllTrim( field->doc_prior )
         cStat := AllTrim( field->doc_stat )
         cOper := AllTrim( field->doc_oper )
         cDescr := AllTrim( field->doc_sdesc )
         SKIP

      ENDDO

      xml_subnode( "nalog", .F. )
      xml_subnode( "item", .F. )

      xml_node( "doc_no", AllTrim( Str( nDoc_no ) ) )
      xml_node( "date", cDate )
      xml_node( "cust", to_xml_encoding( cCustDesc ) )
      xml_node( "obj", to_xml_encoding( cObjekat ) )
      xml_node( "qtty", AllTrim( Str( nTotQtty, 12, 0 ) ) )
      xml_node( "gl_qtty", AllTrim( Str( nTotGlQtty, 12, 0 ) ) )
      xml_node( "div", cDiv )
      xml_node( "pri", to_xml_encoding( cPrioritet ) )
      xml_node( "stat", to_xml_encoding( cStat ) )
      xml_node( "oper", to_xml_encoding( cOper ) )
      xml_node( "descr", to_xml_encoding( cDescr ) )

      IF Len( aItemAop ) > 0
         cPom := ""
         FOR i := 1 TO Len( aItemAop )
            IF i <> 1
               cPom += ", "
            ENDIF
            cPom += aItemAop[ i, 1 ]
         NEXT
         xml_node( "op", to_xml_encoding( cPom ) )
      ELSE
         xml_node( "op", "" )
      ENDIF

      IF !Empty( cLog )
         xml_node( "log", to_xml_encoding( cLog ) )
      ELSE
         xml_node( "log", "" )
      ENDIF

      xml_subnode( "item", .T. )
      xml_subnode( "nalog", .T. )

   ENDDO

   xml_subnode( "spec", .T. )
   close_xml()

   my_close_all_dbf()

   IF generisi_odt_iz_xml( cTemplate )
      prikazi_odt()
   ENDIF

   RETURN



STATIC FUNCTION printaj_specifikaciju_txt( params )

   LOCAL i
   LOCAL ii
   LOCAL nScan
   LOCAL aItemAop
   LOCAL cPom
   LOCAL _group := params[ "group" ]
   LOCAL cObjekat

   START PRINT CRET

   ?
   P_COND2

   naziv_izvjestaja()
   __rpt_info()
   zaglavlje()

   SELECT _tmp1
   GO TOP

   DO WHILE !Eof()

      IF _group <> 0
         IF field->it_group <> _group
            SKIP
            loop
         ENDIF
      ENDIF

      IF nova_stranica() == .T.
         FF
      ENDIF

      nDoc_no := field->doc_no
      cCustDesc := field->cust_desc
      cDate := DToC( field->doc_date ) + "/" +  DToC( field->doc_dvr_d )
      cDescr := AllTrim( field->doc_prior ) + " - " + ;
         AllTrim( field->doc_stat ) + " - " + ;
         AllTrim( field->doc_oper ) + " - (" + ;
         AllTrim( field->doc_sdesc ) + " )"

      nCount := 0
      nTotQtty := 0
      nTotGlQtty := field->GLASS_QTTY
      cItemAop := ""

      aItemAop := {}
      nScan := 0

      DO WHILE !Eof() .AND. field->doc_no == nDoc_no

         ++ nCount
         //nTotQtty += field->qtty
         //nTotGlQtty += field->glass_qtty

         cItemAop := AllTrim( field->doc_aop )

         IF !Empty( cItemAop )

            aPom := TokToNiz( cItemAop, "#" )
            FOR ii := 1 TO Len( aPom )
               nScan := AScan( aItemAop, {| xVar| aPom[ ii ] == xVar[ 1 ] } )
               IF nScan = 0
                  AAdd( aItemAop, { aPom[ ii ] } )
               ENDIF
            NEXT
         ENDIF

         cDiv := AllTrim( field->doc_div )
         cLog := AllTrim( field->doc_log )
         cObjekat := ALLTRIM( field->doc_obj )
         SKIP
      ENDDO

      cDescr := cDiv + " - " + cDescr

      ? docno_str( nDoc_no )
      @ PRow(), PCol() + 1 SAY PadR( cCustDesc, 30 )
      @ PRow(), PCol() + 1 SAY PadR( cDate, 17 )
      @ PRow(), PCol() + 1 SAY " " + PadR( cDescr, 100 )
      ? Space( 10 )
      @ PRow(), PCol() + 1 SAY "kom.na nalogu: " + AllTrim( Str( nTotGlQtty, 12 ) )
      @ PRow(), PCol() + 1 SAY "obj: " + cObjekat

      IF Len( aItemAop ) > 0
         cPom := ""
         FOR i := 1 TO Len( aItemAop )
            IF i <> 1
               cPom += ", "
            ENDIF
            cPom += aItemAop[ i, 1 ]
         NEXT
         @ PRow(), PCol() + 1 SAY ", op.: " + cPom
      ENDIF

      IF !Empty( cLog )
         ? Space( 10 )
         @ PRow(), PCol() + 2 SAY "zadnja promjena: "
         @ PRow(), PCol() + 1 SAY cLog
      ENDIF

      ?
   ENDDO

   my_close_all_dbf()

   FF
   ENDPRINT

   RETURN


STATIC FUNCTION nova_stranica()

   LOCAL lRet := .F.

   IF PRow() > 62
      lRet := .T.
   ENDIF

   RETURN lRet



STATIC FUNCTION naziv_izvjestaja()

   LOCAL cTmp := "rpt: "

   DO CASE
   CASE __nvar == 1
      cTmp += "SPECIFIKACIJA NALOGA ZA POSLOVOĐE"
   ENDCASE

   ?U cTmp

   RETURN .T.



STATIC FUNCTION zaglavlje()

   cLine := Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 30 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 17 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 100 )

   cTxt := PadR( "Nalog br.", 10 )
   cTxt += Space( 1 )
   cTxt += PadR( "Partner", 30 )
   cTxt += Space( 1 )
   cTxt += PadR( "Termini", 17 )
   cTxt += Space( 1 )
   cTxt += PadR( "Ostale info (divizor - prioritet - status - operater - opis - objekat isporuke)", 100 )

   ? cLine
   ? cTxt
   ? cLine

   RETURN



STATIC FUNCTION definicija_pomocne_tabele()

   LOCAL aDbf := {}

   AAdd( aDbf, { "doc_no", "N", 10, 0 } )
   AAdd( aDbf, { "cust_desc", "C", 50, 0 } )
   AAdd( aDbf, { "doc_date", "D", 8, 0 } )
   AAdd( aDbf, { "doc_dvr_d", "D", 8, 0 } )
   AAdd( aDbf, { "doc_dvr_t", "C", 10, 0 } )
   AAdd( aDbf, { "doc_stat", "C", 30, 0 } )
   AAdd( aDbf, { "doc_prior", "C", 30, 0 } )
   AAdd( aDbf, { "doc_oper", "C", 30, 0 } )
   AAdd( aDbf, { "doc_div", "C", 20, 0 } )
   AAdd( aDbf, { "doc_desc", "C", 100, 0 } )
   AAdd( aDbf, { "doc_obj", "C", 150, 0 } )
   AAdd( aDbf, { "doc_sdesc", "C", 100, 0 } )
   AAdd( aDbf, { "doc_item", "C", 250, 0 } )
   AAdd( aDbf, { "doc_aop", "C", 250, 0 } )
   AAdd( aDbf, { "qtty", "N", 15, 5 } )
   AAdd( aDbf, { "glass_qtty", "N", 15, 5 } )
   AAdd( aDbf, { "it_group", "N", 5, 0 } )
   AAdd( aDbf, { "doc_log", "C", 200, 0 } )

   RETURN aDbf


STATIC FUNCTION dodaj_u_pomocnu_tabelu( nDoc_no, cCust_desc, dDoc_date, dDoc_dvr_d, ;
      cDoc_dvr_t, ;
      cDoc_stat, cDoc_prior, ;
      cDoc_div, cDoc_desc, cDoc_sDesc, cDoc_oper, ;
      nQtty, nGl_qtty, cDoc_item, cDoc_aop,nIt_group, cDoc_log, cObjekat )

   LOCAL nTArea := Select()

   SELECT _tmp1
   APPEND BLANK

   REPLACE field->doc_no WITH nDoc_no
   REPLACE field->cust_desc WITH cCust_desc
   REPLACE field->doc_date WITH dDoc_date
   REPLACE field->doc_dvr_d WITH dDoc_dvr_d
   REPLACE field->doc_dvr_t WITH cDoc_dvr_t
   REPLACE field->doc_stat WITH cDoc_stat
   REPLACE field->doc_prior WITH cDoc_prior
   REPLACE field->doc_oper WITH cDoc_oper
   REPLACE field->doc_div WITH cDoc_div
   REPLACE field->doc_desc WITH cDoc_desc
   REPLACE field->doc_sdesc WITH cDoc_sdesc
   REPLACE field->doc_item WITH cDoc_item
   REPLACE field->doc_aop WITH cDoc_aop
   REPLACE field->doc_obj WITH cObjekat
   REPLACE field->qtty WITH nQtty
   REPLACE field->glass_qtty WITH nGl_qtty
   REPLACE field->it_group WITH nIt_group
   REPLACE field->doc_log WITH cDoc_log

   SELECT ( nTArea )

   RETURN
