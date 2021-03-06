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


// -----------------------------------------------
// generisi standardna RNAL pravila
// ako NE POSTOJE
// -----------------------------------------------
FUNCTION gen_rnal_rules()

   LOCAL nTArea := Select()

   O_RULES

   // element CODE_GEN, staklo
   in_elcode_rule( "G", "<GL_TICK>#<GL_TYPE>", ;
      "Sifra stakla, glass code" )

   // element CODE_GEN, distancer
   in_elcode_rule( "F", "<FR_TYPE>#<FR_TICK>#<FR_GAS>", ;
      "Sifra distancera, frame code" )

   SELECT ( nTArea )

   RETURN


// -----------------------------------------------
// ubacuje pravilo za formiranje naziva elementa
// -----------------------------------------------
STATIC FUNCTION in_elcode_rule( cElCond, cRule, cRuleName )

   LOCAL cModul
   LOCAL cRuleObj
   LOCAL cErrMsg
   LOCAL nLevel := 5
   LOCAL cRuleC3
   LOCAL cRuleC4
   LOCAL cRuleC7
   LOCAL hParams

   cTRule := rnal_format_naziva_elementa( cElCond )

   IF !Empty( cTRule )
      RETURN .F.
   ENDIF

   cModul := get_rule_field_mod( "RNAL" )
   cRuleObj := get_rule_field_obj( "ARTICLES" )
   cErrMsg := "-"
   cRuleC3 := get_rule_field_c3( "CODE_GEN" )
   cRuleC4 := get_rule_field_c4( cElCond )

   SELECT fmkrules
   SET ORDER TO TAG "1"
   GO BOTTOM

   nNrec := field->rule_id + 1

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "f18_rules" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabelu f18_rules !#Prekidam operaciju." )
      RETURN .F.
   ENDIF

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "rule_id" ] := nNrec
   _rec[ "modul_name" ] := cModul
   _rec[ "rule_obj" ] := cRuleObj
   _rec[ "rule_no" ] := 1
   _rec[ "rule_name" ] := cRuleName
   _rec[ "rule_ermsg" ] := cErrMsg
   _rec[ "rule_level" ] := nLevel
   _rec[ "rule_c3" ] := cRuleC3
   _rec[ "rule_c4" ] := cRuleC4
   _rec[ "rule_c7" ] := cRule

   IF !update_rec_server_and_dbf( "f18_rules", _rec, 1, "CONT" )
      run_sql_query( "ROLLBACK" )
   ELSE
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "f18_rules" }
      run_sql_query( "COMMIT", hParams )
   ENDIF

   RETURN .T.



// -----------------------------------------------
// setovanje specificnih rules kolona
// -----------------------------------------------
FUNCTION get_rule_field_cols_rnal()

   LOCAL aCols := {}

   AAdd( aCols, { "cond.1", {|| rule_c1 }, "rule_c1", {|| .T. }, {|| .T. } } )
   AAdd( aCols, { "cond.2", {|| rule_c2 }, "rule_c2", {|| .T. }, {|| .T. } } )
   AAdd( aCols, { "cond.3", {|| rule_c3 }, "rule_c3", {|| .T. }, {|| .T. } } )
   AAdd( aCols, { "cond.4", {|| rule_c4 }, "rule_c4", {|| .T. }, {|| .T. } } )
   AAdd( aCols, { "cond.5", {|| rule_c5 }, "rule_c5", {|| .T. }, {|| .T. } } )
   AAdd( aCols, { "cond.6", {|| rule_c6 }, "rule_c6", {|| .T. }, {|| .T. } } )
   AAdd( aCols, { "cond.7", {|| rule_c7 }, "rule_c7", {|| .T. }, {|| .T. } } )

   RETURN aCols


// ------------------------------------------
// vraca block za pregled sifrarnika
// ------------------------------------------
FUNCTION get_rule_field_block_rnal()
   RETURN {|| ed_rules() }


// ------------------------------------------
// ispravka sifrarnika rules
// ------------------------------------------
STATIC FUNCTION ed_rules()
   RETURN DE_CONT



