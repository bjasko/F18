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


/* ingroup ini
  * var *string FmkIni_ExePath_Fakt_Ugovori_Dokumenata_Izgenerisati
  * brief Broj ugovora koji se obrade pri jednom pozivu opcije generisanja faktura na osnovu ugovora
  * param 1 - default vrijednost
  */
// string FmkIni_ExePath_Fakt_Ugovori_Dokumenata_Izgenerisati;


/* ingroup ini
  * var *string FmkIni_ExePath_Fakt_Ugovori_N1
  * brief Koristi li se za generaciju faktura po ugovorima parametar N1 ?
  * param D - da, default vrijednost
  * param N - ne
  */
// string FmkIni_ExePath_Fakt_Ugovori_N1;


/*! \ingroup ini
  * \var *string FmkIni_ExePath_Fakt_Ugovori_N2
  * \brief Koristi li se za generaciju faktura po ugovorima parametar N2 ?
  * \param D - da, default vrijednost
  * \param N - ne
  */
// string FmkIni_ExePath_Fakt_Ugovori_N2;


/* ingroup ini
  * var *string FmkIni_ExePath_Fakt_Ugovori_N3
  * brief Koristi li se za generaciju faktura po ugovorima parametar N3 ?
  * param D - da, default vrijednost
  * param N - ne
  */
// string FmkIni_ExePath_Fakt_Ugovori_N3;


/* ingroup ini
  * var *string FmkIni_ExePath_FAKT_Ugovori_SumirajIstuSifru
  * brief Da li ce se pri generisanju fakture na osnovu ugovora sabirati kolicine stavki iz ugovora koje sadrze isti artikal u jednu stavku na dokumentu
  * param D - da, default vrijednost
  * param N - ne
  */
// string FmkIni_ExePath_FAKT_Ugovori_SumirajIstuSifru;


/* ingroup ini
  * var *string FmkIni_ExePath_Fakt_Ugovori_UNapomenuSamoBrUgovora
  * brief Da li ce se pri generisanju faktura na osnovu ugovora u napomenu dodati iza teksta "VEZA:" samo broj ugovora
  * param D - da, default vrijednost
  * param N - ne, ispisace se i tekst "UGOVOR:", te datum ugovora
  */
  
// string FmkIni_ExePath_Fakt_Ugovori_UNapomenuSamoBrUgovora;


// ----------------------------------------------
// funkcija za poziv generacije ugovora
// ----------------------------------------------
FUNCTION m_gen_ug()

   PRIVATE DFTkolicina := 1
   PRIVATE DFTidroba := PadR( "", 10 )
   PRIVATE DFTvrsta := "1"
   PRIVATE DFTidtipdok := "10"
   PRIVATE DFTdindem := "KM "
   PRIVATE DFTidtxt := "10"
   PRIVATE DFTzaokr := 2
   PRIVATE DFTiddodtxt := "  "
   PRIVATE gGenUgV2 := "1"
   PRIVATE gFinKPath := Space( 50 )

   DFTParUg( .T. )

   IF gGenUgV2 == "1"
      gen_ug()
   ELSE
      // nova varijanta generisanja ugovora
      gen_ug_2()
   ENDIF

   RETURN .T.


