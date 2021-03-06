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


// File cache buffer
// string
STATIC cCache
// ;

// Name of the .INI file that is in the cache buffer
// string
STATIC cIniFile
// ;

// #include "COMMON.CH"

STATIC INI_DATA := {}
STATIC INI_NAME := ''
STATIC INI_SECTION := 'xx'




/*
 *  param cSection  - [SECTION]
 *  param cVar      - Variable
 *  param cValue    - Default value of Variable
 *  param cLokacija - Default = EXEPATH, or my_home(), or SIFPATH or KUMPATH (FileName='FMK.INI')
 *  param lAppend   - True - ako zapisa u ini-ju nema dodaj ga, default false
 * // uzmi vrijednost varijable Debug, sekcija Gateway, iz EXEPATH/FMK.INI
 * cDN:=my_get_from_ini("Gateway","Debug","N",EXEPATH)
 * \endcode
 *
 * \sa R_IniWrite
 *
 */

FUNCTION my_get_from_ini( cSection, cVar, cValue, cLokacija, lAppend )

   LOCAL cRez := "", nFH
   LOCAL cNazIni := 'FMK.INI'

   cLokacija := my_home_root()

   IF ( lAppend == nil )
      lAppend := .F.
   ENDIF


   IF !File( cLokacija + cNazIni )
      nFH := FCreate( cLokacija + cNazIni )
      FWrite( nFh, ";------- Ini Fajl FMK-------" )
      FClose( nFH )
   ENDIF
   
   cRez := R_IniRead( cSection, cVar,  "", cLokacija + cNazIni )

   IF ( lAppend .AND. Empty( cRez ) )
      // nije toga bilo u fmk.ini
      R_IniWrite( cSection, cVar, cValue, cLokacija + cNazIni )
      IniRefresh()
      RETURN cValue
   ELSEIF ( Empty( cRez ) )
      IniRefresh()
      RETURN cValue
   ELSE
      IniRefresh()
      RETURN cRez
   ENDIF

   RETURN ""


FUNCTION R_IniRead ( cSection, cEntry, cDefault, cFName, lAppend )

   LOCAL nHandle
   LOCAL cString
   LOCAL nPos
   LOCAL nEnd
   LOCAL aEntries := {}
   LOCAL   lPom0, lPom

   IF lAppend == NIL
      lAppend := .F.
   ENDIF


   // Extension omitted : Add default extension
   IF ( At ( '.', cFName ) == 0 )
      cFName -= '.INI'
   ENDIF

   IF ( cIniFile == NIL )
      // First time ... (buffer not in cache)
      cIniFile := ''
   ENDIF

   // Check the filename
   IF ( cIniFile != cFName )
      // Other .INI file name : file not in cache !

      IF ( nHandle := FOpen ( cFName, FO_READ + FO_SHARED ) ) < 5
         // Error opening .INI file
         RETURN NIL
      ENDIF

      // INI file opened ...

      // Read complete file into cCache
      ReadFile( nHandle )

      // File not needed anymore ...
      FClose( nHandle )

      // File in cache ...
      cIniFile := cFName

   ENDIF

   lPom0 := SeekSection( cSection, @nPos )
   IF lPom0

      // Section FOUND, nPos points to the start of the section
      IF cEntry = NIL
         // return ALL ENTRIES IN SECTION !

         // nPos points to start of section

         // Skip [section] + NRED_DOS
         nPos = nPos + 4 + Len ( cSection )

         // nPos points to start of first entry
         DO WHILE nPos <= Len ( cCache ) .AND. SubStr ( cCache, nPos, 1 ) != '['

            nEnd    := I_At ( '=', .F., nPos )
            cEntry  := SubStr ( cCache, nPos, nEnd - nPos )
            nPos    := nEnd + 1
            nEnd    := I_At ( NRED_DOS, .F., nPos )
            cString := SubStr ( cCache, nPos, nEnd - nPos )
            AAdd ( aEntries, { cEntry, cString } )
            nPos    := nEnd + 2

            DO WHILE SubStr( cCache, nPos, 2 ) = NRED_DOS
               // Skip NRED_DOS's, if any
               nPos += 2
            ENDDO

         ENDDO

         RETURN aEntries

      ELSE
         // Locate specified entry
         nPos := I_At( Upper( cEntry ) + '=', .T., nPos )

         IF ( nPos > 0 )
            // Entry found, nPos points to start of entry

            // Skip 'entry=' part
            nPos += Len ( cEntry )

            // Return value
            RETURN SubStr ( cCache, nPos + 1, ;
               I_At ( NRED_DOS, .F., nPos + 1 ) - nPos - 1 )

         ENDIF

      ENDIF

   ELSE
      // Section not found
      IF ( ValType( cEntry ) != "C" )
         // Request to return all entries in section ...
         RETURN NIL
      ENDIF
   ENDIF


   IF ( lAppend )
      // CREATE A NEW cDEFAULT ENTRY, if THE SPECIFIED ENTRY NOT EXISTS
      R_IniWrite ( cSection, cEntry, cDefault, cIniFile )
   ENDIF


   // Return default value

   IniRefresh()

   RETURN cDefault



