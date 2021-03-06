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

STATIC LEN_IT_NO := 4
STATIC LEN_DESC := 65

STATIC LEN_QTTY := 10
STATIC LEN_DIMENSION := 10
STATIC LEN_VALUE := 10

STATIC PIC_QTTY := "9999999.99"
STATIC PIC_VALUE := "9999999.99"
STATIC PIC_DIMENSION := "9999999.99"

STATIC LEN_PAGE := 58

STATIC RAZMAK := " "

STATIC nPage := 0
STATIC lPrintedTotal := .F.

// ako se koristi PTXT onda se ova korekcija primjenjuje
// za prikaz vecih fontova
STATIC nDuzStrKorekcija := 0

// ----------------------------------------------
// definicija linije za glavnu tabelu sa stavkama
// nVar - 1 = nalog
// 2 = obracunski list
// ----------------------------------------------
STATIC FUNCTION g_line()

   LOCAL cLine

   // linija za naloge
   cLine := RAZMAK
   cLine += Replicate( "-", LEN_IT_NO )
   cLine += " " + Replicate( "-", LEN_DESC )
   cLine += " " + Replicate( "-", LEN_DIMENSION )
   cLine += " " + Replicate( "-", LEN_DIMENSION )
   cLine += " " + Replicate( "-", LEN_QTTY )

   RETURN cLine


FUNCTION rnal_nalog_za_proizvodnju_txt()

   LOCAL aGroups := {}
   LOCAL nCnt := 0
   LOCAL i
   LOCAL nDoc_no, nDoc_gr

   LEN_QTTY := Len( PIC_QTTY )
   LEN_VALUE := Len( PIC_VALUE )
   LEN_DIMENSION := Len( PIC_DIMENSION )

   RAZMAK := Space( 1 )

   t_rpt_open()

   SELECT t_docit
   SET ORDER TO TAG "2"
   GO TOP
   nDoc_no := field->doc_no

   // izvuci sve grupe....
   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      // grupa dokumenta
      nDoc_gr := field->doc_gr_no
      DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_gr_no == nDoc_gr

         SKIP
      ENDDO

      ++ nCnt
      AAdd( aGroups, { nDoc_gr, nCnt } )

   ENDDO

   IF !start_print()
      RETURN .F.
   ENDIF

   FOR i := 1 TO Len( aGroups )

      stampa_naloga_za_grupu( aGroups[ i, 1 ], aGroups[ i, 2 ], Len( aGroups ) )
      FF
   NEXT

   end_print()

   RETURN .T.


