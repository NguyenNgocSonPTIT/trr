; ============================================================
;  PONG VGA - Assembly 8086 cho EMU8086
;  VGA Mode 13h: 320x200, 256 mau, VRAM tai A000:0000
;  Tac gia: Claude Sonnet 4.6
; ============================================================
;
;  DIEU KHIEN:
;    W / S  -> Di chuyen paddle TRAI len/xuong
;    O / L  -> Di chuyen paddle PHAI len/xuong
;    ESC    -> Thoat game
;
;  KY THUAT:
;    - INT 10H / AL=13H  : Chuyen sang VGA Mode 13h
;    - MOV ES, 0A000H    : Tro ES thang vao VRAM
;    - STOSB / MOV [ES:BX]: Ghi pixel truc tiep - SIEU NHANH
;    - Double buffering don gian (xoa->ve)
; ============================================================

.model small
.stack 200h

.data
    ; ---- Trang thai qua bong ----
    ball_x      dw  160      ; Vi tri X qua bong (giua man hinh)
    ball_y      dw  100      ; Vi tri Y qua bong
    ball_dx     dw  2        ; Toc do X (+2 hoac -2)
    ball_dy     dw  1        ; Toc do Y (+1 hoac -1)
    ball_size   dw  4        ; Kich thuoc qua bong (4x4 pixel)

    ; ---- Paddle TRAI (Player 1: W/S) ----
    pad1_x      dw  8        ; Vi tri X paddle trai
    pad1_y      dw  76       ; Vi tri Y paddle trai (giua doc)
    pad1_h      dw  48       ; Chieu cao paddle
    pad1_w      dw  6        ; Chieu rong paddle
    pad1_score  dw  0        ; Diem nguoi choi 1

    ; ---- Paddle PHAI (Player 2: O/L) ----
    pad2_x      dw  306      ; Vi tri X paddle phai (320-8-6)
    pad2_y      dw  76       ; Vi tri Y paddle phai
    pad2_h      dw  48       ; Chieu cao paddle
    pad2_w      dw  6        ; Chieu rong paddle
    pad2_score  dw  0        ; Diem nguoi choi 2

    ; ---- Hang so man hinh ----
    SCREEN_W    equ 320
    SCREEN_H    equ 200

    ; ---- Hang so mau sac (VGA Palette mac dinh) ----
    CLR_BLACK   equ 0        ; Den
    CLR_WHITE   equ 15       ; Trang sang
    CLR_CYAN    equ 11       ; Xanh lam sang (qua bong)
    CLR_GREEN   equ 10       ; Xanh la sang (paddle trai)
    CLR_RED     equ 12       ; Do sang (paddle phai)
    CLR_YELLOW  equ 14       ; Vang (duong giua)
    CLR_GRAY    equ 8        ; Xam (vien)

    ; ---- Bien phu ----
    game_over   db  0        ; Co game over
    winner      db  0        ; 1=P1 thang, 2=P2 thang
    frame_count dw  0        ; Dem frame (de delay)

.code
main proc
    ; ---- Khoi tao Data Segment ----
    mov  ax, @data
    mov  ds, ax

    ; ---- Chuyen sang VGA Mode 13h ----
    ; INT 10H: AH=00H, AL=13H -> 320x200, 256 mau
    mov  ax, 0013h
    int  10h

    ; ---- Tro ES vao VRAM A000:0000 ----
    ; Day la KHAI BAO QUAN TRONG NHAT:
    ; Moi byte trong vung nho A000:0000..A000:F9FF
    ; tuong ung 1 pixel tren man hinh
    ; pixel(x,y) = ES:[y*320 + x]
    mov  ax, 0A000h
    mov  es, ax

    ; ---- Ve man hinh khoi dong ----
    call clear_screen
    call draw_border
    call draw_center_line

