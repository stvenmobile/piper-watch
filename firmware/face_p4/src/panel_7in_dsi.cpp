// panel_7in_dsi.cpp - CrowPanel Advanced 7" ESP32-P4 (Elecrow DHE04107D V1.0): EK79007 1024x600 IPS
// over 2-lane MIPI-DSI, backlight PWM on GPIO31. Settings from Elecrow's V1.0 Arduino example
// (board_config.h, esp_lcd_ek79007.c).
//
// Version: 1.0.0
// Created: 2026-11-26 (code from main.cpp, first written 2026-11-23)
// Last modified: 2026-11-26
// History:
//   1.0.0  2026-11-26  Moved out of main.cpp unchanged, behind the panel.h interface.

#if defined(PANEL_7IN_DSI)
#include <Arduino.h>
#include "panel.h"
#include "esp_lcd_mipi_dsi.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_io.h"
#include "esp_ldo_regulator.h"
#include "sdkconfig.h"

static const int PIN_BL = 31, PIN_LCD_RST = 41;

static esp_lcd_panel_handle_t panel = nullptr;
static esp_lcd_panel_io_handle_t panelIo = nullptr;
static uint16_t *fb[2] = {nullptr, nullptr};
static int back = 1;                                   // the buffer we draw into (the other is on screen)
static SemaphoreHandle_t fbFree = nullptr;             // given when the panel has switched buffers
static int brightness = 80;
static bool isFlipped = false;                         // upright with the USB connectors on the LEFT (as before)

static void check(esp_err_t e, const char *what) {
  if (e == ESP_OK) return;
  Serial.printf("face: FAILED %s: %s\n", what, esp_err_to_name(e));
  while (true) delay(1000);                          // stop here so the message stays readable
}

// EK79007 MADCTL (36h): bit 0 = scan left/right (SHLR), bit 1 = scan up/down (UPDN); Elecrow's default is 0x01.
// Flipping both turns the picture 180 degrees, in the panel itself (costs nothing per frame).
void setFlip(bool f) {
  isFlipped = f;
  uint8_t madctl = f ? 0x02 : 0x01;
  esp_lcd_panel_io_tx_param(panelIo, 0x36, &madctl, 1);
}
bool flipped() { return isFlipped; }
void touchToScreen(int &, int &) {}                    // unchanged from the bring-up firmware

static bool IRAM_ATTR onFrameDone(esp_lcd_panel_handle_t, esp_lcd_dpi_panel_event_data_t *, void *) {
  BaseType_t woken = pdFALSE;
  xSemaphoreGiveFromISR(fbFree, &woken);
  return woken == pdTRUE;
}

void setBacklight(int pct) {
  brightness = constrain(pct, 0, 100);
  ledcWrite(PIN_BL, (1023 * brightness) / 100);      // 10-bit PWM, active high
}
int backlight() { return brightness; }