FUNCTION stampa_naloga_za_grupu( nDoc_gr, nGr_cnt, nGr_total )

   LOCAL lShow_zagl
   LOCAL i
   LOCAL nDocRbr := 0
   LOCAL nCount := 0
   LOCAL cDoc_it_type := ""
   LOCAL cRekPrint
   LOCAL lRekPrint := .F.
   LOCAL _qtty_total := 0

   nDuzStrKorekcija := 0
   lPrintedTotal := .F.

   nTTotal := Val( g_t_pars_opis( "N10" ) )

   cRekPrint := AllTrim( g_t_pars_opis( "N20" ) )
   IF cRekPrint == "D"
      lRekPrint := .T.
   ENDIF

   // zaglavlje naloga za proizvodnju
   nalpr_header( nGr_cnt, nGr_total )

   // podaci kupac i broj dokumenta itd....
   nalpr_kupac()

   B_ON

   ?
   cLine := g_line( 1 )

   // setuj len_ukupno
   LEN_TOTAL := Len( cLine )

   SELECT t_docit
   SET ORDER TO TAG "1"
   GO TOP

   // stampaj grupu artikala naloga
   s_art_group( nDoc_gr )

   // print header tabele
   s_tbl_header()

   SELECT t_docit
   SET ORDER TO TAG "2"
   nDoc_no := field->doc_no

   SEEK docno_str( nDoc_no ) + Str( nDoc_gr, 2 )

   nPage := 1
   aArt_desc := {}
   nArt_id := 0
   nArt_tmp := 0

   lSh_art_desc := .F.
   lSh_it_desc := .F.
   cTmpItDesc := ""
   cItDesc := ""

   nCount := 0

   // stampaj podatke
   DO WHILE !Eof() .AND. field->doc_no == nDoc_no .AND. field->doc_gr_no == nDoc_gr

      lAops := .F.

      nArt_id := field->art_id

      // dodaj prored samo ako je drugi artikal
      IF nCount > 0 .AND. !Empty( field->art_desc ) // lSh_art_desc == .t.

         ? cLine

      ENDIF

      cDoc_no := docno_str( field->doc_no )
      cDoc_it_no := docit_str( field->doc_it_no )
      cDoc_It_type := field->doc_it_typ


      // prikazuj naziv artikla
      IF !Empty( field->art_desc )     // lSh_art_desc == .t.
         cArt_desc := AllTrim( field->art_desc )
      ELSE
         cPom := "-//-"
         cArt_desc := PadC( cPom, 10 )
      ENDIF

      aArt_desc := SjeciStr( cArt_desc, LEN_DESC )

      // prvi red
      // 1) naziv i sifra artikla

      ? RAZMAK

      // r.br
      ?? PadL( AllTrim( Str( ++nDocRbr ) ) + ")", LEN_IT_NO )

      ?? " "

      // proizvod, naziv robe, jmj
      ?? AllTrim( aArt_desc[ 1 ] ) + " " + Replicate( ".", ( LEN_DESC - 1 ) - Len( AllTrim( aArt_desc[ 1 ] ) ) )

      // ostatak naziva artikla....
      // drugi red

      IF Len( aArt_desc ) > 1

         FOR i := 2 TO Len( aArt_desc )

            ? RAZMAK

            ?? PadL( "", LEN_IT_NO )

            ?? " "

            ?? aArt_desc[ i ]


            // provjeri za novu stranicu
            IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
               ++ nPage
               Nstr_a4( nPage, .T. )
            ENDIF
         NEXT

      ENDIF

      // zatim obrade i napomene obrada, operacije

      SELECT t_docop
      SET ORDER TO TAG "1"
      GO TOP
      SEEK docno_str( t_docit->doc_no ) + docit_str( t_docit->doc_it_no )


      DO WHILE !Eof() .AND. field->doc_no == t_docit->doc_no .AND. field->doc_it_no == t_docit->doc_it_no

         // uzmi element
         nDoc_el_no := field->doc_el_no

         nElDesc := 1
         nElCount := 0
         lSh_op_desc := .F.
         lSh_oper := .F.
         cOpTmpDesc := ""
         cDoc_op_desc := ""

         DO WHILE !Eof() .AND. field->doc_no == t_docit->doc_no .AND. field->doc_it_no == t_docit->doc_it_no .AND. field->doc_el_no == nDoc_el_no

            cDoc_op_desc := AllTrim( field->doc_op_des )

            // element...
            IF nElDesc == 1

               // provjeri za novu stranicu
               IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
                  ++ nPage
                  Nstr_a4( nPage, .T. )
               ENDIF

               ? RAZMAK
               ?? PadL( "", LEN_IT_NO )
               ?? " "
               B_ON
               ?? "obrada na " + Str( field->doc_el_no, 2 ) + ":"
               B_OFF
               ?? " "
               ?? AllTrim( field->doc_el_des )
               ?? ", "
               // prikazi lot broj
               ?? show_lot()

               // iskljuci ga do daljnjeg
               nElDesc := 0

               lAops := .T.

            ENDIF

            // provjeri za novu stranicu
            IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
               ++ nPage
               Nstr_a4( nPage, .T. )
            ENDIF

            // operacije....

            ? RAZMAK

            ?? PadL( "", LEN_IT_NO )

            ?? " "

            IF !Empty( field->aop_desc ) .AND. AllTrim( field->aop_desc ) <> "?????"
               ?? PadL( Str( ++nElCount, 3 ), 3 ) + ")" + Space( 1 ) + AllTrim( field->aop_desc )
            ENDIF

            IF !Empty( field->aop_att_de ) .AND. AllTrim( field->aop_att_de ) <> "?????"
               ?? ", "
               ?? AllTrim( field->aop_att_de )
               ?? ", "
               ?? AllTrim( field->aop_value )

            ENDIF

            IF !Empty( field->doc_op_des )

               cPom := "- napomene: "
               cPom += AllTrim( field->doc_op_des )
               aPom := SjeciStr( cPom, 70 )

               FOR i := 1 TO Len( aPom )

                  ? RAZMAK
                  ?? PadR( "", LEN_IT_NO )
                  ?? Space( 5 )
                  ?? aPom[ i ]

               NEXT

            ENDIF

            SELECT t_docop

            SKIP

         ENDDO

      ENDDO

      SELECT t_docit


      // lot broj ako nema operacija itd...
      IF lAops == .F. .AND. !Empty( field->art_desc )

         // provjeri za novu stranicu
         IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()

            ++ nPage
            Nstr_a4( nPage, .T. )

         ENDIF

         ? RAZMAK
         ?? PadL( "", LEN_IT_NO )
         ?? " "
         ?? show_lot()

         lAops := .T.
      ENDIF


      // zatim dimenzije

      IF lAops == .T.

         // ako postoje obrade u artiklu dodaj tackice

         // provjeri za novu stranicu
         IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()

            ++ nPage
            Nstr_a4( nPage, .T. )

         ENDIF

         ? RAZMAK
         ?? PadL( "", LEN_IT_NO )
         ?? " "
         ?? Replicate( ".", LEN_DESC  )

      ENDIF

      ?? " "

      IF cDoc_it_type == "R"

         // prikazi fi
         ?? PadL( show_fi( field->doc_it_wid, field->doc_it_hei ), 21 )

      ELSEIF cDoc_it_type == "S"

         ? RAZMAK
         ?? PadL( "", LEN_IT_NO )

         ?? " "
         ?? PadR( "", LEN_DESC - 10 )

         ?? " "
         // sirina 1 / 2
         ?? PadL( show_shape( field->doc_it_wid, field->doc_it_w2 ), 15 )
         ?? " "
         // visina 1 / 2
         ?? PadL( show_shape( field->doc_it_hei, field->doc_it_h2 ), 15 )

      ELSE

         // sirina
         ?? show_number( field->doc_it_wid, nil, -10 )

         ?? " "
         // visina
         ?? show_number( field->doc_it_hei, nil, -10 )

      ENDIF

      ?? " "

      // kolicina
      ?? show_number( field->doc_it_qtt, nil, -10 )

      _qtty_total += field->doc_it_qtt

      // napomene za item:
      // - napomene
      // - shema u prilogu

      IF !Empty( field->doc_it_des ) ;
            .OR. field->doc_it_alt <> 0 ;
            .OR. ( field->doc_it_sch == "D" )

         cPom := "Napomene: " + ;
            AllTrim( field->doc_it_des )

         IF field->doc_it_sch == "D"

            cPom += " "
            cPom += "(SHEMA U PRILOGU)"
         ENDIF

         // nadmorska visina
         IF field->doc_it_alt <> 0

            IF !Empty( field->doc_acity )
               cPom += " "
               cPom += "Montaza: "
               cPom += AllTrim( field->doc_acity )
            ENDIF

            cPom += ", "
            cPom += "nadmorska visina = " + AllTrim( Str( field->doc_it_alt, 12, 2 ) ) + " m"
         ENDIF

         cItDesc := cPom

         lSh_it_desc := .F.

         IF ( AllTrim( cTmpItDesc ) <> AllTrim( cItDesc ) ) .OR. ( nArt_tmp <> nArt_id )
            lSh_it_desc := .T.
         ENDIF

         IF lSh_it_desc == .T.

            aDoc_it_desc := SjeciStr( cItDesc, 100 )

            FOR i := 1 TO Len( aDoc_it_desc )

               ? RAZMAK
               ?? PadL( "", LEN_IT_NO )
               ?? " "
               ?? aDoc_it_desc[ i ]

            NEXT

         ENDIF
      ENDIF

      SELECT t_docit

      // provjeri za novu stranicu
      IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()

         ++ nPage
         Nstr_a4( nPage, .T. )

      ENDIF

      SELECT t_docit
      SKIP

      cTmpItDesc := cItDesc
      nArt_tmp := nArt_id

      ++ nCount

   ENDDO

   // provjeri za novu stranicu
   // treba mi 4 prazna mjesta
   IF PRow() + 4 > LEN_PAGE - DSTR_KOREKCIJA()
      ++nPage
      Nstr_a4( nPage, .T. )
   ENDIF

   ? cLine
   ? RAZMAK + PadR( "UKUPNA KOLICINA:", 90 ), show_number( _qtty_total, nil, -10 )
   ? cLine
   B_OFF
   ?

   s_nal_izdao()

   s_nal_footer()

   // stampa rekapitulacije
   s_nal_rekap( lRekPrint, nDoc_no )

   RETURN