/* R_IniWrite ( cSection, cEntry, cString, cFName )
 *
 *  param: cSection - String that specifies the section to which the string will  be copied. If the section does not exist, it is created. cSection is case-independent
 *  param: cEntry - String containing the entry to be associated with the string. If the entry does not exist in the specified section, it is created. If the parameter is NIL, the entire section, including all entries within the section, is deleted.
 *  param: cString - String to be written to the file. If this parameter is NIL, the entry specified by the cEntry parameter is deleted.
 *  param: cFName  - String that names the initialization file
 *
 * \sa R_IniWrite
 *
 */

FUNCTION R_IniWrite( cSection, cEntry, cString, cFName )

   LOCAL nHandle
   LOCAL nBytes
   LOCAL nPos
   LOCAL nEntry
   LOCAL lPom

   IF ( cFName == NIL ) .OR. ValType ( cFName ) != 'C'
      // Required parameter !
      RETURN .F.
   ENDIF

   IF ( cSection == NIL ) .OR. ValType ( cSection ) != 'C'
      // Required paramter !
      RETURN .F.
   ENDIF

   // Append default extension (if no extension present)
   IF At ( '.', cFName ) = 0
      cFName -= '.INI'
   ENDIF

   IF cIniFile = NIL
      // First time ...
      cIniFile := ''
   ENDIF

   // Check the filename
   IF ( cIniFile != cFName )
      // If file name is the SAME : file is still in Cache buffer (cCache) ...

      // Other .INI file or the first time
      IF ( nHandle := FOpen( cFName, FO_READWRITE + FO_SHARED ) ) < 5
         // Error opening .INI file

         IF ( nHandle := FCreate( cFName, FC_NORMAL ) ) < 5
            // Error creating .INI file
            IniRefresh()
            RETURN .F.

         ELSE
            // .INI file created : Write Section and Entry
            PutSection( nHandle, cSection )

            PutEntry ( nHandle, cEntry, cString )

            // ReRead file to adjust cCache cache

            ReadFile( nHandle )
            FClose( nHandle )

            // Buffer in cache ...
            cIniFile := cFName

            IniRefresh()
            RETURN .T.

         ENDIF

      ENDIF

      // Read complete file into cCache
      // Logg("Ini fajl name:" + cFName)
      ReadFile( nHandle )

      // Buffer in cache ...
      cIniFile := cFName

   ENDIF

   nPos := 0

   lPom := SeekSection( cSection, @nPos )
   IF !lPom
      // Section NOT present : append SECTION AND ENTRY !
      IF ( nHandle == NIL )
         // File not presently open
         nHandle := FOpen ( cFName, FO_READWRITE + FO_SHARED )
      ENDIF

      // Pointer to end-of-file
      FSeek( nHandle, 0, FS_END )

      // APPEND NEW SECTION (separated with an empty line)
      FWrite ( nHandle, NRED_DOS, 2 )
      PutSection ( nHandle, cSection )

      PutEntry( nHandle, cEntry, cString )

      // ReRead file to adjust cCache ....
      ReadFile( nHandle )

   ELSE
      // SECTION ALREADY PRESENT
      // nPos points to the start of the section

      IF cEntry == NIL

         // DELETE COMPLETE SECTION !
         // nPos points to start of section
         IF ( nEntry := I_At ( '[', .F., nPos + 1 ) ) = 0
            // No next section : delete to end-of-file
            nEntry := Len ( cCache ) + 1
         ENDIF

         // Delete bytes from string
         cCache := Stuff( cCache, nPos, nEntry - nPos, '' )
         ReWrite( nHandle, cFName )
         IniRefresh()
         RETURN .T.

      ENDIF

      // Skip section + NRED_DOS
      nPos = nPos + 4 + Len ( cSection )

      IF ( nEntry := I_At ( Upper ( cEntry ) + '=', .T., nPos ) ) = 0

         // ENTRY NOT FOUND : APPEND ENTRY
         IF cString != NIL
            // Locate start of next SECTION
            IF nHandle = NIL
               nHandle := FOpen ( cFName, FO_READWRITE + FO_SHARED )
            ENDIF

            IF ( nEntry := I_At ( '[', .F., nPos ) ) = 0

               // Last section : append to end of file
               FSeek ( nHandle, 0, FS_END )

               PutEntry ( nHandle, cEntry, cString )

               // ReRead file to adjust cCache
               ReadFile( nHandle )

            ELSE
               // -- Next section present at : nEntry - 2

               // -- INSERT ENTRY AT END OF SECTION
               DO WHILE SubStr ( cCache, nEntry - 2, 2 ) = NRED_DOS
                  // -- Skip NRED_DOS's, if any ...
                  nEntry -= 2
               ENDDO

               // -- Keep 1 NRED_DOS string ...
               nEntry += 2

               cCache := Stuff( cCache, nEntry, 0, cEntry + '=' + cString + NRED_DOS )

               ReWrite( nHandle, cFName )

               IniRefresh()
               RETURN .T.

            ENDIF

         ENDIF

      ELSE
         // -- ENTRY FOUND : REPLACE VALUE

         IF ( cString == NIL )
            // -- DELETE ENTRY !

            // nEntry points to first pos of entry name
            nPos := I_At( NRED_DOS, .F., nEntry ) + 2

            // Delete bytes from string
            cCache := Stuff ( cCache, nEntry, nPos - nEntry, '' )
         ELSE
            // REPLACE VALUE

            // nEntry points to first pos of entry name

            nEntry  := nEntry + Len ( cEntry ) + 1
            cCache := Stuff ( cCache, nEntry, ;
               At ( NRED_DOS, SubStr ( cCache, nEntry ) ) - 1, cString )

         ENDIF

         ReWrite ( nHandle, cFName )
         IniRefresh()

         RETURN .T.

      ENDIF

   ENDIF
   FClose ( nHandle )

   IniRefresh()

   RETURN .T.



