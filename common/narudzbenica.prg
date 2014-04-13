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



#include "fmk.ch"

STATIC LEN_COLONA :=  42
STATIC LEN_FOOTER := 14

STATIC lShowPopust

STATIC cLine
STATIC lPrintedTotal := .F.
STATIC nStr := 0

// ako se koristi PTXT onda se ova korekcija primjenjuje
// za prikaz vecih fontova
STATIC nDuzStrKorekcija := 0

// prikaz samo kolicine 0, cijena 1
STATIC nSw6


// glavna funkcija za poziv stampe fakture a4
// lStartPrint - pozovi funkcije stampe START PRINT
FUNCTION nar_print( lStartPrint )

   // ako je nil onda je uvijek .t.
   IF lStartPrint == nil
      lStartPrint := .T.
   ENDIF

   PIC_KOLICINA( PadL( AllTrim( Right( PicKol, LEN_KOLICINA() ) ), LEN_KOLICINA(), "9" ) )
   PIC_VRIJEDNOST( PadL( AllTrim( Right( PicDem, LEN_VRIJEDNOST() ) ), LEN_VRIJEDNOST(), "9" ) )
   PIC_CIJENA( PadL( AllTrim( Right( PicCDem, LEN_CIJENA() ) ), LEN_CIJENA(), "9" ) )

   drn_open()

   SELECT drn
   GO TOP

   LEN_NAZIV( 53 )
   LEN_UKUPNO( 99 )
   IF Round( drn->ukpopust, 2 ) <> 0
      lShowPopust := .T.
   ELSE
      lShowPopust := .F.
      LEN_NAZIV( LEN_NAZIV() + LEN_PROC2() + LEN_CIJENA() + 2 )
   ENDIF

   narudzba( lStartPrint )

   RETURN



// stampa narudzbenice
FUNCTION narudzba( lStartPrint )

   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL aRNaz
   LOCAL cArtikal
   LOCAL cSlovima

   PRIVATE nLMargina // lijeva margina
   PRIVATE nDodRedova // broj dodatnih redova
   PRIVATE nSlTxtRow // broj redova slobodnog text-a
   PRIVATE lSamoKol // prikaz samo kolicina
   PRIVATE lZaglStr // zaglavlje na svakoj stranici
   PRIVATE lDatOtp // prikaz datuma otpremnice i narudzbenice
   PRIVATE cValuta // prikaz valute KM ili ???
   PRIVATE lStZagl // automatski formirati zaglavlje
   PRIVATE nGMargina // gornja margina

   IF lStartPrint
      START PRINT CRET
   ENDIF

   nSw6 := Val( get_dtxt_opis( "X09" ) )

   lPrintedTotal := .F.

   // uzmi glavne varijable za stampu fakture
   // razmak, broj redova sl.teksta,
   get_nar_vars( @nLMargina, @nGMargina, @nDodRedova, @nSlTxtRow, @lSamoKol, @lZaglStr, @lStZagl, @lDatOtp, @cValuta )

   // razmak ce biti
   RAZMAK( Space( nLMargina ) )

   cLine := nar_line()

   // zaglavlje por.fakt
   nar_header()

   IF nSw6 == 0
      P_12CPI
   ENDIF

   SELECT rn
   SET ORDER TO TAG "1"
   GO TOP

   IF nSw6 > 0
      P_COND
   ENDIF

   st_zagl_data()

   SELECT rn

   nStr := 1
   aArtNaz := {}

   // data
   DO WHILE !Eof()
	
	
      // uzmi naziv u matricu
      cNazivDobra := NazivDobra( rn->idroba, rn->robanaz, rn->jmj )
      aNazivDobra := SjeciStr( cNazivDobra, LEN_NAZIV() )
	
      // PRVI RED
      // redni broj ili podbroj
      ? RAZMAK()
	
      IF Empty( rn->podbr )
         ?? PadL( rn->rbr + ")", LEN_RBR() )
      ELSE
         ?? PadL( rn->rbr + "." + AllTrim( rn->podbr ), LEN_RBR() )
      ENDIF
      ?? " "
	
      // idroba, naziv robe, kolicina, jmj
      ?? PadR( aNazivDobra[ 1 ], LEN_NAZIV() )
      ?? " "
      ?? show_number( rn->kolicina, PIC_KOLICINA() )
      ?? " "
	
      IF nSw6 > 0
	
         // cijena bez pdv
         ?? show_number( rn->cjenbpdv, PIC_CIJENA() )
         ?? " "


         IF lShowPopust
            // procenat popusta
            ?? show_popust( rn->popust )
            ?? " "

            // cijena bez pd - popust
            ?? show_number( rn->cjen2bpdv, PIC_CIJENA() )
            ?? " "
         ENDIF


         // ukupno bez pdv
         ?? show_number( rn->cjenbpdv * rn->kolicina,  PIC_VRIJEDNOST() )
         ?? " "
      ENDIF

      IF Len( aNazivDobra ) > 1
         // DRUGI RED
         ? RAZMAK()
         ?? " "
         ?? Space( LEN_RBR() )
         ?? PadR( aNazivDobra[ 2 ], LEN_NAZIV() )
      ENDIF
	
      // provjeri za novu stranicu
      IF PRow() > ( nDodRedova + LEN_STRANICA() - DSTR_KOREKCIJA() )
         ++nStr
         Nstr_a4( nStr, .T. )
      endif

      SELECT rn
      SKIP
   ENDDO

   // provjeri za novu stranicu
   IF PRow() > nDodRedova + ( LEN_STRANICA() - LEN_FOOTER )
      ++nStr
      Nstr_a4( nStr, .T. )
   endif

   IF nSw6 > 0
      print_total()
      lPrintedTotal := .T.

      IF PRow() > nDodRedova + ( LEN_STRANICA() - LEN_FOOTER )
         ++nStr
         Nstr_a4( nStr, .T. )
      endif
   ENDIF

   // dodaj text na kraju fakture
   nar_footer()


   IF lStartPrint
      FF
      ENDPRINT
   ENDIF

   RETURN

