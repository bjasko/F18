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

FIELD fcj, kolicina, mcsapp, TBankTr, pu_i, pkonto, rbr


FUNCTION kalk_prod_generacija_dokumenata()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. početno stanje prodavnica                               " )
   AAdd( _opcexe, {|| kalk_prod_pocetno_stanje() } )
   // TODO: izbaciti
   // AADD(_opc, "2. pocetno stanje (stara opcija/legacy)")
   // AADD(_opcexe, {|| PocStProd() } )
   AAdd( _opc, "2. inventura prodavnica" )
   AAdd( _opcexe, {|| kalk_prod_gen_ip() } )

   AAdd( _opc, "3. svedi mpc na mpc iz šifarnika dokumentom nivelacije" )
   AAdd( _opcexe, {|| kalk_prod_kartica_mpc_svedi_mpc_sif() } )


   // AAdd( _opc, "4. nivelacije" )
   // AAdd( _opcexe, {|| MnuPNivel() } )

   // AAdd( _opc, "5. setuj mpc po uzoru na postojecu za % " )
   // AAdd( _opcexe, {|| set_mpc_2() } )

   f18_menu( "gdpr", nil, _izbor, _opc, _opcexe )

   RETURN .T.



STATIC FUNCTION MnuPNivel()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

/*
   AAdd( _opc, "1. nivelacija prema zadatnom %                  " )
   AAdd( _opcexe, {|| NivPoProc() } )
*/

/*
   AAdd( _opc, "2. vrati na cijene prije posljednje nivelacije" )
   AAdd( _opcexe, {|| VratiZadNiv() } )
*/

   // AAdd( _opc, "---------------------------------------------" )
   // AAdd( _opcexe, {|| nil } )

/*
   AAdd( _opc, "3. generacija nivelacije za sve prodavnice" )
   AAdd( _opcexe, {|| get_nivel_p() } )
*/

/*
   AAdd( _opc, "4. pregled promjene cijena (roba->zanivel)" )
   AAdd( _opcexe, {|| rpt_zanivel() } )
*/

   // AAdd( _opc, "5. pregled efekata nivelacije za sve prodavnice" )
   // AAdd( _opcexe, {|| result_nivel_p() } )
   // AAdd( _opc, "6. azuriranje nivelacije za sve prodavnice" )
   // AAdd( _opcexe, {|| obr_nivel_p() } )
   // AAdd( _opc, "7. setovanje mpc nakon obradjenih nivelacija" )
   // AAdd( _opcexe, {|| set_mpc_iz_zanivel() } )
   // AAdd( _opc, "8. kopiranje podataka n.cijena 2 -> n.cijena 1" )
   // AAdd( _opcexe, {|| zaniv2_zaniv() } )
   // AAdd( _opc, "9. stampa obrazaca o prom.cijena za sve prod." )
   // AAdd( _opcexe, {|| o_pr_cijena() } )
   AAdd( _opc, "---------------------------------------------" )
   AAdd( _opcexe, {|| nil } )


   f18_menu( "pmn", nil, _izbor, _opc, _opcexe  )

   RETURN .T.



STATIC FUNCTION kalk_prod_gen_ip()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. dokument inventura prodavnica               " )
   AAdd( _opcexe, {|| kalk_generisi_ip() } )
   AAdd( _opc, "2. inventura-razlika prema postojecoj IP " )
   AAdd( _opcexe, {|| gen_ip_razlika() } )
   AAdd( _opc, "3. na osnovu IP generisi 80-ku " )
   AAdd( _opcexe, {|| gen_ip_80() } )

   f18_menu( "pmi", nil, _izbor, _opc, _opcexe )

   RETURN .T.




