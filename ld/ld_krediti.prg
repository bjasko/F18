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

FUNCTION ld_krediti_menu()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. novi kredit                                  " )
   AAdd( _opcexe, {|| ld_novi_kredit() } )
   AAdd( _opc, "2. pregled/ispravka kredita" )
   AAdd( _opcexe, {|| ld_ispravka_kredita() } )
   AAdd( _opc, "3. lista kredita za jednog kreditora " )
   AAdd( _opcexe, {|| ld_lista_kredita() } )
   AAdd( _opc, "4. brisanje kredita" )
   AAdd( _opcexe, {|| ld_brisanje_kredita() } )
   AAdd( _opc, "5. specifikacija kredita po kreditorima" )
   AAdd( _opcexe, {|| ld_kred_specifikacija() } )

   f18_menu( "kred", .F., _izbor, _opc, _opcexe )

   RETURN .T.




FUNCTION ld_novi_kredit()

   LOCAL lBrojRata := .F.
   LOCAL i
   LOCAL _vals
   LOCAL nOstalo, nTekMj, nTekGodina
   LOCAL cIdRadn  := Space( _LR_ )
   LOCAL nMjesec  := gMjesec
   LOCAL nGodina  := gGodina
   LOCAL cIdKred  := Space( _LK_ )
   LOCAL nIznKred := 0
   LOCAL nRata    := 0
   LOCAL nRata2   := 0
   LOCAL cOsnov   := Space( 20 )
   LOCAL nIRata
   LOCAL hParams

   DO WHILE .T.

      ld_otvori_tabele_kredita()

      Box(, 10, 70 )
      @ m_x + 1, m_y + 2   SAY "Mjesec:" GET nMjesec PICT "99"
      @ m_x + 1, Col() + 2 SAY "Godina:" GET nGodina PICT "9999"
      @ m_x + 2, m_y + 2   SAY "Radnik  :" GET cIdRadn  valid {|| P_Radn( @cIdRadn ), SetPos( m_x + 2, m_y + 20 ), QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), .T. }
      @ m_x + 3, m_y + 2   SAY "Kreditor:" GET cIdKred PICT "@!" VALID P_Kred( @cIdKred, 3, 21 )
      @ m_x + 4, m_y + 2   SAY "Kredit po osnovu:" GET cOsnov PICT "@!"
      @ m_x + 5, m_y + 2   SAY "Ukupan iznos kredita:" GET nIznKred PICT "99" + gPicI

      IF lBrojRata
         @ m_x + 7, m_y + 2 SAY "Broj rata   :" GET nRata2 PICT "9999" VALID nRata2 > 0
      ELSE
         @ m_x + 7, m_y + 2 SAY "Rata kredita:" GET nRata PICT gpici VALID nRata > 0
      ENDIF

      READ

      ESC_BCR
      BoxC()

      IF lBrojRata
         nRata := Round( nIznKred / nRata2, 2 )
         IF nRata * nRata2 - nIznKred < 0
            nRata += 0.01
         ENDIF
      ENDIF

      SELECT radkr
      // "2", idradn + idkred + naosnovu + str(godina) + str(mjesec)
      SET ORDER TO TAG "2"

      SEEK cIdRadn + cIdkred + cOsnov
      PRIVATE nRec := 0

      IF Found()

         IF Pitanje( , "Stavke vec postoje. Zamijeniti novim podacima ?", "D" ) == "N"
            MsgBeep( "Rate nisu formirane! Unesite novu osnovu kredita za zadanog kreditora!" )
            my_close_all_dbf()
            RETURN .F.
         ELSE
            _vals := hb_Hash()
            _vals[ "idradn" ]    := cIdRadn
            _vals[ "idkred" ]    := cIdKred
            _vals[ "naosnovu" ]  := cOsnov
            delete_rec_server_and_dbf( "ld_radkr", _vals, 2, "FULL" )
         ENDIF

      ENDIF


      nOstalo := nIznKred
      nTekMj := nMjesec
      nTekGodina := nGodina

      i := 0
      nTekMj := nMjesec - 1

      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "ld_radkr" }, .T. )
         run_sql_query( "ROLLBACK" )
         RETURN .F.
      ENDIF

      DO WHILE .T.

         IF nTeKMj + 1 > 12
            nTekMj := 1
            ++nTekGodina
         ELSE
            nTekMj++
         ENDIF

         nIRata := nRata

         IF nIRata > 0 .AND. ( nOstalo - nIRata < 0 )
            // rata je pozitivna
            nIRata := nOstalo
         ENDIF

         IF nIRata < 0 .AND. ( nOstalo - nIRata > 0 )
            // rata je negativna
            nIRata := nOstalo
         ENDIF

         IF Round( nIRata, 2 ) <> 0

            APPEND BLANK
            _vals := dbf_get_rec()

            _vals[ "idradn" ]   := cIdRadn
            _vals[ "idkred" ]   := cIdKred
            _vals[ "naosnovu" ] := cOsnov
            _vals[ "mjesec" ]   := nTekMj
            _vals[ "godina" ]   := nTekGodina
            _vals[ "iznos" ]    := nIRata

            update_rec_server_and_dbf( "ld_radkr", _vals, 1, "CONT" )
            ++i

         ENDIF

         nOstalo := nOstalo - nIRata
         IF Round( nOstalo, 2 ) == 0
            EXIT
         ENDIF

      ENDDO

      hParams := hb_Hash()
      hParams[ "unlock" ] := { "ld_radkr" }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER: ld unos novog kredita - radnik: " + cIdRadn + " iznos: " + AllTrim( Str( nIznKred ) ), 2 )

      PRIVATE cDn := "N"

      Box(, 5, 60 )
