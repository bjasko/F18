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
 

function gSjeciStr()

Setpxlat()
if gPrinter=="R"
    Beep(1)
    FF
else
    qqout(gSjeciStr)
endif
konvtable()
return


 
function gOtvorStr()

Setpxlat()
if gPrinter<>"R"
    qqout(gOtvorStr)
endif
konvtable()
return



function PaperFeed()

if gVrstaRS <> "S"
    for i:=1 to nFeedLines
            ?
    next
    if gPrinter=="R"
        Beep(1)
        FF
    else  
        gSjeciStr()
    endif
endif
return



   

function IncID(cId,cPadCh)

if cPadCh==nil
    cPadCh:=" "
else
    cPadCh:=cPadCh
endif

return (PADL(VAL(ALLTRIM(cID))+1,LEN(cID),cPadCh))

/*! \fn DecId(cId,cPadCh)
 *  \brief Decrement id, kontra IncId
 */

function DecID(cId,cPadCh)
*{
if cPadCh==nil
    cPadCh:=" "
else
    cPadCh:=cPadCh
endif
return (PADL(VAL(ALLTRIM(cID))-1,LEN(cID),cPadCh) )
*}


/*! \fn SetNazDVal()
 *  \brief Postavlja naziv domace valute
 *  \brief !!! ovo ipak treba da setuje i stranu valutu !!!
 */