FUNCTION kalk_generisi_niv_prodavnica_na_osnovu_druge_niv()

   o_konto()
   o_tarifa()
   o_sifk()
   o_sifv()
   o_roba()

   Box(, 4, 70 )

   cIdFirma := self_organizacija_id()
   cIdVD := "19"
   cOldDok := Space( 8 )
   cIdkonto := PadR( "1330", 7 )
   dDatDok := Date()

   @ form_x_koord() + 1, m_Y + 2 SAY "Prodavnica:" GET  cidkonto VALID P_Konto( @cidkonto )
   @ form_x_koord() + 2, m_Y + 2 SAY "Datum     :  " GET  dDatDok
   @ form_x_koord() + 4, form_y_koord() + 2 SAY "Dokument na osnovu koga se vrsi inventura:" GET cIdFirma
   @ form_x_koord() + 4, Col() + 2 SAY "-" GET cIdVD
   @ form_x_koord() + 4, Col() + 2 SAY "-" GET cOldDok

   READ
   ESC_BCR

   BoxC()

   o_koncij()
   o_kalk_pripr()
   // o_kalk()
   PRIVATE cBrDok := kalk_get_next_broj_v5( cIdFirma, "19", NIL )

   nRbr := 0
   SET ORDER TO TAG "1"
   // "KALKi1","idFirma+IdVD+BrDok+RBr","KALK")

   SELECT koncij; SEEK Trim( cidkonto )


   find_kalk_by_broj_dokumenta( cIdfirma, cIdvd, cOlddok, "KALK_1", F_KALK + 300 )

   DO WHILE !Eof() .AND. cidfirma + cidvd + colddok == idfirma + idvd + brdok


      cIdRoba := Idroba
      nUlaz := nIzlaz := 0
      nMPVU := nMPVI := nNVU := nNVI := 0
      nRabat := 0
      SELECT roba
      HSEEK cIdRoba

      // SELECT kalk

      // SET ORDER TO TAG "4"
      // "KALKi4","idFirma+Pkonto+idroba+dtos(datdok)+PU_I+IdVD","KALK")
      // ?? drugi alias trebamo ?? SEEK cidfirma + cidkonto + cIdRoba
      find_kalk_by_pkonto_idroba(  cidfirma, cidkonto, cIdRoba )
      DO WHILE !Eof() .AND. cidfirma + cidkonto + cIdRoba == idFirma + pkonto + idroba

         IF ddatdok < datdok  // preskoci
            skip; LOOP
         ENDIF

         IF roba->tip $ "UT"
            skip; LOOP
         ENDIF

         IF pu_i == "1"
            nUlaz += kolicina - GKolicina - GKolicin2
            nMPVU += mpcsapp * kolicina
            nNVU += nc * kolicina

         ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
            nIzlaz += kolicina
            nMPVI += mpcsapp * kolicina
            nNVI += nc * kolicina

         ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
            nUlaz -= kolicina
            nMPVU -= mpcsapp * kolicina
            nnvu -= nc * kolicina

         ELSEIF pu_i == "3"    // nivelacija
            nMPVU += mpcsapp * kolicina

         ELSEIF pu_i == "I"
            nIzlaz += gkolicin2
            nMPVI += mpcsapp * gkolicin2
            nNVI += nc * gkolicin2
         ENDIF

         SKIP
      ENDDO // po orderu 4

      SELECT KALK_1

      SELECT roba
      HSEEK cIdroba

      SELECT kalk_pripr
      scatter()
      APPEND ncnl
      _idfirma := cidfirma; _idkonto := cidkonto; _pkonto := cidkonto; _pu_i := "3"
      _idroba := cIdRoba; _idtarifa := kalk->idtarifa
      _idvd := "19"; _brdok := cbrdok
      _rbr := RedniBroj( ++nrbr )
      _kolicina := nUlaz - nIzlaz
      _datdok := _DatFaktP := ddatdok
      _fcj := kalk->fcj
      _mpc := kalk->mpc
      _mpcsapp := kalk->mpcsapp
      IF ( _kolicina > 0 .AND.  Round( ( nmpvu - nmpvi ) / _kolicina, 4 ) == Round( _fcj, 4 ) ) .OR. ;
            ( Round( _kolicina, 4 ) == 0 .AND. Round( nMpvu - nMpvi, 4 ) == 0 )
         _ERROR := "0"
      ELSE
         _ERROR := "1"
      ENDIF

      my_rlock()
      Gather2()
      my_unlock()

      SELECT kalk_1

      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN .T.


