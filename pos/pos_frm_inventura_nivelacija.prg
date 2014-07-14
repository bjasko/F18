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


#include "pos.ch"

STATIC _saldo_izn := 0
STATIC _saldo_kol := 0


FUNCTION InventNivel()

   PARAMETERS fInvent, fIzZad, fSadAz, dDatRada, stanje_dn

   LOCAL i := 0
   LOCAL j := 0
   LOCAL fPocInv := .F.
   LOCAL fPreuzeo := .F.
   LOCAL cNazDok

   PRIVATE cRSdbf
   PRIVATE cRSblok
   PRIVATE cUI_U
   PRIVATE cUI_I
   PRIVATE cIdVd
   PRIVATE cZaduzuje := "R"

   IF gSamoProdaja == "D"
      MsgBeep( "Ne možete vršiti unos zaduženja !" )
      RETURN
   ENDIF

   IF dDatRada == nil
      dDatRada := gDatum
   ENDIF

   IF stanje_dn == nil
      stanje_dn := "N"
   ENDIF

   IF ( fInvent == nil )
      fInvent := .T.
   ELSE
      fInvent := fInvent
   ENDIF

   IF fInvent
      cIdVd := VD_INV
   ELSE
      cIdVd := VD_NIV
   ENDIF

   IF fInvent
      cNazDok := "INVENTUR"
   ELSE
      cNazDok := "NIVELACIJ"
   ENDIF

   IF fIzZad == nil
      fIzZad := .F.
      // fja pozvana iz zaduzenja
   ENDIF

   IF fSadAz == nil
      fSadAz := .F.
      // fja pozvana iz zaduzenja
   ENDIF

   IF fIzZad
      // ne diraj ove varijable
   ELSE
      PRIVATE cIdOdj := Space( 2 )
      PRIVATE cIdDio := Space( 2 )
   ENDIF

   o_pos_tables()

   SET CURSOR ON

   IF !fIzZad

      aNiz := {}

      IF gVodiOdj == "D"
         AAdd( aNiz, { "Sifra odjeljenja", "cIdOdj", "P_Odj(@cIdOdj)",, } )
      ENDIF

      IF gPostDO == "D" .AND. fInvent
         AAdd( aNiz, { "Sifra dijela objekta", "cIdDio", "P_Dio(@cIdDio)",, } )
      ENDIF

      AAdd( aNiz, { "Datum rada", "dDatRada", "dDatRada <= DATE()",, } )
      AAdd( aNiz, { "Inventura sa gen.stanja (D/N) ?", "stanje_dn", "stanje_dn $ 'DN'", "@!", } )

      IF !VarEdit( aNiz, 9, 15, 15, 64, cNazDok + "A", "B1" )
         CLOSE ALL
         RETURN
      ENDIF

   ENDIF

   SELECT ODJ

   cZaduzuje := "R"
   cRSdbf := "ROBA"
   // cRSblok := "P_Roba( @_IdRoba, 1, 31 )"
   cUI_U := R_U
   cUI_I := R_I

   IF !pos_vrati_dokument_iz_pripr( cIdVd, gIdRadnik, cIdOdj, cIdDio )
      CLOSE ALL
      RETURN
   ENDIF

   SELECT priprz

   IF RecCount2() == 0
      fPocInv := .T.
   ELSE
      fPocInv := .F.
      dDatRada := priprz->datum
   ENDIF

   IF fPocInv

      cBrDok := pos_novi_broj_dokumenta( gIdPos, cIdVd )

      fPreuzeo := .F.

      IF !fPreuzeo
         o_pos_tables()
      ENDIF

      IF stanje_dn == "N" .AND. cIdVd == VD_INV
         fPocInv := .F.
      ENDIF

      IF fPocInv .AND. !fPreuzeo .AND. cIdVd == VD_INV

         MsgO( "GENERIŠEM DATOTEKU " + cNazDok + "E" )

         SELECT priprz

         Scatter()

         SELECT pos
         SET ORDER TO TAG "2"
         // "2", "IdOdj + idroba + DTOS(Datum)
         SEEK cIdOdj

         DO WHILE !Eof() .AND. field->idodj == cIdOdj

            IF pos->datum > dDatRada
               SKIP
               LOOP
            ENDIF

            _kolicina := 0
            _idroba := pos->idroba

            DO WHILE !Eof() .AND. pos->( idodj + idroba ) == ( cIdOdj + _idroba ) .AND. pos->datum <= dDatRada

               IF !Empty( cIdDio ) .AND. pos->iddio <> cIdDio
                  SKIP
                  LOOP
               ENDIF

               IF cZaduzuje == "S" .AND. pos->idvd $ "42#01"
                  SKIP
                  LOOP
               ENDIF

               IF cZaduzuje == "R" .AND. pos->idvd == "96"
                  SKIP
                  LOOP
               ENDIF

               IF pos->idvd $ "16#00"
                  _kolicina += pos->kolicina

               ELSEIF pos->idvd $ "42#96#01#IN#NI"
                  DO CASE
                  CASE pos->idvd == VD_INV
                     _kolicina -= pos->kolicina - pos->kol2
                  CASE pos->idvd == VD_NIV
                  OTHERWISE
                     _kolicina -= pos->kolicina
                  ENDCASE
               ENDIF
               SKIP
            ENDDO

            IF Round( _kolicina, 3 ) <> 0

               SELECT ( cRSdbf )
               HSEEK _idroba

               _cijena := pos_get_mpc()
               _ncijena := pos_get_mpc()
               _robanaz := _field->naz
               _jmj := _field->jmj
               _idtarifa := _field->idtarifa

               SELECT priprz

               _IdOdj := cIdOdj
               _IdDio := cIdDio
               _BrDok := cBrDok
               _IdVd := cIdVd
               _Prebacen := OBR_NIJE
               _IdCijena := "1"
               _IdRadnik := gIdRadnik
               _IdPos := gIdPos
               _datum := dDatRada
               _Smjena := gSmjena
               _Kol2 := _Kolicina
               _MU_I := cUI_I

               APPEND BLANK
               Gather()

               SELECT pos

            ENDIF

         ENDDO

         MsgC()

      ELSE
         SELECT priprz
         my_dbf_zap()
      ENDIF

   ELSE

      SELECT priprz
      GO TOP
      cBrDok := priprz->brdok

   ENDIF

   IF !fSadAz

      ImeKol := {}

      AAdd( ImeKol, { "Sifra i naziv", {|| idroba + "-" + Left( robanaz, 25 ) } } )
      AAdd( ImeKol, { "BARKOD", {|| barkod } } )

      IF cIdVd == VD_INV
         AAdd( ImeKol, { "Knj.kol.", {|| Str( kolicina, 9, 3 ) } } )
         AAdd( ImeKol, { "Pop.kol.", {|| Str( kol2, 9, 3 ) }, "kol2" } )
      ELSE
         AAdd( ImeKol, { "Kolicina", {|| Str( kolicina, 9, 3 ) } } )
      ENDIF

      AAdd( ImeKol, { "Cijena ", {|| Str( cijena, 7, 2 ) } } )

      IF cIdVd == VD_NIV
         AAdd( ImeKol, { "Nova C.",     {|| Str( ncijena, 7, 2 ) } } )
      ENDIF

      AAdd( ImeKol, { "Tarifa ", {|| idtarifa } } )
      AAdd( ImeKol, { "Datum ", {|| datum } } )

      Kol := {}

      FOR nCnt := 1 TO Len( ImeKol )
         AAdd( Kol, nCnt )
      NEXT

      SELECT priprz
      SET ORDER TO TAG "1"

      DO WHILE .T.

         SELECT priprz
         GO TOP

         @ 12, 0 SAY ""

         SET CURSOR ON

         ObjDBedit( "PripInv", MAXROWS() - 15, MAXCOLS() - 3, {|| EditInvNiv( dDatRada ) }, ;
            "Broj dokumenta: " + AllTrim( cBrDok ) + " datum: " + DToC( dDatRada ), ;
            "PRIPREMA " + cNazDok + "E", nil, ;
            { "<c-N>   Dodaj stavku", "<Enter> Ispravi stavku", "<a-P>   Popisna lista", "<c-P>   Stampanje", "<c-A> cirk ispravka", "<D> ispravi datum" }, 2, , , )

         IF priprz->( RecCount() ) == 0
            pos_reset_broj_dokumenta( gIdPos, cIdVd, cBrDok )
            CLOSE ALL
            RETURN
         ENDIF

         i := KudaDalje( "ZAVRSAVATE SA PRIPREMOM " + cNazDok + "E. STA RADITI S NJOM?", { ;
            "NASTAVICU S NJOM KASNIJE", ;
            "AZURIRATI (ZAVRSENA JE)", ;
            "TREBA JE IZBRISATI", ;
            "VRATI PRIPREMU " + cNazDok + "E" } )

         IF i == 1

            SELECT _POS
            AppFrom( "PRIPRZ", .F. )
            SELECT PRIPRZ
            my_dbf_zap()
            CLOSE ALL
            RETURN

         ELSEIF i == 3

            IF Pitanje(, "Sigurno želite izbrisati pripremu dokumenta (D/N) ?", "N" ) == "D"

               SELECT PRIPRZ
               my_dbf_zap()
               pos_reset_broj_dokumenta( gIdPos, cIdVd, cBrDok )
               CLOSE ALL
               RETURN

            ELSE

               SELECT _POS
               AppFrom( "PRIPRZ", .F. )
               SELECT PRIPRZ
               my_dbf_zap()
               CLOSE ALL
               RETURN

            ENDIF

         ELSEIF i == 4

            SELECT PRIPRZ
            GO TOP
            LOOP

         ENDIF

         IF i == 2
            EXIT
         ENDIF

      ENDDO

   ENDIF

   check_before_azur( dDatRada )

   pos_azuriraj_inventura_nivelacija()

   CLOSE ALL

   RETURN


