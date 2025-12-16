class LogRow {
  String ip;
  long timestamp;
  String lat;
  String lon;
  
  public LogRow(String ip, long timestamp) {
    this.ip = ip;
    this.timestamp = timestamp;
  }
  
  void setLatLon(String lat, String lon) {
    this.lat = lat;
    this.lon = lon;
  }
}
