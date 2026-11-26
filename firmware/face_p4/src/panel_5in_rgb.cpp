// panel_5in_rgb.cpp - CrowPanel Advanced 5" ESP32-P4 (Elecrow DHE04005D, V1.0): 800x480 IPS on a 16-bit
// parallel RGB bus (no command channel: the panel just takes pixels). The backlight is not on a GPIO: an
// STC8H1K helper MCU at I2C 0x2F drives it (register 0x20 = PWM duty 0..100), on the same bus as the touch.
// Settings from Elecrow's V1.0 examples (Arduino Lesson07 board_config.h, IDF bsp_illuminate,
// bsp_stc8h1kxx.h).
//
// Version: 1.0.0
// Created: 2026-11-26
// Last modified: 2026-11-26
// History:
//   1.0.0  2026-11-26  First version: RGB panel with two PSRAM frame buffers, STC8 backlight,
//                      180-degree flip in software.

#if defined(PANEL_5IN_RGB)
#include <Arduino.h>
#include <Wire.h>
#include "panel.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_lcd_panel_ops.h"
#include "esp_cache.h"
#include "esp_heap_caps.h"

// RGB bus (Elecrow board_config.h). Refresh = 18 MHz / (4+8+8+800) / (4+16+16+480) = 42.5 Hz
static const int PIN_HSYNC = 40, PIN_VSYNC = 41, PIN_DE = 2, PIN_PCLK = 3;
static const int PIN_DATA[16] = {8, 7, 6, 5, 4,            // B0..B4
                                 14, 13, 12, 11, 10, 9,    // G0..G5
                                 19, 18, 17, 16, 15};      // R0..R4
static const uint32_t PCLK_HZ = 18 * 1000 * 1000;

// STC8H1K helper MCU
static const uint8_t STC8_ADDR = 0x2F, STC8_REG_PWM = 0x20;   // + channel 0 = LCD backlight

static const size_t FB_BYTES = (size_t)W * H * 2;

static esp_lcd_panel_handle_t panel = nullptr;
static uint16_t *fb[2] = {nullptr, nullptr};
static uint16_t *canvas = nullptr;                     // drawing buffer while flipped (copied reversed)
static int back = 1;
static SemaphoreHandle_t vsync = nullptr;
static int brightness = 80;
static bool isFlipped = false;                         // the panel's own way up is unknown until tried

static void check(esp_err_t e, const char *what) {
  if (e == ESP_OK) return;
  Serial.printf("face: FAILED %s: %s\n", what, esp_err_to_name(e));
  while (true) delay(1000);
}

void setBacklight(int pct) {
  brightness = constrain(pct, 0, 100);
  Wire.beginTransmission(STC8_ADDR);
  Wire.write(STC8_REG_PWM);
  Wire.write((uint8_t)brightness);
  if (Wire.endTransmission() != 0) Serial.println("face: backlight: STC8 (I2C 0x2F) did not answer");
}
int backlight() { return brightness; }

// No panel command does this on an RGB panel, so the picture is drawn into a canvas and copied
// into the frame buffer back to front (a 180-degree turn) by present().
void setFlip(bool f) {
  if (f && !canvas) {
    canvas = (uint16_t *)heap_caps_aligned_alloc(64, FB_BYTES, MALLOC_CAP_SPIRAM);
    if (!canvas) { Serial.println("face: no PSRAM for the flip canvas"); return; }
    memcpy(canvas, fb[back], FB_BYTES);
  }
  isFlipped = f;
}
bool flipped() { return isFlipped; }

void touchToScreen(int &x, int &y) {                    // the touch doesn't turn with the picture
  if (isFlipped) { x = W - 1 - x; y = H - 1 - y; }
}

static bool IRAM_ATTR onVsync(esp_lcd_panel_handle_t, const esp_lcd_rgb_panel_event_data_t *, void *) {
  BaseType_t woken = pdFALSE;
  xSemaphoreGiveFromISR(vsync, &woken);
  return woken == pdTRUE;
}