// ---------------------------------------
// stampa rekapitulacije na dnu naloga
// ---------------------------------------
FUNCTION s_nal_rekap( lPrint, nDoc_no, lSpecif )

   LOCAL cTmp
   LOCAL nDoc

   IF lSpecif == nil
      lSpecif := .F.
   ENDIF

   IF lPrint == .F.
      RETURN
   ENDIF

   IF nDoc_no == nil
      nDoc_no := 0
   ENDIF

   SELECT t_docit2

   IF RECCOUNT2() == 0
      RETURN
   ENDIF

   P_COND

   ?
   ? RAZMAK + "rekapitulacija dodatnog materijala:"
   ? RAZMAK + "-----------------------------------"

   // if prow() > LEN_PAGE - DSTR_KOREKCIJA()
   // ++nPage
   // Nstr_a4(nPage, .t.)
   // endif

   GO TOP

   IF nDoc_no > 0
      SEEK docno_str( nDoc_no )
   ENDIF

   DO WHILE !Eof()

      IF nDoc_no > 0
         IF field->doc_no <> nDoc_no
            SKIP
            LOOP
         ENDIF
      ENDIF

      nDoc := field->doc_no
      nDoc_it_no := field->doc_it_no

      // da li se treba stampati ?
      SELECT t_docit
      SEEK docno_str( nDoc ) + docit_str( nDoc_it_no )

      IF field->print == "N"
         SELECT t_docit2
         SKIP
         LOOP
      ENDIF

      // vrati se
      SELECT t_docit2

      // if prow() > LEN_PAGE - DSTR_KOREKCIJA()
      // ++nPage
      // Nstr_a4(nPage, .t.)
      // endif

      ? RAZMAK + "nalog: " + AllTrim( Str( nDoc ) ) + ;
         ", stavka: " + AllTrim( Str( nDoc_it_no ) )
      ? RAZMAK + "----------------------------"

      DO WHILE !Eof() .AND. field->doc_no == nDoc ;
            .AND. field->doc_it_no == nDoc_it_no

         // sifra i naziv stavke
         cTmp := "("
         cTmp += AllTrim( field->art_id )
         cTmp += ")"
         cTmp += " "
         cTmp += AllTrim( field->art_desc )

         // opis stavke
         cTmp2 := AllTrim( field->descr )
         aTmp2 := SjeciStr( cTmp2, 120 )

         // if prow() > LEN_PAGE - DSTR_KOREKCIJA()
         // ++nPage
         // Nstr_a4(nPage, .t.)
         // endif

         ? RAZMAK
         ?? AllTrim( Str( field->it_no ) ) + "."
         ?? " "
         ?? PadR( cTmp, 40 )
         ?? " kol.=", AllTrim( Str( field->doc_it_qtt, 12, 2 ) )

         IF !Empty( cTmp2 )

            ? RAZMAK + Space( 2 ) + "op: "

            FOR i := 1 TO Len( aTmp2 )

               IF i > 1
                  ? RAZMAK + Space( 6 )
               ENDIF

               ?? aTmp2[ i ]

               // if prow() > LEN_PAGE - DSTR_KOREKCIJA()
               // ++nPage
               // Nstr_a4(nPage, .t.)
               // endif
            NEXT
         ENDIF

         SKIP
      ENDDO

   ENDDO

   RETURN