/*

 Generisanje dokumenta tipa 19 tj. nivelacije na osnovu zadanog %

FUNCTION NivPoProc()

   LOCAL nStopa := 0.0
   LOCAL nZaokr := 1

   o_konto()
   o_tarifa()
   o_sifk()
   o_sifv()
   o_roba()

   cVarijanta := "2"

   Box(, 7, 60 )
   cIdFirma := self_organizacija_id()
   cIdkonto := PadR( "1320", 7 )
   dDatDok := Date()
   @ form_x_koord() + 1, m_Y + 2 SAY "Prodavnica :" GET  cidkonto VALID P_Konto( @cidkonto )
   @ form_x_koord() + 2, m_Y + 2 SAY "Datum      :" GET  dDatDok
   @ form_x_koord() + 3, m_Y + 2 SAY "Cijenu zaokruziti na (br.decimalnih mjesta) :" GET nZaokr PICT "9"
   @ form_x_koord() + 4, m_Y + 2 SAY "(1) Popust prema stopama iz polja ROBA->N1"
   @ form_x_koord() + 5, m_Y + 2 SAY "(2) popust prema stopama iz polja ROBA->N2"
   @ form_x_koord() + 6, m_Y + 2 SAY "(3) popust prema jedinstvenoj stopi      ?"  GET cVarijanta VALID cVarijanta $ "123"

   READ
   ESC_BCR

   IF cVarijanta == "3"
      @ form_x_koord() + 7, m_Y + 2 SAY "Stopa promjene cijena (- za smanjenje)      :" GET nStopa PICT "999.99%"
      READ
      ESC_BCR
   ENDIF

   BoxC()

   o_koncij()
   o_kalk_pripr()
   -- o_kalk()
   --PRIVATE cBrDok := kalk_sljedeci_broj( cidfirma, "19", 8 )

   nRbr := 0
   SET ORDER TO TAG "4"

   MsgO( "Generacija dokumenta 19 - " + cbrdok )

   SELECT koncij
   SEEK Trim( cidkonto )
   SELECT kalk
   HSEEK cidfirma + cidkonto

   DO WHILE !Eof() .AND. cIdFirma + cIdKonto == idFirma + pKonto

      cIdRoba := idRoba
      nUlaz := nIzlaz := 0
      nMPVU := nMPVI := nNVU := nNVI := 0
      nRabat := 0
      SELECT roba
      HSEEK cIdRoba
      SELECT kalk

      DO WHILE !Eof() .AND. cIdFirma + cIdKonto + cIdRoba == idFirma + pKonto + idRoba

         IF dDatDok < datDok  // preskoci
            SKIP
            LOOP
         ENDIF
         IF roba->tip $ "UT"
            SKIP
            LOOP
         ENDIF

         IF pu_i == "1"
            nUlaz += kolicina - gKolicina - gKolicin2
            nMPVU += mpcSaPp * kolicina
            nNVU += nc * kolicina

         ELSEIF pu_i == "5"  .AND. !( idVd $ "12#13#22" )
            nIzlaz += kolicina
            nMPVI += mpcSaPp * kolicina
            nNVI += nc * kolicina

         ELSEIF pu_i == "5"  .AND. ( idVd $ "12#13#22" )    // povrat
            nUlaz -= kolicina
            nMPVU -= mpcSaPp * kolicina
            nNVU -= nc * kolicina

         ELSEIF pu_i == "3"    // nivelacija
            nMPVU += mpcSaPp * kolicina

         ELSEIF pu_i == "I"
            nIzlaz += gKolicin2
            nMPVI += mpcSaPp * gKolicin2
            nNVI += nc * gKolicin2
         ENDIF

         SKIP
      ENDDO

      SELECT roba
      HSEEK cIdRoba

      SELECT kalk

      IF ( cVarijanta = "1" .AND. roba->n1 = 0 )
         // skip
         LOOP
      ENDIF

      IF ( cVarijanta = "2" .AND. roba->n2 = 0 )
         // skip
         LOOP
      ENDIF


      IF ( Round( nUlaz - nIzlaz, 4 ) <> 0 ) .OR. ( Round( nMpvU - nMpvI, 4 ) <> 0 )
         PushWA()
         SELECT kalk_pripr
         scatter()
         APPEND ncnl
         _idfirma := cIdFirma
         _pkonto := _idKonto := cIdKonto
         _mkonto := ""
         _mu_i := ""
         _pu_i := "3"
         _idroba := cIdRoba
         _idtarifa := roba->idtarifa
         _idvd := "19"
         _brdok := cBrDok
         _rbr := RedniBroj( ++nRbr )
         _kolicina := nUlaz - nIzlaz
         _datdok := _DatFaktP := dDatDok
         _error := "0"
         _fcj := kalk_get_mpc_by_koncij_pravilo()

         IF cVarijanta == "1"  // roba->n1
            _mpcsapp := Round( -_fcj * roba->N1 / 100, nZaokr )
         ELSEIF cVarijanta == "2"
            _mpcsapp := Round( -_fcj * roba->N2 / 100, nZaokr )
         ELSE
            _mpcsapp := Round( _fcj * nStopa / 100, nZaokr )
         ENDIF

         PRIVATE aPorezi := {}
         --PRIVATE fNovi := .T.
         --VRoba( .F. )
         // P_Tarifa(@_idTarifa)
         SELECT kalk_pripr
         my_rlock()
         Gather2()
         my_unlock()
         SELECT kalk
         PopWA()
      ENDIF

   ENDDO

   MsgC()
   my_close_all_dbf()

   RETURN .F.

*/


