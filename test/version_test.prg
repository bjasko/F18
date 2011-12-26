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

function test_version()
local _str, _num

_num := 032155

TEST_LINE( get_version_str(_num), "3.21.55")

_num := 550507
TEST_LINE( get_version_str(_num), "55.5.7")

TEST_LINE( get_version_num(12, 5, 49), 120549)

return .t.
