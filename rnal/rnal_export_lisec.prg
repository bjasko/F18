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

// static variables
STATIC __REL_VER
STATIC __REL
STATIC __ORD
STATIC __POS
STATIC __PO2
STATIC __GLX
STATIC __FRX
STATIC __TXT
STATIC __TX2
STATIC __TX3
STATIC __SPACE



// --------------------------------------------
// setovanje i definicija kljucnih rijeci
// setovanje statickih varijabli
// --------------------------------------------
FUNCTION lisec_init_static_vars()

   __REL_VER := "02.60"
   __REL := "<REL>"
   __ORD := "<ORD>"
   __POS := "<POS>"
   __PO2 := "<PO2>"
   __TXT := "<TXT>"
   __TX2 := "<TX2>"
   __TX3 := "<TX3>"
   __GLX := "<GLx>"
   __FRX := "<FRx>"
   __SPACE := Space( 1 )

   RETURN


// ---------------------------------------------
// <REL>
// Transfer file release version (file version)
// ---------------------------------------------

// ------------------------------
// dodaj u record <REL>
// ------------------------------
FUNCTION add_rel( cRelAddInfo )

   LOCAL aRel := {}

   lisec_init_static_vars()

   IF Empty( cRelAddInfo ) .OR. cRelAddInfo == nil
      cRelAddInfo := ""
   ENDIF

   AAdd( aRel, __REL )
   AAdd( aRel, __REL_VER )
   AAdd( aRel, cRelAddInfo )

   RETURN aRel




// -----------------------------------------------
// vraca specifikaciju recorda <REL>
// -----------------------------------------------
FUNCTION _get_rel()

   LOCAL aRelSpec := {}

   lisec_init_static_vars()

   AAdd( aRelSpec, { __REL,     "C", 5 } )
   AAdd( aRelSpec, { "REL_NUM", "N", 2.2 } )
   AAdd( aRelSpec, { "REL_INFO", "C", 40 } )

   RETURN aRelSpec



// ---------------------------------------------
// <ORD>
// Order record
// ---------------------------------------------

// ------------------------------
// dodaj u record <ORD>
// ------------------------------
FUNCTION add_ord( nOrd_no, ;
      nCust_id, ;
      cCust_name, ;
      cText1, ;
      cText2, ;
      cText3, ;
      cText4, ;
      cText5, ;
      dDoc_date, ;
      dDoc_dvr_date, ;
      cDvr_ship )

   LOCAL aOrd := {}

   lisec_init_static_vars()

   AAdd( aOrd, __ORD )
   AAdd( aOrd, nOrd_no )
   AAdd( aOrd, AllTrim( Str( nCust_id ) ) )
   AAdd( aOrd, cCust_name )
   AAdd( aOrd, cText1 )
   AAdd( aOrd, cText2 )
   AAdd( aOrd, cText3 )
   AAdd( aOrd, cText4 )
   AAdd( aOrd, cText5 )
   AAdd( aOrd, conv_date( dDoc_date ) )
   AAdd( aOrd, conv_date( dDoc_dvr_date ) )
   AAdd( aOrd, cDvr_ship )

   RETURN aOrd



// -----------------------------------------------
// vraca specifikaciju recorda <ORD>
// -----------------------------------------------
FUNCTION _get_ord()

   LOCAL aOrdSpec := {}

   lisec_init_static_vars()

   AAdd( aOrdSpec, { __ORD,      "C",    5 } )
   AAdd( aOrdSpec, { "ORD",      "N",   10 } )
   AAdd( aOrdSpec, { "CUST_NUM", "C",   10 } )
   AAdd( aOrdSpec, { "CUST_NAM", "C",   40 } )
   AAdd( aOrdSpec, { "TEXT1",    "C",   40 } )
   AAdd( aOrdSpec, { "TEXT2",    "C",   40 } )
   AAdd( aOrdSpec, { "TEXT3",    "C",   40 } )
   AAdd( aOrdSpec, { "TEXT4",    "C",   40 } )
   AAdd( aOrdSpec, { "TEXT5",    "C",   40 } )
   AAdd( aOrdSpec, { "PRD_DATE", "C",   10 } )
   AAdd( aOrdSpec, { "DEL_DATE", "C",   10 } )
   AAdd( aOrdSpec, { "DEL_AREA", "C",   10 } )

   RETURN aOrdSpec



