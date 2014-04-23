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


#include "epdv.ch"



FUNCTION gen_kuf()

   LOCAL dDatOd
   LOCAL dDatDo
   LOCAL cSezona := Space( 4 )

   dDatOd := Date()
   dDatDo := Date()

   Box(, 6, 40 )
   @ m_x + 1, m_y + 2 SAY "Generacija KUF"
	
   @ m_x + 3, m_y + 2 SAY "Datum do " GET dDatOd
   @ m_x + 4, m_y + 2 SAY "      do " GET dDatDo
	
   @ m_x + 6, m_y + 2 SAY "sezona" GET cSezona
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN
   ENDIF


   // ima li nesto u kif pripremi ?
   SELECT F_P_KUF
   IF !Used()
      O_P_KUF
   ENDIF

   IF RECCOUNT2() <> 0
      MsgBeep( "KUF Priprema nije prazna !" )
      IF Pitanje(, "Isprazniti KUF pripremu ?", "N" ) == "D"
         SELECT p_kuf
         ZAP
      ENDIF
   ENDIF


   Box(, 5, 60 )
	
   kalk_kuf( dDatOd, dDatDo, cSezona )
   fin_kuf( dDatOd, dDatDo, cSezona )
	
   renm_rbr( "P_KUF", .F. )
   BoxC()

   RETURN
