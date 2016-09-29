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

MEMVAR gFirma
MEMVAR Ch
MEMVAR m_x, m_y
MEMVAR _idfirma, _opis, _d_p, _iznosbhd, _idrj, _idpartner, _idkonto


FUNCTION knjizenje_gen_otvorene_stavke()

   LOCAL lGenerisano
   LOCAL nNaz := 1
   LOCAL nRec := RecNo()
   LOCAL _col, _row
   LOCAL _rec, _i
   LOCAL nCnt
   LOCAL cBrDok, cOtvSt, dDatDok
   LOCAL hParams
   LOCAL lAsistJednaStavka, lSumirano, nZbir
   LOCAL cPrirkto
   LOCAL lMarker3
   LOCAL nDug, nPot, nDug2, nPot2
   LOCAL nUDug2, nUPot2, nUDug, nUPot
   LOCAL nIznos
   LOCAL nUkDugBHD, nUkPotBHD
   LOCAL cIdFirma, cIdPartner, cIdKonto, cDugPot, cOpis, cIdRj
   LOCAL nRbr, pRegex, aMatch

   LOCAL aFaktura

   lAsistJednaStavka := .T.
   lSumirano := .F.
   nZbir := 0
   nZbir := oasist_provjeri_duple_partnere( _idpartner, _idkonto, _d_p, @lAsistJednaStavka, @lSumirano )

   IF nZbir > 0 .AND. !lAsistJednaStavka
      MsgBeep( "Na dokumentu postoje dvije ili vise uplata#za istog kupca. Asistent onemogucen!" )
      RETURN ( NIL )
   ENDIF

   cIdFirma := gFirma
   cIdPartner := _idpartner

   AltD()

   IF nZbir <> 0
      IF fin_pripr_nova_stavka()
         nIznos := _iznosbhd + nZbir
      ELSE
         nIznos := _iznosbhd
      ENDIF
   ELSE
      nIznos := _iznosbhd
   ENDIF

   cDugPot := _d_p
   cOpis := _opis

   IF gRJ == "D"
      cIdRj := _idrj
   ENDIF

   IF gTroskovi == "D"
      cFunk := _Funk
      cFond := _Fond
   ENDIF

   picD := FormPicL( "9 " + gPicBHD, 14 )
   picDEM := FormPicL( "9 " + gPicDEM, 9 )

   cIdKonto := _idkonto
   cIdFirma := Left( cIdFirma, 2 )

   // SELECT ( F_SUBAN )
   // USE
   // o_suban()

   // SELECT suban
   // SET ORDER TO TAG "1" // IdFirma+IdKonto+IdPartner+dtos(DatDok)+BrNal+str(RBr,5)

   // GO TOP

   Box(, 20, 77 )  // main box ostav

   @ m_x, m_y + 10 SAY8 "KONSULTOVANJE OTVORENIH STAVKI PRI KNJŽENJU"

#ifdef F18_DEBUG_FIN_AZUR
   AltD() // F18_DEBUG_FIN_AZUR
