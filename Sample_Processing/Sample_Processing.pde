/* --------------------------------------------------------------------------
 * SimpleOpenNI User3d Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect 2 library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/
 * date:  12/12/2012 (m/d/y)
 * ----------------------------------------------------------------------------
 */
//Nerf Gun - Pin 6, Laser - Pin 11, servo - Pin 9
import SimpleOpenNI.*;
import processing.serial.*;

import cc.arduino.*;

Arduino arduino;

SimpleOpenNI context;
float        zoomF =0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = radians(0);
boolean      autoCalib=true;

//Ishan Variables
int servoAngleX = 90;
int increment = 1;

PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();                                   
PVector      com2d = new PVector();
PVector      camCenter = new PVector(1024, 348, 0);
color[]      userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };

void setup()
{
  size(1024,768,P3D);  // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem

  // Prints out the available serial ports.
  println(Arduino.list());

  // Modify this line, by changing the "0" to the index of the serial
  // port corresponding to your Arduino board (as it appears in the list
  // printed by the line above).
    arduino = new Arduino(this, Arduino.list()[0], 57600);

  arduino.pinMode(9, Arduino.SERVO);
  arduino.pinMode(6, Arduino.OUTPUT);

  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }

  // disable mirror
  context.setMirror(false);

  // enable depthMap generation 
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser();

  stroke(255,255,255);
  smooth();  
  perspective(radians(45),
              float(width)/float(height),
              10,150000);
  
  //Ishan Setup
  arduino.servoWrite(9, servoAngleX);
  arduino.pinMode(11, Arduino.OUTPUT);
  arduino.digitalWrite(11, Arduino.HIGH);
  delay(1000);
 }

void draw()
{
  // update the cam
  context.update();

  background(0,0,0);

  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);

  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     steps   = 3;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;

  translate(0,0,-1000);  // set the rotation center of the scene 1000 infront of the camera

  // draw the pointcloud
  beginShape(POINTS);
  for(int y=0;y < context.depthHeight();y+=steps)
  {
    for(int x=0;x < context.depthWidth();x+=steps)
    { 
      index = x + y * context.depthWidth();
      if(depthMap[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = context.depthMapRealWorld()[index];
        if(userMap[index] == 0)
          stroke(100); 
        else
          stroke(userClr[ (userMap[index] - 1) % userClr.length ]);        

        point(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
      }
    } 
  } 
  endShape();

  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++)
  {
    if(context.isTrackingSkeleton(userList[i]))
      drawSkeleton(userList[i]);

    // draw the center of mass
    if(context.getCoM(userList[i],com))
    {
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com.x - 15,com.y,com.z);
        vertex(com.x + 15,com.y,com.z);

        vertex(com.x,com.y - 15,com.z);
        vertex(com.x,com.y + 15,com.z);

        vertex(com.x,com.y,com.z - 15);
        vertex(com.x,com.y,com.z + 15);
      endShape();

      fill(0,255,100);
      text(Integer.toString(userList[i]),com.x,com.y,com.z);
    }
  }
  
  // draw the kinect cam
  context.drawCamFrustum();
  
  //Ishan Code
  //Delcare Variables
  PVector bodyX = new PVector(bodyCenter.x, 0,0);
  PVector camX = new PVector(camCenter.x, 0,0);
  float distX = bodyX.dist(camX);
  //Debug Printing
  //println(distX);
  //Logic
  //If user is to the right & is within the bounds of servo movement, move to the right
  if(userList.length>=1 && distX>1074.0 && servoAngleX+increment<160)
  {
    servoAngleX=servoAngleX+increment;
    arduino.servoWrite(9, servoAngleX);
  }
  //Else if the user if to the left & within the bounds of servo movement, move to the left
  else if(userList.length>=1 && distX<974 && servoAngleX-increment>30)
  {
    //println(distX);
    servoAngleX=servoAngleX-increment;
    //println("ServoAngle " + servoAngleX);
    arduino.servoWrite(9, servoAngleX);
  }
  //If the user is lost, stay at the last postition & wait
  else
  {
    arduino.servoWrite(9, servoAngleX);
  }
  for(int count=0; count<10; count++)
  {
    shoot(count, SimpleOpenNI.SKEL_RIGHT_HAND, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_LEFT_HAND, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  }
}

