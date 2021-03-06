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


// variables
STATIC __temp
STATIC __doc_no



FUNCTION stampa_nalog_proizvodnje( lTemporary, nDoc_no )

   LOCAL cFlag := "N"
   LOCAL lFlag

   __temp := lTemporary
   __doc_no := nDoc_no

   t_rpt_create()
   t_rpt_open()

   rnal_o_tables( __temp )

   _fill_main()
   _fill_items()
   fill_za_stampu_doc_it2()
   fill_operacije()

   lFlag := is_printati_rekap_repromaterijala()

   IF lFlag == .T.
      cFlag := "D"
   ENDIF

   add_tpars( "N20", cFlag )

   IF gRnalOdt == "D"
      rnal_nalog_za_proizvodnju_odt()
   ELSE
      rnal_nalog_za_proizvodnju_txt()
   ENDIF

   my_close_all_dbf()

   rnal_o_tables( __temp )

   RETURN DE_REFRESH





FUNCTION rnal_stampa_obracunski_list( temp, doc_no, a_docs )

   LOCAL _gn := .T.
   LOCAL nI
   LOCAL _ii
   LOCAL _docs := ""
   LOCAL _flag := "N"
   LOCAL _count

   IF gGnUse == "N"
      _gn := .F.
   ENDIF


   IF a_docs == NIL .OR. Len( a_docs ) == 0
      a_docs := {}
      AAdd( a_docs, { doc_no, "" } )
   ENDIF

   FOR _ii := 1 TO Len( a_docs )
      IF !Empty( _docs )
         _docs += ","
      ENDIF
      _docs += AllTrim( Str( a_docs[ _ii, 1 ] ) )
   NEXT

   __temp := temp

   t_rpt_create()
   t_rpt_open()

   rnal_o_sif_tables()
   rnal_o_tables( __temp )

   my_use_refresh_stop()

   FOR nI := 1 TO Len( a_docs )

      IF a_docs[ nI, 1 ] < 0
         LOOP
      ENDIF

      __doc_no := a_docs[ nI, 1 ]

      SELECT docs
      GO TOP
      SEEK docno_str( __doc_no )

      _fill_main( _docs )
      _fill_items( _gn, 2 )
      fill_za_stampu_doc_it2()
      fill_operacije()

   NEXT

   my_use_refresh_start()

   _count := t_docit->( RecCount2() )

   IF _count > 0 .AND. Pitanje(, "Odabrati stavke za štampu ? (D/N)", "N" ) == "D"
      rnal_print_odabir_stavki( temp )
   ENDIF

   IF is_printati_rekap_repromaterijala()
      _flag := "D"
   ENDIF

   add_tpars( "N20", _flag )

   IF gRnalOdt == "D"
      rnal_obracunski_list_odt()
   ELSE
      obrl_print( .T. )
   ENDIF

   my_close_all_dbf()

   rnal_o_tables( __temp )

   RETURN DE_REFRESH



// -------------------------------------
// samo napuni pripremne tabale
// -------------------------------------
FUNCTION st_pripr( lTemporary, nDoc_no, aOlDocs )

   LOCAL lGN := .T.
   LOCAL i
   LOCAL ii
   LOCAL cDocs := ""
   LOCAL cFlag := "N"

   IF aOlDocs == NIL .OR. Len( aOlDocs ) == 0
      // dodaj onda ovaj nalog koji treba da se stampa
      aOlDocs := {}
      AAdd( aOlDocs, { nDoc_no, "" } )
   ENDIF

   // setuj opis i dokumente
   FOR ii := 1 TO Len( aOlDocs )
      IF !Empty( cDocs )
         cDocs += ","
      ENDIF
      cDocs += AllTrim( Str( aOlDocs[ ii, 1 ] ) )
   NEXT

   __temp := lTemporary

   // kreiraj print tabele
   t_rpt_create()
   // otvori tabele
   t_rpt_open()

   rnal_o_tables( __temp )

   // prosetaj kroz stavke za stampu !
   FOR i := 1 TO Len( aOlDocs )

      IF aOlDocs[ i, 1 ] < 0
         // ovakve stavke preskoci...
         // jer su to brisane stavke !
         LOOP
      ENDIF

      __doc_no := aOlDocs[ i, 1 ]

      SELECT docs
      GO TOP
      SEEK docno_str( __doc_no )


      _fill_main( cDocs ) // osnovni podaci naloga

      _fill_items( lGN, 2 ) // stavke naloga

      fill_za_stampu_doc_it2() // dodatne stavke naloga

      fill_operacije() // operacije

   NEXT

   my_close_all_dbf()

   rnal_o_tables( __temp )

   RETURN DE_REFRESH




FUNCTION rnal_stampa_naljepnica( lTemporary, nDoc_no )

   LOCAL lGn := .T.

   __temp := lTemporary
   __doc_no := nDoc_no

   t_rpt_create()
   t_rpt_open()

   rnal_o_tables( lTemporary )

   _fill_main()
   _fill_items( lGn, 2 )
   fill_operacije()

   rnal_stampa_naljepnica_odt( lTemporary )

   my_close_all_dbf()

   rnal_o_tables( lTemporary )

   RETURN DE_REFRESH