#endif

   fin_cre_open_dbf_ostav()
   // my_flock()

   nUkDugBHD := 0
   nUkPotBHD := 0

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   hParams := hb_Hash()
   hParams[ "idfirma" ] := cIdFirma
   hParams[ "idkonto" ] := cIdKonto
   hParams[ "idpartner" ] := cIdPartner
   hParams[ "otvst" ] := " "
   hParams[ "order_by" ] := "IdFirma,IdKonto,IdPartner,brdok"
   find_suban_by_konto_partner( @hParams  )
   MsgC()

   dDatDok := CToD( "" )
   cPrirkto := "1"  // priroda konta - dugovni 1, potrazni 2

   SELECT ( F_TRFP2 )
   IF !Used()
      O_TRFP2
   ENDIF

   HSEEK "99 " + Left( cIdKonto, 1 )

   DO WHILE !Eof() .AND. field->idvd == "99" .AND. Trim( field->idkonto ) != Left( cIdKonto, Len( Trim( field->idkonto ) ) )
      SKIP 1
   ENDDO

   IF field->idvd == "99" .AND. Trim( field->idkonto ) == Left( cIdKonto, Len( Trim( field->idkonto ) ) )
      cPrirkto := field->d_p
   ELSE
      IF cIdKonto = "21"
         cPrirkto := "1"
      ELSE
         cPrirkto := "2"
      ENDIF
   ENDIF

   SELECT suban

   nUDug2 := 0
   nUPot2 := 0
   nUDug := 0
   nUPot := 0

   // fPrviprolaz := .T.
   SELECT ostav
   my_flock()
   SELECT SUBAN

   nCnt := 0
   Box( , 1, 40 ) // do while
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. cIdKonto == field->idkonto .AND. cIdPartner == field->idpartner

      cBrDok := field->brdok
      cOtvSt := field->otvst
      dDatDok := Max( fix_dat_var( field->datval, .T. ), fix_dat_var( field->datdok, .T. ) )

      nDug2 := 0
      nPot2 := 0
      nDug := 0
      nPot := 0

      ++nCnt
      IF nCnt % 500 == 0
         @ m_x + 1, m_y + 2 SAY "suban: "
         @ m_x + 1, Col() + 2 SAY nCnt PICT "99999"
      ENDIF
      aFaktura := { CToD( "" ), CToD( "" ), CToD( "" ) }

      DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. cIdKonto == field->idkonto .AND. cIdPartner == field->idpartner ;
            .AND. field->brdok == cBrDok

         dDatDok := Min( Max( fix_dat_var( field->datval, .T. ), fix_dat_var( field->datdok, .T. ) ), dDatDok )

         IF field->d_p == "1"
            nDug += field->IznosBHD
            nDug2 += field->IznosDEM
         ELSE
            nPot += field->IznosBHD
            nPot2 += field->IznosDEM
         ENDIF

         IF field->d_p == cPrirKto
            aFaktura[ 1 ] := field->DATDOK
            aFaktura[ 2 ] := fix_dat_var( field->DATVAL, .T. )
         ENDIF

         IF aFaktura[ 3 ] < field->DatDok
            aFaktura[ 3 ] := field->DatDok   // datum zadnje promjene
         ENDIF

         SKIP

      ENDDO

      IF Round( nDug - nPot, 2 ) <> 0

         SELECT ostav
         APPEND BLANK
         REPLACE field->iznosbhd with ( nDug - nPot ), ;
            field->datdok WITH aFaktura[ 1 ], ;
            field->datval WITH aFaktura[ 2 ], ;
            field->datzpr WITH aFaktura[ 3 ], ;
            field->brdok WITH cBrDok

         IF ( cDugPot == "2" )
            REPLACE field->d_p WITH "1"
         ELSE
            REPLACE field->d_p WITH "2", field->iznosbhd WITH -field->iznosbhd
         ENDIF

         SELECT suban

      ENDIF

   ENDDO

   SELECT ostav
   my_unlock()
   BoxC() // do-while

   ImeKol := {}

   AAdd( ImeKol, { "Br.Veze",     {|| field->BrDok }   } )
   AAdd( ImeKol, { "Dat.Dok.",   {|| field->DatDok }  } )
   AAdd( ImeKol, { "Dat.Val.",   {|| field->DatVal }  } )
   AAdd( ImeKol, { "Dat.ZPR.",   {|| field->DatZPR }   } )
   AAdd( ImeKol, { PadR( "Duguje " + AllTrim( ValDomaca() ), 14 ), {|| Str( ( iif( D_P == "1", iznosbhd, 0 ) ), 14, 2 ) }     } )
   AAdd( ImeKol, { PadR( "Potraz." + AllTrim( ValDomaca() ), 14 ), {|| Str( ( iif( D_P == "2", iznosbhd, 0 ) ), 14, 2 ) }     } )
   AAdd( ImeKol, { PadR( "Uplaceno", 14 ), {|| Str( field->uplaceno, 14, 2 ) }     } )

   Kol := {}

   FOR _i := 1 TO Len( ImeKol )
      AAdd( Kol, _i )
   NEXT

   _row := MAXROWS() - 10
   _col := MAXCOLS() - 8

   Box(, _row, _col, .T. ) // rucni asistent

   SET CURSOR ON
   @ m_x + _row - 2, m_y + 1 SAY "<Enter> Izaberi/ostavi stavku"
   @ m_x + _row - 1, m_y + 1 SAY "<F10>   Asistent"
   @ m_x + _row,    m_y + 1 SAY ""

   ?? "  IZNOS Koji zatvaramo: " + iif( cDugPot == "1", "duguje", "potrazuje" ) + " " + AllTrim( Str( nIznos ) )

   PRIVATE cPomBrDok := Space( 10 )

   SELECT ostav
   GO TOP

   my_db_edit( "KOStav", _row, _col, {|| oasist_key_handler( nIznos, cDugPot ) }, "", "Otvorene stavke.", , , , {|| field->m2 = '3' }, 3 )

   BoxC() // rucni asistent

   SELECT ostav
   nNaz := Kurs( _datdok )

   lMarker3 := .F.

   GO TOP
   DO WHILE !Eof()
      IF field->m2 = "3"
         lMarker3 := .T.
         EXIT
      ENDIF
      SKIP
   ENDDO

   lGenerisano := .F.

   BoxC() // main box ostav end

   IF !lMarker3 .OR. Pitanje( "", "Izgenerisati stavke u nalogu za knjiženje ?", "D" ) == "N"
      SELECT OSTAV
      USE
      SELECT fin_pripr
      RETURN .F.
   ENDIF


   SELECT ( F_OSTAV )
   GO TOP

   SELECT fin_pripr
   my_flock()

   SELECT ostav

   DO WHILE !Eof()

      IF field->m2 == "3"

         REPLACE field->m2 WITH ""

         SELECT fin_pripr
         IF lGenerisano
            APPEND BLANK
         ELSE
            IF !fin_pripr_nova_stavka()
               IF lSumirano
                  APPEND BLANK
               ELSE
                  GO nRec
               ENDIF
            ELSE
               APPEND BLANK
            ENDIF
            lGenerisano := .T. // prvi put

         ENDIF

         Scatter( "w" )
         wIdfirma  := cIdfirma
         wIdvn     := _idvn
         wBrnal    := _brnal
         wIdtipdok := _idtipdok
         wDatVal   := CToD( "" )
         wDatDok   := _datdok
         wOpis     := ""
         wIdkonto  := cIdKonto
         wIdpartner := cIdPartner
         wOpis     := cOpis
         wk1       := _k1
         wk2       := _k2
         wk3       := K3U256( _k3 )
         wk4       := _k4
         wm1       := _m1

         IF gRJ == "D"
            wIdrj := cIdRj
         ENDIF

         IF gTroskovi == "D"
            wFunk := cFunk
            wFond := cFond
         ENDIF

         wRbr := fin_pripr_redni_broj()
         fin_pripr_redni_broj( wRbr + 1 )

         wd_p      := _D_p
         wIznosBhd := ostav->uplaceno
         wBrDok    := ostav->brdok

         pRegex := hb_regexComp( " DIO RN (.*);" )
         aMatch := hb_regex( pRegex, cOpis )
         IF Len( aMatch ) > 0 // aMatch[1]="DIO RN 666222;", aMatch[2]=666222
            cOpis := StrTran( cOpis, aMatch[ 1 ], "" ) // brisanje stare verzije
            wOpis := cOpis
         ENDIF

         IF ostav->uplaceno <> ostav->iznosbhd // dio racuna
            wOpis := Trim( cOpis )
            wOpis += " DIO RN " + Trim( wBrDok ) + ";"
         ENDIF

         wIznosdem := iif( Round( nNaz, 4 ) == 0, 0, wiznosBhd / nNaz )

         Gather( "w" )

         SELECT ( F_OSTAV )

      ENDIF

      SKIP 1

   ENDDO


   IF lGenerisano

      nRbr := fin_pripr_redni_broj()
      fin_pripr_redni_broj( nRbr - 1 )

      SELECT ( F_FIN_PRIPR )
      Scatter()
      IF fin_pripr_nova_stavka()
         my_delete()
      ELSE
         // my_rlock() // pa ga za svaki slucaj pohrani
         Gather()
         // my_unlock()
      ENDIF

      _k3 := K3Iz256( _k3 )

      ShowGets()

   ENDIF

   // SELECT ( F_OSTAV )
   // my_unlock()
   // USE

   SELECT ( F_FIN_PRIPR )
   my_unlock()

   IF !lGenerisano
      IF !Used()
         o_fin_edit()
         SELECT ( F_FIN_PRIPR )
      ENDIF
      GO nRec
   ENDIF

   SELECT OSTAV
   USE
   SELECT fin_pripr

   RETURN .T.