void displayBegin() {
  // MIPI D-PHY power (LDO3, 2.5 V) and the touch / I2C pull-ups (LDO4, 3.3 V)
  static esp_ldo_channel_handle_t ldo3 = nullptr, ldo4 = nullptr;
  esp_ldo_channel_config_t c3 = {}; c3.chan_id = 3; c3.voltage_mv = 2500;
  esp_ldo_channel_config_t c4 = {}; c4.chan_id = 4; c4.voltage_mv = 3300;
  check(esp_ldo_acquire_channel(&c3, &ldo3), "LDO3 (DSI PHY power)");
  check(esp_ldo_acquire_channel(&c4, &ldo4), "LDO4 (touch power)");

  ledcAttach(PIN_BL, 30000, 10);
  setBacklight(0);                                   // dark until there is a picture

  pinMode(PIN_LCD_RST, OUTPUT);                      // hardware reset: low 10 ms, high, wait
  digitalWrite(PIN_LCD_RST, LOW);  delay(10);
  digitalWrite(PIN_LCD_RST, HIGH); delay(20);

  esp_lcd_dsi_bus_handle_t bus = nullptr;
  esp_lcd_dsi_bus_config_t bc = {};
  bc.bus_id = 0;
  bc.num_data_lanes = 2;
#if CONFIG_ESP32P4_SELECTS_REV_LESS_V3
  bc.phy_clk_src = MIPI_DSI_PHY_PLLREF_CLK_SRC_DEFAULT_LEGACY;   // chip rev < 3 (Elecrow V1.0)
#else
  bc.phy_clk_src = MIPI_DSI_PHY_PLLREF_CLK_SRC_DEFAULT;
#endif
  bc.lane_bit_rate_mbps = 1000;
  check(esp_lcd_new_dsi_bus(&bc, &bus), "DSI bus");

  esp_lcd_panel_io_handle_t io = nullptr;           // the command channel (DBI over DSI)
  esp_lcd_dbi_io_config_t ic = {};
  ic.virtual_channel = 0; ic.lcd_cmd_bits = 8; ic.lcd_param_bits = 8;
  check(esp_lcd_new_panel_io_dbi(bus, &ic, &io), "DBI panel IO");
  panelIo = io;

  // EK79007 init (Elecrow's sequence): 2-lane mode, vendor registers, sleep out
  struct Cmd { uint8_t cmd, val; bool hasVal; uint16_t waitMs; };
  static const Cmd init[] = {
    {0xB2, 0x10, true, 0},                           // pad control: 2 data lanes
    {0x80, 0x8B, true, 0}, {0x81, 0x78, true, 0}, {0x82, 0x84, true, 0}, {0x83, 0x88, true, 0},
    {0x84, 0xA8, true, 0}, {0x85, 0xE3, true, 0}, {0x86, 0x88, true, 0},
    {0x11, 0, false, 120},                           // sleep out
  };
  for (const Cmd &c : init) {
    check(esp_lcd_panel_io_tx_param(io, c.cmd, c.hasVal ? &c.val : nullptr, c.hasVal ? 1 : 0), "EK79007 init");
    if (c.waitMs) delay(c.waitMs);
  }

  esp_lcd_dpi_panel_config_t pc = {};
  pc.virtual_channel = 0;
  pc.dpi_clk_src = MIPI_DSI_DPI_CLK_SRC_DEFAULT;
  pc.dpi_clock_freq_mhz = 51;
  pc.pixel_format = LCD_COLOR_PIXEL_FORMAT_RGB565;
  pc.num_fbs = 2;
  pc.video_timing.h_size = W;
  pc.video_timing.v_size = H;
  pc.video_timing.hsync_pulse_width = 70;
  pc.video_timing.hsync_back_porch = 160;
  pc.video_timing.hsync_front_porch = 160;
  pc.video_timing.vsync_pulse_width = 10;
  pc.video_timing.vsync_back_porch = 23;
  pc.video_timing.vsync_front_porch = 21;
  check(esp_lcd_new_panel_dpi(bus, &pc, &panel), "DPI panel");
  check(esp_lcd_panel_init(panel), "panel init");
  check(esp_lcd_panel_io_tx_param(io, 0x29, nullptr, 0), "display on");
  setFlip(isFlipped);

  void *a = nullptr, *b = nullptr;
  check(esp_lcd_dpi_panel_get_frame_buffer(panel, 2, &a, &b), "frame buffers");
  fb[0] = (uint16_t *)a; fb[1] = (uint16_t *)b;

  fbFree = xSemaphoreCreateBinary();
  esp_lcd_dpi_panel_event_callbacks_t cbs = {};
  // on_refresh_done: the name every IDF 5.x has (newer ones call it on_frame_buf_complete, same slot)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  cbs.on_refresh_done = onFrameDone;
#pragma GCC diagnostic pop
  check(esp_lcd_dpi_panel_register_event_callbacks(panel, &cbs, nullptr), "frame callback");
}

uint16_t *drawBuf() { return fb[back]; }

// Show the back buffer: the panel switches to it at the next frame, then we draw into the other one.
void present() {
  xSemaphoreTake(fbFree, 0);                         // drop a stale "done"
  esp_lcd_panel_draw_bitmap(panel, 0, 0, W, H, fb[back]);
  xSemaphoreTake(fbFree, pdMS_TO_TICKS(100));        // wait until it is on screen
  back ^= 1;
}
#endif
