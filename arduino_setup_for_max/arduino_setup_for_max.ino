
#include <Wire.h>
#include "MAX30105.h"

MAX30105 particleSensor;

void setup()
{
    Serial.begin(115200);

    Wire.begin();

    delay(1000);

    // initialize max30102

    if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD))
    {
        Serial.println("ERROR:MAX30102_NOT_FOUND");

        while (1)
        {
            delay(1000);
        }
    }

    // configure sensor

    particleSensor.setup(0x10, 1, 2, 50, 411, 4096);

    // clear old readings

    particleSensor.clearFIFO();

    Serial.println("READY");
}

void loop()
{
    // collect available sensor readings

    particleSensor.check();

    while (particleSensor.available())
    {
        // get red and ir values

        uint32_t red = particleSensor.getFIFORed();
        uint32_t ir = particleSensor.getFIFOIR();

        // transmit timestamp, red and ir

        Serial.print(millis());
        Serial.print(",");
        Serial.print(red);
        Serial.print(",");
        Serial.println(ir);

        // advance fifo

        particleSensor.nextSample();
    }
}