FUNCTION fin_pripr_nova_stavka()

   RETURN fNovi



// brisanje zapisa idfirma "XX"
STATIC FUNCTION _del_nal_xx()

   LOCAL nTArea := Select()
   LOCAL nTREC := RecNo()

   SELECT fin_pripr
   SET ORDER TO TAG "1"
   GO TOP

   SEEK "XX"

   DO WHILE !Eof() .AND. field->idfirma == "XX"

      IF field->rbr == 0
         my_delete()
      ENDIF

      SKIP
   ENDDO

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN .T.




STATIC FUNCTION oasist_key_handler( nIznos, cDugPot )

   LOCAL cOldBrDok := ""
   LOCAL cBrdok := ""
   LOCAL nTrec
   LOCAL cDn := "N"
   LOCAL nRet := DE_CONT
   LOCAL GetList := {}
   LOCAL _rec
   LOCAL nUplaceno
   LOCAL nPredhodniIznos

   DO CASE

   CASE Ch == K_F2

      IF pitanje(, "Izvrsiti ispravku broja veze u SUBAN ?", "N" ) == "D"

         cOldBrDok := field->BRDOK
         cBrDok := field->BRDOK

         Box(, 2, 60 )
         @ m_x + 1, m_Y + 2 SAY "Novi broj veze:" GET cBRDok
         READ
         BoxC()

         IF LastKey() <> K_ESC

            PushWA()


            find_suban_by_konto_partner( _idfirma, _idkonto, _idpartner, cOldBrDok, "IdFirma,IdKonto,IdPartner,brdok" )
            DO WHILE !Eof() .AND. _idfirma + _idkonto + _idpartner + cOldBrDok == field->idfirma + field->idkonto + field->idpartner + field->brdok

               SKIP
               nTrec := RecNo()
               SKIP -1

               _rec := dbf_get_rec()
               _rec[ "brdok" ] := cBrDok

               update_rec_server_and_dbf( "fin_suban", _rec, 1, "FULL" )
               GO nTRec

            ENDDO

            PopWa()

            SELECT ostav
            _rec := dbf_get_rec()
            _rec[ "brdok" ] := cBrDok
            dbf_update_rec( _rec )

            nRet := DE_ABORT

            MsgBeep( "Nakon ispravke morate ponovo pokrenuti asistenta sa <a-O>  !" )

         ENDIF

      ELSE

         nRet := DE_REFRESH

      ENDIF

   CASE Ch == K_CTRL_T

      IF Pitanje(, "Izbrisati stavku ?", "N" ) == "D"
         my_delete()
         nRet := DE_REFRESH
      ELSE
         nRet := DE_CONT
      ENDIF

   CASE Ch == K_ENTER

      IF field->uplaceno == 0
         nUplaceno := field->iznosbhd
      ELSE
         nUplaceno := field->uplaceno
      ENDIF

      Box(, 2, 60 )
      @ m_x + 1, m_y + 2 SAY "Uplaceno po ovom dokumentu:" GET nUplaceno PICT "999999999.99"
      READ
      Boxc()

      IF LastKey() <> K_ESC
         IF nUplaceno <> 0
            RREPLACE m2 WITH "3", uplaceno WITH nUplaceno
         ELSE
            RREPLACE m2 WITH "", uplaceno WITH 0
         ENDIF
      ENDIF

      nRet := DE_REFRESH

   CASE Ch == K_F10

      SELECT ostav
      GO TOP

      IF Pitanje(, "Asistent zatvara stavke ( " + AllTrim( say_iznos( nIznos ) ) + " KM) ?", "D" ) == "D"

         nPredhodniIznos := nIznos

         GO TOP
         my_flock()
         DO WHILE !Eof()
            IF cDugPot <> field->d_p .AND. nPredhodniIznos > 0
               nUplaceno := Min( field->iznosbhd, nPredhodniIznos )
               REPLACE m2 WITH "3"
               REPLACE uplaceno WITH nUplaceno
               nPredhodniIznos -= nUplaceno
            ELSE
               REPLACE m2 WITH ""
            ENDIF
            SKIP 1
         ENDDO
         my_unlock()

         GO TOP
         IF nPredhodniIznos > 0

            // ostao si u avansu
            APPEND BLANK
            Scatter( "w" )
            wbrdok := PadR( "AVANS", 10 )

            IF cDugPot == "1"
               wd_p := "1"
            ELSE
               wd_p := "2"
            ENDIF

            wiznosbhd := nPredhodniIznos
            wuplaceno := nPredhodniIznos
            wdatdok := Date()
            wm2 := "3"

            Box(, 2, 60 )
            @ m_x + 1, m_y + 2 SAY  "Ostatak sredstava knjiziti na dokument:" GET wbrdok
            READ
            Boxc()

            gather( "w" )

         ENDIF

      ENDIF

      nRet := DE_REFRESH

   ENDCASE

   RETURN nRet



