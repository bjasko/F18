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

#include "ld.ch"



FUNCTION ld_unos_obracuna()

   LOCAL lSaveObracun
   LOCAL _vals
   LOCAL _fields
   LOCAL _pr_kart_pl := fetch_metric( "ld_obracun_prikaz_kartice_na_unosu", nil, "N" )
   PRIVATE lNovi
   PRIVATE GetList
   PRIVATE cIdRadn
   PRIVATE nPlacenoRSati

   cIdRadn := Space( _LR_ )
   GetList := {}
   cRj     := gRj
   nGodina := gGodina
   nMjesec := gMjesec

   SELECT ( F_LD )
   IF !Used()
      O_LD
   ENDIF

   DO WHILE .T.

      lSaveObracun := .F.

      ld_unos_obracuna_box( @lSaveObracun )

      IF ( lSaveObracun )

         SELECT ld

         cIdRadn := field->idRadn

         IF ( _UIznos < 0 )
            Beep( 2 )
            Msg( Lokal( "Radnik ne može imati platu u negativnom iznosu !" ) )
         ENDIF

         nPom := 0

         FOR i := 1 TO cLDPolja
            cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
            nPom += Abs( _i&cPom ) + Abs( _s&cPom )
         NEXT

         IF ( nPom <> 0 )

            _vals := get_dbf_global_memvars()
            _vals[ "varobr" ] := gVarObracun

            IF !update_rec_server_and_dbf( "ld_ld",  _vals, 1, "FULL" )
               delete_with_rlock()
            ELSE
               log_write( "F18_DOK_OPER: ld, " + IF( lNovi, "unos novog", "korekcija" ) + " obracuna plate - radnik: " + ld->idradn + ", mjesec: " + AllTrim( Str( ld->mjesec ) ) + ", godina: " + AllTrim( Str( ld->godina ) ), 2 )
            ENDIF

         ELSE
            IF lNovi
               delete_with_rlock()
            ENDIF
         ENDIF

         IF _pr_kart_pl == "D"
            ld_kartica_plate( cRj, nMjesec, nGodina, cIdRadn, IF( lViseObr, gObracun, NIL ) )
         ENDIF

      ELSE

         SELECT ( F_LD )
         IF !Used()
            RETURN
         ENDIF

         SELECT ld

         IF lNovi
            delete_with_rlock()
         ENDIF

         RETURN

      ENDIF

      SELECT ld
      USE

      Beep( 1 )

   ENDDO 

   RETURN



FUNCTION QQOUTC( cTekst, cBoja )
   @ Row(), Col() SAY cTekst COLOR cBoja
   RETURN



FUNCTION OObracun()

   SELECT F_LD
   IF !Used()
      O_LD
   ENDIF

   SELECT F_PAROBR
   IF !Used()
      O_PAROBR
   ENDIF

   SELECT F_RADN
   IF !Used()
      O_RADN
   ENDIF

   SELECT F_VPOSLA
   IF !Used()
      O_VPOSLA
   ENDIF

   SELECT F_STRSPR
   IF !Used()
      O_STRSPR
   ENDIF

   SELECT F_DOPR
   IF !Used()
      O_DOPR
   ENDIF

   SELECT F_POR
   IF !Used()
      O_POR
   ENDIF

   SELECT F_KBENEF
   IF !Used()
      O_KBENEF
   ENDIF

   SELECT F_OPS
   IF !Used()
      O_OPS
   ENDIF

   SELECT F_LD_RJ
   IF !Used()
      O_LD_RJ
   ENDIF

   SELECT F_RADKR
   IF !Used()
      O_RADKR
   ENDIF

   SELECT F_KRED
   IF !Used()
      O_KRED
   ENDIF

   SELECT F_RADSAT
   IF !Used()
      O_RADSAT
   ENDIF

   IF ( IsRamaGlas() )
      MsgBeep( "http://redmine.bring.out.ba/issues/25988" )
      QUIT
      O_RADSIHT
      O_FAKT_OBJEKTI
   ENDIF

   tipprn_use()

   RETURN




