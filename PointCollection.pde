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
  
  void show() {
    int age = millis() - creationTime; //<>//
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
}