/*
  Generise novu 19-ku tj.nivelaciju na osnovu vec azurirane

FUNCTION VratiZadNiv()

   LOCAL nSlog := 0, nPom := 0, cStBrDok := ""

   o_konto()
   o_tarifa()
   o_sifk()
   o_sifv()
   o_roba()

   Box(, 4, 60 )
   cIdFirma := self_organizacija_id()
   cIdKonto := PadR( "1320", 7 )
   dDatDok := Date()
   @ form_x_koord() + 1, m_Y + 2 SAY "Prodavnica :" GET  cIdKonto VALID P_Konto( @cIdKonto )
   @ form_x_koord() + 2, m_Y + 2 SAY "Datum      :" GET  dDatDok
   READ
   ESC_BCR

   BoxC()

   o_kalk_doks()
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + "20"
   SKIP -1

   DO WHILE ( !Bof() .AND. idvd == "19" )
      IF ( pkonto == cIdKonto .AND. datdok <= dDatDok )
         EXIT
      ENDIF
      SKIP -1
   ENDDO

   IF ( idvd != "19" .OR. pkonto != cIdKonto )
      Msg( "Ne postoji nivelacija za zadanu prodavnicu u periodu do unesenog datuma!", 6 )
      CLOSERET
   ELSE
      cStBrDok := kalk_doks->brdok
      Box(, 4, 60 )
      @ form_x_koord() + 1, form_y_koord() + 2 SAY "Nivel. broj " + cIdFirma + " - 19 -" GET cStBrDok
      READ
      ESC_BCR
      BoxC()
   ENDIF

   o_kalk_pripr()
   -- o_kalk()
   --PRIVATE cBrDok := kalk_sljedeci_broj( cIdFirma, "19", 8 )

   nRbr := 0
   SELECT KALK
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + "19" + cStBrDok

   MsgO( "Generacija dokumenta 19 - " + cBrDok )
   DO WHILE !Eof() .AND. idvd == "19" .AND. brdok == cStBrDok
      SELECT ROBA; HSEEK KALK->idroba
      SELECT KALK; nSlog := RecNo()
      // nPom := StanjeProd( cIdFirma+cIdKonto+KALK->idroba , ddatdok )
      SET ORDER TO TAG "1"
      GO nSlog
      Scatter()
      SELECT kalk_pripr; APPEND NCNL

      _idkonto := cidkonto; _pkonto := cidkonto; _pu_i := _mu_i := ""
      _idtarifa := roba->idtarifa
      _idvd := "19"; _brdok := cbrdok
      _rbr := RedniBroj( ++nrbr )
      _kolicina := nPom
      _datdok := _DatFaktP := ddatdok
      _ERROR := ""
      _fcj := _fcj + _mpcsapp
      _mpcsapp := -_mpcsapp

      Gather2()
      SELECT KALK
      SKIP 1
   ENDDO
   MsgC()

   my_close_all_dbf()

   RETURN


*/



