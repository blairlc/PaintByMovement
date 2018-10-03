import processing.video.*;

Capture video;
PImage prev;

float threshold = 50; // increase threshold to decrease motion sensitivity

ArrayList<PointCollection> motionLayers;

void setup() {
  size(640, 480);
  frameRate(30);
  video = new Capture(this, 640, 480);
  video.start();
  prev = createImage(video.width, video.height, RGB);
  motionLayers = new ArrayList<PointCollection>();
}

void captureEvent(Capture video) {
  prev.copy(video, 0, 0, video.width, video.height, 0, 0, prev.width, prev.height);
  prev.updatePixels();
  video.read();
}

void draw() {
  video.loadPixels();
  prev.loadPixels();
  
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
      color prevColor = prev.pixels[loc];
      float r2 = red(prevColor);
      float g2 = green(prevColor);
      float b2 = blue(prevColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      // if color has changed from last frame, add point to motion layer
      if (d > threshold*threshold) {
        motionPixels.add(new PVector(x, y));
      }
    }
  }
  
  // add PointCollection created this frame to the motion layers
  motionLayers.add(new PointCollection(motionPixels, color(0, 0, 255)));   

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
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}