// uzmi osnovne parametre za stampu dokumenta
FUNCTION get_nar_vars( nLMargina, nGMargina, nDodRedova, nSlTxtRow, lSamoKol, lZaglStr, lStZagl, lDatOtp, cValuta, cPDVStavka )

   // uzmi podatak za lijevu marginu
   nLMargina := Val( get_dtxt_opis( "P01" ) )

   // uzmi podatak za gornju marginu
   nGMargina := Val( get_dtxt_opis( "P07" ) )

   // broj dodatnih redova po listu
   nDodRedova := Val( get_dtxt_opis( "P06" ) )

   // uzmi podatak za duzinu slobodnog teksta
   nSlTxtRow := Val( get_dtxt_opis( "P02" ) )

   // varijanta fakture (porez na svaku stavku D/N)
   cPDVStavka := get_dtxt_opis( "P11" )

   // da li se prikazuju samo kolicine
   lSamoKol := .F.
   IF get_dtxt_opis( "P03" ) == "D"
      lSamoKol := .T.
   ENDIF

   // da li se kreira zaglavlje na svakoj stranici
   lZaglStr := .F.
   IF get_dtxt_opis( "P04" ) == "D"
      lZaglStr := .T.
   ENDIF

   // da li se kreira zaglavlje na svakoj stranici
   lStZagl := .F.
   IF get_dtxt_opis( "P10" ) == "D"
      lStZagl := .T.
   ENDIF

   // da li se ispisuji podaci otpremnica itd....
   lDatOtp := .T.
   IF get_dtxt_opis( "P05" ) == "N"
      lZaglStr := .F.
   ENDIF

   // valuta dokuemnta
   cValuta := get_dtxt_opis( "D07" )

   RETURN
// }