STATIC FUNCTION show_lot()

   LOCAL cReturn := ""

   cReturn += "proizv.: ______________"
   cReturn += ","
   cReturn += "LOT: _____________"

   RETURN cReturn




// --------------------------------------------
// prikaz fi iznosa na nalogu
// --------------------------------------------
STATIC FUNCTION show_fi( nWidth, nHeigh )

   LOCAL nFi := nWidth
   LOCAL nFi2 := nHeigh
   LOCAL cTmp := ""

   IF ( nFi + nFi2 ) = 0
      RETURN cTmp
   ENDIF

   cTmp := "fi= "

   IF nFi == nFi2
      cTmp += AllTrim( Str( nFi, 12, 2 ) )
   ELSE
      cTmp += AllTrim( Str( nFi, 12, 2 ) ) + ", " + ;
         AllTrim( Str( nFi2, 12, 2 ) )
   ENDIF

   RETURN cTmp




// --------------------------------------------
// prikaz shaped iznosa na nalogu
// --------------------------------------------
STATIC FUNCTION show_shape( nD1, nD2 )

   LOCAL cTmp := ""

   cTmp := AllTrim( Str( nD1, 12, 2 ) )
   cTmp += "/"
   cTmp += AllTrim( Str( nD2, 12, 2 ) )

   RETURN cTmp