game_loop:
    ; ---- Kiem tra phim bam (khong blocking) ----
    call handle_input

    ; ---- Kiem tra game over ----
    cmp  [game_over], 1
    je   game_end

    ; ---- Cap nhat logic qua bong ----
    call update_ball

    ; ---- Ve lai man hinh ----
    call render_frame

    ; ---- Delay nho de kiem soat toc do ----
    call delay_frame

    jmp  game_loop

game_end:
    call show_winner
    ; Doi phim bat ky
    mov  ah, 00h
    int  16h

    ; ---- Phuc hoi Text Mode ----
    mov  ax, 0003h
    int  10h

    ; ---- Thoat chuong trinh ----
    mov  ax, 4C00h
    int  21h
main endp

; ============================================================
;  XU LY INPUT - Kiem tra phim khong blocking
; ============================================================
handle_input proc
    ; Kiem tra co phim nao duoc nhan khong
    mov  ah, 01h
    int  16h
    jz   input_done      ; ZF=1 neu khong co phim -> bo qua

    ; Co phim -> doc phim
    mov  ah, 00h
    int  16h
    ; AL = ASCII code

    ; ---- ESC -> Thoat ----
    cmp  al, 27
    je   quit_game

    ; ---- W -> Paddle trai di len ----
    cmp  al, 'w'
    je   pad1_up
    cmp  al, 'W'
    je   pad1_up

    ; ---- S -> Paddle trai di xuong ----
    cmp  al, 's'
    je   pad1_down
    cmp  al, 'S'
    je   pad1_down

    ; ---- O -> Paddle phai di len ----
    cmp  al, 'o'
    je   pad2_up
    cmp  al, 'O'
    je   pad2_up

    ; ---- L -> Paddle phai di xuong ----
    cmp  al, 'l'
    je   pad2_down
    cmp  al, 'L'
    je   pad2_down

    jmp  input_done

pad1_up:
    cmp  [pad1_y], 2       ; Kiem tra bien tren (+ vien)
    jle  input_done
    sub  [pad1_y], 3       ; Di len 3 pixel
    jmp  input_done

pad1_down:
    mov  ax, [pad1_y]
    add  ax, [pad1_h]
    cmp  ax, SCREEN_H-2    ; Kiem tra bien duoi
    jge  input_done
    add  [pad1_y], 3       ; Di xuong 3 pixel
    jmp  input_done

pad2_up:
    cmp  [pad2_y], 2
    jle  input_done
    sub  [pad2_y], 3
    jmp  input_done

pad2_down:
    mov  ax, [pad2_y]
    add  ax, [pad2_h]
    cmp  ax, SCREEN_H-2
    jge  input_done
    add  [pad2_y], 3
    jmp  input_done

quit_game:
    mov  ax, 0003h         ; Phuc hoi text mode truoc khi thoat
    int  10h
    mov  ax, 4C00h
    int  21h

input_done:
    ret
handle_input endp

; ============================================================
;  CAP NHAT LOGIC QUA BONG
; ============================================================
update_ball proc
    ; ---- Di chuyen qua bong ----
    mov  ax, [ball_dx]
    add  [ball_x], ax
    mov  ax, [ball_dy]
    add  [ball_y], ax

    ; ---- Kiem tra bien TREN (y <= 1) ----
    cmp  [ball_y], 1
    jg   check_bottom
    mov  [ball_y], 1
    neg  [ball_dy]         ; Doi huong Y

check_bottom:
    ; ---- Kiem tra bien DUOI (y+size >= 199) ----
    mov  ax, [ball_y]
    add  ax, [ball_size]
    cmp  ax, SCREEN_H-1
    jl   check_paddles
    mov  ax, SCREEN_H-1
    sub  ax, [ball_size]
    mov  [ball_y], ax
    neg  [ball_dy]