// -----------------------------------------------------------
// vraca iz pravila kod za formiranje naziva elementa
// params:
// cElCond - element condition - tip elementa
//
// pravilo je sljedece:
//
// modul_name = RNAL
// rule_obj = ARTICLES
// rule_c1 = <CODE_GEN> "CODE_GEN" - generacija "kod"-a
// rule_c2 = cElCond - tip elementa "F" / "G" ili ....
// -----------------------------------------------------------
FUNCTION rnal_format_naziva_elementa( cElCond )

   LOCAL cCode := ""
   LOCAL cModul
   LOCAL cRuleType
   LOCAL cObj
   LOCAL nTArea := Select()

   cModul := get_rule_field_mod( "RNAL" )
   cObj := get_rule_field_obj( "ARTICLES" )
   cRuleType := get_rule_field_c3( "CODE_GEN" )
   cElCond := get_rule_field_c4( cElCond )

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "ELCODE"
   GO TOP

   SEEK cModul + cObj + cRuleType + cElCond

   IF Found()
      cCode := AllTrim( field->rule_c7 )
   ENDIF

   SELECT ( nTArea )

   RETURN cCode



STATIC FUNCTION err_validate( nLevel )

   LOCAL lRet := .F.

   IF nLevel <= 3
      lRet := .T.
   ELSEIF nLevel == 4
      IF Pitanje(, "Želite zanemariti ovo pravilo (D/N) ?", "N" ) == "D"
         lRet := .T.
      ENDIF
   ENDIF

   RETURN lRet


FUNCTION rnal_shema_artikla_za_tip( nType )

   LOCAL aSchema
   LOCAL nTArea := Select()
   LOCAL nTmp
   LOCAL aTmp
   LOCAL cObj := get_rule_field_obj( "ARTICLES" )
   LOCAL cCond := get_rule_field_c3( "AUTO_ELEM" )
   LOCAL cMod := get_rule_field_mod( "RNAL" )

   aSchema := {}

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "ELCODE"
   GO TOP

   SEEK cMod + cObj + cCond

   DO WHILE !Eof() .AND. field->modul_name == cMod ;
         .AND. field->rule_obj == cObj ;
         .AND. field->rule_c3 == cCond

      IF !Empty( field->rule_c4 )

         aTmp := TokToNiz( AllTrim( field->rule_c4 ), "-" )

         // val = 1-SH1
         // aTmp = ['1', 'SH1']

         IF LEN( aTmp ) <> 2
            SKIP
            LOOP
         ENDIF

         nTmp := Val( aTmp[ 1 ] )

         IF nTmp == nType
            AAdd( aSchema, { AllTrim( field->rule_c7 ) } )
         ENDIF

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN aSchema




// -------------------------------------------
// pravila za sifre iz FMK / otpremnica
// -------------------------------------------
FUNCTION rule_s_fmk( cField, nTickness, cType, cKind, cQttyType  )

   LOCAL nErrLevel := 0
   LOCAL cReturn := ""

   cReturn := _rule_s_fmk( cField, nTickness, cType, cKind, @cQttyType )

   RETURN cReturn


// ---------------------------------------------
// uzima sifru za FMK kod prenosa otpremnice
// cQttyType se setuje ovom funkcijom
//
// ---------------------------------------------
STATIC FUNCTION _rule_s_fmk( cField, nTickness, cType, cKind, cQttyType )

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "FMK_OTPREMNICA"
   LOCAL cCond := AllTrim( cField )
   LOCAL cMod := "RNAL"

   LOCAL aTTick := {}

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog
   LOCAL cReturn := ""

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "ITEM1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj ) + get_rule_field_c5( cCond )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj ) ;
         .AND. field->rule_c5 == get_rule_field_c5( cCond )

      // specificni tip stakla... npr: samo "F"
      IF !Empty( cType )

         IF AllTrim( field->rule_c6 ) == "ALL"
            // to je to......
         ELSEIF AllTrim( field->rule_c6 ) <> AllTrim( cType )
            // idi dalje
            SKIP
            LOOP
         ENDIF

      ENDIF

      // vrsta stakla RG ili naruèioc
      IF !Empty( cKind )
         // ako nije ta vrsta preskoci...
         IF AllTrim( field->rule_c4 ) <> AllTrim( cKind )
            SKIP
            LOOP
         ENDIF
      ENDIF

      // setuj vrijednost u kojoj æe se obraèunati kolièina
      cQttyType := AllTrim( field->rule_c3 )

      // to je rule -> debljina rang 0-20, uzmi u matricu
      // medjutim moze biti i prazno, onda su sve dimenzije stakla
      // u igri...
      // tada je aTTick[1] == "     "

      aTTick := TokToNiz( field->rule_c2, "-" )

      lRange := .F.

      IF Len( aTTick ) > 1
         lRange := .T.
      ENDIF

      // ispitaj debljinu

      // ako se koristi rangovi
      IF lRange == .T.

         // trazi se vrijednost recimo od 0-20
         IF nTickness >= Val( aTTick[ 1 ] ) .AND. ;
               nTickness <= Val( aTTick[ 2 ] )

            cReturn := AllTrim( field->rule_c7 )

            // nasao sam izadji iz petlje

            EXIT

         ENDIF

      ELSE

         // sve dimenzije stakla, ako je prazno
         IF Empty( AllTrim( aTTick[ 1 ] ) )

            cReturn := AllTrim( field->rule_c7 )
            EXIT

         ENDIF

         // trazi se odredjena vrijendost, npr 20
         IF nTickness = Val( aTTick[ 1 ] )

            cReturn := AllTrim( field->rule_c7 )

            // nasao sam izadji iz petlje
            EXIT

         ENDIF
      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN cReturn




