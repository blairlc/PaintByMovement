import processing.video.*;

final boolean freezeFrameMode = false;

Capture video;
PImage background;

float motionColorThreshold = 80; // increase threshold to decrease motion sensitivity

// used only in freeze frame mode
float motionPercentThreshold = .01; // percent of pixels that can change without being considered motion
float motionPixelsThreshold;
int frozenFrames = 0;

ArrayList<PointCollection> motionLayers;
PImage updatedPainting; // updated each frame
PImage prevImage;

// used for controlling color
color startColor = color(255, 0, 0);
color endColor = color(0, 0, 255);
int currentColorStep = 0;
int totalColorSteps = 30; 
boolean colorIncreasing = true;

int videoWidth = 640, videoHeight = 480;
int topPadding = 0; // total vertical padding to preserve ratio, half top and half bottom
int sidePadding = 0; // total horizontal padding

int lastLayerTime;
int layerDelay = 50; // time between layers in ms

void setup() {
  fullScreen();
  video = new Capture(this, videoWidth, videoHeight);
  video.start();
  background = createImage(video.width, video.height, RGB);
  prevImage = createImage(video.width, video.height, RGB);
  updatedPainting = createImage(video.width, video.height, RGB);
  motionLayers = new ArrayList<PointCollection>();
  motionPixelsThreshold = video.width * video.height * motionPercentThreshold;

  float videoRatio = (float) videoWidth / videoHeight;
  float screenRatio = (float) width / height;

  if (videoRatio > screenRatio) {
    // space top and bottom
    float widthMultiplier = (float) width / videoWidth;
    topPadding = (int) (height - (videoHeight * widthMultiplier));
  } else if (screenRatio > videoRatio) {
    // space on sides
    float heightMultiplier = (float) height / videoHeight;
    sidePadding = (int) (width - (videoWidth * heightMultiplier));
  }
}

void captureEvent(Capture video) {
  prevImage.copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height); 
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
        if (d > motionColorThreshold*motionColorThreshold) {
          motionPixels.add(new PVector(x, y));
        }
      }
    }

    if (freezeFrameMode) {
      // if you have been moving and then freeze, take a picture
      float d = imgDiff(video, prevImage);
      if (d < motionPixelsThreshold) { // no movement since last frame
        if (frozenFrames == 0) { // first frozen frame
          motionLayers.add(new PointCollection(motionPixels, getNextColor()));
        }
        frozenFrames++;
      } else { // movement since last frame
        frozenFrames = 0;
      }
    } else {
      motionLayers.add(new PointCollection(motionPixels, getNextColor()));
    }
  }

  // remove layers no longer visible
  for (int i = motionLayers.size()-1; i >= 0; i--) {
    if (motionLayers.get(i).isDead()) {
      motionLayers.remove(i);
    }
  }

  // show all layers
  updatePainting();
  imageMode(CENTER);
  image(updatedPainting, width/2, height/2, width - sidePadding, height - topPadding);

  // flip canvas back around for display
  popMatrix();
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

float imgDiff(PImage img1, PImage img2) {
  float diffPixels = 0;
  img1.loadPixels();
  img2.loadPixels();
  for (int x = 0; x < video.width; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;

      color img1Color = img1.pixels[loc];
      float r1 = red(img1Color);
      float g1 = green(img1Color);
      float b1 = blue(img1Color);
      color img2Color = img2.pixels[loc];
      float r2 = red(img2Color);
      float g2 = green(img2Color);
      float b2 = blue(img2Color);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d > motionColorThreshold * motionColorThreshold) {
        diffPixels++;
      }
    }
  }
  return diffPixels;
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
