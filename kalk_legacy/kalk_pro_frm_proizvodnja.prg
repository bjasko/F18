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


FUNCTION leg_Get1_PR()

   SELECT F_SAST

   IF !Used()
      O_SAST
   ENDIF

   SELECT kalk_pripr

   IF nRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF

   IF nRbr == 1

      @ m_x + 6, m_y + 2 SAY "Broj fakture" GET _brfaktp
      @ m_x + 7, m_y + 2 SAY "Mag .got.proizvoda zaduzuje" GET _IdKonto VALID  P_Konto( @_IdKonto, 21, 5 ) PICT "@!"
      @ m_x + 8, m_y + 2 SAY "Mag. sirovina razduzuje    " GET _IdKonto2 PICT "@!" VALID P_Konto( @_IdKonto2 )
      @ m_x + 12, m_y + 2 SAY "Proizvod  " GET _IdRoba PICT "@!" valid  {|| P_Roba( @_IdRoba ), say_from_valid( 12, 24, Trim( Left( roba->naz, 40 ) ) + " (" + ROBA->jmj + ")", 40 ),;
       _IdTarifa := iif( kalk_is_novi_dokument(), ROBA->idtarifa, _IdTarifa ), .T. }
      @ m_x + 12, m_y + 70 GET _IdTarifa WHEN gPromTar == "N" VALID P_Tarifa( @_IdTarifa )

      SELECT tarifa
      hseek _IdTarifa

      // postavi TARIFA na pravu poziciju
      SELECT kalk_pripr
      // napuni tarifu

      @ m_x + 13, m_y + 2 SAY "Kolicina  " GET _Kolicina PICT PicKol VALID _Kolicina <> 0

      READ

      // _BrFaktP := _idzaduz2
      // sada trazim trebovanja u proizvod. u toku i filujem u stavke
      // od 100 pa nadalje
      // ove stavke imace  mu_i=="5", mkonto=_idkonto2, nc,nv
      // "KALKi7","idFirma+mkonto+IDZADUZ2+idroba+dtos(datdok)","KALK")

      nTPriPrec := RecNo()

      SELECT kalk_pripr
      GO BOTTOM

      IF Val( rbr ) < 900 .OR. ( Val( rbr ) > 1 .AND. Pitanje(, "Zelite li izbrisati izgenerisane sirovine ?", "N" ) == "D" )

         my_flock()

         DO WHILE !Bof() .AND. Val( rbr ) > 900
            SKIP -1
            nTrec := RecNo()
            SKIP
            my_delete()
            GO nTrec
         ENDDO

         my_unlock()

         SELECT ROBA
         hseek _idroba

         IF roba->tip = "P" .AND. nRbr == 1
            // radi se o proizvodu, prva stavka
            nRbr2 := 900
            SELECT sast
            hseek  _idroba
            DO WHILE !Eof() .AND. id == _idroba
               // setaj kroz sast
               SELECT roba
               hseek sast->id2
               SELECT kalk_pripr
               LOCATE FOR idroba == sast->id2
               IF Found()
                  RREPLACE kolicina WITH kolicina + kalk_pripr->kolicina * sast->kolicina
               ELSE
                  SELECT kalk_pripr
                  APPEND BLANK
                  REPLACE idfirma WITH _IdFirma, ;
                     rbr WITH Str( ++nRbr2, 3 ), ;
                     idvd WITH "PR", ;
                     brdok WITH _Brdok, ;
                     datdok WITH _Datdok, ;
                     idtarifa WITH ROBA->idtarifa, ;
                     brfaktp WITH _brfaktp, ;
                     datfaktp WITH _Datdok, ;
                     idkonto   WITH _idkonto, ;
                     idkonto2  WITH _idkonto2, ;
                     kolicina WITH _kolicina * sast->kolicina, ;
                     idroba WITH sast->id2, ;
                     nc WITH 0, ;
                     vpc WITH 0, ;
                     pu_i WITH "", ;
                     mu_i WITH "5", ;
                     error WITH "0", ;
                     mkonto WITH _idkonto2

                  nTTKNrec := RecNo()
                  // kalkulacija nabavne cijene
                  // nKolZN:=kolicina koja je na stanju a porijeklo je od zadnje nabavke
                  nKolS := 0
                  nKolZN := 0
                  nC1 := 0
                  nC2 := 0
                  dDatNab := CToD( "" )
                  IF _TBankTr <> "X"
                     // ako je X onda su stavke vec izgenerisane
                     IF !Empty( gMetodaNC )  .AND. !( roba->tip $ "UT" )
                        //MsgO( "Racunam stanje na skladistu" )
                        kalk_get_nabavna_mag( _idfirma, sast->id2, _idkonto2, @nKolS, @nKolZN, @nc1, @nc2, @dDatNab )
                        //MsgC()
                     ENDIF
                     IF dDatNab > _DatDok
                        Beep( 1 )
                        Msg( "Datum nabavke je " + DToC( dDatNab ) + " sirovina " + sast->id2, 4 )
                     ENDIF
                     IF _kolicina >= 0 .OR. Round( _NC, 3 ) == 0 .AND. !( roba->tip $ "UT" )
                        IF gMetodanc == "2"
                           SELECT roba
                           _rec := dbf_get_rec()
                           _rec[ "nc" ] := _nc
                           update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
                           SELECT kalk_pripr
                           // nafiluj sifrarnik robe sa nc sirovina, robe
                        ENDIF
                     ENDIF
                     SELECT kalk_pripr
                     GO nTTKNRec
                     my_rlock()
                     REPLACE nc WITH nc2, gkolicina WITH nKolS
                     my_unlock()

                  ENDIF
               ENDIF
               SELECT sast
               SKIP
            ENDDO
         ENDIF
         // roba->tip == "P"
      ENDIF
      SELECT kalk_pripr
      GO nTPriPrec
      //IF gNW <> "X"
      //   @ m_x + 10, m_y + 42  SAY "Zaduzuje: "   GET _IdZaduz  PICT "@!" VALID Empty( _idZaduz ) .OR. P_Firma( @_IdZaduz, 24 )
      //ENDIF
      READ
      ESC_RETURN K_ESC
   ELSE

      @ m_x + 7, m_y + 2   SAY "Mag. gotovih proizvoda zaduzuje ";?? _IdKonto
      @ m_x + 8, m_y + 2   SAY "Magacin sirovina razduzuje      ";?? _IdKonto2
      //IF gNW <> "X"
      //   @ m_x + 10, m_y + 42  SAY "Zaduzuje: "; ?? _IdZaduz
      //ENDIF

   ENDIF

   @ m_x + 11, m_y + 66 SAY "Tarif.brĿ"

   IF nRbr <> 1
      @ m_x + 12, m_y + 2  SAY "Sirovina  " GET _IdRoba PICT "@!" valid  {|| P_Roba( @_IdRoba ), say_from_valid( 12, 24, Trim( Left( roba->naz, 40 ) ) + " (" + ROBA->jmj + ")", 40 ), ;
      _IdTarifa := iif( kalk_is_novi_dokument(), ROBA->idtarifa, _IdTarifa ), .T. }
      @ m_x + 13, m_y + 2   SAY "Kolicina  " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0
   ENDIF

   READ
   ESC_RETURN K_ESC

   IF nRbr <> 1  // sirovine
      // kalkulacija nabavne cijene
      nKolS := 0
      nKolZN := 0
      nc1 := 0
      nc2 := 0
      dDatNab := CToD( "" )

      IF _TBankTr <> "X"
         // ako je X onda su stavke vec izgenerisane
         IF !Empty( gMetodaNC )  .AND. !( roba->tip $ "UT" )
            //MsgO( "Racunam stanje na skladistu" )
            kalk_get_nabavna_mag( _idfirma, _idroba, _idkonto2, @nKolS, @nKolZN, @nc1, @nc2, @dDatNab )
            //MsgC()
         ENDIF
         IF dDatNab > _DatDok
            Beep( 1 )
            Msg( "Datum nabavke je " + DToC( dDatNab ) + " sirovina " + sast->id2, 4 )
         ENDIF
         IF Round( nKols - _kolicina, 4 ) < 0
            MsgBeep( "Na stanju je samo :" + Str( nkols, 15, 3 ) )
            _error := "1"
         ENDIF
      ENDIF
      SELECT kalk_pripr
   ENDIF

   SELECT koncij
   SEEK Trim( _idkonto )
   SELECT kalk_pripr

   _MKonto := _Idkonto
   _MU_I := "1"

   //check_datum_posljednje_kalkulacije()

   IF kalk_is_novi_dokument()
      SELECT ROBA
      HSEEK _IdRoba
      _VPC := KoncijVPC()
      _TCarDaz := "%"
      _CarDaz := 0
   ENDIF

   SELECT kalk_pripr
   IF _tmarza <> "%"  // procente ne diraj
      _Marza := 0
   ENDIF

   IF nRbr <> 1
      @ m_x + 15, m_y + 2   SAY "N.CJ.(DEM/JM):"
      @ m_x + 15, m_y + 50  GET _NC PICTURE PicDEM VALID _nc >= 0
      READ
      _Mkonto := _idkonto2
      _mu_i := "5"
   ENDIF

   // preracunaj nc proiz
   nTT0Rec := RecNo()
   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   nNV := 0
   DO WHILE !Eof()
      IF Val( RBr ) > 900
         IF Val( rbr ) = nRbr
            nNV += _NC * _kolicina
         ELSE
            nNV += NC * kolicina
            // ovo je u stvari nabavna vrijednost
         ENDIF
         IF nRbr == 1 .AND. gkolicina < kolicina
            Beep( 2 )
            Msg( "Na stanju " + idkonto2 + " se nalazi samo " + Str( gkolicina, 9, 2 ) + " sirovine " + idroba,0 )
            _error := "1"
         ENDIF
      ENDIF
      SKIP
   ENDDO

   IF nRbr == 1
      _fcj := nNV / _kolicina
   ELSE
      IF !kalk_is_novi_dokument()
         GO TOP
         IF Val( rbr ) = 1
            RREPLACE fcj WITH nNv / kolicina
         ENDIF
      ENDIF
   ENDIF
   GO nTT0Rec

   IF nRbr == 1
      _fcj := nNV / _kolicina
      @ m_x + 15, m_y + 2   SAY "N.CJ.(DEM/JM):"
      @ m_x + 15, m_y + 50  GET _FCJ PICTURE PicDEM VALID _fcj > 0 WHEN V_kol10()
      READ
      ESC_RETURN K_ESC
   ENDIF

   _FCJ2 := _FCJ * ( 1 - _Rabat / 100 )

   RETURN LastKey()



