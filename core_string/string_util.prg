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

FUNCTION _l( cString )
   RETURN cString


// --------------------------------------------------
// funkcija za formatiranje stringa za filter
// mjenja staru funkciju dbf_quote()
// --------------------------------------------------
FUNCTION _filter_quote( value )

   LOCAL _var_type := ValType( value )

   DO CASE
   CASE _var_type == "D"
      RETURN "STOD('" + DToS( value ) + "')"
   CASE _var_type == "C"
      RETURN "'" + value + "'"
   OTHERWISE
      RETURN hb_ValToStr( value )
   ENDCASE

   RETURN NIL


// ------------------------------------------------------------
// stara funkcija za formatiranje string-a za filterski uslov
// mjenja je nova funkcija filter_quote()
// ------------------------------------------------------------
FUNCTION dbf_quote( value )
   RETURN _filter_quote( value )


// ------------------------------------------------------------
// vraca vrijednost u tip string - bilo kojeg polja
// ------------------------------------------------------------
FUNCTION to_str( val )
   RETURN ToStr( val )

FUNCTION ToStr( xVal )

   LOCAL _val_t

   _val_t := ValType( xVal )

   DO CASE
   CASE _val_t  == "C"
      return( xVal )
   CASE _val_t  == "D"
      return( DToC( xVal ) )
   CASE _val_t  == "L"
      return( iif( xVal, ".t.", ".f." ) )
   CASE _val_t  == "N"
      return( Str( xVal ) )
   OTHERWISE
      RETURN "_?_"
   ENDCASE


FUNCTION SjeciStr( cStr, nLen, aRez )

   LOCAL lProsao, i

   IF aRez == nil
      aRez := {}
   //ELSE
      // prosljedjena je matrica da se dodaju elementi
      // sa SjeciStr(cStr, nLen, @aRez)
   ENDIF

   cStr := Trim( cStr )

   DO WHILE  !Empty( cStr )

      lProsao := .F.
      IF Len( cStr ) > nLen
         FOR i := nLen TO Int( nLen / 2 ) STEP -1

            IF SubStr( cStr, i, 1 ) $ " ,/-:)"
               AAdd( aRez, PadR( Left( cStr, i ), nLen ) )
               cStr := SubStr( cStr, i + 1 )
               i := 1
               lProsao := .T.
            ENDIF

         NEXT

      ELSE

         AAdd( aRez, PadR( cStr, nLen ) )
         lProsao := .T.
         cStr := ""

      ENDIF

      IF !lProsao
         AAdd( aRez, PadR( Left( cStr, nLen - 1 ) + iif( Len( cStr ) > nLen, "-", "" ), nLen ) )
         cStr := SubStr( cStr, nLen )
      ENDIF
   ENDDO

   IF Len( aRez ) == 0
      AAdd( aRez, Space( nLen ) )
   ENDIF

   RETURN aRez



FUNCTION CryptSC( cStr )

   LOCAL nLen, cC, cPom, i

   cPom := ""
   nLen := Len( cStr )
   FOR i = 1 TO Int( nLen / 2 )
      cC := SubStr( cStr, nLen + 1 - i, 1 )
      IF cC < ''
         cPom += Chr( Asc( cC ) + 128 )
      ELSE
         cPom += Chr( Asc( cC ) - 128 )
      ENDIF
   NEXT

   IF nLen % 2 <> 0
      cC := SubStr( cStr, Int( nLen / 2 ) + 1, 1 )
      IF cC < ''
         cPom += Chr( Asc( cC ) + 128 )
      ELSE
         cPom += Chr( Asc( cC ) - 128 )
      ENDIF
   ENDIF
   FOR i = Int( nLen / 2 ) TO 1 STEP -1
      cC := SubStr( cStr, i, 1 )
      IF cC < ''
         cPom += Chr( Asc( cC ) + 128 )
      ELSE
         cPom += Chr( Asc( cC ) - 128 )
      ENDIF
   NEXT

   RETURN cPom