// ------------------------------------
// konverzija datuma
// 01.01.2007 => 01/01/2007
// #format = "DD/MM/YYYY"
// ------------------------------------
STATIC FUNCTION conv_date( dDate )

   LOCAL cDate

   cDate := ""
   cDate += PadL( AllTrim( Str( Day( dDate ) ) ), 2, "0" )
   cDate += "/"
   cDate += PadL( AllTrim( Str( Month( dDate ) ) ), 2, "0" )
   cDate += "/"
   cDate += Str( Year( dDate ), 4 )

   RETURN cDate


// ---------------------------------------------
// <POS>
// Item record
// ---------------------------------------------

// ------------------------------
// dodaj u record <POS>
// ------------------------------
FUNCTION add_pos( nItem_no, ;
      cId_no, ;
      nBarCode, ;
      nQty, ;
      nWidth, ;
      nHeight, ;
      cGlass1, ;
      cFrame1, ;
      cGlass2, ;
      cFrame2, ;
      cGlass3, ;
      nInset, ;
      nFrame_txt, ;
      nGas_code1, ;
      nGas_code2, ;
      nSeal_type, ;
      nFrah_type, ;
      nFrah_hoe, ;
      nPattDir )

   LOCAL aPos := {}

   lisec_init_static_vars()

   AAdd( aPos, __POS )
   AAdd( aPos, nItem_no )
   AAdd( aPos, cId_no )
   AAdd( aPos, nBarcode )
   AAdd( aPos, nQty )
   AAdd( aPos, recalc_dim_za_lisec( nWidth ) )
   AAdd( aPos, recalc_dim_za_lisec( nHeight ) )
   AAdd( aPos, cGlass1 )
   AAdd( aPos, cFrame1 )
   AAdd( aPos, cGlass2 )
   AAdd( aPos, cFrame2 )
   AAdd( aPos, cGlass3 )
   AAdd( aPos, nInset )
   AAdd( aPos, nFrame_txt )
   AAdd( aPos, nGas_code1 )
   AAdd( aPos, nGas_code2 )
   AAdd( aPos, nSeal_type )
   AAdd( aPos, nFrah_type )
   AAdd( aPos, nFrah_hoe )
   AAdd( aPos, nPattdir )

   RETURN aPos



// -----------------------------------------------
// vraca specifikaciju recorda <POS>
// -----------------------------------------------
FUNCTION _get_pos()

   LOCAL aPosSpec := {}

   lisec_init_static_vars()

   AAdd( aPosSpec, { __POS,      "C",    5 } )
   AAdd( aPosSpec, { "ITEM_NUM", "N",    5 } )
   AAdd( aPosSpec, { "ID_NUM",   "C",    8 } )
   AAdd( aPosSpec, { "BARCODE",  "N",    4 } )
   AAdd( aPosSpec, { "QTY",      "N",    5 } )
   AAdd( aPosSpec, { "WIDTH",    "N",    5 } )
   AAdd( aPosSpec, { "HEIGHT",   "N",    5 } )
   AAdd( aPosSpec, { "GLASS1",   "C",    5 } )
   AAdd( aPosSpec, { "FRAME1",   "C",    3 } )
   AAdd( aPosSpec, { "GLASS2",   "C",    5 } )
   AAdd( aPosSpec, { "FRAME2",   "C",    3 } )
   AAdd( aPosSpec, { "GLASS3",   "C",    5 } )
   AAdd( aPosSpec, { "INSET",    "N",    3 } )
   AAdd( aPosSpec, { "FRAME_TXT",  "N",    2 } )
   AAdd( aPosSpec, { "GAS_CODE1",  "N",    2 } )
   AAdd( aPosSpec, { "GAS_CODE2",  "N",    2 } )
   AAdd( aPosSpec, { "SEAL_TYPE",  "N",    1 } )
   AAdd( aPosSpec, { "FRAH_TYPE",  "N",    1 } )
   AAdd( aPosSpec, { "FRAH_HOE",  "N",    5 } )
   AAdd( aPosSpec, { "PATT_DIR",  "N",    1 } )

   RETURN aPosSpec


/*
   rekalkulisi kalkulisi dimenziju na n/10 mm
   jer je u lisec/GPS.opt to jedinica mjere
*/

