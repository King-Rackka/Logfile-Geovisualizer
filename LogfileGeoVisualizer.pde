import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;// PENTING: Untuk format tanggal
import java.util.HashMap;
import processing.core.PImage;
import processing.core.PShape; 

// --- Variabel Global ---
int LOADING = 0;
int LOGFILE = 1;
int GEOCODING = 2;
int DONE = 3;
int state = LOADING;
int count = 0;
int total = 0;
float a = 0;

HashMap<Long, IPdb> ipdatabase;
LogRow[] data;

// Aset Visual
PImage world;      // Gambar peta dasar
PImage worldNeon;  // Tekstur Globe Neon
PImage bluemarble;
PImage night;
PShape pin; 
PShape sphere;
PShader blur;
PShader edge;

// Mode Switcher
boolean showGlobe = false; // False = 2D, True = 3D (Tekan Spasi)
boolean satelite = false;

void setup() {  
  size(700, 450, P3D); 
  
  pin = loadShape("pin.svg"); 
  world = loadImage("world.png"); 
  
  frameRate(25);
  initGlobe();
  
  Thread t = new Thread(new Runnable() {
    public void run() {
      state = LOADING;
      ipdatabase = parseIpDatabase("hip_ip4_city_lat_lng.csv");
      
      state = LOGFILE;
      String[] log = loadStrings("access.log");
      if (log != null) {
        data = parseLogfile(log);
        
        state = GEOCODING;
        geoCode(data);
      } else {
        println("ERROR: File access.log tidak ditemukan!");
      }
      
      state = DONE;
    }
  });
  t.start();
}

void initGlobe() {
  PGraphics g = createGraphics(700, 349);
  g.beginDraw();
  PImage tmp = loadImage("world.png"); 
  
    tmp.filter(INVERT);
    g.tint(100, 255, 0);
    g.image(tmp, 0, 0);
    g.endDraw();
  worldNeon = g.get();
  
  bluemarble = loadImage("bluemarble.jpg");
  night = loadImage("night.jpg");
  
  // Buat bola bumi default (Neon)
  sphere = makeSphere(150, 5, worldNeon);   
  
  // Load shader dengan aman (try-catch)
  try {
    edge = loadShader("edges.glsl");  
    blur = loadShader("blur.glsl");
  } catch (Exception e) {
    println("Shader tidak ditemukan, efek neon dimatikan.");
  }
}

// Fungsi manual membuat bola
PShape makeSphere(int R, int step, PImage tex) {
  PShape s = createShape();
  s.beginShape(QUAD_STRIP);
  if (tex != null) s.texture(tex);
    // Aktifkan jaring biru
  s.stroke(0, 0, 255);
  s.strokeWeight(2);
  
  //for (int i = 0; i < 180; i+=step) {
  //  float sini = sin(radians(i));
  //  float cosi = cos(radians(i));
  //  float sinip = sin(radians(i + step));
  //  float cosip = cos(radians(i + step));
  //  for (int j = 0; j <= 360; j+=step) {
  //    float sinj = sin(radians(j));
  //    float cosj = cos(radians(j));
      
  //    s.normal(cosj * sini, -cosi, sinj * sini);
  //    s.vertex(R * cosj * sini, R * -cosi, R * sinj * sini, tex.width-j * tex.width / 360, i * tex.height / 180);         
  //    s.normal(cosj * sinip, -cosip, sinj * sinip);
  //    s.vertex(R * cosj * sinip, R * -cosip, R * sinj * sinip, tex.width-j * tex.width / 360, (i + step ) * tex.height / 180);
  //  }
  //}
  
  for ( int i = 0; i < 180; i+=step ) { 
    float sini = sin( radians( i )); 
    float cosi = cos( radians( i ));
    float sinip = sin( radians( i + step )); 
    float cosip = cos( radians( i + step ));

  for ( int j = 0; j <= 360; j+=step ) { 
    float sinj = sin( radians( j )); 
    float cosj = cos( radians( j ));
    float sinjp = sin( radians( j + step )); 
    float cosjp = cos( radians( j + step ));
    
   s.normal( cosj * sini, -cosi, sinj * sini);
  s.vertex( R * cosj * sini, R * -cosi, R * sinj * sini, tex.width-j * tex.width / 360, i * tex.height / 180);
  
  s.normal( cosj * sinip, -cosip, sinj * sinip);
s.vertex( R * cosj * sinip, R * -cosip, R * sinj * sinip, tex.width-j * tex.width / 360, (i + step ) * tex.height / 180);
    }
}
  
  s.endShape(); 
  return s;
}

