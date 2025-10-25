/**
 * Convert hex color to HSL
 */
function hexToHSL(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return null;

  let r = parseInt(result[1], 16) / 255;
  let g = parseInt(result[2], 16) / 255;
  let b = parseInt(result[3], 16) / 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h,
    s,
    l = (max + min) / 2;

  if (max === min) {
    h = s = 0;
  } else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
        break;
      case g:
        h = ((b - r) / d + 2) / 6;
        break;
      case b:
        h = ((r - g) / d + 4) / 6;
        break;
    }
  }

  return { h: h * 360, s: s * 100, l: l * 100 };
}

/**
 * Convert HSL to hex color
 */
function hslToHex(h, s, l) {
  const rgb = hslToRgb(h, s, l);
  return rgbToHex(rgb.r, rgb.g, rgb.b);
}

function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : { r: 0, g: 0, b: 0 };
}

function rgbToHex(r, g, b) {
  return "#" + [r, g, b].map(x => {
    const hex = Math.round(Math.max(0, Math.min(255, x))).toString(16);
    return hex.length === 1 ? "0" + hex : hex;
  }).join("");
}

function rgbToHsl(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;
  
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h, s, l = (max + min) / 2;

  if (max === min) {
    h = s = 0;
  } else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
      case g: h = ((b - r) / d + 2) / 6; break;
      case b: h = ((r - g) / d + 4) / 6; break;
    }
  }
  
  return { h: h * 360, s: s * 100, l: l * 100 };
}

function hslToRgb(h, s, l) {
  h /= 360;
  s /= 100;
  l /= 100;
  
  let r, g, b;

  if (s === 0) {
    r = g = b = l;
  } else {
    const hue2rgb = (p, q, t) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1/6) return p + (q - p) * 6 * t;
      if (t < 1/2) return q;
      if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
      return p;
    };
    
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    
    r = hue2rgb(p, q, h + 1/3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1/3);
  }
  
  return { r: r * 255, g: g * 255, b: b * 255 };
}