// zaglavlje glavne tabele sa stavkama
STATIC FUNCTION st_zagl_data()

   // {

   LOCAL cRed1 := ""
   LOCAL cRed2 := ""
   LOCAL cRed3 := ""


   ? cLine

   cRed1 := RAZMAK()
   cRed1 += PadC( "R.br", LEN_RBR() )
   cRed1 += " " + PadR( lokal( "Trgovacki naziv dobra/usluge (sifra, naziv, jmj)" ), LEN_NAZIV() )

   cRed1 += " " + PadC( lokal( "kolicina" ), LEN_KOLICINA() )

   IF nSw6 > 0
      cRed1 += " " + PadC( lokal( "C.b.PDV" ), LEN_CIJENA() )
      IF lShowPopust
         cRed1 += " " + PadC( lokal( "Pop.%" ), LEN_PROC2() )
         cRed1 += " " + PadC( lokal( "C.2.b.PDV" ), LEN_CIJENA() )
      ENDIF
      cRed1 += " " + PadC( lokal( "Uk.bez.PDV" ), LEN_VRIJEDNOST() )
   ENDIF

   ? cRed1

   ? cLine

   RETURN
// }

// definicija linije za glavnu tabelu sa stavkama
FUNCTION nar_line()

   LOCAL cLine

   cLine := RAZMAK()
   cLine += Replicate( "-", LEN_RBR() )
   cLine += " " + Replicate( "-", LEN_NAZIV() )
   // kolicina
   cLine += " " + Replicate( "-", LEN_KOLICINA() )

   IF nSw6 > 0
      // cijena b. pdv
      cLine += " " + Replicate( "-", LEN_CIJENA() )

      IF lShowPopust
         // popust
         cLine += " " + Replicate( "-", LEN_PROC2() )
         // cijen b. pdv - popust
         cLine += " " + Replicate( "-", LEN_CIJENA() )
      ENDIF

      // vrijednost b. pdv
      cLine += " " + Replicate( "-", LEN_VRIJEDNOST() )
   ENDIF

   RETURN cLine

// --------------------------------------------------
// --------------------------------------------------
STATIC FUNCTION print_total()

   ? cLine

   // kolona bez PDV

   ? RAZMAK()
   ?? Space( LEN_UKUPNO() - ( LEN_KOLICINA() + LEN_CIJENA() + 2 ) )

   IF Round( drn->ukkol, 2 ) <> 0
      ?? show_number( drn->ukkol, PIC_KOLICINA() )
   ELSE
      ?? Space( LEN_KOLICINA() )
   ENDIF
   ?? " "

   ?? Space( LEN_CIJENA() )
   ?? " "

   ?? show_number( drn->ukbezpdv, PIC_VRIJEDNOST() )

   // cijene se ne rekapituliraju
   ?? " "
   ?? Space( Len( PIC_CIJENA() ) )


   // provjeri i dodaj stavke vezane za popust
   IF Round( drn->ukpopust, 2 ) <> 0
      ? RAZMAK()
      ?? PadL( lokal( "Popust (" ) + cValuta + ") :", LEN_UKUPNO() )
      ?? show_number( drn->ukpopust, PIC_VRIJEDNOST() )
		
      ? RAZMAK()
      ?? PadL( lokal( "Uk.bez.PDV-popust (" ) + cValuta + ") :", LEN_UKUPNO() )
      ?? show_number( drn->ukbpdvpop, PIC_VRIJEDNOST() )
   ENDIF


   // obracun PDV-a
   ? RAZMAK()
   ?? PadL( lokal( "PDV 17% :" ), LEN_UKUPNO() )
   ?? show_number( drn->ukpdv, PIC_VRIJEDNOST() )


   // zaokruzenje
   IF Round( drn->zaokr, 4 ) <> 0
      ? RAZMAK()
      ?? PadL( lokal( "Zaokruzenje :" ), LEN_UKUPNO() )
      ?? show_number( drn->zaokr, PIC_VRIJEDNOST() )
   ENDIF
	
   ? cLine
   ? RAZMAK()
   // ipak izleti za dva karaktera rekapitulacija u bold rezimu
   ?? Space( 50 - 2 )
   B_ON
   ?? PadL( lokal( "** SVEUKUPNO SA PDV  (" ) + cValuta + ") :", LEN_UKUPNO() - 50 )
   ?? Transform( drn->ukupno, PIC_VRIJEDNOST() )
   B_OFF

	
   cSlovima := get_dtxt_opis( "D04" )
   ? RAZMAK()
   B_ON
   ?? lokal( "slovima: " ) + cSlovima
   B_OFF
   ? cLine

   RETURN