#ifndef TEST
      SET CONFIRM OFF
#endif
      @ m_x + 1, m_y + 2 SAY "Za radnika " + cIdRadn + " kredit je formiran na " + Str( i, 3 ) + " rata"
      @ m_x + 3, m_y + 2 SAY "Prikazati pregled kamata:" GET cDN PICT "@!"
      READ
      BoxC()

#ifndef TEST
      SET CONFIRM ON
#endif

      my_close_all_dbf()

      IF ( cDn == "D" )
         ld_ispravka_kredita( cIdRadn, cIdKred, cOsnov )
      ENDIF

   ENDDO

   my_close_all_dbf()

   RETURN .T.


FUNCTION ld_ispravka_kredita

   PARAMETERS cIdRadn, cIdKred, cNaOsnovu

   IF PCount() == 0
      cIdRadn := Space( _LR_ )
      cIdKRed := Space( _LK_ )
      cNaOsnovu := Space( 20 )
   ENDIF

   ld_otvori_tabele_kredita()

   SELECT radkr
   SET ORDER TO TAG "2"

   Box(, 19, 77 )
   ImeKol := {}
   AAdd( ImeKol, { "Mjesec", {|| mjesec } } )
   AAdd( ImeKol, { "Godina", {|| godina } } )
   AAdd( ImeKol, { "Iznos", {|| iznos } } )
   AAdd( ImeKol, { "Otplaceno", {|| placeno } } )
   AAdd( ImeKol, { "NaOsnovu", {|| naosnovu } } )
   Kol := {}
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   SET CURSOR ON

   @ m_x + 1, m_y + 2 SAY "KREDIT - pregled, ispravka"
   @ m_x + 2, m_y + 2 SAY "Radnik:   " GET cIdRadn  valid {|| P_Radn( @cIdRadn ), SetPos( m_x + 2, m_y + 20 ), QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), P_Krediti( cIdRadn, @cIdKred, @cNaOsnovu ), .T. }
   @ m_x + 3, m_y + 2 SAY "Kreditor: " GET cIdKred  VALID P_Kred( @cIdKred, 3, 21 ) PICT "@!"
   @ m_x + 4, m_y + 2 SAY "Na osnovu:" GET cNaOsnovu PICT "@!"

   IF PCount() == 0
      READ
      ESC_BCR
   ELSE
      GetList := {}
   ENDIF

   cNaOsnovu := PadR( cNaOsnovu, Len( radkr->naosnovu ) )

   BrowseKey( m_x + 6, m_y + 1, m_x + 19, m_y + 77, ImeKol, {| Ch| ld_krediti_key_handler( Ch ) }, "idradn+idkred+naosnovu=cidradn+cidkred+cnaosnovu", cIdRadn + cIdKred + cNaOsnovu, 2,, )

   BoxC()

   my_close_all_dbf()

   RETURN .T.