check_paddles:
    ; ---- Va cham Paddle TRAI ----
    ; Kiem tra: ball_x <= pad1_x + pad1_w
    ;           ball_y+size >= pad1_y
    ;           ball_y <= pad1_y + pad1_h
    mov  ax, [ball_x]
    cmp  ax, 14            ; pad1_x + pad1_w = 8+6 = 14
    jg   check_pad2

    mov  ax, [ball_y]
    add  ax, [ball_size]
    cmp  ax, [pad1_y]
    jl   miss_left         ; Bong di qua paddle -> ghi diem P2

    mov  ax, [ball_y]
    mov  bx, [pad1_y]
    add  bx, [pad1_h]
    cmp  ax, bx
    jg   miss_left

    ; Va cham! Doi huong X, dat bong ra ngoai paddle
    mov  [ball_x], 15
    neg  [ball_dx]
    jmp  check_score

miss_left:
    ; P2 ghi diem
    cmp  [ball_x], 0
    jge  check_pad2
    inc  [pad2_score]
    call reset_ball
    jmp  check_score

check_pad2:
    ; ---- Va cham Paddle PHAI ----
    mov  ax, [ball_x]
    add  ax, [ball_size]
    cmp  ax, [pad2_x]      ; 306
    jl   check_score

    mov  ax, [ball_y]
    add  ax, [ball_size]
    cmp  ax, [pad2_y]
    jl   miss_right

    mov  ax, [ball_y]
    mov  bx, [pad2_y]
    add  bx, [pad2_h]
    cmp  ax, bx
    jg   miss_right

    ; Va cham!
    mov  [ball_x], 305
    neg  [ball_dx]
    jmp  check_score

miss_right:
    ; P1 ghi diem
    mov  ax, [ball_x]
    cmp  ax, SCREEN_W
    jl   check_score
    inc  [pad1_score]
    call reset_ball

check_score:
    ; ---- Kiem tra thang (dat 7 diem) ----
    cmp  [pad1_score], 7
    jl   check_score2
    mov  [game_over], 1
    mov  [winner], 1
    ret

check_score2:
    cmp  [pad2_score], 7
    jl   update_done
    mov  [game_over], 1
    mov  [winner], 2

update_done:
    ret
update_ball endp

; ============================================================
;  DAT LAI QUA BONG VE TRUNG TAM
; ============================================================
reset_ball proc
    mov  [ball_x], 160
    mov  [ball_y], 100
    ; Doi huong X moi lan dat lai
    neg  [ball_dx]
    ret
reset_ball endp

; ============================================================
;  VE TOAN BO MAN HINH (RENDER FRAME)
;  Xoa -> Ve vien -> Ve duong giua -> Ve paddles -> Ve bong -> Ve diem
; ============================================================
render_frame proc
    call clear_screen
    call draw_border
    call draw_center_line
    call draw_paddle1
    call draw_paddle2
    call draw_ball
    call draw_scores
    ret
render_frame endp

; ============================================================
;  XOA MAN HINH - To den toan bo 320x200 = 64000 bytes
;  Dung REP STOSB de to nhanh nhat co the
; ============================================================
clear_screen proc
    ; ES da tro vao A000h tu truoc
    xor  di, di            ; DI = 0 (bat dau tu pixel (0,0))
    mov  cx, SCREEN_W * SCREEN_H  ; 64000 pixel
    mov  al, CLR_BLACK     ; Mau den
    rep  stosb             ; To 64000 byte lien tiep = XOA MAN HINH
    ret
clear_screen endp

; ============================================================
;  VE VIEN MAN HINH (mau xam)
; ============================================================
draw_border proc
    ; Duong tren (y=0): 320 pixel
    xor  di, di
    mov  cx, SCREEN_W
    mov  al, CLR_GRAY
    rep  stosb

    ; Duong duoi (y=199): 320 pixel
    mov  di, 199 * SCREEN_W
    mov  cx, SCREEN_W
    mov  al, CLR_GRAY
    rep  stosb

    ; Vien trai va phai (tung pixel y tu 0..199)
    mov  cx, SCREEN_H
    xor  bx, bx            ; BX = y
