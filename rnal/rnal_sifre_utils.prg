/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "rnal.ch"

// -------------------------------------------------
// vrati match_code za stavku sifrarnika
// -------------------------------------------------
FUNCTION say_item_mc( nArea, cTable, nId )

   LOCAL nTArea := Select()
   LOCAL xRet := "-----"

   IF !Used( nArea )
      USE ( nArea )
   ENDIF
   select &cTable

   SET ORDER TO TAG "1"
   GO TOP

   SEEK Str( nId )

   IF Found()
      xRet := AllTrim( field->match_code )
   ENDIF

   SELECT ( nTArea )

   RETURN xRet


// ---------------------------------------------
// prikaz id/mc za stavku u browse-u sifrarnika
// nFieldId - vrijednost id polja
// ---------------------------------------------
FUNCTION sif_idmc( nFieldId, lOnlyMc, nRpad )

   LOCAL cId := Str( nFieldId )

   LOCAL cMCode := iif( FieldPos( "MATCH_CODE" ) <> 0, AllTrim( field->match_code ), "" )
   LOCAL xRet := ""

   IF nRpad == nil
      nRPad := 10
   ENDIF

   IF lOnlyMC == nil
      lOnlyMC := .F.
   ENDIF

   IF lOnlyMC <> .T.
      xRet += AllTrim( cId )
   ELSE
      xRet += "--"
   ENDIF

   IF !Empty( cMCode )
      xRet += "/"
      IF Len( cMCode ) > 4
         xRet += Left( cMCode, 4 ) + ".."
      ELSE
         xRet += cMCode
      ENDIF
   ENDIF

   RETURN PadR( xRet, nRPad )


// ------------------------------------------------
// prikazuje cItem u istom redu gdje je get
// cItem - string za prikazati
// nPadR - n vrijednost pad-a
// ------------------------------------------------
FUNCTION show_it( cItem, nPadR )

   IF nPadR <> nil
      cItem := PadR( cItem, nPadR )
   ENDIF

   @ Row(), Col() + 3 SAY cItem

   RETURN .T.



FUNCTION rnal_inc_id( wId, cFieldName, cIndexTag, lAuto )

   LOCAL nTRec
   LOCAL _t_rec := RecNo()
   LOCAL cTBFilter := dbFilter()
   LOCAL _alias := AllTrim( Lower( Alias() ) )
   LOCAL _param := "rnal_" + _alias + "_no"
   LOCAL _t_area := Select()
   LOCAL _value := 0

   IF cIndexTag == NIL
      cIndexTag := "1"
   ENDIF

   IF lAuto == NIL
      lAuto := .F.
   ENDIF

   IF ( Ch == K_CTRL_N .OR. Ch == K_F4 ) .AND. ( VALTYPE( wId ) == "N" .AND. wId <> 0 ) .or. ( VALTYPE( wId ) == "C" .AND. !EMPTY( wId ) )
      RETURN .F.
   ENDIF

   IF ( Ch == K_CTRL_N .OR. Ch == K_F4 .OR. lAuto )
	
      IF ( LastKey() == K_ESC )
         RETURN .F.
      ENDIF
	
      SET FILTER TO
      SET ORDER TO tag &cIndexTag
	
      _value := ( fetch_metric( _param, NIL, 0 ) + 1 )

      wId := rnal_last_id( cFieldName ) + 1

      wid := Max( _value, wid )
	
      set_metric( _param, NIL, wId )

      SET FILTER to &cTBFilter
      SET ORDER TO TAG "1"
      GO ( _t_rec )

      AEval( GetList, {| o| o:display() } )

   ENDIF

   RETURN .T.


// ----------------------------------------
// vraca posljednji id zapis iz tabele
// cFieldName - ime id polja
// ----------------------------------------
STATIC FUNCTION rnal_last_id( cFieldName )

   LOCAL nLast_rec := 0

   GO TOP
   SEEK Str( 9999999999, 10 )
   SKIP -1

   nLast_rec := field->&cFieldName

   RETURN nLast_rec