// ----------------------------------------
// stampanje grupe artikala naloga
// ----------------------------------------
STATIC FUNCTION s_art_group( nGr )

   ? RAZMAK + "grupa artikala: (" + AllTrim( Str( nGr ) ) + ") - " + get_art_docgr( nGr )

   RETURN



// -------------------------------------------
// stampa potpisa nalog izdao
// -------------------------------------------
STATIC FUNCTION s_nal_izdao()

   LOCAL cPom := ""
   LOCAL cOper := ""

   // provjeri za novu stranicu
   IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
      ++ nPage
      Nstr_a4( nPage, .T. )
   ENDIF

   // izvuci operatera iz PARS
   cOper := g_t_pars_opis( "N13" )

   // nalog izdao
   cPom += "Nalog izdao: "
   cPom += PadC( cOper, 20 )
   cPom += ", stampao: "
   cPom += PadC( getfullusername( f18_get_user_id( f18_user() ) ), 20 )
   cPom += " "
   cPom += "Vrijeme: "
   cPom += PadR( Time(), 5 )

   ? PadL( cPom, LEN_TOTAL )

   RETURN


STATIC FUNCTION s_nal_footer()

   LOCAL cPom
   LOCAL cPayDesc := ""
   LOCAL cPayed := ""
   LOCAL cPayAddDesc := ""

   // provjeri za novu stranicu
   IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
      ++ nPage
      Nstr_a4( nPage, .T. )
   ENDIF

   cPayDesc := g_t_pars_opis( "N06" )
   cPayed := g_t_pars_opis( "N10" )
   cPayAddDesc := g_t_pars_opis( "N11" )

   // footer
   // vrsta placanja
   ? RAZMAK + "Vrsta placanja: " + cPayDesc

   // placeno D/N
   IF !Empty( cPayed ) .AND. AllTrim( cPayed ) <> "-"

      // provjeri za novu stranicu
      IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
         ++ nPage
         Nstr_a4( nPage, .T. )
      ENDIF

      cPom := "Placeno: "

      IF cPayed == "D"
         cPom += "DA"
      ELSE
         cPom += "NE"
      ENDIF

      ? RAZMAK + cPom

   ENDIF

   // dodatne napomene placanje
   IF !Empty( cPayAddDesc ) .AND. AllTrim( cPayAddDesc ) <> "-"

      // provjeri za novu stranicu
      IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
         ++ nPage
         Nstr_a4( nPage, .T. )
      ENDIF

      cPom := "Napomene za placanje: "
      cPom += cPayAddDesc

      ? RAZMAK + cPom

   ENDIF

   // provjeri za novu stranicu
   // treba mi 4 reda za ovaj ispis !
   IF PRow() + 4 > LEN_PAGE - DSTR_KOREKCIJA()
      ++ nPage
      Nstr_a4( nPage, .T. )
   ENDIF

   // oznacene pozicije na nalogu
   cPom := "Oznacene pozicije:"
   cPom += "      "
   cPom += "DA  /  NE"

   ? RAZMAK + cPom

   // konacan proizvod
   cPom := "Konacan proizvod: "
   cPom += "  VALIDAN  "
   cPom += "  NIJE VALIDAN  "
   cPom += " ovjerio: __________________ "
   cPom += ", vrijeme: _____________"

   ? RAZMAK + cPom

   ?
   ?

   // provjeri za novu stranicu
   IF PRow() > LEN_PAGE - DSTR_KOREKCIJA()
      ++ nPage
      Nstr_a4( nPage, .T. )
   ENDIF

   // potvrda narudzbe

   cPom := "Narucilac potvrdjuje narudzbu:"
   cPom += " "
   cPom += "_______________"
   cPom += " "
   cPom += "  Datum:"
   cPom += " "
   cPom += "_________"

   ? RAZMAK + cPom

   RETURN