FUNCTION ChADD( cC, n )

   // poziv cC:="A"; ChADD(@cC,2) -> "C"

   cC := Chr( Asc( cC ) + n )

   RETURN NIL



FUNCTION ChSub( cC, cC2 )

   // poziv ChSub("C","A") -> 2

   RETURN Asc( cC ) - Asc( cC2 )


FUNCTION Crypt2( cStr, cModul )

   LOCAL nLen, cC, cPom, i

   IF cModul = NIL
      cModul := gModul
   ENDIF

   cPom := ""
   nLen := Len( cStr )
   FOR i = 1 TO Int( nLen / 2 )
      cC := SubStr( cStr, nLen + 1 - i, 1 )
      IF cC < ''
         cPom += Chr( Asc( cC ) + Asc( SubStr( PadR( cModul, 8 ), i, 1 ) ) )
      ELSE
         cPom += Chr( Asc( cC ) - Asc( SubStr( PadR( cModul, 8 ), i, 1 ) ) )
      ENDIF

   NEXT
   FOR i = Int( nLen / 2 ) TO 1 STEP -1
      cC := SubStr( cStr, i, 1 )
      IF cC < ''
         cPom += Chr( Asc( cC ) + Asc( SubStr( PadR( cModul, 8 ), nLen + 1 - i, 1 ) ) )
      ELSE
         cPom += Chr( Asc( cC ) - Asc( SubStr( PadR( cModul, 8 ), nLen + 1 - i, 1 ) ) )
      ENDIF
   NEXT

   RETURN cPom




FUNCTION Razrijedi ( cStr )

   LOCAL cRazrStr, nLenM1, nCnt

   cStr := AllTrim ( cStr )
   nLenM1 := Len ( cStr ) - 1
   cRazrStr := ""
   FOR nCnt := 1 TO nLenM1
      cRazrStr += SubStr ( cStr, nCnt, 1 ) + " "
   NEXT
   cRazrStr += Right ( cStr, 1 )

   RETURN ( cRazrStr )


// f-je chr256() i asc256() rade sa tekstom duzine 2 znaka
// -------------------------------------------------------
FUNCTION CHR256( nKod )

   RETURN ( Chr( Int( nKod / 256 ) ) + Chr( nKod % 256 ) )

FUNCTION ASC256( cTxt )

   RETURN ( Asc( Left( cTxt, 1 ) ) * 256 + Asc( Right( cTxt, 1 ) ) )


FUNCTION KPAD( n, l )

   RETURN PadL( LTrim( TRANS( Round( n, gZaokr ), PicDEM ) ), l, "." )




FUNCTION StrLinija( cTxt2 )

   LOCAL nTxt2, nI, nLTxt2

   nLTxt2 := 1
   FOR nI := 1 TO Len( cTxt2 )
      IF SubStr( cTxt2, nI, 1 ) = Chr( 13 )
         ++nLTxt2
      ENDIF
   NEXT

   RETURN nLTxt2



/*
 *  brief Token pretvori u niz
 *  param cInputTekst - token
 *  param cSeparator - separator niza
 */
FUNCTION TokToNiz( cInputTekst, cSeparator )

   LOCAL aNiz := {}
   LOCAL nI := 0
   LOCAL cE := ""

   IF cSeparator == NIL
      cSeparator := "."
   ENDIF

   FOR nI := 1 TO NumToken( cInputTekst, cSeparator )
      cE := Token( cInputTekst, cSeparator, nI )
      AAdd( aNiz, cE )
   NEXT

   RETURN aNiz


FUNCTION BrDecimala( cFormat )

   LOCAL i := 0, cPom, nVrati := 0

   i := At( ".", cFormat )
   IF i != 0
      cPom := AllTrim( SubStr( cFormat, i + 1 ) )
      FOR i := 1 TO Len( cPom )
         IF SubStr( cPom, i, 1 ) == "9"
            nVrati += 1
         ELSE
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN nVrati


/* 
 *  brief Ispisuje iznos slovima
 *  param nIzn       - iznos
 *  param cDinDem    -
 */