STATIC FUNCTION check_before_azur( dDatRada )

   LOCAL _ret := .T.
   LOCAL _rec

   MsgO( "Provjera unesenih podataka prije ažuriranja u toku ..." )

   SELECT priprz
   GO TOP
   DO WHILE !Eof()

      IF field->datum <> dDatRada
         _rec := dbf_get_rec()
         _rec[ "datum" ] := dDatRada
         dbf_update_rec( _rec )
      ENDIF
      SKIP
   ENDDO

   SELECT priprz
   GO TOP

   MsgC()

   RETURN _ret



FUNCTION EditInvNiv( dat_inv_niv )

   LOCAL nRec := RecNo()
   LOCAL i := 0
   LOCAL lVrati := DE_CONT
   LOCAL _dat

   DO CASE

   CASE Ch == K_CTRL_P

      StampaInv()

      o_pos_tables()
      SELECT priprz
      GO nRec

      lVrati := DE_REFRESH

   CASE Upper( Chr( Ch ) ) == "D"

      _dat := Date()

      Box(, 1, 50 )
      @ m_x + 1, m_y + 2 SAY "Postavi datum na:" GET _dat
      READ
      BoxC()

      IF LastKey() <> K_ESC
         check_before_azur( _dat )
         TB:RefreshAll()
         DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
            Tb:stabilize()
         ENDDO
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_ALT_P

      IF cIdVd == VD_INV
         StampaInv( .T. )
         o_pos_tables()
         SELECT priprz
         GO nRec
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_ENTER

      _calc_priprz()

      IF !( EdPrInv( 1, dat_inv_niv ) == 0 )
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_O

      IF update_ip_razlika() == 1
         lVrati := DE_REFRESH
      ENDIF

   CASE Ch == K_CTRL_U

      update_knj_kol()
      lVrati := DE_REFRESH

   CASE Ch == K_CTRL_A

      DO WHILE !Eof()
         IF EdPrInv( 1, dat_inv_niv ) == 0
            EXIT
         ENDIF
         SKIP
      ENDDO

      IF Eof()
         SKIP -1
      ENDIF

      lVrati := DE_REFRESH

   CASE Ch == K_CTRL_N

      _calc_priprz()

      EdPrInv( 0, dat_inv_niv )

      lVrati := DE_REFRESH

   CASE Ch == K_CTRL_T

      lVrati := DE_CONT

      IF Pitanje(, "Stavku " + AllTrim( priprz->idroba ) + " izbrisati ?", "N" ) == "D"
         my_delete_with_pack()
         lVrati := DE_REFRESH
      ENDIF

   ENDCASE

   RETURN lVrati