FUNCTION ld_krediti_key_handler( Ch )

   LOCAL cDn := "N"
   LOCAL nRet := DE_CONT
   LOCAL nRec := RecNo()
   LOCAL _placeno, _iznos, _rec
   LOCAL hParams

   SELECT radkr

   DO CASE

   CASE Ch == K_ENTER

      _vals := dbf_get_rec()

      _iznos := _vals[ "iznos" ]
      _placeno := _vals[ "placeno" ]

      Box(, 6, 70 )

      @ m_x + 1, m_y + 2 SAY "Rucna prepravka rate !"
      @ m_x + 3, m_y + 2 SAY "Iznos  " GET _iznos PICT gpici
      @ m_x + 4, m_y + 2 SAY "Placeno" GET _placeno PICT gpici

      cNaOsnovu2 := cNaOsnovu

      @ m_x + 6, m_y + 2 SAY "Na osnovu" GET cNaOsnovu2

      READ

      IF ( cNaOsnovu2 <> field->naosnovu ) .AND. Pitanje( , "Zelite li promijeniti osnov kredita ? (D/N)", "N" ) == "D"

         SEEK cIdRadn + cIdKred + cNaOsnovu

         run_sql_query( "BEGIN" )
         IF !f18_lock_tables( { "ld_radkr" }, .T. )
            run_sql_query( "ROLLBACK" )
            RETURN .F.
         ENDIF


         DO WHILE !Eof() .AND. ( field->idradn + field->idkred + field->naosnovu ) == ( cIdRadn + cIdKred + cNaOsnovu )

            SKIP 1
            nRecK := RecNo()
            SKIP -1

            _vals := dbf_get_rec()
            _vals[ "naosnovu" ] := cNaOsnovu2

            update_rec_server_and_dbf( "ld_radkr", _vals, 1, "CONT" )

            GO ( nRecK )

         ENDDO


         hParams := hb_Hash()
         hParams[ "unlock" ] := { "ld_radkr" }
         run_sql_query( "COMMIT", hParams )

      ENDIF

      READ

      BoxC()

      GO ( nRec )

      _vals := dbf_get_rec()
      _vals[ "naosnovu" ] := cNaOsnovu2
      _vals[ "placeno" ] := _placeno
      _vals[ "iznos" ] := _iznos

      update_rec_server_and_dbf( "ld_radkr", _vals, 1, "FULL" )

      log_write( "F18_DOK_OPER: ld korekcija kredita, rucna ispravka rate - radnik: " + cIdRadn + ", iznos: " + AllTrim( Str( radkr->placeno, 12, 2 ) ) + "/" + AllTrim( Str( radkr->iznos, 12, 2 ) ), 2 )

      SELECT radkr

      nRet := DE_REFRESH

   CASE Ch == K_CTRL_N
      nRet := DE_REFRESH
   CASE Ch == K_CTRL_T
      nRet := DE_REFRESH
   CASE Ch == K_CTRL_P
      PushWA()
      // StRjes(radkr->idradn,radkr->idkred,radkr->naosnovu)
      PopWA()
      nRet := DE_REFRESH
   CASE Ch == K_F10
      nRet := DE_REFRESH
   ENDCASE

   RETURN nRet


FUNCTION ld_krediti_redefinisanje_rata()

   LOCAL GetList := {}
   LOCAL nTRata
   LOCAL nNRata
   LOCAL cNaOsnovu := Space( 20 )
   LOCAL _rec
   LOCAL hParams

   Box(, 6, 60 )

   @ m_x + 1, m_y + 2 SAY "*** podaci o kreditu" COLOR F18_COLOR_I

   @ m_x + 3, m_y + 2 SAY "kredit na osnovu" GET cNaOsnovu

   READ

   SELECT radkr
   SET ORDER TO TAG "4"
   SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn + cNaOsnovu

   nTRata := field->iznos
   nNRata := nTRata

   @ m_x + 4, m_y + 2 SAY "tekuæa rata kredita = " + ;
      AllTrim( Str( nTRata ) ) + " KM"
   @ m_x + 5, m_y + 2 SAY "rata kredita za obracun" GET nNRata VALID nNRata <> 0
   READ

   BoxC()

   IF nNRata <> nTRata

      SELECT radkr
      SET ORDER TO TAG "4"
      SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn + cNaOsnovu

      cKreditor := idkred
      cIdRadn := idradn

      SET ORDER TO TAG "2"
      SEEK cIdRadn + cKreditor + cNaOsnovu + Str( _godina, 4 ) + Str( _mjesec, 2 )

      nTotalKr := 0

      run_sql_query( "BEGIN" )
      IF !f18_lock_tables( { "ld_radkr" }, .T. )
         run_sql_query( "ROLLBACK" )
         RETURN .F.
      ENDIF


      DO WHILE !Eof() .AND. cKreditor == idkred ;
            .AND. idradn = _idradn ;
            .AND. naosnovu == cNaOsnovu

         nTotalKr += iznos

         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )

         SKIP
      ENDDO


      nOstalo := nTotalKr
      nTekMj := _mjesec
      nTekGodina := _godina

      i := 0
      nTekMj := nMjesec - 1

      DO WHILE .T.
         IF nTeKMj + 1 > 12
            nTekMj := 1
            ++nTekGodina
         ELSE
            nTekMj++
         ENDIF

         nIRata := nNRata

         IF nIRata > 0 .AND. ( nOstalo - nIRata < 0 )
            // rata je pozitivna
            nIRata := nOstalo
         ENDIF

         IF nIRata < 0 .AND. ( nOstalo - nIRata > 0 )
            // rata je negativna
            nIRata := nOstalo
         ENDIF

         IF Round( nIRata, 2 ) <> 0

            APPEND BLANK
            _rec := dbf_get_rec()
            _rec[ "idradn" ] := cIdRadn
            _rec[ "mjesec" ] := nTekMj
            _rec[ "godina" ] := nTekGodina
            _rec[ "idkred" ] := cKreditor
            _rec[ "iznos" ] := nIRata
            _rec[ "naosnovu" ] := cNaOsnovu

            update_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )

            ++i

         ENDIF

         nOstalo := nOstalo - nIRata

         IF Round( nOstalo, 2 ) == 0
            EXIT
         ENDIF
      ENDDO


      hParams := hb_Hash()
      hParams[ "unlock" ] := { "ld_radkr" }
      run_sql_query( "COMMIT", hParams )


      log_write( "F18_DOK_OPER: ld, redefinisanje kredita za radnika: " + cIdRadn, 2 )

   ENDIF

   RETURN nNRata



