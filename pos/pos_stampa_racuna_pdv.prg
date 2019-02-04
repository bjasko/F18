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

FUNCTION pos_stampa_racuna_pdv( hParams )

   LOCAL cVrijeme

   pos_napuni_drn_rn_dbf( hParams )

   IF !fiscal_opt_active() // fiskalni racun - ne stampati !
      pos_racun_print()
   ENDIF

   RETURN cVrijeme


FUNCTION pos_napuni_drn_rn_dbf( hParams )

   LOCAL cPosDB

   //LOCAL cSmjena
   LOCAL cIdRoba
   LOCAL cIdTarifa
   LOCAL cRobaNaz
   LOCAL nRbr

   // rn vars
   LOCAL nCjenBPDV
   LOCAL nCjenPDV
   LOCAL nKolicina
   LOCAL nPopust
   LOCAL nCjen2BPDV
   LOCAL nCjen2PDV
   LOCAL nVPDV
   LOCAL nPPDV
   LOCAL nPDV, nIznPop

   LOCAL nUkStavka
   LOCAL nUkupno
   LOCAL cJmj

   // drn vars
   LOCAL nUBPDV
   LOCAL nUPDV
   LOCAL nUPopust
   LOCAL nUBPDVPopust
   LOCAL nUTotal
   LOCAL nCSum
   LOCAL cRdnkNaz := ""
   LOCAL nZakBr := 0
   LOCAL nFZaokr := 0
   LOCAL i
   LOCAL cIdPos := hParams[ "idpos" ]
   LOCAL dDatum := hParams[ "datum" ]
   LOCAL cBrDok := hParams[ "brdok" ]
   LOCAL cIdRadnik := hParams[ "idradnik" ]
   LOCAL cIdVrsteP := hParams[ "idvrstep" ]
   LOCAL cVrijeme := hParams[ "vrijeme" ]

   close_open_racun_tbl()
   zap_racun_tbl()
   firma_params_fill()
   gvars_fill()

   IF hParams[ "priprema" ]
      SELECT _pos_pripr
   ELSE
      SELECT pos
   ENDIF

   // checksum
   nCSum := 0
   nUkupno := 0
   nUkStavka := 0
   nUBPDV := 0
   nUPDV := 0
   nUPopust := 0
   nUBPDVPopust := 0
   nUTotal := 0

   IF !hParams[ "priprema" ]
      seek_pos_pos( cIdPos, POS_VD_RACUN, dDatum, cBrDok )
      SELECT pos_doks
      //cVrijeme := pos_doks->vrijeme
      //cIdVrsteP := pos_doks->idvrstep
   ELSE
      SELECT _pos_pripr
      SET ORDER TO TAG "1"
      GO TOP
      SEEK cIdPos + POS_VD_RACUN + DToS( dDatum ) + cBrDok
      //cVrijeme := Left( Time(), 5 )
      //cIdVrsteP := _pos->idvrstep
   ENDIF


   find_pos_osob_by_naz( cIdRadnik )
   cRdnkNaz := osob->naz

   IF !select_o_vrstep( cIdVrsteP )
      cNazVrstaP := "GOTOVINA"
   ELSE
      cNazVrstaP := AllTrim( vrstep->naz )
   ENDIF

   IF hParams[ "priprema" ]
      SELECT _pos_pripr
   ELSE
      SELECT pos
   ENDIF

   AltD()
   DO WHILE !Eof() .AND. iif( !hParams[ "priprema" ], ;
         ( pos->idpos + pos->idvd + DToS( pos->datum ) + pos->brdok ) == ( cIdPos + POS_VD_RACUN + DToS( dDatum ) + cBrDok ), ;
         ( _pos_pripr->idpos + _pos_pripr->idvd + DToS( _pos_pripr->datum ) + _pos_pripr->brdok ) == ( cIdPos + POS_VD_RACUN + DToS( dDatum ) + cBrDok ) )

      nCjenBPDV := 0
      nCjenPDV := 0
      nKolicina := 0
      nPopust := 0
      nCjen2BPDV := 0
      nCjen2PDV := 0
      nPDV := 0
      nIznPop := 0

      cIdRoba := field->idroba
      cIdTarifa := field->idtarifa

      select_o_roba( cIdRoba )
      cJmj := roba->jmj
      cRobaNaz := AllTrim( roba->naz )
      select_o_tarifa( cIdTarifa )
      nPPDV := tarifa->opp

      nStPP := 0

      IF hParams[ "priprema" ]
         SELECT _POS_PRIPR
      ELSE
         SELECT pos
      ENDIF

      nKolicina := kolicina
      nCjenPDV :=  cijena
      nCjenBPDV := nCjenPDV / ( 1 + ( nPPDV + nStPP ) / 100 )
      nIznPop := field->ncijena

      nPopust := 0

      IF Round( nIznPop, 4 ) <> 0
         // cjena 2 : cjena sa pdv - iznos popusta
         nCjen2PDV := nCjenPDV - nIznPop
         // cjena 2 : cjena bez pdv - iznos popusta bez pdv
         nCjen2BPDV := nCjenBPDV - ( nIznPop / ( 1 + nPPDV / 100 ) )
         // procenat popusta
         nPopust := ( ( nIznPop / ( 1 + nPPDV / 100 ) ) / nCjenBPDV ) * 100

      ENDIF

      // izracunaj ukupno za stavku
      nUkupno := ( nKolicina * nCjenPDV ) - ( nKolicina * nIznPop )

      // izracunaj ukupnu vrijednost pdv-a
      nVPDV := ( ( nKolicina * nCjenBPDV ) - ( nKolicina * ( nIznPop / ( 1 + nPPDV / 100 ) ) ) ) * ( nPPDV / 100 )

      // ukupno bez pdv-a
      nUBPDV += nKolicina * nCjenBPDV
      // ukupno pdv
      nUPDV += nVPDV
      // total racuna
      nUTotal += nUkupno

      IF Round( nCjen2BPDV, 2 ) <> 0
         // ukupno popust
         nUPopust += ( nCjenBPDV - nCjen2BPDV ) * nKolicina
      ENDIF

      // ukupno bez pdv-a - popust
      nUBPDVPopust := nUBPDV - nUPopust

      IF grbCjen == 2
         nUkStavka := nUkupno
      ELSE
         nUkStavka := nUBPDVPopust
      ENDIF

      ++nCSum

      // cre_porezna_faktura_dbf.prg
      dodaj_stavku_racuna( cBrDok, Str( nCSum, 3 ), "", cIdRoba, cRobaNaz, cJmj, nKolicina, Round( nCjenPDV, 3 ), Round( nCjenBPDV, 3 ), Round( nCjen2PDV, 3 ), Round( nCjen2BPDV, 3 ), Round( nPopust, 2 ), Round( nPPDV, 2 ), Round( nVPDV, 3 ), Round( nUkStavka, 3 ), 0, 0 )

      IF hParams[ "priprema" ]
         SELECT _pos_pripr
      ELSE
         SELECT pos
      ENDIF
      SKIP

   ENDDO

   // dodaj zapis u drn.dbf
   add_drn( cBrDok, dDatum, NIL, NIL, cVrijeme, Round( nUBPDV, 2 ), Round( nUPopust, 2 ), Round( nUBPDVPopust, 2 ), Round( nUPDV, 2 ), Round( nUTotal - nFZaokr, 2 ), nCSum, 0, nFZaokr, 0 )
   // mjesto nastanka racuna
   add_drntext( "R01", gRnMjesto )
   // dodaj naziv radnika
   add_drntext( "R02", cRdnkNaz )

   // vrsta placanja
   add_drntext( "R05", cNazVrstaP )
   // dodatni text na racunu 3 linije
   add_drntext( "R06", gRnPTxt1 )
   add_drntext( "R07", gRnPTxt2 )
   add_drntext( "R08", gRnPTxt3 )
   // Broj linija potrebnih da se ocjepi traka
   add_drntext( "P12", AllTrim( Str( nFeedLines ) ) )
   // sekv.za otvaranje ladice
   add_drntext( "P13", gOtvorStr )
   // sekv.za cjepanje trake
   add_drntext( "P14", gSjeciStr )

   IF hParams[ "priprema" ]
      add_drntext( "D01", "P" ) // racun u pripremi
   ELSE
      // add_drntext( "K01", dokspf->knaz ) // podaci o kupcu
      // add_drntext( "K02", dokspf->kadr )
      // add_drntext( "K03", dokspf->kidbr )
      add_drntext( "D01", "A" ) // prepis racuna
   ENDIF

   RETURN .T.


STATIC FUNCTION gvars_fill()

   add_drntext( "P20", AllTrim( Str( grbCjen ) ) ) // prikaz cijene sa pdv, bez pdv
   add_drntext( "P21", grbStId ) // stampa id robe na racunu
   add_drntext( "P22", AllTrim( Str( grbReduk ) ) ) // redukcija trake

   RETURN .T.

STATIC FUNCTION firma_params_fill()

   add_drntext( "I01", gFirNaziv )
   add_drntext( "I02", gFirAdres )
   add_drntext( "I03", gFirIdBroj )
   add_drntext( "I04", gFirPM )
   add_drntext( "I05", gFirTel )

   RETURN .T.
