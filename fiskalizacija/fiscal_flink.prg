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

STATIC s_cPath, s_cPath2, s_cName

THREAD STATIC F_POS_RN := "POS_RN" // pos komande

// --------------------------------------------------------
// fiskalni racun pos (FLINK)
// cFPath - putanja do fajla
// cFName - naziv fajla
// aData - podaci racuna
// lStorno - da li se stampa storno ili ne (.T. ili .F. )
// --------------------------------------------------------
FUNCTION fiskalni_flink_racun( cFPath, cFName, aData, lStorno, cError )

   LOCAL cSep := ";"
   LOCAL aPosData := {}
   LOCAL aStruct := {}
   LOCAL nErr := 0
   LOCAL cTmp_date, cTmp_time

   IF lStorno == nil
      lStorno := .F.
   ENDIF

   IF cError == nil
      cError := "N"
   ENDIF

   fl_d_tmp() // pobrisi temp fajlove
   cFName := f_filepos( aData[ 1, 1 ] ) // naziv fajla
   _f_err_delete( cFPath, cFName ) // izbrisi fajl greske odmah na pocetku ako postoji
   // uzmi strukturu tabele za pos racun
   aStruct := _g_f_struct( F_POS_RN )
   // iscitaj pos matricu
   aPosData := __pos_rn( aData, lStorno )
   cTmp_date := DToC( Date() )
   cTmp_time := Time()
   fiscal_array_to_file( cFPath, cFName, aStruct, aPosData )
   IF cError == "D"
      MsgO( "Provjera grešaka ..." )
      Sleep( 3 )
      MsgC()
      nErr := flink_pos_error( cFPath, cFName, cTmp_date, cTmp_time ) // provjeri da li je racun odstampan
   ENDIF

   RETURN nErr

// ---------------------------------------------------
// citanje log fajla
// ---------------------------------------------------
FUNCTION flink_pos_error( cFPath, cFName, cDate, cTime )

   LOCAL nErr := 0
   LOCAL aDir := {}
   LOCAL cTmp
   LOCAL cE_date

   // error file time-hour, min, sec.
   LOCAL cE_th
   LOCAL cE_tm
   LOCAL cE_ts
   // origin file time-hour, min, sec.
   LOCAL cF_th := SubStr( cTime, 1, 2 )
   LOCAL cF_tm := SubStr( cTime, 4, 2 )
   LOCAL cF_ts := SubStr( cTime, 7, 2 )
   LOCAL i

   IF !Empty( AllTrim( flink_path2() ) )
      cTmp := cFPath + AllTrim( flink_path2() ) + SLASH + cFName
   ELSE
      cTmp := cFPath + "printe~1" + SLASH + cFName
   ENDIF

   aDir := Directory( cTmp )
   IF Len( aDir ) == 0  // nema fajla
      RETURN nErr
   ENDIF

   // napravi pattern za pretragu unutar matrice
   // <filename> + <date> + <file hour> + <file minute>
   // primjer:
   //
   // 21100000.inp + 10.10.10 + 12 + 15 = "21100000.inp10.10.101215"

   cF_patt := AllTrim( Upper( cFName ) ) + cDate + cF_th + cF_tm

   // ima fajla, provjeri jos samo datum i vrijeme
   FOR i := 1 TO Len( aDir )
      cE_name := Upper( AllTrim( aDir[ i, 1 ] ) )
      // datum fajla
      cE_date := DToC( aDir[ i, 3 ] )
      // vrijeme fajla
      cE_th := SubStr( AllTrim( aDir[ i, 4 ] ), 1, 2 )
      cE_tm := SubStr( AllTrim( aDir[ i, 4 ] ), 4, 2 )
      cE_ts := SubStr( AllTrim( aDir[ i, 4 ] ), 7, 2 )
      // patern pretrage
      cE_patt := AllTrim( cE_name ) + cE_date + cE_th + cE_tm
      IF cE_patt == cF_patt // imamo error fajl !!!
         nErr := 1
         EXIT
      ENDIF
   NEXT

   RETURN nErr

// --------------------------------------------------------
// brisi fajl greske ako postoji prije kucanja racuna
// --------------------------------------------------------
STATIC FUNCTION _f_err_delete( cFPath, cFName )

   LOCAL cTmp := cFPath + "printe~1" + SLASH + cFName
   FErase( cTmp )

   RETURN .T.