// -------------------------------------------------------
// filuj tabele za stampu
// lZPoGn - zaokruzenje po GN .t. or .f.
// nVar - varijanta 1, 2, 3... 1-nalog, 2-obrl. itd..
// -------------------------------------------------------
STATIC FUNCTION _fill_items( lZpoGN, nVar )

   LOCAL nTable := F_DOC_IT
   LOCAL nTOps := F_DOC_OPS
   LOCAL nArt_id
   LOCAL cArt_desc
   LOCAL cArt_full_desc
   LOCAL nDoc_it_no
   LOCAL cDoc_gr_no := "0"
   LOCAL nQtty
   LOCAL nTotal
   LOCAL nTot_m
   LOCAL nHeigh
   LOCAL nHe2
   LOCAL nWidth
   LOCAL nWi2
   LOCAL nZWidth := 0
   LOCAL nZH2 := 0
   LOCAL nZW2 := 0
   LOCAL nZHeigh := 0
   LOCAL nNeto := 0
   LOCAL nBruto := 0
   LOCAL lGroups := .F.
   LOCAL nGr1
   LOCAL nGr2
   LOCAL cPosition
   LOCAL cIt_lab_pos, cArtShTmp, cOrigDesc
   LOCAL nScan
   LOCAL xx

   IF nVar == NIL
      nVar := 1
   ENDIF

   IF lZpoGN == NIL
      lZPoGN := .F.
   ENDIF


   IF gGnUse == "N" // iskljucen parametar zaokruzenja
      lZPoGn := .F.
   ENDIF

   IF nVar == 1 .AND. Pitanje(, "Razdijeliti nalog po grupama ?", "D" ) == "D"
      lGroups := .T.
   ENDIF

   IF ( __temp == .T. )
      nTable := F__DOC_IT
      nTOps := F__DOC_OPS
   ENDIF

   SELECT ( nTable )
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( __doc_no )

   nArtTmp := -1
   cGrTmp := "-1"
   cArtShTmp := "xxx"

   // filuj stavke
   DO WHILE !Eof() .AND. field->doc_no == __doc_no

      nArt_id := field->art_id
      nDoc_it_no := field->doc_it_no
      nDoc_no := field->doc_no

      cDoc_it_pos := AllTrim( field->doc_it_pos )
      cIt_lab_pos := field->it_lab_pos
      cPosition := ""

      IF !Empty( cDoc_it_pos )
         cPosition := "pozicija: " + cDoc_it_pos + ", "
      ENDIF


      cDoc_it_type := field->doc_it_typ // tip artikla

      // nadji proizvod
      SELECT articles
      HSEEK artid_str( nArt_id )

      IF lGroups == .T.

         // odredi grupu artikla
         // - izo i kaljeno, izo i bruseno ili ....
         cDoc_gr_no := set_art_docgr( nArt_id, nDoc_no, nDoc_it_no, __temp )

      ELSE

         cDoc_gr_no := "0"

      ENDIF

      cOper_desc := ""
      lPrepust := .F.

      nHeigh := 0
      nWidth := 0

      // u varijanti obracunskog lista uzmi i operacije za ovu stavku
      IF nVar == 2

         aOper := {}
         cTmp := ""

         SELECT ( nTOps )
         SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no )
         DO WHILE !Eof() .AND. field->doc_no = nDoc_no ;
               .AND. field->doc_it_no = nDoc_it_no

            // ako je prepust, uzmi dimenzije
            cTmp_val := AllTrim( field->aop_value )

            IF ( "<A_PREP>" $ cTmp_val ) .AND. lPrepust == .F.

               lPrepust := .T.
               rnal_dimenzije_prepusta_za_nalog( cTmp_val, @nWidth, @nHeigh )

            ENDIF

            cTmp := g_aop_desc( field->aop_id )
            nScan := AScan( aOper, {| xVar| xVar[ 1 ] = cTmp } )

            IF nScan = 0
               AAdd( aOper, { cTmp } )
            ENDIF

            SKIP
         ENDDO

         FOR xx := 1 TO Len( aOper )

            IF !Empty( cOper_desc )
               cOper_desc += ", "
            ENDIF

            cOper_desc += AllTrim( aOper[ xx, 1 ] )
         NEXT

         IF !Empty( cOper_desc )
            cOper_desc := ", " + cOper_desc
         ENDIF

      ENDIF

      cArt_full_desc := AllTrim( articles->art_full_d )
      cArt_desc := AllTrim( articles->art_desc )

      cArt_sh := cArt_desc
      cArt_sh += cOper_desc

      // temporary
      cArt_desc := "(" + cArt_desc + ")"
      cArt_desc += " " + cArt_full_desc

      IF nVar = 2
         cArt_desc += cOper_desc
      ENDIF

      cOrigDesc := cArt_desc

      // ako je artikal isti ne treba mu opis...
      IF ( nArt_Id == nArtTmp ) .AND. ( cGrTmp == cDoc_gr_no ) .AND. ( cArt_sh == cArtShTmp )
         IF lZpoGN == .F.
            cArt_desc := ""
         ENDIF
      ENDIF

      SELECT ( nTable )

      nQtty := field->doc_it_qtt

      // dimenzije stakla
      IF nHeigh < field->doc_it_hei
         nHeigh := field->doc_it_hei
      ENDIF

      IF nWidth < field->doc_it_wid
         nWidth := field->doc_it_wid
      ENDIF

      // dimenzije ako je oblik SHAPE
      nHe2 := field->doc_it_h2
      nWi2 := field->doc_it_w2

      // kod obracunskog lista
      IF nVar == 2
         // prepust...
      ENDIF

      // nadmorska visina
      // samo ako je razlicita vrijednost od default-ne
      IF ( field->doc_it_alt <> gDefNVM ) .OR. ;
            ( field->doc_acity <> AllTrim( gDefCity ) )
         nDocit_altt := field->doc_it_alt
         cDocit_city := field->doc_acity
      ELSE
         nDocit_altt := 0
         cDocit_city := ""
      ENDIF

      // ukupno mm -> m2
      nTotal := Round( c_ukvadrat( nQtty, nHeigh, nWidth ), 2 )

      // ukupno duzinski
      nTot_m := Round( c_duzinski( nQtty, nHeigh, nWidth ), 2 )

      cDoc_it_schema := field->doc_it_sch
      // na napomene dodaj i poziciju ako postoji...
      cDoc_it_desc := cPosition + AllTrim( field->doc_it_des )

      aZpoGN := {}
      rnal_matrica_artikla( nArt_id, @aZpoGN )

      IF lZpoGN == .T.

         lBezZaokr := .F.

         IF lBezZaokr == .F.
            // da li je kaljeno ? kod kaljenog nema zaokruzenja
            lBezZaokr := is_kaljeno( aZpoGN, nDoc_no, nDoc_it_no, NIL, __temp )
         ENDIF

         IF lBezZaokr == .F.
            // da li je emajlirano ? isto nema zaokruzenja
            lBezZaokr := is_emajl( aZpoGN, nDoc_no, nDoc_it_no, NIL, __temp )
         ENDIF

         IF lBezZaokr == .F.
            // da li je vatroglas ? isto nema zaokruzenja
            lBezZaokr := is_vglass( aZpoGN )
         ENDIF

         IF lBezZaokr == .F.
            // da li je plexiglas ? isto nema zaokruzenja
            lBezZaokr := is_plex( aZpoGN )
         ENDIF

         nZHeigh := obrl_zaok( nHeigh, aZpoGN, lBezZaokr )
         nZH2 := obrl_zaok( nHe2, aZpoGN, lBezZaokr )

         nZWidth := obrl_zaok( nWidth, aZpoGN, lBezZaokr )
         nZW2 := obrl_zaok( nWi2, aZpoGN, lBezZaokr )

         // ako se zaokruzuje onda total ide po zaokr.vrijednostima
         nTotal := Round( c_ukvadrat( nQtty, nZHeigh, nZWidth, nZH2, nZW2 ), 2 )

      ENDIF


      // izracunaj neto
      nNeto := Round( obrl_neto( nTotal, aZpoGN ), 2 )
      nBruto := 0

      // prva grupa
      nGr1 := Val( SubStr( cDoc_gr_no, 1, 1 ) )

      // dodaj u stavke
      a_t_docit( __doc_no, nGr1, nDoc_it_no, nArt_id, cArt_desc, cArt_sh, cOrigDesc, ;
         cDoc_it_schema, cDoc_it_desc, cDoc_it_Type, ;
         nQtty, nHeigh, nWidth, ;
         nHe2, nWi2, ;
         nDocit_altt, cDocit_city, nTotal, nTot_m, ;
         nZHeigh, nZWidth, ;
         nZH2, nZW2, ;
         nNeto, nBruto, cDoc_it_pos, cIt_lab_pos )


      IF Len( cDoc_gr_no ) > 1

         // razdvoji nalog na 2 dijela
         // ako ima vise grupa

         FOR xx := 1 to ( Len( cDoc_gr_no ) )

            // ako je vec kao grupa 1 onda preskoci...
            IF Val( SubStr( cDoc_gr_no, xx, 1 ) ) == nGr1
               LOOP
            ENDIF

            a_t_docit( __doc_no, Val( SubStr( cDoc_Gr_no, xx, 1 ) ), nDoc_it_no, nArt_id, cArt_desc, cArt_sh, cOrigDesc, ;
               cDoc_it_schema, cDoc_it_desc, cDoc_it_type, ;
               nQtty, nHeigh, nWidth, ;
               nHe2, nWi2, ;
               nDocit_altt, cDocit_city, nTotal, nTot_m, ;
               nZHeigh, nZWidth, ;
               nZH2, nZW2, ;
               nNeto, nBruto, cDoc_it_pos, cIt_lab_pos )

         NEXT

      ENDIF

      nArtTmp := nArt_Id
      cGrTmp := cDoc_gr_no
      cArtShTmp := cArt_sh

      SELECT ( nTable )
      SKIP
   ENDDO

   RETURN .T.