void displayBegin() {
  Wire.begin(PIN_SDA, PIN_SCL, 400000);                // the STC8 (backlight) and the GT911 share this bus
  setBacklight(0);                                     // dark until there is a picture

  esp_lcd_rgb_panel_config_t pc = {};
  pc.clk_src = LCD_CLK_SRC_DEFAULT;
  pc.data_width = 16;
  pc.num_fbs = 2;
  pc.dma_burst_size = 64;
  pc.hsync_gpio_num = PIN_HSYNC;
  pc.vsync_gpio_num = PIN_VSYNC;
  pc.de_gpio_num = PIN_DE;
  pc.pclk_gpio_num = PIN_PCLK;
  pc.disp_gpio_num = -1;
  for (int i = 0; i < 16; i++) pc.data_gpio_nums[i] = PIN_DATA[i];
  pc.timings.pclk_hz = PCLK_HZ;
  pc.timings.h_res = W;
  pc.timings.v_res = H;
  pc.timings.hsync_pulse_width = 4;
  pc.timings.hsync_back_porch = 8;
  pc.timings.hsync_front_porch = 8;
  pc.timings.vsync_pulse_width = 4;
  pc.timings.vsync_back_porch = 16;
  pc.timings.vsync_front_porch = 16;
  pc.timings.flags.pclk_active_neg = 1;                // data sampled on the falling edge
  pc.timings.flags.pclk_idle_high = 1;
  pc.flags.fb_in_psram = 1;
  check(esp_lcd_new_rgb_panel(&pc, &panel), "RGB panel");

  vsync = xSemaphoreCreateBinary();
  esp_lcd_rgb_panel_event_callbacks_t cbs = {};
  cbs.on_vsync = onVsync;
  check(esp_lcd_rgb_panel_register_event_callbacks(panel, &cbs, nullptr), "vsync callback");

  check(esp_lcd_panel_reset(panel), "panel reset");
  check(esp_lcd_panel_init(panel), "panel init");

  void *a = nullptr, *b = nullptr;
  check(esp_lcd_rgb_panel_get_frame_buffer(panel, 2, &a, &b), "frame buffers");
  fb[0] = (uint16_t *)a; fb[1] = (uint16_t *)b;
  memset(fb[0], 0, FB_BYTES); memset(fb[1], 0, FB_BYTES);
  esp_cache_msync(fb[0], FB_BYTES, ESP_CACHE_MSYNC_FLAG_DIR_C2M | ESP_CACHE_MSYNC_FLAG_UNALIGNED);
  esp_cache_msync(fb[1], FB_BYTES, ESP_CACHE_MSYNC_FLAG_DIR_C2M | ESP_CACHE_MSYNC_FLAG_UNALIGNED);
}

uint16_t *drawBuf() { return isFlipped ? canvas : fb[back]; }

// Show the back buffer: the RGB driver switches to it at the next vsync; then draw into the other one.
void present() {
  uint16_t *buf = fb[back];
  if (isFlipped) {                                     // copy the canvas back to front, two pixels at a time
    const uint32_t *s = (const uint32_t *)canvas;
    uint32_t *d = (uint32_t *)buf;
    const size_t n = FB_BYTES / 4;
    for (size_t i = 0; i < n; i++) { uint32_t v = s[n - 1 - i]; d[i] = (v >> 16) | (v << 16); }
  }
  esp_cache_msync(buf, FB_BYTES, ESP_CACHE_MSYNC_FLAG_DIR_C2M | ESP_CACHE_MSYNC_FLAG_UNALIGNED);
  xSemaphoreTake(vsync, 0);                            // drop a stale vsync
  esp_lcd_panel_draw_bitmap(panel, 0, 0, W, H, buf);   // one of its own frame buffers: a switch, no copy
  xSemaphoreTake(vsync, pdMS_TO_TICKS(100));           // the switch happens at this vsync
  back ^= 1;
}
#endif
