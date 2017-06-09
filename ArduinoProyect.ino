#include <WiFi.h>
#include <Servo.h>
#include <SPI.h>
#include <HttpClient.h>
#include <MemoryFree.h>
#include <aJSON.h>

// Wifi Status
char ssid[] = "Aq";
char pass[] = "Aquaris_A45";
int status = WL_IDLE_STATUS;
#define CONTENT_MAX_LENGTH 300

// Direccion del servidor de destino
int times;
const char kHostname[] = "mobility-final-project.herokuapp.com";
const int TIMES_TO_REFRESH_CLOUD = 10;
const int kNetworkTimeout = 30*1000;
const int kNetworkDelay = 1000;
char responseContent[CONTENT_MAX_LENGTH]="";

// Dispositivos
const int LED_SALON_PIN_ADDRESS = 6;
const int LED_COCINA_PIN_ADDRESS = 2;
const int LED_HABITACION_PIN_ADDRESS = 3;
const int ENGINE_PIN_ADDRESS = 5;
const int TEMPERATURE_PIN_ADDRESS = A0;

Servo servoMotor;
const int PERSIANA_FULL_MOVEMENT_TIME = 5000;

float persianaPosition = 0.5;
float currentTemperature;
float desiredTemperature;

WiFiClient c;
HttpClient http(c);

void setup() {
  Serial.begin(9600);
   
  servoMotor.attach(ENGINE_PIN_ADDRESS);
  pinMode(LED_SALON_PIN_ADDRESS, OUTPUT);
  pinMode(LED_COCINA_PIN_ADDRESS, OUTPUT);
  pinMode(LED_HABITACION_PIN_ADDRESS, OUTPUT);
  pinMode(TEMPERATURE_PIN_ADDRESS, INPUT);
  
  connectToWifi();
}

void loop() {
  Serial.print(F("freeMemory()="));
  Serial.println(freeMemory());
  
  boolean value;
  float newPosition;
  
  // Comprobar bombillas
  getData("bombilla", "salon");
  value = parseBombillaValue();
  switchBombilla(LED_SALON_PIN_ADDRESS, value);
  
  getData("bombilla", "cocina");
  value = parseBombillaValue();
  switchBombilla(LED_COCINA_PIN_ADDRESS, value);
  
  getData("bombilla", "habitacion");
  value = parseBombillaValue();
  switchBombilla(LED_HABITACION_PIN_ADDRESS, value);

  // Comprobar y enviar temperatura
  getData("climatizador", "sala");
  desiredTemperature = parseClimatizadorValue();
  readSensorTemperature();
  putTemperatureData();
  
  // Comprobar y actuar persianas
  getData("persiana", "persiana1");
  newPosition = parsePersianaValue();
  switchPersiana(newPosition, persianaPosition);
  
  checkWifiStatus();
  Serial.println(F("=========================================================="));
  delay(4000);
}

void switchBombilla(int devicePin, boolean isEnabled) {    
    if (isEnabled) {
      analogWrite(devicePin, 255);
    } else {
      analogWrite(devicePin, 0); 
    }
}

void switchPersiana(float percentage, float currentPosition) {
  float finalPosition = percentage;
  currentPosition *= 360;
  percentage *=360;
  
  Serial.println(F("Posiciones de persianas"));
  Serial.println(F("Final:"));
  Serial.println(finalPosition);
  Serial.println(F("Inicial:"));
  Serial.println(persianaPosition);
  
  if (persianaPosition > finalPosition) {
    for (currentPosition; currentPosition > percentage; currentPosition--) {
       servoMotor.write(currentPosition);
       delay(15);                   
    }
  } else if (persianaPosition < finalPosition) {
    for (currentPosition; currentPosition < percentage; currentPosition++) {
       servoMotor.write(currentPosition);
       delay(15);                   
    }
  }
  
  persianaPosition = finalPosition;
}

void readSensorTemperature() {
  currentTemperature = analogRead(TEMPERATURE_PIN_ADDRESS);
  currentTemperature = ((currentTemperature * 0.004882814) - .5) * 100;
  
  Serial.print(F("Temperatura: "));
  Serial.println(currentTemperature);
  Serial.print(F("Temperatura Objetivo: "));
  Serial.println(desiredTemperature);
}

