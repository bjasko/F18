#include "f18.ch"

STATIC aHeader := {}
STATIC aZaglLen := {}

STATIC aZagl := {}
STATIC lSvakaHeader := .F.

STATIC dDatOd
STATIC dDatDo

// report area
STATIC nRArea

// kumulativ area
STATIC nKArea

// bez path-a npr: R_KUF
STATIC cTbl

// tekuca linija reporta
STATIC nCurrLine := 0

STATIC cRptNaziv := "Lista dokumenata na dan "


FUNCTION epdv_r_lista( cTName )

   LOCAL aDInt, nX
   LOCAL GetList := {}

   aZaglLen := { 8, 8, 8, 8, Len( PIC_IZN() ), Len( PIC_IZN() ), Len( PIC_IZN() ) }

   IF cTName == "KUF"
      nRArea := F_R_KUF
      nKArea := F_KUF
      cTbl := "epdv_r_kuf"
   ELSE
      nRArea := F_R_KIF
      nKArea := F_KIF
      cTbl := "epdv_r_kif"
   ENDIF

   aDInt := epdv_rpt_d_interval ( Date() )

   dDate := Date()

   dDatOd := aDInt[ 1 ]
   dDatDo := Date()


   nX := 1
   Box(, 8, 60 )
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Period"
   nX++

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "od " GET dDatOd
   @ box_x_koord() + nX, Col() + 2 SAY "do " GET dDatDo

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY Replicate( "-", 30 )

   READ
   BoxC()

   IF LastKey() == K_ESC
      my_close_all_dbf()
      RETURN .F.
   ENDIF


   aHeader := {}
   AAdd( aHeader, "Preduzece: " + self_organizacija_naziv() )
   AAdd( aHeader, cTName + " : " + cRptNaziv +  DToC( dDate ) + ", za period :" + DToC( dDatOd ) + "-" + DToC( dDatDo ) )

   aZagl := {}
   AAdd( aZagl, { "Broj",  "Datum",  "Dat.d", "Dat.d",    "iznos", "iznos",    "iznos" } )
   AAdd( aZagl, { "dok.",  "azur.",    "min",  "max",  "bez PDV", "PDV", "sa PDV" } )
   AAdd( aZagl, { "(1)",     "(2)",      "(3)",  "(4)",  "(5)",  "(6)", "(7)" } )


   epdv_fill_rpt()
   show_rpt(  .F.,  .F. )

   my_close_all_dbf()

STATIC FUNCTION epdv_fill_rpt()

   LOCAL nCount
   LOCAL hParams := hb_Hash()
   LOCAL nBrDok

// + stavka preknjizenja = pdv
// - stavka = ppp

   cre_r_tbl()

   hParams[ "datum_2" ] := .T.

   IF ( nRArea == F_R_KUF )
      select_o_epdv_r_kuf()
      // select_o_epdv_kuf()
      // SET ORDER TO TAG "br_dok"
      find_epdv_kuf_za_period( dDatOd, dDatDo, hParams, "br_dok" )

   ELSE
      select_o_epdv_r_kif()
      // select_o_epdv_kif()
      // SET ORDER TO TAG "br_dok"
      find_epdv_kif_za_period( dDatOd, dDatDo, hParams, "br_dok" )

   ENDIF


   SELECT ( nKArea )
// datum azuriranja

   PRIVATE cFilter := dbf_quote( dDatOd ) + " <= datum_2 .and. " + dbf_quote( dDatDo ) + ">= datum_2"

   SET FILTER TO &cFilter

   GO TOP


   Box(, 3, 60 )

   nCount := 0

   DO WHILE !Eof()

      ++nCount
      @ box_x_koord() + 2, box_y_koord() + 2 SAY Str( nCount, 6, 0 )

      nBrDok := field->br_dok
      nBPdv := 0
      nPdv := 0
      dDatAz := CToD( "" )
      dDMin := Date() + 100
      dDMax := CToD( "" )

      DO WHILE !Eof() .AND. field->br_dok == nBrDok

// datum je manji od trenutnog min datuma
         IF dDMin > field->datum
            dDmin := field->datum
         ENDIF

// datum veci od trenutnog max datuma
         IF dDMax < field->datum
            dDMax := field->datum
         ENDIF

         nBPdv += field->i_b_pdv
         nPdv += field->i_pdv
         dDatAz := field->datum_2

         SKIP
      ENDDO

      SELECT ( nRArea )
      APPEND BLANK
      REPLACE br_dok WITH nBrDok

      REPLACE dat_az WITH dDatAz
      REPLACE d_d_min WITH dDMin
      REPLACE d_d_max WITH dDMax

      REPLACE i_b_pdv WITH nBPdv
      REPLACE i_pdv WITH nPdv

      SELECT ( nKArea )

   ENDDO

   BoxC()

   SELECT ( nKArea )
   SET FILTER TO

   RETURN .T.