FUNCTION SumKredita()

   LOCAL fUsed := .T.
   LOCAL cTRada := " "
   LOCAL hParams

   PushWA()

   SELECT ( F_RADKR )
   IF !Used()
      fUsed := .F.
      O_RADKR
   ENDIF

   IF gVarObracun == "2"
      cTRada := g_tip_rada( _idradn, _idrj )
      IF cTRada $ "A#U#P#S"

         PopWa()
         RETURN 0
      ENDIF
   ENDIF

   SET ORDER TO TAG "1"
   SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn

   nIznos := 0

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "ld_radkr" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF

   DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec == mjesec .AND. idradn == _idradn

      nIznos += field->iznos

      _vals := dbf_get_rec()
      _vals[ "placeno" ] := iznos

      update_rec_server_and_dbf( "ld_radkr", _vals, 1, "CONT" )

      SKIP

   ENDDO

   hParams := hb_Hash()
   hParams[ "unlock" ] := { "ld_radkr" }
   run_sql_query( "COMMIT", hParams )

   IF !fUsed
      SELECT radkr
      USE
   ENDIF

   PopWa()

   RETURN nIznos



FUNCTION Okreditu( _idradn, cIdkred, cNaOsnovu, _mjesec, _godina )

   LOCAL nUkupno, nPlaceno, nNTXORd
   LOCAL fused := .T.

   PushWA()

   SELECT ( F_RADKR )

   IF !Used()
      fUsed := .F.
      O_RADKR
      SET ORDER TO TAG "2"
      // "RADKRi2","idradn+idkred+naosnovu itd..."
   ELSE
      nNTXORD := IndexOrd()
      SET ORDER TO TAG "2"
   ENDIF

   SEEK _idradn + cIdkred + cNaOsnovu

   nUkupno := 0
   nPlaceno := 0

   DO WHILE !Eof() .AND. AllTrim( idradn ) == AllTrim( _idradn ) .AND. AllTrim( idkred ) == AllTrim( cIdKred ) .AND. naosnovu == cNaOsnovu
      nUkupno += iznos

      IF ( mjesec > _mjesec .AND. godina >= _godina )
         SKIP
         LOOP
      ELSE
         nPlaceno += placeno
      ENDIF

      SKIP
   ENDDO

   IF !fUsed
      SELECT radkr
      USE
   ELSE
#ifdef C52
      ordSetFocus( nNTXOrd )
#else
      SET ORDER TO nNTXORd
#endif
   ENDIF

   PopWa()

   RETURN { nUkupno, nPlaceno }




