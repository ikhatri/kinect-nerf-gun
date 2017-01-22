import SimpleOpenNI.*;
import processing.serial.*;

import cc.arduino.*;

Arduino arduino;
void setup()
{
  size(360, 200);
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  arduino.pinMode(9, Arduino.SERVO);
  
}

void draw()
{
  
  
  arduino.servoWrite(9, 0);
  delay(750);
  arduino.servoWrite(9,180);
  delay(750);
}