FUNCTION kalk_prod_kartica_mpc_svedi_mpc_sif()

   LOCAL dDok := Date()
   LOCAL nPom := 0
   PRIVATE cIdKontoProdavnica := fetch_metric( "kalk_sredi_karicu_mpc", my_user(), PadR( "1330", 7 ) )

   o_konto()

   cSravnitiD := "D"

   PRIVATE cUvijekSif := "D"

   Box(, 6, 50 )
   @ form_x_koord() + 1, form_y_koord() + 2 SAY "Konto prodavnice: " GET cIdKontoProdavnica PICT "@!" VALID P_konto( @cIdKontoProdavnica )
   @ form_x_koord() + 2, form_y_koord() + 2 SAY "Sravniti do odredjenog datuma:" GET cSravnitiD VALID cSravnitiD $ "DN" PICT "@!"
   @ form_x_koord() + 4, form_y_koord() + 2 SAY "Uvijek nivelisati na MPC iz sifrarnika:" GET cUvijekSif VALID cUvijekSif $ "DN" PICT "@!"
   READ
   ESC_BCR
   @ form_x_koord() + 6, form_y_koord() + 2 SAY "Datum do kojeg se sravnjava" GET dDok
   READ
   ESC_BCR
   BoxC()

   o_koncij()
   SEEK Trim( cIdKontoProdavnica )

   o_roba()
   o_kalk_pripr()


   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   lGenerisao := .F.
   PRIVATE nRbr := 0

   cBrNiv := kalk_get_next_broj_v5( self_organizacija_id(), "19", NIL )

   find_kalk_by_pkonto_idroba( self_organizacija_id(), cIdKontoProdavnica )


   Box(, 6, 65 )

   @ 1 + form_x_koord(), 2 + form_y_koord() SAY "Generisem nivelaciju... 19-" + cBrNiv

   DO WHILE !Eof() .AND. field->idfirma + field->pkonto == self_organizacija_id() + cIdKontoProdavnica

      cIdRoba := Idroba
      nUlaz := nIzlaz := 0
      nVPVU := nVPVI := nNVU := nNVI := 0
      nRabat := 0

      SELECT roba
      HSEEK cIdroba
      SELECT kalk

      IF roba->tip $ "TU"
         SKIP
         LOOP
      ENDIF

      cIdkonto := pkonto

      nUlazVPC  := kalk_get_mpc_by_koncij_pravilo()
      nStartMPC := nUlazVPC
      // od ove cijene pocinjemo

      nPosljVPC := nUlazVPC

      @ 2 + form_x_koord(), 2 + form_y_koord() SAY "ID roba: " + cIdRoba
      @ 3 + form_x_koord(), 2 + form_y_koord() SAY "Cijena u sifrarniku " + AllTrim( Str( nUlazVpc ) )

      DO WHILE !Eof() .AND. self_organizacija_id() + cidkonto + cIdRoba == idFirma + pkonto + idroba

         IF roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF cSravnitiD == "D"
            IF datdok > dDok
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF pu_i == "1"
            nUlaz += kolicina - gkolicina - gkolicin2
            nVPVU += mpcsapp * ( kolicina - gkolicina - gkolicin2 )
            nUlazVPC := mpcsapp
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
            nIzlaz += kolicina
            nVPVI += mpcsapp * kolicina
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
            nUlaz -= kolicina
            nVPVU -= mpcsapp * kolicina
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ELSEIF pu_i == "3"
            // nivelacija
            nVPVU += mpcsapp * kolicina
            IF mpcsapp + fcj <> 0
               nPosljVPC := mpcsapp + fcj
            ENDIF
         ELSEIF pu_i == "I"
            nIzlaz += gkolicin2
            nVPVI += mpcsapp * gkolicin2
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ENDIF
         SKIP
      ENDDO

      nRazlika := 0
      // nStanje := ROUND( nUlaz - nIzlaz, 4 )
      // nVPV := ROUND( nVPVU - nVPVI, 4 )

      nStanje := ( nUlaz - nIzlaz )
      nVPV := ( nVPVU - nVPVI )

      SELECT kalk_pripr

      IF cUvijekSif == "D"
         nUlazVPC := nStartMPC
      ENDIF

      IF Round( nStanje, 4 ) <> 0 .OR. Round( nVPV, 4 ) <> 0
         IF Round( nStanje, 4 ) <> 0
            IF cUvijekSif == "D" .AND. Round( nUlazVPC - nVPV / nStanje, 4 ) <> 0
               nRazlika := nUlazVPC - nVPV / nStanje
            ELSE
               // samo ako kartica nije ok
               IF Round( nPosljVPC - nVPV / nStanje, 4 ) = 0
                  // kartica izgleda ok
                  nRazlika := 0
               ELSE
                  nRazlika := nUlazVPC - nVPV / nStanje
                  // nova - stara cjena
               ENDIF
            ENDIF
         ELSE
            nRazlika := nVPV
         ENDIF

         IF Round( nRazlika, 4 ) <> 0

            lGenerisao := .T.

            @ 4 + form_x_koord(), 2 + form_y_koord() SAY "Generisao stavki: " + AllTrim( Str( ++nRbr ) )

            APPEND BLANK

            REPLACE idfirma WITH self_organizacija_id(), idroba WITH cIdRoba, idkonto WITH cIdKonto, ;
               datdok WITH dDok, ;
               idtarifa WITH roba->idtarifa, ;
               datfaktp WITH dDok, ;
               kolicina WITH nStanje, ;
               idvd WITH "19", brdok WITH cBrNiv, ;
               rbr WITH Str( nRbr, 3 ), ;
               pkonto WITH cIdKontoProdavnica, ;
               pu_i WITH "3"

            IF ROUND( nStanje, 4 ) <> 0 .AND. ABS( nVPV / nStanje ) < 99999
               REPLACE fcj WITH nVPV / nStanje
               REPLACE mpcsapp WITH nRazlika
            ELSE
               REPLACE kolicina WITH 1
               REPLACE fcj WITH nRazlika + nUlazVPC
               REPLACE mpcsapp WITH -nRazlika
               REPLACE Tbanktr WITH "X"
            ENDIF

         ENDIF

      ENDIF

      SELECT kalk

   ENDDO

   BoxC()

   IF lGenerisao
      MsgBeep( "Generisana nivelacija u kalk_pripremi - obradite je!" )
   ENDIF

   my_close_all_dbf()

   RETURN .T.


// Generisanje dokumenta tipa 11 na osnovu 13-ke
FUNCTION kalk_13_to_11()

   o_konto()
   o_kalk_pripr()
   o_kalk_pripr2()
   //o_kalk()
   o_sifk()
   o_sifv()
   o_roba()

   SELECT kalk_pripr
   GO TOP
   PRIVATE cIdFirma := idfirma, cIdVD := idvd, cBrDok := brdok
   IF !( cidvd $ "13" )   .OR. Pitanje(, "Zelite li zaduziti drugu prodavnicu ?", "D" ) == "N"
      closeret
   ENDIF

   PRIVATE cProdavn := Space( 7 )
   Box(, 3, 35 )
   @ form_x_koord() + 2, form_y_koord() + 2 SAY "Prenos u prodavnicu:" GET cProdavn VALID P_Konto( @cProdavn )
   READ
   BoxC()
   PRIVATE cBrUlaz := "0"


   kalk_set_brkalk_za_idvd( "11", @cBrUlaz )

   SELECT kalk_pripr
   GO TOP
   PRIVATE nRBr := 0
   DO WHILE !Eof() .AND. cidfirma == idfirma .AND. cidvd == idvd .AND. cbrdok == brdok
      scatter()
      SELECT roba; HSEEK _idroba
      SELECT kalk_pripr2
      APPEND BLANK

      _idpartner := ""
      _rabat := prevoz := prevoz2 := _banktr := _spedtr := _zavtr := _nc := _marza := _marza2 := _mpc := 0

      _fcj := _fcj2 := _nc := kalk_pripr->nc
      _rbr := Str( ++nRbr, 3 )
      _kolicina := kalk_pripr->kolicina
      _idkonto := cProdavn
      _idkonto2 := kalk_pripr->idkonto2
      _brdok := cBrUlaz
      _idvd := "11"
      _MKonto := _Idkonto2;_MU_I := "5"     // izlaz iz magacina
      _PKonto := _Idkonto; _PU_I := "1"     // ulaz  u prodavnicu

      _TBankTr := ""    // izgenerisani dokument
      gather()

      SELECT kalk_pripr
      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN .T.