// ----------------------------------------
// funkcija za ispis podataka o kupcu
// ----------------------------------------
STATIC FUNCTION nar_header()

   LOCAL cPom, cPom2
   LOCAL cLin
   LOCAL cPartMjesto
   LOCAL cPartPTT
   LOCAL cNaziv, cNaziv2
   LOCAL cAdresa, cAdresa2
   LOCAL cIdBroj, cIdBroj2
   LOCAL cMjesto, cMjesto2
   LOCAL cTelFax, cTelFax2
   LOCAL aKupac, aDobavljac
   LOCAL cDatDok
   LOCAL cDatIsp
   LOCAL cDatVal
   LOCAL cBrDok
   LOCAL cBrNar
   LOCAL cBrOtp
   LOCAL nPRowsDelta

   nPRowsDelta := PRow()

   drn_open()
   SELECT drn
   GO TOP

   cDatDok := DToC( datdok )

   IF Empty( datIsp )
      // posto je ovo obavezno polje na racunu
      // stavicemo ako nije uneseno da je datum isporuke
      // jednak datumu dokumenta
      cDatIsp := DToC( datDok )
   ELSE
      cDatIsp := DToC( datisp )
   ENDIF

   cDatVal := DToC( field->datval )
   cBrDok := field->brdok

   cBrNar := get_dtxt_opis( "D06" )
   cBrOtp := get_dtxt_opis( "D05" )

   cNaziv := get_dtxt_opis( "K01" )
   cAdresa := get_dtxt_opis( "K02" )
   cIdBroj := get_dtxt_opis( "K03" )
   cDestinacija := get_dtxt_opis( "D08" )

   cTelFax := "tel: "
   cPom := AllTrim( get_dtxt_opis( "K13" ) )

   IF Empty( cPom )
      cPom := "-"
   ENDIF

   cTelFax += cPom
   cPom := AllTrim( get_dtxt_opis( "K14" ) )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cTelFax += ", fax: " + cPom

   // K10 - partner mjesto
   cMjesto := get_dtxt_opis( "K10" )
   // K11 - partner PTT
   cPTT := get_dtxt_opis( "K11" )


   PushWa()
   SELECT F_PARTN
   IF !Used()
      O_PARTN
   ENDIF

   // gFirma sadrzi podatke o maticnoj firmi
   SEEK gFirma

   cNaziv2  := AllTrim( partn->naz )
   cMjesto2 := AllTrim( partn->ptt ) + " " + AllTrim( partn->mjesto )
   cAdresa2 := AllTrim( partn->adresa )
   cAdresa2 := get_dtxt_opis( "I02" )
   // idbroj
   cIdBroj2 := get_dtxt_opis( "I03" )
   cTelFax2 := "tel: " + AllTrim( partn->telefon )  + ", fax: " + AllTrim( partn->fax )

   PopWa()

   cMjesto := AllTrim( cMjesto )
   IF !Empty( cPTT )
      cMjesto := AllTrim( cPTT ) + " " + cMjesto
   ENDIF

   aKupac := Sjecistr( cNaziv, LEN_COLONA )
   aDobavljac := SjeciStr( cNaziv2, LEN_COLONA )

   B_ON
   cPom := PadR( lokal( "Naručioc:" ), LEN_COLONA ) + " " + PadR( lokal( "Dobavljač:" ), LEN_COLONA )

   p_line( cPom, 12, .T. )

   cPom := PadR( Replicate( "-", LEN_COLONA - 2 ), LEN_COLONA )
   cLin := cPom + " " + cPom
   p_line( cLin, 12, .F. )

   // prvi red kupca, 10cpi, bold
   cPom := AllTrim( aKupac[ 1 ] )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom := PadR( cPom, LEN_COLONA )

   // prvi red dobavljaca, 10cpi, bold
   cPom2 := AllTrim( aDobavljac[ 1 ] )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF
   cPom := cPom +  " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .F. )


   cPom := AllTrim( cAdresa )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cAdresa2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF

   cPom := PadR( cPom, LEN_COLONA )
   cPom += " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )

   // mjesto
   cPom := AllTrim( cMjesto )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cMjesto2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF
   cPom := PadR( cPom, LEN_COLONA )
   cPom += " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )

   // idbroj
   cPom := AllTrim( cIdBroj )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cIdBroj2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF
   cPom := PadR( lokal( "ID: " ) + cPom, LEN_COLONA )
   cPom += " " + PadR( lokal( "ID: " ) + cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )


   // telfax
   cPom := AllTrim( cTelFax )
   IF Empty( cTelFax )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cTelFax2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF


   cPom := PadR( cPom, LEN_COLONA )
   cPom += " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )


   p_line( cLin, 12, .T. )

   B_OFF

   IF !Empty( cDestinacija )
      ?
      p_line( Replicate( "-", LEN_KUPAC() - 10 ), 12, .F. )
      cPom := lokal( "Destinacija: " )  + AllTrim( cDestinacija )
      p_line( cPom, 12, .F. )
      ?
   ENDIF


   ?
   ?
   P_10CPI
   // broj dokumenta
   cPom := lokal( "NARUDZBENICA br. ___________ od " ) + cDatDok
   cPom := PadC( cPom, LEN_COLONA * 2 )
   p_line( cPom, 10, .T. )
   B_OFF
   ?
   cPom := lokal( "Molimo da nam na osnovu ponude/dogovora/ugovora _________________ " )
   p_line( cPom, 12, .F. )
   cPom := lokal( "isporucite sljedeca dobra/usluge:" )
   p_line( cPom, 12, .F. )

   nPRowsDelta := PRow() - nPRowsDelta
   IF IsPtxtOutput()
      nDuzStrKorekcija += nPRowsDelta * 7 / 100
   ENDIF

   RETURN