void keyPressed() {
  // GANTI MODE DENGAN SPASI
  if (key == ' ') {
    showGlobe = !showGlobe;
  }
  
  // GANTI TEKSTUR (1, 2, 3)
  if (key == '1') {
    satelite = false; 
    sphere = makeSphere(150, 5, worldNeon);
  }
  else if (key == '2') {
    if (bluemarble != null) {
      sphere.setTexture(bluemarble);
      satelite = true;
    }
  }
  else if (key == '3') {
    if (night != null) {
      sphere.setTexture(night);
      satelite = true;
    }
  }
}

void draw() {
  if (showGlobe) {
    // --- MODE 3D ---
    background(0);
    hint(ENABLE_DEPTH_TEST);
    drawGlobe();
    
    // UI (Timeline & Loading)
    hint(DISABLE_DEPTH_TEST);
    noLights();
    drawUI(true); // Mode gelap
    
  } else {
    // --- MODE 2D ---
    background(255);
    hint(DISABLE_DEPTH_TEST);
    noLights();
    
    // Gambar Peta Datar
    if (world != null) image(world, 0, 0, width, height-50);
    
    // Gambar Pin di Peta Datar
    if ( state < DONE ) {
    stroke( 0, 200 );
    strokeWeight(2);
    fill( 200, 200 );
    rect( 25, 150, 650, 50 );
    noStroke();
    fill( 255 );
    rect( 30, 155, map( count, 0, total, 0, 640 ), 40 );
    fill( 0 );
    String msg="";
    if ( state == LOADING ) {
      msg = "loading database ...";
    }
    else if ( state == LOGFILE ) {
      msg = "parsing logfile ...";
    }
    else if ( state == GEOCODING ) {
      msg = "geocoding ip adresses ...";
    }
    text( msg, 35, 190 );
  } else if (state == DONE) {
    noStroke();
    fill(255);
    rect(0, 350, 700, 50);
    stroke(0, 10);
    long mints = data[0].timestamp;
    long maxts = data[ data.length-1].timestamp;
    for ( int i=0; i<data.length; i++) {
      float pos = map( data[i].timestamp, mints, maxts, 0, 700 );
      line( pos, 350, pos, 400 );
    }
   stroke(255, 0, 0);
for (int i=0; i < data.length; i++) {
  if (data[i].lat != null && data[i].lon != null) {
    
    float x = map(float(data[i].lon), -180, 180, 0, width);
    float y = map(float(data[i].lat), 90, -90, 0, height - 50);

    noStroke();

    if (pin != null) {
        shape(pin, x - 8, y - 16, 16, 24);  // tampilkan pin.svg
    } else {
        fill(255, 0, 0);
        ellipse(x, y, 8, 8);               // fallback titik merah
    }
  }
}
  }

  }
}

// Fungsi Menggambar UI (Loading & Timeline)
void drawUI(boolean darkMode) {
  if (state < DONE) {
    // Loading Bar
    stroke(0, 200); strokeWeight(2); fill(200, 200);
    rect(width/2 - 150, height/2, 300, 40);
    noStroke(); fill(0, 100, 255);
    float w = 0;
    if (total > 0) w = map(count, 0, total, 0, 290);
    rect(width/2 - 145, height/2 + 5, w, 30);
    
    fill(0); textAlign(CENTER);
    String msg = "";
    if (state == LOADING) msg = "Loading database...";
    else if (state == LOGFILE) msg = "Parsing logfile...";
    else if (state == GEOCODING) msg = "Geocoding addresses...";
    text(msg, width/2, height/2 + 25);
    textAlign(LEFT);
    
  } else if (state == DONE) {
    // Timeline
    noStroke();
    if (darkMode) fill(0); else fill(200);
    rect(0, height-50, width, 50);
    
    if (darkMode) stroke(255, 255, 0, 50); else stroke(0, 50);
    
    if (data != null && data.length > 0) {
      // Cari min dan max timestamp
      // Catatan: data[0] mungkin null jika baris pertama log rusak, jadi kita loop cari yg valid
      long mints = 0;
      long maxts = 0;
      
      // Cari data valid pertama dan terakhir
      for(LogRow r : data) { if(r!=null) { mints = r.timestamp; break; } }
      for(int i=data.length-1; i>=0; i--) { if(data[i]!=null) { maxts = data[i].timestamp; break; } }
      
      if (maxts > mints) {
        for (int i=0; i<data.length; i++) {
          if (data[i] != null) {
            float pos = map(data[i].timestamp, mints, maxts, 0, width);
            line(pos, height-50, pos, height);
          }
        }
      }
    }
  }
}

