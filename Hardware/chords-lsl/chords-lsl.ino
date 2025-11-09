// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// Copyright (c) 2024 - 2025 Upside Down Labs - contact@upsidedownlabs.tech
// Author: Deepak Khatri
//
// At Upside Down Labs, we create open-source DIY neuroscience hardware and software.
// Our mission is to make neuroscience affordable and accessible for everyone.
// By supporting us with your purchase, you help spread innovation and open science.
// Thank you for being part of this journey with us!

#include <Arduino.h>

/** 
** Select your board from list below
** Uncomment only your board macro
**/

// #define BOARD_NANO_CLONE
// #define BOARD_MAKER_NANO
// #define BOARD_NANO_CLASSIC
#define BOARD_UNO_R3
// #define BOARD_GENUINO_UNO
// #define BOARD_UNO_CLONE
// #define BOARD_MAKER_UNO
// #define BOARD_MEGA_2560_R3
// #define BOARD_MEGA_2560_CLONE

// Board specific macros
// Do not edit anything!
#if defined(BOARD_UNO_R3)
#define BOARD_NAME "UNO-R3"
#define NUM_CHANNELS 6
#elif defined(BOARD_GENUINO_UNO)
#define BOARD_NAME "GENUINO-UNO"
#define NUM_CHANNELS 6
#elif defined(BOARD_UNO_CLONE) || defined(BOARD_MAKER_UNO)
#define BOARD_NAME "UNO-CLONE"
#define NUM_CHANNELS 6
#elif defined(BOARD_NANO_CLASSIC)
#define BOARD_NAME "NANO-CLASSIC"
#define NUM_CHANNELS 8
#elif defined(BOARD_NANO_CLONE) || defined(BOARD_MAKER_NANO)
#define BOARD_NAME "NANO-CLONE"
#define NUM_CHANNELS 8
#elif defined(BOARD_MEGA_2560_R3)
#define BOARD_NAME "MEGA-2560-R3"
#define NUM_CHANNELS 16
#elif defined(BOARD_MEGA_2560_CLONE)
#define BOARD_NAME "MEGA-2560-CLONE"
#define NUM_CHANNELS 16
#else
#error "Board type not selected, please uncomment your BOARD macro!"
#endif

// Common macros
#define SAMP_RATE 250
#define BAUD_RATE 9600
#define HEADER_LEN 3                                    // Header = SYNC_BYTE_1 + SYNC_BYTE_2 + Counter
#define PACKET_LEN (NUM_CHANNELS * 2 + HEADER_LEN + 1)  // Packet length = Header + Data + END_BYTE
#define SYNC_BYTE_1 0xC7                                // Packet first byte
#define SYNC_BYTE_2 0x7C                                // Packet second byte
#define END_BYTE 0x01                                   // Packet last byte

// defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

// Global constants and variables
uint8_t packetBuffer[PACKET_LEN];  // The transmission packet
uint8_t currentChannel;            // Current channel being sampled
uint16_t adcValue = 0;             // ADC current value
bool timerStatus = false;          // SATUS bit
bool bufferReady = false;          // Buffer ready status bit


// Designed for 125 Hz!!!!
// Coeff arrays: one entry per section.
const int NUM_SECTIONS = 4;
const float ECG_a1[NUM_SECTIONS] = { 0.70682283f, 0.95028224f, -1.95360385f, -1.98048558f };
const float ECG_a2[NUM_SECTIONS] = { 0.15621030f, 0.54073140f, 0.95423412f, 0.98111344f };
const float ECG_b0[NUM_SECTIONS] = { 0.28064917f, 1.00000000f, 1.00000000f, 1.00000000f };
const float ECG_b1[NUM_SECTIONS] = { 0.56129834f, 2.00000000f, -2.00000000f, -2.00000000f };
const float ECG_b2[NUM_SECTIONS] = { 0.28064917f, 1.00000000f, 1.00000000f, 1.00000000f };

// Per-channel state: z1 and z2 for each section and each channel
// z_state[channel][section][state_index] where state_index 0 => z1, 1 => z2
static float z_state[NUM_CHANNELS][NUM_SECTIONS][2];



float ECGFilterChannel(uint8_t channel, float input) {
  float output = input;
  for (int s = 0; s < NUM_SECTIONS; ++s){
    float z1 = z_state[channel][s][0];
    float z2 = z_state[channel][s][1];
    float x = output - ECG_a1[s] * z1 - ECG_a2[s] * z2;
    output = ECG_b0[s] * x + ECG_b1[s] * z1 + ECG_b2[s] * z2;
    z_state[channel][s][1] = z1;
    z_state[channel][s][0] = x;
  }
  return output;
}

// searches for the string sfind in the string str
// returns 1 if string found
// returns 0 if string not found

bool timerStart() {
  timerStatus = true;
  digitalWrite(LED_BUILTIN, HIGH);
  // Enable Timer1 Compare A interrupt
  return TIMSK1 |= (1 << OCIE1A);
}

