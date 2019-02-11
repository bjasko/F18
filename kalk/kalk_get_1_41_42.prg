/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR _pkonto, _idkonto2
MEMVAR GetList

FUNCTION kalk_get_1_41_42()

   LOCAL lRet

   IF Empty( _pkonto )
      _pkonto := _idkonto2
   ENDIF

   lKalkIzgenerisaneStavke := .F. // izgenerisane stavke jos ne postoje
   PRIVATE aPorezi := {}

   IF kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF _idvd == "41"
      @  box_x_koord() + 6,  box_y_koord() + 2 SAY "KUPAC:" GET _IdPartner PICT "@!" VALID Empty( _IdPartner ) .OR. p_partner( @_IdPartner, 5, 30 )
      @  box_x_koord() + 7,  box_y_koord() + 2 SAY "Faktura Broj:" GET _BrFaktP
      @  box_x_koord() + 7, Col() + 2 SAY "Datum:" GET _DatFaktP
   ELSE
      _idpartner := ""
      _brfaktP := ""

   ENDIF

   @ box_x_koord() + 8, box_y_koord() + 2  SAY8 "Prodavnički Konto razdužuje" GET _pkonto VALID  P_Konto( @_pkonto, 8, 38 ) PICT "@!"

   //_idkonto2 := ""
   _idzaduz2 := ""

   READ

   SELECT kalk_pripr
   ESC_RETURN K_ESC

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"
   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _idVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   @ box_x_koord() + 12, box_y_koord() + 2  SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_tarifa( _IdTarifa )
   select_o_koncij( _pkonto )
   SELECT kalk_pripr  // napuni tarifu


   _GKolicina := 0
   _GKolicin2 := 0

   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      select_o_roba( _IdRoba )
      _MPCSaPP := kalk_get_mpc_by_koncij_pravilo()

      IF gMagacin == "2"
         _FCJ := NC
         _VPC := 0
      ELSE
         _FCJ := NC
         _VPC := 0
      ENDIF

      SELECT kalk_pripr
      _Marza2 := 0
      _TMarza2 := "A"

   ENDIF

   IF ( dozvoljeno_azuriranje_sumnjivih_stavki() .AND. ( _MpcSAPP == 0 .OR. kalk_is_novi_dokument() ) )
      kalk_fakticka_mpc( @_MPCSAPP, _idfirma, _pkonto, _idroba )
   ENDIF

   _vpc := 0
   IF ( roba->tip != "T" )

      nKolS := 0
      nKolZN := 0
      nc1 := 0
      nc2 := 0

      // ako je X onda su stavke vec izgenerisane
      IF _TBankTr <> "X"
         IF !Empty( kalk_metoda_nc() )
            nc1 := 0
            nc2 := 0

            kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolS, @nKolZN, @nc1, @nc2 )

            IF kalk_metoda_nc() $ "13"
               _fcj := nc1
            ELSEIF kalk_metoda_nc() == "2"
               _fcj := nc2
            ENDIF
         ENDIF
      ENDIF

      @ box_x_koord() + 12, box_y_koord() + 30 SAY "Ukupno na stanju "
      @ box_x_koord() + 12, Col() + 2 SAY nKols PICT pickol

      @ box_x_koord() + 14, box_y_koord() + 2 SAY "NC  :" GET _fcj PICT picdem ;
         VALID {|| lRet := kalk_valid_kolicina_prod(), _tprevoz := "A", _prevoz := 0, _nc := _fcj, lRet }

      @ box_x_koord() + 15, box_y_koord() + 40 SAY "MP marza:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICTURE "@!"
      @ box_x_koord() + 15, Col() + 1 GET _Marza2 PICTURE  PicDEM

   ENDIF

   @ box_x_koord() + 17, box_y_koord() + 2 SAY "PRODAJNA CJENA  (PC):"
   @ box_x_koord() + 17, box_y_koord() + 50 GET _mpc PICT PicDEM WHEN kalk_when_valid_mpc_80_81_41_42( IdVd, .F., @aPorezi ) VALID kalk_valid_mpc_80_81_41_42( _IdVd, .F., @aPorezi )

   PRIVATE cRCRP := gRCRP

   @ box_x_koord() + 18, box_y_koord() + 2 SAY "POPUST (C-CIJENA,P-%)" GET cRCRP VALID cRCRP $ "CP" PICT "@!"
   @ box_x_koord() + 18, box_y_koord() + 50 GET _Rabatv PICT picdem VALID RabProcToC()

   kalk_say_pdv_a_porezi_var( 19 )

   @ box_x_koord() + 20, box_y_koord() + 2 SAY "MPC SA PDV    :"
   @ box_x_koord() + 20, box_y_koord() + 50 GET _mpcsapp PICT PicDEM VALID kalk_valid_mpcsapdv( _IdVd, .F., @aPorezi, .T. )

   READ

   ESC_RETURN K_ESC

   _PU_I := "5" // izlaz iz prodavnice
   nKalkStrana := 2

   kalk_puni_polja_za_izgenerisane_stavke( lKalkIzgenerisaneStavke )

   RETURN LastKey()


STATIC FUNCTION RabProcToC()

   IF cRCRP == "P"
      _rabatv := _mpc * ( _rabatv / 100 )
      cRCRP := "C"
      ShowGets()
   ENDIF

   RETURN .T.