STATIC FUNCTION show_rpt()

   nCurrLine := 0


   START PRINT CRET
   ?

   nPageLimit := 65
   nRow := 0

   r_zagl()

   SELECT ( nRArea )
   SET ORDER TO TAG "1"
   GO TOP
   nRbr := 0

   nBPdv := 0
   nPdv :=  0
   DO WHILE !Eof()

      ++nCurrLine

      ?
      // broj dokumenta
      ?? PadL( field->br_dok, aZaglLen[ 1 ] )
      ?? " "

      // datum azuriranja
      ?? PadL( field->dat_az, aZaglLen[ 2 ] )
      ?? " "

      // datum dokumenta min
      ?? PadL( field->d_d_min, aZaglLen[ 3 ] )
      ?? " "

      // datum dokumenta max
      ?? PadL( field->d_d_max, aZaglLen[ 3 ] )
      ?? " "

      // bez pdv
      ?? Transform( field->i_b_pdv,  PIC_IZN() )
      ?? " "

      // pdv
      ?? Transform( field->i_pdv,  PIC_IZN() )
      ?? " "

      // sa pdv
      ?? Transform( field->i_b_pdv + field->i_pdv,  PIC_IZN() )
      ?? " "


      nBPdv += field->i_b_pdv
      nPdv += field->i_pdv

      IF nCurrLine > nPageLimit
         FF
         nCurrLine := 0
         IF lSvakaHeader
            r_zagl()
         ENDIF

      ENDIF

      SKIP

   ENDDO

   IF ( nCurrLine + 3 ) > nPageLimit
      FF
      nCurrLine := 0
      IF lSvakaHeader
         r_zagl()
      ENDIF
   ENDIF


// ukupno izvjestaj
   r_linija()
   ?
   cPom := "U K U P N O :"
   ?? PadR( cPom, aZaglLen[ 1 ] + 3 * 8 + 3 )
   ?? " "
   ?? Transform( nBPdv, PIC_IZN() )
   ?? " "

   ?? Transform( nPdv, PIC_IZN() )
   ?? " "

   ?? Transform( nBPdv + nPdv, PIC_IZN() )

   r_linija()


   FF
   ENDPRINT

   RETURN .T.


STATIC FUNCTION r_zagl()

   LOCAL i

   P_12CPI
   B_ON
   FOR i := 1 TO Len( aHeader )
      ? aHeader[ i ]
      ++nCurrLine
   NEXT
   B_OFF

   P_12CPI

   r_linija()

   FOR i := 1 TO Len( aZagl )
      ++nCurrLine
      ?
      FOR nCol := 1 TO Len( aZaglLen )
         // mergirana kolona ovako izgleda
// "#3 Zauzimam tri kolone"
         IF Left( aZagl[ i, nCol ], 1 ) = "#"

            nMergirano := Val( SubStr( aZagl[ i, nCol ], 2, 1 ) )
            cPom := SubStr( aZagl[ i, nCol ], 3, Len( aZagl[ i, nCol ] ) - 2 )
            nMrgWidth := 0
            FOR nMrg := 1 TO nMergirano
               nMrgWidth += aZaglLen[ nCol + nMrg - 1 ]
               nMrgWidth++
            NEXT
            ?? PadC( cPom, nMrgWidth )
            ?? " "
            nCol += ( nMergirano - 1 )
         ELSE
            ?? PadC( aZagl[ i, nCol ], aZaglLen[ nCol ] )
            ?? " "
         ENDIF
      NEXT
   NEXT
   r_linija()

   RETURN .T.



STATIC FUNCTION get_r_fields( aArr )

   AAdd( aArr, { "br_dok",   "N",  6, 0 } )
   AAdd( aArr, { "dat_az",   "D",  8, 0 } )
   // datum dokumenta min - max
   AAdd( aArr, { "d_d_min",   "D",  8, 0 } )
   AAdd( aArr, { "d_d_max",   "D",  8, 0 } )
   AAdd( aArr, { "i_b_pdv",   "N",  18, 2 } )
   AAdd( aArr, { "i_pdv",   "N",  18, 2 } )

   RETURN .T.


STATIC FUNCTION cre_r_tbl()

   LOCAL aArr := {}

   my_close_all_dbf()

   ferase_dbf ( cTbl )

   get_r_fields( @aArr )

   dbcreate2( cTbl, aArr )
   CREATE_INDEX( "br_dok", "br_dok", cTbl, .T. )

   RETURN .T.


STATIC FUNCTION r_linija()

   LOCAL i

   ++nCurrLine
   ?
   FOR i = 1 TO Len( aZaglLen )
      ?? PadR( "-", aZaglLen[ i ], "-" )
      ?? " "
   NEXT

   RETURN .T.