bool timerStop() {
  timerStatus = false;
  bufferReady = false;
  digitalWrite(LED_BUILTIN, LOW);
  // Disable Timer1 Compare A interrupt
  return TIMSK1 &= ~(1 << OCIE1A);
}

// ISR for Timer1 Compare A match (called based on the sampling rate)
ISR(TIMER1_COMPA_vect) {
  // ADC value Reading, Converting, and Storing:
    for (currentChannel = 0; currentChannel < NUM_CHANNELS; currentChannel++) {

      // Read ADC input
      adcValue = analogRead(currentChannel);

      //FILTER
      float raw_f = (float)adcValue;
      float filtered_f = ECGFilterChannel(currentChannel, raw_f);
      int16_t filtered_i16 = (int16_t) round(filtered_f);
      uint16_t encoded = (uint16_t)( (uint16_t)filtered_i16 + 0x8000 );

      // Store current values in packetBuffer to send.
      packetBuffer[((2 * currentChannel) + HEADER_LEN)] = highByte(encoded);     // Write High Byte
      packetBuffer[((2 * currentChannel) + HEADER_LEN + 1)] = lowByte(encoded);  // Write Low Byte
    }

    // Increment the packet counter
    packetBuffer[2]++;

    bufferReady = true;

}

void timerBegin(float sampling_rate) {
  cli();  // Disable global interrupts

  // Set prescaler division factor to 16
  sbi(ADCSRA, ADPS2);  // 1
  cbi(ADCSRA, ADPS1);  // 0
  cbi(ADCSRA, ADPS0);  // 0

  // Calculate OCR1A based on the interval
  // OCR1A = (16MHz / (Prescaler * Desired Time)) - 1
  // Prescaler options: 1, 8, 64, 256, 1024
  unsigned long ocrValue = (16000000 / (8 * sampling_rate)) - 1;

  // Configure Timer1 for CTC mode (Clear Timer on Compare Match)
  TCCR1A = 0;  // Clear control register A
  TCCR1B = 0;  // Clear control register B
  TCNT1 = 0;   // Clear counter value

  // Set the calculated value in OCR1A register
  OCR1A = ocrValue;

  // Set CTC mode (WGM12 bit) and set the prescaler to 8
  TCCR1B |= (1 << WGM12) | (1 << CS11);  // Prescaler = 8

  sei();  // Enable global interrupts
}

void setup() {
  Serial.begin(BAUD_RATE);
  // while (!Serial) {
  //   ;  // Wait for serial port to connect. Needed for native USB
  // }

  // Status LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // Initialize packetBuffer
  packetBuffer[0] = SYNC_BYTE_1;            // Sync 0
  packetBuffer[1] = SYNC_BYTE_2;            // Sync 1
  packetBuffer[2] = 0;                      // Packet counter
  packetBuffer[PACKET_LEN - 1] = END_BYTE;  // End Byte

  // Setup timer
  timerBegin(SAMP_RATE);
}

void loop() {
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();         // Remove extra spaces or newline characters
    command.toUpperCase();  // Normalize to uppercase for case-insensitivity

    Serial.print(command);
    Serial.print(command == "STOP");
    Serial.print("\n");

    uint8_t commandPacket[16] = {0};

    if (command == "WHORU") {
      // Serial.println(BOARD_NAME);
      commandPacket[0] = 0x2;
      commandPacket[1] = 0x0;
      commandPacket[2] = 0x0;

      int i = 3;
      for (char c : BOARD_NAME) {
        commandPacket[i] = (uint8_t) c;
        i++;
      }
      commandPacket[15] = 0x2;
      Serial.write(commandPacket, 16);
    } 

    else if (command == "START")  {
      timerStart();
    } 
    // else if (command == "STOP")  // Stop data acquisition
    // {
    //   timerStop();
    // } 
    else if (command == "STATUS") {
      // Serial.println(timerStatus ? "RUNNING" : "STOPPED");
      commandPacket[0] = 0x2;
      commandPacket[1] = 0x0;
      commandPacket[2] = 0x0;

      int i = 3;
      for (char c : (timerStatus? "RUNNING" : "STOPPED")) {
        commandPacket[i] = (uint8_t) c;
        i++;
      }
      commandPacket[15] = 0x2;
      Serial.write(commandPacket, 16);
    } 
    else {
      commandPacket[0] = 0x2;
      commandPacket[1] = 0x0;
      commandPacket[2] = 0x0;

      int i = 3;
      for (char c : "STOP / ?") {
        commandPacket[i] = (uint8_t) c;
        i++;
      }
      commandPacket[15] = 0x2;
      Serial.write(commandPacket, 16);
      timerStop();
    }
  }
  // Send data if the buffer is ready and the timer is activ
  if (timerStatus and bufferReady) {
    // Send the packetBuffer to the Serial port
    Serial.write(packetBuffer, PACKET_LEN);
    // Reset the bufferReady flag
    bufferReady = false;
  }
  

}