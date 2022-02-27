; Archivo: PRELAB5.s
; Dispositivo: PIC16F887
; Autor: Melanie Morales
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: contador decimal y hexadecimal
; Hardware: displays en un mismo puerto 
;
; Creado: 21 feb, 2022
; Última modificación: 21 feb, 2022

  PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
 CONFIG FOSC=INTRC_NOCLKOUT// Oscilador interno sin salidas
 CONFIG WDTE=OFF	      // WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON           // PWRT enabled (espera de 72ms al iniciar)
 CONFIG MCLRE=OFF	      // El pin de MCLR se utiliza como I/O
 CONFIG CP=OFF             // Sin protección de código
 CONFIG CPD=OFF            // Sin protección de datos
    
 CONFIG BOREN=OFF          // Sin reinicio cuando el voltaje de alimentación baja de 4v
 CONFIG IESO=OFF	      // Reinicio sin cambio de reloj interno a externo
 CONFIG FCMEN=OFF          // Cambio de reloj externo a interno en caso de fallo 
 CONFIG LVP=ON	      // Programación en bajo voltaje permitida

;configuration word 2
 CONFIG WRT=OFF            //Protección de autoescritura por el programa desactivadas
 CONFIG BOR4V=BOR40V       // Reinicio abajo de 4v, (BOR21v=2.1v)

UP    EQU 0   ; Asignacion de nombres para los pushbutton 
DOWN  EQU 1
 
reinicio_tmr0 macro ; Macro para el reinicio del tmr 0
 banksel PORTA	    ; Se llama al banco
 movlw  253	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0	    ;se mueve al tmr0
 bcf	T0IF	    ; se quita la bandera del tmr0
 endm
 
PSECT udata_bank0   
  var:  DS 2	; Cantidad de bytes en cada variable
  Uni:	DS 1
  Decc:	DS 1
  Cen:	DS 1
    
;--------------------------------variables a usar-------------------
PSECT udata_shr
  W_TEMP:	DS 1	    ;Variables a utilizar 
  STATUS_TEMP:  DS 1	    ;1byte
  bandera:	DS 2	    ;2 bytes
  nibble:	DS 2	    ;2 bytes
  cambio_disp:  DS 5	    ;5bytes
    
    
PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2
;-----------vector interrupt--------------;
ORG 04h     ;posicion 0004h para las interrupciones
push:
    movwf   W_TEMP	    ;Colocar las variables temporales a W
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    btfsc   RBIF	    ;Revisar interrupciones en el puerto B
    call    PB_subr	    ;Llamada a subrutina de pushbuttons
    btfsc   T0IF	    
    call    TMR0_SR	    ;Llamada a subrutina de SETUP_TMR0
    
pop:
    swapf   STATUS_TEMP, W  ;Regresa a W al status
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
;--------------sub rutinas de int------:
PB_subr:
    banksel PORTA	    ;Subrutina de interrupcion de los pushbutttons
    btfss   PORTB, UP
    incf    var		    ;incrementa la variables
    movf    var, W	    ; se mueve a w
    movwf   PORTA	    ;se muestra w en A
    btfss   PORTB, DOWN	    ;moverse si cambia
    Decf    var		    ;decrementar la variable
    movf    var, W	    ;mover a w
    movwf   PORTA	    ;mostrar w en A
    bcf	    RBIF	    ;desactivar la bandera de B
    return	
TMR0_SR:		    ;Subrutina de interrupcion del tmr0
    reinicio_tmr0           
    bcf	    PORTB, 5	    ; se limpia
    bcf	    PORTB, 6	    ; se limpia
    bcf	    PORTB, 7	    ; se limpia
    
    btfsc   bandera, 0	    ;Se enciende la bandera de cada display
    goto    display_1
    
    btfsc   bandera, 1
    goto    display_2
    
    btfsc   bandera, 2
    goto    display_3
   
    btfsc   bandera, 3
    goto    display_4
display0:			;Primer display hexa
    movf    cambio_disp, W	;se elige el byte de la varriable
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTE, 0		;transistor que se desea activar
    goto    nextDisp0		;llamada a instruccion siguiente
display_1:
    movf    cambio_disp+1, W	;Segundo display hexa
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTE, 1		;transistor que se desea activar
    goto    nextDisp1
display_2:
    movf    cambio_disp+2, W	;Primer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTB, 5		;transistor que se desea activar
    goto    nextDisp2
display_3:
    movf    cambio_disp+3, W	;Segundo display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTB, 6		;transistor que se desea activar
    goto    nextDisp3
display_4:
    movf    cambio_disp+4, W	;Tercer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTB, 7		;transistor que se desea activar
    goto    nextDisp4
nextDisp0:		;Intruccion de rotacion de displays 
    movlw   00000001B
    xorwf   bandera, 1	    ;XOR para hacer la rotación 
    return
nextDisp1:		;Intruccion de rotacion de displays 
    movlw   00000011B
    xorwf   bandera, 1
    return