// -----------------------------------------
// zaglavlje glavne tabele sa stavkama
// -----------------------------------------
STATIC FUNCTION s_tbl_header()

   LOCAL cLine
   LOCAL cRow1

   cLine := g_line( 1 )

   ? cLine

   cRow1 := RAZMAK
   cRow1 += PadC( "r.br", LEN_IT_NO )
   cRow1 += " " + PadR( "artikal/naziv/element/operacije/napomene", LEN_DESC )
   cRow1 += " " + PadC( "sirina(mm)", LEN_DIMENSION )
   cRow1 += " " + PadC( "visina(mm)", LEN_DIMENSION )
   cRow1 += " " + PadC( "kol. (kom)", LEN_QTTY )

   ? cRow1

   ? cLine

   RETURN


// -----------------------------------------
// funkcija za ispis headera
// -----------------------------------------
FUNCTION nalpr_header( nDocGr, nDocGrTot )

   LOCAL cDLHead
   LOCAL cSLHead
   LOCAL cINaziv
   LOCAL cRazmak := Space( 2 )
   LOCAL cDoc_no
   LOCAL _np := g_t_pars_opis( "N21" )

   // broj dokumenta
   cDoc_no := g_t_pars_opis( "N01" )

   // naziv
   cINaziv := AllTrim( gFNaziv )
   cINaziv += " : "
   cINaziv += "NALOG ZA PROIZVODNJU br."
   cINaziv += cDoc_no
   cINaziv += " "
   cINaziv += "("
   cINaziv += AllTrim( Str( nDocGr ) )
   cINaziv += "/"
   cINaziv += AllTrim( Str( nDocGrTot ) )
   cINaziv += ")"

   // double line header
   cDLHead := Replicate( "=", 70 )

   // single line header
   cSLHead := Replicate( "-", Len( gFNaziv ) )

   // prvo se pozicioniraj na g.marginu
   FOR i := 1 TO gDg_margina
      ?
   NEXT

   p_line( cRazmak + cDlhead, 10, .T. )
   p_line( cRazmak + cINaziv, 10, .T. )

   IF _np == "NP"
      p_line( cRazmak + hb_StrToUTF8( "NEUSKLADJEN PROIZVOD" ), 10, .T. )
   ENDIF

   p_line( cRazmak + cDlhead, 10, .T. )

   ?

   RETURN