// Calculate relative luminance (WCAG standard)
function getLuminance(hex) {
  const rgb = hexToRgb(hex);
  const [r, g, b] = [rgb.r, rgb.g, rgb.b].map(val => {
    val /= 255;
    return val <= 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// Calculate contrast ratio between two colors
function getContrastRatio(hex1, hex2) {
  const lum1 = getLuminance(hex1);
  const lum2 = getLuminance(hex2);
  const brightest = Math.max(lum1, lum2);
  const darkest = Math.min(lum1, lum2);
  return (brightest + 0.05) / (darkest + 0.05);
}

// Check if a color is considered "light"
function isLightColor(hex) {
  return getLuminance(hex) > 0.5;
}

// Adjust color lightness
function adjustLightness(hex, amount) {
  const hsl = hexToHSL(hex);
  hsl.l = Math.max(0, Math.min(100, hsl.l + amount));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

// Adjust color saturation
function adjustSaturation(hex, amount) {
  const hsl = hexToHSL(hex);
  hsl.s = Math.max(0, Math.min(100, hsl.s + amount));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

// Adjust both lightness and saturation
function adjustLightnessAndSaturation(hex, lightnessAmount, saturationAmount) {
  const hsl = hexToHSL(hex);
  hsl.l = Math.max(0, Math.min(100, hsl.l + lightnessAmount));
  hsl.s = Math.max(0, Math.min(100, hsl.s + saturationAmount));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

// Generate "on" color with proper contrast (for text/icons)
function generateOnColor(baseColor, isDarkMode) {
  const isBaseLight = isLightColor(baseColor);
  
  // If base is light, we need dark text; if base is dark, we need light text
  if (isBaseLight) {
    // Try darker variants
    let testColor = "#000000";
    if (getContrastRatio(baseColor, testColor) >= 4.5) {
      return testColor;
    }
    // Fallback to dark gray
    return "#1c1b1f";
  } else {
    // Try lighter variants
    let testColor = "#ffffff";
    if (getContrastRatio(baseColor, testColor) >= 4.5) {
      return testColor;
    }
    // Fallback to light gray
    return "#e6e1e5";
  }
}

// Generate container color (lighter in light mode, darker in dark mode)
function generateContainerColor(baseColor, isDarkMode) {
  const rgb = hexToRgb(baseColor);
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
  
  if (isDarkMode) {
    // In dark mode, containers are darker and more saturated
    hsl.l = Math.max(10, Math.min(30, hsl.l - 20));
    hsl.s = Math.min(100, hsl.s + 10);
  } else {
    // In light mode, containers are lighter and less saturated
    hsl.l = Math.min(90, Math.max(75, hsl.l + 30));
    hsl.s = Math.max(0, hsl.s - 10);
  }
  
  const newRgb = hslToRgb(hsl.h, hsl.s, hsl.l);
  return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
}

// Generate surface variant colors
function generateSurfaceVariant(backgroundColor, step, isDarkMode) {
  const rgb = hexToRgb(backgroundColor);
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);

  if (isDarkMode) {
    // In dark mode, variants get progressively lighter
    hsl.l = Math.min(100, hsl.l + (step * 3));
  } else {
    // In light mode, variants get progressively darker
    hsl.l = Math.max(0, hsl.l - (step * 2));
  }

  const newRgb = hslToRgb(hsl.h, hsl.s, hsl.l);
  return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
}

// ============================================================================
// MATUGEN FORMAT GENERATORS
// ============================================================================

/**
 * Convert hex to RGB string format: "rgb(255, 87, 51)"
 */
function toRgbString(hex) {
  const rgb = hexToRgb(hex);
  return `rgb(${rgb.r}, ${rgb.g}, ${rgb.b})`;
}

/**
 * Convert hex to RGBA string format: "rgba(255, 87, 51, 1.0)"
 */
function toRgbaString(hex, alpha) {
  if (alpha === undefined || alpha === null) {
    alpha = 1.0;
  }
  const rgb = hexToRgb(hex);
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`;
}

/**
 * Convert hex to HSL string format: "hsl(12, 100%, 60%)"
 */
function toHslString(hex) {
  const hsl = hexToHSL(hex);
  return `hsl(${Math.round(hsl.h)}, ${Math.round(hsl.s)}%, ${Math.round(hsl.l)}%)`;
}

/**
 * Convert hex to HSLA string format: "hsla(12, 100%, 60%, 1.0)"
 */
function toHslaString(hex, alpha) {
  if (alpha === undefined || alpha === null) {
    alpha = 1.0;
  }
  const hsl = hexToHSL(hex);
  return `hsla(${Math.round(hsl.h)}, ${Math.round(hsl.s)}%, ${Math.round(hsl.l)}%, ${alpha})`;
}

// ============================================================================
// COMPONENT EXTRACTORS
// ============================================================================

function getRed(hex) {
  return hexToRgb(hex).r;
}

function getGreen(hex) {
  return hexToRgb(hex).g;
}

function getBlue(hex) {
  return hexToRgb(hex).b;
}

function getHue(hex) {
  return Math.round(hexToHSL(hex).h);
}

function getSaturation(hex) {
  return Math.round(hexToHSL(hex).s);
}

function getLightness(hex) {
  return Math.round(hexToHSL(hex).l);
}

// ============================================================================
// MATUGEN FILTERS
// ============================================================================

/**
 * Set alpha/transparency (returns object with hex and alpha for RGBA conversion)
 */
function setAlpha(hex, alpha) {
  return {
    hex: hex,
    alpha: parseFloat(alpha)
  };
}

/**
 * Set hue (rotate hue by degrees, -180 to 180)
 */
function setHue(hex, degrees) {
  const rgb = hexToRgb(hex);
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
  // Normalize hue to 0-360 range
  hsl.h = (hsl.h + parseFloat(degrees) + 360) % 360;
  const newRgb = hslToRgb(hsl.h, hsl.s, hsl.l);
  return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
}

/**
 * Set lightness (adjust lightness by amount)
 */
function setLightness(hex, amount) {
  return adjustLightness(hex, parseFloat(amount));
}

/**
 * Auto lightness - automatically adjusts between light-to-dark or dark-to-light
 */
function autoLightness(hex, amount, isDarkMode) {
  const isLight = isLightColor(hex);
  // In dark mode: light colors get lighter, dark colors get darker
  // In light mode: opposite
  const direction = isDarkMode ? (isLight ? 1 : -1) : (isLight ? -1 : 1);
  return adjustLightness(hex, parseFloat(amount) * direction);
}

/**
 * Convert color to grayscale (remove all saturation)
 */
function grayscale(hex) {
  return adjustSaturation(hex, -100);
}

/**
 * Invert color (RGB inversion)
 */
function invert(hex) {
  const rgb = hexToRgb(hex);
  return rgbToHex(255 - rgb.r, 255 - rgb.g, 255 - rgb.b);
}

// ============================================================================
// STRING FILTERS
// ============================================================================

/**
 * Convert snake_case to camelCase
 */
function toCamelCase(str) {
  return String(str).replace(/_([a-z])/g, function(_, letter) {
    return letter.toUpperCase();
  });
}