nextDisp2:		;Intruccion de rotacion de displays 
    movlw   00000110B
    xorwf   bandera, 1
    return
nextDisp3:		;Intruccion de rotacion de displays 
    movlw   00001100B
    xorwf   bandera, 1
    return
nextDisp4:		;Intruccion de rotacion de displays 
    clrf    bandera
    return

RTRN_TMR0:
    return
    
PSECT code, delta=2, abs
ORG 100h    ; posicion para le codigo
 TABLA:
    clrf    PCLATH
    bsf	    PCLATH, 0   ;PCLATH = 01
    andlw   0x0f
    addwf   PCL         ;PC = PCLATH + PCL  se configura la TABLA para el siete segmentos
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01100111B  ;9
    retlw   01110111B  ;A
    retlw   01111100B  ;B
    retlw   00111001B  ;C
    retlw   01011110B  ;D
    retlw   01111001B  ;E
    retlw   01110001B  ;F
      
;-----------configuracion--------------;	
main:
    banksel ANSEL	; se escoge banco 3
    clrf    ANSEL	; limpiar puertos digitales
    clrf    ANSELH	;se configuran como digitales
    
    banksel TRISA	;Se asignan los pines de salida del contador binario
    movlw   00000000B	;se coloca el 0 en w
    movwf   TRISA	;se mueve a los pines de A
    
    bsf	    TRISB, UP	;se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, DOWN
    
    bcf	    TRISE, 0	;Se activan las salidas de los transistores
    bcf	    TRISE, 1
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    bcf	    TRISB, 7
    
    bcf	    OPTION_REG, 7   ;configuracion del Pull-Up de B 
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    call    RELOJ	;se llama al RELOJ 
    call    config_ioc	;se llama a nuestra configuracion de pull up
    call    SETUP_TMR0	;se llama a nuestro SETUP_TMR0
    call    SETUP_INT	;se llama configuracion de interrupciones
    
    banksel PORTA	;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    var
;----------Loop------------------------------
loop:
    banksel PORTA	;llamada a la seleccion de nibbles para cada displays
    call    SETUP_NIBBLES
    call    SETUP_DISPLAYS
    banksel PORTA	;selección del banco 
    call    division_pic	; se divide el nibble
    
    goto loop		
;-----------Sub-Rutinas--------------------
SETUP_NIBBLES:
    movf    var, W	;se mueve cada valor del PORTA a una parte del nibble
    andlw   0x0f	;
    movwf   nibble
    swapf   var, W
    andlw   0x0f
    movwf   nibble+1
    return
    
SETUP_DISPLAYS:
    movf    nibble, W	    ;se asigna el valor del nibble para cada byte del display
    call    TABLA
    movwf   cambio_disp
    
    movf    nibble+1, W
    call    TABLA
    movwf   cambio_disp+1
    
    movf    Cen, W
    call    TABLA
    movwf   cambio_disp+2
    
    movf    Decc, W
    call    TABLA
    movwf   cambio_disp+3
    
    movf    Uni, W
    call    TABLA
    movwf   cambio_disp+4
    
    return
    
config_ioc:
    banksel TRISA
    bsf	    IOCB, UP	   ;se colocan los pushbuttons como pull ups
    bsf	    IOCB, DOWN
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF
    return
    
RELOJ:
    banksel  OSCCON
    bcf      IRCF2      ; IRCF = 010 250 KHz
    bsf	     IRCF1
    bcf	     IRCF0
    bsf	     SCS        ; RELOJ interno
    return
    
SETUP_TMR0:
    banksel TRISA
    bcf	    T0CS       ;RELOJ interno
    bcf	    PSA	       ;Prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0        ; PS = 111   rate 1:256
    banksel PORTA
    reinicio_tmr0
    return

SETUP_INT:	    ;se habilitan las interrupciones en el puerto B y TMR0
    bsf	    GIE     ;INTCON
    bsf	    RBIE
    bsf	    T0IE
    bcf	    RBIF
    bcf	    T0IF
    return

division_pic: 
    clrf    Cen	    ;primer valor a encontrar
    movf    PORTA, 0	    ;Se mueve valor de leds a W
    movwf   Uni	    ;Se mueve w a nuestra variable
    movlw   100		    ;valor de 100 a W
    subwf   Uni, 0	    ;Se resta 100 a variable
    btfsc   STATUS, 0	    ;Se verifica la bandera de status 0
    incf    Cen		    ;Si la bandera es 1, se incrementa
    btfsc   STATUS, 0	    ;Se mueve valor restante a unidades para seguir division
    movwf   Uni
    btfsc   STATUS, 0
    goto    $-7
    
    clrf    Decc	    ;mismo proceso que para centenas
    movlw   10		    ;se utiliza valor de 10 para encontrar decimales
    subwf   Uni, 0
    btfsc   STATUS, 0
    incf    Decc
    btfsc   STATUS, 0
    movwf   Uni		    ;lo sobrante son nuestras Unidades
    btfsc   STATUS, 0
    goto    $-7
    btfss   STATUS, 0	    
    return

END