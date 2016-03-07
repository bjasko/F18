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



// Omogucava izradu naljepnica u dvije varijante:
// 1 - prikaz naljepnica sa tekucom cijenom
// 2 - prikaz naljepnica sa novom cijenom, kao i prekrizenom starom cijenom


FUNCTION RLabele()

   LOCAL cVarijanta
   LOCAL cKolicina
   LOCAL _tkm_no
   LOCAL _xml_file := my_home() + "data.xml"
   LOCAL _template := "rlab1.odt"
   LOCAL _len_naz := 25

   cVarijanta := "1"
   cKolicina := "N"

   IF GetVars( @cVarijanta, @cKolicina, @_tkm_no, @_len_naz ) == 0
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   cre_rlabele()

   IF cVarijanta == "2"
      _template := "rlab2.odt"
   ENDIF

   KaFillRLabele( cKolicina )

   SELECT rlabele
   IF RecCount() == 0
      MsgBeep( "Nije generisano nista! greska..." )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   _gen_xml( _xml_file, _tkm_no, _len_naz )

   my_close_all_dbf()

   IF generisi_odt_iz_xml( _template, _xml_file )
      prikazi_odt()
   ENDIF

   RETURN .T.


STATIC FUNCTION GetVars( cVarijanta, cKolicina, tkm_no, len_naz )

   LOCAL lOpened
   LOCAL cIdVd

   cIdVd := "XX"
   cVarijanta := "1"
   cKolicina := "N"
   lOpened := .T.

   tkm_no := PadR( fetch_metric( "rlabel_tkm_no", my_user(), "" ), 20 )
   len_naz := fetch_metric( "rlabel_naz_len", NIL, 28 )

   IF ( gModul == "KALK" )

      SELECT ( F_KALK_PRIPR )
      IF !Used()
         O_KALK_PRIPR
         lOpened := .F.
      ENDIF

      PushWA()
      SELECT kalk_pripr
      GO TOP

      cIdVd := kalk_pripr->idVd

      PopWa()

      IF ( cIdVd == "19" )
         cVarijanta := "2"
      ENDIF
   ENDIF

   Box(, 10, 65 )

   @ m_x + 1, m_y + 2 SAY "Broj labela zavisi od kolicine artikla (D/N):" ;
      GET cKolicina VALID cKolicina $ "DN" PICT "@!"

   @ m_x + 3, m_y + 2 SAY "1 - standardna naljepnica"
   @ m_x + 4, m_y + 2 SAY "2 - sa prikazom stare cijene (prekrizeno)"

   @ m_x + 6, m_y + 3 SAY "Odaberi zeljenu varijantu " ;
      GET cVarijanta VALID cVarijanta $ "12"

   @ m_x + 7, m_y + 2 SAY "Broj TKM:" GET tkm_no

   @ m_x + 8, m_y + 2 SAY "Naziv skrati na broj karaktera:" GET len_naz PICT "999"

   READ

   BoxC()

   IF ( gModul == "KALK" )
      IF ( !lOpened )
         USE
      ENDIF
   ENDIF

   IF ( LastKey() == K_ESC )
      RETURN 0
   ENDIF

   set_metric( "rlabel_tkm_no", my_user(), AllTrim( tkm_no ) )
   set_metric( "rlabel_naz_len", NIL, len_naz )

   RETURN 1




// -------------------------------------------------------------
// Kreira tabelu rLabele u privatnom direktoriju
// -------------------------------------------------------------
STATIC FUNCTION cre_rlabele()

   LOCAL aDbf
   LOCAL _tbl
   LOCAL _dbf
   LOCAL _cdx

   SELECT ( F_RLABELE )
   IF Used()
      USE
   ENDIF

   _tbl := "rlabele"
   _dbf := my_home() + _tbl + ".dbf"
   _cdx := my_home() + _tbl + ".cdx"

   FErase( _dbf )
   FErase( _cdx )

   aDBf := {}
   AAdd( aDBf, { 'idRoba', 'C', 10, 0 } )
   AAdd( aDBf, { 'naz', 'C', 100, 0 } )
   AAdd( aDBf, { 'idTarifa', 'C',  6, 0 } )
   AAdd( aDBf, { 'barkod', 'C', 20, 0 } )
   AAdd( aDBf, { 'evBr', 'C', 10, 0 } )
   AAdd( aDBf, { 'cijena', 'N', 10, 2 } )
   AAdd( aDBf, { 'sCijena', 'N', 10, 2 } )
   AAdd( aDBf, { 'skrNaziv', 'C', 20, 0 } )
   AAdd( aDBf, { 'brojLabela', 'N',  6, 0 } )
   AAdd( aDBf, { 'jmj', 'C',  3, 0 } )
   AAdd( aDBf, { 'katBr', 'C', 20, 0 } )
   AAdd( aDBf, { 'catribut', 'C', 30, 0 } )
   AAdd( aDBf, { 'catribut2', 'C', 30, 0 } )
   AAdd( aDBf, { 'natribut', 'N', 10, 2 } )
   AAdd( aDBf, { 'natribut2', 'N', 10, 2 } )
   AAdd( aDBf, { 'vpc', 'N',  8, 2 } )
   AAdd( aDBf, { 'mpc', 'N',  8, 2 } )
   AAdd( aDBf, { 'porez', 'N',  8, 2 } )
   AAdd( aDBf, { 'porez2', 'N',  8, 2 } )
   AAdd( aDBf, { 'porez3', 'N',  8, 2 } )

   dbCreate( _dbf, aDbf )

   SELECT ( F_RLABELE )
   my_use_temp( "RLABELE", AllTrim( _dbf ), .F., .T. )

   INDEX on ( "idroba" ) TAG "1"
   SET ORDER TO TAG "1"

   RETURN NIL




