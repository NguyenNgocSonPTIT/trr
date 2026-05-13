ORG 100H

; ==============================================================
; GAME CARO NANG CAP - Assembly 8086
; Chon ban co: 3x3 / 5x5 / 10x10
; Che do: 2 nguoi choi | Danh voi may (AI)
; Giao dien mau sac dung INT 10H
; Chay tren EMU8086 va DOSBox (.COM file)
;
; CACH CHAY:
;   EMU8086: Mo file -> Compile -> Run
;   DOSBox:  nasm caro_game.asm -o caro_game.com
;            caro_game.com
;
; LUAT CHOI:
;   Ban 3x3: thang 3 o lien tiep
;   Ban 5x5: thang 3 o lien tiep
;   Ban 10x10: thang 5 o lien tiep
;   Nhap so hang va so cot (tu 0 den SIZE-1)
; ==============================================================

JMP START

; ============================================================
; VUNG DU LIEU
; ============================================================

BOARD   DB 100 DUP(0)   ; 0=trong 1=X 2=O

BSIZE   DB 3            ; Kich thuoc: 3, 5, hoac 10
WLEN    DB 3            ; So o lien tiep de thang
GMODE   DB 0            ; 0=2 nguoi  1=AI
CPLYR   DB 1            ; Nguoi choi hien tai: 1=X  2=O
NMOVES  DB 0            ; So nuoc da di
WINNER  DB 0            ; 0=chua xong  1=X  2=O  3=Hoa
TCELLS  DB 9            ; BSIZE*BSIZE

SCX     DB 0            ; Diem X
SCO     DB 0            ; Diem O
SCD     DB 0            ; So van hoa

BROW    DB 5            ; Dong bat dau ve ban co
BCOL    DB 28           ; Cot bat dau ve ban co

TR      DB 0            ; Hang nguoi choi nhap
TC      DB 0            ; Cot nguoi choi nhap
AIMV    DB 0            ; Nuoc AI chon (index 0..99)
AI_OK   DB 0            ; 1 neu AI tim duoc nuoc

; Bien dung trong CHKWIN / CHKDIR
VR      DB 0
VC      DB 0
VPLR    DB 0
VDIR_R  DB 0
VDIR_C  DB 0

; Bien tam noi bo CHKDIR
CD_HR   DB 0
CD_HC   DB 0

; ============================================================
; CHUOI VAN BAN (ket thuc bang '$')
; ============================================================

S_LINE  DB '================================================$'
S_T1    DB '   GAME CARO - ASM 8086 NANG CAP - v2.0       $'
S_T2    DB '   Ban 3x3 / 5x5 / 10x10  |  Che do AI        $'

S_MS0   DB ' CHON KICH THUOC BAN CO:$'
S_MS1   DB '  [1] Ban  3 x  3  (thang 3 o lien tiep)$'
S_MS2   DB '  [2] Ban  5 x  5  (thang 3 o lien tiep)$'
S_MS3   DB '  [3] Ban 10 x 10  (thang 5 o lien tiep)$'

S_MD0   DB ' CHON CHE DO:$'
S_MD1   DB '  [1] Hai nguoi choi (PvP)$'
S_MD2   DB '  [2] Danh voi may  (AI)$'

S_PICK  DB ' >> Lua chon: $'

S_TRN   DB ' LUOT: $'
S_PLX   DB 'X (Nguoi 1)$'
S_PLO   DB 'O (Nguoi 2)$'
S_PLAI  DB 'O (May AI) $'

S_IROW  DB ' Nhap HANG (0-?): $'
S_ICOL  DB ' Nhap COT  (0-?): $'

S_WX    DB ' *** NGUOI X CHIEN THANG! CHUC MUNG! ***$'
S_WO    DB ' *** NGUOI O CHIEN THANG! CHUC MUNG! ***$'
S_WAI   DB ' *** MAY (AI) CHIEN THANG! RAT TIEC... ***$'
S_DRAW  DB ' *** HOA NHAU! HAI BEN NGANG TAI ***$'
S_USED  DB ' O nay da co roi! Chon o khac.$'
S_INVL  DB ' So khong hop le! Nhap lai.    $'
S_AIWT  DB ' May dang suy nghi...          $'