STATIC FUNCTION _calc_priprz()

   LOCAL _t_area := Select()
   LOCAL _t_rec := RecNo()

   SELECT priprz
   GO TOP

   _saldo_kol := 0
   _saldo_izn := 0

   DO WHILE !Eof()

      IF field->idvd == "IN"
         _saldo_kol += field->kol2
         _saldo_izn += ( field->kol2 * field->cijena )
      ELSE
         _saldo_kol += field->kolicina
         _saldo_kol += ( field->kolicina * field->cijena )
      ENDIF

      SKIP

   ENDDO

   SELECT ( _t_area )
   GO ( _t_rec )

   RETURN




FUNCTION edprinv( nInd, datum )

   LOCAL nVrati := 0
   LOCAL aNiz := {}
   LOCAL nRec := RecNo()
   LOCAL _r_tar, _r_barkod, _r_jmj, _r_naz
   LOCAL _duz_sif := "10"
   LOCAL _pict := "9999999.99"
   LOCAL _last_read_var

   IF gDuzSifre <> NIL .AND. gDuzSifre > 0
      _duz_sif := AllTrim( Str( gDuzSifre ) )
   ENDIF

   SET CURSOR ON

   SELECT priprz

   DO WHILE .T.

      SET CONFIRM ON

      Box(, 7, maxcols() -5, .T. )

      @ m_x + 0, m_y + 1 SAY " " + IF( nInd == 0, "NOVA STAVKA", "ISPRAVKA STAVKE" ) + " "

      Scatter()

      @ m_x + 1, m_y + 31 SAY PadR( "", 35 )
      @ m_x + 6, m_y + 2 SAY "... zadnji artikal: " + AllTrim( _idroba ) + " - " + PadR( _robanaz, 25 ) + "..."
      @ m_x + 7, m_y + 2 SAY "stanje unosa - kol: " + AllTrim( Str( _saldo_kol, 12, 2 ) ) + ;
         " total: " + AllTrim( Str( _saldo_izn, 12, 2 ) )

      SELECT ( cRSdbf )
      hseek _idroba

      IF nInd == 1
         @ m_x + 0, m_y + 1 SAY _idroba + " : " + AllTrim( naz ) + " (" + AllTrim( idtarifa ) + ")"
      ENDIF

      SELECT priprz

      IF nInd == 0

         _idodj := cIdOdj
         _iddio := cIdDio
         _idroba := Space( 10 )
         _kolicina := 0
         _kol2 := 0
         _brdok := cBrDok
         _idvd := cIdVd
         _prebacen := OBR_NIJE
         _idcijena := "1"
         _idradnik := gIdRadnik
         _idpos := gIdPos
         _cijena := 0
         _ncijena := 0
         _datum := datum
         _smjena := gSmjena
         _mu_i := cUI_I

      ENDIF

      nLX := m_x + 1
	
      @ nLX, m_y + 3 SAY "      Artikal:" GET _idroba ;
         PICT PICT_POS_ARTIKAL ;
         WHEN {|| _idroba := PadR( _idroba, Val( _duz_sif ) ), .T. } ;
         VALID valid_pos_inv_niv( cIdVd, nInd )


      nLX ++

      IF cIdVd == VD_INV
         @ nLX, m_y + 3 SAY8 "Knj. količina:" GET _kolicina PICT _pict ;
            WHEN {|| .F. }
      ELSE
         @ nLX, m_y + 3 SAY8 "     Količina:" GET _kolicina PICT _pict ;
            WHEN {|| .T. }
      ENDIF

      nLX ++

      IF cIdVd == VD_INV

         @ nLX, m_y + 3 SAY8 "Pop. količina:" GET _kol2 PICT _pict ;
            VALID _pop_kol( _kol2 ) ;
            WHEN {|| .T. }

         nLX ++

      ENDIF

      @ nLX, m_y + 3 SAY "       Cijena:" GET _cijena PICT _pict ;
         WHEN {|| .T. } ;
         VALID {|| _cijena < 999999.99 }

      IF cIdVd == VD_NIV

         nLX ++

         @ nLX, m_y + 3 SAY "  Nova cijena:" GET _ncijena PICT _pict ;
            WHEN {|| .T. }

      ENDIF

      READ

      IF LastKey() == K_ESC

         BoxC()

         TB:RefreshAll()
         DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
            Tb:stabilize()
         ENDDO

         EXIT

      ENDIF

      IF nInd == 0

         SELECT priprz
         GO TOP
         SEEK _idroba

         IF !Found()
            APPEND BLANK
         ENDIF

      ENDIF

      SELECT ( cRSdbf )
      SET ORDER TO TAG "ID"
      hseek _idroba

      _r_tar := field->idtarifa
      _r_barkod := field->barkod
      _r_naz := field->naz
      _r_jmj := field->jmj

      SELECT priprz

      _idtarifa := _r_tar
      _barkod := _r_barkod
      _robanaz := _r_naz
      _jmj := _r_jmj

      _kol2 := ( priprz->kol2 + _kol2 )

      Gather()

      _saldo_kol += priprz->kol2
      _saldo_izn += ( priprz->kol2 * priprz->cijena )

      IF nInd == 0

         TB:RefreshAll()

         DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
            Tb:stabilize()
         ENDDO

      ENDIF


      IF nInd == 1
         nVrati := 1
         BoxC()
         EXIT
      ENDIF

      BoxC()

   ENDDO

   GO nRec

   RETURN nVrati