FUNCTION Slovima( nIzn, cDinDem )

   LOCAL nPom
   LOCAL cRez := ""
   LOCAL lMarker := .F.

   IF nIzn < 0
      nIzn := -nIzn
      cRez := "negativno:"
   ENDIF

   IF ( nPom := Int( nIzn / 10 ** 9 ) ) >= 1
      IF nPom == 1
         cRez += "milijarda"
      ELSE
         Stotice( nPom, @cRez, .F., .T., cDinDEM )
         IF Right( cRez, 1 ) $ "eiou"
            cRez += "milijarde"
         ELSE
            cRez += "milijardi"
         ENDIF
      ENDIF
      nIzn := nIzn - nPom * 10 ** 9
      lMarker := .T.
   ENDIF
   IF ( nPom := Int( nIzn / 10 ** 6 ) ) >= 1
      IF lMarker; cRez += ""; ENDIF
      lMarker := .T.
      IF nPom == 1
         cRez += "milion"
      ELSE
         Stotice( nPom, @cRez, .F., .F., cDINDEM )
         cRez += "miliona"
      ENDIF
      nIzn := nIzn - nPom * 10 ** 6


   ENDIF
   IF ( nPom := Int( nIzn / 10 ** 3 ) ) >= 1
      IF lMarker
         cRez += ""
      ENDIF
      lMarker := .T.
      IF nPom == 1
         cRez += "hiljadu"
      ELSE
         Stotice( nPom, @cRez, .F., .T., cDINDEM )
         IF Right( cRez, 1 ) $ "eiou"
            cRez += "hiljade"
         ELSE
            cRez += "hiljada"
         ENDIF
      ENDIF
      nIzn := nIzn - nPom * 10 ** 3
   ENDIF

   IF lMarker .AND. nIzn >= 1
      cRez += ""
   ENDIF
   Stotice( nIzn, @cRez, .T., .T., cDINDEM )

   RETURN cRez



/*  Stotice(nIzn, cRez, fDecimale, fMnozina, cDinDem)
 *  brief Formatira tekst ako iznos prelazi 100
 *  param nIzn       - iznos
 *  param cRez
 *  param fdecimale
 *  param fMnozina
 *  param cDinDem
 *  return cRez
 */

STATIC FUNCTION Stotice( nIzn, cRez, fDecimale, fMnozina, cDinDem )

   LOCAL fDec, fSto := .F., i, nPom, aSl

   IF ( nPom := Int( nIzn / 100 ) ) >= 1
      aSl := { "stotinu", "dvijestotine", "tristotine", "četiristotine", ;
         "petstotina", "šeststotina", "sedamstotina", "osamstotina", "devetstotina" }
      cRez += hb_UTF8ToStr( aSl[ nPom ] )
      nIzn := nIzn - nPom * 100
      fSto := .T.
   ENDIF

   fDec := .F.
   DO WHILE .T.
      IF fdec
         cRez += AllTrim( Str( nizn, 2 ) )
      ELSE
         IF Int( nIzn ) > 10 .AND. Int( nIzn ) < 20
            aSl := { "jedanaest", "dvanaest", "trinaest", "četrnaest", ;
               "petnaest", "šesnaest", "sedamnaest", "osamnaest", "devetnaest" }

            cRez += hb_UTF8ToStr( aSl[ Int( nIzn ) - 10 ] )
            nIzn := nIzn - Int( nIzn )
         ENDIF
         IF ( nPom := Int( nIzn / 10 ) ) >= 1
            aSl := { "deset", "dvadeset", "trideset", "četrdeset", ;
               "pedeset", "šezdeset", "sedamdeset", "osamdeset", "devedeset" }
            cRez += hb_UTF8ToStr( aSl[ nPom ] )
            nIzn := nIzn - nPom * 10
         ENDIF
         IF ( nPom := Int( nIzn ) ) >= 1
            aSl := { "jedan", "dva", "tri", "četiri", ;
               "pet", "šest", "sedam", "osam", "devet" }
            IF fmnozina
               aSl[ 1 ] := "jedna"
               aSl[ 2 ] := "dvije"
            ENDIF
            cRez += hb_UTF8ToStr( aSl[ nPom ] )
            nIzn := nIzn - nPom
         ENDIF
         IF !fDecimale
            EXIT
         ENDIF

      ENDIF // fdec
      IF fdec
         cRez += "/100 " + cDINDEM
         EXIT
      ENDIF

      fDec := .T.
      fMnozina := .F.
      nizn := Round( nIzn * 100, 0 )
      IF nizn > 0
         IF !Empty( cRez )
            cRez += " i "
         ENDIF
      ELSE
         IF Empty( cRez )
            cRez := "nula " + cDINDEM
         ELSE
            cRez += " " + cDINDEM
         ENDIF
         EXIT
      ENDIF
   ENDDO

   RETURN cRez