STATIC FUNCTION recalc_dim_za_lisec( nDim )

   LOCAL xRet := 0

   IF nDim = 0
      xRet := nDim
   ENDIF

   xRet := nDim * 10

   RETURN xRet



// ---------------------------------------------
// <PO2>
// Additional record information
// ---------------------------------------------

// ------------------------------
// dodaj u record <PO2>
// -----------------------------
FUNCTION add_po2( cIdCode, ;
      nW1, nH1, ;
      nG1_bott, nG1_rig, nG1_top, nG1_left, ;
      nS1_bott, nS1_rig, nS1_top, nS1_left, ;
      nW2, nH2, ;
      nG2_bott, nG2_rig, nG2_top, nG2_left, ;
      nS2_bott, nS2_rig, nS2_top, nS2_left, ;
      nOff2x, nOff2y, ;
      nW3, nH3, ;
      nG3_bott, nG3_rig, nG3_top, nG3_left, ;
      nS3_bott, nS3_rig, nS3_top, nS3_left, ;
      nOff3x, nOff3y )

   LOCAL aPo2 := {}

   lisec_init_static_vars()

   AAdd( aPo2, __PO2 )
   AAdd( aPo2, cIdCode )
   AAdd( aPo2, recalc_dim_za_lisec( nW1 ) )
   AAdd( aPo2, recalc_dim_za_lisec( nH1 ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG1_bott ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG1_rig ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG1_top ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG1_left ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS1_bott ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS1_rig ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS1_top ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS1_left ) )
   AAdd( aPo2, recalc_dim_za_lisec( nW2 ) )
   AAdd( aPo2, recalc_dim_za_lisec( nH2 ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG2_bott ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG2_rig ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG2_top ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG2_left ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS2_bott ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS2_rig ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS2_top ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS2_left ) )
   AAdd( aPo2, recalc_dim_za_lisec( nOff2x ) )
   AAdd( aPo2, recalc_dim_za_lisec( nOff2y ) )
   AAdd( aPo2, recalc_dim_za_lisec( nW3 ) )
   AAdd( aPo2, recalc_dim_za_lisec( nH3 ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG3_bott ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG3_rig ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG3_top ) )
   AAdd( aPo2, recalc_dim_za_lisec( nG3_left ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS3_bott ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS3_rig ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS3_top ) )
   AAdd( aPo2, recalc_dim_za_lisec( nS3_left ) )
   AAdd( aPo2, recalc_dim_za_lisec( nOff3x ) )
   AAdd( aPo2, recalc_dim_za_lisec( nOff3y ) )

   RETURN aPo2


// -----------------------------------------------
// vraca specifikaciju recorda <PO2>
// dodatne informacije na samom rekordu iz <POS>
// -----------------------------------------------
FUNCTION _get_po2()

   LOCAL aPO2Spec := {}

   lisec_init_static_vars()

   AAdd( aPO2Spec, { __PO2,        "C",    5 } )
   AAdd( aPO2Spec, { "ID_CODE",    "C",   40 } )
   AAdd( aPO2Spec, { "WIDTH1",     "N",    5 } )
   AAdd( aPO2Spec, { "HEIGHT1",    "N",    5 } )
   AAdd( aPO2Spec, { "GA1_BOTT",   "N",    4 } )
   AAdd( aPO2Spec, { "GA1_RIGHT",  "N",    4 } )
   AAdd( aPO2Spec, { "GA1_TOP",    "N",    4 } )
   AAdd( aPO2Spec, { "GA1_LEFT",   "N",    4 } )
   AAdd( aPO2Spec, { "ST1_BOTT",   "N",    5 } )
   AAdd( aPO2Spec, { "ST1_RIGHT",  "N",    5 } )
   AAdd( aPO2Spec, { "ST1_TOP",    "N",    5 } )
   AAdd( aPO2Spec, { "ST1_LEFT",   "N",    5 } )
   AAdd( aPO2Spec, { "WIDTH2",     "N",    5 } )
   AAdd( aPO2Spec, { "HEIGHT2",    "N",    5 } )
   AAdd( aPO2Spec, { "GA2_BOTT",   "N",    4 } )
   AAdd( aPO2Spec, { "GA2_RIGHT",  "N",    4 } )
   AAdd( aPO2Spec, { "GA2_TOP",    "N",    4 } )
   AAdd( aPO2Spec, { "GA2_LEFT",   "N",    4 } )
   AAdd( aPO2Spec, { "ST2_BOTT",   "N",    5 } )
   AAdd( aPO2Spec, { "ST2_RIGHT",  "N",    5 } )
   AAdd( aPO2Spec, { "ST2_TOP",    "N",    5 } )
   AAdd( aPO2Spec, { "ST2_LEFT",   "N",    5 } )
   AAdd( aPO2Spec, { "OFFS2_X",    "N",    5 } )
   AAdd( aPO2Spec, { "OFFS2_Y",    "N",    5 } )
   AAdd( aPO2Spec, { "WIDTH3",     "N",    5 } )
   AAdd( aPO2Spec, { "HEIGHT3",    "N",    5 } )
   AAdd( aPO2Spec, { "GA3_BOTT",   "N",    4 } )
   AAdd( aPO2Spec, { "GA3_RIGHT",  "N",    4 } )
   AAdd( aPO2Spec, { "GA3_TOP",    "N",    4 } )
   AAdd( aPO2Spec, { "GA3_LEFT",   "N",    4 } )
   AAdd( aPO2Spec, { "ST3_BOTT",   "N",    5 } )
   AAdd( aPO2Spec, { "ST3_RIGHT",  "N",    5 } )
   AAdd( aPO2Spec, { "ST3_TOP",    "N",    5 } )
   AAdd( aPO2Spec, { "ST3_LEFT",   "N",    5 } )
   AAdd( aPO2Spec, { "OFFS3_X",    "N",    5 } )
   AAdd( aPO2Spec, { "OFFS3_Y",    "N",    5 } )

   RETURN aPO2Spec