// -----------------------------------
// -----------------------------------
FUNCTION nar_footer()

   LOCAL cPom

   ?
   cPom := lokal( "USLOVI NABAVKE:" )
   p_line( cPom, 12, .T. )
   cPom := "----------------"
   p_line( cPom, 12, .T. )
   ?
   cPom := lokal( "Mjesto isporuke _______________________  Nacin placanja: gotovina/banka/kompenzacija" )
   p_line( cPom, 12, .T. )
   ?
   cPom := lokal( "Vrijeme isporuke _____________________________________________________________" )
   ?
   p_line( cPom, 12, .T. )
   ?
   cPom := lokal( "Napomena: Molimo popuniti prazna polja, te zaokružiti željene opcije" )
   p_line( cPom, 20, .F. )

   ?
   cPom := PadL( lokal( " M.P.          " ), LEN_COLONA ) + " "
   cPom += PadC( lokal( "Za naručioca:" ), LEN_COLONA )
   p_line( cPom, 12, .F. )
   ?
   cPom := PadC( " ", LEN_COLONA ) + " "
   cPom += PadC( Replicate( "-", LEN_COLONA - 4 ), LEN_COLONA )
   p_line( cPom, 12, .F. )

   ?

   RETURN

// -----------------------------------------
// funkcija za novu stranu
// -----------------------------------------
STATIC FUNCTION NStr_a4( nStr, lShZagl )

   // {

   // korekcija duzine je na svako strani razlicita
   nDuzStrKorekcija := 0

   P_COND
   ? cLine
   p_line( lokal( "Prenos na sljedecu stranicu" ), 17, .F. )
   ? cLine

   FF

   P_COND
   ? cLine
   IF nStr <> nil
      p_line( lokal( "       Strana:" ) + Str( nStr, 3 ), 17, .F. )
   ENDIF

   // total nije odstampan znaci ima jos podataka
   IF lShZagl
      IF !lPrintedTotal
         st_zagl_data()
      ELSE
         // vec je odstampan, znaci nema vise stavki
         // najbolje ga prenesi na ovu stranu koja je posljednja
         print_total()
      ENDIF
   ELSE
      ? cLine
   ENDIF

   RETURN
// }


// --------------------------------
// korekcija za duzinu strane
// --------------------------------
STATIC FUNCTION DSTR_KOREKCIJA()

   LOCAL nPom

   nPom := Round( nDuzStrKorekcija, 0 )
   IF Round( nDuzStrKorekcija - nPom, 1 ) > 0.2
      nPom ++
   ENDIF

   RETURN nPom

   RETURN