FUNCTION ld_lista_kredita()

   PRIVATE fSvi
   PRIVATE nR := nIzn := nIznP := 0
   PRIVATE nUkIzn := nUkIznP := nUkIRR := 0
   PRIVATE nCol1 := 10
   PRIVATE lRjRadn := .F.
   PRIVATE cIdRj

   O_KRED
   O_RADN

   IF FieldPos( "IDRJ" ) <> 0
      lRjRadn := .T.
      O_LD_RJ
      cIdRj := "  "
   ENDIF

   O_RADKR

   PRIVATE m := "----- " + Replicate( "-", _LR_ ) + " ------------------------------- " + Replicate( "-", 39 )

   cIdKred := Space( _LK_ )

   cNaOsnovu := PadR( ".", 20 )
   cIdRadnaJedinica := Space( 2 )
   cGodina := gGodina; cMjesec := gmjesec
   PRIVATE cRateDN := "D", cAktivni := "D"

   Box(, 13, 60 )
   IF lRjRadn
      @ m_x + 1, m_y + 2 SAY "RJ (prazno=sve): " GET cIdRj  valid {|| Empty( cIdRj ) .OR. P_LD_Rj( @cIdRj ) } PICT "@!"
   ENDIF
   @ m_x + 2, m_y + 2 SAY "Kreditor ('.' svi): " GET cIdKred  valid {|| cidkred = '.' .OR. P_Kred( @cIdKred ) } PICT "@!"
   @ m_x + 3, m_y + 2 SAY "Na osnovu ('.' po svim osnovama):" GET cNaOsnovu PICT "@!"
   @ m_x + 4, m_y + 2 SAY "Prikazati rate kredita D/N/J/R/T:"
   @ m_x + 5, m_y + 2 SAY "D - prikazati sve rate"
   @ m_x + 6, m_y + 2 SAY "N - prikazati samo broj rata i ukupan iznos"
   @ m_x + 7, m_y + 2 SAY "J - samo jedna rata"
   @ m_x + 8, m_y + 2 SAY "R - partija,br.rata,iznos,rata,ostalo"
   @ m_x + 9, m_y + 2 SAY "T - trenutno stanje" GET cRateDN PICT "@!" VALID cRateDN $ "DNJRT"
   @ m_x + 10, m_y + 2 SAY "Prikazi samo aktivne-neotplacene kredite D/N" GET cAktivni PICT "@!" VALID cAktivni $ "DN"
   READ
   ESC_BCR
   IF cRateDN $ "JR"
      @ m_x + 12, m_y + 2 SAY "Prikazati ratu od godina/mjesec:" GET cGodina PICT "9999"
      @ m_x + 12, Col() + 1 SAY "/" GET cMjesec PICT "99"
      READ
      ESC_BCR
   ENDIF
   IF lRjRadn .AND. Empty( cIdRj )
      lRazdvojiPoRj := ( Pitanje(, "Razdvojiti spiskove po radnim jedinicama? (D/N)", "N" ) == "D" )
   ELSE
      lRazdvojiPoRj := .F.
   ENDIF
   BoxC()

   IF Trim( cNaOsnovu ) == "."
      cNaOsnovu := ""
   ENDIF

   SELECT radkr

   IF lRazdvojiPoRj

      SET RELATION TO idradn into radn

      Box(, 2, 30 )
      nSlog := 0
      cSort1 := "radn->idRj+idKred+naOsnovu+idRadn"
      cFilt := ".t."
      IF !cIdKred = "."
         cFilt += ".and. idKred==" + _filter_quote( cIdKred )
      ENDIF
      INDEX ON &cSort1 TO "TMPRK" FOR &cFilt
      BoxC()

      GO TOP

   ELSE
      IF lRjRadn .AND. !Empty( cIdRj )
         SET RELATION TO idradn into radn
         SET FILTER TO radn->idRj == cIdRj
      ENDIF
      SET ORDER TO TAG "3"
      SEEK cIdKred + cNaOsnovu
   ENDIF

   nRbr := 0

   IF cRateDN == "R"
      m += REPL( "-", 16 )
   ENDIF

   IF cidkred = '.'
      fSvi := .T.
      GO TOP
   ELSE
      IF !lRazdvojiPoRj .AND. !Found()
         MsgBeep( "Nema podataka!" )
         CLOSERET
      ENDIF
      fSvi := .F.
   ENDIF

   START PRINT CRET

   ld_lista_kredita_zaglavlje()

   DO WHILE !Eof()

      IF lRazdvojiPoRj
         cIdTekRj := radn->idRj
         ?
         ? "RJ:", radn->idRj, "-", Ocitaj( F_LD_RJ, cIdTekRj, "naz" )
         ?
      ENDIF

      cIdKred := IdKred

      SELECT kred
      HSEEK cIdKred

      SELECT radkr

      IF fsvi
         ?
         ? StrTran( m, "-", "*" )
         ? gTS + ":", cIdKred, kred->naz
         ? StrTran( m, "-", "*" )
      ENDIF
      cOsn := ""
      nCol1 := 20

      DO WHILE !Eof() .AND. idkred = cIdKred .AND. naosnovu = cNaOsnovu .AND. if( lRazdvojiPoRj, radn->idRj == cIdTekRj, .T. )

         PRIVATE cOsn := naosnovu
         cIdRadn := idradn
         nIzn := nIznP := 0

         IF cAktivni == "D"
            nTekRec := RecNo()
            RKgod := RADKR->Godina
            RKmjes := RADKR->Mjesec
            DO WHILE !Eof() .AND. idkred = cidkred .AND. cosn == naosnovu .AND. idradn == cidradn
               nIzn += RADKR->Iznos
               nIznP += RADKR->Placeno
               RKgod := RADKR->Godina
               RKmjes := RADKR->Mjesec
               SKIP 1
            ENDDO
            IF nIzn > nIznP .OR. ( nIzn == nIznP .AND. RKgod == cGodina .AND. RKmjes >= cMjesec )
               GO nTekRec
            ELSE
               LOOP
            ENDIF
         ENDIF

         IF cNaOsnovu == "" .AND. cOsn <> naosnovu
            ?
            ? m
            ? "KREDIT PO OSNOVI:", naosnovu
            ? m
         ENDIF

         SELECT radn
         HSEEK cidradn
         SELECT radkr

         ?
         ? Str( ++nRbr, 4 ) + ".", cIdRadn, RADNIK_PREZ_IME

         IF cRateDN == "D"
            ?? " Osnov:", cOsn, Replicate( "_", 11 )
         ENDIF

         nR := nIzn := nIznP := 0
         nCol1 := 64
         nIRR := 0

         DO WHILE !Eof() .AND. idkred = cidkred .AND. cosn == naosnovu .AND. idradn == cidradn
            nKoef := 1

            IF cRateDN <> "J" .OR. ( godina == cGodina .AND. mjesec == cMjesec )
               ++nR
               nIzn += iznos * nKoef
               nIznP += placeno
               IF iznos * nKoef == 0 .AND. cRateDN == "R"
                  --nR
               ENDIF  // mozda i za sve var. ?!
               IF cMjesec == mjesec .AND. cGodina == godina
                  nIRR := iznos * nKoef
               ENDIF
            ENDIF

            IF cRateDN == "D"
               ? Space( 47 ), Str( mjesec ) + "/" + Str( godina )
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY iznos * nKoef PICT gpici
            ELSEIF cRateDN == "J"
               IF godina == cGodina .AND. mjesec == cMjesec
                  ?? "", Str( mjesec ) + "/" + Str( godina )
                  nCol1 := PCol() + 1
                  @ PRow(), PCol() + 1 SAY iznos * nKoef PICT gpici
                  @ PRow(), PCol() + 1 SAY "___________"
               ENDIF
            ENDIF
            SKIP 1
         ENDDO

         IF cRateDN == "N"
            @ PRow(), PCol() + 1 SAY nR PICT "9999"
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nIzn PICT gpici
            @ PRow(), PCol() + 1 SAY "___________"
         ENDIF

         IF cRateDN == "T"
            @ PRow(), PCol() + 1 SAY ""
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nIzn PICT gpici
            @ PRow(), PCol() + 1 SAY nIznP PICT gpici
            @ PRow(), PCol() + 1 SAY nIzn - nIznP PICT gpici
         ENDIF

         IF cRateDN == "R"
            @ PRow(), PCol() + 1 SAY cOsn
            @ PRow(), PCol() + 1 SAY nR PICT "9999"
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nIzn PICT gpici
            @ PRow(), PCol() + 1 SAY nIRR PICT gpici
            @ PRow(), PCol() + 1 SAY nIzn - nIznP PICT gpici
         ENDIF

         nUkIzn += nIzn
         nUkIznP += nIznP
         nUkIRR += nIRR
      ENDDO

      ? m
      ? "UKUPNO:"

      @ PRow(), nCol1 SAY nUkIzn PICT gpici

      IF cRatedn == "T"
         @ PRow(), PCol() + 1 SAY nUkIznP  PICT gpici
         @ PRow(), PCol() + 1 SAY nUkizn - nUkIznP  PICT gpici
      ENDIF

      IF cRatedn == "R"
         @ PRow(), PCol() + 1 SAY nUkIRR          PICT gpici
         @ PRow(), PCol() + 1 SAY nUkizn - nUkIznP  PICT gpici
      ENDIF

      ? m

      IF !fsvi .AND. !lRazdvojiPoRj
         EXIT
      ENDIF

   ENDDO

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN



