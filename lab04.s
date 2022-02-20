; Archivo: lab04.s
; Dispositivo: PIC16F887
; Autor: Melanie Morales 
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: Interrupciones
; Hardware: LEDs en el puerto A y push en el b con display 7s
;
; Creado: 13 feb, 2022
; Última modificación: 13 feb, 2022
;--------librería a implementar------  
 PROCESSOR 16F887
 #include <xc.inc>
;------------bits de configuración------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON            ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)
; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;---------configuración de macros------------------
 reset_timer	MACRO;	Esto hace una subrutina macro
    banksel	PORTD	;asegurar el puerto d
    movlw	178;configuración del prescaler
    movwf	TMR0		;guardado en el timer cero
    bcf		T0IF		;bandera cuando no haya overflow
    endm	    
 ;-----------------------valores generales------------------------
UP EQU 0
DOWN EQU 5
;------------------------variables a usar---------------------
PSECT udata_bank0	; la variable se guarda en memoria común
     CONT:	DS 2		;variable de contador PortD
    CONT1:	DS 2		;variable de contador
    PORT:	DS 1
    PORT1:	DS 1		;variable
    PORT2:	DS 2
    PORT3:	DS 1
    PORTC1:	DS 1

PSECT udata_shr			;dirigido a la memoria común
    W_TEMP:	DS 1		;variable
    STATUS_TEMP:DS 1

PSECT resVect, class=code, abs, delta=2
;------------vector reset------------------------------------
  ORG 00h			;posición para el el reset 0000h
  resVect:
    PAGESEL main
    GOTO main  
  PSECT intVect,  class=code, abs, delta=2
;-------configuración de interrupciones----------------------------
ORG 04h			;lugar para el código

push:
    movwf W_TEMP		;variable se almacena en en f
    swapf STATUS, W	;se da vuelta en nibbler
    movwf STATUS_TEMP	;se almacena en la variable

isr:
    btfsc T0IF		;se evalúa si se hizo la interrupción
    call int_t0		;se llama la interrupción
    
    btfsc RBIF
    call int_onc	;se llama la interrupción
    
pop:
    SWAPF STATUS_TEMP, W	;se da vuelta a la variable
    MOVWF STATUS		;se almacena en STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE
;-------------------------interrupciones--------------------
int_onc:
    banksel	PORTA
    btfss	PORTB, UP	;por las resistencias, si está en 1 salta, si está en 0 incrementa
    incf	PORT
    btfss	PORTB, DOWN	;check si está en 1 o 0
    decf	PORT
    movf	PORT,  W	;mover el valor a W 
    andlw	00001111B	;contador de 4 bits
    movwf	PORTA		;mostrar en puerto A
    bcf		RBIF		;reinicia bandera RBIF
    return
int_t0:
    reset_timer		    ;50ms
    incf	CONT		;se incrementa
    movf	CONT,   W	; se mueve a W
    sublw	50		;se multiplica por 50
    btfsc	ZERO
    goto	return_t0	
    clrf	CONT		; se limpia el contador 
    incf	PORT1		; se incrementa la variable para el 7s
    movf	PORT1,	W	; se mueve a w
    call	tabla		; se traduce a la tabla	    
    movwf	PORTD		; se mueve a d para mostrarse
    
    movf	PORT1,	W	; se configura decenas
    sublw	10		; si la resta de las unidades con 10<=0 se llama incremento 
    btfsc	STATUS, 2
    call	incremento 
    
    movf	PORT3,	W	; se mueve el valor 
    call	tabla		; se traduce a la tabla
    movwf	PORTC		; se muestra en puerto C
    return 
incremento:
    incf	PORT3		;incrementa el puerto 3
    clrf	PORT1	
    movf	PORT1,	W	
    call	tabla
    movwf	PORTD
    
    movf	PORT3,  W	; se mueve a w
    sublw	6		;se resta el valor para asegurar que reinicie cuando llegue a 60
    btfsc	STATUS, 2
    clrf	PORT3
    return
return_t0:
    return
    PSECT code, delta=2, abs 
 ORG 100h; posición para el código 
 tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0	;PCLATH=01
    andlw   0x0f	;deja pasar cualquier número menor a Fhex
    addwf   PCL		;PC=PCLATH+PCL+w
    retlw   00111111B	;0
    retlw   00000110B	;1
    retlw   01011011B	;2
    retlw   01001111B	;3
    retlw   01100110B	;4
    retlw   01101101B	;5
    retlw   01111101B	;6
    retlw   00000111B	;7
    retlw   01111111B	;8
    retlw   01101111B	;9
    retlw   01110111B	;A
    retlw   01111100B	;B
    retlw   00111001B	;C
    retlw   01011110B	;D
    retlw   01111001B	;E
    retlw   01110001B	;F

;---------------------configuración--------------------------------
main:
    call CONFIG_IO
    call CONFIG_RELOJ
    call CONFIG_TMR0
    call CONFIG_INT_ENABLE
    call CONFIG_IOCB

loop:
    goto loop
;-------------------------------SUBRUTINAS--------------------------------------
CONFIG_IOCB:
    banksel	TRISA
    bsf		IOCB, UP
    bsf		IOCB, DOWN
    
    banksel	PORTA
    movf	PORTB, W
    bcf		RBIF
    return
CONFIG_TMR0:
    banksel TRISD
    bcf     T0CS    ;Reloj interno
    bcf	    PSA	    ;prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0     ;PS=110=256      
    reset_timer		    ;50ms
    return
CONFIG_INT_ENABLE:	    ;se configuraron las banderas y las interrupciones
    bsf	    GIE
    bsf	    T0IE	    ; interrupcion para Tmr0
    bsf	    RBIE	    ; interrupcion para push B
    bcf	    T0IF	    ; interrupción para Tmr0
    bcf	    RBIF	    ; interrupcion para push B
    return 
CONFIG_RELOJ:
    banksel	OSCCON	    ;configuración del reloj
    bsf		IRCF2	    ;IRCF=110=4MHZ
    bsf		IRCF1
    bcf		IRCF0
    bsf		SCS
    return
CONFIG_IO:
    bsf		STATUS, 5	    ;banco 11
    bsf		STATUS, 6
    clrf	ANSEL		    ;pines digitales
    clrf	ANSELH
    
    bsf		STATUS, 5	    ;banco01
    bcf		STATUS, 6
    clrf	TRISA		    ;portA salida
    clrf	TRISC	    ;portC salida
    clrf	TRISD		    ;portD salida
    
    bsf		TRISB, UP	    ;Pines 0 y5de PORTB como entrada (push)
    bsf		TRISB, DOWN
    
    bcf		OPTION_REG, 7	    ; habilita pullups
    bsf		WPUB, UP
    bsf		WPUB, DOWN
    
    bcf		STATUS, 5	    ;banco 00
    bcf		STATUS, 6
    clrf	PORTA
    return
end    
    