// -------------------------------------------
// pravilo za unos operacija
// -------------------------------------------
FUNCTION rule_aop( xVal, aArr, lShErr )

   LOCAL nErrLevel := 0

   IF lShErr == nil
      lShErr := .T.
   ENDIF

   nErrLevel := _rule_aop_( xVal, aArr, lShErr )

   RETURN err_validate( nErrLevel )



// ---------------------------------------------
// rule za unos opracija dokumenta
//
// aArr -> matrica sa definicijom artikla...
// ---------------------------------------------
STATIC FUNCTION _rule_aop_( xVal,  aArr, lShErr )

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "ITEMS"
   LOCAL cCond := "DOC_IT_AOP"
   LOCAL cMod := "RNAL"

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "ITEM1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj ) + get_rule_field_c5( cCond )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj ) ;
         .AND. field->rule_c5 == get_rule_field_c5( cCond )

      // pravilo: koja operacija <A_KSR> recimo
      cAopCond := AllTrim( fmkrules->rule_c7 )

      // operator, < > = <> itd...
      xOperCond := AllTrim( fmkrules->rule_c2 )

      // vrijednost koja se provjerava
      xValue := AllTrim( fmkrules->rule_c3 )

      // tip elementa
      xType := AllTrim( fmkrules->rule_c4 )

      // atribut elementa
      xAttType := AllTrim( fmkrules->rule_c6 )

      nErrLevel := fmkrules->rule_level

      // da li postoji artikal koji zadovoljava ovo ???
      IF nErrLevel <> 0 .AND. cAopCond == xVal .AND. ;
            _r_aop_cond( xVal, xValue, xType, ;
            xAttType, xOperCond, aArr )

         nReturn := nErrLevel

         IF lShErr == .T.
            sh_rule_err( fmkrules->rule_ermsg, nErrLevel )
         ENDIF

         EXIT

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn


// -------------------------------------------
// pravilo za polje u items
// -------------------------------------------
FUNCTION rule_items( cField, xVal, aArr, lShErr )

   LOCAL nErrLevel := 0

   IF lShErr == nil
      lShErr := .T.
   ENDIF

   nErrLevel := _rule_item_( cField, xVal, aArr, lShErr )

   RETURN err_validate( nErrLevel )


// ---------------------------------------------
// rule za item u unosu. 1
//
// aArr -> matrica sa definicijom artikla...
// ---------------------------------------------
STATIC FUNCTION _rule_item_( cField, xVal,  aArr, lShErr )

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "ITEMS"
   LOCAL cCond := AllTrim( cField )
   LOCAL cMod := "RNAL"

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "ITEM1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj ) + get_rule_field_c5( cCond )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj ) ;
         .AND. field->rule_c5 == get_rule_field_c5( cCond )

      cArtCond := AllTrim( fmkrules->rule_c7 )
      xRCond := AllTrim( fmkrules->rule_c2 )
      xRVal1 := AllTrim( fmkrules->rule_c3 )
      xRVal2 := AllTrim( fmkrules->rule_c4 )

      nErrLevel := fmkrules->rule_level

      // da li postoji artikal koji zadovoljava ovo ???
      IF nErrLevel <> 0 .AND. ;
            _r_item_cond( xVal, xRCond, xRVal1, xRVal2 ) .AND. ;
            _r_art_cond( aArr, cArtCond )

         nReturn := nErrLevel

         IF lShErr == .T.
            sh_rule_err( fmkrules->rule_ermsg, nErrLevel )
         ENDIF

         EXIT

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn


