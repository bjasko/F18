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


#include "fakt.ch"

// staticke varijable
STATIC __generisati := .F.



FUNCTION GDokInv( cIdRj )

   LOCAL cIdRoba
   LOCAL cBrDok
   LOCAL nUl
   LOCAL nIzl
   LOCAL nRezerv
   LOCAL nRevers
   LOCAL nRbr
   LOCAL lFoundUPripremi

   O_FAKT_DOKS
   O_ROBA
   O_TARIFA
   O_FAKT_PRIPR
   SET ORDER TO TAG "3"

   O_FAKT
   MsgO( "scaniram tabelu fakt" )
   nRbr := 0

   GO TOP
   cBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   DO WHILE !Eof()
      IF ( field->idFirma <> cIdRj )
         SKIP
         LOOP
      ENDIF
      SELECT fakt_pripr
      cIdRoba := fakt->idRoba
      // vidi imali ovo u pripremi; ako ima stavka je obradjena
      SEEK cIdRj + cIdRoba
      lFoundUPripremi := Found()
      SELECT fakt
      PushWa()
      IF !( lFoundUPripremi )
         fakt_stanje_artikla( cIdRj, cIdroba, @nUl, @nIzl, @nRezerv, @nRevers, .T. )
         IF ( nUl - nIzl - nRevers ) <> 0
            SELECT fakt_pripr
            nRbr++
            ShowKorner( nRbr, 10 )
            cRbr := RedniBroj( nRbr )
            ApndInvItem( cIdRj, cIdRoba, cBrDok, nUl - nIzl - nRevers, cRbr )
         ENDIF
      ENDIF
      PopWa()
      SKIP
   ENDDO
   MsgC()

   my_close_all_dbf()

   RETURN




STATIC FUNCTION ApndInvItem( cIdRj, cIdRoba, cBrDok, nKolicina, cRbr )

   APPEND BLANK
   REPLACE idFirma WITH cIdRj
   REPLACE idRoba  WITH cIdRoba
   REPLACE datDok  WITH Date()
   REPLACE idTipDok WITH "IM"
   REPLACE serBr   WITH Str( nKolicina, 15, 4 )
   REPLACE kolicina WITH nKolicina
   REPLACE rBr WITH cRbr

   IF Val( cRbr ) == 1
      cTxt := ""
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, gNFirma )
      AddTxt( @cTxt, "RJ:" + cIdRj )
      AddTxt( @cTxt, gMjStr )
      REPLACE txt WITH cTxt
   ENDIF

   REPLACE brDok WITH cBrDok
   REPLACE dinDem WITH ValDomaca()

   SELECT roba
   SEEK cIdRoba

   SELECT fakt_pripr
   REPLACE cijena WITH roba->vpc

   RETURN


STATIC FUNCTION AddTxt( cTxt, cStr )

   cTxt := cTxt + Chr( 16 ) + cStr + Chr( 17 )

   RETURN NIL





/*! \fn GDokInvManjak(cIdRj, cBrDok)
 *  \param cIdRj - oznaka firme dokumenta IM na osnovu kojeg se generise dok.19
 *  \param cBrDok - broj dokumenta IM na osnovu kojeg se generise dok.19
 *  \brief Generacija dokumenta 19 tj. otpreme iz mag na osnovu dok. IM
 */
FUNCTION GDokInvManjak( cIdRj, cBrDok )

   LOCAL nRBr
   LOCAL nRazlikaKol
   LOCAL cRBr
   LOCAL cNoviBrDok

   nRBr := 0

   O_FAKT
   O_FAKT_PRIPR
   O_ROBA

   cNoviBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   SELECT fakt
   SET ORDER TO TAG "1"
   HSEEK cIdRj + "IM" + cBrDok

   DO WHILE ( !Eof() .AND. cIdRj + "IM" + cBrDok == fakt->( idFirma + idTipDok + brDok ) )
      nRazlikaKol := Val( fakt->serBr ) -fakt->kolicina
      IF ( Round( nRazlikaKol, 5 ) > 0 )
         SELECT roba
         HSEEK fakt->idRoba
         SELECT fakt_pripr
         nRBr++
         cRBr := RedniBroj( nRBr )
         ApndInvMItem( cIdRj, fakt->idRoba, cNoviBrDok, nRazlikaKol, cRBr )
      ENDIF
      SELECT fakt
      SKIP 1
   ENDDO

   IF ( nRBr > 0 )
      MsgBeep( "U pripremu je izgenerisan dokument otpreme manjka " + cIdRj + "-19-" + cNoviBrDok )
   ELSE
      MsgBeep( "Inventurom nije evidentiran manjak pa nije generisan nikakav dokument!" )
   ENDIF

   my_close_all_dbf()

   RETURN




/*! \fn ApndInvMItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
 *  \param cIdRj - oznaka firme dokumenta
 *  \param cIdRoba - sifra robe
 *  \param cBrDok - broj dokumenta
 *  \param nKolicina - kolicina tj.manjak
 *  \param cRbr - redni broj stavke
 *  \brief Dodavanje stavke dokumenta 19 za evidentiranje manjka po osnovu inventure
 */