border_sides:
    ; Pixel trai (x=0)
    mov  di, bx
    mov  byte ptr es:[di], CLR_GRAY

    ; Pixel phai (x=319)
    mov  di, bx
    add  di, SCREEN_W - 1
    mov  byte ptr es:[di], CLR_GRAY

    add  bx, SCREEN_W      ; Xuong dong tiep theo
    loop border_sides

    ret
draw_border endp

; ============================================================
;  VE DUONG GIUA (vach ke, mau vang)
; ============================================================
draw_center_line proc
    mov  bx, 0             ; y = 0
center_loop:
    cmp  bx, SCREEN_H
    jge  center_done

    ; Ve 4 pixel, ngat quang 4 pixel (hieu ung vach ke)
    mov  ax, bx
    and  ax, 7             ; ax = bx mod 8
    cmp  ax, 4
    jge  center_skip       ; Bo qua 4 pixel cuoi moi nhom 8

    ; Ve pixel tai (160, y)
    mov  di, bx
    add  di, 160           ; x = 160
    mov  byte ptr es:[di], CLR_YELLOW

center_skip:
    add  bx, SCREEN_W      ; Xuong dong tiep theo
    jmp  center_loop

center_done:
    ret
draw_center_line endp

; ============================================================
;  VE PADDLE 1 (TRAI - mau xanh la)
;  Su dung tinh toan: offset = y*320 + x
; ============================================================


; Chu y: bx o tren dang dung lam offset dong (y*320)
; Ta can tinh offset tu so dong y
; Sua lai: dung ham tinh chinh xac

draw_paddle1 proc
    ; Tinh offset cho y dau tien: di = pad1_y * 320 + pad1_x
    mov  ax, [pad1_y]
    mov  bx, SCREEN_W
    mul  bx                ; ax = pad1_y * 320
    add  ax, [pad1_x]      ; ax = pad1_y*320 + pad1_x
    mov  di, ax

    mov  cx, [pad1_h]      ; So dong

dp1_row:
    push cx
    push di
    mov  cx, [pad1_w]      ; So pixel moi dong
    mov  al, CLR_GREEN
    rep  stosb             ; Ve dong ngang
    pop  di
    pop  cx

    add  di, SCREEN_W      ; Xuong dong ke
    loop dp1_row

    ret
draw_paddle1 endp

; ============================================================
;  VE PADDLE 2 (PHAI - mau do)
; ============================================================
draw_paddle2 proc
    mov  ax, [pad2_y]
    mov  bx, SCREEN_W
    mul  bx
    add  ax, [pad2_x]
    mov  di, ax

    mov  cx, [pad2_h]

dp2_row:
    push cx
    push di
    mov  cx, [pad2_w]
    mov  al, CLR_RED
    rep  stosb
    pop  di
    pop  cx

    add  di, SCREEN_W
    loop dp2_row

    ret
draw_paddle2 endp

; ============================================================
;  VE QUA BONG (hinh vuong 4x4, mau xanh cyan)
; ============================================================
draw_ball proc
    mov  ax, [ball_y]
    mov  bx, SCREEN_W
    mul  bx
    add  ax, [ball_x]
    mov  di, ax

    mov  cx, [ball_size]   ; 4 dong

draw_ball_row:
    push cx
    push di
    mov  cx, [ball_size]   ; 4 pixel moi dong
    mov  al, CLR_CYAN
    rep  stosb
    pop  di
    pop  cx

    add  di, SCREEN_W
    loop draw_ball_row

    ret
draw_ball endp

; ============================================================
;  VE DIEM SO (dang chu so pixel art 5x7)
;  Ve so don gian tai vi tri co dinh
; ============================================================
draw_scores proc
    ; Ve diem P1 tai (120, 10)
    mov  ax, [pad1_score]
    mov  bx, 120           ; X
    mov  cx, 10            ; Y
    call draw_digit

    ; Ve diem P2 tai (190, 10)
    mov  ax, [pad2_score]
    mov  bx, 190           ; X
    mov  cx, 10            ; Y
    call draw_digit

    ret