// -------------------------------------------------------------
// provjera uslova r_item_cond()
// -------------------------------------------------------------
STATIC FUNCTION _r_item_cond( xVal, xCond, xRVal1, xRVal2 )

   LOCAL lRet := .T.

   xCond := AllTrim( xCond )

   DO CASE

      // provjera minimalne i maximalne vrijednosti
   CASE xCond == "MIN"

      IF xVal >= Val( xRVal1 )
         lRet := .F.
      ENDIF

   CASE xCond == "MAX"

      IF xVal <= Val( xRVal2 )
         lRet := .F.
      ENDIF

   ENDCASE

   RETURN lRet


// --------------------------------------------
//
// pravila nad artiklima
//
// --------------------------------------------
FUNCTION rule_articles( aArr )

   LOCAL nErrLevel := 0

   nErrLevel := _rule_art1( aArr )

   RETURN err_validate( nErrLevel )




// ---------------------------------------------
// rule za sastavljanje artikla ver. 1
//
// aArr -> matrica sa definicijom artikla...
// ---------------------------------------------
STATIC FUNCTION _rule_art1( aArr )

   LOCAL nReturn := 0
   LOCAL nTArea := Select()
   LOCAL cObj := "ARTICLES"
   LOCAL cCond := "ART_NEW"
   LOCAL cMod := "RNAL"
   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "RNART1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj ) + get_rule_field_c3( cCond )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj ) ;
         .AND. field->rule_c3 == get_rule_field_c3( cCond )

      cArtcond := AllTrim( fmkrules->rule_c7 )

      nErrLevel := fmkrules->rule_level

      // postoji li pravilo koje ne-zadovoljava ???
      IF nErrLevel <> 0 .AND. ;
            _r_art_cond( aArr, cArtCond )

         nReturn := nErrLevel

         sh_rule_err( fmkrules->rule_ermsg, nErrLevel )

         EXIT

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn


// ---------------------------------------------------------
// uslov za provjeru operacija i artikala
// ---------------------------------------------------------
STATIC FUNCTION _r_aop_cond( cSearch, cVal, cEl_type, ;
      cEl_att, cOper, aArr )

   LOCAL lReturn := .F.
   LOCAL nScan

   nScan := 0

   IF cOper == "="

      nScan := AScan( aArr, {|xV| AllTrim( xV[ 2 ] ) == AllTrim( cEl_type ) ;
         .AND. AllTrim( xV[ 4 ] ) == AllTrim( cEl_att ) ;
         .AND. AllTrim( xV[ 5 ] ) == AllTrim( cVal ) } )

   ELSEIF cOper == ">"

      nScan := AScan( aArr, {|xV| AllTrim( xV[ 2 ] ) == AllTrim( cEl_type ) ;
         .AND. AllTrim( xV[ 4 ] ) == AllTrim( cEl_att ) ;
         .AND. AllTrim( xV[ 5 ] ) > AllTrim( cVal ) } )

   ELSEIF cOper == "<"

      nScan := AScan( aArr, {|xV| AllTrim( xV[ 2 ] ) == AllTrim( cEl_type ) ;
         .AND. AllTrim( xV[ 4 ] ) == AllTrim( cEl_att ) ;
         .AND. AllTrim( xV[ 5 ] ) < AllTrim( cVal ) } )

   ELSEIF cOper == "<>"

      nScan := AScan( aArr, {|xV| AllTrim( xV[ 2 ] ) == AllTrim( cEl_type ) ;
         .AND. AllTrim( xV[ 4 ] ) == AllTrim( cEl_att ) ;
         .AND. AllTrim( xV[ 5 ] ) <> AllTrim( cVal ) } )

   ENDIF

   IF nScan <> 0
      lReturn := .T.
   ENDIF

   RETURN lReturn



