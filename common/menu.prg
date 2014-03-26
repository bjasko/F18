/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "fmk.ch"

STATIC aMenuStack:={}    

// -----------------------------------------------------
// -----------------------------------------------------
FUNCTION f18_menu( cIzp, main_menu, izbor, opc, opcexe )

   LOCAL cOdgovor
   LOCAL nIzbor
   LOCAL _menu_opc

   IF main_menu == NIL
      main_menu := .F.
   ENDIF

   IF main_menu
      @ 4, 5 SAY ""
   ENDIF

   DO WHILE .T.
      Izbor := menu( cIzp, opc, izbor, .F. )
      nIzbor := retitem( izbor )
      DO CASE
      CASE izbor == 0
         IF main_menu
            cOdgovor := Pitanje( "", 'Želite izaći iz programa ?', 'N' )
            IF cOdgovor == "D"
               EXIT
            ELSEIF cOdgovor == "L"
               Prijava()
               Izbor := 1
               @ 4, 5 SAY ""
               LOOP
            ELSE
               Izbor := 1
               @ 4, 5 SAY ""
               LOOP
            ENDIF
         ELSE
            EXIT
         ENDIF

      OTHERWISE

         IF opcexe[ nIzbor ] <> nil

            _menu_opc := opcexe[ nIzbor ]

            IF ValType( _menu_opc ) == "B"
               Eval( _menu_opc )
            ELSE
               MsgBeep( "meni cudan ?" + hb_ValToStr( nIzbor ) )
            ENDIF

         ENDIF
      ENDCASE

   ENDDO

   RETURN




FUNCTION Menu_SC( cIzp, lMain )

  //pretpostavljamo privatne varijable Izbor, Opc, OpcExe
  RETURN f18_menu( cIzp, lMain, Izbor, Opc, Opcexe )


/*  Menu(MenuId,Items,ItemNo,Inv)
 *
 *  Prikazuje zadati meni, vraca odabranu opciju
 *
 *  MenuId  - identifikacija menija     C
 *  Items   - niz opcija za izbor       {}
 *  ItemNo  - Broj pocetne pozicije     N
 *  Inv     - da li je meni invertovan  L
 *
 *  Broj izabrane opcije, 0 kraj
 *
 */

