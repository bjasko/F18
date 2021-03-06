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


STATIC l_open_dbedit
STATIC par_count
STATIC _art_id
STATIC l_quick_find
STATIC __art_sep
STATIC __mc_sep
STATIC __qf_cond
STATIC __aop_sep


// ------------------------------------------------
// otvara sifrarnik artikala
// cId - artikal id
// ------------------------------------------------
FUNCTION s_articles( cId, lAutoFind, lQuickFind )

   LOCAL nBoxX := f18_max_rows() - 4
   LOCAL nBoxY := f18_max_cols() - 4
   LOCAL nTArea
   LOCAL cHeader
   LOCAL cFooter
   LOCAL cOptions := ""
   LOCAL cTag := "1"
   LOCAL GetList := {}
   PRIVATE ImeKol
   PRIVATE Kol

   par_count := PCount()
   l_open_dbedit := .T.

   __art_sep := "_"
   __aop_sep := "-"
   __mc_sep := "_"
   __qf_cond := Space( 200 )

   IF lAutoFind == nil
      lAutoFind := .F.
   ENDIF

   IF lQuickFind == nil
      lQuickFind := .F.
   ENDIF

   l_quick_find := lQuickFind

   IF ( par_count > 0 )

      rnal_sifra_bez_tacke( @cId )

      IF lAutoFind == .F.

         l_open_dbedit := .F.

      ENDIF

      IF cId <> Val( artid_str( 0 ) ) .AND. lAutoFind == .T.

         l_open_dbedit := .F.

         lAutoFind := .F.

      ENDIF

   ENDIF

   nTArea := Select()

   O_ARTICLES

   cHeader := "Artikli /"
   cFooter := ""

   SELECT articles
   SET RELATION TO
   SET FILTER TO

   // id: sort by art_id
   SET ORDER TO TAG "1"

   GO TOP

   IF !l_open_dbedit

      SEEK artid_str( cId )

      IF !Found()
         l_open_dbedit := .T.
         GO TOP
      ENDIF

   ENDIF

   IF l_open_dbedit

      set_a_kol( @ImeKol, @Kol )

      cOptions += "cN-novi "
      cOptions += "cT-brisi "
      cOptions += "F2-ispr. "
      cOptions += "F3-isp.naz. "
      cOptions += "F4-dupl. "
      cOptions += "Q-br.traz"

      Box(, nBoxX, nBoxY, .T. )

      @ box_x_koord() + nBoxX + 1, box_y_koord() + 2 SAY cOptions

      my_browse(, nBoxX, nBoxY, {|| key_handler( Ch ) }, cHeader, cFooter, .T.,,,, 7 )

      BoxC()

   ENDIF

   cId := field->art_id

   SELECT ( nTArea )

   RETURN



STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { PadC( "ID/MC", 10 ), {|| sif_idmc( art_id ) }, "art_id", {|| rnal_uvecaj_id( @wArt_id, "ART_ID" ), .F. }, {|| .T. } } )
   AAdd( aImeKol, { "sifra :: puni naziv", {|| AllTrim( art_desc ) + " :: " + Upper( art_full_d ) }, "art_desc" } )
   AAdd( aImeKol, { "labela opis", {|| AllTrim( art_lab_de ) }, "art_desc" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


STATIC FUNCTION key_handler()

   LOCAL nArt_id := 0
   LOCAL cArt_desc := ""
   LOCAL nArt_type := 0
   LOCAL cSchema := Space( 20 )
   LOCAL nTRec := RecNo()
   LOCAL nRet

   box_preview( f18_max_rows() - 9, 2, f18_max_cols() - 3 )

   DO CASE

   CASE l_quick_find == .T.

      brza_pretraga_artikla()

      l_quick_find := .F.

      Tb:RefreshAll()

      WHILE !TB:stabilize()
      END

      box_preview( f18_max_rows() - 9, 2, f18_max_cols() - 3 )

      RETURN DE_CONT

   CASE Ch == K_CTRL_N

      SELECT articles
      SET FILTER TO
      SET RELATION TO

      IF setuj_novi_id_tabele( @nArt_id, "ART_ID", NIL, "FULL" ) == 0
         RETURN DE_CONT
      ENDIF

      odaberi_tip_artikla( @nArt_type, @cSchema )

      IF s_elements( nArt_id, .T., nArt_Type, cSchema ) == 1
         SELECT articles
         GO BOTTOM
      ELSE
         SELECT articles
         GO ( nTRec )
      ENDIF

      RETURN DE_REFRESH

   CASE Ch == K_F2

      IF s_elements( field->art_id ) == 1

         SELECT articles
         SET ORDER TO TAG "1"
         GO ( nTRec )

         RETURN DE_REFRESH

      ENDIF

      SELECT articles
      SET ORDER TO TAG "1"
      GO ( nTRec )

      RETURN DE_CONT

   CASE Ch == K_F3

      IF ispravi_opis_artikla( field->art_id ) == 1
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == K_F4

      SELECT articles

      nArt_new := rnal_dupliciraj_artikal( articles->art_id )

      IF nArt_new > 0 .AND. s_elements( nArt_new, .T. ) == 1

         SELECT articles
         SET ORDER TO TAG "1"
         GO ( nTRec )

         RETURN DE_REFRESH

      ENDIF

      SELECT articles
      SET ORDER TO TAG "1"
      GO ( nTRec )
      RETURN DE_REFRESH

   CASE Ch == K_CTRL_T

      IF rnal_brisi_artikal( field->art_id, .T. ) == 1
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT


   CASE Ch == K_ENTER

      IF par_count > 0
         RETURN DE_ABORT
      ENDIF

   CASE Upper( Chr( Ch ) ) == "Q"

      IF brza_pretraga_artikla() == 1
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT

   ENDCASE

   RETURN DE_CONT



STATIC FUNCTION odaberi_tip_artikla( nType, cSchema )

   LOCAL nX := 1
   PRIVATE GetList := {}

   cSchema := Space( 20 )
   nType := 0

   Box(, 10, 50 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Odabir vrste artikla"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   (1) jednostruko staklo"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   (2) dvostruko staklo"

   ++nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "   (3) trostruko/višestruko staklo"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   (0) ostalo"

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY " selekcija:" GET nType VALID nType >= 0 .AND. nType <= 3 PICT "9"

   READ

   IF nType <> 0
      @ box_x_koord() + nX, box_y_koord() + 18 SAY8 "šema:" GET cSchema VALID odaberi_shemu_artikla( @cSchema, nType )
   ENDIF

   READ

   BoxC()

   RETURN


STATIC FUNCTION odaberi_shemu_artikla( cSchema, nType )

   LOCAL aSch
   LOCAL i
   LOCAL nSelect := 0
   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL izbor := 1

   aSch := rnal_shema_artikla_za_tip( nType )

   IF ( aSch == NIL .OR. Len( aSch ) == 0 )

      MsgBeep( "Ne postoje definisane šeme, koristim standardnu šemu za tip " + AllTrim( Str( nType ) ) )

      IF nType == 1
         cSchema := "G"
      ELSEIF nType == 2
         cSchema := "G-F-G"
      ELSEIF nType == 3
         cSchema := "G-F-G-F-G"
      ENDIF

      RETURN .T.

   ENDIF


   FOR i := 1 TO Len( aSch )

      cPom := PadR( aSch[ i, 1 ], 30 )

      AAdd( opc, cPom )
      AAdd( opcexe, {|| nSelect := izbor, izbor := 0 } )

   NEXT

   f18_menu( "schema", .F., @izbor, opc, opcexe )

   IF LastKey() <> K_ESC .OR. nSelect > 0
      cSchema := AllTrim( aSch[ nSelect, 1 ] )
   ENDIF

   RETURN .T.



STATIC FUNCTION brza_pretraga_artikla()

   LOCAL cFilt := ".t."

   IF brza_pretraga_uslov() == 0
      RETURN 0
   ENDIF

   IF brza_pretraga_filter( @cFilt ) == 0
      RETURN 0
   ENDIF

   SELECT articles
   SET FILTER TO
   GO TOP

   IF cFilt == ".t."

      SET FILTER TO
      GO TOP
      nRet := 0

   ELSE

      MsgO( "Vrsim selekciju artikala... sačekajte trenutak...." )

      cFilt := StrTran( cFilt, ".t. .and.", "" )

      SET FILTER to &cFilt
      SET ORDER TO TAG "2"

      GO TOP

      MsgC()
      nRet := 1

   ENDIF

   RETURN nRet



STATIC FUNCTION brza_pretraga_filter( cFilter )

   LOCAL nRet := 0
   LOCAL aTmp := {}
   LOCAL aArtTmp := {}
   LOCAL i
   LOCAL nCnt

   IF Empty( __qf_cond )
      RETURN nRet
   ENDIF

   cCond := AllTrim( __qf_cond )

   // F4*F4;F2*F4; => aTmp[1] = F4*F4
   // => aTmp[2] = F2*F4

   aTmp := TokToNiz( cCond, ";" )

   FOR i := 1 TO Len( aTmp )

      IF ( i == 1 )

         cFilter += " .and. "

      ELSE

         cFilter += " .or. "

      ENDIF


      IF "*" $ aTmp[ i ]

         aCountTmp := TokToNiz( cCond, "*" )
         nCount := Len( aCountTmp )

         // "*F4"

         IF Left( aTmp[ i ], 1 ) == "*" .AND. nCount == 1

            cTmp := Upper( AllTrim( aCountTmp[ 1 ] ) )

            cFilter += dbf_quote( "_" + cTmp )
            cFilter += " $ "
            cFilter += "ALLTRIM(UPPER(art_desc))"


            // "F4*"

         ELSEIF Right( aTmp[ i ], 1 ) == "*" .AND. nCount == 1

            cTmp := Upper( AllTrim( aCountTmp[ i ] ) )
            nTmp := Len( cTmp )

            cFilter += "LEFT(ALLTRIM(UPPER(art_desc)), " + AllTrim( Str( nTmp ) ) + ")"
            cFilter += " = "
            cFilter += dbf_quote( cTmp )


         ELSEIF nCount > 1

            aArtTmp := TokToNiz( aTmp[ i ], "*" )

            FOR iii := 1 TO Len( aArtTmp )

               IF iii == 1

                  cTmp := Upper( AllTrim( aArtTmp[ iii ] ) )
                  nTmp := Len( cTmp )

                  cFilter += " ( "
                  cFilter += "LEFT(ALLTRIM(UPPER(art_desc)), " + AllTrim( Str( nTmp ) ) + ")"
                  cFilter += " = "
                  cFilter += dbf_quote( cTmp )

               ELSEIF iii > 1

                  cTmp := Upper( AllTrim( aArtTmp[ iii ] ) )
                  cFilter += " .and. " + dbf_quote( "_" + cTmp )
                  cFilter += " $ "
                  cFilter += "ALLTRIM(UPPER(art_desc))"

               ENDIF

               IF iii == Len( aArtTmp )
                  cFilter += " ) "
               ENDIF
            NEXT

         ELSE

         ENDIF

      ELSE

         // cisi unos, gleda se samo LEFT( nnn )

         cTmp := AllTrim( aTmp[ i ] )
         nTmp := Len( cTmp )

         cFilter += "LEFT(ALLTRIM(UPPER(art_desc)), " + AllTrim( Str( nTmp ) ) + ")"
         cFilter += " = "
         cFilter += dbf_quote( Upper( cTmp ) )

      ENDIF

   NEXT

   IF cFilter == ".t."
      nRet := 0
   ELSE
      nRet := 1
   ENDIF

   RETURN nRet


STATIC FUNCTION brza_pretraga_uslov()

   LOCAL nBoxX := 6
   LOCAL nBoxY := 70
   LOCAL nX := 1
   PRIVATE GetList := {}

   Box(, nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "===>>> Brza pretraga artikala ===>>>"

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "uslov:" GET __qf_cond VALID validacija_uslova( __qf_cond ) PICT "@S60!"

   READ
   BoxC()

   ESC_RETURN 0

   RETURN 1


STATIC FUNCTION validacija_uslova( cCond )

   LOCAL lRet := .T.

   IF Empty( cCond )
      lRet := .F.
   ENDIF

   IF lRet == .F. .AND. Empty( cCond )
      MsgBeep( "Uslov ne može biti prazno !" )
   ENDIF

   RETURN lRet




STATIC FUNCTION ispravi_opis_artikla( nArt_id )

   LOCAL cArt_desc := PadR( field->art_desc, 100 )
   LOCAL cArt_mcode := PadR( field->match_code, 10 )
   LOCAL cArt_full_desc := PadR( field->art_full_d, 250 )
   LOCAL cArt_lab_desc := PadR( field->art_lab_de, 200 )
   LOCAL cDBFilter := dbFilter()
   LOCAL nTRec := RecNo()
   LOCAL nRet := 0
   LOCAL _rec
   LOCAL hParams

   IF ispravka_artikla_box( @cArt_desc, @cArt_full_desc, @cArt_lab_desc, ;
         @cArt_mcode ) == 1

      run_sql_query( "BEGIN" )

      IF !f18_lock_tables( { "articles" }, .T. )
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Ne mogu zaključati tabelu articles !#Prekidam operaciju." )
         RETURN nRet
      ENDIF

      SET FILTER TO
      SET ORDER TO TAG "1"
      GO TOP

      SEEK artid_str( nArt_id )

      _rec := dbf_get_rec()

      _rec[ "art_desc" ] := cArt_desc
      _rec[ "art_full_d" ] := cArt_full_desc
      _rec[ "art_lab_de" ] := cArt_lab_desc
      _rec[ "match_code" ] := cArt_mcode

      IF !update_rec_server_and_dbf( "articles", _rec, 1, "CONT" )
         run_sql_query( "ROLLBACK" )
      ELSE
         hParams := hb_Hash()
         hParams[ "unlock" ] :=  { "articles" }
         run_sql_query( "COMMIT", hParams )
         nRet := 1
      ENDIF

      SET ORDER TO TAG "1"
      SET FILTER to &cDBFilter
      GO ( nTRec )

   ENDIF

   RETURN nRet


// ----------------------------------------
// prikazi info artikla u box preview
// ----------------------------------------
STATIC FUNCTION box_preview( nX, nY, nLen )

   LOCAL aDesc := {}
   LOCAL i

   aDesc := TokToNiz( articles->art_full_d, ";" )

   @ nX, nY SAY PadR( "ID: " + artid_str( articles->art_id ) + Space( 3 ) + "MATCH CODE: " + articles->match_code, nLen ) COLOR "GR+/G"

   FOR i := 1 TO 6
      @ nX + i, nY SAY PadR( "", nLen ) COLOR "BG+/B"
   NEXT

   FOR i := 1 TO Len( aDesc )

      @ nX + i, nY SAY PadR( " * " + AllTrim( aDesc[ i ] ), nLen ) COLOR "BG+/B"

   NEXT

   RETURN


// -------------------------------
// convert art_id to string
// -------------------------------
FUNCTION artid_str( nId )
   RETURN Str( nId, 10 )


// -------------------------------
// get art_desc by art_id
// -------------------------------
FUNCTION g_art_desc( nArt_id, lEmpty, lFullDesc )

   LOCAL cArtDesc := "?????"
   LOCAL nTArea := Select()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cArtDesc := ""
   ENDIF

   IF lFullDesc == nil
      lFullDesc := .T.
   ENDIF

   O_ARTICLES
   SELECT articles
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   IF Found()
      IF lFullDesc == .T.
         IF !Empty( field->art_full_d )
            cArtDesc := AllTrim( field->art_full_d )
         ENDIF
      ELSE
         IF !Empty( field->art_desc )
            cArtDesc := AllTrim( field->art_desc )
         ENDIF
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cArtDesc




STATIC FUNCTION brisi_stavku_iz_articles( nArt_id )

   LOCAL lOk := .T.
   LOCAL _rec

   _rec := dbf_get_rec()

   lOk := delete_rec_server_and_dbf( "articles", _rec, 1, "CONT" )

   RETURN lOk



STATIC FUNCTION brisi_stavke_iz_elemenata_i_operacija( nArt_id )

   LOCAL lOk := .T.
   LOCAL nElTekRec, nAttTekRec, nAopTekRec, nEl_id
   LOCAL _rec

   SELECT elements
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   DO WHILE !Eof() .AND. field->art_id == nArt_id

      SKIP 1
      nElTekRec := RecNo()
      SKIP -1

      nEl_id := field->el_id

      SELECT e_att
      SET ORDER TO TAG "1"
      GO TOP
      SEEK elid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id

         SKIP 1
         nAttTekRec := RecNo()
         SKIP -1

         _rec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

         IF !lOk
            RETURN lOk
         ENDIF

         GO ( nAttTekRec )

      ENDDO

      SELECT e_aops
      SET ORDER TO TAG "1"
      GO TOP
      SEEK elid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id
         SKIP 1
         nAopTekRec := RecNo()
         SKIP -1
         _rec := dbf_get_rec()
         lOk := delete_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

         IF !lOk
            RETURN lOk
         ENDIF

         GO ( nAopTekRec )
      ENDDO

      SELECT elements

      _rec := dbf_get_rec()
      lOk := delete_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      GO ( nElTekRec )

   ENDDO

   RETURN lOk



FUNCTION rnal_ima_li_artikla_u_dokumentima( nArt_id )

   LOCAL lExist := .F.
   LOCAL cWhere

   cWhere := " art_id = " + AllTrim( Str( nArt_id ) )

   IF table_count( F18_PSQL_SCHEMA_DOT + "rnal_doc_it", cWhere ) > 0
      lExist := .T.
   ENDIF

   RETURN lExist




STATIC FUNCTION rnal_brisi_artikal( nArt_id, lChkKum, lSilent )

   LOCAL nEl_id
   LOCAL _del_rec, _field_ids, _where_bl
   LOCAL _el_tek, _att_tek, _aops_tek
   LOCAL lOk := .T.
   LOCAL hParams

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF lChkKum == nil
      lChkKum := .F.
   ENDIF

   IF lChkKum == .T.

      IF rnal_ima_li_artikla_u_dokumentima( nArt_id )
         MsgBeep( "Artikal se nalazi u ažuriranim nalozima.#BRISANJE ONEMOGUĆENO !" )
         SELECT articles
         RETURN 0
      ENDIF

   ENDIF

   SELECT articles
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   IF Found()

      IF !lSilent .AND. Pitanje(, "Izbrisati artikal iz šifarnika (D/N) ?", "N" ) == "N"
         RETURN 0
      ENDIF

      run_sql_query( "BEGIN" )

      IF !f18_lock_tables( { "articles", "elements", "e_att", "e_aops" }, .T. )
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju." )
         RETURN 0
      ENDIF

      lOk := brisi_stavku_iz_articles( nArt_id )

      IF lOk
         lOk := brisi_stavke_iz_elemenata_i_operacija( nArt_id )
      ENDIF

      IF lOk
         hParams := hb_Hash()
         hParams[ "unlock" ] :=  { "articles", "elements", "e_att", "e_aops" }
         run_sql_query( "COMMIT", hParams )

      ELSE
         run_sql_query( "ROLLBACK" )
      ENDIF

   ENDIF

   SELECT articles

   RETURN 1



STATIC FUNCTION rnal_dupliciraj_artikal( nArt_id )

   LOCAL nArtNewid
   LOCAL nElRecno
   LOCAL nOldEl_id
   LOCAL nElGr_id
   LOCAL nElNewid := 0
   LOCAL _rec
   LOCAL lOk := .T.
   LOCAL hParams

   IF Pitanje(, "Duplicirati artikal (D/N)?", "D" ) == "N"
      RETURN -1
   ENDIF

   SELECT articles
   SET FILTER TO
   SET RELATION TO

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "articles", "elements", "e_att", "e_aops" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju." )
      RETURN -1
   ENDIF

   IF setuj_novi_id_tabele( @nArtNewid, "ART_ID" ) == 0
      RETURN -1
   ENDIF

   SELECT elements
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   DO WHILE !Eof() .AND. field->art_id == nArt_id

      nElNewId := 0
      nOldEl_id := field->el_id
      nElGr_id := field->e_gr_id

      SKIP 1
      nElRecno := RecNo()
      SKIP -1

      // daj mi novi element
      setuj_novi_id_tabele( @nElNewid, "EL_ID" )

      _rec := dbf_get_rec()

      _rec[ "art_id" ] := nArtNewid
      _rec[ "e_gr_id" ] := nElGr_id

      lOk := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

      IF lOk
         lOk := rnal_dupliciraj_atribute_artikla( nOldEl_id, nElNewid )
      ENDIF

      IF lOk
         lOk := rnal_dupliciraj_operacije_artikla( nOldEl_id, nElNewid )
      ENDIF

      IF !lOk
         EXIT
      ENDIF

      SELECT elements
      GO ( nElRecno )

   ENDDO

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] :=  { "articles", "elements", "e_att", "e_aops" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN nArtNewid




STATIC FUNCTION rnal_dupliciraj_atribute_artikla( nOldEl_id, nNewEl_id )

   LOCAL nElRecno
   LOCAL nNewAttId := 0
   LOCAL _rec
   LOCAL lOk := .T.

   SELECT e_att
   SET ORDER TO TAG "1"
   GO TOP

   SEEK elid_str( nOldEl_id )

   DO WHILE !Eof() .AND. field->el_id == nOldEl_id

      SKIP 1
      nElRecno := RecNo()
      SKIP -1

      _rec := dbf_get_rec()

      setuj_novi_id_tabele( @nNewAttId, "EL_ATT_ID" )

      _rec := dbf_get_rec()

      _rec[ "el_att_id" ] := nNewAttId
      _rec[ "el_id" ] := nNewEl_id

      lOk := update_rec_server_and_dbf( "e_att", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SELECT e_att
      GO ( nElRecno )

   ENDDO

   RETURN lOk


STATIC FUNCTION rnal_dupliciraj_operacije_artikla( nOldEl_id, nNewEl_id )

   LOCAL nElRecno
   LOCAL nNewAopId := 0
   LOCAL _rec
   LOCAL lAuto := .T.
   LOCAL lOk := .T.

   SELECT e_aops
   SET ORDER TO TAG "1"
   GO TOP

   SEEK elid_str( nOldEl_id )

   DO WHILE !Eof() .AND. field->el_id == nOldEl_id

      nNewAopId := 0

      SKIP 1
      nElRecno := RecNo()
      SKIP -1

      _rec := dbf_get_rec()

      setuj_novi_id_tabele( @nNewAopId, "EL_OP_ID", lAuto )

      _rec[ "el_op_id" ] := nNewAopid
      _rec[ "el_id" ] := nNewEl_id

      lOk := update_rec_server_and_dbf( "e_aops", _rec, 1, "CONT" )

      IF !lOk
         EXIT
      ENDIF

      SELECT e_aops
      GO ( nElRecno )

   ENDDO

   RETURN lOk




// -----------------------------------------
// filuje matricu aAttr
//
// vars:
// aArr - matrica, proslijedjuje se po ref.
// nElNo - broj elementa artikla
// cGrValCode - kod vrijednosti grupe
// cGrVal - vrijednost grupe (puni opis)
// cAttJoker - joker atributa
// cAttValCode - kod vrijednosti atributa
// cAttVal - vrijednost atributa (puni opis)
// -----------------------------------------
STATIC FUNCTION _f_a_attr( aArr, nElNo, cGrValCode, cGrVal, ;
      cAttJoker, cAttValCode, cAttVal )

   AAdd( aArr, { nElNo, cGrValCode, cGrVal, cAttJoker, cAttValCode, cAttVal } )

   RETURN


// ----------------------------------------------
// setovanje opisa artikla na osnovu tabela
// ELEMENTS, E_AOPS, E_ATT
//
// nArt_id - artikal id
// lNew - novi artikal
// lAuto - auto generacija naziva
// ----------------------------------------------
//
// aArr sadrzi:
// { nElNo, cGrValCode, cGrVal, cAttJoker, cAttValCode, cAttVal }

FUNCTION rnal_setuj_naziv_artikla( nArt_id, lNew, lAuto, aAttr, lOnlyArr )

   LOCAL nRet := 0
   LOCAL cArt_code := ""
   LOCAL cArt_desc := ""
   LOCAL cArt_mcode := ""

   IF aAttr == NIL
      aAttr := {}
   ENDIF

   rnal_matrica_artikla( nArt_id, @aAttr )

   IF aAttr == NIL .OR. Len( aAttr ) == 0
      RETURN nRet
   ENDIF

   IF lAuto == NIL
      lAuto := .F.
   ENDIF

   IF lOnlyArr == NIL
      lOnlyArr := .F.
   ENDIF

   IF lOnlyArr == .F.

      rnal_setuj_naziv_artikla_iz_pravila( aAttr, @cArt_code, @cArt_desc, @cArt_mcode )

      IF lAuto == .T.
         nRet := rnal_azuriraj_artikal_auto( nArt_id, cArt_code, cArt_desc, cArt_mcode )
      ELSE
         nRet := rnal_azuriraj_artikal( nArt_id, cArt_code, cArt_desc, cArt_mcode, lNew )
      ENDIF

   ENDIF

   RETURN nRet




FUNCTION rnal_matrica_artikla( nArt_id, aAttr )

   LOCAL nEl_id
   LOCAL nEl_gr_id
   LOCAL cGr_code
   LOCAL cGr_desc
   LOCAL nE_gr_att
   LOCAL nE_gr_val
   LOCAL cAttValCode
   LOCAL cAttVal
   LOCAL cAttJoker
   LOCAL cAopJoker
   LOCAL cAop
   LOCAL cAopCode
   LOCAL cAopAtt
   LOCAL cAopAttCode
   LOCAL nCount := 0
   LOCAL nElCount := 0

   IF aAttr == nil
      aAttr := {}
   ENDIF

   // article code separator
   __art_sep := "_"
   // puni naziv separator
   __mc_sep := ";"
   // add ops separator
   __aop_sep := "-"

   SELECT elements
   SET FILTER TO
   SELECT e_att
   SET FILTER TO
   SELECT e_aops
   SET FILTER TO
   SELECT aops
   SET FILTER TO
   SELECT aops_att
   SET FILTER TO

   // elementi...
   SELECT elements
   SET ORDER TO TAG "1"
   SEEK artid_str( nArt_id )

   DO WHILE !Eof() .AND. field->art_id == nArt_id

      ++ nElCount

      nEl_id := field->el_id
      nEl_gr_id := field->e_gr_id
      cGr_code := AllTrim( g_e_gr_desc( nEl_gr_id, nil, .F. ) )
      cGr_desc := AllTrim( g_e_gr_desc( nEl_gr_id ) )

      SELECT e_att
      SET ORDER TO TAG "1"
      GO TOP
      SEEK elid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id
         nE_gr_val := field->e_gr_vl_id
         cAttValCode := AllTrim( g_e_gr_vl_desc( nE_gr_val, nil, .F. ) )
         cAttVal := AllTrim( g_e_gr_vl_desc( nE_gr_val ) )
         nE_gr_att := g_gr_att_val( nE_gr_val )
         cAtt_desc := AllTrim( g_gr_at_desc( nE_gr_att ) )
         cAttJoker := g_gr_att_joker( nE_gr_att )

         _f_a_attr( @aAttr, nElCount, cGr_code, cGr_desc, ;
            cAttJoker, cAttValCode, cAttVal )

         SKIP

      ENDDO

      SELECT e_aops
      SET ORDER TO TAG "1"
      GO TOP
      SEEK elid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id

         nAop_id := field->aop_id

         cAopCode := AllTrim( g_aop_desc( nAop_id, nil, .F. ) )
         cAop := AllTrim( g_aop_desc( nAop_id ) )
         cAopJoker := AllTrim( g_aop_joker( nAop_id ) )
         nAop_att_id := field->aop_att_id
         cAopAttCode := AllTrim( g_aop_att_desc( nAop_att_id, nil, .F. ) )
         IF Empty( cAopAttCode )
            cAopAttCode := cAopCode
         ENDIF
         cAopAtt := AllTrim( g_aop_att_desc( nAop_att_id ) )

         IF Empty( cAopAtt )
            cAopAtt := cAop
         ENDIF

         rem_jokers( @cAopAtt )

         _f_a_attr( @aAttr, nElCount, cGr_code, cGr_desc, ;
            cAopJoker, cAopAttCode, ;
            cAopAtt )

         SKIP
      ENDDO

      SELECT elements
      SKIP

      ++ nCount

   ENDDO

   RETURN .T.



// ---------------------------------------------------------
// vraca naziv elementa unutar kompozicije iz ARR
// aArr - matrica sa definicijom artikla
// nEl_count - redni broj trazenog elementa
// ---------------------------------------------------------
FUNCTION g_el_descr( aArr, nEl_count )

   LOCAL nTotElem
   LOCAL cElemCode
   LOCAL i
   LOCAL xRet := ""
   LOCAL cTmp
   LOCAL nTmp
   LOCAL nTmp2
   LOCAL nScan
   LOCAL lInsLExtChar := .F.
   LOCAL cLExtraChar := ""

   // ukupni broj elemenata
   IF Len( aArr ) > 0
      nTotElem := aArr[ Len( aArr ), 1 ]
   ENDIF

   IF nEl_count > nTotElem
      xRet := "unknown"
      RETURN xRet
   ENDIF

   nScan := AScan( aArr, {| xVal| xVal[ 1 ] = nEl_count } )

   IF nScan = 0
      xRet := "unknown"
      RETURN xRet
   ENDIF

   // iscitaj code elementa
   cElemCode := aArr[ nScan, 2 ]

   // uzmi pravilo <GL_TICK>#<GL_TYPE>.....
   cRule := pravilo_grupe_elementa( cElemCode )

   aRule := TokToNiz( cRule, "#" )

   FOR nRule := 1 TO Len( aRule )

      // <GL_TICK>
      cRuleDef := AllTrim( aRule[ nRule ] )

      IF Left( cRuleDef, 1 ) <> "<"

         cLExtraChar := Left( cRuleDef, 1 )
         cRuleDef := StrTran( cRuleDef, cLExtraChar, "" )

         lInsLExtChar := .T.

      ENDIF

      nSeek := AScan( aArr, {| xVal | ;
         xVal[ 1 ] == nEl_count .AND. xVal[ 4 ] == cRuleDef } )

      IF nSeek > 0

         IF lInsLExtChar == .T.
            xRet += cLExtraChar
            lInsLExtChar := .F.
         ENDIF

         xRet += AllTrim( aArr[ nSeek, 5 ] )

      ENDIF

   NEXT

   RETURN xRet


/*
   Opis: setovanje naziva artikla automatski na osnovu pravila definisanih u tabeli pravila (f18_rules)

   Parameters:
     - aArr - matrica definicije artikla
     - cArt_code
     - cArt_desc
     - cArt_mcode
*/

STATIC FUNCTION rnal_setuj_naziv_artikla_iz_pravila( aArr, cArt_code, cArt_desc, cArt_mcode )

   LOCAL nTotElem := 0
   LOCAL cElemCode
   LOCAL i
   LOCAL cTmp
   LOCAL nTmp
   LOCAL lInsLExtChar := .F.
   LOCAL cLExtraChar := ""

   IF aArr == NIL .OR. Len( aArr ) == 0
      RETURN .F.
   ENDIF

   IF Len( aArr ) > 0
      nTotElem := aArr[ Len( aArr ), 1 ]
   ENDIF

   FOR i := 1 TO nTotElem

      nTmp := AScan( aArr, {| xVar | xVar[ 1 ] == i } )

      cElemCode := aArr[ nTmp, 2 ]

      cRule := pravilo_grupe_elementa( cElemCode )
      aRule := TokToNiz( cRule, "#" )

      FOR nRule := 1 TO Len( aRule )

         cRuleDef := AllTrim( aRule[ nRule ] )

         IF Left( cRuleDef, 1 ) <> "<"

            cLExtraChar := Left( cRuleDef, 1 )
            cRuleDef := StrTran( cRuleDef, cLExtraChar, "" )

            lInsLExtChar := .T.

         ENDIF

         nSeek := AScan( aArr, {| xVal | ;
            xVal[ 1 ] == i .AND. xVal[ 4 ] == cRuleDef } )

         IF nSeek > 0

            IF lInsLExtChar == .T.
               cArt_code += cLExtraChar
               lInsLExtChar := .F.
            ENDIF

            cArt_code += AllTrim( aArr[ nSeek, 5 ] )

            IF !Empty( cArt_desc )
               cArt_desc += " "
            ENDIF

            cArt_desc += AllTrim( aArr[ nSeek, 6 ] )

            cArt_mcode += AllTrim( ;
               PadR( Upper( AllTrim( aArr[ nSeek, 6 ] ) ), 2 ) )

         ENDIF

      NEXT

      IF i <> nTotElem
         cArt_code += "_"
         cArt_desc += ";"
      ENDIF

   NEXT

   RETURN .T.



STATIC FUNCTION pravilo_grupe_elementa( cCode )

   LOCAL cRule := ""

   cRule := rnal_format_naziva_elementa( cCode )

   IF Empty( cRule )
      MsgBeep( "Pravilo za formiranje naziva elementa ne postoji !!!" )
   ENDIF

   RETURN cRule




STATIC FUNCTION postoji_li_artikal( nArt_id, cDesc, nId )

   LOCAL nTArea := Select()
   LOCAL lRet := .F.

   SELECT articles
   SET ORDER TO TAG "2"
   GO TOP
   SEEK cDesc

   IF Found() .AND. field->art_id <> nArt_id .AND. AllTrim( cDesc ) == AllTrim( field->art_desc )
      nId := field->art_id
      lRet := .T.
   ENDIF

   SET ORDER TO TAG "1"

   SELECT ( nTArea )

   RETURN lRet


/*
   Opis: ažuriranje artikla u šifranik rnal_articles, otvaranje box-a za nazive

   Parametres:
     - nArt_id - id artikla
     - cArt_desc - skraćeni opis artikla
     - cArt_full_desc - puni opis artikla
     - cArt_mcode - match code artikla
     - lNew - .T. novi artikla, .F. postojeći
*/

STATIC FUNCTION rnal_azuriraj_artikal( nArt_id, cArt_Desc, cArt_full_desc, cArt_mcode, lNew )

   LOCAL lAppend := .F.
   LOCAL lExist := .F.
   LOCAL nExist_id := 0
   LOCAL cArt_lab_desc := ""

   lExist := postoji_li_artikal( nArt_id, cArt_desc, @nExist_id )

   IF lExist == .T.
      msgBeep( "UPOZORENJE: već postoji artikal sa istim opisom !!!#Artikal: " + AllTrim( Str( nExist_id ) ) )
   ENDIF

   SELECT articles
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   IF Found()

      IF !lNew
         IF AllTrim( cArt_desc ) == AllTrim( articles->art_desc ) ;
               .AND. AllTrim( cArt_full_desc ) == AllTrim( articles->art_full_d )
            lAppend := .F.
         ELSE
            lAppend := .T.
         ENDIF
      ELSE
         lAppend := .T.
      ENDIF

      IF !Empty( cArt_desc ) .AND. lAppend == .T. ;
            .AND. ( !lNew .OR. ( lNew .AND. Pitanje(, "Novi artikal, snimiti promjene (D/N) ?", "D" ) == "D" ) )

         cArt_desc := PadR( cArt_desc, 100 )
         cArt_full_desc := PadR( cArt_full_desc, 250 )
         cArt_lab_desc := PadR( cArt_lab_desc, 200 )
         cArt_mcode := PadR( cArt_mcode, 10 )

         IF ispravka_artikla_box( @cArt_desc, @cArt_full_desc, ;
               @cArt_lab_desc, @cArt_mcode ) == 1

            _rec := dbf_get_rec()

            _rec[ "art_desc" ] := cArt_desc
            _rec[ "match_code" ] := cArt_mcode
            _rec[ "art_full_d" ] := cArt_full_desc
            _rec[ "art_lab_de" ] := cArt_lab_desc

            update_rec_server_and_dbf( "articles", _rec, 1, "FULL" )

            RETURN 1

         ENDIF

      ENDIF

      IF lNew == .T.
         rnal_brisi_artikal( nArt_id, .T., .T. )
      ENDIF

   ENDIF

   RETURN 0



/*
   Opis: automatsko ažuriranje artikla u šifranik rnal_articles

   Parametres:
     - nArt_id - id artikla
     - cArt_desc - skraćeni opis artikla
     - cArt_full_desc - puni opis artikla
     - cArt_mcode - match code artikla
*/
STATIC FUNCTION rnal_azuriraj_artikal_auto( nArt_id, cArt_Desc, cArt_full_desc, cArt_mcode )

   LOCAL lChange := .F.
   LOCAL _rec

   IF Empty( cArt_desc )
      RETURN 0
   ENDIF

   SELECT articles
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   IF Found()

      IF AllTrim( cArt_desc ) == AllTrim( articles->art_desc ) .AND. ;
            AllTrim( cArt_full_desc ) == AllTrim( articles->art_full_d )
         lChange := .F.
      ELSE
         lChange := .T.
      ENDIF

   ENDIF

   IF lChange == .T.

      cArt_desc := PadR( cArt_desc, 100 )
      cArt_full_desc := PadR( cArt_full_desc, 100 )
      cArt_mcode := PadR( cArt_mcode, 10 )

      _rec := dbf_get_rec()

      _rec[ "art_desc" ] := cArt_desc
      _rec[ "match_code" ] := cArt_mcode
      _rec[ "art_full_d" ] := cArt_full_desc

      update_rec_server_and_dbf( "articles", _rec, 1, "FULL" )

      RETURN 1

   ENDIF

   RETURN 0



// ------------------------------------------------
// dodaj na string cStr string cAdd
// cStr - po referenci string na koji se stikla
// cAdd - dodatak za string
// lNoSpace - .t. - nema razmaka
// ------------------------------------------------
STATIC FUNCTION __add_to_str( cStr, cAdd, lNoSpace )

   LOCAL cSpace := Space( 1 )

   IF lNoSpace == nil
      lNoSpace := .F.
   ENDIF

   IF Empty( cStr ) .OR. lNoSpace == .T.
      cSpace := ""
   ENDIF

   cStr += cSpace + cAdd

   RETURN



STATIC FUNCTION ispravka_artikla_box( cArt_desc, cArt_full_desc, ;
      cArt_lab_desc, cArt_mcode )

   PRIVATE GetList := {}

   Box(, 6, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "*** pregled/korekcija podataka artikla"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Puni naziv:" GET cArt_full_desc PICT "@S57" VALID !Empty( cArt_full_desc )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Skr. naziv:" GET cArt_desc PICT "@S57" VALID !Empty( cArt_desc )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Lab. tekst:" GET cArt_lab_desc PICT "@S57"

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Match code:" GET cArt_mcode

   READ

   BoxC()

   ESC_RETURN 1

   RETURN 1



// ------------------------------------------------
// napuni matricu aElem sa elementima artikla
// aElem - matrica sa elementima
// nArt_id - id artikla
//
// aElem = { el_id, tip, naz, mc, e_gr_at_id, e_gr_vl_id }
// ------------------------------------------------
FUNCTION _fill_a_articles( aElem, nArt_id )

   LOCAL nTArea := Select()
   LOCAL cArt_desc := ""
   LOCAL cArt_mc := ""

   aElem := {}

   // artikli
   SELECT articles
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   IF Found()
      cArt_desc := AllTrim( field->art_desc )
      cArt_mc := AllTrim( field->match_code )
   ENDIF

   // elementi
   SELECT elements
   SET ORDER TO TAG "1"
   GO TOP
   SEEK artid_str( nArt_id )

   DO WHILE !Eof() .AND. field->art_id == nArt_id

      nEl_id := field->el_id

      // atributi
      SELECT e_att
      SET ORDER TO TAG "1"
      GO TOP
      SEEK artid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id

         AAdd( aElem, { field->el_id, "ATT",  cArt_desc, cArt_mc, field->e_gr_at_id, field->e_gr_vl_id } )
         SKIP

      ENDDO

      // operacije
      SELECT e_aops
      SET ORDER TO TAG "1"
      GO TOP
      SEEK artid_str( nEl_id )

      DO WHILE !Eof() .AND. field->el_id == nEl_id
         AAdd( aElem, { field->el_id, "AOP",  cArt_desc, cArt_mc, field->aop_id, field->aop_att_id } )
         SKIP
      ENDDO

      SELECT elements
      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN



// ------------------------------------------------
// napuni matricu aElem cisto sa elementima artikla
// aElem - matrica sa elementima
// nArt_id - id artikla
//
// aElem = { el_id, grupa }
// ------------------------------------------------
FUNCTION _g_art_elements( aElem, nArt_id )

   LOCAL nTArea := Select()
   LOCAL cPom := ""
   LOCAL nCnt := 0

   aElem := {}

   // elementi
   SELECT elements
   SET ORDER TO TAG "1"
   GO TOP
   SEEK elid_str( nArt_id )

   DO WHILE !Eof() .AND. field->art_id == nArt_id

      ++ nCnt

      cPom := g_e_gr_desc( field->e_gr_id )
      cPom += " "
      cPom += get_el_desc( field->el_id )

      AAdd( aElem, { field->el_id, cPom, nCnt } )

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN



// -------------------------------------
// get element description
// -------------------------------------
STATIC FUNCTION get_el_desc( nEl_id )

   LOCAL xRet := ""
   LOCAL nTArea := Select()

   SELECT e_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK elid_str( nEl_id )

   DO WHILE !Eof() .AND. field->el_id == nEl_id

      xRet += AllTrim(  g_e_gr_vl_desc( field->e_gr_vl_id ) ) + " "

      SKIP
   ENDDO

   SELECT ( nTArea )

   RETURN xRet


// ---------------------------------------
// vraca broj elementa artikla
// ---------------------------------------
FUNCTION _g_elem_no( aElem, nDoc_el_no, nElem_no )

   LOCAL nTmp

   nTmp := AScan( aElem, {| xVal| xVal[ 1 ] == nDoc_el_no } )

   IF nTmp > Len( aElem ) .OR. nTmp == 0
      nElem_no := 0
   ELSE
      nElem_no := aElem[ nTmp, 3 ]
   ENDIF

   RETURN


FUNCTION check_article_valid( art_id )

   LOCAL nDbfArea := Select()
   LOCAL _valid := .T.
   LOCAL _elem := {}

   rnal_matrica_artikla( art_id, @_elem )

   IF Len( _elem ) == 0
      MsgBeep( "Artikal nema pripadajuce elemente !!!" )
      _valid := .F.
   ENDIF

   SELECT ( nDbfArea )

   RETURN _valid




FUNCTION rpt_artikli_bez_elemenata()

   LOCAL _elem, _art_id
   LOCAL _error := {}
   LOCAL _count

   // otvori mi sifrarnike
   rnal_o_sif_tables()

   SELECT articles
   GO TOP

   Box(, 1, 50 )

   DO WHILE !Eof()

      _elem := {}
      _art_id := field->art_id

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Artikal: " + AllTrim( Str ( _art_id ) )

      rnal_matrica_artikla( _art_id, @_elem )

      SELECT articles

      IF Len( _elem ) == 0
         AAdd( _error, { field->art_id, field->art_desc } )
      ENDIF

      SKIP

   ENDDO

   BoxC()

   my_close_all_dbf()

   IF Len( _error ) == 0
      RETURN .T.
   ENDIF

   START PRINT CRET

   ?

   ? "Lista artikala bez elemenata..."
   ? Replicate( "-", 70 )
   ? "R.br  Artikal / Opis"
   ? Replicate( "-", 70 )

   _count := 0

   FOR nI := 1 TO Len( _error )
      ? PadL( AllTrim( Str( ++_count ) ), 4 ) + ".", _error[ nI, 1 ], _error[ nI, 2 ]
   NEXT

   FF
   ENDPRINT

   RETURN .T.