// ---------------------------------------------------
// da li printati rekapitulaciju repromaterijala
// ---------------------------------------------------
FUNCTION is_printati_rekap_repromaterijala()

   LOCAL lRet := .F.
   LOCAL nTArea := Select()

   SELECT t_docit2

   IF RECCOUNT2() > 0
      IF Pitanje(, "Štampati rekapitulaciju materijala ?", "D" ) == "D"
         lRet := .T.
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN lRet


// ----------------------------------
// filuj tabele za stampu DOC_IT2
// ----------------------------------
STATIC FUNCTION fill_za_stampu_doc_it2()

   LOCAL nTable := F_DOC_IT2
   LOCAL cArt_id
   LOCAL cArt_desc
   LOCAL nDoc_it_no
   LOCAL nQtty

   IF ( __temp == .T. )
      nTable := F__DOC_IT2
   ENDIF

   SELECT ( nTable )

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( __doc_no )

   // filuj stavke
   DO WHILE !Eof() .AND. field->doc_no == __doc_no

      cArt_id := field->art_id
      nDoc_it_no := field->doc_it_no
      nDoc_no := field->doc_no
      nIt_no := field->it_no

      // nadji artikal
      select_o_roba( cArt_id )

      cArt_desc := AllTrim( roba->naz )

      SELECT ( nTable )

      nQtty := field->doc_it_qtt
      nQ2 := field->doc_it_q2
      nPrice := field->doc_it_pri

      cJmj := field->jmj
      cJmjArt := field->jmj_art

      cDesc := AllTrim( field->descr )
      cSh_desc := AllTrim( field->sh_desc )

      cDescription := ""

      IF !Empty( cSh_desc )
         cDescription += cSh_desc
      ENDIF

      IF !Empty( cDesc )
         cDescription += ", " + cDesc
      ENDIF

      // dodaj u stavke
      a_t_docit2( __doc_no, nDoc_it_no, nIt_no, cArt_id, cArt_desc, ;
         nQtty, nQ2, cJmj, cJmjArt, nPrice, cDescription )

      SELECT ( nTable )
      SKIP

   ENDDO

   RETURN .T.




