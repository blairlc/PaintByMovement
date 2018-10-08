import processing.video.*;

Capture video;
PImage background;

float threshold = 60; // increase threshold to decrease motion sensitivity

ArrayList<PointCollection> motionLayers;
PImage updatedPainting; // updated each frame

// used for controlling color
color startColor = color(255, 0, 0);
color endColor = color(0, 0, 255);
int currentColorStep = 0;
int totalColorSteps = 30;
boolean colorIncreasing = true;


int lastLayerTime;
int layerDelay = 67; // time between layers

void setup() {
  size(640, 480);
  video = new Capture(this, 640, 480);
  video.start();
  background = createImage(video.width, video.height, RGB);
  updatedPainting = createImage(video.width, video.height, RGB);
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

  if (millis() - lastLayerTime > layerDelay) {   
    lastLayerTime = millis();
    ArrayList<PVector> motionPixels = new ArrayList<PVector>();

    // loop through every pixel, adding pixels different from background to motionPixels
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
  }

  // remove layers no longer visible
  for (int i = motionLayers.size()-1; i >= 0; i--) {
    if (motionLayers.get(i).isDead()) {
      motionLayers.remove(i);
    }
  }

  // show all layers
  updatePainting();
  image(updatedPainting, 0, 0);

  // flip canvas back around for display
  popMatrix();
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

/* 
 * return the next step in the color spectrum 
 * color increases to max then decreases to 0 repeatedly
 * current value / max is passed into lerpColor between start and end of spectrum
 */
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

/*
 * Updates the updatedPainting PImage. Points, color, and opacity are retrieved from each 
 * PointCollection in motionLayers. Newer layers are drawn over older layers. Opacity is done 
 * using lerpColor between the layer's color and black.
*/
public void updatePainting() {
  updatedPainting = createImage(video.width, video.height, RGB);
  updatedPainting.loadPixels();
  for (PointCollection pc : motionLayers) {
    // lerp between color and black creates opacity gradient
    color pointColor = lerpColor(color(0, 0, 0), pc.pointColor, pc.getOpacity());
    // draw each point into the painting
    for (PVector p : pc.points) {
      int loc = (int)p.x + (int)p.y * video.width;
      updatedPainting.pixels[loc] = pointColor;
    } 
  }
  updatedPainting.updatePixels();
}

void mouseClicked() {
  background.copy(video, 0, 0, video.width, video.height, 0, 0, background.width, background.height);
  background.updatePixels();
  motionLayers.clear(); // get rid of layers based on old background
}