// ---------------------------------------------------------
// uslov za poredjenje artikla sa pravilom - matrice
//
// aArr - matrica sa osnovnim elementima artikla iz unosa
// cArtCond - rule artikla
// ---------------------------------------------------------
STATIC FUNCTION _r_art_cond( aArr, cArtCond )

   LOCAL aTmp := {}
   LOCAL aTmp2 := {}
   LOCAL aArtArr := {}
   LOCAL i
   LOCAL i2
   LOCAL nCond
   LOCAL lExist := .T.

   // example rule:
   //
   // "1:<GL_TYPE>=FL;<GL_TICK>=4#3:<GL_TYPE>=LO"


   // prvo rastavi elemente sa "#"

   aTmp := TokToNiz( cArtCond, "#" )

   FOR i := 1 TO Len( aTmp )

      // "1:<GL_TYPE>=FL;<GL_TICK>=4"
      cTmp := AllTrim( aTmp[ i ] )

      // zatim rastavi broj elementa od uslova..... sa ":"
      aTmp2 := TokToNiz( cTmp, ":" )

      // i dobit ces sljedece:
      //
      // aTmp2[1] = "1"
      // aTmp2[2] = "<GL_TYPE>=FL;<GL_TICK>=4"

      // broj elementa = 1
      nElem := Val( AllTrim( aTmp2[ 1 ] ) )

      // uslov je = <GL_TYPE>=FL;<GL_TICK>=4
      cElCond := AllTrim( aTmp2[ 2 ] )

      // sada razdvoji uslove, moze ih biti vise, sa ";"
      aElConds := TokToNiz( cElCond, ";" )

      // dodaj ih u nasu novu matricu....

      FOR i2 := 1 TO Len( aElConds )

         // dobije se:
         //
         // aElConds[1] = "<GL_TYPE>=FL"
         // aElConds[2] = "<GL_TICK>=4"

         cECond := AllTrim( aElConds[ i2 ] )

         // rastavi sada uslov na djoker i vrijednost sa "="

         aECnds := TokToNiz( cECond, "=" )

         // i ubaci u novu matricu koja ce sluziti za usporedbu
         // .....
         // format matrice ce biti ovakav:
         //
         // aArtArr[1] = { 1, "<GL_TYPE>", "FL" }
         // aArtArr[2] = { 1, "<GL_TICK>",  "4" }
         // aArtArr[3] = { 3, "<GL_TYPE>", "LO" }

         AAdd( aArtArr, { nElem, aECnds[ 1 ], aECnds[ 2 ] } )

      NEXT

   NEXT

   // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   // UPOREDJIVANJE NOVE MATRICE SA USLOVIMA SA POSTOJECOM IZ UNOSA
   // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   // format matrice iz unosa je npr:
   //
   // aArr = { EL_NO, GR_VAL_CODE, GR_VAL, JOKER, ATR_CODE, ATR_VAL }
   //
   // aArr[1] = { 1, "G", "staklo", "<GL_TYPE>", "FL", "FLOAT" }
   // aArr[2] = { 1, "G", "staklo", "<GL_TICK>", "4", "4mm" }
   // aArr[3] = { 2, "F", "distancer", "<FR_TYPE>", "A", "Aluminij" }
   // aArr[4] = { 2, "F", "distancer", "<FR_TICK>", "10", "10mm" }
   // aArr[4] = { 2, "F", "distancer", "<FR_GAS>", "A", "Argon" }
   // aArr[4] = { 3, "G", "staklo", "<GL_TYPE>", "FL", "FLOAT" }
   // aArr[4] = { 3, "G", "staklo", "<GL_TYPE>", "4", "4mm" }


   FOR nCond := 1 TO Len( aArtArr )

      // element = 1
      nElement := aArtArr[ nCond, 1 ]

      // djoker atributa = "<GL_TYPE>"
      cCondAtt := aArtArr[ nCond, 2 ]

      // vrijednost atributa = "4"
      cCondVal := aArtArr[ nCond, 3 ]


      // ako postoji upitnik... onda je to "like"...
      // pr: S?, moze biti: "S", "SC", "SG" ....

      IF Len( cCondVal ) > 1 .AND. "?" $ cCondVal

         // ponisti upitnik ....
         cCondVal := StrTran( cCondVal, "?", "" )

         // pronadji da li postoji takav zapis... u matrici aArr
         nSeek := AScan( aArr, {| xVal | xVal[ 1 ] == nElement .AND. ;
            AllTrim( xVal[ 4 ] ) == cCondAtt .AND. ;
            AllTrim( xVal[ 5 ] ) = cCondVal } )

         // rijec je o bilo kojem uslovu...
         // na poziciji nElement

      ELSEIF Len( cCondVal ) == 1 .AND. cCondVal == "?"

         // pronadji da li postoji takav zapis... u matrici aArr
         nSeek := AScan( aArr, {| xVal | xVal[ 1 ] == nElement .AND. ;
            AllTrim( xVal[ 4 ] ) == cCondAtt } )

         // trazi se striktni uslov
         // npr: "L"

      ELSE
         // pronadji da li postoji takav zapis... u matrici aArr
         nSeek := AScan( aArr, {| xVal | xVal[ 1 ] == nElement .AND. ;
            AllTrim( xVal[ 4 ] ) == cCondAtt .AND. ;
            AllTrim( xVal[ 5 ] ) == cCondVal } )

      ENDIF

      IF nSeek == 0

         lExist := .F.
         EXIT

      ENDIF

   NEXT

   RETURN lExist