draw_scores endp

; ---- Ve 1 chu so (0-9) tai vi tri (bx=x, cx=y), ax=gia tri ----
; Su dung pixel art thu cong (5x7 pixel moi so)
draw_digit proc
    ; Tinh offset co so
    push bx
    push cx

    mov  di, cx            ; y
    mov  dx, SCREEN_W
    ; di = cx*320 + bx
    push ax
    mov  ax, cx
    mul  dx
    pop  dx                ; dx = so can ve
    add  ax, bx            ; ax = cy*320 + bx
    mov  di, ax
    mov  ax, dx            ; ax = digit value

    ; Chi ve hinh chu nhat don gian theo gia tri
    ; (pixel art so day du se qua dai, dung o dang gian luoc)
    ; Ve so kieu "7-segment" don gian bang cac thanh 5px

    cmp  ax, 0
    je   dig_0
    cmp  ax, 1
    je   dig_1
    cmp  ax, 2
    je   dig_2
    cmp  ax, 3
    je   dig_3
    cmp  ax, 4
    je   dig_4
    cmp  ax, 5
    je   dig_5
    cmp  ax, 6
    je   dig_6
    cmp  ax, 7
    je   dig_7

    ; Mac dinh: ve o vuong
    jmp  dig_draw_box

dig_0:
    call draw_digit_0
    jmp  dig_done
dig_1:
    call draw_digit_1
    jmp  dig_done
dig_2:
    call draw_digit_2
    jmp  dig_done
dig_3:
    call draw_digit_3
    jmp  dig_done
dig_4:
    call draw_digit_4
    jmp  dig_done
dig_5:
    call draw_digit_5
    jmp  dig_done
dig_6:
    call draw_digit_6
    jmp  dig_done
dig_7:
    call draw_digit_7
    jmp  dig_done

dig_draw_box:
    ; Ve o trang don gian (5x7)
    mov  cx, 7
dig_box_row:
    push cx
    push di
    mov  cx, 5
    mov  al, CLR_WHITE
    rep  stosb
    pop  di
    pop  cx
    add  di, SCREEN_W
    loop dig_box_row

dig_done:
    pop  cx
    pop  bx
    ret
draw_digit endp

; ---- Cac hinh dang so pixel art 5x7 ----
; DI da tro vao vi tri bat dau, ES = A000h

; Macro nho: ve 1 hang 5 pixel
; Ta dung inline cho nhanh

draw_digit_0 proc
    ; 0: ###
    ;    # #
    ;    # #
    ;    # #
    ;    ###
    push di
    ; Hang 1: 5 trang
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    ; Hang 2: trang + den + trang
    mov  byte ptr es:[di], CLR_WHITE
    mov  byte ptr es:[di+1], CLR_BLACK
    mov  byte ptr es:[di+2], CLR_BLACK
    mov  byte ptr es:[di+3], CLR_BLACK
    mov  byte ptr es:[di+4], CLR_WHITE
    add  di, SCREEN_W
    ; Hang 3,4 giong hang 2
    mov  byte ptr es:[di], CLR_WHITE
    mov  byte ptr es:[di+4], CLR_WHITE
    add  di, SCREEN_W
    mov  byte ptr es:[di], CLR_WHITE
    mov  byte ptr es:[di+4], CLR_WHITE
    add  di, SCREEN_W
    ; Hang 5: giong hang 2
    mov  byte ptr es:[di], CLR_WHITE
    mov  byte ptr es:[di+4], CLR_WHITE
    add  di, SCREEN_W
    ; Hang 6: giong hang 2
    mov  byte ptr es:[di], CLR_WHITE
    mov  byte ptr es:[di+4], CLR_WHITE
    add  di, SCREEN_W
    ; Hang 7: 5 trang
    mov  cx, 5
    mov  al, CLR_WHITE
    rep  stosb
    pop  di
    ret