// ----------------------------------------------
// funkcija za ispis podataka o kupcu
// dokument, datumi, hitnost itd..
// ----------------------------------------------
STATIC FUNCTION nalpr_kupac()

   LOCAL cDoc_date
   LOCAL cDoc_time
   LOCAL cDoc_dvr_date
   LOCAL cDoc_dvr_time
   LOCAL cDoc_ship_place
   LOCAL cPriority
   LOCAL cCust_desc
   LOCAL cCust_addr
   LOCAL cCust_tel
   LOCAL cContId
   LOCAL cCont_desc
   LOCAL cCont_tel
   LOCAL cContadesc
   LOCAL cCont_add_desc
   LOCAL cObjId
   LOCAL cObj_desc
   LOCAL cDoc_no
   LOCAL cRazmak := Space( 2 )
   LOCAL nLeft := 15
   LOCAL nRight := 8
   LOCAL i
   LOCAL cPom
   LOCAL aPom

   cDoc_date := g_t_pars_opis( "N02" )
   cDoc_time := g_t_pars_opis( "N12" )
   cDoc_dvr_date := g_t_pars_opis( "N03" )
   cDoc_dvr_time := g_t_pars_opis( "N04" )
   cPriority := g_t_pars_opis( "N05" )
   cDoc_ship_place := g_t_pars_opis( "N07" )
   cDoc_add_desc := g_t_pars_opis( "N08" )

   // get/set customer data
   cCustId := g_t_pars_opis( "P01" )
   cCust_desc := g_t_pars_opis( "P02" )
   cCust_addr := g_t_pars_opis( "P03" )
   cCust_tel := g_t_pars_opis( "P04" )

   // get/set contacts data
   cContId := g_t_pars_opis( "P10" )
   cCont_desc := g_t_pars_opis( "P11" )
   cCont_tel := g_t_pars_opis( "P12" )
   cContadesc := g_t_pars_opis( "P13" )
   cCont_add_desc := g_t_pars_opis( "N09" )

   // get/set objects data
   cObjId := g_t_pars_opis( "P20" )
   cObj_desc := g_t_pars_opis( "P21" )

   B_OFF

   // doc_date + doc_time + doc_dvr_date + doc_dvr_time
   cPom := "Datum/vrijeme naloga: "
   cPom += cDoc_date
   cPom += " "
   cPom += cDoc_time
   cPom += ",  "
   cPom += "Datum/vrijeme isporuke: "
   cPom += cDoc_dvr_date
   cPom += " "
   cPom += cDoc_dvr_time

   p_line( cRazmak + cPom, 12, .F. )


   // priority + sh_place
   cPom := "Prioritet: "
   cPom += cPriority
   cPom += ", "
   cPom += "Objekat: "
   cPom += cObj_desc
   cPom += ", "
   cPom += "Mjesto isp.: "
   cPom += cDoc_ship_place

   aPom := SjeciStr( cPom, 100 )

   FOR i := 1 TO Len( aPom )

      p_line( cRazmak + aPom[ i ], 12, .F. )

   NEXT

   // podaci narucioca
   cPom := "Narucioc: "
   cPom += AllTrim( cCust_desc )
   cPom += ", "
   cPom += AllTrim( cCust_addr )
   cPom += ", tel: "
   cPom += AllTrim( cCust_tel )

   p_line( cRazmak + cPom, 12, .F. )

   // podaci kontakta
   cPom := "Kontakt: "
   cPom += " " + AllTrim( cCont_desc ) + " (" + AllTrim( cContadesc ) + "), " + AllTrim( "tel: " + cCont_tel ) + ", " + AllTrim( cCont_add_desc )

   aPom := SjeciStr( cPom, 100 )

   FOR i := 1 TO Len( aPom )

      p_line( cRazmak + aPom[ i ], 12, .F. )

   NEXT

   // ostale napomene naloga...
   IF !Empty( cDoc_add_desc )

      cPom := "Ostale napomene: " + AllTrim( cDoc_add_desc )

      aPom := SjeciStr( cPom, 100 )

      FOR i := 1 TO Len( aPom )
         p_line( cRazmak + aPom[ i ], 12, .F. )
      NEXT

   ENDIF

   RETURN



// -----------------------------------------
// funkcija za novu stranu
// -----------------------------------------
FUNCTION NStr_a4( nPage, lShZagl )

   LOCAL cLine

   // idemo bez ostranicavanja
   // return

   cLine := g_line( 1 )

   // korekcija duzine je na svako strani razlicita
   nDuzStrKorekcija := 0

   // P_COND

   ? cLine
   p_line( " Prenos na sljedecu stranicu", 12, .F. )
   ? cLine

   FF

   // P_COND

   ? cLine
   IF nPage <> nil
      p_line( "       Strana:" + Str( nPage, 3 ), 12, .F. )
   ENDIF
   ? cLine

   RETURN


// --------------------------------
// korekcija za duzinu strane
// --------------------------------
FUNCTION DSTR_KOREKCIJA()

   LOCAL nPom

   nPom := Round( nDuzStrKorekcija, 0 )
   IF Round( nDuzStrKorekcija - nPom, 1 ) > 0.2
      nPom ++
   ENDIF

   RETURN nPom