/* CreateHashString(aColl)
 *  brief Kreira hash string na osnovu podataka iz matrice aColl
 *  brief primjer: aColl[1] = "podatak1"
              aColl[2] = "podatak2"
      CreateHashString(aColl) => "podatak1#podatak2"
 *  param aColl - matrica sa podacima
 *  return cHStr - hash string
 */

FUNCTION CreateHashString( aColl )

   LOCAL cHStr := "", i

   // Ako je duzina matrice 0 izadji
   IF Len( aColl ) == 0
      RETURN cHStr
   ENDIF

   FOR i := 1 TO Len( aColl )
      cHStr += aColl[ i ]
      IF ( i <> Len( aColl ) )
         cHStr += "#"
      ENDIF
   NEXT

   RETURN cHStr


/*
 *     Iscitava hash string u matricu
 *  return aColl - matrica popunjena podacima iz stringa
 */
FUNCTION ReadHashString( cHashString )

   LOCAL aColl

   IF Len( cHashString ) == 0
      cHashString := ""
   ENDIF

   aColl := {}
   aColl := TokToNiz( cHashString, "#" )

   RETURN aColl



/*
 *     Kreiraj array na osnovu stringa
 *   param: cStr - string
 *   param: nLen - na svakih nLen upisi novu stavku u array
 */

FUNCTION StrToArray( cStr, nLen )

   LOCAL aColl := {}
   LOCAL cTmp := "", nCnt, i

   cStr := AllTrim( cStr )

   IF ( Len( cStr ) < nLen )
      AAdd( aColl, cStr )
      RETURN aColl
   ENDIF

   nCnt := 0

   FOR i := 1 TO Len( cStr )
      nCnt++
      cTmp += SubStr( cStr, i, 1 )
      IF ( nCnt == nLen .OR. ( ( nCnt < nLen ) .AND. i == Len( cStr ) ) )
         AAdd( aColl, cTmp )
         nCnt := 0
         cTmp := ""
      ENDIF
   NEXT

   RETURN aColl



/*
 *     Vraca vrijednost memo niza u string
 */

FUNCTION FlushMemo( aMemo )

   LOCAL i, cPom

   cPom := ""
   cPom += Chr( 16 )
   FOR i := 1 TO Len( aMemo )
      cPom += aMemo[ i ]
      cPom += Chr( 17 )
      cPom += Chr( 16 )
   NEXT

   RETURN cPom