/*

// Generisanje stavki u 42-ki na osnovu storna 41-ica
FUNCTION Gen41S()

   o_kalk_pripr()
   SELECT kalk_pripr
   IF idvd <> "42"
      MsgBeep( "U kalk_pripremi mora da se nalazi dokument 42 !!!" )
      CLOSE kalk_pripr
      RETURN .F.
   ENDIF

   IF pitanje(, "Generisati storno 41-ca ?", " " ) == "N"
      CLOSE kalk_pripr
      RETURN .F.
   ENDIF

   o_tarifa()
   o_roba()
   -- o_kalk()

   SELECT kalk_pripr
   GO BOTTOM

   cIdFirma := kalk_pripr->idFirma
   cPKonto := kalk_pripr->pkonto

   SELECT kalk; SET ORDER TO TAG "PTARIFA"
   // ("PTarifa","idFirma+PKonto+IDTarifa+idroba",KUMPATH+"KALK")
   SEEK cidfirma + cPKonto


   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. Pkonto == cPKonto
      cIdTarifa := IdTarifa
      SELECT roba; HSEEK kalk->idroba
--      SELECT tarifa; HSEEK cIdTarifa; SELECT kalk
      set_pdv_public_vars()
      nOPP := TARIFA->OPP; nPPP := TARIFA->PPP
      nZPP := tarifa->zpp
      nMPV := nMPVSaPP := 0
      nPopust := 0

      lUPripr := .T.
      SELECT kalk_pripr; LOCATE FOR idtarifa == cIdTarifa
      IF !Found(); GO top; lUPripr := .F. ; ENDIF
      dGledamDo := datdok
      SELECT kalk

      // ---------------------------------
      // koliko je avansa na raspolaganju?
      // ---------------------------------
      DO WHILE !Eof() .AND. cIdFirma == IdFirma  .AND. PKonto == cPKonto .AND. ;
            cIdtarifa == IdTarifa
         IF DATDOK > dGledamDo .OR. !lUPripr; SKIP 1; LOOP; ENDIF
         SELECT ROBA; HSEEK KALK->IDROBA  // pozicioniraj sifrarnik robe
         SELECT KALK
         IF IDVD = "41" .OR. ( IDVD == "42" .AND. KOLICINA * MPC < 0 )
            // ----------------------------------
            // gledaj samo 41-ce i 42-ke u stornu
            // ----------------------------------
            IF IDVD == "42" .AND. kolicina > 0
               nMPV     += ( -MPC * Kolicina )
               nMPVSaPP += ( -MPCSaPP * Kolicina )
            ELSE
               nMPV     += MPC * Kolicina
               nMPVSaPP += MPCSaPP * Kolicina
            ENDIF
         ENDIF
         SKIP 1
      ENDDO // tarifa

      SELECT kalk_pripr

      nMPVSappReal := 0
      nMPVReal     := 0

      IF Round( nMPVSaPP, 4 ) <> 0
         IF !lUPripr
            MsgBeep( "U kalk_pripremi se ne nalazi unesena stavka za tarifu :" + cIdtarifa + " ?" )
            my_close_all_dbf()
            RETURN .F.
         ELSE
            nMPVSappREal := kalk_pripr->mpcsapp * kolicina
            nMPVReal     := kalk_pripr->mpc * kolicina
            cRIdRoba     := kalk_pripr->idroba
            SKIP 1
            DO WHILE !Eof()
               IF idtarifa == cIdTarifa
                  IF kolicina > 0
                     nMPVSappREal += kalk_pripr->mpcsapp * kolicina
                     nMPVReal     += kalk_pripr->mpc * kolicina
                  ELSE
                     MsgBeep( "Vec postoji storno 41-ca, stavka br." + rbr + " u kalk_pripremi!" )
                  ENDIF
               ENDIF
               SKIP 1
            ENDDO
         ENDIF
      ENDIF

      IF nMPVSAppReal < 0  // ako se radi o une�enom stornu obra�unate realizacije
         nMPVSapp := 0      // onda ne mo�e biti storna avansa
         nMPV := 0
      ELSEIF nMPVSAPP > nMPVSAppREal   // akontacije su vece od realizovanog poreza
         nMPVSapp := nMPVSappReal // poreska uplata ne moze biti negativna
         nMPV := nMPVReal         // tj realizovano - akontacija >=0
      ENDIF

      IF Round( nMPVSaPP, 4 ) <> 0
         SELECT kalk_pripr ; GO BOTTOM
         Scatter()
         APPEND BLANK
         gather()
         RREPLACE rbr WITH Str( Val( rbr ) + 1, 3 ), kolicina WITH -1, MPCSAPP WITH nMPVSapp, ;
            mpc WITH nMPV, nc WITH nMPV, marza2 WITH 0, TMarza WITH "A", ;
            idtarifa WITH cIdTarifa,  idroba WITH cRIdRoba

      ENDIF
      SELECT kalk

   ENDDO // konto

   my_close_all_dbf()

   RETURN .T.

*/