STATIC FUNCTION fill_operacije()

   LOCAL nTable := F_DOC_OPS
   LOCAL nTable2 := F_DOC_IT
   LOCAL nDoc_op_no
   LOCAL nDoc_it_no
   LOCAL nDoc_el_no
   LOCAL cDoc_el_desc
   LOCAL nArt_id
   LOCAL aElem
   LOCAL nElem_no
   LOCAL nAop_id
   LOCAL cAop_desc
   LOCAL nAop_att_id
   LOCAL cAop_att_desc
   LOCAL cDoc_op_desc
   LOCAL cAop_Value
   LOCAL cAop_vraw
   LOCAL cRecord

   IF ( __temp == .T. )
      nTable := F__DOC_OPS
      nTable2 := F__DOC_IT
   ENDIF

   SELECT ( nTable2 )
   SET ORDER TO TAG "2"

   SELECT ( nTable )  // filuj operacije
   SET ORDER TO TAG "1"

   SEEK docno_str( __doc_no )

   cRecord := ""
   cTmpRecord := "XX"
   nArticle := -99
   nTmpArticle := -99


   DO WHILE !Eof() .AND. field->doc_no == __doc_no

      nElem_no := 0
      nDoc_it_no := field->doc_it_no
      nDoc_op_no := field->doc_op_no
      nDoc_el_no := field->doc_it_el_

      // uzmi sve operacije za jednu stavku
      // ispitaj da li trebas da da je dodajes za stampu

      nRec := RecNo()

      cRecord := ""

      DO WHILE !Eof() .AND. field->doc_no == __doc_no .AND. field->doc_it_no == nDoc_it_no

         nAop_id := field->aop_id
         nAop_att_id := field->aop_att_id

         cRecord += g_aop_desc( nAop_id )
         cRecord += ","
         cRecord += g_aop_att_desc( nAop_att_id )

         IF !Empty( field->aop_value )
            cRecord += ","
            cRecord += AllTrim( field->aop_value )
         ENDIF

         IF !Empty( AllTrim( field->doc_op_des ) )
            cRecord += ","
            cRecord += AllTrim( field->doc_op_des )
         ENDIF

         cRecord += "#"

         SKIP
      ENDDO

      SELECT ( nTable2 ) // doc_it uzmi artikal
      SET ORDER TO TAG "1"

      SEEK docno_str( __doc_no ) + docit_str( nDoc_it_no )

      nArticle := field->art_id

      SELECT ( nTable ) // vrati se na operacije

      // ako su identicne operacije samo idi dalje....
      IF cRecord == cTmpRecord .AND. nArticle == nTmpArticle
         LOOP
      ENDIF

      // vrati se na zapis gdje si bio
      GO ( nRec )

      DO WHILE !Eof() .AND. field->doc_no == __doc_no ;
            .AND. field->doc_it_no == nDoc_it_no


         nElem_no := 0
         nDoc_it_no := field->doc_it_no
         nDoc_op_no := field->doc_op_no
         nDoc_el_no := field->doc_it_el_

         SELECT ( nTable2 )
         SET ORDER TO TAG "1"
         GO TOP
         SEEK docno_str( __doc_no ) + docit_str( nDoc_it_no )

         nArt_id := field->art_id

         aElem := {}

         _g_art_elements( @aElem, nArt_id )

         // vrati broj elementa artikla (1, 2, 3 ...)
         _g_elem_no( aElem, nDoc_el_no, @nElem_no )

         cDoc_el_desc := get_elem_desc( aElem, nDoc_el_no, 150 )

         SELECT ( nTable )

         nAop_id := field->aop_id
         nAop_att_id := field->aop_att_id

         cAop_desc := g_aop_desc( nAop_id )
         cAop_att_desc := g_aop_att_desc( nAop_att_id )

         cDoc_op_desc := AllTrim( field->doc_op_des )

         cAop_value := g_aop_value( field->aop_value )
         cAop_vraw := AllTrim( field->aop_value )

         a_t_docop( __doc_no, nDoc_op_no, nDoc_it_no, ;
            nElem_no, cDoc_el_desc, ;
            nAop_id, cAop_desc, ;
            nAop_att_id, cAop_att_desc, ;
            cDoc_op_desc, cAop_value, cAop_vraw )


         SELECT ( nTable )
         SKIP

      ENDDO

      cTmpRecord := cRecord
      nTmpArticle := nArticle

   ENDDO

   RETURN .T.