FUNCTION show_number( nNumber, cPicture, nExtra )

   LOCAL nDec
   LOCAL nLen
   LOCAL nExp
   LOCAL i

   IF nExtra <> NIL
      nLen := Abs( nExtra )

   ELSE
      nLen := Len( cPicture )
   ENDIF


   IF cPicture == nil
      nDec = kolko_decimala( nNumber )
   ELSE
      // 99999.999"
      // AT(".") = 6
      // nLen 9

      nDec := At( ".", cPicture )

      IF nDec > 0
         // nDec =  9  - 6  = 3
         nDec := nLen - nDec
      ENDIF

   ENDIF

   // max velicina koja se moze prikazati sa ovim picture
   // 5  =  9 - 3 - 1  => 10 ^ 5
   //
   nExp := nLen - nDec - 1

   // 0  -> 3
   FOR i := 0 TO nDec
      // nNum 177 000  < 10**5 -1 = 100 000 - 1 = 99 999
      IF nNumber / ( 10 ** i ) < ( 10 ** ( nExp ) - 1 )
         IF i = 0
            IF cPicture == nil
               RETURN Str( nNumber, nLen, nDec )
            ELSE
               RETURN Transform( nNumber, cPicture )
            ENDIF
         ELSE
            RETURN Str( nNumber, nLen, nDec - i )
         ENDIF
      ENDIF
   NEXT

   RETURN Replicate( "*", nLen )



STATIC FUNCTION kolko_decimala( nNumber )

   LOCAL nDec
   LOCAL i

   // prepostavka da je maximalno 4
   nDec := 4

   // nadji broj potrebnih decimala
   FOR i := 0 TO 4
      IF Round( nNumber, i ) == Round( nNumber, nDec )
         RETURN i
      ENDIF
   NEXT

   RETURN nDec




// -----------------------------------------------------------------------
// F-ja vraca novu sifru koju odredjuje uvecavanjem postojece po sljedecem
// principu: Provjeravaju se znakovi pocevsi od posljednjeg i dok god je
// znak cifra "9" uzima se sljedeci znak, a "9" se mijenja sa "0". Ukoliko
// provjeravani znak nije "9", zamjenjuje se sa znakom ciji je kod veci za 1
// i zavrsava se sa pravljenjem sifre tj. neprovjeravani znakovi ostaju isti.
// -----------------------------------------------------------------------
FUNCTION NovaSifra( cSifra )

   LOCAL i := 0
   LOCAL cPom, cPom2

   IF Empty( cSifra )
      cSifra := StrTran( cSifra, " ", "0" )
   ENDIF

   FOR i := Len( cSifra ) TO 1 STEP -1

      IF ( cPom := SubStr( cSifra, i, 1 ) ) < "9"
         cSifra := Stuff( cSifra, i, 1, Chr( Asc( cPom ) + 1 ) )
         EXIT
      ENDIF

      IF i == 1
         cPom2 := novi_znak_extended( cPom )
      ELSE
         cPom2 := "0"
      ENDIF

      cSifra := Stuff( cSifra, i, 1, cPom2 )
   NEXT

   RETURN cSifra



STATIC FUNCTION novi_znak_extended( cChar )

   IF cChar == "9"
      RETURN "A"

   ELSEIF cChar == "Z"
      RETURN Chr( 143 )

   ELSEIF cChar == Chr( 143 )
      RETURN Chr( 166 )

   ELSEIF cChar == Chr( 166 )
      RETURN Chr( 172 )

   ELSEIF cChar == Chr( 172 )
      RETURN Chr( 209 )

   ELSEIF cChar == Chr( 209 )
      RETURN Chr( 230 )

   ELSEIF cChar == Chr( 230 )
      RETURN "?"
   ELSE
      RETURN Chr( Asc( cChar ) + 1 )
   ENDIF

FUNCTION _to_utf8( str )
   RETURN hb_StrToUTF8( str )



FUNCTION _to_str( str )
   RETURN hb_UTF8ToStr( str )


FUNCTION _u( cStr )
   RETURN hb_UTF8ToStr( cStr )


FUNCTION ToStrU( val )

   RETURN hb_UTF8ToStr( ToStr( val ) )


FUNCTION _upadr( cUtf, nNum )

   RETURN hb_StrToUTF8( PadR( hb_UTF8ToStr( cUtf ), nNum ) )


FUNCTION num_to_str( nNumber, nLen, nDec )

   LOCAL cTxt := Str( nNumber, nLen, nDec )

   cTxt := AllTrim( cTxt )
   cTxt := StrTran( cTxt, ".", "" )
   cTxt := PadL( cTxt, nLen, "0" )

   RETURN cTxt