S_SC1   DB ' SCORE: X=$'
S_SC2   DB '  O=$'
S_SC3   DB '  HOA=$'

S_AGN   DB ' Choi lai? [Y/N]: $'
S_BACK  DB ' Menu chinh? [Y/N]: $'
S_BYE   DB ' Cam on da choi! Hen gap lai!$'
S_GD    DB ' [Nhap hang 0..N-1 va cot 0..N-1]$'

; ============================================================
; CHUONG TRINH CHINH
; ============================================================

START:
    MOV AX, CS
    MOV DS, AX

; ---- MENU CHON KICH THUOC ----
MENU_SIZE:
    CALL CLR
    CALL SETBG
    CALL PRTHDR

    MOV DH, 6
    MOV DL, 2
    CALL GOXY
    MOV BL, 03FH
    LEA DX, S_MS0
    CALL PCOL

    MOV DH, 7
    MOV DL, 2
    CALL GOXY
    MOV BL, 01FH
    LEA DX, S_MS1
    CALL PCOL

    MOV DH, 8
    MOV DL, 2
    CALL GOXY
    LEA DX, S_MS2
    CALL PCOL

    MOV DH, 9
    MOV DL, 2
    CALL GOXY
    LEA DX, S_MS3
    CALL PCOL

    MOV DH, 11
    MOV DL, 2
    CALL GOXY
    MOV BL, 01EH
    LEA DX, S_PICK
    CALL PCOL

    MOV AH, 01H
    INT 21H

    CMP AL, '1'
    JNE MS2
    MOV BSIZE,  3
    MOV WLEN,   3
    MOV TCELLS, 9
    MOV BROW,   5
    MOV BCOL,   28
    JMP MENU_MODE
MS2:
    CMP AL, '2'
    JNE MS3
    MOV BSIZE,  5
    MOV WLEN,   3
    MOV TCELLS, 25
    MOV BROW,   4
    MOV BCOL,   20
    JMP MENU_MODE
MS3:
    CMP AL, '3'
    JNE MENU_SIZE
    MOV BSIZE,  10
    MOV WLEN,   5
    MOV TCELLS, 100
    MOV BROW,   3
    MOV BCOL,   2

; ---- MENU CHON CHE DO ----
MENU_MODE:
    CALL CLR
    CALL SETBG
    CALL PRTHDR

    MOV DH, 6
    MOV DL, 2
    CALL GOXY
    MOV BL, 03FH
    LEA DX, S_MD0
    CALL PCOL

    MOV DH, 7
    MOV DL, 2
    CALL GOXY
    MOV BL, 01FH
    LEA DX, S_MD1
    CALL PCOL

    MOV DH, 8
    MOV DL, 2
    CALL GOXY
    LEA DX, S_MD2
    CALL PCOL

    MOV DH, 10
    MOV DL, 2
    CALL GOXY
    MOV BL, 01EH
    LEA DX, S_PICK
    CALL PCOL

    MOV AH, 01H
    INT 21H

    CMP AL, '1'
    JE  MD_2P
    CMP AL, '2'
    JE  MD_AI
    JMP MENU_MODE
MD_2P:
    MOV GMODE, 0
    JMP NEW_GAME
MD_AI:
    MOV GMODE, 1

; ---- VAN MOI ----
NEW_GAME:
    CALL RESET_BRD
    CALL DRAW_SCR

; ---- VONG CHOI ----
GLOOP:
    CALL SHOW_TRN

    CMP GMODE, 1
    JNE GL_HMN
    CMP CPLYR, 2
    JNE GL_HMN
    CALL DO_AI
    JMP GL_AFT
GL_HMN:
    CALL DO_HMN
GL_AFT:
    ; Kiem tra thang
    MOV AL, CPLYR
    CALL CHKWIN
    CMP AL, 0
    JE  GL_DRAW

    MOV AL, CPLYR
    MOV WINNER, AL
    CALL DRAW_SCR
    CALL SHOW_WIN
    JMP REPLAY

GL_DRAW:
    MOV AL, NMOVES
    CMP AL, TCELLS
    JNE GL_CONT
    MOV WINNER, 3
    CALL DRAW_SCR
    CALL SHOW_DRAW
    JMP REPLAY