STATIC FUNCTION _fill_main( cDescr )

   LOCAL nTable := F_DOCS

   IF cDescr == nil
      cDescr := ""
   ENDIF

   IF ( __temp == .T. )
      nTable := F__DOCS
   ENDIF

   SELECT ( nTable )
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( __doc_no )

   _fill_customer( field->cust_id )
   _fill_contacts( field->cont_id )
   _fill_objects( field->obj_id )

   SELECT ( nTable )

   // broj naloga
   add_tpars( "N01", docno_str( __doc_no ) )
   // datum naloga
   add_tpars( "N02", DToC( field->doc_date ) )
   // datum isporuke
   add_tpars( "N03", DToC( field->doc_dvr_da ) )
   // vrijeme isporuke
   add_tpars( "N04", PadR( field->doc_dvr_ti, 5 ) )
   // hitnost - prioritet
   add_tpars( "N05", s_priority( field->doc_priori ) )
   // nalog vrsta placanja
   add_tpars( "N06", s_pay_id( field->doc_pay_id ) )
   // mjesto isporuke
   add_tpars( "N07", AllTrim( field->doc_ship_p ) )
   // dokument dodatni podaci
   add_tpars( "N08", AllTrim( field->doc_desc ) )
   // dokument kratki opis
   add_tpars( "N15", AllTrim( field->doc_sh_des ) )
   // dokument, kontakt dodatni podaci...
   add_tpars( "N09", AllTrim( field->cont_add_d ) )
   // operater koji je napravio nalog
   add_tpars( "N13", AllTrim( getfullusername( field->operater_i ) ) )
   // status naloga
   add_tpars( "N22", hb_utf8tostr( AllTrim( get_status_dokumenta( field->doc_status ) ) ) )

   // dokumenti koji su sadrzani
   IF !Empty( cDescr )
      add_tpars( "N14", cDescr )
   ENDIF

   // neuskladjeni proizvod
   add_tpars( "N21", field->doc_type )

   // ako je kes, dodaj i podatke o placeno D i napomene
   IF field->doc_pay_id == 2

      // placeno d/n...
      add_tpars( "N10", AllTrim( field->doc_paid ) )
      // placanje dodatne napomene...
      add_tpars( "N11", AllTrim( field->doc_pay_de ) )

   ENDIF

   IF FieldPos( "DOC_TIME" ) <> 0
      // vrijeme dokumenta
      add_tpars( "N12", AllTrim( field->doc_time ) )
   ENDIF

   RETURN .T.



// ----------------------------------------
// dodaj podatke o naruciocu
// ----------------------------------------
STATIC FUNCTION _fill_customer( nCust_id )

   LOCAL nTArea := Select()
   LOCAL cCust_desc := ""
   LOCAL cCust_addr := ""
   LOCAL cCust_tel := ""

   SELECT customs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK custid_str( nCust_id )

   IF Found()
      cCust_desc := AllTrim( customs->cust_desc )
      cCust_addr := AllTrim( customs->cust_addr )
      cCust_tel := AllTrim( customs->cust_tel )
   ENDIF

   add_tpars( "P01", custid_str( nCust_id ) )
   add_tpars( "P02", cCust_desc )
   add_tpars( "P03", cCust_addr )
   add_tpars( "P04", cCust_tel )

   SELECT ( nTArea )

   RETURN


// ----------------------------------------
// dodaj podatke o kontaktu
// ----------------------------------------
STATIC FUNCTION _fill_contacts( nCont_id )

   LOCAL nTArea := Select()
   LOCAL cCont_desc := ""
   LOCAL cCont_tel := ""
   LOCAL cCont_add_desc := ""

   SELECT contacts
   SET ORDER TO TAG "1"
   GO TOP
   SEEK contid_str( nCont_id )

   IF Found()
      cCont_desc := AllTrim( contacts->cont_desc )
      cCont_tel := AllTrim( contacts->cont_tel )
      cCont_add_desc := AllTrim( contacts->cont_add_d )
   ENDIF

   add_tpars( "P10", contid_str( nCont_id ) )
   add_tpars( "P11", cCont_desc )
   add_tpars( "P12", cCont_tel )
   add_tpars( "P13", cCont_add_desc )

   SELECT ( nTArea )

   RETURN