void putTemperatureData() {
  int err;
  char DESTINY[100];
  char temp[10];
  memset(responseContent, 0, CONTENT_MAX_LENGTH);
  
  dtostrf(currentTemperature, 1, 2, temp);
  sprintf(DESTINY, "/api/arduino/climatizador/sala?temperatura=%s", temp);
  
  Serial.print(F("PUT to: "));
  Serial.print(DESTINY);
  
  err = http.get(kHostname, DESTINY);
  if (err == 0) {
      Serial.println(F("startedRequest ok"));
  
      err = http.responseStatusCode();
      if (err >= 0) {
        Serial.print(F("Got status code: "));
        Serial.println(err);
  
        err = http.skipResponseHeaders();
      } else {    
        Serial.print(F("Getting response failed: "));
        Serial.println(err);
      }
    } else {
      Serial.print(F("Connect failed: "));
      Serial.println(err);
    }
  http.stop();
}

void getData(char device[], char nombre[]) {
  int err;
  char requestConverted[200];
  memset(responseContent, 0, CONTENT_MAX_LENGTH);
  sprintf(requestConverted, "%s%s%s%s", "/api/", device, "/", nombre);
  
  Serial.print(F("Request to: "));
  Serial.println(requestConverted);
  
  err = http.get(kHostname, requestConverted);
  if (err == 0) {
    Serial.println(F("startedRequest ok"));

    err = http.responseStatusCode();
    if (err >= 0) {
      Serial.print(F("Got status code: "));
      Serial.println(err);

      err = http.skipResponseHeaders();
      if (err >= 0) {
        int bodyLen = http.contentLength();
        Serial.print(F("Content length is: "));
        Serial.println(bodyLen);
        Serial.println();
        Serial.println(F("Body returned follows:"));
        
        unsigned long timeoutStart = millis();
        char c;
        while ( (http.connected() || http.available()) &&
               ((millis() - timeoutStart) < kNetworkTimeout) ) {
            if (http.available()) {
                c = http.read();

                int lastPos = strlen(responseContent);
                responseContent[lastPos] = c;
                responseContent[++lastPos] = '\0';
               
                bodyLen--;
                timeoutStart = millis();
            } else {
                delay(kNetworkDelay);
            }
        }
        
        Serial.println(responseContent);
      }
      else {
        Serial.print(F("Failed to skip response headers: "));
        Serial.println(err);
      }
    } else {    
      Serial.print(F("Getting response failed: "));
      Serial.println(err);
    }
  } else {
    Serial.print(F("Connect failed: "));
    Serial.println(err);
  }
  
  http.stop();
}


void checkWifiStatus()
{
  if ((status = WiFi.status()) != WL_CONNECTED) {
     Serial.println(F("Connection lost!"));
     connectToWifi(); 
  }
}

void connectToWifi() {
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  if ((status = WiFi.status()) == WL_NO_SHIELD) {
    Serial.println(F("WiFi shield not present")); 
    // don't continue:
    while(true);
  }
  while (status != WL_CONNECTED) { 
    Serial.print(F("Attempting to connect to WPA SSID: "));
    Serial.println(ssid);   
    status = WiFi.begin(ssid, pass);

    delay(10000);
  }
   
  Serial.println(F("You're connected to the network"));
}

char* buildTemperatureInfo() {  
  boolean value;
  char* resp;
  
  aJsonObject* root = aJson.createObject();
  aJson.addStringToObject(root, "nombre", "sala");
  aJson.addNumberToObject(root, "temperaturaObjetivo", desiredTemperature);
  aJson.addNumberToObject(root, "temperaturaActual", currentTemperature);
  resp = aJson.print(root);
  
  // Super-important. Once done, deleteto root element to free memory!!
  aJson.deleteItem(root);
  
  return resp;
}

boolean parseBombillaValue() {  
  boolean value;
  aJsonObject* root = aJson.parse(responseContent);
  aJsonObject* json_value = aJson.getObjectItem(root, "encendida");
  value = json_value->valuebool;
  
  // Super-important. Once done, deleteto root element to free memory!!
  aJson.deleteItem(root);
  
  return value;
}

float parsePersianaValue() {
  float value;
  aJsonObject* root = aJson.parse(responseContent);
  aJsonObject* json_value = aJson.getObjectItem(root, "porcentajeAbierta");
  
  value = json_value->valuefloat;
  
  // Super-important. Once done, deleteto root element to free memory!!
  aJson.deleteItem(root);
  
  return value;
}

float parseClimatizadorValue() {
  float value;
  aJsonObject* root = aJson.parse(responseContent);
  aJsonObject* json_value = aJson.getObjectItem(root, "temperaturaObjetivo");
  
  value = json_value->valuefloat;
  
  // Super-important. Once done, deleteto root element to free memory!!
  aJson.deleteItem(root);
  
  return value;
}


