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

#include "f18.ch"

MEMVAR m_x, m_y

FUNCTION TAppModNew( oParent, cVerzija, cPeriod, cKorisn, cSifra, p3, p4, p5, p6, p7 )

   LOCAL oObj

   oObj := TAppMod():new()

   RETURN oObj


CLASS TAppMod

   DATA cName
   DATA oParent
   DATA oDesktop
   DATA cVerzija
   DATA cPeriod
   DATA cKorisn
   DATA cSifra
   DATA cP3
   DATA cP4
   DATA cP5
   DATA cP6
   DATA cP7
   DATA cSqlLogBase
   DATA lSqlDirektno
   DATA lStarted
   DATA lTerminate

   METHOD NEW
   METHOD hasParent
   METHOD setParent
   METHOD getParent
   METHOD setName
   METHOD RUN
   METHOD QUIT
   METHOD gProc
   METHOD gParams
   METHOD setTGVars

ENDCLASS



METHOD New( oParent, cModul, cVerzija, cPeriod, cKorisn, cSifra, p3, p4, p5, p6, p7 ) CLASS TAppMod

   ::lStarted := nil

   ::cName := cModul
   ::oParent := oParent
   ::cVerzija := cVerzija
   ::cPeriod := cPeriod
   ::cKorisn := cKorisn
   ::cSifra := cSifra
   ::cP3 := p3
   ::cP4 := p4
   ::cP5 := p5
   ::cP6 := p6
   ::cP7 := p7
   ::lTerminate := .F.

   RETURN .T.



METHOD hasParent()

   RETURN !( ::oParent == nil )




METHOD setParent( oParent )

   ::parent := oParent

   RETURN .T.


METHOD getParent()
   return ::oParent



METHOD setName()

   ::cName := "F18"

   RETURN .T.



METHOD run()

   if ::oDesktop == NIL
      ::oDesktop := TDesktopNew()
   ENDIF

   if ::lStarted == NIL
      ::lStarted := .F.
   ENDIF

   //add_idle_handlers()  BUG_CPU100
   start_f18_program_module( self, .T. )

   ::lStarted := .T.

   if ::lTerminate
      ::quit()
      RETURN .F.
   ENDIF

   ::MMenu() // osnovni meni programskog modula

   remove_idle_handlers()

   RETURN .T.


METHOD gProc( Ch )

   LOCAL lPushWa
   LOCAL nI

   DO CASE

#ifdef __PLATFORM__DARWIN
   CASE ( Ch == K_F12 )
#else
   CASE ( Ch == K_INS )
#endif
      show_insert_over_stanje( .T. )
      RETURN DE_CONT

   CASE Ch == Asc( "i" ) .OR. Ch == Asc( "I" )
      show_infos()
      RETURN DE_CONT

   CASE Ch == Asc( "e" ) .OR. Ch == Asc( "E" )
      show_errors()
      RETURN DE_CONT

   CASE ( Ch == K_SH_F1 )
      Calc()

   CASE ( Ch == K_SH_F6 )
      f18_promjena_sezone()

   CASE ( Ch == K_SH_F2 .OR. Ch == K_CTRL_F2 )
      PPrint()

   CASE Ch == K_SH_F10
      ::gParams()

   CASE Ch == K_SH_F9
      Adresar()

   OTHERWISE
      IF !( "U" $ Type( "gaKeys" ) )
         FOR nI := 1 TO Len( gaKeys )
            IF ( Ch == gaKeys[ nI, 1 ] )
               Eval( gaKeys[ nI, 2 ] )
            ENDIF
         NEXT
      ENDIF
   ENDCASE

   RETURN .T.



/*   izlazak iz aplikacijskog modula
 *  lVratiSeURP - default vrijednost .t.; kada je .t. vrati se u radno podrucje; .f. ne mjenjaj radno podrucje
 */

METHOD quit( lVratiseURP )

   LOCAL cKontrDbf

   my_close_all_dbf()

   IF ( lVratiseURP == nil )
      lVratiseURP := .T.
   ENDIF

   RETURN .T.

::lTerminate := .T.

CLEAR SCREEN

IF !( ::hasParent() )
QUIT_1
ENDIF

   RETURN .T.