// --------------------------------------
// testiraj id u sifrarniku
// wId - polje id proslijedjeno po ref.
// cFieldName - ime id polja
// --------------------------------------
FUNCTION rnal_chk_id( wId, cFieldName, cIndexTag  )

   LOCAL nTRec
   LOCAL _t_rec := RecNo()
   LOCAL cTBFilter := dbFilter()
   LOCAL lSeek := .T.
   LOCAL nIndexOrd := IndexOrd()
   LOCAL cTag

   IF cIndexTag == nil
      cIndexTag := "1"
   ENDIF

   SET FILTER TO
   SET ORDER TO tag &cIndexTag
   GO TOP

   SEEK Str( wId, 10 )

   IF Found()
      lSeek := .F.
   ENDIF
	
   cTag := AllTrim( Str( nIndexOrd ) )

   SET FILTER to &cTBFilter
   SET ORDER TO TAG cTag
   GO ( _t_rec )

   IF lSeek == .F.
      lSeek := rnal_inc_id( @wId, cFieldName )
   ENDIF

   RETURN lSeek


// --------------------------------
// edit sifre u sifraniku
// --------------------------------
FUNCTION rnal_wid_edit( cField )

   LOCAL nRet := DE_CONT
   LOCAL nId

   nId := field->&( cField )

   nId += 1

   Box(, 1, 50 )
   @ m_x + 1, m_y + 2 SAY "Ispravi sifru na:" GET nId PICT Replicate( "9", 10 )
   READ
   BoxC()

   IF LastKey() <> K_ESC

      _rec := dbf_get_rec()
      _rec[ Lower( cField ) ] := nId
      update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
      nRet := DE_REFRESH

   ENDIF

   RETURN nRet


// --------------------------------------------------
// vraca shemu artikla na osnovu matrice aArtArr
// --------------------------------------------------
FUNCTION arr_schema( aArtArr )

   LOCAL cSchema := ""
   LOCAL i
   LOCAL ii
   LOCAL aTmp := {}
   LOCAL nScan
   LOCAL nElem
   LOCAL nElemNo
   LOCAL cCode
   LOCAL nSrch

   // aArtArr[ element_no, gr_code, gr_desc, att_joker, att_valcode, att_val ]
   // example:
   // [     1     ,   G    , staklo ,  <GL_TICK>,     6     ,  6mm    ]
   // [     1     ,   G    , staklo ,  <GL_TYPE>,     F     ,  FLOAT  ]
   // [     2     , .....

   IF Len( aArtArr ) == 0
      RETURN cSchema
   ENDIF

   // koliko ima elemenata artikala ???
   nElemNo := aArtArr[ Len( aArtArr ), 1 ]

   FOR i := 1 TO nElemNo

      // prvo potrazi coating ako ima
      nSrch := AScan( aArtArr, {| xVal| xVal[ 1 ] == i ;
         .AND. xVal[ 4 ] == "<GL_COAT>"  } )

      IF nSrch <> 0
	
         nElem := aArtArr[ nScan, 1 ]
         cCode := aArtArr[ nScan, 2 ]
		
      ELSE
		
         // trazi bilo koji element
         nSrch := AScan( aTmp, {| xVal| xVal[ 1 ] == i } )
		
         nElem := aArtArr[ nScan, 1 ]
         cCode := aArtArr[ nScan, 2 ]
	
      ENDIF
	

      nScan := AScan( aTmp, {| xVal| xVal[ 1 ] == nElem ;
         .AND. xVal[ 2 ] == cCode } )

      IF nScan == 0
         AAdd( aTmp, { nElem, cCode } )
      ENDIF
	
   NEXT

   // sada to razbij u string

   FOR ii := 1 TO Len( aTmp )

      IF ii <> 1
         cSchema += "#"
      ENDIF
	
      cSchema += AllTrim( aTmp[ ii, 2 ] )

   NEXT

   RETURN cSchema



// --------------------------------------------------
// vraca picture code za artikal prema schemi
// --------------------------------------------------
FUNCTION g_a_piccode( cSchema )

   LOCAL cPicCode := cSchema

   cPicCode := StrTran( cPicCode, "FL", Chr( 177 ) )
   cPicCode := StrTran( cPicCode, "G", Chr( 219 ) )
   cPicCode := StrTran( cPicCode, "F", " " )
   cPicCode := StrTran( cPicCode, "-", "" )

   RETURN cPicCode