FUNCTION ld_lista_kredita_zaglavlje()

   ?
   P_10CPI

   IF cRateDN == "R"
      ?? "LD, izvjestaj na dan:", Date()
      ? "FIRMA   :", gNFirma
      ?
      IF !fsvi
         ? "Kreditor:", cidkred, kred->naz
      ENDIF
      ? "Ziro-r. :", kred->ziro
      ?
      ? PadC( "DOJAVA KREDITA ZA MJESEC : " + Str( cMjesec ) + ". GODINE: " + Str( cGodina ) + ".", 78 )
   ELSE
      ? "LD: SPISAK KREDITA, izvjestaj na dan:", Date()
      IF !fsvi
         ? "Kreditor:", cidkred, kred->naz
      ENDIF
      IF !( cNaOsnovu == "" )
         ?? "   na osnovu:", cnaosnovu
      ENDIF
   ENDIF

   IF lRjRadn .AND. !Empty( cIdRj )
      ? "RJ:", cIdRj, "-", Ocitaj( F_LD_RJ, cIdRj, "naz" )
   ENDIF

   IF cRateDN == "R"
      P_COND
   ELSE
      P_12CPI
   ENDIF

   ?
   ? m
   IF cRateDN == "N"
      ? " Rbr *" + PadC( "Sifra ", _LR_ ) + "*    Radnik                         Br.Rata    Iznos      Potpis"
   ELSEIF cRateDN == "T"
      ? " Rbr *" + PadC( "Sifra ", _LR_ ) + "*    Radnik                           Ukupno       Placeno       Ostalo"
   ELSEIF cRateDN == "R"
      ? " Red.*" + PadC( " ", _LR_ ) + "*                                  Partija kr.   Broj     Iznos                   Ostatak"
      ? " br. *" + PadC( "Sifra ", _LR_ ) + "*    Radnik                        (na osnovu)   rata     kredita      Rata         duga "
   ELSE
      ? " Rbr *" + PadC( "Sifra ", _LR_ ) + "*    Radnik                        Mjesec/godina/Rata"
   ENDIF
   ? m

   RETURN