STATIC FUNCTION ApndInvMItem( cIdRj, cIdRoba, cBrDok, nKolicina, cRbr )

   APPEND BLANK
   REPLACE idFirma WITH cIdRj
   REPLACE idRoba  WITH cIdRoba
   REPLACE datDok  WITH Date()
   REPLACE idTipDok WITH "19"
   REPLACE serBr   WITH ""
   REPLACE kolicina WITH nKolicina
   REPLACE rBr WITH cRbr

   IF ( Val( cRbr ) == 1 )
      cTxt := ""
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, gNFirma )
      AddTxt( @cTxt, "RJ:" + cIdRj )
      AddTxt( @cTxt, gMjStr )
      REPLACE txt WITH cTxt
   ENDIF

   REPLACE brDok WITH cBrDok
   REPLACE dinDem WITH ValDomaca()
   REPLACE cijena WITH roba->vpc

   RETURN





/*! \fn GDokInvVisak(cIdRj, cBrDok)
 *  \param cIdRj - oznaka firme dokumenta IM na osnovu kojeg se generise dok.19
 *  \param cBrDok - broj dokumenta IM na osnovu kojeg se generise dok.19
 *  \brief Generacija dokumenta 01 tj.primke u magacin na osnovu dok. IM
 */
FUNCTION GDokInvVisak( cIdRj, cBrDok )

   LOCAL nRBr
   LOCAL nRazlikaKol
   LOCAL cRBr
   LOCAL cNoviBrDok

   nRBr := 0

   O_FAKT
   O_FAKT_PRIPR
   O_ROBA

   cNoviBrDok := PadR( Replicate( "0", gNumDio ), 8 )

   SELECT fakt
   SET ORDER TO TAG "1"
   HSEEK cIdRj + "IM" + cBrDok
   DO WHILE ( !Eof() .AND. cIdRj + "IM" + cBrDok == fakt->( idFirma + idTipDok + brDok ) )
      nRazlikaKol := Val( fakt->serBr ) -fakt->kolicina
      IF ( Round( nRazlikaKol, 5 ) < 0 )
         SELECT roba
         HSEEK fakt->idRoba
         SELECT fakt_pripr
         nRBr++
         cRBr := RedniBroj( nRBr )
         ApndInvVItem( cIdRj, fakt->idRoba, cNoviBrDok, -nRazlikaKol, cRBr )
      ENDIF
      SELECT fakt
      SKIP 1
   ENDDO

   IF ( nRBr > 0 )
      MsgBeep( "U pripremu je izgenerisan dokument dopreme viska " + cIdRj + "-01-" + cNoviBrDok )
   ELSE
      MsgBeep( "Inventurom nije evidentiran visak pa nije generisan nikakav dokument!" )
   ENDIF

   my_close_all_dbf()

   RETURN





/*! \fn ApndInvVItem(cIdRj, cIdRoba, cBrDok, nKolicina, cRbr)
 *  \param cIdRj - oznaka firme dokumenta
 *  \param cIdRoba - sifra robe
 *  \param cBrDok - broj dokumenta
 *  \param nKolicina - kolicina tj.visak
 *  \param cRbr - redni broj stavke
 *  \brief Dodavanje stavke dokumenta 01 za evidentiranje viska po osnovu inventure
 */

STATIC FUNCTION ApndInvVItem( cIdRj, cIdRoba, cBrDok, nKolicina, cRbr )

   APPEND BLANK
   REPLACE idFirma WITH cIdRj
   REPLACE idRoba  WITH cIdRoba
   REPLACE datDok  WITH Date()
   REPLACE idTipDok WITH "01"
   REPLACE serBr   WITH ""
   REPLACE kolicina WITH nKolicina
   REPLACE rBr WITH cRbr

   IF ( Val( cRbr ) == 1 )
      cTxt := ""
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, "" )
      AddTxt( @cTxt, gNFirma )
      AddTxt( @cTxt, "RJ:" + cIdRj )
      AddTxt( @cTxt, gMjStr )
      REPLACE txt WITH cTxt
   ENDIF

   REPLACE brDok WITH cBrDok
   REPLACE dinDem WITH ValDomaca()
   REPLACE cijena WITH roba->vpc

   RETURN





// -----------------------------------------------------------
// generise racun na osnovu podataka iz pripreme
// -----------------------------------------------------------
FUNCTION fakt_generisi_racun_iz_pripreme()

   LOCAL _novi_tip, _tip_dok, _br_dok
   LOCAL _t_rec

   IF !( field->idtipdok $ "12#20#13#01#27" )
      Msg( "Ova opcija je za promjenu 20,12,13 -> 10 i 27 -> 11 " )
      RETURN .F.
   ENDIF

   IF field->idtipdok = "27"
      _novi_tip := "11"
   ELSEIF field->idtipdok = "01"
      _novi_tip := "19"
   ELSE
      _novi_tip := "10"
   ENDIF

   IF Pitanje(, "Želite li dokument pretvoriti u " + _novi_tip + " ? (D/N)", "D" ) == "N"
      RETURN .F.
   ENDIF

   Box(, 5, 60 )

   _tip_dok := field->idtipdok
   _br_dok := PadR( Replicate( "0", 5 ), 8 )

   SELECT fakt_pripr
   PushWa()

   GO TOP
   _t_rec := 0

   my_flock()

   DO WHILE !Eof()

      SKIP
      _t_rec := RecNo()
      SKIP -1

      REPLACE field->brdok WITH _br_dok
      REPLACE field->idtipdok WITH _novi_tip
      REPLACE field->datdok WITH Date()

      IF _tip_dok == "12"
         // otpremnica u racun ???
         REPLACE serbr WITH "*"
      ENDIF

      IF _tip_dok == "13"
         REPLACE kolicina WITH -kolicina
      ENDIF

      GO ( _t_rec )
   	
   ENDDO

   my_unlock()

   PopWa()

   BoxC()

   IsprUzorTxt()

   RETURN .T.