STATIC FUNCTION update_ip_razlika()

   LOCAL _id_odj := Space( 2 )
   LOCAL ip_kol, ip_roba
   LOCAL _rec2, _rec

   IF Pitanje(, "Generisati razliku artikala sa stanja ?", "N" ) == "N"
      RETURN 0
   ENDIF

   MsgO( "GENERIŠEM RAZLIKU NA OSNOVU STANJA" )

   SELECT priprz
   GO TOP
   _rec2 := dbf_get_rec()

   SELECT pos
   SET ORDER TO TAG "2"
   // "2", "IdOdj + idroba + DTOS(Datum)
   SEEK _id_odj

   DO WHILE !Eof() .AND. field->idodj == _id_odj

      IF pos->datum > dDatRada
         SKIP
         LOOP
      ENDIF

      ip_kol := 0
      ip_roba := pos->idroba

      SELECT priprz
      SET ORDER TO TAG "1"
      GO TOP
      SEEK PadR( ip_roba, 10 )

      IF Found() .AND. field->idroba == PadR( ip_roba, 10 )
         SELECT pos
         SKIP
         LOOP
      ENDIF

      SELECT pos

      DO WHILE !Eof() .AND. pos->( idodj + idroba ) == ( _id_odj + ip_roba ) .AND. pos->datum <= dDatRada

         IF !Empty( cIdDio ) .AND. pos->iddio <> cIdDio
            SKIP
            LOOP
         ENDIF

         IF pos->idvd $ "16#00"
            ip_kol += pos->kolicina

         ELSEIF pos->idvd $ "42#96#01#IN#NI"
            DO CASE
            CASE pos->idvd == VD_INV
               ip_kol -= pos->kolicina - pos->kol2
            CASE pos->idvd == VD_NIV
            OTHERWISE
               ip_kol -= pos->kolicina
            ENDCASE
         ENDIF

         SKIP

      ENDDO

      IF Round( ip_kol, 3 ) <> 0

         SELECT roba
         SET ORDER TO TAG "ID"
         GO TOP
         SEEK ip_roba

         SELECT priprz
         APPEND BLANK

         _rec := dbf_get_rec()
         _rec[ "cijena" ] := pos_get_mpc()
         _rec[ "ncijena" ] := 0
         _rec[ "idroba" ] := ip_roba
         _rec[ "barkod" ] := roba->barkod
         _rec[ "robanaz" ] := roba->naz
         _rec[ "jmj" ] := roba->jmj
         _rec[ "idtarifa" ] := roba->idtarifa
         _rec[ "kol2" ] := 0
         _rec[ "kolicina" ] := ip_kol
         _rec[ "brdok" ] := _rec2[ "brdok" ]
         _rec[ "datum" ] := _rec2[ "datum" ]
         _rec[ "idcijena" ] := _rec2[ "idcijena" ]
         _rec[ "idpos" ] := _rec2[ "idpos" ]
         _rec[ "idradnik" ] := _rec2[ "idradnik" ]
         _rec[ "idvd" ] := _rec2[ "idvd" ]
         _rec[ "mu_i" ] := _rec2[ "mu_i" ]
         _rec[ "prebacen" ] := _rec2[ "prebacen" ]
         _rec[ "smjena" ] := _rec2[ "smjena" ]

         dbf_update_rec( _rec )

      ENDIF

      SELECT pos

   ENDDO

   SELECT priprz
   GO TOP

   TB:RefreshAll()

   DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
      Tb:stabilize()
   ENDDO

   RETURN 1


