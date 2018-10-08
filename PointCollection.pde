class PointCollection {
  static final int lifespan = 3000; // how many millis the layer is visible
  
  color pointColor;
  ArrayList<PVector> points;
  int creationTime;  

  PointCollection (ArrayList<PVector> points, color pColor) {
    this.points = points;
    creationTime = millis();
    pointColor = pColor;
  }

 /* //<>//
  * Draws every point in this layer using point()
  * Method left for future use/debugging but it is too slow 
  * to use for every layer every frame.
  */
  void show() {
    int age = millis() - creationTime; 
    float opacity = map(age, 0, lifespan, 255, 0);
    stroke(pointColor, opacity);
    for (PVector p : points) {
      point(p.x, p.y);
    }
  }
  
  boolean isDead() {
    int age = millis() - creationTime;
    return age > lifespan;
  }
  
  // returns opactity as a value between 0 and 1.0
  float getOpacity() {
    int age = millis() - creationTime;
    return map(age, 0, lifespan, 1, 0);
  }
}
