#include "f18.ch"

/*

FUNCTION fin_prekart()

   LOCAL _arr := {}
   LOCAL _usl_kto, _usl_part, _tmp_dbf
   PRIVATE _id_konto := fetch_metric( "fin_preb_kart_id_konto", my_user(), Space( 60 ) )
   PRIVATE _id_partner := fetch_metric( "fin_preb_kart_id_partner", my_user(), Space( 60 ) )
   PRIVATE _dat_od := fetch_metric( "fin_preb_kart_dat_od", my_user(), CToD( "" ) )
   PRIVATE _dat_do := fetch_metric( "fin_preb_kart_dat_do", my_user(), CToD( "" ) )
   PRIVATE _id_firma := self_organizacija_id()

   Msg( "Ova opcija omogucava prebacivanje svih ili dijela stavki sa#" + ;
      "postojeceg na drugi konto. Zeljeni konto je u tabeli prikazan#" + ;
      "u koloni sa zaglavljem 'Novi konto'. POSLJEDICA OVIH PROMJENA#" + ;
      "JE DA CE NALOZI KOJI SADRZE IZMIJENJENE STAVKE BITI RAZLICITI#" + ;
      "OD ODSTAMPANIH, PA SE PREPORUCUJE PONOVNA STAMPA TIH NALOGA." )

   AAdd ( _arr, { "Firma (prazno-sve)", "_id_firma",,, } )
   AAdd ( _arr, { "Konto (prazno-sva)", "_id_konto",, "@!S30", } )
   AAdd ( _arr, { "Partner (prazno-svi)", "_id_partner",, "@!S30", } )
   AAdd ( _arr, { "Za period od datuma", "_dat_od",,, } )
   AAdd ( _arr, { "          do datuma", "_dat_do",,, } )

   DO WHILE .T.

      IF !VarEdit( _arr, 9, 5, 17, 74, ;
            'POSTAVLJANJE USLOVA ZA IZDVAJANJE SUBANALITICKIH STAVKI', ;
            "B1" )
         my_close_all_dbf()
         RETURN
      ENDIF

      _usl_kto := Parsiraj( _id_konto, "idkonto" )
      _usl_part := Parsiraj( _id_partner, "idpartner" )

      IF _usl_kto <> NIL .AND. _usl_part <> NIL
         EXIT
      ELSEIF _usl_part <> NIL
         MsgBeep ( "Kriterij za partnera nije korektno postavljen!" )
      ELSEIF _usl_kto <> NIL
         MsgBeep ( "Kriterij za konto nije korektno postavljen!" )
      ELSE
         MsgBeep ( "Kriteriji za konto i partnera nisu korektno postavljeni!" )
      ENDIF

   ENDDO

   o_konto()
   // o_partner()
   o_sint()
   SET ORDER TO TAG "2"
   o_anal()
   SET ORDER TO TAG "2"
   o_suban()

   _cre_temp77()

   SELECT ( F_SUBAN )

   _filter := ".t." + IF( !Empty( _id_firma ), ".and.IDFIRMA==" + dbf_quote( _id_firma ), "" ) + iif( !Empty( _dat_od ), ".and.DATDOK>=" + dbf_quote( _dat_do ), "" ) + ;
      IF( !Empty( _dat_do ), ".and.DATDOK<=" + dbf_quote( _dat_do ), "" ) + ".and." + _usl_kto + ".and." + _usl_part

   _filter := StrTran( _filter, ".t..and.", "" )

   IF !( _filter == ".t." )
      SET FILTER TO &( _filter )
   ENDIF

   GO TOP
   DO WHILE !Eof()

      _rec := dbf_get_rec()
      _rec[ "konto2" ] := _rec[ "idkonto" ]
      _rec[ "part2" ] := _rec[ "idpartner" ]
      _rec[ "nslog" ] := RecNo()

      SELECT TEMP77
      APPEND BLANK

      dbf_update_rec( _rec )

      SELECT F_SUBAN
      SKIP 1

   ENDDO

   SELECT TEMP77
   GO TOP

   ImeKol := { ;
      { "F.",            {|| IdFirma }, "IdFirma" }, ;
      { "VN",            {|| IdVN    }, "IdVN" }, ;
      { "Br.",           {|| BrNal   }, "BrNal" }, ;
      { "R.br",          {|| RBr     }, "rbr", {|| wRbr() }, {|| .T. } }, ;
      { "Konto",         {|| IdKonto }, "IdKonto", {|| .T. }, {|| P_Konto( @_IdKonto ), .T. } }, ;
      { "Novi konto",    {|| konto2  }, "konto2", {|| .T. }, {|| P_Konto( @_konto2 ), .T. } }, ;
      { "Partner",       {|| IdPartner }, "IdPartner", {|| .T. }, {|| p_partner( @_idpartner ), .T. } }, ;
      { "Novi partner",  {|| part2  }, "part2", {|| .T. }, {|| p_partner( @_part2 ), .T. } }, ;
      { "Br.veze ",      {|| BrDok   }, "BrDok" }, ;
      { "Datum",         {|| DatDok  }, "DatDok" }, ;
      { "D/P",           {|| D_P     }, "D_P" }, ;
      { valuta_domaca_skraceni_naziv(),     {|| Transform( IznosBHD, FormPicL( gPicBHD, 15 ) ) }, "iznos " + AllTrim( valuta_domaca_skraceni_naziv() ) }, ;
      { ValPomocna(),    {|| Transform( IznosDEM, FormPicL( pic_iznos_eur(), 10 ) ) }, "iznos " + AllTrim( ValPomocna() ) }, ;
      { "Opis",          {|| Opis      }, "OPIS" }, ;
      { "K1",            {|| k1      }, "k1" }, ;
      { "K2",            {|| k2      }, "k2" }, ;
      { "K3",            {|| k3iz256( k3 )      }, "k3" }, ;
      { "K4",            {|| k4      }, "k4" } ;
      }

   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   DO WHILE .T.

      Box(, 20, 77 )
      @ box_x_koord() + 19, box_y_koord() + 2 SAY "                         �                        �                   "
      @ box_x_koord() + 20, box_y_koord() + 2 SAY " <c-T>  Brisi stavku     � <ENTER>  Ispravi konto � <a-A> Azuriraj    "
      my_browse( "PPK", 20, 77, {|| EPPK() }, "", "Priprema za prebacivanje stavki", , , , , 2 )
      BoxC()

      IF RECCOUNT2() > 0
         i := KudaDalje( "ZAVRSAVATE SA PRIPREMOM PODATAKA. STA RADITI SA URADJENIM?", ;
            { "AZURIRATI PODATKE", ;
            "IZBRISATI PODATKE", ;
            "VRATIMO SE U PRIPREMU" } )
         DO CASE
         CASE i == 1
            AzurPPK()
            EXIT
         CASE i == 2
            EXIT
         CASE i == 3
            GO TOP
         ENDCASE
      ELSE
         EXIT
      ENDIF
   ENDDO

   my_close_all_dbf()

   RETURN ( NIL )



STATIC FUNCTION EPPK()

   LOCAL nTr2

   IF ( Ch == K_CTRL_T .OR. Ch == K_ENTER ) .AND. reccount2() == 0
      RETURN DE_CONT
   ENDIF

   SELECT temp77

   DO CASE

   CASE Ch == K_CTRL_T

      IF Pitanje( "p01", "Zelite izbrisati ovu stavku ?", "D" ) == "D"
         my_delete()
         RETURN DE_REFRESH
      ENDIF

      RETURN DE_CONT

   CASE Ch == K_ENTER
      Scatter()
      IF !VarEdit( { { "Konto", "_konto2", "P_Konto(@_konto2)",, } }, 9, 5, 17, 74, ;
            'POSTAVLJANJE NOVOG KONTA', ;
            "B1" )
         RETURN DE_CONT
      ELSE
         my_rlock()
         Gather()
         my_unlock()
         RETURN DE_REFRESH
      ENDIF

   CASE Ch == K_ALT_A
      AzurPPK()
      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT







STATIC FUNCTION AzurPPK()

   LOCAL lIndik1 := .F., lIndik2 := .F., nZapisa := 0, nSlog := 0, cStavka := "   "
   LOCAL hParams := hb_Hash()

   SELECT SUBAN
   SET FILTER TO
   GO TOP

   SELECT TEMP77

   Postotak( 1, RECCOUNT2(), "Azuriranje promjena na subanalitici",,, .T. )

   GO TOP

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "fin_suban", "fin_anal", "fin_sint" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   DO WHILE !Eof()

      // azuriraj subanalitiku
      IF ( TEMP77->idkonto != TEMP77->konto2 )
         SELECT SUBAN
         GO TEMP77->NSLOG
         _rec := dbf_get_rec()
         _rec[ "idkonto" ] := temp77->konto2
         update_rec_server_and_dbf( "fin_suban", _rec, 1, "CONT" )
      ENDIF

      IF ( TEMP77->idpartner != TEMP77->part2 )
         SELECT SUBAN
         GO TEMP77->NSLOG
         _rec := dbf_get_rec()
         _rec[ "idpartner" ] := temp77->part2
         update_rec_server_and_dbf( "fin_suban", _rec, 1, "CONT" )
      ENDIF

      // azuriraj analitiku
      IF TEMP77->idkonto != TEMP77->konto2

         SELECT ANAL
         GO TOP
         SEEK TEMP77->( idfirma + idvn + brnal )

         lIndik1 := .F.
         lIndik2 := .F.

         DO WHILE !Eof() .AND. idfirma + idvn + brnal == TEMP77->( idfirma + idvn + brnal )

            IF idkonto == TEMP77->idkonto .AND. !lIndik1

               lIndik1 := .T.

               _rec := dbf_get_rec()

               IF TEMP77->d_p == "1"
                  _rec[ "dugbhd" ] := _rec[ "dugbhd" ] - TEMP77->iznosbhd
                  _rec[ "dugdem" ] := _rec[ "dugdem" ] - TEMP77->iznosdem
               ELSE
                  _rec[ "potbhd" ] := _rec[ "potbhd" ] - TEMP77->iznosbhd
                  _rec[ "potdem" ] := _rec[ "potdem" ] - TEMP77->iznosdem
               ENDIF

               update_rec_server_and_dbf( "fin_anal", _rec, 1, "CONT" )

            ELSEIF idkonto == TEMP77->konto2 .AND. !lIndik2

               lIndik2 := .T.

               _rec := dbf_get_rec()

               IF TEMP77->d_p == "1"
                  _rec[ "dugbhd" ] := _rec[ "dugbhd" ] + TEMP77->iznosbhd
                  _rec[ "dugdem" ] := _rec[ "dugdem" ] + TEMP77->iznosdem
               ELSE
                  _rec[ "potbhd" ] := _rec[ "potbhd" ] + TEMP77->iznosbhd
                  _rec[ "potdem" ] := _rec[ "potdem" ] + TEMP77->iznosdem
               ENDIF

               update_rec_server_and_dbf( "fin_anal", _rec, 1, "CONT" )

            ENDIF

            SKIP 1

         ENDDO

         SKIP -1

         IF !lIndik2

            _rec := dbf_get_rec()

            _rec[ "idkonto" ] := TEMP77->konto2
            _rec[ "rbr" ] := NovaSifra( _rec[ "rbr" ] )

            IF gDatNal == "N"
               _rec[ "datnal" ] := TEMP77->datdok
            ENDIF

            _rec[ "dugbhd" ] := IF( TEMP77->d_p == "1", TEMP77->iznosbhd, 0 )
            _rec[ "potbhd" ] := IF( TEMP77->d_p == "2", TEMP77->iznosbhd, 0 )
            _rec[ "dugdem" ] := IF( TEMP77->d_p == "1", TEMP77->iznosdem, 0 )
            _rec[ "potdem" ] := IF( TEMP77->d_p == "2", TEMP77->iznosdem, 0 )

            APPEND BLANK

            update_rec_server_and_dbf( "fin_anal", _rec, 1, "CONT" )

         ENDIF

      ENDIF

      // azuriraj sintetiku
      IF Left( TEMP77->idkonto, 3 ) != Left( TEMP77->konto2, 3 )

         SELECT SINT
         GO TOP
         SEEK TEMP77->( idfirma + idvn + brnal )

         lIndik1 := .F.
         lIndik2 := .F.

         DO WHILE !Eof() .AND. idfirma + idvn + brnal == TEMP77->( idfirma + idvn + brnal )

            IF idkonto == Left( TEMP77->idkonto, 3 ) .AND. !lIndik1

               lIndik1 := .T.

               _rec := dbf_get_rec()

               IF TEMP77->d_p == "1"
                  _rec[ "dugbhd" ] := _rec[ "dugbhd" ] + TEMP77->iznosbhd
                  _rec[ "dugdem" ] := _rec[ "dugdem" ] + TEMP77->iznosdem
               ELSE
                  _rec[ "potbhd" ] := _rec[ "potbhd" ] + TEMP77->iznosbhd
                  _rec[ "potdem" ] := _rec[ "potdem" ] + TEMP77->iznosdem
               ENDIF

               update_rec_server_and_dbf( "fin_sint", _rec, 1, "CONT" )

            ELSEIF idkonto == Left( TEMP77->konto2, 3 ) .AND. !lIndik2

               lIndik2 := .T.

               _rec := dbf_get_rec()

               IF TEMP77->d_p == "1"
                  _rec[ "dugbhd" ] := _rec[ "dugbhd" ] + TEMP77->iznosbhd
                  _rec[ "dugdem" ] := _rec[ "dugdem" ] + TEMP77->iznosdem
               ELSE
                  _rec[ "potbhd" ] := _rec[ "potbhd" ] + TEMP77->iznosbhd
                  _rec[ "potdem" ] := _rec[ "potdem" ] + TEMP77->iznosdem
               ENDIF

               update_rec_server_and_dbf( "fin_sint", _rec, 1, "CONT" )

            ENDIF

            SKIP 1

         ENDDO

         SKIP -1

         IF !lIndik2

            _rec := dbf_get_rec()

            _rec[ "idkonto" ] := Left( TEMP77->konto2, 3 )
            _rec[ "rbr" ] := NovaSifra( _rec[ "rbr" ] )

            IF gDatNal == "N"
               _rec[ "datnal" ] := TEMP77->datdok
            ENDIF

            _rec[ "dugbhd" ] := IF( TEMP77->d_p == "1", TEMP77->iznosbhd, 0 )
            _rec[ "potbhd" ] := IF( TEMP77->d_p == "2", TEMP77->iznosbhd, 0 )
            _rec[ "dugdem" ] := IF( TEMP77->d_p == "1", TEMP77->iznosdem, 0 )
            _rec[ "potdem" ] := IF( TEMP77->d_p == "2", TEMP77->iznosdem, 0 )

            APPEND BLANK

            update_rec_server_and_dbf( "fin_sint", _rec, 1, "CONT" )

         ENDIF

      ENDIF

      SELECT TEMP77
      SKIP 1

      Postotak( 2, ++nZapisa,,,, .F. )

   ENDDO

   Postotak( - 1,,,,, .F. )

   SELECT TEMP77
   my_dbf_zap()

   SELECT ANAL
   nZapisa := 0

   Postotak( 1, RECCOUNT2(), "Azuriranje promjena na analitici",,, .F. )

   GO TOP

   DO WHILE !Eof()
      IF dugbhd == 0 .AND. potbhd == 0 .AND. dugdem == 0 .AND. potdem == 0
         SKIP 1
         nSlog := RecNo()
         SKIP -1
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "fin_anal", _rec, 1, "CONT" )
         GO nSlog
      ELSE
         SKIP 1
      ENDIF
      Postotak( 2, ++nZapisa,,,, .F. )
   ENDDO

   Postotak( - 1,,,,, .F. )

   SELECT SINT
   nZapisa := 0

   Postotak( 1, RECCOUNT2(), "Azuriranje promjena na sintetici",,, .F. )

   GO TOP

   DO WHILE !Eof()

      IF dugbhd == 0 .AND. potbhd == 0 .AND. dugdem == 0 .AND. potdem == 0
         SKIP 1
         nSlog := RecNo()
         SKIP -1
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "fin_sint", _rec, 1, "CONT" )
         GO nSlog
      ELSE
         SKIP 1
      ENDIF
      Postotak( 2, ++nZapisa,,,, .F. )
   ENDDO

   Postotak( - 1,,,,, .T. )

   hParams[ "unlock" ] := { "fin_suban", "fin_anal", "fin_sint" }
   run_sql_query( "COMMIT", hParams )


   SELECT TEMP77
   USE

   RETURN .T.




STATIC FUNCTION _cre_temp77()

   LOCAL _table := "temp77"
   LOCAL _ret := .T.
   LOCAL _dbf

   IF !File( my_home() + my_dbf_prefix() + _table + ".dbf" )

      _dbf := dbStruct()

      AAdd( _dbf, { "KONTO2", "C", 7, 0 } )
      AAdd( _dbf, { "PART2", "C", 6, 0 } )
      AAdd( _dbf, { "NSLOG", "N", 10, 0 } )

      dbCreate( my_home() + my_dbf_prefix() + _table + ".dbf", _dbf )

   ENDIF

   my_use_temp( "TEMP77", my_home() + my_dbf_prefix() + _table, .F., .T. )

   my_dbf_zap()

   RETURN .T.

*/
