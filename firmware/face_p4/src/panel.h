// panel.h - what main.cpp needs from a face panel. One panel_*.cpp is compiled in, chosen by the
// build flag in platformio.ini:  PANEL_7IN_DSI  (CrowPanel Advanced 7", bench)
//                                PANEL_5IN_RGB  (CrowPanel Advanced 5", final head)
//
// Version: 1.0.0
// Created: 2026-11-26
// Last modified: 2026-11-26
// History:
//   1.0.0  2026-11-26  First version: panel code split out of main.cpp so the 5" can be added.

#pragma once
#include <stdint.h>

#if defined(PANEL_7IN_DSI)
  #define PANEL_NAME "CrowPanel P4 7in (MIPI-DSI)"
  static const int W = 1024, H = 600;
  static const int PIN_SDA = 45, PIN_SCL = 46, PIN_TP_RST = 40, PIN_TP_INT = 42;
#elif defined(PANEL_5IN_RGB)
  #define PANEL_NAME "CrowPanel P4 5in (RGB)"
  static const int W = 800, H = 480;
  static const int PIN_SDA = 45, PIN_SCL = 46, PIN_TP_RST = 36, PIN_TP_INT = 42;
#else
  #error "Build with -DPANEL_7IN_DSI or -DPANEL_5IN_RGB (pick an env in platformio.ini)"
#endif

void      displayBegin();            // panel, frame buffers, backlight off
uint16_t *drawBuf();                 // the W x H RGB565 buffer to draw the next frame into
void      present();                 // show what was drawn; returns once it is on screen
void      setBacklight(int pct);     // 0..100
int       backlight();
void      setFlip(bool f);           // rotate the picture 180 degrees
bool      flipped();
void      touchToScreen(int &x, int &y);   // touch coordinates -> drawing coordinates