// -----------------------------------------
// generacija ugovora varijanta 1
// -----------------------------------------
FUNCTION gen_ug()

   // otvori tabele
   o_ugov()

   nN1 := 0
   nN2 := 0
   nN3 := 0
   O_PARAMS
   PRIVATE cSection := "U"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}
   PRIVATE cUPartner := Space( IF( gVFU == "1", 16, 20 ) )
   PRIVATE dDatDok := CToD( "" ), cFUArtikal := Space( Len( ROBA->id ) )
   PRIVATE cSamoAktivni := "D"

   RPar( "uP", @cUPartner )
   RPar( "dU", @dDatDok )
   RPar( "P1", @nn1 )
   RPar( "P2", @nn2 )
   RPar( "P3", @nn3 )
   RPar( "P4", @cFUArtikal )
   RPar( "P5", @cSamoAktivni )
   USE

   nDokGen := Val( IzFMkIni( 'Fakt_Ugovori', "Dokumenata_Izgenerisati", '1' ) )

   IF nDokgen = 0
      nDokGen := 1
   ENDIF

   Box( "#PARAMETRI ZA GENERACIJU FAKTURA PO UGOVORIMA", 7, 70 )

   @ m_X + 1, m_y + 2 SAY "Datum fakture" GET dDAtDok

   IF IzFMkIni( 'Fakt_Ugovori', "N1", 'D' ) == "D"
      @ m_X + 2, m_y + 2 SAY "Parametar N1 " GET nn1 PICT "999999.999"
   ENDIF
   IF IzFMkIni( 'Fakt_Ugovori', "N2", 'D' ) == "D"
      @ m_X + 3, m_y + 2 SAY "Parametar N2 " GET nn2 PICT "999999.999"
   ENDIF
   IF IzFMkIni( 'Fakt_Ugovori', "N3", 'D' ) == "D"
      @ m_X + 4, m_y + 2 SAY "Parametar N3 " GET nn3 PICT "999999.999"
   ENDIF

   @ m_x + 5, m_y + 2 SAY "Predracun ili racun (0/1) ? " GET nn3  PICT "@!"
   @ m_x + 6, m_y + 2 SAY "Artikal (prazno-svi)" GET cFUArtikal VALID Empty( cFUArtikal ) .OR. P_Roba( @cFUArtikal ) PICT "@!"
   @ m_x + 7, m_y + 2 SAY "Generisati fakture samo na osnovu aktivnih ugovora? (D/N)" GET cSamoAktivni VALID cSamoAktivni $ "DN" PICT "@!"

   READ
   BoxC()

   lSamoAktivni := ( cSamoAktivni == "D" )
   SELECT UGOV
   IF lSamoAktivni
      SET FILTER TO aktivan == "D"
   ENDIF
   GO TOP

   FOR nTekUg := 1 TO nDokGen

      SELECT UGOV

      IF nTekug = 1
         cUPartner := Left( cUPartner, IF( gVFU == "1", 15, 19 ) ) + Chr( 254 )
      ELSE
         // ne browsaj
         SKIP 1 // saltaj ugovore
         IF Eof(); EXIT; ENDIF
      ENDIF

      IF Empty( cUPartner ) // eof()
         EXIT
      ENDIF

      IF nTekug == 1 // kada je vise ugovora, samo prvi browsaj
         P_ugov( cUPartner )
      ENDIF

      IF gVFU == "1"
         cUPartner := ugov->( id + idpartner )
      ELSE
         cUPartner := ugov->( naz )
      ENDIF

      O_FAKT
      O_FAKT_PRIPR
      IF reccount2() <> 0 .AND. nTekug = 1
         Msg( "Neki dokument vec postoji u pripremi" )
         my_close_all_dbf()
         RETURN
      ENDIF

      O_PARAMS
      PRIVATE cSection := "U", cHistory := " "; aHistory := {}
      WPar( "uP", cUPartner )
      WPar( "dU", dDatDok )
      WPar( "P1", nn1 )
      WPar( "P2", nn2 )
      WPar( "P3", nn3 )
      WPar( "P4", cFUArtikal )
      WPar( "P5", cSamoAktivni )
      USE

      SELECT fakt_pripr

      cIdTipdok := ugov->idtipdok

      IF nn3 = 1 .AND. ugov->idtipdok = "20" // konverzija 20->10
         cIdTipDok := "10"
      ENDIF

      SELECT fakt_pripr
      SEEK gFirma + cidtipdok + "È"
      SKIP -1
      IF idtipdok <> cIdTipdok
         SEEK "È" // idi na kraj, nema zeljenih dokumenata
      ENDIF

      SELECT fakt
      SEEK gFirma + cidtipdok + "È"
      SKIP -1

      IF idtipdok <> cIdTipdok
         SEEK "È" // idi na kraj, nema zeljenih  dokumenata
      ENDIF

      IF fakt_pripr->brdok > fakt->brdok
         SELECT fakt_pripr  // odaberi tabelu u kojoj ima vise dokumenata
      ENDIF


      IF cidtipdok <> idtipdok
         cBrDok := UBrojDok( 1, gNumDio, "" )
      ELSE
         cBrDok := UBrojDok( Val( Left( brdok, gNumDio ) ) + 1, ;
            gNumDio, Right( brdok, Len( brdok ) -gNumDio ) )
      ENDIF


      SELECT ugov
      IF lSamoAktivni .AND. aktivan != "D"
         IF nTekUg > 2
            --nTekUg
         ENDIF
         LOOP
      ENDIF

      cIdUgov := id



      // !!! vrtim kroz rugov
      SELECT rugov
      nRbr := 0

      SEEK cidugov

      // prvi krug odredjuje glavnicu
      nGlavnica := 0  // jedna stavka mo§e biti glavnica za ostale
      DO WHILE !Eof() .AND. id == cidugov
         SELECT roba; HSEEK rugov->idroba
         SELECT rugov
         IF K1 == "G"
            // nGlavnica+=kolicina*roba->vpc
            nGlavnica += kolicina * 10
         ENDIF
         SKIP
      ENDDO

      SEEK cidugov

      // RUGOV.DBF
      // ---------
      DO WHILE !Eof() .AND. id == cidugov

         IF !( Empty( cFUArtikal ) .OR. idroba == cFUArtikal )
            SKIP 1; LOOP
         ENDIF

         nCijena := 0

         SELECT fakt_pripr

         IF IzFMKIni( 'FAKT_Ugovori', "SumirajIstuSifru", 'D' ) == "D" .AND. ;
               IdFirma + idtipdok + brdok + idroba == gFirma + cIDTipDok + PadR( cBrDok, Len( brdok ) ) + RUGOV->idroba
            Scatter()
            _kolicina += RUGOV->kolicina
            // tag "1": "IdFirma+idtipdok+brdok+rbr+podbr"
            Gather()
            SELECT RUGOV; SKIP 1; LOOP
         ELSE
            APPEND blank; Scatter()
         ENDIF

         IF nRbr == 0
            SELECT PARTN
            HSEEK ugov->idpartner
            _txt3b := _txt3c := ""
            _txt3a := PadR( ugov->idpartner + ".", 30 )

            IzSifre( .T. )

            SELECT ftxt; HSEEK ugov->iddodtxt; cDodTxt := Trim( naz )
            HSEEK ugov->idtxt
            PRIVATE _Txt1 := ""

            SELECT roba; HSEEK rugov->idroba
            IF roba->tip == "U"
               _txt1 := roba->naz
            ELSE
               _txt1 := " "
            ENDIF

            cVezaUgovor := "Veza: " + Trim( ugov->id )

            _txt := Chr( 16 ) + _txt1 + Chr( 17 ) + ;
               Chr( 16 ) + Trim( ftxt->naz ) + Chr( 13 ) + Chr( 10 ) + ;
               cVezaUgovor + Chr( 13 ) + Chr( 10 ) + ;
               cDodTxt + Chr( 17 ) + Chr( 16 ) + _Txt3a + Chr( 17 ) + Chr( 16 ) + _Txt3b + Chr( 17 ) + ;
               Chr( 16 ) + _Txt3c + Chr( 17 )

         ENDIF


         SELECT fakt_pripr

         PRIVATE nKolicina := rugov->kolicina


         IF rugov->k1 = "A"  // onda je kolicina= A2-A1  (novo stanje - staro stanje)
            nA2 := 0
            Box(, 5, 60 )
            @ M_X + 1, M_Y + 2 SAY ugov->naz
            @ m_x + 3, m_y + 2 SAY "A: Stara vrijednost:"; ?? ugov->A2
            @ m_x + 5, m_y + 2 SAY "A: Nova vrijednost (0 ne mjenjaj):" GET nA2 PICT "999999.99"
            READ
            BoxC()
            IF na2 <> 0
               SELECT ugov
               REPLACE a1 WITH a2, a2 WITH nA2
               SELECT fakt_pripr
            ENDIF

            nKolicina := ugov->( a2 - a1 )
         ELSEIF rugov->k1 = "B"
            nB2 := 0
            Box(, 5, 60,, ugov->naz )
            @ M_X + 1, M_Y + 2 SAY ugov->naz
            @ m_x + 3, m_y + 2 SAY "B: Stara vrijednost:"; ?? ugov->B2
            @ m_x + 5, m_y + 2 SAY "B: Nova vrijednost (0 ne mjenjaj):" GET nB2 PICT "999999.99"
            READ
            BoxC()
            IF nB2 <> 0
               SELECT ugov
               REPLACE B1 WITH B2, B2 WITH nB2
               SELECT fakt_pripr
            ENDIF
            nKolicina := ugov->( b2 - b1 )
         ELSEIF rugov->k1 = "%"   // procenat na neku stavku
            nKolicina := 1
            nCijena := rugov->kolicina * nGlavnica / 100
         ELSEIF rugov->k1 = "1"   // kolicinu popunjava ulazni parametar n1
            nKolicina := nn1
         ELSEIF rugov->k1 = "2"   // kolicinu popunjava ulazni parametar n2
            nKolicina := nn2
         ELSEIF rugov->k1 = "3"   // kolicinu popunjava ulazni parametar n3
            nKolicina := nn3
         ENDIF

         PRIVATE _Txt1 := ""

         SELECT roba; HSEEK rugov->idroba
         IF nRbr <> 0 .AND. roba->tip == "U"
            _txt1 := roba->naz
            _txt := Chr( 16 ) + _txt1 + Chr( 17 )
         ENDIF

         _idfirma := gFirma
         _zaokr := ugov->zaokr
         _rbr := Str( ++nRbr, 3 )
         _idtipdok := cidtipdok
         _brdok := cBrDok
         _datdok := dDatDok
         _datpl := dDatDok
         _kolicina := nKolicina
         _idroba := rugov->idroba
         SELECT roba; HSEEK _idroba

         SELECT fakt_pripr
         fakt_setuj_cijenu( "1" )
         IF ncijena <> 0
            _cijena := nCijena
         ENDIF
         _rabat := rugov->rabat
         _porez := rugov->porez
         _dindem := ugov->dindem
         SELECT fakt_pripr
         Gather()


         SELECT rugov
         SKIP
      ENDDO


      // ****************** izgenerisati n dokumenata ***********
   NEXT

   closeret

   RETURN
// }