GL_CONT:
    MOV AL, CPLYR
    CMP AL, 1
    JNE GC_SO
    MOV CPLYR, 2
    JMP GLOOP
GC_SO:
    MOV CPLYR, 1
    JMP GLOOP

REPLAY:
    MOV DH, 22
    MOV DL, 2
    CALL GOXY
    MOV BL, 01FH
    LEA DX, S_AGN
    CALL PCOL

    MOV AH, 01H
    INT 21H
    CMP AL, 'Y'
    JE  NEW_GAME
    CMP AL, 'y'
    JE  NEW_GAME
    CMP AL, 'N'
    JE  REPLAY2
    CMP AL, 'n'
    JE  REPLAY2
    JMP REPLAY

REPLAY2:
    MOV DH, 23
    MOV DL, 2
    CALL GOXY
    MOV BL, 01FH
    LEA DX, S_BACK
    CALL PCOL

    MOV AH, 01H
    INT 21H
    CMP AL, 'Y'
    JE  MENU_SIZE
    CMP AL, 'y'
    JE  MENU_SIZE

    CALL CLR
    CALL SETBG
    MOV DH, 12
    MOV DL, 18
    CALL GOXY
    MOV BL, 01EH
    LEA DX, S_BYE
    CALL PCOL
    MOV AH, 4CH
    INT 21H

; ============================================================
; PROC: RESET_BRD
; ============================================================
RESET_BRD PROC
    MOV CX, 100
    LEA DI, BOARD
    MOV AL, 0
RB_L:
    MOV [DI], AL
    INC DI
    LOOP RB_L
    MOV CPLYR,  1
    MOV NMOVES, 0
    MOV WINNER, 0
    RET
RESET_BRD ENDP

; ============================================================
; PROC: DRAW_SCR - Ve man hinh game
; ============================================================
DRAW_SCR PROC
    CALL CLR
    CALL SETBG
    CALL PRTHDR
    CALL DBOARD
    CALL DSCORE
    CALL DGUIDE
    RET
DRAW_SCR ENDP

; ============================================================
; PROC: DBOARD - Ve ban co
; Su dung CH=hang, CL=cot (bien dem noi bo)
; ============================================================
DBOARD PROC
    MOV CH, 0           ; hang = 0
DB_ROW:
    MOV AL, BSIZE
    CMP CH, AL
    JAE DB_END

    MOV CL, 0           ; cot = 0
DB_COL:
    MOV AL, BSIZE
    CMP CL, AL
    JAE DB_NROW

    ; Tinh dong man hinh = BROW + hang*2
    MOV AL, CH
    SHL AL, 1
    ADD AL, BROW
    MOV DH, AL

    ; Tinh cot man hinh = BCOL + cot*4
    MOV AL, CL
    SHL AL, 1
    SHL AL, 1
    ADD AL, BCOL
    MOV DL, AL
    CALL GOXY

    ; Index = hang * BSIZE + cot
    MOV AL, CH
    MUL BSIZE           ; AX = CH * BSIZE  (AH=0 vi BSIZE<=10)
    ADD AL, CL
    MOV AH, 0
    MOV SI, AX
    MOV AL, BOARD[SI]

    CMP AL, 0
    JE  DBE
    CMP AL, 1
    JE  DBX
    ; Ve O
    MOV BL, 01CH
    MOV DL, 'O'
    CALL PCH
    JMP DBSEP
DBX:
    ; Ve X
    MOV BL, 01EH
    MOV DL, 'X'
    CALL PCH
    JMP DBSEP
DBE:
    ; Ve o trong
    MOV BL, 017H
    MOV DL, '.'
    CALL PCH

DBSEP:
    ; Ke cot (tru cot cuoi)
    MOV AL, BSIZE
    DEC AL
    CMP CL, AL
    JE  DB_NCOL
    MOV BL, 01BH
    MOV DL, '|'
    CALL PCH
    MOV BL, 017H
    MOV DL, ' '
    CALL PCH

DB_NCOL:
    INC CL
    JMP DB_COL

DB_NROW:
    ; Ke hang (tru hang cuoi)
    MOV AL, BSIZE
    DEC AL
    CMP CH, AL
    JE  DB_NHLINE

    MOV AL, CH
    SHL AL, 1
    INC AL
    ADD AL, BROW
    MOV DH, AL
    MOV DL, BCOL
    CALL GOXY

    ; Do rong ke = BSIZE*4 - 1
    MOV AL, BSIZE
    SHL AL, 1
    SHL AL, 1
    DEC AL
    MOV AH, 0
    MOV CX, AX
