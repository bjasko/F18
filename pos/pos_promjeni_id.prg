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


#include "pos.ch"



function PromjeniID()
local fScope
local cFil0
local cTekIdPos:=gIdPos
private aVezani:={}
private dMinDatProm:=ctod("")

// datum kada je napravljena promjena na racunima
// unutar PRacuni, odnosno P_SRproc setuje se ovaj datum

O_SIFK
O_SIFV
O_KASE
O_ROBA
O__POS_PRIPR
O_POS_DOKS
O_POS

if KLevel<="0".and.SigmaSif(gSTELA)
	fScope:=.f.
else
	fscope:=.t.
endif

dDatOd:=ctod("")
dDatDo:=cTod("")

qIdRoba:=SPACE(LEN(POS->idroba))

SET CURSOR ON
if IzFmkIni("PREGLEDRACUNA","MozeIZaArtikal","N",KUMPATH)=="D"
	Box(,3,72)
    	@ m_x+1,m_y+2 SAY "Racuni na kojima se nalazi artikal: (prazno-svi)" GET qIdRoba VALID EMPTY(qIdRoba).or.P_Roba(@qIdRoba) PICT "@!"
    	@ m_x+2,m_y+2 SAY "Datumski period:" GET dDatOd
    	@ m_x+2,col()+2 SAY "-" GET dDatDo
	@ m_x+3,m_y+2 SAY "Prodajno mjesto:" GET gIdPos VALID P_Kase(@gIdPos)
    	read
  	BoxC()
else
  	Box(,2,60)
    	@ m_x+1,m_y+2 SAY "Datumski period:" GET dDatOd
    	@ m_x+1,col()+2 SAY "-" GET dDatDo
	@ m_x+2,m_y+2 SAY "Prodajno mjesto:" GET gIdPos VALID P_Kase(@gIdPos)
    	read
  	BoxC()
endif

cFil0:=""

if !EMPTY(dDatOd).and.!EMPTY(dDatDo)
	cFil0:="Datum>="+cm2str(dDatOD)+".and. Datum<="+cm2str(dDatDo)+".and."
endif

PRacuni(,,,fScope,cFil0,qIdRoba)  
// postavi scope: P_StalniRac(dDat,cBroj,fPrep,fScope)

CLOSE ALL

gIdPos := cTekIdPos

return



// ---------------------------------------------------------------------------------
// brisanje racuna za period
// ---------------------------------------------------------------------------------
function BrisiRNVP()

if Pitanje(,"Potpuno - fizicki izbrisati racune za period ?","N") == "N"
	return DE_CONT
endif

dDatOd := dDatDo := DATE()

Box(,2,60)
	set cursor on
    @ m_x+1,m_y+2 SAY "Period " GET dDatOd
    @ m_x+1,col()+2 SAY "-" GET dDatDo
    read
Boxc()

if lastkey() == K_ESC
	return DE_CONT
endif

if empty( dMinDatProm )
	dMinDatProm := pos_doks->datum
else
    dMinDatProm := min(dMinDatProm, pos_doks->datum)
endif

select pos_doks      
cFilt1 := "DATUM>="+cm2str(dDatOd)+".and.DATUM<="+cm2str(dDatDo)+".and.IDVD=='42'"
set filter to &cFilt1
go top

my_use_semaphore_off()
sql_table_update( nil, "BEGIN" )

do while !eof()
	
	select pos_doks    

	_id_pos := field->idpos
	_id_vd := field->idvd
	_br_dok := field->brdok
	_dat_dok := field->datum	

	_rec := dbf_get_rec()

	delete_rec_server_and_dbf( "pos_doks", _rec, 1, "CONT" )

	select pos
    seek _id_pos + "42" + DTOS( _dat_dok ) + _br_dok
	if FOUND()
		delete_rec_server_and_dbf( "pos_pos", _rec, 2, "CONT" ) 
	endif

    select pos_doks

enddo

select pos_doks
set filter to
go top

return DE_REFRESH



/*! \fn KL_PRacuna()
 *  \brief Korisnicka Lozinka Pregleda Racuna
 */
function KL_PRacuna()
Box("#PR", 4, 34, .f.)
	@ m_x+2,m_y+2 SAY "Stara lozinka..."
    	@ m_x+4,m_y+2 SAY "Nova lozinka...."
    	nSifLen := 6
    	do while .t.
      		SET CURSOR ON
      		cKorSif:=SPACE(nSifLen)
      		cKorSifN:=SPACE(nSifLen)
      		@ m_x+2,m_y+19 GET cKorSif PICTURE "@!" COLOR Nevid
      		@ m_x+2, col() SAY "<" COLOR "R/W"
      		@ m_x+2, col()-len(cKorSif)-2 SAY ">" COLOR "R/W"
      		@ m_x+4, col()+6 SAY " "
      		@ m_x+4, col()-len(cKorSifN)-2 SAY " "
        	READ
        	if LASTKEY()==K_ESC
			EXIT
		endif
      		@ m_x+4,m_y+19 GET cKorSifN PICTURE "@!" COLOR Nevid
      		@ m_x+4, col() SAY "<" COLOR "R/W"
      		@ m_x+4, col()-len(cKorSifN)-2 SAY ">" COLOR "R/W"
      		@ m_x+2, col()+6 SAY " "
     		@ m_x+2, col()-len(cKorSif)-2 SAY " "
        	READ
        	if LASTKEY()==K_ESC
			EXIT
		endif
      		nMax:=MAX(LEN(cKorSif),LEN(gStela))
      		if PADR(cKorSif,nMax)==PADR(gStela,nMax) .and. !EMPTY(cKorSifN)
        		UzmiIzIni(KUMPATH+"FMK.INI","KL","PregledRacuna",;
                  	CryptSC(TRIM(cKorSifN)),"WRITE")
        		gStela:=CryptSC(IzFmkIni("KL","PregledRacuna",CryptSC("STELA"),KUMPATH))
        		MsgBeep("Sifra promijenjena!")
      		endif
    	enddo
    	SET CURSOR OFF
    	SETCOLOR (Normal)
BoxC()
return