// ----------------------------------------
// fajl za pos fiskalni stampac
// ----------------------------------------
STATIC FUNCTION f_filepos( cBrRn )

   LOCAL cRet := PadL( AllTrim( cBrRn ), 8, "0" ) + ".inp"

   RETURN cRet



// ----------------------------------------------
// brise fajlove iz ulaznog direktorija
// ----------------------------------------------
STATIC FUNCTION fl_d_tmp()

   LOCAL cTmp, cF_path

   MsgO( "brisem tmp fajlove..." )

   cF_path := AllTrim( flink_path() )
   cTmp := "*.inp"

   AEval( Directory( cF_path + cTmp ), {| aFile| FErase( cF_path +  AllTrim( aFile[ 1 ] ) ) } )

   Sleep( 1 )

   MsgC()

   RETURN .T.



/*
// fiskalno upisivanje robe
// cFPath - putanja do fajla
// aData - podaci racuna

FUNCTION fc_pos_art( cFPath, cFName, aData )

   LOCAL cSep := ";"
   LOCAL aPosData := {}
   LOCAL aStruct := {}

   // uzmi strukturu tabele za pos racun
   aStruct := _g_f_struct( F_POS_RN )

   // iscitaj pos matricu
   aPosData := __pos_art( aData )

   fiscal_array_to_file( cFPath, cFName, aStruct, aPosData )

   RETURN .T.
*/

// ------------------------------------------------------
// vraca popunjenu matricu za upis artikla u memoriju
// ------------------------------------------------------
STATIC FUNCTION __pos_art( aData )

   LOCAL aArr := {}
   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL i

   // ocekivana struktura
   // aData = { idroba, nazroba, cijena, kolicina, porstopa, plu }

   // nemam pojma sta ce ovdje biti logic ?
   cLogic := "1"

   FOR i := 1 TO Len( aData )
      cTmp := "U"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      // naziv artikla
      cTmp += AllTrim( aData[ i, 2 ] )
      cTmp += cSep
      // cjena 0-99999.99
      cTmp += AllTrim( Str( aData[ i, 3 ], 12, 2 ) )
      cTmp += cSep
      // kolicina 0-99999.99
      cTmp += AllTrim( Str( aData[ i, 4 ], 12, 2 ) )
      cTmp += cSep
      // stand od 1-9
      cTmp += "1"
      cTmp += cSep
      // grupa artikla 1-99
      cTmp += "1"
      cTmp += cSep
      // poreska grupa artikala 1 - 4
      cTmp += "1"
      cTmp += cSep
      // 0 ???
      cTmp += "0"
      cTmp += cSep
      // kod PLU
      cTmp += AllTrim( aData[ i, 1 ] )
      cTmp += cSep

      AAdd( aArr, { cTmp } )

   NEXT

   RETURN aArr


// ----------------------------------------
// vraca popunjenu matricu za ispis racuna
// ----------------------------------------
STATIC FUNCTION __pos_rn( aData, lStorno )

   LOCAL aArr := {}
   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL i
   LOCAL cRek_rn := ""
   LOCAL cRnBroj
   LOCAL nTotal := 0

   // ocekuje se matrica formata
   // aData { brrn, rbr, idroba, nazroba, cijena, kolicina, porstopa, rek_rn, plu, cVrPlacanja, nTotal }

   // !!! nije broj racuna !!!!
   // prakticno broj racuna
   // cLogic := ALLTRIM( aData[1, 1] )

   // broj racuna
   cRnBroj := AllTrim( aData[ 1, 1 ] )

   // logic je uvijek "1"
   cLogic := "1"

   IF lStorno == .T.

      cRek_rn := AllTrim( aData[ 1, 8 ] )

      cTmp := "K"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      cTmp += cRek_rn

      AAdd( aArr, { cTmp } )

   ENDIF

   FOR i := 1 TO Len( aData )

      cT_porst := aData[ i, 7 ]

      cTmp := "S"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      // naziv artikla
      cTmp += AllTrim( aData[ i, 4 ] )
      cTmp += cSep
      // cjena 0-99999.99
      cTmp += AllTrim( Str( aData[ i, 5 ], 12, 2 ) )
      cTmp += cSep
      // kolicina 0-99999.99
      cTmp += AllTrim( Str( aData[ i, 6 ], 12, 2 ) )
      cTmp += cSep
      // stand od 1-9
      cTmp += PadR( "1", 1 )
      cTmp += cSep
      // grupa artikla 1-99
      cTmp += "1"
      cTmp += cSep
      // poreska grupa artikala 1 - 4
      IF cT_porst == "E"
         cTmp += "2"
      ELSE
         cTmp += "1"
      ENDIF
      cTmp += cSep
      // -0 ???
      cTmp += "-0"
      cTmp += cSep
      // kod PLU
      cTmp += AllTrim( aData[ i, 3 ] )
      cTmp += cSep

      AAdd( aArr, { cTmp } )

   NEXT

   // podnozje
   cTmp := "Q"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += "1"
   cTmp += cSep
   cTmp += "pos rn: " + cRnBroj

   AAdd( aArr, { cTmp } )

   // vrsta placanja
   IF aData[ 1, 10 ] <> "0"

      nTotal := aData[ 1, 11 ]

      // zatvaranje racuna
      cTmp := "T"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      cTmp += aData[ 1, 10 ]
      cTmp += cSep
      cTmp += AllTrim( Str( aData[ 1, 11 ], 12, 2 ) )
      cTmp += cSep

      AAdd( aArr, { cTmp } )

   ENDIF

   // zatvaranje racuna
   cTmp := "T"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   RETURN aArr


