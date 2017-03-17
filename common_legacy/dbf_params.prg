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

MEMVAR cSection, cHistory, cImeVar

FUNCTION RPar( cImeVar, xArg )

   LOCAL cPom, clTip

   select_o_params()
   SEEK cSection + cHistory + cImeVar + "1"

   IF Found()
      cPom := ""
      clTip := field->tip

      DO WHILE !Eof() .AND. ( cSection + cHistory + cImeVar == field->Fsec + cHistory + field->Fvar )
         cPom += field->Fv
         SKIP
      ENDDO

      cPom := Left( cPom, At( Chr( CHR254 ), cPom ) - 1 )
      IF clTip = "C"
         xArg := cPom
      ELSEIF clTip == "N"
         xArg := Val( cPom )
      ELSEIF clTip == "D"
         xArg := CToD( cPom )
      ELSEIF clTip == "L"
         xArg := iif( cPom == "0", .F., .T. )
      ENDIF

   ENDIF

   RETURN NIL




FUNCTION WPar( cImeVar, xArg, fSQL, cAkcija )

   LOCAL cPom, nRec

   IF ( cAkcija == NIL )
      cAkcija := "A"
   ENDIF

   SEEK cSection + cHistory + cImeVar

   IF Found()
      IF my_flock()
         DO WHILE !Eof() .AND. cSection + cHistory + cImeVar == Fsec + Fh + Fvar
            SKIP
            nRec := RecNo()
            SKIP -1
            dbdelete2()
            GO nRec
         ENDDO
      ELSE
         MsgBeep( "FLOCK:parametri nedostupni!!" )
      ENDIF
      my_unlock()
   ENDIF


   clTip := ValType( xArg )
   IF clTip == "C"
      cPom := xArg
   ELSEIF clTip == "N"
      cPom := Str( xArg )
   ELSEIF clTip == "D"
      cPom := DToC( xArg )
   ELSEIF clTip == "L"
      cPom := iif( xArg, "1", "0" )
   ENDIF
   cPom += Chr( CHR254 )

   cRbr := "0"
   DO WHILE Len( cPom ) <> 0
      APPEND BLANK

      Chadd( @cRbr, 1 )

      REPLACE Fh WITH chistory, ;
         Fsec WITH cSection, ;
         Fvar WITH cImeVar, ;
         tip WITH clTip, ;
         rBr WITH cRbr, ;
         Fv   WITH Left( cPom, 15 )

      cPom := SubStr( cPom, 16 )
   ENDDO

   RETURN NIL



STATIC FUNCTION NextAkcija( cAkcija )

   IF goModul:lSqlDirektno
      cAkcija := "L"
   ENDIF

   IF cAkcija == "A"
      cAkcija := "A"
   ELSEIF cAkcija == "P" .OR. cAkcija == "D"
      cAkcija := "D"
   ELSEIF cAkcija == "Z"
      cAkcija := "Z"
   ENDIF

   RETURN .T.


FUNCTION Params1()

   LOCAL ncx, ncy, nOldc

   IF cHistory == "*"

      SEEK cSection
      DO WHILE !Eof() .AND. cSection == Fsec
         cH := Fh
         DO WHILE !Eof() .AND. cSection == Fsec .AND. ch == Fh
            SKIP
         ENDDO
         AAdd( aHistory, { ch } )
      ENDDO

      IF Len( aHistory ) > 0
         @ - 1, 70 SAY ""
         cHistory := ( ABrowse( aHistory, 10, 1, {| ch |  HistUser( ch ) } ) )[ 1 ]
      ELSE
         cHistory := " "
      ENDIF
   ENDIF

   RETURN NIL


FUNCTION Params2()

   LOCAL ncx, ncy, nOldC

   // TODO: skloni
   // f18_tone( 320, 1 )
   // f18_tone( 320, 1 )

   RETURN .T.

FUNCTION HistUser( Ch )

   LOCAL nRec, cHi

   DO CASE
   CASE Ch == K_ENTER
      RETURN DE_ABORT
   CASE Ch = K_CTRL_T
      IF Len( aHistory ) > 1
         cHi := aHistory[ aBrowRow(), 1 ]
         ADel( aHistory, aBrowRow() )
         ASize( aHistory, Len( aHistory ) - 1 )
         SEEK cSection + cHi
         DO WHILE !Eof() .AND. cSection + cHi == Fsec + Fh
            SKIP
            nRec := RecNo()
            SKIP -1
            DELETE
            GO nRec
         ENDDO
      ELSE
         Beep( 2 )
      ENDIF
      RETURN DE_REFRESH
      // izbrisi tekuci element
   OTHERWISE
      RETURN DE_CONT
   ENDCASE

   RETURN NIL



FUNCTION o_params()

   RETURN o_dbf_table( F_PARAMS, "params", "ID" )


FUNCTION select_o_params()

   RETURN select_o_dbf( "PARAMS", F_PARAMS, "params", "ID" )
