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

// -------------------------------------------
// export dokumenta
// nDoc_no - dokument broj
// lTemporary - priprema .t., kumulativ .f.
// lWriteRel - upisi rel_ver prvi zapis
// -------------------------------------------
FUNCTION exp_2_lisec( nDoc_no, lTemporary, lWriteRel )

   LOCAL cLocation
   LOCAL cFile := ""
   LOCAL nHnd
   LOCAL nADOCS := F_DOCS
   LOCAL nADOC_IT := F_DOC_IT
   LOCAL nADOC_OP := F_DOC_OPS
   LOCAL nTArea := Select()

   LOCAL aRel
   LOCAL aRelSpec
   LOCAL aPos
   LOCAL aPosSpec
   LOCAL aPo2
   LOCAL aPo2Spec
   LOCAL aOrd
   LOCAL aOrdSpec
   LOCAL aTxt
   LOCAL aTxtSpec
   LOCAL aTx2Spec
   LOCAL aTx3Spec
   LOCAL aGl1
   LOCAL aGl2
   LOCAL aGl3
   LOCAL aGlSpec
   LOCAL aFr1
   LOCAL aFr2
   LOCAL aFrSpec

   LOCAL ix
   LOCAL i
   LOCAL iy

   LOCAL aArticles
   LOCAL aElem

   aRelSpec := _get_rel()
   aOrdSpec := _get_ord()
   aPosSpec := _get_pos()
   aPo2Spec := _get_po2()
   aTxtSpec := _get_txt( 1 )
   aTx2Spec := _get_txt( 2 )
   aTx3Spec := _get_txt( 3 )
   aFrSpec  := _get_frx()
   aGlSpec  := _get_glx()

   IF lTemporary == nil
      lTemporary := .F.
   ENDIF

   IF lWriteRel == nil
      lWriteRel := .F.
   ENDIF

   IF lTemporary == .T.
      nADOCS := F__DOCS
      nADOC_IT := F__DOC_IT
      nADOC_OP := F__DOC_OPS
   ENDIF

   SELECT ( nADOCS )
   GO TOP
   SEEK docno_str( nDoc_no )


   // ako je nalog 0 ili manje, znaci da nema broja nije odstampan !

   IF nDoc_no <= 0
      MsgBeep( "Broj naloga: " + AllTrim( Str( nDoc_no ) ) + "#Odradite prvo stampu naloga !" )
      RETURN
   ENDIF

   // uzmi lokaciju fajla
   g_exp_location( @cLocation )

   // kreiraj fajl exporta....
   IF cre_exp_file( nDoc_no, cLocation, @cFile, @nHnd ) == 0

      SELECT ( nTArea )
      MsgBeep( "Operacija ponistena, nista nije exportovano!" )
      RETURN

   ENDIF


   // WRITE VALUES TO TRF FILE

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "Upisujem osnovne podatke", 50 )

   // upisi <REL>
   aRel := add_rel( "" )
   write_rec( nHnd, aRel, aRelSpec )

   SELECT ( nADOCS )
   nCustId := field->cust_id
   nContId := field->cont_id

   // nadji naziv narucioca
   SELECT customs
   SET FILTER TO
   SET ORDER TO TAG "1"
   GO TOP
   SEEK custid_str( nCustid )

   SELECT contacts
   SET FILTER TO
   SET ORDER TO TAG "1"
   GO TOP
   SEEK contid_str( nContId )

   SELECT ( nADOCS )

   // ako su podaci ispravni
   IF field->cust_id <> 0

      @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "Upisujem podatke o partneru ...... ", 50 )
      // uzmi i upisi osnovne elemente naloga
      aOrd := add_ord( field->doc_no, ;
         field->cust_id, ;
         AllTrim( customs->cust_desc ) + " " + AllTrim( customs->cust_addr ) + " " + AllTrim( customs->cust_tel ), ;
         AllTrim( field->doc_desc ), ;
         AllTrim( field->doc_sh_des ), ;
         AllTrim( field->cont_add_d ), ;
         AllTrim( contacts->cont_desc ) + " " + AllTrim( contacts->cont_tel ), ;
         nil, ;
         field->doc_date, ;
         field->doc_dvr_da, ;
         field->doc_ship_p )

      // UPISI <ORD>
      write_rec( nHnd, aOrd, aOrdSpec )

   ELSE

      SELECT ( nTArea )
      Msgbeep( "Nisu ispravni podaci narudžbe !#Operacija prekinuta..." )

      BoxC()

      RETURN

   ENDIF

   // predji na stavke naloga

   nCount := 0

   SELECT ( nADOC_IT )
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      nTRec := RecNo()

      @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( "Upisujem stavke naloga.....", 50 )

      nDoc_it_no := field->doc_it_no
      nArt_id := field->art_id
      nHeight := field->doc_it_hei
      nWidth := field->doc_it_wid

      SELECT articles
      SET ORDER TO TAG "1"
      SEEK artid_str( nArt_id )

      SELECT ( nADOC_IT )

      cGl1 := ""
      cPosGl1 := ""
      cGl2 := ""
      cPosGl2 := ""
      cGl3 := ""
      cPosGl3 := ""
      cFr1 := ""
      cPosFr1 := ""
      cFr2 := ""
      cPosFr2 := ""
      nGl1h := 0
      nGl1w := 0
      nGl2h := 0
      nGl2w := 0
      nGl3h := 0
      nGl3w := 0
      nUnit_w := nWidth
      nUnit_h := nHeight

      // uzmi i razlozi artikal
      // F4_A12_F3
      cArtDesc := AllTrim( articles->art_desc )

      // napuni aElem sa elemetima artikla
      aElem := {}
      // aelem = { elem_id, descriptin, rec.no }
      _g_art_elements( @aElem, articles->art_id )

      // aArtDesc[1] = F4
      // ....    [2] = A12
      // ....    [3] = F3
      aArtDesc := TokToNiz( cArtDesc, "_" )

      aArticles := {}

      FOR i := 1 TO Len( aArtDesc )

         nElem := aElem[ i, 1 ]
         // sta je ovaj elemenat

         cType := g_grd_by_elid( nElem )

         // aArt { elem_no, art_desc, position,
         // width, height, posx, posy, neww, newh,
         // x, y, type}
         AAdd( aArticles, { nElem, aArtDesc[ i ], AllTrim( Str( ++nCount ) ), ;
            nWidth, nHeight, 0, 0, nWidth, nHeight, 0, 0, cType } )

         @ box_x_koord() + 2, box_y_koord() + 2 SAY PadR( cArtdesc + " - ok stavka - " + AllTrim( Str( i ) ), 50 )

      NEXT

      // pregledaj operacije artikla
      // npr: ako ima brusenje - mora se dodati po 3 mm na dimenzije

      // ima za upis u <PO2>
      lPo2Write := .F.

      SELECT ( nADOC_OP )
      SET ORDER TO TAG "1"
      GO TOP
      SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no )

      DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_it_no == nDoc_it_no

         cJoker := g_aatt_joker( field->aop_att_id )

         SELECT ( nADOC_OP )

         // moramo znati i koji je element
         nElemPos := field->doc_it_el_

         // kod brusenja dodaj na dimenzije po 3mm
         IF cJoker == "<A_B>"

            lPo2Write := .T.

            nScan := AScan( aArticles, {|xvar| xvar[ 1 ] == nElemPos } )

            IF nScan <> 0

               // ako su init.vrijednosti spucaj mu
               // tacnu h i w mjeru

               IF aArticles[ nScan, 8 ] = 0
                  aArticles[ nScan, 8 ] := nWidth
               ENDIF
               IF aArticles[ nScan, 9 ] = 0
                  aArticles[ nScan, 9 ] := nHeight
               ENDIF

               // upisi preracunate vrijednosti
               // u matricu...

               nHtmp := dodaj_za_bruseno( nHeight )
               nWtmp := dodaj_za_bruseno( nWidth )

               // povecanje
               aArticles[ nScan, 6 ] += gBrusenoStakloDodaj
               aArticles[ nScan, 7 ] += gBrusenoStakloDodaj

               // nove dimenzije
               aArticles[ nScan, 8 ] += gBrusenoStakloDodaj
               aArticles[ nScan, 9 ] += gBrusenoStakloDodaj
            ENDIF
         ENDIF

         // kod stakala sa prepustom - takodjer gledaj druge dimenzije
         IF "A_PREP" $ cJoker

            lPo2Write := .T.

            cValue := field->aop_value

            nScan := AScan( aArticles, {|xvar| xvar[ 1 ] == nElemPos } )


            nH := 0
            nW := 0

            nHraz := 0
            nWraz := 0

            izracunaj_dimenzije_prepusta( cValue, @nW, @nH )

            nHraz := ( nH - nHeight )
            nWraz := ( nW - nWidth )

            IF nScan <> 0

               IF aArticles[ nScan, 8 ] = 0
                  aArticles[ nScan, 8 ] := nWidth
               ENDIF

               IF aArticles[ nScan, 9 ] = 0
                  aArticles[ nScan, 9 ] := nHeight
               ENDIF

               // povecanje
               aArticles[ nScan, 6 ] += nWraz
               aArticles[ nScan, 7 ] += nHraz

               // nova dimenzija
               aArticles[ nScan, 8 ] += nWraz
               aArticles[ nScan, 9 ] += nHraz
            ENDIF

         ENDIF

         SKIP
      ENDDO

      SELECT ( nADOC_IT )
      GO ( nTRec )

      // napuni varijable
      FOR ix := 1 TO Len( aArticles )

         IF ix == 1
            cGl1 := aArticles[ ix, 2 ]
            cPosGl1 := aArticles[ ix, 3 ]
            nGl1w := aArticles[ ix, 8 ]
            nGl1h := aArticles[ ix, 9 ]
         ENDIF

         IF ix == 2
            cFr1 := aArticles[ ix, 2 ]
            cPosFr1 := aArticles[ ix, 3 ]
         ENDIF

         IF ix == 3
            cGl2 := aArticles[ ix, 2 ]
            cPosGl2 := aArticles[ ix, 3 ]
            nGl2w := aArticles[ ix, 8 ]
            nGl2h := aArticles[ ix, 9 ]
         ENDIF

         IF ix == 4
            cFr2 := aArticles[ ix, 2 ]
            cPosFr2 := aArticles[ ix, 3 ]
         ENDIF

         IF ix == 5
            cGl3 := aArticles[ ix, 2 ]
            cPosGl3 := aArticles[ ix, 3 ]
            nGl3w := aArticles[ ix, 8 ]
            nGl3h := aArticles[ ix, 9 ]
         ENDIF
      NEXT

      // samo ako su dimenzije ispravne.....
      IF ( field->doc_it_wid <> 0 .AND. ;
            field->doc_it_hei <> 0 .AND. ;
            field->doc_it_qtt <> 0 )

         // ubaci u matricu podatke
         aPos := add_pos( field->doc_it_no, "", nil, field->doc_it_qtt, nGl1w, nGl1h, cPosGl1, cPosFr1, cPosGl2, cPosFr2, cPosGl3 )

         // upisi <POS>
         write_rec( nHnd, aPos, aPosSpec )


      ENDIF

      // da li ima za dodatne informacije <PO2> ?
      IF lPo2Write == .T.

         aPo2 := add_po2( "", ;
            nGl1w, ;
            nGl1h, ;
            0, 0, 0, 0, ;
            0, ;
            0, ;
            0, 0, ;
            nGl2w, ;
            nGl2h, ;
            0, 0, 0, 0, ;
            abs_unit( nGl2w, nGl1w ), ;
            abs_unit( nGl2h, nGl1h ), ;
            0, 0, ;
            0, 0, ;
            nGl3w, ;
            nGl3h, ;
            0, 0, 0, 0, ;
            abs_unit( nGl3w, nGl2w ), ;
            abs_unit( nGl3h, nGl2h ), ;
            0, 0, ;
            0, 0 )

         write_rec( nHnd, aPo2, aPo2Spec )


      ENDIF

      upisi_glx_frx( nHnd, cGl1, cGl2, cGl3, cFr1, cFr2, aGlSpec, aFrSpec )

      // ako ima napomena...
      IF !Empty( field->doc_it_des )

         // upisi <TXT> ostale informacije
         aTxt := add_txt( 1, AllTrim( field->doc_it_des ) )
         write_rec( nHnd, aTxt, aTxtSpec )

      ENDIF

      SELECT ( nADOC_IT )
      GO ( nTRec )

      SKIP

   ENDDO

   BoxC()

   SELECT ( nADOC_IT )
   GO TOP

   // zatvori fajl
   close_exp_file( nHnd )

   SELECT ( nTArea )

   MsgBeep( "Export završen ... kreiran je fajl#" + IIF( Len( cLocation ) > 20,  PadR( cLocation, 20 ) + "...", cLocation ) + cFile )

   RETURN

