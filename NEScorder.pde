/**************************************
 *  NEScorder
 *  JeremyABurns 2010
 *  Source v1.0
 **************************************/
 
 
// Arduino FAT16 Library can be found at http://code.google.com/p/fat16lib/
#include <Fat16.h>

// The 4021 PISO shifters in the original NES gamepads aren't very fast,
// but 2 cycles seems to be enough delay between pin value changes.
#define NES_DELAY __asm__( "nop\nnop\n" )


// Macros for reading and writing I/O values to/from the ports.
#define PIN_TEST( _pin, _mask ) ( _pin & ( 1 << (_mask) ) )
#define PORT_SET_LO( _port, _mask ) ( _port &= ~( 1 << (_mask) ) )
#define PORT_SET_HI( _port, _mask ) ( _port |=  ( 1 << (_mask) ) )
#define PORT_FLIP(   _port, _mask ) ( _port ^=  ( 1 << (_mask) ) )



// NES Output Ports
#define IND_NES_LATCH       2    // Connected to the NES gamepad port pin resonsible for latching gamepad values.
#define OUTD_OUTPUT_CLOCK   3    // Connected to the clock on the SIPO shifter where we store the gamepad values we want the NES to pick up.
#define OUTD_OUTPUT_DATA    4    // The inputs to the SIPO shifter go here.

// Gamepad Input Ports
#define IND_CONTROLLER_DATA    5
#define OUTD_CONTROLLER_LATCH  6
#define OUTD_CONTROLLER_CLOCK  7


// Status LEDs
#define OUTC_LED_POWER      0
#define OUTC_LED_RECORDING  1
#define OUTC_LED_PLAYING    2
#define OUTC_LED_IDLE       3


// Input buttons/switches
#define INC_SW_RECORD  4
#define INC_SW_PLAY    5
#define INB_SW_STOP    0



// Possible modes of operation
#define MODE_IDLE      0
#define MODE_RECORDING 1
#define MODE_PLAYBACK  2



uint8_t  modusOperandi;

uint32_t cycleCounter;

uint8_t  buttonValues;
uint8_t  oldButtonValues;


bool  requestWrite;
bool  requestRead;
bool  initTimeComplete;

// These variables are used during playback and store the next entry in the macro.
uint8_t  nextButtonValues;
uint32_t nextCycleCount;


#define BUFFER_SIZE 300
uint8_t  bufferA[ BUFFER_SIZE ];
uint8_t  bufferB[ BUFFER_SIZE ];
uint8_t *curBuffer;
uint8_t *otherBuffer;
uint32_t bufferPosition;



SdCard  card;
Fat16   file;


void setup()
{
        cli();
        
        EICRA |= 1<<ISC01 | 0<<ISC00;    // Falling edge triggers INT0.  The NES gamepad latch pin is wired to INT0.
        EIMSK |= 1<<INT0;                // Enable INT0 interrupt.
        
        DDRB &= 0b11111110;    // Set the lowest bit as input in Port B to read the stop button status.
        
        DDRD  = 0b11011010;    // Port D is connected to the incoming controller as well as the NES and the UART debug port.
        PORTD = 0b00000000;
        
        DDRC  = 0b00001111;    // Port C is connected to active low LEDs and buttons
        PORTC = 0b00001111;
        
        buttonValues    = 0xFF;
        oldButtonValues = 0xFF;
        
        cycleCounter   = 0;

        curBuffer   = (uint8_t*)(&bufferA);
        otherBuffer = (uint8_t*)(&bufferB);
        bufferPosition = 0;        
        
        requestRead  = false;
        requestWrite = false;
        
        initTimeComplete = false;
        
        sei();
        
        uint8_t cardOK = card.init( true );
        if( cardOK ) cardOK = Fat16::init( &card );
        
        modusOperandi = MODE_IDLE;
        
        if( !cardOK ) {
            PORT_SET_LO( PORTC, OUTC_LED_IDLE );
            PORT_SET_LO( PORTC, OUTC_LED_PLAYING );
            PORT_SET_LO( PORTC, OUTC_LED_RECORDING );
            return;
        }

        if( PIN_TEST( PINC, INC_SW_RECORD ) ) {
            modusOperandi = MODE_RECORDING;
        }
        else if( PIN_TEST( PINC, INC_SW_PLAY ) ) {
            modusOperandi = MODE_PLAYBACK;
        }        
        
        switch( modusOperandi )
        {
            case MODE_PLAYBACK:

                cardOK = file.open( "NESCORDR.DAT", O_CREAT | O_READ );
                if( !cardOK ) break;
                
                file.read( &bufferA, BUFFER_SIZE );
                file.read( &bufferB, BUFFER_SIZE );
                readNextMacroEntry();

                PORT_SET_LO( PORTC, OUTC_LED_PLAYING );
                break;
                
            case MODE_RECORDING:
            
                cardOK = file.open( "NESCORDR.DAT", O_CREAT | O_WRITE );
                if( !cardOK ) break;
                
                PORT_SET_LO( PORTC, OUTC_LED_RECORDING );
                break;
                
            case MODE_IDLE:
                PORT_SET_LO( PORTC, OUTC_LED_IDLE );
                break;
        }
        
        if( !cardOK ) {
            modusOperandi = MODE_IDLE;
            PORT_SET_LO( PORTC, OUTC_LED_IDLE );
            PORT_SET_LO( PORTC, OUTC_LED_PLAYING );
            PORT_SET_LO( PORTC, OUTC_LED_RECORDING );
        }
}