// --------------------------------------------
// druga stranica unosa dokumenta PR
// --------------------------------------------
FUNCTION leg_Get2_PR()

   LOCAL cSPom := " (%,A,U,R) "

   IF nRbr <> 1
      RETURN K_ENTER
   ENDIF

   PRIVATE getlist := {}

   IF Empty( _TPrevoz ); _TPrevoz := "%"; ENDIF
   IF Empty( _TCarDaz ); _TCarDaz := "%"; ENDIF
   IF Empty( _TBankTr ); _TBankTr := "%"; ENDIF
   IF Empty( _TSpedTr ); _TSpedtr := "%"; ENDIF
   IF Empty( _TZavTr );  _TZavTr := "%" ; ENDIF
   IF Empty( _TMarza );  _TMarza := "%" ; ENDIF

   @ m_x + 2, m_y + 2 SAY cRNT1 + cSPom GET _TPrevoz VALID _TPrevoz $ "%AUR" PICTURE "@!"
   @ m_x + 2, m_y + 40 GET _Prevoz PICTURE PicDEM

   @ m_x + 3, m_y + 2 SAY cRNT2 + cSPom  GET _TBankTr VALID _TBankTr $ "%AUR" PICT "@!"
   @ m_x + 3, m_y + 40 GET _BankTr PICTURE PicDEM

   @ m_x + 4, m_y + 2 SAY cRNT3 + cSPom GET _TSpedTr VALID _TSpedTr $ "%AUR" PICT "@!"
   @ m_x + 4, m_y + 40 GET _SpedTr PICTURE PicDEM

   @ m_x + 5, m_y + 2 SAY cRNT4 + cSPom GET _TCarDaz VALID _TCarDaz $ "%AUR" PICTURE "@!"
   @ m_x + 5, m_y + 40 GET _CarDaz PICTURE PicDEM

   @ m_x + 6, m_y + 2 SAY cRNT5 + cSPom GET _TZavTr VALID _TZavTr $ "%AUR" PICTURE "@!"
   @ m_x + 6, m_y + 40 GET _ZavTr PICTURE PicDEM VALID {|| NabCj(), .T. }

   @ m_x + 8, m_y + 2 SAY "CIJENA KOST.  "
   @ m_x + 8, m_y + 50 GET _NC PICTURE PicDEM

   IF koncij->naz <> "N1"

      // vodi se po vpc
      PRIVATE fMarza := " "
      @ m_x + 10, m_y + 2 SAY "Magacin. Marza            :" GET _TMarza VALID _Tmarza $ "%AU" PICTURE "@!"
      @ m_x + 10, m_y + 40 GET _Marza PICTURE PicDEM
      @ m_x + 10, Col() + 1 GET fMarza PICT "@!"
      @ m_x + 12, m_y + 2 SAY "VELEPRODAJNA CJENA  (VPC)   :"
      @ m_x + 12, m_y + 50 GET _VPC PICT PicDEM VALID {|| Marza( fMarza ), .T. }

      READ
      SetujVPC( _vpc )

   ELSE

      READ
      _Marza := 0
      _TMarza := "A"
      _VPC := _NC

   ENDIF

   IF nRbr = 1
      _MKonto := _Idkonto; _MU_I := "1"
   ENDIF
   nStrana := 3

   RETURN LastKey()