STATIC FUNCTION update_knj_kol()

   SELECT priprz
   GO TOP

   DO WHILE !Eof()
      Scatter()
      RacKol( _idodj, _idroba, @_kolicina )
      SELECT priprz
      Gather()
      SKIP
   ENDDO

   TB:RefreshAll()

   DO WHILE !TB:stable .AND. ( Ch := Inkey() ) == 0
      Tb:stabilize()
   ENDDO

   SELECT priprz
   GO TOP

   RETURN .T.


STATIC FUNCTION valid_pos_inv_niv( cIdVd, ind )

   LOCAL _area := Select()

   pos_postoji_roba( @_IdRoba, 1, 31 )

   RacKol( _idodj, _idroba, @_kolicina )

   _set_cijena_artikla( cIdVd, _idroba )

   IF ind == 0 .AND. !_postoji_artikal_u_pripremi( _idroba )
      SELECT ( _area )
   ENDIF

   IF cIdVD == VD_INV
      get_field_set_focus( "_kol2" )
   ELSE
      get_field_set_focus( "_cijena" )
   ENDIF

   SELECT ( _area )

   RETURN .T.




FUNCTION _pop_kol( kol )

   LOCAL _ok := .T.

   IF kol > 200
      IF Pitanje(, "Da li je " + AllTrim( Str( kol, 12, 2 ) ) + " ispravna količina (D/N) ?", "N" ) == "N"
         _ok := .F.
      ENDIF
   ENDIF

   RETURN _ok