// ----------------------------------------
// dodaj podatke o objektu
// ----------------------------------------
STATIC FUNCTION _fill_objects( nObj_id )

   LOCAL nTArea := Select()
   LOCAL cObj_desc := ""

   SELECT objects
   SET ORDER TO TAG "1"
   GO TOP
   SEEK objid_str( nObj_id )

   IF Found()
      cObj_desc := AllTrim( objects->obj_desc )
   ENDIF

   add_tpars( "P20", objid_str( nObj_id ) )
   add_tpars( "P21", cObj_desc )

   SELECT ( nTArea )

   RETURN



// ---------------------------------------------
// vraca opis grupe za stampu dokumenta
// ---------------------------------------------
FUNCTION get_art_docgr( nGr )

   LOCAL cGr := "sve grupe"

   DO CASE
   CASE nGr == 1
      cGr := "rezano"
   CASE nGr == 2
      cGr := "kaljeno"
   CASE nGr == 3
      cGr := "bruseno"
   CASE nGr == 4
      cGr := "IZO"
   CASE nGr == 5
      cGr := "LAMI-RG"
   CASE nGr == 6
      cGr := "emajlirano"
   CASE nGr == 7
      cGr := "buseno"
   CASE nGr == -99
      cGr := "!!! ARTICLE-ERROR !!!"
   ENDCASE

   RETURN cGr


// -----------------------------------------------
// setuj grupu artikla za stampu naloga
// -----------------------------------------------
FUNCTION set_art_docgr( nArt_id, nDoc_no, nDocit_no, lPriprema )

   LOCAL cGroup := ""
   LOCAL aArt := {}
   LOCAL lIsIZO := .F.
   LOCAL lIsBruseno := .F.
   LOCAL lIsBuseno := .F.
   LOCAL lIsKaljeno := .F.
   LOCAL lIsLamiG := .F.
   LOCAL lIsLami := .F.

   rnal_matrica_artikla( nArt_id, @aArt )

   IF aArt == NIL .OR. Len( aArt ) == 0
      cGroup := "0"
      RETURN cGroup
   ENDIF

   // da li je artikal IZO...
   lIsIZO := is_izo( aArt )
   // lami-rg staklo
   lIsLami := is_lami( aArt )
   // lami gotovo staklo - ne laminira RG
   lIsLAMIG := is_lamig( aArt )

   lIsBruseno := is_bruseno( aArt, nDoc_no, nDocIt_no, NIL, lPriprema )
   lIsBuseno := is_staklo_buseno( aArt, nDoc_no, nDocIt_no, NIL, lPriprema )
   lIsKaljeno := is_kaljeno( aArt, nDoc_no, nDocIt_no, NIL, lPriprema )
   lIsEmajl := is_emajl( aArt, nDoc_no, nDocIt_no, NIL, lPriprema )

   // grupe su sljedece
   // 1 - rezano
   // 2 - kaljeno
   // 3 - bruseno
   // 4 - IZO
   // 5 - lami-rg
   // 6 - emajlirano
   // 7 - buseno

   IF lIsEmajl == .T.
      cGroup += "6"
   ENDIF

   IF lIsKaljeno == .T. .AND. lIsEmajl == .F.
      cGroup += "2"
   ENDIF

   IF lIsBruseno == .T. .AND. ( lIsKaljeno == .F. .AND. lIsEmajl == .F. )
      cGroup += "3"
   ENDIF

   IF lIsIZO == .T.
      cGroup += "4"
   ENDIF

   IF lIsLAMI == .T.
      cGroup += "5"
   ENDIF

   IF lIsBuseno == .T.
      cGroup += "7"
   ENDIF


   IF ( lIsKaljeno == .F. ) .AND. ;
         ( lIsBruseno == .F. ) .AND. ;
         ( lIsBuseno == .F. ) .AND. ;
         ( lIsIZO == .F. ) .AND. ;
         ( lIsEmajl == .F. ) .AND. ;
         ( lIsLami == .F. )

      // ako sve ovo nije, onda je rezano
      cGroup += "1"

   ENDIF

   RETURN cGroup


// ---------------------------------------
// da li je staklo IZO
// ---------------------------------------
FUNCTION is_izo( aArticle )

   LOCAL lRet := .F.
   LOCAL nElNo
   LOCAL nGlass
   LOCAL nFrame

   LOCAL cGlCode := AllTrim( gGlassJoker )
   LOCAL cFrCode := AllTrim( gFrameJoker )

   nElNo := aArticle[ Len( aArticle ), 1 ]

   IF nElNo > 1

      nGlass := AScan( aArticle, {| xVar| AllTrim( xVar[ 2 ] ) == cGlCode } )
      nFrame := AScan( aArticle, {| xVar| AllTrim( xVar[ 2 ] ) == cFrCode } )

      IF nGlass <> 0 .AND. nFrame <> 0
         lRet := .T.
      ENDIF

   ENDIF

   RETURN lRet


// ---------------------------------------------
// da li je staklo LAMI - gotovo LAMI staklo
// ---------------------------------------------
FUNCTION is_lamig( aArticle )

   LOCAL lRet := .F.
   LOCAL nLAMI

   LOCAL cGlCode := AllTrim( gGlassJoker )
   LOCAL cLamiCode := AllTrim( gGlLamiJoker )

   nLAMI := AScan( aArticle, {| xVar| AllTrim( xVar[ 2 ] ) == cGlCode .AND. ;
      AllTrim( xVar[ 5 ] ) == cLamiCode } )

   IF nLAMI <> 0
      lRet := .T.
   ENDIF

   RETURN lRet