METHOD gParams()

   LOCAL cFMKINI := "N"
   LOCAL cPosebno := "N"
   LOCAL cInstall := "N"
   LOCAL lPushWa := .F.
   PRIVATE GetList := {}

   IF Used()
      lPushWa := .T.
      PushWA()
   ELSE
      lPushWa := .F.
   ENDIF

   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   SELECT ( F_PARAMS )
   USE
   O_PARAMS

   RPar( "p?", @cPosebno )

   gArhDir := PadR( gArhDir, 100 )
   gPFont := PadR( gPFont, 20 )

   Box(, 20, 70 )
   SET CURSOR ON
   @ m_x + 1, m_y + 2 SAY "Parametre pohraniti posebno za korisnika "  GET cPosebno VALID cPosebno $ "DN" PICT "@!"
   READ
   WPAr( "p?", cPosebno )
   SELECT params
   USE
   IF cPosebno == "D"
      SELECT ( F_GPARAMSP )
      USE
      O_GPARAMSP
   ELSE
      SELECT ( F_GPARAMS )
      USE
      O_GPARAMS
   ENDIF

   gPtkonv := PadR( gPtkonv, 2 )

   @ m_x + 7, m_y + 2 SAY "Stroga kontrola ispravki/brisanja sifara     (D/N)"  GET gSKSif VALID gSKSif $ "DN" PICT "@!"
   @ m_x + 8, m_y + 2 SAY "Direktorij pomocne kopije podataka" GET gArhDir PICT "@S20"
   @ m_x + 9, m_y + 2 SAY "Default odgovor na pitanje 'Izlaz direktno na printer?' (D/N/V/E)" GET gcDirekt VALID gcDirekt $ "DNVER" PICT "@!"
   @ m_x + 10, m_y + 2 SAY "Shema boja za prikaz na ekranu 'V' (B1/B2/.../B7):" GET gShemaVF
   @ m_x + 12, Col() + 2 SAY "Zaok 50f (5):" GET g50f    VALID g50f    $ " 5" PICT "9"
   @ m_x + 14, m_y + 2 SAY "Omoguciti kolor-prikaz? (D/N)" GET gFKolor VALID gFKolor $ "DN" PICT "@!"
   @ m_x + 15, Col() + 2 SAY "SQL log ? (D/N)" GET gSql PICT "@!"

   @ m_x + 18, m_y + 2 SAY "PDF stampa (N/D/X)?" GET gPDFPrint VALID {|| gPDFPrint $ "DNX" .AND. if( gPDFPrint $ "XD", pdf_box(), .T. ) } PICT "@!"

   @ m_x + 20, m_y + 2 SAY "Ispravka FMK.INI (D/S/P/K/M/N)" GET cFMKINI VALID cFMKINI $ "DNSPKM" PICT "@!"
   @ m_x + 20, m_y + 36 SAY "M - FMKMREZ"


   READ
   BoxC()

   IF cFMKIni $ "DSPKM"
      PRIVATE cKom := "q "
      IF cFMKINI == "D"
         cKom += EXEPATH
      ELSEIF  cFMKINI == "K"
         cKom += KUMPATH
      ELSEIF  cFMKINI == "P"
         cKom += PRIVPATH
      ELSEIF  cFMKINI == "S"
         cKom += SIFPATH
      ENDIF
      // -- M je za ispravku FMKMREZ.BAT
      IF cFMKINI == "M"
         cKom += EXEPATH + "FMKMREZ.BAT"
      ELSE
         cKom += "FMK.INI"
      ENDIF

      Box(, 25, 80 )
      f18_run( ckom )
      BoxC()
      IniRefresh() // izbrisi iz cache-a
   ENDIF


   IF LastKey() <> K_ESC
      Wpar( "pt", gPTKonv )
      Wpar( "SK", gSKSif )
      Wpar( "DO", gcDirekt )
      Wpar( "FK", gFKolor )
      Wpar( "S9", gSQL )
      Wpar( "SB", gShemaVF )
      Wpar( "Ad", Trim( gArhDir ) )
      Wpar( "FO", Trim( gPFont ) )
      Wpar( "KS", gKodnaS )
      Wpar( "5f", g50f )
      Wpar( "pR", gPDFPrint )
   ENDIF


   SELECT gparams
   USE


   IF lPushWa
      PopWa()
   ENDIF

   RETURN .T.