function SetNazDVal()
*{
local lOpened
SELECT F_VALUTE
PushWA()
lOpened:=.t.
if !USED() 
    O_VALUTE
    lOpened:=.f.
endif
SET ORDER TO TAG "NAZ"       // tip
GO TOP
Seek2("D")   // trazi domacu valutu
gDomValuta:=ALLTRIM(Naz2)
// postavi odmah i stranu
go top
Seek2("P")
gStrValuta:=ALLTRIM(Naz2)

if !lOpened
    USE
end
PopWA()
return


//-----------------------------------------------------
// ispisuje iznos racuna velikim brojevima
//-----------------------------------------------------
function ispisi_iznos_veliki_brojevi( iznos, row, col )
local _iznos
local _cnt, _char, _next_y

if col == nil
    col := 76
endif

_iznos := ALLTRIM( TRANSFORM( iznos, "9999999.99" ) )
_next_y := m_y + col

// ocisti iznos 
@ m_x + row + 0, MAXCOLS() / 2 SAY PADR( "", MAXCOLS() / 2 )
@ m_x + row + 1, MAXCOLS() / 2 SAY PADR( "", MAXCOLS() / 2 )
@ m_x + row + 2, MAXCOLS() / 2 SAY PADR( "", MAXCOLS() / 2 )
@ m_x + row + 3, MAXCOLS() / 2 SAY PADR( "", MAXCOLS() / 2 )
@ m_x + row + 4, MAXCOLS() / 2 SAY PADR( "", MAXCOLS() / 2 )

for _cnt := LEN( _iznos ) TO 1 STEP -1

    _char := SUBSTR( _iznos, _cnt, 1 )

    do case
        case _char = "1"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY " ��"
            @ m_x + row + 1, _Next_Y SAY "  �"
            @ m_x + row + 2, _Next_Y SAY "  �"
            @ m_x + row + 3, _Next_Y SAY "  �"
            @ m_x + row + 4, _Next_Y SAY "����"

        case _char = "2"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY "����"
            @ m_x + row + 1, _Next_Y SAY "   �"
            @ m_x + row + 2, _Next_Y SAY "����"
            @ m_x + row + 3, _Next_Y SAY "�"
            @ m_x + row + 4, _Next_Y SAY "����"

        case _char = "3"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY " ���"
            @ m_x + row + 1, _Next_Y SAY "   �"
            @ m_x + row + 2, _Next_Y SAY "  ��"
            @ m_x + row + 3, _Next_Y SAY "   �"
            @ m_x + row + 4, _Next_Y SAY "����"
        
        case _char = "4"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY "�"
            @ m_x + row + 1, _Next_Y SAY "�  �"
            @ m_x + row + 2, _Next_Y SAY "����"
            @ m_x + row + 3, _Next_Y SAY "   �"
            @ m_x + row + 4, _Next_Y SAY "   �"

        case _char = "5"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY "����"
            @ m_x + row + 1, _Next_Y SAY "�"
            @ m_x + row + 2, _Next_Y SAY "����"
            @ m_x + row + 3, _Next_Y SAY "   �"
            @ m_x + row + 4, _Next_Y SAY "����"

        case _char = "6"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY "����"
            @ m_x + row + 1, _Next_Y SAY "�"
            @ m_x + row + 2, _Next_Y SAY "����"
            @ m_x + row + 3, _Next_Y SAY "�  �"
            @ m_x + row + 4, _Next_Y SAY "����"

        case _char = "7"

            _next_y -= 5
         
            @ m_x + row + 0, _Next_Y SAY "����"
            @ m_x + row + 1, _Next_Y SAY "   �"
            @ m_x + row + 2, _Next_Y SAY "  �"
            @ m_x + row + 3, _Next_Y SAY " �"
            @ m_x + row + 4, _Next_Y SAY "�"

        case _char = "8"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY "����"
            @ m_x + row + 1, _Next_Y SAY "�  �"
            @ m_x + row + 2, _Next_Y SAY " �� "
            @ m_x + row + 3, _Next_Y SAY "�  �"
            @ m_x + row + 4, _Next_Y SAY "����"
        
        case _char = "9"

            _next_y -= 5
         
            @ m_x + row + 0, _Next_Y SAY "����"
            @ m_x + row + 1, _Next_Y SAY "�  �"
            @ m_x + row + 2, _Next_Y SAY "����"
            @ m_x + row + 3, _Next_Y SAY "   �"
            @ m_x + row + 4, _Next_Y SAY "����"

        case _char = "0"

            _next_y -= 5

            @ m_x + row + 0, _Next_Y SAY " �� "
            @ m_x + row + 1, _Next_Y SAY "�  �"
            @ m_x + row + 2, _Next_Y SAY "�  �"
            @ m_x + row + 3, _Next_Y SAY "�  �"
            @ m_x + row + 4, _Next_Y SAY " ��"

        case _char = "."

            _next_y -= 2

            @ m_x + row + 4, _Next_Y SAY "�"

        case _char = "-"

            _next_y -= 4

            @ m_x + row + 2, _Next_Y SAY "���"

    endcase
next

return



//-----------------------------------------------------
// ispisuje iznos racuna u box-u
//-----------------------------------------------------
function ispisi_iznos_racuna_box( iznos )
local cIzn
local nCnt, Char, NextY
local nPrevRow := ROW()
local nPrevCol := COL()

SETPOS (0,0)

Box (, 9, 77)

    cIzn := ALLTRIM (TRANSFORM ( iznos, "9999999.99" ))

    @ m_x, m_y + 28 SAY "  IZNOS RACUNA JE  " COLOR INVERT

    NextY := m_y + 76

    FOR nCnt := LEN (cIzn) TO 1 STEP -1
        Char := SUBSTR (cIzn, nCnt, 1)
        DO CASE
        CASE Char = "1"
         NextY -= 6
         @ m_x+2, NextY SAY " ��"
         @ m_x+3, NextY SAY "  �"
         @ m_x+4, NextY SAY "  �"
         @ m_x+5, NextY SAY "  �"
         @ m_x+6, NextY SAY "  �"
         @ m_x+7, NextY SAY "  �"
         @ m_x+8, NextY SAY "  �"
         @ m_x+9, NextY SAY "�����"
        CASE Char = "2"
         NextY -= 8
         @ m_x+2, NextY SAY "�������"
         @ m_x+3, NextY SAY "      �"
         @ m_x+4, NextY SAY "      �"
         @ m_x+5, NextY SAY "�������"
         @ m_x+6, NextY SAY "�"
         @ m_x+7, NextY SAY "�"
         @ m_x+8, NextY SAY "�     �"
         @ m_x+9, NextY SAY "�������"
        CASE Char = "3"
         NextY -= 8
         @ m_x+2, NextY SAY " ������"
         @ m_x+3, NextY SAY "      �"
         @ m_x+4, NextY SAY "      �"
         @ m_x+5, NextY SAY "  ����"
         @ m_x+6, NextY SAY "      �"
         @ m_x+7, NextY SAY "      �"
         @ m_x+8, NextY SAY "      �"
         @ m_x+9, NextY SAY "�������"
        CASE Char = "4"
         NextY -= 8
         @ m_x+2, NextY SAY "�"
         @ m_x+3, NextY SAY "�"
         @ m_x+4, NextY SAY "�     �"
         @ m_x+5, NextY SAY "�     �"
         @ m_x+6, NextY SAY "�������"
         @ m_x+7, NextY SAY "      �"
         @ m_x+8, NextY SAY "      �"
         @ m_x+9, NextY SAY "      �"
        CASE Char = "5"
         NextY -= 8
         @ m_x+2, NextY SAY "�������"
         @ m_x+3, NextY SAY "�"
         @ m_x+4, NextY SAY "�"
         @ m_x+5, NextY SAY "�������"
         @ m_x+6, NextY SAY "      �"
         @ m_x+7, NextY SAY "      �"
         @ m_x+8, NextY SAY "�     �"
         @ m_x+9, NextY SAY "�������"
        CASE Char = "6"
         NextY -= 8
         @ m_x+2, NextY SAY "�������"
         @ m_x+3, NextY SAY "�"
         @ m_x+4, NextY SAY "�"
         @ m_x+5, NextY SAY "�������"
         @ m_x+6, NextY SAY "�     �"
         @ m_x+7, NextY SAY "�     �"
         @ m_x+8, NextY SAY "�     �"
         @ m_x+9, NextY SAY "�������"
        CASE Char = "7"
         NextY -= 8
         @ m_x+2, NextY SAY "�������"
         @ m_x+3, NextY SAY "      �"
         @ m_x+4, NextY SAY "     �"
         @ m_x+5, NextY SAY "    �"
         @ m_x+6, NextY SAY "   �"
         @ m_x+7, NextY SAY "  �"
         @ m_x+8, NextY SAY " �"
         @ m_x+9, NextY SAY "�"
        CASE Char = "8"
         NextY -= 8
         @ m_x+2, NextY SAY "�������"
         @ m_x+3, NextY SAY "�     �"
         @ m_x+4, NextY SAY "�     �"
         @ m_x+5, NextY SAY " ����� "
         @ m_x+6, NextY SAY "�     �"
         @ m_x+7, NextY SAY "�     �"
         @ m_x+8, NextY SAY "�     �"
         @ m_x+9, NextY SAY "�������"
        CASE Char = "9"
         NextY -= 8
         @ m_x+2, NextY SAY "�������"
         @ m_x+3, NextY SAY "�     �"
         @ m_x+4, NextY SAY "�     �"
         @ m_x+5, NextY SAY "�������"
         @ m_x+6, NextY SAY "      �"
         @ m_x+7, NextY SAY "      �"
         @ m_x+8, NextY SAY "�     �"
         @ m_x+9, NextY SAY "�������"
        CASE Char = "0"
         NextY -= 8
         @ m_x+2, NextY SAY " ����� "
         @ m_x+3, NextY SAY "�     �"
         @ m_x+4, NextY SAY "�     �"
         @ m_x+5, NextY SAY "�     �"
         @ m_x+6, NextY SAY "�     �"
         @ m_x+7, NextY SAY "�     �"
         @ m_x+8, NextY SAY "�     �"
         @ m_x+9, NextY SAY " �����"
        CASE Char = "."
         NextY -= 4
         @ m_x+9, NextY SAY "���"
        CASE Char = "-"
         NextY -= 6
         @ m_x+5, NextY SAY "�����"
    ENDCASE
NEXT

SETPOS (nPrevRow, nPrevCol)

return


/*! \fn SkloniIznosRac()
    \brief Pravo korisna funkcija ... ?!?
*/

function SkloniIznRac()
*{
BoxC()
return
*}

/*! \fn DummyProc()
 *  \brief
 */
 
function DummyProc()
*{
 return NIL
*}


/*! \fn PromIdCijena()
 *  \brief Promjena seta cijena
 *  \todo Ovu funkciju treba ugasiti, zajedno sa konceptom vise setova cijena, to treba generalno revidirati jer prakticno niko i ne koristi, a knjigovodstveno je sporno
 */

function PromIdCijena()
*{

LOCAL i:=0,j:=LEN(SC_Opisi)
LOCAL cbsstara:=ShemaBoja("B1")
 Prozor1(5,1,6+j+2,78,"SETOVI CIJENA",cbnaslova,,cbokvira,cbteksta,0)
 FOR i:=1 TO j
  @ 6+i,2 SAY IF(VAL(gIdCijena)==i,"->","  ")+;
              STR(i,3)+". "+PADR(SC_Opisi[i],40)+;
              IF(VAL(gIdCijena)==i," <- tekuci set","")
 NEXT
 VarEdit({{"Oznaka seta cijena","gIdCijena","VAL(gIdCijena)>0.and.VAL(gIdCijena)<=LEN(SC_Opisi)",,}},;
             6+j+3,1,6+j+7,78,"IZBOR SETA CIJENA","B1")
 Prozor0()
 ShemaBoja(cbsstara)
 pos_status_traka()
return
*}


/*! \fn PortZaMT(cIdDio,cIdOdj)
 *  \brief 
 *  \param cIdDio
 *  \param cIdOdj
 */
 
function PortZaMT(cIdDio,cIdOdj)
*{

LOCAL nObl:=SELECT(),cVrati:=gLocPort    // default port je gLocPort
  SELECT F_UREDJ; PushWA()
  IF ! USED()
    O_UREDJ
  ENDIF
  SELECT F_MJTRUR; PushWA()
  IF ! USED()
    O_MJTRUR
  ENDIF
  GO TOP; HSEEK cIdDio+cIdOdj
  IF FOUND()
    SELECT F_UREDJ
    GO TOP; HSEEK MJTRUR->iduredjaj
    cVrati:=ALLTRIM(port)
  ENDIF
  SELECT F_MJTRUR; PopWA()
  SELECT F_UREDJ; PopWA()
  SELECT (nObl)
return cVrati
*}




/*! \fn ProgKeyboard()
*
*   \brief Programiranje tastature
*
*/
function ProgKeyboard()
*{

local nKey1
local nKey2
local idroba
local fIzm
local nIzb
local aOpc[3]

aOpc:={"Izmjeni","Ukini","Ostavi"}

O_SIFK
O_SIFV
O_ROBA
O_K2C

Box(,10,75)
do while .t.
    @ m_x+1,m_y+3 SAY "Pritisnite tipku koju zelite programirati --> "
    nKey1:=INKEY(0)
    if nKey1==K_ESC
            EXIT
    endif
    if nKey1==K_ENTER
            MsgBeep("Ovu tipku ne mozete programirati")
            BoxCls()
            LOOP
    endif
    @ m_x+3,m_y+3 SAY "          Ponovite pritisak na istu tipku --> "
    nKey2:=INKEY(0)
    if nKey2==K_ESC
            EXIT
    endif
    if nKey1==K_ENTER
            MsgBeep("Ovu tipku ne mozete programirati")
            BoxCls()
            LOOP
    endif
    if nKey1<>nKey2
            Msg ("Pritisnute razlicite tipke! Ponovite proceduru", 10)
            BoxCLS ()
            LOOP
    endif
    fIzm:=.f.
    SELECT K2C
    set order to 1
    SEEK STR(nKey1,4)
    if FOUND ()
            Beep(3)
            nIzb:=KudaDalje("Tipka je vec programirana!!!", aOpc)
            do case
                case nIzb==0 .or. nIzb==3
                    LOOP
                case nIzb==1
                    fIzm:=.t.
                case nIzb==2
                    DELETE
                    LOOP
            endcase
    endif

    Scatter() // iz K2C
    @ m_x+5,m_y+3 SAY "Sifra robe koja se pridruzuje tipki:"
    @ m_x+6,m_y+13 GET _idroba VALID P_Roba(@_idroba,6,25).AND.NijeDuplo(_idroba, nKey1)
    READ
    if LASTKEY()=K_ESC
            EXIT
    endif

    SELECT K2C
    if !fIzm
            APPEND BLANK
            _KeyCode:=nKey1
    endif
    Gather()
    BoxCLS()
end
BoxC()
CLOSERET
return
*}


/*! \fn NijeDuplo(cIdRoba,nKey)
*   \brief Provjerava da li se pokusava staviti jedna roba na vise tipki 
*   \param cIdRoba - Id robe
*   \param nKey    - tipka
*   \return lFlag==.t. ili .f.
*/
function NijeDuplo(cIdRoba,nKey)
*{

local lFlag:=.t.
SELECT K2C
set order to 2
nCurrRec:=RECNO()
HSEEK cIdRoba
if FOUND().and.RECNO()<>nCurrRec
    Beep(2)
    Msg("Roba je vec pridruzena drugoj tipki!", 15)
    lFlag := .f.
endif
GO(nCurrRec)
return (lFlag)
*}


/*! \fn NazivRobe(cIdRoba)
 *  \brief
 *  \param cIdRoba
 */
 
function NazivRobe(cIdRoba)
*{
local nCurr:=SELECT()

select roba
HSEEK cIdRoba
SELECT nCurr
return (roba->Naz)
*}


/*! \fn Godina_2(dDatum)
 *  \brief
 *  \param dDatum
 */
 
function Godina_2(dDatum)
*{
//
// 01.01.99 -> "99"
// 01.01.00 -> "00"
return padl(alltrim(str(year(dDatum)%100,2,0)),2,"0")
*}


/*! \fn NenapPop()
 *  \brief
 */
 
function NenapPop()
*{
return iif(gPopVar="A","NENAPLACENO:","     POPUST:")
*}


/*! \fn InstallOps(cKorSif)
 *  \brief
 *  \param cKorSif
 */
 
function InstallOps(cKorSif)
*{
if cKorsif="I"
          cKom:=cKom:="I"+gModul+" "+imekorisn+" "+CryptSC(sifrakorisn)
endif
if cKorsif="IM"
          cKom+="  /M"
endif
if cKorsif="II"
          cKom+="  /I"
endif
if cKorsif="IR"
          cKom+="  /R"
endif
if cKorsif="IP"
          cKom+="  /P"
endif
if cKorsif="IB"
          cKom+="  /B"
endif
if cKorsif="I"
          RunInstall(cKom)
endif

return
*}

/*! \fn SetUser(cKorSif,nSifLen,cLevel)
 *  \brief
 *  \param cKorSif
 *  \param nSifLen
 *  \param cLevel
 */
 
function SetUser(cKorSif,nSifLen,cLevel)

O_STRAD
O_OSOB

cKorSif:=CryptSC(PADR(UPPER(TRIM(cKorSif)),nSifLen))
SELECT OSOB
Seek2(cKorSif)

if FOUND()
    gIdRadnik := ID     ; gKorIme   := Naz
    gSTRAD  := ALLTRIM (Status)
    SELECT STRAD
    Seek2 (OSOB->Status)
    IF FOUND ()
      cLevel := Prioritet
    ELSE
      cLevel := L_PRODAVAC ; gSTRAD := "K"
    ENDIF
    SELECT OSOB
    return 1
else
    MsgBeep ("Unijeta je nepostojeca lozinka!")
    SELECT OSOB
    return 0
endif

return 0


// ...........................................
// prikazuje status pos modula... 
// ...........................................
function pos_status_traka()
local _x := MAXROWS() - 3
local _y := 0

@ 1, _y + 1 SAY "RADI:"+PADR(LTRIM(gKorIme),31)+" SMJENA:"+gSmjena+" CIJENE:"+gIdCijena+" DATUM:"+DTOC(gDatum)+IF(gVrstaRS=="S","   SERVER  "," KASA-PM:"+gIdPos)

if gIdPos=="X "
    @ _x, _y + 1 SAY PADC( "$$$ --- PRODAJNO MJESTO X ! --- $$$", MAXCOLS() - 2, "�" )
else
    @ _x, _y + 1 SAY REPLICATE( "�", MAXCOLS() - 2 )
endif

@ _x - 1, _y + 1 SAY PADC ( Razrijedi (gKorIme), MAXCOLS() - 2 ) COLOR INVERT

return



/*! \fn SetBoje(gVrstaRS)
 *  \brief
 *  \param gVrstaRS
 */
 
function SetBoje(gVrstaRS)
*{

// postavljanje boja (samo C/B kombinacija dolazi u obzir, ako nije server)
IF gVrstaRS <> "S"
    Invert := "N/W,W/N,,,W/N"
    Normal := "W/N,N/W,,,N/W"
    Blink  := "N****/W,W/N,,,W/N"
    Nevid  := "W/W,N/N"
ENDIF

return
*}


