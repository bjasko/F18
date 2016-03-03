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



FUNCTION _uk_sa_pdv( cIdTipDok, cPartner, nIznos )

   LOCAL nRet := 0
   LOCAL nTArea := Select()

   IF cIdTipDok $ "11#13#23"
      nRet := nIznos
   ELSE
      IF !IsIno( cPartner ) .AND. !is_pdv_oslobodjen( cPartner )
         nRet := ( nIznos * 1.17 )
      ELSE
         nRet := nIznos
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN nRet



FUNCTION _osnovica( cIdTipDok, cPartner, nIznos )

   LOCAL nRet := 0
   LOCAL nTArea := Select()

   IF cIdTipDok $ "11#13#23"
      nRet := ( nIznos / 1.17 )
   ELSE
      nRet := nIznos
   ENDIF

   SELECT ( nTArea )

   RETURN nRet



FUNCTION _pdv( cIdTipDok, cPartner, nIznos )

   LOCAL nRet := 0
   LOCAL nTArea := Select()

   IF cIdTipDok $ "11#13#23"
      nRet := ( nIznos / 1.17 ) * 0.17
   ELSE
      IF !IsIno( cPartner ) .AND. !is_pdv_oslobodjen( cPartner )
         nRet := ( nIznos * 0.17 )
      ELSE
         nRet := 0
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN nRet




FUNCTION fakt_objekat_naz( id_obj )

   LOCAL _ret := ""

   PushWA()

   O_FAKT_OBJEKTI

   SELECT fakt_objekti
   SET ORDER TO TAG "ID"
   SEEK id_obj

   IF Found()
      _ret := AllTrim( field->naz )
   ENDIF

   PopWa()

   RETURN _ret



// --------------------------------------------------
// Vraca objekat iz tabele fakt
// ako se zadaje bez parametara pretpostavlja se da je
// napravljena tabela relacije fakt_doks->fakt
// --------------------------------------------------
FUNCTION fakt_objekat_id( id_firma, id_tipdok, br_dok )

   LOCAL _ret := ""
   LOCAL _memo

   PushWA()
   IF id_firma == NIL
      id_firma = fakt->idfirma
      id_tipdok = fakt->idtipdok
      br_dok = fakt->brdok
   ENDIF

   SELECT ( F_FAKT )

   IF !Used()
      O_FAKT
   ENDIF

   SELECT fakt
   SET FILTER TO
   SET ORDER TO TAG "1"
   SEEK id_firma + id_tipdok + br_dok + "  1"

   IF !Found()
      _ret := Space( 10 )
   ELSE
      _memo := ParsMemo( fakt->txt )
      IF Len( _memo ) >= 20
         _ret := PadR( _memo[ 20 ], 10 )
      ENDIF
   ENDIF

   PopWa()

   RETURN _ret



FUNCTION fakt_memo_field_to_txt( memo_field )

   LOCAL _txt := ""
   LOCAL _val := ""
   LOCAL _i

   FOR _i := 1 TO Len( memo_field )

      _tmp := memo_field[ _i ]

      IF ValType( _tmp ) == "D"
         _val := DToC( _tmp )
      ELSEIF ValType( _tmp ) == "N"
         _val := Val( _tmp )
      ELSE
         _val := _tmp
      ENDIF

      _txt += Chr( 16 ) + _val + Chr( 17 )

   NEXT

   RETURN _txt



FUNCTION get_fakt_vezni_dokumenti( id_firma, tip_dok, br_dok )

   LOCAL _t_arr := Select()
   LOCAL _ret := ""
   LOCAL _memo

   SELECT ( F_FAKT )
   IF !Used()
      O_FAKT
   ENDIF

   SELECT fakt
   SET ORDER TO TAG "1"
   GO TOP
   SEEK id_firma + tip_dok + br_dok

   IF !Found()
      RETURN _ret
   ENDIF

   _memo := ParsMemo( fakt->txt )

   IF Len( _memo ) >= 19
      _ret := _memo[ 19 ]
   ENDIF

   SELECT ( _t_arr )

   RETURN _ret



FUNCTION fakt_priprema_prazna()

   LOCAL _ret := .T.
   LOCAL _t_area := Select()

   SELECT ( F_FAKT_PRIPR )
   IF !Used()
      O_FAKT_PRIPR
   ENDIF

   IF RECCOUNT2() == 0
      SELECT ( _t_area )
      RETURN _ret
   ENDIF

   _ret := .F.

   IF Pitanje(, "Priprema modula FAKT nije prazna, izbrisati postojeće stavke (D/N) ?", "N" ) == "D"

      SELECT fakt_pripr
      my_dbf_zap()
      _ret := .T.

   ENDIF

   SELECT ( _t_area )

   RETURN _ret
