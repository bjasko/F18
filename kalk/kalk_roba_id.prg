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


FUNCTION RobaIdSredi()

   cSifOld := Space( 10 )
   cSifNew := Space( 10 )

   IF !spec_funkcije_sifra( "spec_funkcije_sifra" )
      RETURN
   ENDIF

   O_ROBA
   o_kalk()
   O_FAKT
   fSrediF := .T.

   Box(, 10, 60 )

   DO WHILE .T.
      @ m_x + 6, m_y + 2 SAY "                 "
      @ m_x + 1, m_Y + 2 SAY "ISPRAVKA SIFRE ARTIKLA U DOKUMENTIMA"
      @ m_x + 2, m_Y + 2 SAY "Stara sifra:" GET cSifOld PICT "@!"
      @ m_x + 3, m_Y + 2 SAY "Nova  sifra:" GET cSifNew PICT "@!" VALID !Empty( cSifNew )
      READ
      ESC_BCR

      IF !( kalk->( FLock() ) ) .OR. !( fakt->( FLock() ) ) .OR. !( roba->( FLock() ) )
         Msg( "Ostali korisnici ne smiju raditi u programu" )
         closeret
      ENDIF

      SELECT kalk
      LOCATE FOR idroba == cSifNew

      IF Found()
         BoxC()
         Msg( "Nova sifra se vec nalazi u prometu. prekid !" )
         closeret
      ENDIF

      LOCATE FOR idroba == cSifOld
      nRbr := 0

      DO WHILE Found()
         _field->idroba := cSifNew
         @ m_X + 5, m_y + 2 SAY ++nRbr PICT "999"
         CONTINUE
      ENDDO

      IF fSrediF
         SELECT fakt
         LOCATE FOR idroba == cSifOld
         nRbr := 0
         DO WHILE Found()
            @ m_X + 5, m_y + 2 SAY ++nRbr PICT "999"
            _field->idroba := cSifNew
            CONTINUE
         ENDDO
      ENDIF

      SELECT roba
      LOCATE FOR id == cSifOld
      nRbr := 0
      DO WHILE Found()
         @ m_X + 5, m_y + 2 SAY ++nRbr PICT "999"
         _field->id := cSifNew
         CONTINUE
      ENDDO
      Beep( 2 )
      @ m_x + 6, m_y + 2 SAY "Sifra promijenjena"
   ENDDO  // .t.

   BoxC()
   closeret

/*
FUNCTION kalk_sljedeci( cIdFirma, cVrsta )

   LOCAL cBrKalk := Space( 8 )

   kalk_set_brkalk_za_idvd( cVrsta, @cBrKalk )

   RETURN cBrKalk
*/
