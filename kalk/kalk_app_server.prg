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


#include "kalk.ch"


function KalkBatchObrada(p3,p4,p5,p6,p7)
if mpar37("/B",p3,p4,p5,p6,p7)
  // sada cemo staviti da je batch stampa azuriranog dokumenta
  KEYBOARD Chr(K_ENTER) + Chr(K_ESC)
  nH:=FOPEN(PRIVPATH+"para.txt")
  cKom:=FReadLn(nH)
  cKom:=left(cKom, (len(cKom) -2 ))
  if alltrim(cKom)="STAZUR"
    cBroj:=FreadLn(nH)
    cBroj:=left(cBroj, (len(cBroj) -2 ))
    FClose(nH)
    StKalk(.t.,cBroj)
  else
    FClose(nH)
  endif
  goModul:quit()
endif
return