DBHL:
    MOV BL, 01BH
    MOV DL, '-'
    CALL PCH
    LOOP DBHL

DB_NHLINE:
    INC CH
    JMP DB_ROW

DB_END:
    RET
DBOARD ENDP

; ============================================================
; PROC: SHOW_TRN - Hien thi luot choi
; ============================================================
SHOW_TRN PROC
    ; Dong = BROW + BSIZE*2 + 1
    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    INC AL
    MOV DH, AL
    MOV DL, 2
    CALL GOXY

    ; Xoa dong
    MOV CX, 50
STN_C:
    MOV BL, 017H
    MOV DL, ' '
    CALL PCH
    LOOP STN_C

    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    INC AL
    MOV DH, AL
    MOV DL, 2
    CALL GOXY

    MOV BL, 01FH
    LEA DX, S_TRN
    CALL PCOL

    MOV AL, CPLYR
    CMP AL, 1
    JNE STN_O
    MOV BL, 01EH
    LEA DX, S_PLX
    CALL PCOL
    RET
STN_O:
    CMP GMODE, 1
    JNE STN_O2P
    MOV BL, 01CH
    LEA DX, S_PLAI
    CALL PCOL
    RET
STN_O2P:
    MOV BL, 01CH
    LEA DX, S_PLO
    CALL PCOL
    RET
SHOW_TRN ENDP

; ============================================================
; PROC: DO_HMN - Nguoi choi nhap nuoc
; ============================================================
DO_HMN PROC
    ; Tinh dong nhap = BROW + BSIZE*2 + 2
    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    ADD AL, 2
    MOV BH, AL          ; BH = dong bat dau nhap

HG_LP:
    ; Xoa 3 dong nhap
    MOV DH, BH
    MOV DL, 2
    CALL GOXY
    MOV CX, 55
HGC1:
    MOV BL, 017H
    MOV DL, ' '
    CALL PCH
    LOOP HGC1

    MOV AL, BH
    INC AL
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV CX, 55
HGC2:
    MOV BL, 017H
    MOV DL, ' '
    CALL PCH
    LOOP HGC2

    MOV AL, BH
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV CX, 50
HGC3:
    MOV BL, 017H
    MOV DL, ' '
    CALL PCH
    LOOP HGC3

    ; Nhap hang
    MOV DH, BH
    MOV DL, 2
    CALL GOXY
    MOV BL, 03FH
    LEA DX, S_IROW
    CALL PCOL

    MOV AH, 01H
    INT 21H

    CMP AL, '0'
    JB  HG_INV

    ; Gioi han tren: '0' + BSIZE - 1
    MOV AH, BSIZE
    ADD AH, '0'
    DEC AH
    CMP AL, AH
    JA  HG_INV

    SUB AL, '0'
    MOV TR, AL

    ; Nhap cot
    MOV AL, BH
    INC AL
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV BL, 03FH
    LEA DX, S_ICOL
    CALL PCOL

    MOV AH, 01H
    INT 21H

    CMP AL, '0'
    JB  HG_INV

    MOV AH, BSIZE
    ADD AH, '0'
    DEC AH
    CMP AL, AH
    JA  HG_INV

    SUB AL, '0'
    MOV TC, AL

    ; Index = TR * BSIZE + TC
    MOV AL, TR
    MUL BSIZE
    ADD AL, TC
    MOV AH, 0
    MOV SI, AX

    CMP BOARD[SI], 0
    JNE HG_USED

    MOV AL, CPLYR
    MOV BOARD[SI], AL
    INC NMOVES
    CALL DBOARD
    RET

HG_INV:
    MOV AL, BH
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV BL, 01CH
    LEA DX, S_INVL
    CALL PCOL
    MOV AH, 08H
    INT 21H
    JMP HG_LP

HG_USED:
    MOV AL, BH
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV BL, 01CH
    LEA DX, S_USED
    CALL PCOL
    MOV AH, 08H
    INT 21H
    JMP HG_LP
