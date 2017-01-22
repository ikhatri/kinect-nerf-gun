//----------------------------start Arduino code--------------------------------

#include <Servo.h> // include servo headers
// this would be whatever pin you want to use
#define SERVOR 8
#define SERVOL 9

// global variables
Servo servoL; // initialize left servo
Servo servoR; // init right servo

int message = 0; // This will hold one byte of the serial message

// played around with values that sets the servos to neutral position
// these values need to be set for each servo!!!
const int servoneutralLeft = 1515;
const int servoneutralRight = 1520;

// set neutral range for servos
const int minneutral = 1400;
const int maxneutral = 1600;

//--- Function: Setup ()
void setup()
{
pinMode (SERVOL, OUTPUT);
pinMode (SERVOR, OUTPUT);

servoL.attach(SERVOL);
servoR.attach(SERVOR);

servoL.writeMicroseconds(servoneutralLeft); // set servo to mid-point
servoR.writeMicroseconds(servoneutralRight); // set servo to mid-point

Serial.begin(9600); //set serial to 9600 baud rate
}

//--- Function: loop ()
void loop()
{
// Check if there is a new message
if (Serial.available() > 0)
{

message = Serial.read(); // Put the serial input into the message

int val=message; // val to match pwm delay in ms
int tempval=0; // temp storage

// we can send values from 0 to 255 to the arduino.
// both fadders are set up to go from 0 to 1.
// left servo: 0-127, right servo 128-255. should be enough resolution
int minpulse = 127*8/2; // max storage is 0-255.
// Begin LEFT servo code

if (val <= 127)
{
// scale everything from 1000 to 2000
tempval = val*8 + servoneutralLeft - minpulse;
if (tempval > minneutral && tempval < maxneutral)
{
    // Creates dead zone at midpoint of the
    servoL.writeMicroseconds(servoneutralLeft); // fader range (neutral) and trims input to neutral
}
else
{
    servoL.writeMicroseconds(tempval);
}
}
// End LEFT servo code

           // Begin RIGHT servo code
if (val > 128)
{
// scale everything from 1000 to 2000
tempval = val*8 + servoneutralRight - minpulse - 128*8;
if (tempval > minneutral && tempval < maxneutral)
{
    servoR.writeMicroseconds(servoneutralRight);
    // fader range (neutral) and trims input to neutral value
}
else
{
    servoR.writeMicroseconds(tempval);
}
} // End RIGHT servo code 
}
}
//----------------------------end Arduino code-------------------------------- 