FUNCTION _set_cijena_artikla( id_vd, id_roba )

   LOCAL _t_area := Select()

   IF id_vd == VD_INV

      SELECT roba
      hseek id_roba
      _cijena := pos_get_mpc()

   ENDIF

   SELECT ( _t_area )

   RETURN .T.


FUNCTION _postoji_artikal_u_pripremi( id_roba )

   LOCAL _ok := .T.
   LOCAL _t_area := Select()
   LOCAL _t_rec := RecNo()

   SELECT priprz
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_roba

   IF Found()
      _ok := .F.
      MsgBeep( "Artikal " + AllTrim( id_roba ) + " se već nalazi u pripremi! Ako nastavite sa unosom #dodat će se vrijednost na postojeću stavku..." )
   ENDIF

   SELECT ( _t_area )
   GO ( _t_rec )

   RETURN _ok



FUNCTION RacKol( cIdOdj, cIdRoba, nKol )

   MsgO( "Računam količinu artikla ..." )
 
   SELECT pos
   SET ORDER TO TAG "2"
   nKol := 0

   SEEK cIdOdj + cIdRoba

   WHILE !Eof() .AND. pos->( IdOdj + IdRoba ) == ( cIdOdj + cIdRoba ) .AND. pos->Datum <= dDatRada

      IF AllTrim( POS->IdPos ) == "X"
         SKIP
         LOOP
      ENDIF

      IF pos->idvd $ "16#00"
         nKol += pos->Kolicina
      ELSEIF POS->idvd $ "42#01#IN#NI"
         DO CASE
         CASE POS->IdVd == VD_INV
            nKol := pos->kol2
         CASE POS->idvd == VD_NIV
         OTHERWISE
            nKol -= pos->kolicina
         ENDCASE
      ENDIF
      SKIP
   ENDDO

   MsgC()

   SELECT priprz

   RETURN ( .T. )