FUNCTION P_Krediti

   PARAMETERS cIdRadn, cIdkred, cNaOsnovu

   LOCAL i
   PRIVATE ImeKol

   PushWA()

   SELECT radkr
   SET ORDER TO TAG "2"
   SET scope to ( cIdRadn )

   SEEK cIdRadn

   PRIVATE Imekol := {}
   AAdd( ImeKol, { "Kreditor",      {|| IdKred   } } )
   AAdd( ImeKol, { "Osnov",         {|| NaOsnovu } } )
   AAdd( ImeKol, { "Mjesec",        {|| mjesec   } } )
   AAdd( ImeKol, { "Godina",        {|| godina   } } )
   AAdd( ImeKol, { "Iznos",         {|| Iznos    } } )

   Kol := {}

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   Box(, 18, 60 )
   my_db_edit( "PKred", 18, 60, {|| ld_lista_kredita_key_handler() }, "Postojece stavke za " + cidradn, "", , , , )
   Boxc()

   SET scope TO

   PopwA()

   RETURN




FUNCTION ld_lista_kredita_key_handler()

   IF Ch == K_ENTER
      cIdKred := radkr->idkred
      cNaOsnovu := radkr->naosnovu
      RETURN DE_ABORT
   ENDIF

   RETURN DE_CONT




/* GodMjesec(nGodina,nMjesec,nPomak)
 *     eg. GodMjesec(2002,4,-6) -> {2001,10}
 *   param: nGodina
 *   param: nMjesec
 *   param: nPomak
 */

FUNCTION GodMjesec( nGodina, nMjesec, nPomak )

   LOCAL nPGodina
   LOCAL nPMjesec
   LOCAL nVgodina := 0

   IF nPomak < 0  // vrati se unazad
      nPomak := Abs( nPomak )
      nVGodina := Int( nPomak / 12 )
      nPomak := nPomak % 12
      IF nMjesec - nPomak < 1
         nPGodina := nGodina - 1
         nPMjesec := 12 + nMjesec - nPomak
      ELSE
         nPGodina := nGodina
         nPMjesec := nMjesec - nPomak
      ENDIF
      nPGodina := nPGodina - nVGodina
   ELSE
      nVGodina := Int( nPomak / 12 )
      nPomak := nPomak % 12
      IF nMjesec + nPomak > 12
         nPGodina := nGodina + 1
         nPMjesec := nMjesec + nPomak - 12
      ELSE
         nPGodina := nGodina
         nPMjesec := nMjesec + nPomak
      ENDIF
      nPGodina := nPGodina + nVGodina
   ENDIF

   RETURN { nPGodina, nPMjesec }





FUNCTION DatADD( dDat, nMjeseci, nGodina )

   LOCAL aRez
   LOCAL cPom := ""

   aRez := GodMjesec( Year( dDat ), Month( dDat ), nMjeseci + 12 * nGodina )
   cPom := Str( aRez[ 1 ], 4 )
   cPom += PadL( AllTrim( Str( aRez[ 2 ], 2 ) ), 2, "0" )
   cPom += PadL( AllTrim( Str( Day( dDat ), 2 ) ), 2, "0" )

   RETURN SToD( cPom )




/* DatRazmak(dDatDo,dDatOd,nMjeseci,nDana)
 *     Datumski razmak izrazen u: mjeseci, dana. Poziv: DatRazmak("15.07.2002","05.06.2001",@nMjeseci,@nDana)
 *   param:
 *   param:
 *   param:
 *   param:
 */