/*
 step vrijednost kod razlicite dimenzije stakla
 nGl1 - vrijednost za staklo
 nUnit - vrijednost za kompletnu jedinicu
*/
STATIC FUNCTION abs_unit( nGl1, nUnit )

   LOCAL nStep := 0

   IF ( nGl1 <> 0 ) .AND. ( nGl1 <> nUnit )
      nStep := Abs( nGl1 - nUnit )
   ENDIF

   RETURN nStep


STATIC FUNCTION  upisi_glx_frx( nHnd, cGl1, cGl2, cGl3, cFr1, cFr2, aGlSpec, aFrSpec )

   // upisi <GLx>, <FRx>
   IF !Empty( cGl1 )

      aGl1 := add_glx( "1", cGl1 )
      write_rec( nHnd, aGl1, aGlSpec )

   ENDIF

   IF !Empty( cFr1 )

      aFr1 := add_frx( "1", cFr1 )
      write_rec( nHnd, aFr1, aFrSpec )

   ENDIF

   IF !Empty( cGl2 )

      aGl2 := add_glx( "2", cGl2 )
      write_rec( nHnd, aGl2, aGlSpec )

   ENDIF

   IF !Empty( cFr2 )

      aFr2 := add_frx( "2", cFr2 )
      write_rec( nHnd, aFr2, aFrSpec )

   ENDIF

   IF !Empty( cGl3 )

      aGl3 := add_glx( "3", cGl3 )
      write_rec( nHnd, aGl3, aGlSpec )

   ENDIF

   RETURN


STATIC FUNCTION dodaj_za_bruseno( nDimension )

   RETURN nDimension + gBrusenoStakloDodaj