// ---------------------------------------------
// da li je staklo LAMI - lami-rg staklo
// ramaglas radi laminiranje stakla !
// ---------------------------------------------
FUNCTION is_lami( aArticle )

   LOCAL lRet := .F.
   LOCAL nLAMI

   // folija je joker kod pravljenih stakala u elementu folija
   LOCAL cFrCode := "FL"

   // kod ovog tipa je bitno samo da se nadje Folija u komponenti stakla
   nLAMI := AScan( aArticle, {| xVar| AllTrim( xVar[ 2 ] ) == cFrCode } )

   IF nLAMI <> 0
      lRet := .T.
   ENDIF

   RETURN lRet


// ---------------------------------------
// da li je staklo PLEX
// ---------------------------------------
FUNCTION is_plex( aArticle )

   LOCAL lRet := .F.
   LOCAL nRet

   LOCAL cGlCode := AllTrim( gGlassJoker )
   LOCAL cSGlCode := "PLEX"

   nRet := AScan( aArticle, {| xVar| AllTrim( xVar[ 2 ] ) == cGlCode .AND. ;
      AllTrim( xVar[ 5 ] ) = cSGlCode } )

   IF nRet <> 0
      lRet := .T.
   ENDIF

   RETURN lRet


// ---------------------------------------
// da li je staklo vatroglass
// ---------------------------------------
FUNCTION is_vglass( aArticle )

   LOCAL lRet := .F.
   LOCAL nRet

   LOCAL cGlCode := AllTrim( gGlassJoker )
   LOCAL cSGlCode := "V"

   nRet := AScan( aArticle, {| xVar| AllTrim( xVar[ 2 ] ) == cGlCode .AND. ;
      AllTrim( xVar[ 5 ] ) = cSGlCode } )

   IF nRet <> 0
      lRet := .T.
   ENDIF

   RETURN lRet



// ------------------------------------------------------------
// da li je staklo kaljeno ?
// ------------------------------------------------------------
FUNCTION is_kaljeno( aArticle, nDoc_no, nDocit_no, nDoc_el_no, lPriprema )

   LOCAL lRet := .F.
   LOCAL cSrcJok := AllTrim( gAopKaljenje )

   IF nDoc_el_no == nil
      nDoc_el_no := 0
   ENDIF

   lRet := postoji_obrada_u_artiklu( aArticle, cSrcJok )

   IF lRet == .F.
      lRet := postoji_obrada_u_operacijama( nDoc_no, nDocit_no, nDoc_el_no, cSrcJok, lPriprema )
   ENDIF

   RETURN lRet


// -----------------------------------------------------------
// da li je staklo emajlirano ???
// -----------------------------------------------------------
FUNCTION is_emajl( aArticle, nDoc_no, nDocit_no, nDoc_el_no, lPriprema )

   LOCAL lRet := .F.
   LOCAL cSrcJok := "<A_E>"

   IF nDoc_el_no == nil
      nDoc_el_no := 0
   ENDIF

   lRet := postoji_obrada_u_artiklu( aArticle, cSrcJok )

   IF lRet == .F.
      lRet := postoji_obrada_u_operacijama( nDoc_no, nDocit_no, nDoc_el_no, cSrcJok, lPriprema )
   ENDIF

   RETURN lRet



// -------------------------------------------------------------
// da li je staklo kaljeno ???
// -------------------------------------------------------------
FUNCTION is_bruseno( aArticle, nDoc_no, nDocit_no, nDoc_el_no, lPriprema )

   LOCAL lRet := .F.
   LOCAL cSrcJok := AllTrim( gAopBrusenje )

   IF nDoc_el_no == NIL
      nDoc_el_no := 0
   ENDIF

   lRet := postoji_obrada_u_artiklu( aArticle, cSrcJok )

   IF lRet == .F.
      lRet := postoji_obrada_u_operacijama( nDoc_no, nDocit_no, nDoc_el_no, cSrcJok, lPriprema )
   ENDIF

   RETURN lRet



FUNCTION is_staklo_buseno( aArticle, nDoc_no, nDocit_no, nDoc_el_no, lPriprema )

   LOCAL lRet := .F.
   LOCAL cSrcJok := "<A_BU>"

   IF nDoc_el_no == nil
      nDoc_el_no := 0
   ENDIF

   lRet := postoji_obrada_u_artiklu( aArticle, cSrcJok )

   IF lRet == .F.
      lRet := postoji_obrada_u_operacijama( nDoc_no, nDocit_no, nDoc_el_no, cSrcJok, lPriprema )
   ENDIF

   RETURN lRet



/*
   Opis: Provjerava postoji li obrada unutar matrice artikla

   Usage: postoji_obrada_u_artiklu( aArticle, "<A_B>" )

      Parametri:
      1) matrica sa definicijom elemenata artikla
      2) operacija brušenja "<A_B>"

      Return:
         .T. postoji zadana obrada

   Prerequisites:
     formirana matrica artikla sa funkcijom rnal_setuj_naziv_artikla()

*/
STATIC FUNCTION postoji_obrada_u_artiklu( aArticle, cSrcObrada )

   LOCAL lRet := .F.
   LOCAL nObrada

   nObrada := AScan( aArticle, {| xVar| AllTrim( xVar[ 4 ] ) == cSrcObrada } )
   IF nObrada <> 0
      lRet := .T.
   ENDIF

   RETURN lRet


