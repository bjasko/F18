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

// parametri funkcija
STATIC par_1
STATIC par_2
STATIC par_3
STATIC par_4
STATIC last_nX
STATIC last_nY
STATIC txt_in_name
STATIC txt_out_name
STATIC s_cDesktopPath

// ----------------------------------------------------
// dodaje opciju u matricu opcija...
// aOpt - matrica koja se proslijedjuje po referenci
// cOption - string opcije npr "set readonly"
// ----------------------------------------------------
FUNCTION add_gvim_options( aOpt, cOption )

   AAdd( aOpt, { '"' + cOption + '"' } )

   RETURN



// ----------------------------------------------------
// dodaje argument u matricu argumenata...
// aArgs - matrica koja se proslijedjuje po referenci
// cArg - string argumneta npr "-c"
// ----------------------------------------------------
FUNCTION add_gvim_args( aArgs, cArg )

   AAdd( aArgs, { cArg } )

   RETURN .T.


// -----------------------------------------
// pokrece gvim sa zadanim parametrima...
// -----------------------------------------
FUNCTION gvim_cmd()

   LOCAL aOpts := {}
   LOCAL aArgs := {}
   LOCAL cPom

   // setovanje argumenata gvim-a (aArgs)
   // -----------------------------------
   // -n (no swap file)
   cPom := "-n"
   add_gvim_args( @aArgs, cPom )

   // -R (read only)
   cPom := "-R"
   add_gvim_args( @aArgs, cPom )


   // setovanje opcija gvim gui-ja (aOpts)
   // ------------------------------------
   // readonly
   // cPom := 'set readonly'
   // add_gvim_options(@aOpts, cPom)

   // pokreni gvim sa opcijama
   r_gvim_cmd( aArgs, aOpts )

   RETURN .T.


// -------------------------------------------------
// pokrece gvim iz cmd line-a
// aOpts - matrica sa opcijama
// aArgs - matrica sa argumnetima
// -------------------------------------------------
STATIC FUNCTION r_gvim_cmd( aArgs, aOpts )

   // gvim pokretacka komanda
   LOCAL cGvimCmd := ""
   LOCAL cSpace := Space( 1 )
   LOCAL nOpts
   LOCAL nArgs

   // putanja i naziv bat fajla za pokretanje gvim-a
   cRunGvim := my_home() + "run_gvim.bat"

   // putanja do desktopa
   s_cDesktopPath := '%HOMEDRIVE%%HOMEPATH%\Desktop\'

   cGvimCmd += 'gvim'

   IF Len( aArgs ) > 0
      FOR nArgs := 1 TO Len( aArgs )
         cGvimCmd += cSpace
         cGvimCmd += AllTrim( aArgs[ nArgs, 1 ] )
         // generise sljedeci string, npr: ' -n'
      NEXT
   ENDIF

   // prodji kroz matricu opcija i dodaj ih u gvimcmd ....
   IF Len( aOpts ) > 0
      FOR nOpts := 1 TO Len( aOpts )
         // maksimalni broj opcija je 10, preko toga ne idi...
         IF nOpts == 11
            EXIT
         ENDIF

         cGvimCmd += cSpace
         cGvimCmd += '-c'
         cGvimCmd += cSpace
         cGvimCmd += AllTrim( aOpts[ nOpts, 1 ] )
         // generise sljedeci string, npr: ' -c "set readonly"'
      NEXT
   ENDIF

   cGvimCmd += cSpace

   IF Upper( Right( txt_out_name, 4 ) ) <> ".TXT"
      txt_out_name += ".TXT"
   ENDIF

   cGvimCmd += '"' + s_cDesktopPath + txt_out_name + '"'

   SET PRINTER to ( cRunGvim )
   SET PRINTER ON
   SET CONSOLE OFF

   // definisi komande bat fajla...

   // pobrisi swap fajl ako je ostao... ali prvo attribut promjeni
   // posto je swp hidden...
   ? 'ATTRIB -H "' + s_cDesktopPath + '.' + txt_out_name + '.swp"'
   ? 'DEL "' + s_cDesktopPath + '.' + txt_out_name + '.swp"'

   // komanda kopiranja fajla outf.txt na desktop
   ? 'COPY ' + my_home() + txt_in_name + ' "' + s_cDesktopPath + txt_out_name + '"'

   // komanda za pokretanje gvima
   ? cGvimCmd

   SET PRINTER TO
   SET PRINTER OFF
   SET CONSOLE ON

   Run( 'cmd /c ' + cRunGvim )

   RETURN .T.


// ---------------------------------------
// start print u GVIM
// cOut_name - ime izlaznog txt fajla
// ---------------------------------------
FUNCTION gvim_print( cOut_Name )

   last_nX := 0
   last_nY := 0

   par_1 := gPrinter
   par_2 := gcDirekt
   par_3 := gPTKonv
   par_4 := gKodnaS

   txt_in_name := OUTF_FILE

   IF ( cOut_name == nil )
      txt_out_name := txt_in_name
   ELSE
      txt_out_name := cOut_name
   ENDIF

   // uzmi parametre iz printera "G"
   SELECT F_GPARAMS
   IF !Used()
      o_gparams()
   ENDIF

   gPrinter := "G"
   gPTKonv := "0 "
   gKodnaS := "8"

   PRIVATE cSection := "P"
   PRIVATE cHistory := gPrinter
   PRIVATE aHistory := {}

   RPar_Printer()

   START PRINT CRET

   RETURN .T.



// -------------------------------------
// vrati standardne printer parametre
// -------------------------------------
FUNCTION gvim_end()

   ?
   ENDPRINT

   // vrati tekuce parametre
   gPrinter := par_1
   gcDirekt := par_2
   gPTKonv := par_3
   gKodnaS := par_4

   SELECT F_GPARAMS
   IF !Used()
      o_gparams()
   ENDIF

   PRIVATE cSection := "P"
   PRIVATE cHistory := gPrinter
   PRIVATE aHistory := {}

   RPar_Printer()

   SELECT gparams
   USE

   RETURN
