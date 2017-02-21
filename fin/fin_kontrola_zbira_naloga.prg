/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION kontrola_zbira_naloga_u_pripremi()

   LOCAL nDug, nDug2, nPot, nPot2

   PushWA()

   select_o_fin_pripr()


   Box( "kzb", 12, 70, .F., "Kontrola zbira naloga" )

   SET CURSOR ON

   cIdFirma := IdFirma
   cIdVN := IdVN
   cBrNal := BrNal

   @ m_x + 1, m_y + 1 SAY "       Firma: " + cIDFirma
   @ m_x + 2, m_y + 1 SAY "Vrsta naloga:" GET cIdVn VALID browse_tnal( @cIdVN, 2, 20 )
   @ m_x + 3, m_y + 1 SAY " Broj naloga:" GET cBrNal

   READ

   IF LastKey() == K_ESC
      BoxC()
      PopWA()
      RETURN DE_CONT
   ENDIF

   SET CURSOR OFF
   cIdFirma := Left( cIdFirma, 2 )


   SET ORDER TO TAG "1"
   SEEK cIdFirma + cIdVn + cBrNal
   IF !( fin_pripr->IdFirma + fin_pripr->IdVn + fin_pripr->BrNal == cIdFirma + cIdVn + cBrNal )
      Msg( "Ovaj nalog nije unesen ...", 10 )
      BoxC()
      PopWa()
      RETURN DE_CONT
   ENDIF

   nDug := nDug2 := nPot := nPot2 := 0
   DO WHILE  !Eof() .AND. ( fin_pripr->IdFirma + fin_pripr->IdVn + fin_pripr->BrNal == cIdFirma + cIdVn + cBrNal )
      IF D_P == "1"
         nDug  += Round( field->IznosBHD, 2 )
         nDug2 += Round( field->iznosdem, 2 )
      ELSE
         nPot  += Round( field->IznosBHD, 2 )
         nPot2 += Round( field->iznosdem, 2 )
      ENDIF
      SKIP
   ENDDO
   SKIP -1

   Scatter()

   cPic := FormPicL( "9 " + gPicBHD, 20 )

   @ m_x + 5, m_y + 2 SAY "Zbir naloga:"
   @ m_x + 6, m_y + 2 SAY "     Duguje:"
   @ m_x + 6, Col() + 2 SAY nDug PICTURE cPic
   @ m_x + 6, Col() + 2 SAY nDug2 PICTURE cPic
   @ m_x + 7, m_y + 2 SAY "  Potrazuje:"
   @ m_x + 7, Col() + 2 SAY nPot  PICTURE cPic
   @ m_x + 7, Col() + 2 SAY nPot2  PICTURE cPic
   @ m_x + 8, m_y + 2 SAY "      Saldo:"
   @ m_x + 8, Col() + 2 SAY nDug - nPot  PICTURE cPic
   @ m_x + 8, Col() + 2 SAY nDug2 - nPot2  PICTURE cPic
   Inkey( 0 )


   IF Round( nDug - nPot, 2 ) <> 0  .AND. gRavnot == "D"

      cDN := "N"
      SET CURSOR ON
      @ m_x + 10, m_y + 2 SAY8 "Želite li uravnoteziti nalog (D/N) ?" GET cDN valid ( cDN $ "DN" ) PICT "@!"
      READ

      IF cDN == "D"

         _Opis := PadR( "?", Len( _opis ) )
         _BrDok := ""
         _D_P := "2"
         _IdKonto := Space( 7 )

         @ m_x + 11, m_y + 2 SAY "Opis" GET _opis  PICT "@S40"
         @ m_x + 12, m_y + 2 SAY "Staviti na konto ?" GET _IdKonto VALID P_Konto( @_IdKonto )
         @ m_x + 12, Col() + 1 SAY "Datum dokumenta:" GET _DatDok
         READ

         IF LastKey() <> K_ESC
            _Rbr :=  _Rbr + 1
            _IdPartner := ""
            _IznosBHD := nDug - nPot
            konverzija_valute( NIL, NIL, "_IZNOSBHD" )
            APPEND BLANK
            my_rlock()
            Gather()
            my_unlock()
         ENDIF

      ENDIF

   ENDIF
   BoxC()

   PopWA()

   RETURN .T.



FUNCTION fin_saldo_provjera_psuban( cIdFirma, cIdVn, cBrNal )

   LOCAL lOkAzuriranje := .F.
   LOCAL _tmp, nSaldo

   IF gRavnot == "N"
      lOkAzuriranje := .T.
      RETURN lOkAzuriranje
   ENDIF

   SELECT psuban
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   nSaldo := 0

   DO WHILE !Eof() .AND. psuban->idfirma == cIdFirma .AND. psuban->idvn == cIdVn .AND. psuban->brnal == cBrNal

      IF field->d_p == "1"
         nSaldo += Round( psuban->iznosbhd, 2 )
      ELSE
         nSaldo -= Round( psuban->iznosbhd, 2 )
      ENDIF
      SKIP

   ENDDO

   IF Round( nSaldo, 2 ) <> 0
      Beep( 3 )
      Msg( "Neophodna ravnoteža naloga " + cIdFirma + "-" + cIdVn + "-" + AllTrim( cBrNal ) + "##, ažuriranje neće biti izvršeno!" )
      RETURN .F.
   ENDIF

   lOkAzuriranje := .T.

   RETURN lOkAzuriranje


FUNCTION is_fin_nalog_u_ravnotezi( cIdFirma, cIdVn, cBrNal )

   LOCAL  nDuguje, nPotrazuje, lRavnoteza

   PushWA()

   select_o_fin_pripr()

   IF cIdFirma == NIL
      GO TOP
      cIdFirma := field->IdFirma
      cIdVN := field->IdVN
      cBrNal := field->BrNal
   ENDIF

   nDuguje := 0
   nPotrazuje := 0
   DO WHILE  !Eof() .AND. ( field->IdFirma + field->IdVn + field->BrNal == cIdFirma + cIdVn + cBrNal )
      IF field->D_P == "1"
         nDuguje  += field->IznosBHD
      ELSE
         nPotrazuje  += field->IznosBHD
      ENDIF
      SKIP
   ENDDO

   PopWA()

   lRavnoteza := ( Round( nDuguje - nPotrazuje, 2 ) == 0 )

   IF !lRavnoteza
      MsgBeep( "FIN nalog " + cIdFirma + " - " + cIdVn + " - " + cBrNal + "##u pripremi nije u ravnoteži !?# STOP" )
   ENDIF

   RETURN lRavnoteza
