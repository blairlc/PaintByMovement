import processing.video.*;

Capture video;
PImage background;

float threshold = 60; // increase threshold to decrease motion sensitivity

ArrayList<PointCollection> motionLayers;

color startColor = color(255, 0, 0);
color endColor = color(0, 0, 255);
int currentColorStep = 0;
int totalColorSteps = 30;
boolean colorIncreasing = true;

void setup() {
  size(640, 480);
  frameRate(30);
  video = new Capture(this, 640, 480);
  video.start();
  background = createImage(video.width, video.height, RGB);
  motionLayers = new ArrayList<PointCollection>();
}

void captureEvent(Capture video) {
  video.read();
}

void draw() {
  // flip canvas backwards so user's movement is mirrored
  pushMatrix();
  scale(-1, 1);
  translate(-width, 0);
  
  video.loadPixels();
  background.loadPixels();

  background(0);

  // uncomment for video background
  //image(video, 0, 0);

  ArrayList<PVector> motionPixels = new ArrayList<PVector>();

  // loop through every pixel
  for (int x = 0; x < video.width; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;

      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      color backgroundColor = background.pixels[loc];
      float r2 = red(backgroundColor);
      float g2 = green(backgroundColor);
      float b2 = blue(backgroundColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      // if color has changed from last frame, add point to motion layer
      if (d > threshold*threshold) {
        motionPixels.add(new PVector(x, y));
      }
    }
  }

  // add PointCollection created this frame to the motion layers
  motionLayers.add(new PointCollection(motionPixels, getNextColor()));   

  // remove layers no longer visible
  for (int i = motionLayers.size()-1; i >= 0; i--) {
    if (motionLayers.get(i).isDead()) {
      motionLayers.remove(i);
    }
  }

  // show all layers
  for (PointCollection layer : motionLayers) {
    layer.show();
  }
  
  // flip canvas back around for display
  popMatrix();
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

// move to the next step in the color spectrum and return it
// color increases to max then decreases to 0 repeatedly
// current value / max is passed into lerpColor between start and end of spectrum
color getNextColor() {
  if (colorIncreasing) {
    if (currentColorStep < totalColorSteps) {
      currentColorStep++;
    } else {
      currentColorStep--;
      colorIncreasing = false;
    }
  } else {
    if (currentColorStep > 0) {
      currentColorStep--;
    } else {
      currentColorStep++;
      colorIncreasing = true;
    }
  }
  return lerpColor(startColor, endColor, ((float) currentColorStep / (float) totalColorSteps));
}

void mouseClicked() {
  background.copy(video, 0, 0, video.width, video.height, 0, 0, background.width, background.height);
  background.updatePixels();
}