// -------------------------------------------------------------------------
// Puni tabelu rLabele podacima na osnovu dokumenta iz pripreme modula KALK
//
// cKolicina - D ili N, broj labela zavisi od kolicine robe
// -------------------------------------------------------------------------
STATIC FUNCTION KaFillRLabele( cKolicina )

   LOCAL cDok
   LOCAL nBr_labela := 0
   LOCAL _predisp := .F.

   O_ROBA
   O_KALK_PRIPR

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF mp_predispozicija( field->idfirma, field->idvd, field->brdok )
      _predisp := .T.
   ENDIF

   SELECT kalk_pripr
   GO TOP

   cDok := ( field->idFirma + field->idVd + field->brDok )

   DO WHILE ( !Eof() .AND. cDok == ( field->idFirma + field->idVd + ;
         field->brDok ) )

      IF _predisp
         IF field->idkonto2 <> "XXX"
            SKIP
            LOOP
         ENDIF
      ENDIF

      nBr_labela := field->kolicina

      // ako ne zavisi od kolicine artikla
      // uvijek je jedna labela

      IF cKolicina == "N"
         nBr_labela := 1
      ENDIF

      SELECT roba
      SEEK kalk_pripr->idRoba

      SELECT rlabele
      SEEK kalk_pripr->idroba

      IF ( cKolicina == "D" .OR. ( cKolicina == "N" .AND. !Found() ) )

         FOR i := 1 TO nBr_labela

            SELECT rlabele
            APPEND BLANK

            Scatter()

            _idroba := kalk_pripr->idroba
            _naz := Left( roba->naz, 40 )
            _idtarifa := kalk_pripr->idtarifa
            _evbr := kalk_pripr->brdok
            _jmj := roba->jmj

            IF !Empty( roba->barkod )
               _barkod := roba->barkod
            ENDIF

            IF ( kalk_pripr->idVd == "19" )
               _cijena := kalk_pripr->mpcsapp + kalk_pripr->fcj
               _scijena := kalk_pripr->fcj
            ELSE
               _cijena := kalk_pripr->mpcsapp
               _scijena := _cijena
            ENDIF

            Gather()

         NEXT

      ENDIF

      SELECT kalk_pripr
      SKIP 1

   ENDDO

   RETURN NIL


// ---------------------------------------------------------------
// Prodji kroz pripremu FAKT-a i napuni tabelu rLabele
// ---------------------------------------------------------------
STATIC FUNCTION FaFillRLabele()
   RETURN NIL



// -------------------------------------------------------------------
// Stampaj RLabele (delphirb)
// cVarijanta - varijanta izgleda labele robe:
// "1" - standardna;
// "2" - za dokument nivelacije - prikazuju snizenje,
// gdje se vidi i precrtana stara cijena
// -------------------------------------------------------------------
STATIC FUNCTION PrintRLabele( cVarijanta )

   LOCAL _rtm_naziv := AllTrim( "rLab" + cVarijanta )

   f18_rtm_print( _rtm_naziv, "rlabele", "1" )

   RETURN NIL


// ----------------------------------------------------------
// generisi xml na osnovu tabele rlabele
// ----------------------------------------------------------
STATIC FUNCTION _gen_xml( xml_file, tkm_no, len_naz )

   LOCAL _t_area := Select()

   open_xml( xml_file )
   xml_head()

   xml_subnode( "lab", .F. )

   SELECT rlabele
   SET ORDER TO TAG "1"
   GO TOP

   xml_node( "pred", to_xml_encoding( AllTrim( gNFirma ) ) )
   xml_node( "grad", to_xml_encoding( AllTrim( gMjStr ) ) )
   xml_node( "tkm", to_xml_encoding( AllTrim( tkm_no ) ) )
   xml_node( "dok", to_xml_encoding( AllTrim( rlabele->evbr ) ) )

   DO WHILE !Eof()

      xml_subnode( "data", .F. )

      xml_node( "id", to_xml_encoding( AllTrim( rlabele->idroba ) )  )
      xml_node( "naz", to_xml_encoding( PadR( AllTrim( rlabele->naz ), len_naz ) ) )
      xml_node( "jmj", to_xml_encoding( AllTrim( rlabele->jmj ) )  )
      xml_node( "bk", to_xml_encoding( AllTrim( rlabele->barkod ) )  )
      xml_node( "c1", AllTrim( Str( rlabele->cijena, 12, 2 ) )  )
      xml_node( "c2", AllTrim( Str( rlabele->scijena, 12, 2 ) )  )

      xml_subnode( "data", .T. )

      SKIP
   ENDDO

   xml_subnode( "lab", .T. )

   close_xml()

   SELECT ( _t_area )

   RETURN