/*
  Generisanje dokumenta tipa 41 ili 42 na osnovu 11-ke
*/

FUNCTION kalk_iz_11_u_41_42()

   o_kalk_edit()
   cIdFirma := self_organizacija_id()
   cIdVdU   := "11"
   cIdVdI   := "4"
   cBrDokU  := Space( Len( kalk_pripr->brdok ) )
   cBrDokI  := ""
   dDatDok    := CToD( "" )

   cBrFaktP   := Space( Len( kalk_pripr->brfaktp ) )
   cIdPartner := Space( Len( kalk_pripr->idpartner ) )
   dDatFaktP  := CToD( "" )

   cPoMetodiNC := "N"

   Box(, 6, 75 )
   @ form_x_koord() + 0, form_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 41/42 NA OSNOVU DOKUMENTA 11"
   @ form_x_koord() + 2, form_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-" + cIdVdU + "-"
   @ Row(), Col() GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ form_x_koord() + 3, form_y_koord() + 2 SAY "Formirati dokument (41 ili 42)  4"
   cPom := "2"
   @ Row(), Col() GET cPom VALID cPom $ "12" PICT "9"
   @ form_x_koord() + 4, form_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   @ form_x_koord() + 5, form_y_koord() + 2 SAY "Utvrditi NC po metodi iz parametara ? (D/N)" GET cPoMetodiNC VALID cPoMetodiNC $ "DN" PICT "@!"
   READ; ESC_BCR
   cIdVdI += cPom
   BoxC()

   IF cIdVdI == "41"
      Box(, 5, 75 )
      @ form_x_koord() + 0, form_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 41 NA OSNOVU DOKUMENTA 11"
      @ form_x_koord() + 2, form_y_koord() + 2 SAY "Broj maloprodajne fakture" GET cBrFaktP
      @ form_x_koord() + 3, form_y_koord() + 2 SAY "Datum fakture            " GET dDatFaktP
      @ form_x_koord() + 4, form_y_koord() + 2 SAY "Sifra kupca              " GET cIdPartner VALID Empty( cIdPartner ) .OR. p_partner( @cIdPartner )
      READ
      BoxC()
   ENDIF

   kalk_set_brkalk_za_idvd( cIdVdI, @cBrDokI )


   find_kalk_by_broj_dokumenta( cIdFirma, cIdVDU, cBrDokU )
   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK

      PushWA()
      SELECT kalk_pripr; APPEND BLANK; Scatter()
      _idfirma   := cIdFirma
      _idroba    := KALK->idroba
      _idkonto   := KALK->idkonto
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := cBrFaktP
      _datfaktp  := IF( !Empty( dDatFaktP ), dDatFaktP, dDatDok )
      _idpartner := cIdPartner
      _rbr       := KALK->rbr
      _kolicina  := KALK->kolicina
      _fcj       := KALK->nc
      _tprevoz   := "A"
      _tmarza2   := "A"
      // _marza2    := KALK->(marza+marza2)
      _mpc       := KALK->mpc
      _idtarifa  := KALK->idtarifa
      _mpcsapp   := KALK->mpcsapp
      _pkonto    := KALK->pkonto
      _pu_i      := "5"
      _error     := "0"

      IF !Empty( kalk_metoda_nc() ) .AND. cPoMetodiNC == "D"
         nc1 := nc2 := 0

         ?
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, 0, 0, @nc1, @nc2, )


         // if dDatNab>_DatDok; Beep(1);Msg("Datum nabavke je "+dtoc(dDatNab),4);endif
         IF kalk_metoda_nc() $ "13"; _fcj := nc1; ELSEIF kalk_metoda_nc() == "2"; _fcj := nc2; ENDIF
      ENDIF

      _nc     := _fcj
      _marza2 := _mpc - _nc

      SELECT kalk_pripr
      my_rlock()
      Gather()
      my_unlock()
      SELECT KALK
      PopWA()
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN .T.