// ---------------------------------------------
// <GLx>
// Glass record information
// ---------------------------------------------

// ------------------------------
// dodaj u record <GLx>
// -----------------------------
FUNCTION add_glx( cGlassNo, cIdCode )

   LOCAL aGLx := {}

   lisec_init_static_vars()

   AAdd( aGLx, StrTran( __GLX, "x", cGlassNo ) )
   AAdd( aGLx, cIdCode )

   // dodaci na liniju
   AAdd( aGLx, 1 )
   AAdd( aGLx, 0 )
   AAdd( aGLx, 0 )
   AAdd( aGLx, "" )
   AAdd( aGLx, 0 )

   RETURN aGLx


// -----------------------------------------------
// vraca specifikaciju recorda <GLx>
// -----------------------------------------------
FUNCTION _get_glx()

   LOCAL aGLxSpec := {}

   lisec_init_static_vars()

   AAdd( aGLxSpec, { __GLX,        "C",   5 } )
   AAdd( aGLxSpec, { "DESCRIPT",   "C",  40 } )
   AAdd( aGLxSpec, { "TYPE",       "N",   1 } )
   AAdd( aGLxSpec, { "THICKNESS",  "N",   5 } )
   AAdd( aGLxSpec, { "FACE_SIDE",  "N",   1 } )
   AAdd( aGLxSpec, { "IDENT",      "C",  10 } )
   AAdd( aGLxSpec, { "PATT_DIR",   "N",   1 } )

   RETURN aGLxSpec


// ---------------------------------------------
// <FRx>
// Frame record information
// ---------------------------------------------

// ------------------------------
// dodaj u record <FRx>
// -----------------------------
FUNCTION add_frx( cFrameNo, cIdCode )

   LOCAL aFrx := {}

   lisec_init_static_vars()

   AAdd( aFRx, StrTran( __FRX, "x", cFrameNo ) )
   AAdd( aFRx, cIdCode )

   RETURN aFRx


// -----------------------------------------------
// vraca specifikaciju recorda <FRx>
// -----------------------------------------------
FUNCTION _get_frx()

   LOCAL aFRxSpec := {}

   lisec_init_static_vars()

   AAdd( aFRxSpec, { __FRX,      "C",    5 } )
   AAdd( aFRxSpec, { "DESCRIPT", "C",   40 } )
   AAdd( aFRxSpec, { "TYPE",     "N",    1 } )
   AAdd( aFRxSpec, { "WIDTH",    "N",    5 } )
   AAdd( aFRxSpec, { "HEIGHT",   "N",    5 } )
   AAdd( aFRxSpec, { "IDENT",    "C",   10 } )

   RETURN aFRxSpec