draw_digit_0 endp

draw_digit_1 proc
    ; 1:  #
    ;     #
    ;     #
    push di
    mov  cx, 7
dg1_loop:
    mov  byte ptr es:[di+2], CLR_WHITE
    add  di, SCREEN_W
    loop dg1_loop
    pop  di
    ret
draw_digit_1 endp

draw_digit_2 proc
    ; 2: ###
    ;      #
    ;    ###
    ;    #
    ;    ###
    push di
    ; H1
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    ; H2
    mov  byte ptr es:[di+4], CLR_WHITE
    add  di, SCREEN_W
    ; H3
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    ; H4
    mov  byte ptr es:[di], CLR_WHITE
    add  di, SCREEN_W
    ; H5
    mov  byte ptr es:[di], CLR_WHITE
    add  di, SCREEN_W
    ; H6
    mov  byte ptr es:[di], CLR_WHITE
    add  di, SCREEN_W
    ; H7
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb
    pop  di
    ret
draw_digit_2 endp

draw_digit_3 proc
    push di
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
	mov al, CLR_WHITE 
	rep stosb 
	add di, SCREEN_W-5
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
	mov al, CLR_WHITE 
	rep stosb
    pop  di
    ret
draw_digit_3 endp

draw_digit_4 proc
    push di
    mov  byte ptr es:[di], CLR_WHITE 
	mov byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di], CLR_WHITE 
	mov byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di], CLR_WHITE 
	mov byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    pop  di
    ret
draw_digit_4 endp

draw_digit_5 proc
    push di
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    mov  byte ptr es:[di], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb
    pop  di
    ret
draw_digit_5 endp

draw_digit_6 proc
    push di
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    mov  byte ptr es:[di], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb 
    add di, SCREEN_W-5
    mov  byte ptr es:[di], CLR_WHITE 
	mov byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di], CLR_WHITE 
	mov byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  cx, 5 
    mov al, CLR_WHITE 
    rep stosb
    pop  di
    ret
draw_digit_6 endp

draw_digit_7 proc
    push di
    mov  cx, 5 
	mov al, CLR_WHITE 
	rep stosb 
	add di, SCREEN_W-5
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+4], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+2], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+2], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+2], CLR_WHITE 
	add di, SCREEN_W
    mov  byte ptr es:[di+2], CLR_WHITE
    pop  di
    ret
draw_digit_7 endp

; ============================================================
;  HIEN THI NGUOI THANG
; ============================================================
show_winner proc
    call clear_screen

    ; Ve chu "P1 WIN" hoac "P2 WIN" bang cach to mau
    cmp  [winner], 1
    je   show_p1_win

    ; P2 thang: ve cot mau do lon o giua
    mov  ax, 80 * SCREEN_W + 120
    mov  di, ax
    mov  cx, 40
sw_p2_row:
    push cx
    push di
    mov  cx, 80
    mov  al, CLR_RED
    rep  stosb
    pop  di
    pop  cx
    add  di, SCREEN_W
    loop sw_p2_row
    ret

show_p1_win:
    ; P1 thang: ve cot mau xanh lon o giua
    mov  ax, 80 * SCREEN_W + 120
    mov  di, ax
    mov  cx, 40
sw_p1_row:
    push cx
    push di
    mov  cx, 80
    mov  al, CLR_GREEN
    rep  stosb
    pop  di
    pop  cx
    add  di, SCREEN_W
    loop sw_p1_row
    ret
show_winner endp

; ============================================================
;  DELAY - Lam cham game loop xuong ~30fps
; ============================================================
delay_frame proc
    ; Dung vong lap CPU don gian (khong dung timer interrupt)
    mov  cx, 0FFFFh
delay_loop:
    nop
    loop delay_loop
    ret
delay_frame endp

end main