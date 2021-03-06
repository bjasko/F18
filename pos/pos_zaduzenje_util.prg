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


FUNCTION pos_dokument_naziv( cIdVd )

   DO CASE
   CASE cIdVD == POS_IDVD_POCETNO_STANJE_PRODAVNICA
      RETURN "Početno stanje"

   CASE cIdVd == POS_IDVD_PRIJEM_PRODAVNICA
      RETURN "Prijem prodavnica"

      // CASE cIdVd == POS_IDVD_OTPREMNICA_MAGACIN
      // RETURN "Otpremnica magacin"

   CASE cIdVd == POS_IDVD_NIVELACIJA
      RETURN "Nivelacija"

   CASE cIdVd == POS_IDVD_DOBAVLJAC_PRODAVNICA
      RETURN "Ulaz od dobavljača"

   CASE cIdVD == POS_IDVD_ZAHTJEV_SNIZENJE
      RETURN "Zathjev za sniženje"

   CASE cIdVD == POS_IDVD_ODOBRENO_SNIZENJE
      RETURN "Odobreno sniženje"

   CASE cIdVD == POS_IDVD_ZAHTJEV_NABAVKA
      RETURN "Zahtjev za nabavku"

   CASE cIdVD == POS_IDVD_OTPREMNICA_MAGACIN_ZAHTJEV
      RETURN "Zahtjev za prijem iz magacina"

   CASE cIdVD == POS_IDVD_OTPREMNICA_MAGACIN_PRIJEM
      RETURN "POS prijem iz magacina"
   ENDCASE

   RETURN "<undefined>"