//Shooting Method
//Joint key: 1-rightHand, 2-rightShoulder, 3-leftHand, 4-leftShoulder 
void shoot(int userId, int jointType1, int jointType2, int jointType3, int jointType4)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  PVector jointPos3 = new PVector();
  PVector jointPos4 = new PVector();
  float  confidence;
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = context.getJointPositionSkeleton(userId,jointType2,jointPos2);
  confidence = context.getJointPositionSkeleton(userId,jointType3,jointPos3);
  confidence = context.getJointPositionSkeleton(userId,jointType4,jointPos4);
  
  if(jointPos1.y<jointPos2.y && jointPos3.y<jointPos4.y)
  {
    
    arduino.digitalWrite(6, Arduino.HIGH);
    delay(500);
    arduino.digitalWrite(6, Arduino.LOW);
    delay(500);
    println("Shoot!");
    //delay(500);
    //arduino.digitalWrite(6, Arduino.LOW);
    
  }
  else
  {
    arduino.digitalWrite(6, Arduino.LOW);
    //println("NOT SHOOTING");
  }
}
//End Ishan Code
// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  strokeWeight(3);

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  

  handCircle(userId,SimpleOpenNI.SKEL_RIGHT_HAND);
  handCircle(userId,SimpleOpenNI.SKEL_LEFT_HAND);

  drawbuttons(userId,SimpleOpenNI.SKEL_LEFT_HAND,SimpleOpenNI.SKEL_RIGHT_HAND,SimpleOpenNI.SKEL_HEAD); 
  // draw body direction
  getBodyDirection(userId,bodyCenter,bodyDir);

  bodyDir.mult(200);  // 200mm length
  bodyDir.add(bodyCenter);

  stroke(255,200,200);
  line(bodyCenter.x,bodyCenter.y,bodyCenter.z,
       bodyDir.x ,bodyDir.y,bodyDir.z);

  strokeWeight(1);

}
void drawbuttons(int userId,int jointType1,int jointType2,int jointType3){
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  PVector jointPos3 = new PVector();
  float  confidence;
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = context.getJointPositionSkeleton(userId,jointType2,jointPos2);
  confidence = context.getJointPositionSkeleton(userId,jointType3,jointPos3);

  /*if(dist(jointPos1.x,jointPos1.y,-600,500)<100){
    fill(255,255,0);
    arduino.analogWrite(6,255);
  }
  else{
    fill(0,255,255);
    arduino.analogWrite(6,0);
  }*/
  //fill(abs(constrain(jointPos1.x,0,255)), abs(constrain(jointPos1.y,0,255)), abs(constrain(jointPos1.z,0,255)));
  pushMatrix();
  translate(-100 ,100,0);
  ellipse(0,0,50,50);
  popMatrix();

  /*if(dist(jointPos2.x,jointPos2.y,600,500)<100){
    fill(255,255,0);
    arduino.analogWrite(3,255);
  }
  else{
    fill(0,255,255);
    arduino.analogWrite(3,0);
  }*/

  pushMatrix();
  translate(100 ,100,0);
  ellipse(0,0,50,50);
  popMatrix();
  //print(jointPos1.z);print(",");print(jointPos2.z);print(",");println(jointPos3.z);
  //println(bodyCenter.x-camCenter.x);
 

}
void handCircle(int userId,int jointType1)
{
  PVector jointPos1 = new PVector();
  float  confidence;
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  fill(200, 100, 0);
  pushMatrix();
  translate(jointPos1.x,jointPos1.y,jointPos1.z);
  ellipse(0,0,50,50);
  popMatrix();
}

void drawLimb(int userId,int jointType1,int jointType2)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;

  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = context.getJointPositionSkeleton(userId,jointType2,jointPos2);

  stroke(255,0,0,confidence * 200 + 55);
  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z);

  drawJointOrientation(userId,jointType1,jointPos1,50);
}

void drawJointOrientation(int userId,int jointType,PVector pos,float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId,jointType,orientation);
  if(confidence < 0.001f) 
    // nothing to draw, orientation data is useless
    return;

  pushMatrix();
    translate(pos.x,pos.y,pos.z);

    // set the local coordsys
    applyMatrix(orientation);

    // coordsys lines are 100mm long
    // x - r
    stroke(255,0,0,confidence * 200 + 55);
    line(0,0,0,
         length,0,0);
    // y - g
    stroke(0,255,0,confidence * 200 + 55);
    line(0,0,0,
         0,length,0);
    // z - b    
    stroke(0,0,255,confidence * 200 + 55);
    line(0,0,0,
         0,0,length);
  popMatrix();
}

// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(SimpleOpenNI curContext,int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");

  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext,int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext,int userId)
{
  //println("onVisibleUser - userId: " + userId);
}

// -----------------------------------------------------------------
// Keyboard events

void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  }

  switch(keyCode)
  {
    case LEFT:
      rotY += 0.1f;
      break;
    case RIGHT:
      // zoom out
      rotY -= 0.1f;
      break;
    case UP:
      if(keyEvent.isShiftDown())
        zoomF += 0.01f;
      else
        rotX += 0.1f;
      break;
    case DOWN:
      if(keyEvent.isShiftDown())
      {
        zoomF -= 0.01f;
        if(zoomF < 0.01)
          zoomF = 0.01;
      }
      else
        rotX -= 0.1f;
      break;
  }
}

void getBodyDirection(int userId,PVector centerPoint,PVector dir)
{
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float  confidence;

  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_SHOULDER,jointL);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_HEAD,jointH);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointR);

  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,centerPoint);

  /*  // manually calc the centerPoint
  PVector shoulderDist = PVector.sub(jointL,jointR);
  centerPoint.set(PVector.mult(shoulderDist,.5));
  centerPoint.add(jointR);
  */

  PVector up = PVector.sub(jointH,centerPoint);
  PVector left = PVector.sub(jointR,centerPoint);

  dir.set(up.cross(left));
  dir.normalize();
}
