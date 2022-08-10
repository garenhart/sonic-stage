// spi-osc-processing sketch
// GH
import oscP5.*;

OscP5 oscP5;

int[] clr = new int[3];
float rad;
float amp;

// 4 random numbers
int max = 250;
// Which number are we using
int min = 50;
int size = 50; 

void setup() {
  size(300, 300);
  stroke(max-10);
  //frameRate(5);
  oscP5 = new OscP5(this,8000); //set up osc connection, localhost port 8000
}

void draw() {
  // Every frame we access one element of the array
  background(size);
  translate(width/2, height/2);
  ellipse(0, 0, size, size);

  // And then go on to the next one
  size = (size + 10) % max; // Using the modulo operator to cycle a counter back to 0.
  if (size == 0) size = min;
}

void oscEvent(OscMessage msg) {
  
  if (msg.checkAddrPattern("/kick_amp")==true) //<>//
  {
    println("HERE"); //<>//
    amp = msg.get(0).floatValue();
    println(amp);
  } //<>//
}
