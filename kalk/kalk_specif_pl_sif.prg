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


FUNCTION P_RVrsta( cid, dx, dy )

   LOCAL nSelect
   PRIVATE ImeKol, Kol := {}

   ImeKol := { { "ID ",  {|| id }, "id", {|| .T. }, {|| validacija_postoji_sifra( wId ) }      }, ;
      { PadC( "Naziv", 30 ), {|| Left( naz, 30 ) },      "naz"       };
      }
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   nSelect := Select()
   SELECT ( F_RVRSTA )
   IF !Used()
      O_RVRSTA
   ENDIF
   SELECT ( nSelect )

   RETURN p_sifra( F_RVRSTA, 1, 10, 75, "Vrste artikala", @cid, dx, dy )





FUNCTION P_TPurchase( cId )
   RETURN .T.



FUNCTION P_IdPartner( cId )
   RETURN .T.



FUNCTION PlFill_Sezona()

   LOCAL cSezonaPf
   LOCAL cSezonaPk
   LOCAL cSez
   LOCAL nI

   cSezonaPf := Space( 5 )
   cSezonaPk := Space( 3 )

   IF .F.
      Box(, 3, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Sezona PF-Sa   :" GET cSezonaPf
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Sezona Pl-Kranj:" GET cSezonaPk
      READ
      BoxC()
   ENDIF

   IF Pitanje(, "Zelite li izvrsiti konverziju ?", "N" ) == "D"
      nI := 0
      o_roba()
      //o_sifk()
      //o_sifv()
      SELECT roba
      GO TOP
      Box(, 3, 60 )
      DO WHILE !Eof()
         cSez := IzSifKRoba( "SEZ", roba->id, .F. )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY roba->id + " " + cSez

         cSezonaPf = cSez
         // if EMPTY(roba->sezona) .and. ;
         // (cSez == cSezonaPf)
         REPLACE sezona WITH Right( cSezonaPf, 3 )
         nI++
         // endif
         SELECT roba
         SKIP
      ENDDO
      BoxC()
      MsgBeep( "Promjena:" + Str( nI ) )
   ENDIF

   RETURN


/*
FUNCTION PlFill_Vrsta()

   LOCAL cVrstaPf
   LOCAL cVrstaPk
   LOCAL nI

   cVrstaPf := Space( 10 )
   cVrstaPk := Space( 1 )
   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Sifra artikla sadrzi ($):" GET cVrstaPf
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Vrsta Pl-Kranj:" GET cVrstaPk
   READ
   BoxC()

   nI := 0
   IF Pitanje(, "Zelite li izvrsiti konverziju ?", "N" ) == "D"

  //    o_roba()
    //  o_sifk()
  //    o_sifv()
      SELECT roba
      GO TOP
      MsgO( "Koverzija ..." )
      DO WHILE !Eof()
         IF Empty( roba->vrsta ) .AND. ;
               ( AllTrim( cVrstaPf ) $ roba->id )
            REPLACE vrsta WITH cVrstaPk
            nI++
         ENDIF
         SELECT roba
         SKIP
      ENDDO
      MsgC()
      MsgBeep( "Promjena:" + Str( nI ) )
   ENDIF

   RETURN
// }




FUNCTION PlFillIdPartner( cIdPartner, cIdRoba )


   LOCAL nArr
   IF Empty( cIdPartner ) .OR. Empty( cIdRoba )
      RETURN
   ENDIF
   nArr := Select()
   select_o_roba(  cIdRoba )
   REPLACE field->idpartner WITH cIdPartner

   SELECT ( nArr )

   RETURN
// }

*/
