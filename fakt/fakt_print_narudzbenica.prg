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


FUNCTION fakt_print_narudzbenica( cIdFirma, cIdTipDok, cBrDok )

   PushWa()

   close_open_fakt_tabele()

   // izgenerisi rn.dbf i drn.dbf, ali nemoj stampati poreznu fakturu
   StampTXT( cIdfirma, cIdTipdok, cBrDok, .T. )

   print_narudzbenica()

   O_PARTN
   SELECT ( F_FAKT_DOKS )
   USE
   O_FAKT_DOKS
   PopWa()

   RETURN NIL


FUNCTION fakt_print_narudzbenica_priprema()

      stdokpdv( nil, nil, nil, .T. )
      select_fakt_pripr()

      print_narudzbenica()
      close_open_fakt_tabele()
      select_fakt_pripr()

    RETURN NIL

FUNCTION print_radni_nalog()

   SELECT fakt_doks
   nTrec := RecNo()
   _cIdFirma := idfirma
   _cIdTipDok := idtipdok
   _cBrDok := brdok
   close_open_fakt_tabele()
   StampTXT( _cidfirma, _cIdTipdok, _cbrdok, .T. )

   rnal_print( .T. )
   SELECT ( F_FAKT_DOKS )
   USE

   O_FAKT_DOKS
   O_PARTN
   IF cFilter == ".t."
      SET FILTER TO
   ELSE
      SET FILTER to &cFilter
   ENDIF
   GO nTrec

   RETURN DE_CONT