// ---------------------------------------------
// <TXT>
// Additional record information
// ---------------------------------------------

// ------------------------------
// dodaj u record <TXT>
// -----------------------------
FUNCTION add_txt( nVar, cT1, cT2, cT3, cT4, cT5, cT6, cT7, cT8, cT9, cT10 )

   LOCAL aTxt := {}

   lisec_init_static_vars()

   IF nVar == nil
      nVar := 1
   ENDIF

   IF nVar == 1
      AAdd( aTxt, __TXT )
   ENDIF

   IF nVar == 2
      AAdd( aTxt, __TX2 )
   ENDIF

   IF nVar == 3
      AAdd( aTxt, __TX3 )
   ENDIF

   AAdd( aTxt, cT1 )
   AAdd( aTxt, cT2 )
   AAdd( aTxt, cT3 )
   AAdd( aTxt, cT4 )
   AAdd( aTxt, cT5 )
   AAdd( aTxt, cT6 )
   AAdd( aTxt, cT7 )
   AAdd( aTxt, cT8 )
   AAdd( aTxt, cT9 )
   AAdd( aTxt, cT10 )

   RETURN aTxt


// -----------------------------------------------
// vraca specifikaciju recorda <TXT>
// -----------------------------------------------
FUNCTION _get_txt( nVar )

   LOCAL aTxtSpec := {}

   lisec_init_static_vars()

   IF nVar == nil
      nVar := 1
   ENDIF

   IF nVar == 1
      AAdd( aTxtSpec, { __TXT,      "C",    5 } )
   ENDIF

   IF nVar == 2
      AAdd( aTxtSpec, { __TX2,      "C",    5 } )
   ENDIF

   IF nVar == 3
      AAdd( aTxtSpec, { __TX3,      "C",    5 } )
   ENDIF

   AAdd( aTxtSpec, { "TEXT1",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT2",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT3",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT4",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT5",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT6",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT7",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT8",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT9",   "C",   40 } )
   AAdd( aTxtSpec, { "TEXT10",  "C",   40 } )

   RETURN aTxtSpec



// ----------------------------------------
// ispisi vrijednosti recorda
// na osnovu aRec podataka
// i na osnovu aSpec - specifikacije polja
// ----------------------------------------
FUNCTION write_rec( nH, aRec, aSpec )

   LOCAL i
   LOCAL nI
   LOCAL nII
   LOCAL cTmp := ""
   LOCAL cType
   LOCAL nLen
   LOCAL xVal
   LOCAL nVal1
   LOCAL nVal2
   LOCAL cTrans
   LOCAL aPom

   lisec_init_static_vars()

   FOR i := 1 TO Len( aRec )

      // dodaj space, ali ne na prvoj
      IF i <> 1

         cTmp += __SPACE

      ENDIF

      xVal := aRec[ i ]
      cType := aSpec[ i, 2 ]
      nLen := aSpec[ i, 3 ]

      IF xVal == NIL .OR. Empty( xVal )
         xVal := " "
      ENDIF

      // karakterni tip
      IF cType == "C"

         cTmp += PadR( xVal, nLen, " " )

      ENDIF

      // numericki tip
      IF cType == "N"

         aPom := TokToNiz( AllTrim( Str( nLen ) ), "." )
         nVal1 := 0
         nVal2 := 0

         FOR nI := 1 TO Len( aPom )

            IF nI == 1
               nVal1 := Val( aPom[ nI ] )
            ENDIF

            IF nI == 2
               nVal2 := Val( aPom[ nI ] )
            ENDIF

         NEXT

         cTrans := Replicate( "9", nVal1 )

         IF nVal2 > 0
            cTrans += "." + Replicate( "9", nVal2 )
         ENDIF

         nTmpLen := Len( cTrans )

         IF ValType( xVal ) == "N"

            cTmp += PadL( AllTrim( Str( xVal, nVal1, nVal2 ) ), nTmpLen, "0" )

         ENDIF

         IF ValType( xVal ) == "C"

            IF xVal == " "
               xVal := 0
            ENDIF


            cTmp += PadL ( AllTrim( Transform( xVal, cTrans ) ), nTmpLen, "0" )

         ENDIF

      ENDIF

   NEXT

   write2file( nH, cTmp, .T. )

   RETURN