STATIC FUNCTION ld_unos_obracuna_box( lSaveObracun )

   LOCAL nULicOdb
   LOCAL cTrosk
   LOCAL cOpor
   LOCAL _radni_sati := fetch_metric( "ld_radni_sati", nil, "N" )
   PRIVATE cIdRj
   PRIVATE cGodina
   PRIVATE cIdRadn
   PRIVATE cMjesec

   cIdRadn := Space( 6 )
   cIdRj := gRj
   cMjesec := gMjesec
   cGodina := gGodina
   cObracun := gObracun

   IF Logirati( "LD", "DOK", "UNOS" )
      lLogUnos := .T.
   ELSE
      lLogUnos := .F.
   ENDIF

   OObracun()

   lNovi := .F.

   Box( , MAXROWS() -10, MAXCOLS() -10 )

   @ m_x + 1, m_y + 2 SAY Lokal( "Radna jedinica: " )

   QQOutC( cIdRJ, "GR+/N" )

   IF gUNMjesec == "D"
      @ m_x + 1, Col() + 2 SAY Lokal( "Mjesec: " )  GET cMjesec PICT "99"
   ELSE
      @ m_x + 1, Col() + 2 SAY Lokal( "Mjesec: " )
      QQOutC( Str( cMjesec, 2 ), "GR+/N" )
   ENDIF

   IF lViseObr
      IF gUNMjesec == "D"
         @ m_x + 1, Col() + 2 SAY8 Lokal( "Obračun: " ) GET cObracun WHEN HelpObr( .F., cObracun ) VALID ValObr( .F., cObracun )
      ELSE
         @ m_x + 1, Col() + 2 SAY8 Lokal( "Obračun: " )
         QQOutC( cObracun, "GR+/N" )
      ENDIF
   ENDIF

   @ m_x + 1, Col() + 2 SAY Lokal( "Godina: " )

   QQOutC( Str( cGodina, 4 ), "GR+/N" )

   @ m_x + 2, m_y + 2 SAY Lokal( "Radnik:" ) GET cIdRadn ;
      VALID {|| P_Radn( @cIdRadn ), SetPos( m_x + 2, m_y + 17 ), ;
      QQOut( PadR( Trim( radn->naz ) + " (" + Trim( radn->imerod ) + ") " + Trim( radn->ime ), 28 ) ), .T. }

   READ

   clvbox()

   ESC_BCR

   nO_Ret := ParObr( cMjesec, cGodina, IF( lViseObr, cObracun, nil ), cIdRj )

   IF nO_ret = 0

      msgbeep( "Ne postoje unešeni parametri obračuna za " + ;
         Str( cMjesec, 2 ) + "/" + Str( cGodina, 4 ) + " !!" )

      boxc()

      RETURN

   ELSEIF nO_ret = 2

      msgbeep( "Ne postoje unešeni parametri obračuna za " + ;
         Str( cMjesec, 2 ) + "/" + Str( cGodina, 4 ) + " !!" + ;
         "#Koristit ću postojeće parametre." )
   ENDIF

   SELECT radn

   cTR := g_tip_rada( cIdRadn, cIdRj )
   cOpor := g_oporeziv( cIdRadn, cIdrj )
   cTrosk := radn->trosk
   nULicOdb := ( radn->klo * gOsnLOdb )

   IF cTR $ "A#U#S"
      nULicOdb := 0
   ENDIF

   IF lViseObr .AND. cObracun <> "1"
      nULicOdb := 0
   ENDIF

   SELECT ld

   SEEK Str( cGodina, 4 ) + cIdRj + Str( cMjesec, 2 ) + iif( lViseObr, cObracun, "" ) + cIdRadn

   IF Found()
      lNovi := .F.
      set_global_vars_from_dbf()
   ELSE
      lNovi := .T.
      APPEND BLANK

      set_global_vars_from_dbf()

      _Godina := cGodina
      _idrj   := cIdRj
      _idradn := cIdRadn
      _mjesec := cMjesec
      _ulicodb := nULicOdb
      IF LD->( FieldPos( "TROSK" ) ) <> 0
         _trosk := cTrosk
         _opor := cOpor
      ENDIF

      IF lViseObr
         _obr := cObracun
      ENDIF

   ENDIF

   IF lNovi
      _brbod := radn->brbod
      _kminrad := radn->kminrad
      _idvposla := radn->idvposla
      _idstrspr := radn->idstrspr
   ENDIF

   ParObr( cMjesec, cGodina, iif( lViseObr, cObracun, ), cIdRj )

   IF gTipObr == "1"
      @ m_x + 3, m_y + 2   SAY IF( gBodK == "1", Lokal( "Broj bodova" ), Lokal( "Koeficijent" ) ) GET _brbod PICT "99999.99" VALID FillBrBod( _brbod )
   ELSE
      @ m_x + 3, m_y + 2   SAY Lokal( "Plan.osnov ld" ) GET _brbod PICT "99999.99" VALID FillBrBod( _brbod )
   ENDIF

   SELECT ld

   @ m_x + 3, Col() + 2 SAY IF( gBodK == "1", Lokal( "Vrijednost boda" ), Lokal( "Vr.koeficijenta" ) ); @ Row(), Col() + 1 SAY parobr->vrbod  PICT "99999.99999"
   IF gMinR == "B"
      @ m_x + 3, Col() + 2 SAY Lokal( "Minuli rad (bod)" ) GET _kminrad PICT "9999.99" VALID FillKMinRad( _kminrad )
   ELSE
      @ m_x + 3, Col() + 2 SAY Lokal( "Koef.minulog rada" ) GET _kminrad PICT "99.99%" VALID FillKMinRad( _kminrad )
   ENDIF

   @ m_x + 4, m_y + 2 SAY8 "Lič.odb:" GET _ulicodb PICT "9999.99"
   @ m_x + 4, Col() + 1 SAY Lokal( "Vrsta posla koji radnik obavlja" ) GET _IdVPosla valid ( Empty( _idvposla ) .OR. P_VPosla( @_IdVPosla, 4, 55 ) ) .AND. FillVPosla()

   READ

   IF _radni_sati == "D"
      @ m_x + 4, m_y + 85 SAY "R.sati:" GET _radSat
   ENDIF

   READ

   IF _radni_sati == "D"

      nTArea := Select()
      nSatiPreth := 0
      nSatiPreth := FillRadSati( cIdRadn, _radSat )
      SELECT ( nTArea )
   ENDIF

   IF gSihtarica == "D"
      UzmiSiht()
   ENDIF

   ld_unos_obracuna_tipovi_primanja()

   ld_unos_obracuna_footer( @lSaveObracun )

   IF _radni_sati == "D" .AND. lSaveObracun == .F.
      delRadSati( cIdRadn, nSatiPreth )
   ENDIF

   BoxC()

   RETURN



