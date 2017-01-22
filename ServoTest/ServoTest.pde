import processing.serial.*;

import cc.arduino.*;

Arduino arduino;
int servoAngle = 90;
void setup()
{
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  arduino.pinMode(9, Arduino.SERVO);
  arduino.pinMode(6, Arduino.OUTPUT);
  arduino.servoWrite(9, servoAngle);
  //arduino.digitalWrite(6, Arduino.HIGH);
  //delay(1000);
  //arduino.digitalWrite(6, Arduino.LOW);
  println(servoAngle);
  //servoAngle+=90;
  //arduino.servoWrite(9, servoAngle);
  //println(servoAngle);
}

void draw(){
  /*while(servoAngle<-500){
  arduino.servoWrite(9, servoAngle);
  println(servoAngle);
  servoAngle-=10;
  }*/
}
