/* 
 * File:   Lab7.c
 * Author: Melanie Morales
 *
 */
//#include <stdio.h>
//#include <stdlib.h>
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF       // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)
// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)
// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.
#include <xc.h>
#include <stdint.h>
#define _tmr0_value 177 //177 Para 5ms
// Variables a utilizar 
uint8_t mux;
uint8_t cen;
uint8_t dec;
uint8_t uni;
// PROTOTIPO DE FUNCIONES
void setup(void);
int Display(int Numero);
void Decimales (void);
// INTERRUPCION
void __interrupt() isr (void)
{
    // INTERRUPCION TIMER0
    if (T0IF)                       //verifica si hay overflow del tmr0
    {     
        switch(mux){                //Dependiendo del display que despliegue, llama al respectivo valor desde el arreglo para el display
            case(0x01): mux = 0x02;
            break;
            case(0x02): mux = 0x04;
            break;
            case(0x04): mux = 0x01;
            break;
        }
        T0IF = 0;
        TMR0 = _tmr0_value;
    }
    // INTERRUPCION DEL PUERTO B
    if (RBIF)                       //verifica si hay interrupción y dependiendo del pin presionado o botón aumenta o decrementa el valor
    {
        if (RB0 == 0){
            PORTD++;  
        }
        if (RB1 == 0){
            PORTD--;
        }  
      RBIF = 0;  
    }       
    } 
void main(void){
    // configuración inicial 
setup();
// valor inicial para el mux
mux = 0x01;
while(1)
{   
Decimales(); 
// Muxeo y demostración en displays
switch(mux){
    case(0x01):
        PORTC = 0;
        PORTE = 0x01;
        Display(cen);   
        break;
    case(0x02):
        PORTC = 0;
        PORTE = 0x02;
        Display(dec);
        break;
    case(0x04):
        PORTC = 0;
        PORTE = 0x04;
        Display(uni);
        break;
}
}
}
void setup (void)
{
    // Configuración interna para el reloj
    OSCCONbits.SCS = 1;
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.IRCF1 = 0; // 125KHztenemos  Hz
    OSCCONbits.IRCF0 = 1;
    //Configuración I/O
    PORTC = 0X00;
    PORTB = 0X03;
    PORTD = 0X00;
    PORTE = 0X00;
            
    ANSEL = 0X00; //configuración de los puertos
    ANSELH = 0X00;
    TRISC = 0X00;
    TRISB = 0X03;
    TRISD = 0X00;
    TRISE = 0X00;
    //habilitar PULLUP PORTB
    OPTION_REGbits.nRBPU = 0;
    IOCB = 0X0F;
    //configuración PULLUP PORTB
    WPUB = 0X0F;
    //configuración TMR0
    OPTION_REGbits.T0CS = 0;// Configuramos (Fosc/4)
    OPTION_REGbits.PSA = 0; // PSA asignamos el prescaler al Timer0
    OPTION_REGbits.PS2 = 0; // prescaler 1:2
    OPTION_REGbits.PS1 = 0;
    OPTION_REGbits.PS0 = 0;
    TMR0 = _tmr0_value;
    //Se habilitan interrrupciones de Tmr0 y de B
    //INTCONbits.RBIF = 0;
    INTCONbits.T0IF = 0;
    //INTCONbits.RBIE = 1;
    INTCONbits.T0IE = 1;
    INTCONbits.GIE = 1;
}
// CONVERSOR 
void Decimales (void){
    int Temporal;
    cen = PORTD /100;
    Temporal = PORTD % 100;
    dec = Temporal /10;
    uni = Temporal % 10; 
} 
// Tabla 7 seg cátodo común hex-bin-dec
int Display(int Numero){
    switch (Numero){
        case(0): PORTC = (0b0111111);
        break;
        case(1): PORTC = (0b0000110);
        break;
        case(2): PORTC = (0b1011011);
        break;
        case(3): PORTC = (0b1001111);
        break;
        case(4): PORTC = (0b1100110);
        break;
        case(5): PORTC = (0b1101101);
        break;
        case(6): PORTC = (0b1111101);
        break;
        case(7): PORTC = (0b1111111);
        break;
        case(8): PORTC = (0b1111111);
        break;
        case(9): PORTC = (0b1100111);
        break;
    }  
}