void loop() 
{
        if( requestWrite )
        {
            file.writeError = false;
            file.write( otherBuffer, BUFFER_SIZE );
            if( file.writeError ) {
                file.close();
                modusOperandi = MODE_IDLE;
            }
            requestWrite = false;
        }
        else if( requestRead )
        {
            if( file.read( otherBuffer, BUFFER_SIZE ) < 0 ) {
                file.close();
                modusOperandi = MODE_IDLE;
            }
            requestRead = false;
        }

        if( modusOperandi != MODE_IDLE && PIN_TEST( PINC, INC_SW_RECORD ) == 0 && PIN_TEST( PINC, INC_SW_PLAY ) == 0 )
        {
            stopButtonPressed();
        }
}


void swapBuffersAndSeekZero()
{
        bufferPosition = 0;
        uint8_t *x  = otherBuffer;
        otherBuffer = curBuffer;
        curBuffer   = x;
}

void stopButtonPressed()
{
        cli();
        
        uint8_t originalMode = modusOperandi;
        modusOperandi = MODE_IDLE;
        
        switch( originalMode )
        {
            case MODE_RECORDING:
                for( uint8_t i = 0 ; i < 4 ; ++i ) curBuffer[ bufferPosition++ ] = 0xFF;
                file.write( curBuffer, BUFFER_SIZE );
                file.sync();
                
            case MODE_PLAYBACK:
                file.close();
                break;
        }  
        
        PORTC = 0b00001111;
        PORT_SET_LO( PORTC, OUTC_LED_IDLE );
        PORT_SET_LO( PORTC, OUTC_LED_POWER );
        
        sei();
}

// Called on the falling edge of the controller latch signal from the NES.
ISR( INT0_vect )
{
        cycleCounter++;
        
        if( !initTimeComplete )
        {
            if( millis() < 3000 ) {
                return;
            } else {
                initTimeComplete = true;
            }
        }
        
        if( cycleCounter % 60 == 0 ) PORT_FLIP( PORTC, OUTC_LED_POWER );
 
        if( modusOperandi != MODE_PLAYBACK ) {
            getGamepadButtonValues();
        }       
        
        switch( modusOperandi )
        {
            case MODE_RECORDING:  recordButtonValues();    break;
            case MODE_PLAYBACK:   playbackButtonValues();  break;
        }
        
        shiftButtonValuesOut();
}



void recordButtonValues()
{
        uint8_t *bytesOfCycleCounter = (uint8_t*)(&cycleCounter);
        if( buttonValues != oldButtonValues )
        {
            curBuffer[ bufferPosition++ ] = bytesOfCycleCounter[0];
            curBuffer[ bufferPosition++ ] = bytesOfCycleCounter[1];
            curBuffer[ bufferPosition++ ] = bytesOfCycleCounter[2];
            curBuffer[ bufferPosition++ ] = bytesOfCycleCounter[3];
            curBuffer[ bufferPosition++ ] = buttonValues;
            
            if( bufferPosition >= BUFFER_SIZE )
            {
                swapBuffersAndSeekZero();
                requestWrite = true;
            }
        }
}



void playbackButtonValues()
{
        if( cycleCounter == nextCycleCount ) // If the cycleCounter is where the playback macro event we're waiting for happened...
        {
            buttonValues = nextButtonValues;
            readNextMacroEntry();
        }
}


void readNextMacroEntry()
{
        uint8_t *bytesOfNextCycleCount = (uint8_t*)(&nextCycleCount);
        bytesOfNextCycleCount[0] = curBuffer[ bufferPosition++ ];
        bytesOfNextCycleCount[1] = curBuffer[ bufferPosition++ ];
        bytesOfNextCycleCount[2] = curBuffer[ bufferPosition++ ];
        bytesOfNextCycleCount[3] = curBuffer[ bufferPosition++ ];
        nextButtonValues         = curBuffer[ bufferPosition++ ];
        
        if( nextCycleCount == 0xFFFFFFFF )
        {
            file.close();
            modusOperandi = MODE_IDLE;
            PORT_SET_LO( PORTC, OUTC_LED_IDLE    );
            PORT_SET_HI( PORTC, OUTC_LED_PLAYING );
        }
        else if( bufferPosition >= BUFFER_SIZE )
        {
            swapBuffersAndSeekZero();
            requestRead = true;
        }
}


// Read the button values from the input gamepad and store them.
void getGamepadButtonValues()
{
        PORT_SET_HI( PORTD, OUTD_CONTROLLER_LATCH );
        NES_DELAY;  // Latch is held high for 12us by the NES, all other hi/lo sections of the signals are 6us.
        NES_DELAY;  // This actually runs quite a bit faster than that but still works on the original NES gamepads.
        PORT_SET_LO( PORTD, OUTD_CONTROLLER_LATCH );
        NES_DELAY;
        
        oldButtonValues = buttonValues;
        buttonValues = 0;
            
        uint8_t i;
        for( i = 0 ; i < 8 ; ++i )
        {
            if( PIN_TEST( PIND, IND_CONTROLLER_DATA ) ) 
            {
                buttonValues |= 1 << i;
            }
                
            PORT_SET_HI( PORTD, OUTD_CONTROLLER_CLOCK );
            NES_DELAY;
            PORT_SET_LO( PORTD, OUTD_CONTROLLER_CLOCK );
            NES_DELAY;
        }
}

// Shift the buttonValues out on to the board.
void shiftButtonValuesOut()
{
        uint8_t i;
        for( i = 0 ; i < 8 ; ++i )
        {
            if( buttonValues & (1 << i) ) {
                PORT_SET_HI( PORTD, OUTD_OUTPUT_DATA );
            } else {
                PORT_SET_LO( PORTD, OUTD_OUTPUT_DATA );
            }
                
            PORT_SET_HI( PORTD, OUTD_OUTPUT_CLOCK );
            PORT_SET_LO( PORTD, OUTD_OUTPUT_CLOCK );
        }
}