DO_HMN ENDP

; ============================================================
; PROC: DO_AI - Nuoc di cua may
; Chien luoc: thang ngay > chan X > trung tam > goc > o trong dau
; ============================================================
DO_AI PROC
    ; Hien thi thong bao
    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV BL, 01BH
    LEA DX, S_AIWT
    CALL PCOL

    MOV AIMV,  0
    MOV AI_OK, 0

    ; B1: Tim nuoc thang cua O(2)
    MOV VPLR, 2
    CALL FINDWIN
    CMP AI_OK, 1
    JE  AI_PLACE

    ; B2: Chan nuoc thang X(1)
    MOV VPLR, 1
    CALL FINDWIN
    CMP AI_OK, 1
    JE  AI_PLACE

    ; B3: Trung tam = TCELLS / 2
    MOV AL, TCELLS
    SHR AL, 1
    MOV AH, 0
    MOV SI, AX
    CMP BOARD[SI], 0
    JNE AI_CORN
    MOV AIMV, AL
    MOV AI_OK, 1
    JMP AI_PLACE

AI_CORN:
    ; Goc trai tren (index 0)
    CMP BOARD[0], 0
    JNE AI_C2
    MOV AIMV,  0
    MOV AI_OK, 1
    JMP AI_PLACE
AI_C2:
    ; Goc phai tren (index BSIZE-1)
    MOV AL, BSIZE
    DEC AL
    MOV AH, 0
    MOV SI, AX
    CMP BOARD[SI], 0
    JNE AI_SCAN
    MOV AIMV,  AL
    MOV AI_OK, 1
    JMP AI_PLACE

AI_SCAN:
    ; Tim o trong dau tien
    MOV SI, 0
AI_SLP:
    MOV AL, TCELLS
    MOV AH, 0
    CMP SI, AX
    JAE AI_PLACE
    CMP BOARD[SI], 0
    JNE AI_SNX
    MOV AL, SI
    MOV AIMV,  AL
    MOV AI_OK, 1
    JMP AI_PLACE
AI_SNX:
    INC SI
    JMP AI_SLP

AI_PLACE:
    CMP AI_OK, 0
    JE  AI_DONE

    MOV AL, AIMV
    MOV AH, 0
    MOV SI, AX
    MOV BOARD[SI], 2
    INC NMOVES
    CALL DBOARD

    ; Xoa thong bao
    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV CX, 40
AICLR:
    MOV BL, 017H
    MOV DL, ' '
    CALL PCH
    LOOP AICLR

AI_DONE:
    RET
DO_AI ENDP

; ============================================================
; PROC: FINDWIN
; Tim o trong ma neu dat VPLR vao thi thang
; Ket qua: AIMV = index, AI_OK = 1 neu tim thay
; ============================================================
FINDWIN PROC
    MOV SI, 0
FW_LP:
    MOV AL, TCELLS
    MOV AH, 0
    CMP SI, AX
    JAE FW_DONE

    CMP BOARD[SI], 0
    JNE FW_NX

    ; Thu dat
    MOV AL, VPLR
    MOV BOARD[SI], AL

    MOV AL, VPLR
    CALL CHKWIN         ; ket qua AL
    PUSH AX
    MOV BOARD[SI], 0    ; hoan tac
    POP AX

    CMP AL, 0
    JE  FW_NX
    ; Tim duoc
    MOV AL, SI
    MOV AIMV,  AL
    MOV AI_OK, 1
    RET

FW_NX:
    INC SI
    JMP FW_LP
FW_DONE:
    RET
FINDWIN ENDP

; ============================================================
; PROC: CHKWIN
; Input:  AL = player (1 hoac 2)
; Output: AL = 1 neu thang, 0 neu chua
; Dung bien VR, VC, VPLR (da duoc dat truoc)
; ============================================================
CHKWIN PROC
    MOV VPLR, AL

    MOV VR, 0
CWR:
    MOV AL, BSIZE
    CMP VR, AL
    JAE CW_NO

    MOV VC, 0