/* I_At(cSearch, cString, nStart)
 *   param: nStart - pocni pretragu od nStart pozicije
 */
STATIC FUNCTION I_At( cSearch, lUpper, nStart )

   LOCAL nPos

   IF lUpper
      nPos := At( cSearch, SubStr( Upper( cCache ), nStart ) )
   ELSE
      nPos := At( cSearch, SubStr( cCache, nStart ) )
   ENDIF

   RETURN IF ( nPos > 0, nPos + nStart - 1, 0 )





FUNCTION TEMPINI( cSection, cVar, cValue, cread )

   //
   // cValue  - tekuca vrijednost
   // cREAD = "WRITE" , "READ"

   LOCAL cRez := ""
   LOCAL cNazIni := EXEPATH + 'TEMP.INI'

   IF cread == NIL
      read := "READ"
   ENDIF


   IF !File( EXEPATH + 'TEMP.INI' )
      nFH := FCreate( EXEPATH + 'TEMP.INI' )
      FWrite( nFh, ";------- Ini Fajl TMP-------" )
      FClose( nFH )
   ENDIF
   cRez := R_IniRead ( cSection, cVar,  "", cNazIni )

   IF Empty( cRez ) .OR. cRead == "WRITE"  // nije toga bilo u fmk.ini
      R_IniWrite( cSection, cVar, cValue, cNazIni )
      RETURN cValue
   ELSE
      RETURN cRez
   ENDIF

   RETURN



FUNCTION IniRefresh()

   // cCache:=NIL
   // cIniFile:=NIL
   cCache := ""
   cIniFile := ""
   // trazi novo citanje ini fajla !

   RETURN .T.



FUNCTION UzmiIzINI( cNazIni, cSection, cVar, cValue, cread )

   //
   // cValue  - tekuca vrijednost
   // cREAD = "WRITE" , "READ"

   LOCAL cRez := ""

   IF cread == NIL
      read := "READ"
   ENDIF

   IF !File( cNazIni )
      nFH := FCreate( cNazIni )
      FWrite( nFh, ";------- Ini Fajl " + cNazIni + "-------" )
      FClose( nFH )
   ENDIF
   cRez := R_IniRead ( cSection, cVar,  "", cNazIni )

   IF Empty( cRez ) .OR. cRead == "WRITE"
      IF ValType( cValue ) = "N"
         R_IniWrite( cSection, cVar, Str( cValue, 22, 2 ), cNazIni )
      ELSE
         R_IniWrite( cSection, cVar, cValue, cNazIni )
      ENDIF
      RETURN cValue
   ELSE
      RETURN cRez
   ENDIF

   RETURN



STATIC FUNCTION SeekSection( sect, pos )

   // Look for the specified section in buffer

   pos := At ( '[' + Upper ( sect ) + ']', Upper ( cCache ) )

   RETURN pos > 0



STATIC FUNCTION ReadFile( hnd )

   // if VALTYPE(gCnt1)<>"N"
   // gCnt1:=0
   // endif
   // gCnt1++
   // cCache:="[xx]"
   // return

   // Read complete file into cache buffer
   cCache := Space( FSeek ( hnd, 0, FS_END ) )
   FSeek ( hnd, 0, FS_SET )
   FRead ( hnd, @cCache, Len( cCache ) )

   RETURN


STATIC FUNCTION PutSection( hnd, sect )

   IF !Empty( sect )
      RETURN FWrite ( hnd, '[' + sect + ']' + NRED_DOS )
   ELSE
      RETURN NIL
   ENDIF

   RETURN



STATIC FUNCTION PutEntry( hnd, entry, val )

   IF !Empty ( entry ) .AND. !Empty ( val )
      RETURN FWrite ( hnd, entry + '=' + val + NRED_DOS )
   ELSE
      RETURN NIL
   ENDIF


   // Rewrite complete file from buffer

STATIC FUNCTION ReWrite( hnd, fnm )

   IF ( hnd != NIL )
      FClose( hnd )
   ENDIF
   hnd := FCreate ( fnm, FC_NORMAL )
   FWrite ( hnd, cCache )
   FClose ( hnd )

   RETURN