void drawGlobe() {
  pushMatrix();
  translate(width/2, (height-50)/2);
  lights();
  pushMatrix();
  rotateX(radians(-30));
  rotateY(a);
  a+= 0.01;   
  drawGlobePins(); // Gambar garis kuning
  shape(sphere);
  popMatrix();
  popMatrix();
  
  if ( !satelite ) { 
    filter(edge); 
    filter(blur);
  }

}

void drawGlobePins() {
  float R = 160;
  if (state == DONE && data != null) {
    strokeWeight(1);
    stroke(255, 250, 0); // Kuning
    
    beginShape(LINES);
    for (int i=0; i<data.length; i++) {
      if (data[i] != null && data[i].lat != null && data[i].lon != null) {
        try {
          float la = map(float(data[i].lat), 90, -90, 0, 180);
          float lo = map(float(data[i].lon), 180, -180, 0, 360);
          float sini = sin(radians(la));
          float cosi = cos(radians(la));
          float sinj = sin(radians(lo));
          float cosj = cos(radians(lo));
          
          vertex(0, 0, 0);
          vertex(R * cosj * sini, R * -cosi, R * sinj * sini);
        } catch (Exception e) {}
      }   
    }
    endShape();
  }   
}

// --- PARSING HELPERS ---

HashMap<Long, IPdb> parseIpDatabase(String filename) {
  String[] raw = loadStrings(filename);
  if (raw == null) return new HashMap<Long, IPdb>();
  total = raw.length;
  
  HashMap<Long, IPdb> map = new HashMap<Long, IPdb>(total);
  for (int i = 0; i < raw.length; i++) {
    count = i;
    String[] parts = raw[i].split(",");
    
    if (parts.length >= 4) {
      try {
        // Membersihkan tanda kutip
        String ipStr = parts[0].replace("\"", "");
        String latStr = parts[2].replace("\"", "");
        String lonStr = parts[3].replace("\"", "");
        
        long ipblock = Long.parseLong(ipStr); 
        map.put(ipblock, new IPdb(ipblock, latStr, lonStr));
      } catch (Exception e) {}
    }
  }
  return map;
}

LogRow[] parseLogfile(String[] rows) {
 // Gunakan Locale.US agar 'Jan', 'Feb' terbaca di PC Indonesia
 SimpleDateFormat sdf = new SimpleDateFormat("dd/MMM/yyyy:HH:mm:ss Z", Locale.US);
 
 ArrayList<LogRow> validRows = new ArrayList<LogRow>();
 
 for(int i=0; i< rows.length; i++) {
   count = i;
   if (rows[i].trim().length() == 0) continue;
   
   String[] m = match(rows[i], "(\\d+\\.\\d+\\.\\d+\\.\\d+) - - \\[(.*)\\]");
   if (m != null) {
     try {
       long time = sdf.parse(m[2]).getTime();
       validRows.add(new LogRow(m[1], time));
     } catch(Exception e) {}
   }
 }
 return validRows.toArray(new LogRow[validRows.size()]);
}

void geoCode(LogRow[] data) {
  total = data.length;
  for (int i = 0; i < data.length; i++) {
    count = i;
    if (data[i] != null && data[i].ip != null) {
      try {
        String[] block = data[i].ip.split("\\.");
        if (block.length == 4) {
          // Gunakan Long.parseLong agar tidak error syntax
          long p1 = Long.parseLong(block[0]);  
          long p2 = Long.parseLong(block[1]);
          long p3 = Long.parseLong(block[2]);
          
          long ipNum = (p1 * 256 * 256 * 256) + (p2 * 256 * 256) + (p3 * 256);
          
          if (ipdatabase.containsKey(ipNum)) {
             IPdb r = ipdatabase.get(ipNum);
             data[i].setLatLon(r.lat, r.lon);
          }
        }
      } catch (Exception e) {}
    }
  }
}