CWC:
    MOV AL, BSIZE
    CMP VC, AL
    JAE CW_NROW

    ; Index = VR * BSIZE + VC
    MOV AL, VR
    MUL BSIZE
    ADD AL, VC
    MOV AH, 0
    MOV SI, AX

    MOV AL, BOARD[SI]
    CMP AL, VPLR
    JNE CW_NCOL

    ; Kiem tra 4 huong
    MOV VDIR_R, 0
    MOV VDIR_C, 1
    CALL CHKDIR
    CMP AL, 1
    JE  CW_YES

    MOV VDIR_R, 1
    MOV VDIR_C, 0
    CALL CHKDIR
    CMP AL, 1
    JE  CW_YES

    MOV VDIR_R, 1
    MOV VDIR_C, 1
    CALL CHKDIR
    CMP AL, 1
    JE  CW_YES

    ; Cheo nguoc: di xuong, sang trai
    ; Dung: neu CL >= WLEN-1 thi moi co the di sang trai
    MOV VDIR_R, 1
    MOV VDIR_C, 255     ; -1 (mod 256), kiem tra bien trong CHKDIR
    CALL CHKDIR
    CMP AL, 1
    JE  CW_YES

CW_NCOL:
    INC VC
    JMP CWC

CW_NROW:
    INC VR
    JMP CWR

CW_NO:
    MOV AL, 0
    RET
CW_YES:
    MOV AL, 1
    RET
CHKWIN ENDP

; ============================================================
; PROC: CHKDIR
; Kiem tra WLEN o lien tiep tu (VR,VC) theo huong (VDIR_R,VDIR_C)
; Output: AL = 1 neu co du WLEN o cua VPLR
; ============================================================
CHKDIR PROC
    MOV CL, 0           ; k = 0 (buoc di)
    MOV CH, 0           ; dem = 0

CD_LP:
    MOV AL, WLEN
    CMP CL, AL
    JAE CD_CHECK

    ; hang_moi = VR + k * VDIR_R
    MOV AL, CL
    MUL VDIR_R          ; AX = k * VDIR_R
    ADD AL, VR
    ; Neu VDIR_R = 0 thi AH = 0, AL = VR (OK)
    ; Neu VDIR_R = 1 thi AH = 0, AL = VR + k
    ; AH tu MUL byte luon = 0 vi k,VDIR_R < 256
    MOV CD_HR, AL       ; luu hang moi

    CMP AL, BSIZE       ; hang >= BSIZE?
    JAE CD_FAIL

    ; cot_moi = VC + k * VDIR_C
    MOV AL, CL
    MUL VDIR_C          ; AX = k * VDIR_C
    ; Neu VDIR_C = 255 (-1): AL = (255*k) mod 256
    ; Vi du k=1: AL=255, VC=0 -> 255+0=255 >= BSIZE -> FAIL (dung)
    ; Vi du k=1: AL=255, VC=2 -> 255+2=1 (overflow byte) -> < BSIZE (sai)
    ; => Can kiem tra rieng truong hop VDIR_C = 255
    ADD AL, VC
    MOV CD_HC, AL       ; luu cot moi

    ; Kiem tra bien cot
    CMP AL, BSIZE       ; cot >= BSIZE (unsigned)?
    JAE CD_FAIL

    ; Index = hang_moi * BSIZE + cot_moi
    MOV AL, CD_HR
    MUL BSIZE
    ADD AL, CD_HC
    MOV AH, 0
    MOV SI, AX

    MOV AL, BOARD[SI]
    CMP AL, VPLR
    JNE CD_FAIL

    INC CH
    INC CL
    JMP CD_LP

CD_CHECK:
    MOV AL, CH
    CMP AL, WLEN
    JNE CD_FAIL
    MOV AL, 1
    RET
CD_FAIL:
    MOV AL, 0
    RET
CHKDIR ENDP

; ============================================================
; PROC: SHOW_WIN - In thong bao thang
; ============================================================
SHOW_WIN PROC
    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV BL, 02EH        ; Vang tren xanh la

    MOV AL, WINNER
    CMP AL, 1
    JNE SW_O
    LEA DX, S_WX
    CALL PCOL
    INC SCX
    RET
SW_O:
    CMP GMODE, 1
    JNE SW_O2
    LEA DX, S_WAI
    CALL PCOL
    INC SCO
    RET
SW_O2:
    LEA DX, S_WO
    CALL PCOL
    INC SCO
    RET
SHOW_WIN ENDP