// ----------------------------------------------------
// flink: unos pologa u printer
// ----------------------------------------------------
FUNCTION fl_polog( cFPath, cFName, nPolog )

   LOCAL cSep := ";"
   LOCAL aPolog := {}
   LOCAL aStruct := {}
   LOCAL GetList := {}

   IF nPolog == nil
      nPolog := 0
   ENDIF

   // ako je polog 0, pozovi formu za unos
   IF nPolog = 0

      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Zadužujem kasu za:" GET nPolog PICT "999999.99"
      READ
      BoxC()

      IF nPolog == 0
         MsgBeep( "Polog mora biti <> 0 !" )
         RETURN .F.
      ENDIF

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

   ENDIF

   cFName := f_filepos( "0" )

   // pobrisi ulazni direktorij
   fl_d_tmp()

   // izbrisi fajl greske odmah na pocetku ako postoji
   _f_err_delete( cFPath, cFName )

   // uzmi strukturu tabele za pos racun
   aStruct := _g_f_struct( F_POS_RN )

   // iscitaj pos matricu
   aPolog := _fl_polog( nPolog )

   fiscal_array_to_file( cFPath, cFName, aStruct, aPolog )

   RETURN .T.



// ----------------------------------------------------
// flink: reset racuna
// ----------------------------------------------------
FUNCTION fl_reset( cFPath, cFName )

   LOCAL cSep := ";"
   LOCAL aReset := {}
   LOCAL aStruct := {}

   // pobrisi ulazni direktorij
   fl_d_tmp()

   cFName := f_filepos( "0" )

   // izbrisi fajl greske odmah na pocetku ako postoji
   _f_err_delete( cFPath, cFName )

   // uzmi strukturu tabele za pos racun
   aStruct := _g_f_struct( F_POS_RN )

   // iscitaj pos matricu
   aReset := _fl_reset()

   fiscal_array_to_file( cFPath, cFName, aStruct, aReset )

   RETURN .T.




FUNCTION flink_dnevni_izvjestaj( cFPath, cFName )

   LOCAL cSep := ";"
   LOCAL aRpt := {}
   LOCAL aStruct := {}
   LOCAL cRpt := "Z"
   LOCAL GetList := {}

   Box(, 6, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Dnevni izvještaji:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Z - dnevni izvještaj"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "X - presjek stanja"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "         ------------>" GET cRpt VALID cRpt $ "ZX" PICT "@!"


   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // pobrisi ulazni direktorij
   fl_d_tmp()

   cFName := f_filepos( "0" )

   // izbrisi fajl greske odmah na pocetku ako postoji
   _f_err_delete( cFPath, cFName )

   // uzmi strukturu tabele za pos racun
   aStruct := _g_f_struct( F_POS_RN )

   // iscitaj pos matricu
   aRpt := _flink_dnevni_izvjestaj( cRpt )

   fiscal_array_to_file( cFPath, cFName, aStruct, aRpt )

   RETURN .T.



// ---------------------------------------------------
// unos pologa u printer
// ---------------------------------------------------
STATIC FUNCTION _fl_polog( nIznos )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}
   LOCAL cZnak := "0"

   // :tip
   // 0 - uplata
   // 1 - isplata

   IF nIznos < 0
      cZnak := "1"
   ENDIF

   cLogic := "1"

   cTmp := "I"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cZnak
   cTmp += cSep
   cTmp += AllTrim( Str( Abs( nIznos ) ) )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   RETURN aArr