// ------------------------------------------------------------
// prikaz dodatnog box-a za stimanje parametara PDF stampe
// ------------------------------------------------------------
STATIC FUNCTION pdf_box()

   LOCAL nX := 1
   PRIVATE GetList := {}

   IF Pitanje(, "Podesiti parametre PDF stampe (D/N) ?", "D" ) == "N"
      RETURN .T.
   ENDIF

   Box(, 10, 75 )

   @ m_x + nX, m_y + 2 SAY "Podesavanje parametara PDF stampe *******"

   nX += 2
   @ m_x + nX, m_y + 2 SAY "PDF preglednik:" GET gPDFViewer VALID _g_pdf_viewer( @gPDFViewer ) PICT "@S56"

   nX += 1
   @ m_x + nX, m_y + 2 SAY "Printanje PDF-a bez poziva preglednika (D/N)?" GET gPDFPAuto VALID gPDFPAuto $ "DN" PICT "@!"

   nX += 2
   @ m_x + nX, m_y + 2 SAY "Default printer:" GET gDefPrinter PICT "@S55"


   READ
   BoxC()

   IF LastKey() <> K_ESC

      // generisi yml fajl iz parametara
      wr_to_yml()

      // snimi parametre.....
      Wpar( "pV", gPDFViewer )
      Wpar( "dP", gDefPrinter )
      Wpar( "pA", gPDFPAuto )

   ENDIF

   RETURN .T.


// ---------------------------------------------
// upisi u yml fajl podesenja
// ---------------------------------------------
STATIC FUNCTION wr_to_yml( cFName )

   LOCAL nH
   LOCAL cParams := ""
   LOCAL cNewRow := Chr( 13 ) + Chr( 10 )

   IF cFName == nil
      cFName := "fmk_pdf.yml"
   ENDIF

   // write params to yml
   cParams += "pdf_viewer: " + AllTrim( gPDFviewer )
   cParams += cNewRow
   cParams += "print_to: " + AllTrim( gDefPrinter )

   // kreiraj fajl
   nH := FCreate( EXEPATH + cFName )
   // upisi u fajl
   FWrite( nH, cParams )
   // zatvori fajl
   FClose( EXEPATH + cFName )

   RETURN .T.



// -------------------------------------------
// vraca lokaciju pdf viewera
// -------------------------------------------
STATIC FUNCTION _g_pdf_viewer( cViewer )

   LOCAL cViewName := "acrord32.exe"
   LOCAL cViewPath := "c:" + SLASH + "progra~1" + SLASH + "adobe" + SLASH
   LOCAL aPath := Directory( cViewPath + "*.*", "D" )
   LOCAL cPom

   IF !Empty( cViewer )
      RETURN .T.
   ENDIF

   ASort( aPath, {| x, y| x[ 1 ] < y[ 1 ] } )

   nScan := AScan( aPath, {| xVal| Upper( xVal[ 1 ] ) = "ACRO" } )

   IF nScan > 0
      cPom := AllTrim( aPath[ nScan, 1 ] )

      cViewer := cViewPath + cPom
      cViewer += SLASH + "reader" + SLASH
      cViewer += cViewName

      cViewer := PadR( cViewer, 150 )

   ENDIF

   IF !Empty( cViewer ) .AND. !File( cViewer )
      MsgBeep( "Ne mogu naci Acrobat Reader!#Podesite rucno lokaciju preglednika..." )
   ENDIF

   RETURN .T.


/*
 *  Setuje globalne varijable, te setuje incijalne vrijednosti objekata koji pripadaju glavnom app objektu
 */

METHOD setTGVars()

   info_bar( ::cName, ::cName + " set_tg_vars start " )
   ::cSqlLogBase := my_get_from_ini( "Sql", "SqlLogBase", "c:" + SLASH + "sigma" )
   gSqlLogBase := ::cSqlLogBase

   IF my_get_from_ini( "Sql", "SqlDirektno", "D" ) == "D"
      ::lSqlDirektno := .T.
   ELSE
      ::lSqlDirektno := .F.
   ENDIF

   IF ( ::oDesktop != nil )
      ::oDesktop := nil
   ENDIF

   PUBLIC cZabrana := "Opcija nedostupna za ovaj nivo !"

   ::oDesktop := TDesktopNew()

   info_bar( ::cName, ::cName + " set_tg_vars end" )

   RETURN .T.