STATIC FUNCTION oasist_provjeri_duple_partnere( cIdPartner, cIdKonto, cDp, lAsistJednaStavka, lSumirano )

   LOCAL nSuma, nCnt, nTot

   SELECT fin_pripr
   GO TOP

   nCnt := 0
   nSuma := 0

   lNovaStavka := fin_pripr_nova_stavka()

   IF lNovaStavka
      nTot := 0
   ELSE
      nTot := 1
   ENDIF

   DO WHILE !Eof()
      IF field->idpartner == cIdPartner .AND. field->idkonto == cIdKonto .AND. field->d_p == cDp
         ++ nCnt
         nSuma += field->iznosbhd
      ENDIF
      SKIP
   ENDDO

   IF ( nCnt > nTot ) // ima vise stavki za jednog partnera

      IF  Pitanje(, "Spojiti duple uplate za partnera?", "D" ) == "D"
         GO TOP
         DO WHILE !Eof()
            IF field->idpartner == cIdPartner .AND. field->idkonto == cIdKonto .AND. field->d_p == cDp
               my_delete()
            ENDIF
            SKIP
         ENDDO
         lSumirano := .T.
      ELSE
         lAsistJednaStavka := .F.
         RETURN nSuma
      ENDIF

   ENDIF

   RETURN nSuma