// ---------------------------------------------------
// dnevni izvjestaj x i z
// ---------------------------------------------------
STATIC FUNCTION _flink_dnevni_izvjestaj( cTip )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"

   cTmp := cTip
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   RETURN aArr


// ---------------------------------------------------
// reset otvorenog racuna
// ---------------------------------------------------
STATIC FUNCTION _fl_reset()

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"

   cTmp := "N"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   RETURN aArr

/*
     _err_level := fakt_to_flink( id_firma, tip_dok, br_dok, _items_data, _partn_data, _storno )
*/

FUNCTION fakt_to_flink( hDeviceParams, cFirma, cTipDok, cBrDok )

   LOCAL aItems := {}
   LOCAL aTxt := {}
   LOCAL aPla_data := {}
   LOCAL aSem_data := {}
   LOCAL lStorno := .T.
   LOCAL aMemo := {}
   LOCAL nBrDok
   LOCAL nReklRn := 0
   LOCAL cStPatt := "/S"
   LOCAL GetList := {}
   LOCAL nStornoIdentifikator, nTRec

   SELECT fakt_doks
   SEEK cFirma + cTipDok + cBrDok

   flink_name( hDeviceParams[ "out_file" ] )
   flink_path( hDeviceParams[ "out_dir" ] )

   IF cStPatt $ AllTrim( field->brdok )  // ako je storno racun
      nReklRn := Val( StrTran( AllTrim( field->brdok ), cStPatt, "" ) )
   ENDIF

   nBrDok := Val( AllTrim( field->brdok ) )
   nTotal := field->iznos
   nNRekRn := 0

   IF nReklRn <> 0
      Box( , 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj rekl.fiskalnog racuna:"  GET nNRekRn PICT "99999" VALID ( nNRekRn > 0 )
      READ
      BoxC()
   ENDIF

   SELECT fakt
   SEEK cFirma + cTipDok + cBrDok

   nTRec := RecNo()

   // da li se radi o storno racunu ?
   DO WHILE !Eof() .AND. field->idfirma == cFirma .AND. field->idtipdok == cTipDok .AND. field->brdok == cBrDok

      IF field->kolicina > 0
         lStorno := .F.
         EXIT
      ENDIF
      SKIP

   ENDDO

   // nTipRac = 1 - maloprodaja
   // nTipRac = 2 - veleprodaja

   // nSemCmd = semafor komanda
   // 0 - stampa mp racuna
   // 1 - stampa storno mp racuna
   // 20 - stampa vp racuna
   // 21 - stampa storno vp racuna

   nSemCmd := 0
   nPartnId := 0

   IF cTipDok $ "10#"

      nTipRac := 2 // veleprodajni racun

      nPartnId := get_sifra_partner( fakt_doks->idpartner ) // daj mi partnera za ovu fakturu

      nSemCmd := 20 // stampa vp racuna

      IF lStorno == .T.
         // stampa storno vp racuna
         nSemCmd := 21
      ENDIF

   ELSEIF cTipDok $ "11#"

      // maloprodajni racun

      nTipRac := 1

      // nema parnera
      nPartnId := 0

      // stampa mp racuna
      nSemCmd := 0

      IF lStorno == .T.
         // stampa storno mp racuna
         nSemCmd := 1
      ENDIF

   ENDIF

   GO ( nTRec ) // vrati se opet na pocetak

   // upisi u [items] stavke
   DO WHILE !Eof() .AND. field->idfirma == cFirma .AND. field->idtipdok == cTipDok .AND. field->brdok == cBrDok

      SELECT roba
      SEEK fakt->idroba

      SELECT fakt

      nStornoIdentifikator := 0

      IF ( field->kolicina < 0 ) .AND. lStorno == .F.
         nStornoIdentifikator := 1
      ENDIF

      nSifRoba := _g_sdob( field->idroba )
      // cNazRoba := AllTrim( to_xml_encoding( roba->naz ) )
      cNazRoba := flink_konverzija_znakova( AllTrim( roba->naz ) )

      cBarKod := AllTrim( roba->barkod )
      nGrRoba := 1
      nPorStopa := 1
      nR_cijena := Abs( field->cijena )
      nR_kolicina := Abs( field->kolicina )

      AAdd( aItems, { nBrDok, ;
         nTipRac, ;
         nStornoIdentifikator, ;
         nSifRoba, ;
         cNazRoba, ;
         cBarKod, ;
         nGrRoba, ;
         nPorStopa, ;
         nR_cijena, ;
         nR_kolicina } )

      SKIP
   ENDDO

   // tip placanja
   // --------------------
   // 0 - gotovina
   // 1 - cek
   // 2 - kartica
   // 3 - virman

   nTipPla := 0

   IF lStorno == .F.
      // povrat novca
      nPovrat := 0
      // uplaceno novca
      nUplaceno := nTotal
   ELSE
      // povrat novca
      nPovrat := nTotal
      // uplaceno novca
      nUplaceno := 0
   ENDIF

   // upisi u [pla_data] stavke
   AAdd( aPla_data, { nBrDok,  nTipRac, nTipPla,  Abs( nUplaceno ), Abs( nTotal ),  Abs( nPovrat ) } )

   // RACUN.MEM data
   AAdd( aTxt, { "fakt: " + cTipDok + "-" + cBrDok } )

   // reklamirani racun uzmi sa box-a
   nReklRn := nNRekRn
   // print memo od - do
   nPrMemoOd := 1
   nPrMemoDo := 1

   // upisi stavke za [semafor]
   AAdd( aSem_data, { nBrDok, ;
      nSemCmd, ;
      nPrMemoOd, ;
      nPrMemoDo, ;
      nPartnId, ;
      nReklRn } )

   IF nTipRac == 2

      flink_racun_veleprodaja( flink_path(), aItems, aTxt, aPla_data, aSem_data )   // veleprodaja, posalji na fiskalni stampac

   ELSEIF nTipRac == 1

      flink_racun_maloprodaja( flink_path(), aItems, aTxt, aPla_data, aSem_data ) // maloprodaja posalji na fiskalni stampac

   ENDIF

   RETURN 0



FUNCTION flink_path( cSet )

   // RETURN PadR( "c:" + SLASH + "fiscal" + SLASH, 150 )
   IF cSet != NIL
      IF Right( cSet ) != SLASH
         cSet += SLASH
      ENDIF
      s_cPath := cSet
   ENDIF

   RETURN  s_cPath

FUNCTION flink_path2( cSet )

   IF cSet != NIL
      IF Right( cSet ) != SLASH
         cSet += SLASH
      ENDIF
      s_cPath2 := cSet
   ENDIF
   // RETURN PadR( "", 150 )

   RETURN s_cPath2


FUNCTION flink_name( cSet )

   // RETURN  PadR( "OUT.TXT", 150 )
   IF cSet != NIL
      s_cName := cSet
   ENDIF

   RETURN s_cName


FUNCTION flink_type()

   RETURN "FPRINT"


// ------------------------------------------------
// vraca sifru dobavljaca
// ------------------------------------------------
STATIC FUNCTION _g_sdob( id_roba )

   LOCAL _ret := 0
   LOCAL nDbfArea := Select()

   SELECT roba
   SEEK id_roba

   IF Found()
      _ret := Val( AllTrim( field->sifradob ) )
   ENDIF

   SELECT ( nDbfArea )

   RETURN _ret



STATIC FUNCTION get_sifra_partner( id_partner )

   LOCAL _ret := 0
   LOCAL _tmp

   _tmp := Right( AllTrim( id_partner ), 5 )
   _ret := Val( _tmp )

   RETURN _ret


STATIC FUNCTION flink_konverzija_znakova( cIn )

   LOCAL cOut := cIn

   cOut := StrTran( cOut, hb_UTF8ToStr( "š" ), "s" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Š" ), "S" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "ć" ), "c" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Ć" ), "C" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "č" ), "c" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Č" ), "C" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "ž" ), "z" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Ž" ), "Z" )

   RETURN cOut