/*
   Opis: Provjerava da li unutar dodatnih operacija postoji određena obrada.

   Usage: postoji_obrada_u_operacijama( 1, 1, 3, "<A_B>", .T. )

      Parametri:
      1) dokument 1 tabele DOC_OPS
      2) stavka 1
      3) element artikla 3 (treće staklo)
      4) operacija brušenja "<A_B>"
      5) gledati tabelu pripreme ili kumulativ

      Return:
        .T.  postoji zadana obrada

   Prerequisites:

   - Mora biti otvorena Workarea:
       - DOC_OPS ili _DOC_OPS (priprema)

   Napomene:

    - DOC_OPS - tabela operacija dokumenta (kumulativna)
    - _DOC_OPS - tabela operacija dokumenta (priprema)
*/

STATIC FUNCTION postoji_obrada_u_operacijama( nDoc_no, nDocit_no, nDoc_el_no, cSrcObrada, lPriprema )

   LOCAL lRet := .F.
   LOCAL nTArea := Select()
   LOCAL nTable := F_DOC_OPS

   IF lPriprema == NIL
      lPriprema := .F.
   ENDIF

   IF lPriprema
      nTable := F__DOC_OPS
   ENDIF

   SELECT ( nTable )
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no ) + docit_str( nDocit_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_it_no == nDocit_no

      IF nDoc_el_no > 0
         IF field->doc_it_el_ <> nDoc_el_no
            SKIP
            LOOP
         ENDIF
      ENDIF

      nAop_id := field->aop_id

      SELECT aops
      GO TOP
      SEEK aopid_str( nAop_id )

      IF Found() .AND. field->aop_id == nAop_id .AND. AllTrim( field->aop_joker ) == cSrcObrada

         lRet := .T.
         EXIT

      ENDIF

      SELECT ( nTable )
      SKIP
   ENDDO

   SELECT ( nTArea )

   RETURN lRet



// ----------------------------------------------
// printanje naloga, po zadatom broju
// ----------------------------------------------
FUNCTION prn_nal()

   LOCAL GetList := {}
   LOCAL nDoc_no := 0

   Box(, 1, 30 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj naloga:" GET nDoc_no PICT "999999999"
   READ
   BoxC()

   IF LastKey() == K_ESC .OR. nDoc_no = 0
      RETURN .F.
   ENDIF

   rnal_o_tables()

   SELECT docs
   SET ORDER TO TAG "1"
   SEEK docno_str( nDoc_no )

   IF field->doc_no <> nDoc_no
      MsgBeep( "Traženi nalog ne postoji !" )
      RETURN
   ENDIF

   stampa_nalog_proizvodnje( .F., nDoc_no )

   RETURN .T.


FUNCTION rekalkulisi_stavke_za_stampu( lPriprema )

   LOCAL aZpoGn := {}
   LOCAL nTArea := Select()

   RREPLACE field->doc_it_tot WITH Round( c_ukvadrat( field->doc_it_qtt, field->doc_it_hei, field->doc_it_wid ), 2 ), field->doc_it_tm WITH Round( c_duzinski( field->doc_it_qtt, field->doc_it_hei, field->doc_it_wid ), 2 )

   aZpoGN := {}

   rnal_matrica_artikla( field->art_id, @aZpoGN )

   SELECT ( nTArea )

   lBezZaokr := .F.

   IF lBezZaokr == .F.
      lBezZaokr := is_kaljeno( aZpoGN, field->doc_no, field->doc_it_no, NIL, lPriprema )
   ENDIF

   IF lBezZaokr == .F.
      lBezZaokr := is_emajl( aZpoGN, field->doc_no, field->doc_it_no, NIL, lPriprema )
   ENDIF

   IF lBezZaokr == .F.
      lBezZaokr := is_vglass( aZpoGN )
   ENDIF

   IF lBezZaokr == .F.
      lBezZaokr := is_plex( aZpoGN )
   ENDIF

   RREPLACE field->doc_it_zhe WITH obrl_zaok( field->doc_it_hei, aZpoGN, lBezZaokr ), ;
      field->doc_it_zh2 WITH obrl_zaok( field->doc_it_h2, aZpoGN, lBezZaokr ), ;
      field->doc_it_zwi WITH obrl_zaok( field->doc_it_wid, aZpoGN, lBezZaokr ), ;
      field->doc_it_zw2 WITH obrl_zaok( field->doc_it_w2, aZpoGN, lBezZaokr ), ;
      field->doc_it_tot WITH Round( c_ukvadrat( field->doc_it_qtt, field->doc_it_zhe, field->doc_it_zwi, field->doc_it_zh2, field->doc_it_zw2 ), 2 ), ;
      field->doc_it_tm WITH Round( c_duzinski( field->doc_it_qtt, field->doc_it_zhe, field->doc_it_zwi, field->doc_it_zh2, field->doc_it_zw2 ), 2 ), ;
      field->doc_it_net WITH Round( obrl_neto( field->doc_it_tot, aZpoGN ), 2 )

   RETURN