STATIC FUNCTION fin_cre_open_dbf_ostav()

   LOCAL _dbf
   LOCAL _ret := .T.
   LOCAL _table := "ostav"

   // formiraj datoteku ostav
   _dbf := {}
   AAdd( _dbf, { 'DATDOK', 'D',   8,  0 } )
   AAdd( _dbf, { 'DATVAL', 'D',   8,  0 } )
   AAdd( _dbf, { 'DATZPR', 'D',   8,  0 } )
   AAdd( _dbf, { 'BRDOK', 'C',   10,  0 } )
   AAdd( _dbf, { 'D_P', 'C',   1,  0 } )
   AAdd( _dbf, { 'IZNOSBHD', 'N',  21,  2 } )
   AAdd( _dbf, { 'UPLACENO', 'N',  21,  2 } )
   AAdd( _dbf, { 'M2', 'C',  1, 0 } )

   dbCreate( my_home() + my_dbf_prefix() + _table + ".dbf", _dbf )

   SELECT ( F_OSTAV )
   USE

   my_use_temp( "OSTAV", my_home() + my_dbf_prefix() + _table, .F., .T. )

   INDEX ON DToS( DatDok ) + DToS( iif( Empty( datval ), datdok, datval ) ) + brdok TAG "1"

   RETURN _ret