; ============================================================
; PROC: SHOW_DRAW - In thong bao hoa
; ============================================================
SHOW_DRAW PROC
    MOV AL, BSIZE
    SHL AL, 1
    ADD AL, BROW
    ADD AL, 2
    MOV DH, AL
    MOV DL, 2
    CALL GOXY
    MOV BL, 01EH
    LEA DX, S_DRAW
    CALL PCOL
    INC SCD
    RET
SHOW_DRAW ENDP

; ============================================================
; PROC: DSCORE - Hien thi diem so
; ============================================================
DSCORE PROC
    MOV DH, 2
    MOV DL, 42
    CALL GOXY
    MOV BL, 01FH
    LEA DX, S_SC1
    CALL PCOL

    MOV BL, 01EH
    MOV AL, SCX
    ADD AL, '0'
    MOV DL, AL
    CALL PCH

    MOV BL, 01FH
    LEA DX, S_SC2
    CALL PCOL

    MOV BL, 01CH
    MOV AL, SCO
    ADD AL, '0'
    MOV DL, AL
    CALL PCH

    MOV BL, 01FH
    LEA DX, S_SC3
    CALL PCOL

    MOV BL, 01BH
    MOV AL, SCD
    ADD AL, '0'
    MOV DL, AL
    CALL PCH
    RET
DSCORE ENDP

; ============================================================
; PROC: DGUIDE - In huong dan ngan o dong cuoi
; ============================================================
DGUIDE PROC
    MOV DH, 24
    MOV DL, 0
    CALL GOXY
    MOV BL, 01BH
    LEA DX, S_GD
    CALL PCOL
    RET
DGUIDE ENDP

; ============================================================
; PROC: PRTHDR - In tieu de 4 dong dau
; ============================================================
PRTHDR PROC
    MOV DH, 0
    MOV DL, 0
    CALL GOXY
    MOV BL, 01FH
    LEA DX, S_LINE
    CALL PCOL

    MOV DH, 1
    MOV DL, 0
    CALL GOXY
    LEA DX, S_T1
    CALL PCOL

    MOV DH, 2
    MOV DL, 0
    CALL GOXY
    LEA DX, S_T2
    CALL PCOL

    MOV DH, 3
    MOV DL, 0
    CALL GOXY
    LEA DX, S_LINE
    CALL PCOL
    RET
PRTHDR ENDP

; ============================================================
; PROC: SETBG - To nen xanh dam toan man hinh
; ============================================================
SETBG PROC
    MOV AX, 0600H
    MOV BH, 017H
    MOV CX, 0000H
    MOV DX, 184FH
    INT 10H
    RET
SETBG ENDP

; ============================================================
; PROC: CLR - Xoa man hinh
; ============================================================
CLR PROC
    MOV AH, 00H
    MOV AL, 03H
    INT 10H
    RET
CLR ENDP

; ============================================================
; PROC: GOXY - Di chuyen con tro (DH=dong, DL=cot)
; ============================================================
GOXY PROC
    MOV AH, 02H
    MOV BH, 00H
    INT 10H
    RET
GOXY ENDP

; ============================================================
; PROC: PCOL - In chuoi co mau BL (chuoi ket thuc bang '$')
; Input: DX = dia chi chuoi, BL = mau (color attribute)
; ============================================================
PCOL PROC
    PUSH SI
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV SI, DX
    MOV BH, 0
PCOL_L:
    MOV AL, [SI]
    CMP AL, '$'
    JE  PCOL_D
    MOV AH, 09H
    MOV CX, 1
    INT 10H
    ; Dich con tro sang phai 1 o
    MOV AH, 03H
    INT 10H
    INC DL
    MOV AH, 02H
    INT 10H
    INC SI
    JMP PCOL_L
PCOL_D:
    POP DX
    POP CX
    POP BX
    POP AX
    POP SI
    RET
PCOL ENDP

; ============================================================
; PROC: PCH - In 1 ky tu co mau
; Input: DL = ky tu, BL = mau
; ============================================================
PCH PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV BH, 0
    MOV AH, 09H
    MOV AL, DL
    MOV CX, 1
    INT 10H
    MOV AH, 03H
    INT 10H
    INC DL
    MOV AH, 02H
    INT 10H
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PCH ENDP

; ============================================================
END