STATIC FUNCTION ld_unos_obracuna_footer( lSaveObracun )

   _USati := 0
   _UNeto := 0
   _UOdbici := 0

   UkRadnik()

   _UIznos := _UNeto + _UOdbici

   nKLO := radn->klo
   cTipRada := g_tip_rada( _idradn, _idrj )
   nSPr_koef := 0
   nTrosk := 0
   nBrOsn := 0
   cOpor := " "
   cTrosk := " "
   lInRS := .F.
   lInRs := radnik_iz_rs( radn->idopsst, radn->idopsrad )

   FOR i := 1 TO 40

      cTp := PadL( AllTrim( Str( i ) ), 2, "0" )
      xVar := "_I" + cTp

      nTArea := Select()

      SELECT tippr
      SEEK cTp

      SELECT ( nTArea )

      IF tippr->uneto == "D"
         _nakn_opor += &( xVar )
      ELSEIF tippr->uneto == "N"
         _nakn_neop += &( xVar )
      ENDIF

      SELECT ( nTArea )

   NEXT

   IF radn->( FieldPos( "opor" ) ) <> 0
      cOpor := radn->opor
   ENDIF

   IF radn->( FieldPos( "trosk" ) ) <> 0
      cTrosk := radn->trosk
   ENDIF

   IF cTipRada == "S"
      IF radn->( FieldPos( "SP_KOEF" ) ) <> 0
         nSPr_koef := radn->sp_koef
      ENDIF
   ENDIF

   IF cTipRada $ "A#U#P#S"
      _ULicOdb := 0
   ENDIF

   _UBruto := bruto_osn( _UNeto, cTipRada, _ULicOdb, nSPr_koef, cTrosk )

   IF cTipRada == "U" .AND. cTrosk <> "N"
      nTrosk := ROUND2( _UBruto * ( gUgTrosk / 100 ), gZaok2 )
      IF lInRS == .T.
         nTrosk := 0
      ENDIF
      _UBruto := _UBruto - nTrosk
   ENDIF

   IF cTipRada == "A" .AND. cTrosk <> "N"

      nTrosk := ROUND2( _UBruto * ( gAhTrosk / 100 ), gZaok2 )
      IF lInRS == .T.
         nTrosk := 0
      ENDIF
      _UBruto := _UBruto - nTrosk
   ENDIF

   nMinBO := _UBruto
   IF cTipRada $ " #I#N"
      IF _I01 = 0
         // ne racunaj min.bruto osnovu
      ELSE
         nMinBO := min_bruto( _UBruto, _USati )
      ENDIF
   ENDIF

   nDop := u_dopr_iz( nMinBO, cTipRada )
   _udopr := nDop
   _udop_st := 31.0
   nPorOsnovica := ( ( _ubruto - _udopr ) - _ulicodb )

   IF nPorOsnovica < 0 .OR. !radn_oporeziv( _idradn, _idrj )
      nPorOsnovica := 0
   ENDIF

   _uporez := izr_porez( nPorOsnovica, "B" )
   _upor_st := 10.0

   IF !radn_oporeziv( _idradn, _idrj )
      _uporez := 0
      _upor_st := 0
   ENDIF

   _uneto2 := Round( ( ( _ubruto - _udopr ) - _uporez ), gZaok2 )

   IF cTipRada $ " #I#N#"
      nMinNeto := min_neto( _uneto2, _usati )
      _uneto2 := nMinNeto
   ENDIF

   _uiznos := ROUND2( _uneto2 + _UOdbici, gZaok2 )

   IF cTipRada $ "U#A" .AND. cTrosk <> "N"
      _uIznos := ROUND2( _uiznos + nTrosk, gZaok2 )
      IF lInRS == .T.
         _uIznos := _UNeto
      ENDIF
   ENDIF

   IF cTipRada $ "S"
      _uIznos := _UNeto
   ENDIF

   @ m_x + 19, m_y + 2 SAY "Ukupno sati:"
   @ Row(), Col() + 1 SAY _USati PICT gPics
   @ m_x + 19, Col() + 2 SAY "Uk.lic.odb.:"
   @ Row(), Col() + 1 SAY _ULicOdb PICT gPici
   @ m_x + 20, m_y + 2 SAY "Primanja:"
   @ Row(), Col() + 1 SAY _UNeto PICT gPici
   @ m_x + 20, Col() + 2 SAY "Odbici:"
   @ Row(), Col() + 1 SAY _UOdbici PICT gPici
   @ m_x + 20, Col() + 2 SAY "UKUPNO ZA ISPLATU:"
   @ Row(), Col() + 1 SAY _UIznos PICT gPici
   @ m_x + 22, m_y + 10 SAY "Pritisni <ENTER> za snimanje, <ESC> napustanje"
   @ m_x + 21, m_y + 2 SAY "Vrsta isplate (1 - 13):"
   @ Row(), Col() + 1 GET _v_ispl

   READ

   Inkey( 0 )

   DO WHILE LastKey() <> K_ESC .AND. LastKey() <> K_ENTER
      Inkey( 0 )
   ENDDO

   IF LastKey() == K_ESC
      MsgBeep( "Obracun nije pohranjen !!!" )
      lSaveObracun := .F.
   ELSE
      MsgBeep( "Obracun je pohranjen !!!" )
      lSaveObracun := .T.
   ENDIF

   RETURN