FUNCTION MENU( MenuId, Items, ItemNo, Inv, cHelpT, nPovratak, aFixKoo, nMaxVR )

   LOCAL Length
   LOCAL N
   LOCAL OldC
   LOCAL LocalC
   LOCAL LocalIC
   LOCAL ItemSav
   LOCAL i
   LOCAL aMenu := {}
   LOCAL cPom := Set( _SET_DEVICE )
   LOCAL lFK := .F.

   SET DEVICE TO SCREEN

   IF nPovratak == NIL
      nPovratak := 0
   ENDIF
   IF nMaxVR == NIL
      nMaxVR := 16
   ENDIF
   IF aFixKoo == NIL
      aFixKoo := {}
   ENDIF
   IF Len( aFixKoo ) == 2
      lFK := .T.
   ENDIF

   N := IF( Len( Items ) > nMaxVR, nMaxVR, Len( Items ) )
   Length := Len( Items[ 1 ] ) + 1

   IF Inv == NIL
      Inv := .F.
   ENDIF

   LocalC  := iif( Inv, Invert, Normal )
   LocalIC := iif( Inv, Normal, Invert )


   OldC := SetColor( LocalC )

   // Ako se meni zove prvi put, upisi ga na stek
   IF Len( aMenuStack ) == 0 .OR. ( Len( aMenuStack ) <> 0 .AND. MenuId <> ( StackTop( aMenuStack ) )[ 1 ] )
      IF lFK
         m_x := aFixKoo[ 1 ]
         m_y := aFixKoo[ 2 ]
      ELSE
         // odredi koordinate menija
         Calc_xy( @m_x, @m_y, N, Length )
      ENDIF

      StackPush( aMenuStack, { MenuId, ;
         m_x, ;
         m_y, ;
         SaveScreen( m_x, m_y, m_x + N + 2 -IF( lFK, 1, 0 ), m_y + Length + 4 -IF( lFK, 1, 0 ) ), ;
         ItemNo, ;
         cHelpT;
         } )

   ELSE
      // Ako se meni ne zove prvi put, uzmi koordinate sa steka
      aMenu := StackTop( aMenuStack )
      m_x := aMenu[ 2 ]
      m_y := aMenu[ 3 ]

   END IF

   @ m_x, m_y CLEAR TO m_x + N + 1, m_y + Length + 3
   IF lFK
      @ m_x, m_y TO m_x + N + 1, m_y + Length + 3
   ELSE
      @ m_x, m_y TO m_x + N + 1, m_y + Length + 3 DOUBLE
      @ m_x + N + 2, m_y + 1 SAY Replicate( Chr( 177 ), Length + 4 )

      FOR i := 1 TO N + 1
         @ m_x + i, m_y + Length + 4 SAY Chr( 177 )
      NEXT

   ENDIF

   SetColor( Invert )
   IF ItemNo == 0
      CentrTxt( h[ 1 ], MAXROWS() -1 )
   END IF

   SetColor( LocalC )
   IF Len( Items ) > nMaxVR
      ItemNo := AChoice3( m_x + 1, m_y + 2, m_x + N + 1, m_y + Length + 1, Items, .T., "MenuFunc", RetItem( ItemNo ), RetItem( ItemNo ) -1 )
   ELSE
      ItemNo := AChoice2( m_x + 1, m_y + 2, m_x + N + 1, m_y + Length + 1, Items, .T., "MenuFunc", RetItem( ItemNo ), RetItem( ItemNo ) -1 )
   ENDIF

   nTItemNo := RetItem( ItemNo )

   aMenu := StackTop( aMenuStack )
   m_x := aMenu[ 2 ]
   m_y := aMenu[ 3 ]
   aMenu[ 5 ] := nTItemNo

   @ m_x, m_y TO m_x + N + 1, m_y + Length + 3

   //
   // Ako nije pritisnuto ESC, <-, ->, oznaci izabranu opciju
   //
   IF nTItemNo <> 0
      SetColor( LocalIC )
      @ m_x + Min( nTItemNo, nMaxVR ), m_y + 1 SAY8 " " + Items[ nTItemNo ] + " "
      @ m_x + Min( nTItemNo, nMaxVR ), m_y + 2 SAY ""
   END IF

   Ch := LastKey()

   // Ako je ESC meni treba odmah izbrisati (ItemNo=0),
   // skini meni sa steka
   IF Ch == K_ESC .OR. nTItemNo == 0 .OR. nTItemNo == nPovratak
      @ m_x, m_y CLEAR TO m_x + N + 2 -IF( lFK, 1, 0 ), m_y + Length + 4 - iif( lFK, 1, 0 )
      aMenu := StackPop( aMenuStack )
      RestScreen( m_x, m_y, m_x + N + 2 -iif( lFK, 1, 0 ), m_y + Length + 4 - iif( lFK, 1, 0 ), aMenu[ 4 ] )
   END IF

   SetColor( OldC )
   SET( _SET_DEVICE, cPom )

   RETURN ItemNo


// ------------------------------------
// ------------------------------------
FUNCTION Menu2( x1, y1, aNiz, nIzb )

   LOCAL xM := 0, yM := 0

   xM := Len( aNiz ); AEval( aNiz, {| x| IF( Len( x ) > yM, yM := Len( x ), ) } )
   Prozor1( x1, y1, x1 + xM + 1, y1 + yM + 1,,,,,, 0 )
   nIzb := ACHOICE2( x1 + 1, y1 + 1, x1 + xM, y1 + yM, aNiz,, "KorMenu2", nIzb )
   Prozor0()

   RETURN nIzb


FUNCTION KorMenu2

   LOCAL nVrati := 2, nTipka := LastKey()

   DO CASE
   CASE nTipka == K_ESC
      nVrati := 0
   CASE nTipka == K_ENTER
      nVrati := 1
   ENDCASE

   RETURN nVrati