// Generisanje dokumenta tipa 11 na osnovu 10-ke
FUNCTION kalk_iz_10_u_11()

   o_kalk_edit()
   cIdFirma := self_organizacija_id()
   cIdVdU   := "10"
   cIdVdI   := "11"
   cBrDokU  := Space( Len( kalk_pripr->brdok ) )
   cIdKonto := Space( Len( kalk_pripr->idkonto ) )
   cBrDokI  := ""
   dDatDok    := CToD( "" )

   cBrFaktP   := ""
   cIdPartner := ""
   dDatFaktP  := CToD( "" )

   cPoMetodiNC := "N"

   Box(, 6, 75 )
   @ form_x_koord() + 0, form_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 11 NA OSNOVU DOKUMENTA 10"
   @ form_x_koord() + 2, form_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-" + cIdVdU + "-"
   @ Row(), Col() GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ form_x_koord() + 3, form_y_koord() + 2 SAY "Prodavn.konto zaduzuje   " GET cIdKonto VALID P_Konto( @cIdKonto )
   @ form_x_koord() + 4, form_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   @ form_x_koord() + 5, form_y_koord() + 2 SAY "Utvrditi NC po metodi iz parametara ? (D/N)" GET cPoMetodiNC VALID cPoMetodiNC $ "DN" PICT "@!"
   READ; ESC_BCR
   BoxC()


   kalk_set_brkalk_za_idvd( cIdVdI, @cBrDokI )


   find_kalk_by_broj_dokumenta( cIdFirma, cIdVDU, cBrDokU )

   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK
      PushWA()
      SELECT kalk_pripr
      APPEND BLANK
      Scatter()
      _idfirma   := cIdFirma
      _idroba    := KALK->idroba
      _idkonto   := cIdKonto
      _idkonto2  := KALK->idkonto
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := cBrFaktP
      _datfaktp  := IF( !Empty( dDatFaktP ), dDatFaktP, dDatDok )
      _idpartner := cIdPartner
      _rbr       := KALK->rbr
      _kolicina  := KALK->kolicina
      _fcj       := KALK->nc
      _tprevoz   := "R"
      _tmarza    := "A"
      _tmarza2   := "A"
      _vpc       := KALK->vpc
      // _marza2 := _mpc - _vpc
      // _mpc       := KALK->mpc
      _idtarifa  := KALK->idtarifa
      _mpcsapp   := KALK->mpcsapp
      _pkonto    := _idkonto
      _mkonto    := _idkonto2
      _mu_i      := "5"
      _pu_i      := "1"
      _error     := "0"

      IF !Empty( kalk_metoda_nc() ) .AND. cPoMetodiNC == "D"
         nc1 := nc2 := 0


         // ? ?           ?
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, 0, 0, @nc1, @nc2, )

         // if dDatNab>_DatDok; Beep(1);Msg("Datum nabavke je "+dtoc(dDatNab),4);endif
         IF kalk_metoda_nc() $ "13"; _fcj := nc1; ELSEIF kalk_metoda_nc() == "2"; _fcj := nc2; ENDIF
      ENDIF

      _nc     := _fcj
      _marza  := _vpc - _nc

      SELECT kalk_pripr
      my_rlock()
      Gather()
      my_unlock()
      SELECT KALK
      PopWA()
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN .T.



// generisi 80-ku na osnovu IP-a
FUNCTION gen_ip_80()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cTipDok := "IP"
   LOCAL cIpBrDok := Space( 8 )
   LOCAL dDat80 := Date()
   LOCAL nCnt := 0
   LOCAL cNxt80 := Space( 8 )

   Box(, 5, 65 )
   @ 1 + form_x_koord(), 2 + form_y_koord() SAY "Postojeci dokument IP -> " + cIdFirma + "-" + cTipDok + "-" GET cIpBrDok VALID !Empty( cIpBrDok )
   @ 2 + form_x_koord(), 2 + form_y_koord() SAY "Datum dokumenta" GET dDat80 VALID !Empty( dDat80 )
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   IF Pitanje(, "Generisati 80-ku (D/N)?", "D" ) == "N"
      RETURN .F.
   ENDIF

   // kopiraj dokument u pript
   IF !kalk_copy_kalk_azuriran_u_pript( cIdFirma, cTipDok, cIpBrDok )
      RETURN .F.
   ENDIF

   o_kalk_doks()
   o_kalk()
   o_kalk_pript()
   o_kalk_pripr()

   cNxt80 := kalk_get_next_kalk_doc_uvecaj( self_organizacija_id(), "80" )

   // obradi dokument u kalk_pripremu -> konvertuj u 80
   SELECT pript
   SET ORDER TO TAG "2"
   GO TOP

   Box(, 1, 30 )

   DO WHILE !Eof()

      Scatter()

      SELECT kalk_pripr
      APPEND BLANK

      _gkolicina := 0
      _gkolicin2 := 0
      _idvd := "80"
      _error := "0"
      _tmarza2 := "A"
      _datdok := dDat80
      _datfaktp := dDat80
      _brdok := cNxt80

      Gather()

      ++ nCnt
      @ 1 + form_x_koord(), 2 + form_y_koord() SAY AllTrim( Str( nCnt ) )

      SELECT pript
      SKIP
   ENDDO

   BoxC()

   RETURN .T.