STATIC FUNCTION ld_unos_obracuna_tipovi_primanja()

   LOCAL i
   PRIVATE cIdTP := "  "
   PRIVATE nRedTP := 4
   PRIVATE cVarTP
   PRIVATE cIznosTP

   cTipPrC := " "

   FOR i := 1 TO cLDPolja
      IF i < 10
         cIdTP := "0" + AllTrim( Str( i ) )
         cVarTP := "_S0" + AllTrim( Str( i ) )
         cIznosTP := "_I0" + AllTrim( Str( i ) )
         cPoljeIznos := "I0" + AllTrim( Str( i ) )
         cPoljeSati := "S0" + AllTrim( Str( i ) )
      ELSE
         cIdTP := AllTrim( Str( i ) )
         cVarTP := "_S" + AllTrim( Str( i ) )
         cIznosTP := "_I" + AllTrim( Str( i ) )
         cPoljeIznos := "I" + AllTrim( Str( i ) )
         cPoljeSati := "S" + AllTrim( Str( i ) )
      ENDIF

      nRedTP++

      SELECT tippr
      SEEK cIdTP
      SELECT ld

      IF LD->( FieldPos( cPoljeIznos ) = 0 ) .AND. LD->( FieldPos( cPoljeSati ) = 0 )
         MsgBeep( "Broj polja u LD -> 30, potrebna modifikacija struktura !!!" )
         RETURN
      ENDIF

      cW := "WhUnos(" + cm2str( cIdTp ) + ")"
      cV := "Izracunaj(@" + cIznosTP + ")"

      IF ( tippr->( Found() ) .AND. tippr->aktivan == "D" )
         IF ( tippr->fiksan $ "DN" )
            @ m_x + nRedTP, m_Y + 2 SAY tippr->id + "-" + tippr->naz + " (SATI) " GET &cVarTP PICT gPics when &cW valid &cV
         ELSEIF ( tippr->fiksan == "P" )
            @ m_x + nRedTP, m_Y + 2 SAY tippr->id + "-" + tippr->naz + " (%)    " GET &cVarTP. PICT "999.99" when &cW valid &cV
         ELSEIF tippr->fiksan == "B"
            @ m_x + nRedTP, m_Y + 2 SAY tippr->id + "-" + tippr->naz + "(BODOVA)" GET &cVarTP. PICT gPici when &cW valid &cV
         ELSEIF tippr->fiksan == "C"
            @ m_x + nRedTP, m_Y + 2 SAY tippr->id + "-" + tippr->naz + "        " GET cTipPrC when &cW valid &cV
         ENDIF

         @ m_x + nRedTP, m_y + 50 SAY "IZNOS" GET &cIznosTP PICT gPici
      ENDIF

      IF ( i % 17 == 0 )
         READ
         @ m_x + 5, m_y + 2 CLEAR TO m_x + 21, m_y + 69
         nRedTP := 4
      ENDIF

      IF ( i == cLDPolja )
         READ
      ENDIF

   NEXT

   RETURN



FUNCTION WhUnos( cTP )
   tippr->( dbSeek( cTP ) )
   RETURN .T.




FUNCTION ValRNal( cPom, i )

   IF !Empty( cPom )
      P_fakt_objekti( @cPom )
      cRNal[ i ] := cPom
   ENDIF

   RETURN .T.