FUNCTION DatRazmak( dDatDo, dDatOd, nMjeseci, nDana )

   LOCAL aRez
   LOCAL cPom := ""
   LOCAL lZadnjiDan := .F.

   nMjeseci := 0
   nDana := 0
   dNextMj := dDatOd
   i := 0

   IF Day( dDatOd ) = LastDayOM( dDatOd )
      lZadnjiDan := .T.
   ENDIF

   IF Month( dDatDo ) == Month( dDatOd ) .AND. Day( dDatDo ) = Day( dDatOd )
      // isti mjesec, isti dan
      nMjeseci := ( Year( dDatDo ) -Year( dDatOd ) ) * 12
      nDana := 0
      RETURN
   ENDIF

   DO WHILE .T.
      // predvidjen je razmak do 36 mjeseci
      IF Month( dNextMj ) = Month( dDatDO ) .AND. Year( dNextMj ) = Year( dDatDo )
         // uletili smo u isti mjesec
         nDana := Day( dDatDo ) -Day( dNextMj )
         IF nDana < 0  // moramo se vratiti mjesec unazad
            dNextMj := AddMonth( dNextMj, -1 )
            --nMjeseci
            IF nMjeseci = 0  // samo dva krnjava mjeseca
               nDana := ( Day( EoM( dDatOd ) ) -Day( dDatOd ) + 1 ) + Day( dDatDo ) -1
            ELSE
               nDana := ( Day( EoM( dNextMj ) ) -Day( dDatOd ) + 1 ) + Day( dDatDo ) -1
            ENDIF
         ELSEIF nDana >= 0
            // not implemented
         ENDIF
         EXIT
      ENDIF

      dNextMj := AddMonth( dNextMj, 1 )

      IF lZadnjiDan  // zadnji dan u mjesecu
         dNextMj := EoM( dNextMj )
      ENDIF

      nMjeseci++
      ++i
      IF i > 200
         MsgBeep( "jel to neko lud ovdje ?" )
         EXIT
      ENDIF
   ENDDO

   RETURN



FUNCTION DanaUmjesecu( dDatum )

   LOCAL nDatZM

   nDatZM := EoM( dDatum )

   RETURN Day( nDatZM )



/* DatZadUMjesecu(dDatum)
 *     Vraca datum zadnjed u mjesecu
 *   param: dDatum
 */

FUNCTION DatZadUMjesecu( dDatum )

   LOCAL nDana
   LOCAL dPoc

   dPoc := dDatum
   nDana := Day( dDatum )
   DO WHILE .T.
      dDatum++
      IF Month( dPoc ) = Month( dDatum )
         nDana := Day( dDatum )
      ELSE
         EXIT  // uletio sam usljedeci mjesec
      ENDIF
   ENDDO

   RETURN dDatum - 1


FUNCTION ld_brisanje_kredita()

   LOCAL _rec
   LOCAL hParams

   cIdRadn := Space( _LR_ )
   cIdKRed := Space( _LK_ )
   cNaOsnovu := Space( 20 )
   cBrisi := "N"

   ld_otvori_tabele_kredita()

   SET ORDER TO TAG "2"

   Box( "#BRISANJE NEOTPLACENIH RATA KREDITA", 9, 77 )
   @ m_x + 2, m_y + 2 SAY "Radnik:   " GET cIdRadn  valid {|| P_Radn( @cIdRadn ), SetPos( m_x + 2, m_y + 20 ), QQOut( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + radn->ime ), P_Krediti( cIdRadn, @cIdKred, @cNaOsnovu ), .T. }
   @ m_x + 3, m_y + 2 SAY "Kreditor: " GET cIdKred  VALID P_Kred( @cIdKred, 3, 21 ) PICT "@!"
   @ m_x + 4, m_y + 2 SAY "Na osnovu:" GET cNaOsnovu PICT "@!"
   @ m_x + 6, m_y + 2, m_x + 8, m_y + 76 BOX "         " COLOR "GR+/R"
   @ m_x + 7, m_y + 8 SAY "Jeste li 100% sigurni da zelite izbrisati ovaj kredit ? (D/N)" COLOR "GR+/R"
   @ Row(), Col() + 1 GET cBrisi VALID cBrisi $ "DN" PICT "@!" COLOR "N/W"
   READ
   ESC_BCR
   BoxC()

   IF cBrisi == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   SELECT RADKR
   SET ORDER TO TAG "2"
   SEEK cIdRadn + cIdKred + cNaOsnovu

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "ld_radkr" }, .T. )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF


   nStavki := 0
   DO WHILE !Eof() .AND. idradn + idkred + naosnovu == cIdRadn + cIdKred + cNaOsnovu
      SKIP 1
      nRec := RecNo()
      SKIP -1
      IF placeno = 0
         ++nStavki
         _rec := dbf_get_rec()
         delete_rec_server_and_dbf( "ld_radkr", _rec, 1, "CONT" )
      ENDIF
      GO ( nRec )
   ENDDO


   hParams := hb_Hash()
   hParams[ "unlock" ] := { "ld_radkr" }
   run_sql_query( "COMMIT", hParams )


   IF nStavki > 0
      MsgBeep( "Sve neotplacene rate (ukupno " + AllTrim( Str( nStavki ) ) + ") kredita izbrisane!" )
   ELSE
      MsgBeep( "Nista nije izbrisano. Za izabrani kredit ne postoje neotplacene rate!" )
   ENDIF

   my_close_all_dbf()

   RETURN



FUNCTION ld_otvori_tabele_kredita()

   O_LD_RJ
   O_KRED
   O_STRSPR
   O_OPS
   O_RADN
   O_RADKR

   RETURN
