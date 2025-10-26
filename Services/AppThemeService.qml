pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import "../Helpers/ColorsConvert.js" as ColorsConvert

Singleton {
  id: root

  readonly property string colorsApplyScript: Quickshell.shellDir + '/Bin/colors-apply.sh'
  readonly property string dynamicConfigPath: Settings.cacheDir + "matugen.dynamic.toml"
  readonly property var terminalPaths: ({
                                          "foot": "~/.config/foot/themes/noctalia",
                                          "ghostty": "~/.config/ghostty/themes/noctalia",
                                          "kitty": "~/.config/kitty/themes/noctalia.conf"
                                        })

  readonly property var schemeNameMap: ({
                                          "Noctalia (default)": "Noctalia-default",
                                          "Noctalia (legacy)": "Noctalia-legacy",
                                          "Tokyo Night": "Tokyo-Night"
                                        })
  readonly property var predefinedTemplateConfigs: ({
                                                      "gtk": {
                                                        "input": "gtk.css",
                                                        "outputs": [{
                                                            "path": "~/.config/gtk-3.0/gtk.css"
                                                          }, {
                                                            "path": "~/.config/gtk-4.0/gtk.css"
                                                          }],
                                                        "postProcess": mode => `gsettings set org.gnome.desktop.interface color-scheme prefer-${mode}\n`
                                                      },
                                                      "qt": {
                                                        "input": "qtct.conf",
                                                        "outputs": [{
                                                            "path": "~/.config/qt5ct/colors/noctalia.conf"
                                                          }, {
                                                            "path": "~/.config/qt6ct/colors/noctalia.conf"
                                                          }]
                                                      },
                                                      "kcolorscheme": {
                                                        "input": "kcolorscheme.colors",
                                                        "outputs": [{
                                                            "path": "~/.local/share/color-schemes/noctalia.colors"
                                                          }]
                                                      },
                                                      "fuzzel": {
                                                        "input": "fuzzel.conf",
                                                        "outputs": [{
                                                            "path": "~/.config/fuzzel/themes/noctalia"
                                                          }],
                                                        "postProcess": () => `${colorsApplyScript} fuzzel\n`
                                                      },
                                                      "pywalfox": {
                                                        "input": "pywalfox.json",
                                                        "outputs": [{
                                                            "path": "~/.cache/wal/colors.json"
                                                          }],
                                                        "postProcess": () => `${colorsApplyScript} pywalfox\n`
                                                      },
                                                      "discord_vesktop": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/vesktop/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "discord_webcord": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/webcord/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "discord_armcord": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/armcord/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "discord_equibop": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/equibop/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "discord_lightcord": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/lightcord/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "discord_dorion": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/dorion/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "discord_vencord": {
                                                        "input": "vesktop.css",
                                                        "outputs": [{
                                                            "path": "~/.config/discord/themes/noctalia.theme.css"
                                                          }]
                                                      },
                                                      "vicinae": {
                                                        "input": "vicinae.toml",
                                                        "outputs": [{
                                                            "path": "~/.local/share/vicinae/themes/matugen.toml"
                                                          }],
                                                        "postProcess": () => `cp -n ${Quickshell.shellDir}/Assets/noctalia.svg ~/.local/share/vicinae/themes/noctalia.svg && ${colorsApplyScript} vicinae\n`
                                                      }
                                                    })

  // ============================================================================
  // SEMANTIC PALETTE MAPPINGS
  // Full palettes for themes with semantic/named colors
  // ============================================================================
  readonly property var semanticPaletteMaps: ({
                                                "rosepine": {
                                                  "palette": {
                                                    "base": "#191724",
                                                    "surface": "#1f1d2e",
                                                    "overlay": "#26233a",
                                                    "muted": "#6e6a86",
                                                    "subtle": "#908caa",
                                                    "text": "#e0def4",
                                                    "love": "#eb6f92",
                                                    "gold": "#f6c177",
                                                    "rose": "#ebbcba",
                                                    "pine": "#31748f",
                                                    "foam": "#9ccfd8",
                                                    "iris": "#c4a7e7",
                                                    "highlight_low": "#21202e",
                                                    "highlight_med": "#403d52",
                                                    "highlight_high": "#524f67"
                                                  }
                                                },
                                                "catppuccin": {
                                                  "palette": {
                                                    "rosewater": "#f5e0dc",
                                                    "flamingo": "#f2cdcd",
                                                    "pink": "#f5bde6",
                                                    "mauve": "#cba6f7",
                                                    "red": "#f38ba8",
                                                    "maroon": "#eba0ac",
                                                    "peach": "#fab387",
                                                    "yellow": "#f9e2af",
                                                    "green": "#a6e3a1",
                                                    "teal": "#94e2d5",
                                                    "sky": "#89dceb",
                                                    "sapphire": "#74c7ec",
                                                    "blue": "#89b4fa",
                                                    "lavender": "#b4befe",
                                                    "text": "#cdd6f4",
                                                    "base": "#1e1e2e"
                                                  }
                                                },
                                                "nord": {
                                                  "palette": {
                                                    "nord0": "#2e3440",
                                                    "nord1": "#3b4252",
                                                    "nord2": "#434c5e",
                                                    "nord3": "#4c566a",
                                                    "nord4": "#d8dee9",
                                                    "nord5": "#e5e9f0",
                                                    "nord6": "#eceff4",
                                                    "nord7": "#8fbcbb",
                                                    "nord8": "#88c0d0",
                                                    "nord9": "#81a1c1",
                                                    "nord10": "#5e81ac",
                                                    "nord11": "#bf616a",
                                                    "nord12": "#d08770",
                                                    "nord13": "#ebcb8b",
                                                    "nord14": "#a3be8c",
                                                    "nord15": "#b48ead"
                                                  }
                                                }
                                              })

  // Get semantic palette for a theme (if available)
  function getSemanticPalette(schemeName) {
    const normalizedName = String(schemeName).toLowerCase().replace(/[\s\-()]/g, "")
    return semanticPaletteMaps[normalizedName] || null
  }

  Connections {
    target: WallpaperService
    function onWallpaperChanged(screenName, path) {
      // Only regenerate for the primary screen to avoid multiple regenerations
      if (Quickshell.screens.length > 0 && screenName === Quickshell.screens[0].name && Settings.data.colorSchemes.useWallpaperColors) {
        generateFromWallpaper(screenName)
      }
    }
  }

  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      Logger.i("AppThemeService", "Detected dark mode change")
      AppThemeService.generate()
    }
  }

  // --------------------------------------------------------------------------------
  function init() {
    Logger.i("AppThemeService", "Service started")
  }

  // --------------------------------------------------------------------------------
  function generate() {
    if (Settings.data.colorSchemes.useWallpaperColors) {
      // Use primary screen when called without a specific screen
      const screenName = Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
      generateFromWallpaper(screenName)
    } else {
      // Re-apply the scheme, this is the best way to regenerate all templates too.
      ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme)
    }
  }

  // --------------------------------------------------------------------------------
  // Wallpaper Colors Generation
  // --------------------------------------------------------------------------------
  function generateFromWallpaper(screenName) {
    if (!screenName) {
      Logger.error("AppThemeService", "No screen name provided for wallpaper generation")
      return
    }

    if (Settings.data.general.debugMode) {
      Logger.d("AppThemeService", "Generating from wallpaper on screen:", screenName)
    }

    const wp = WallpaperService.getWallpaper(screenName).replace(/'/g, "'\\''")

    if (!wp) {
      Logger.e("AppThemeService", "No wallpaper found")
      return
    }

    const content = MatugenTemplates.buildConfigToml()
    if (!content)
      return

    const mode = Settings.data.colorSchemes.darkMode ? "dark" : "light"
    const script = buildMatugenScript(content, wp, mode)

    generateProcess.command = ["bash", "-lc", script]
    generateProcess.running = true
  }

  function buildMatugenScript(content, wallpaper, mode) {
    const delimiter = "MATUGEN_CONFIG_EOF_" + Math.random().toString(36).substr(2, 9)
    const pathEsc = dynamicConfigPath.replace(/'/g, "'\\''")

    let script = `cat > '${pathEsc}' << '${delimiter}'\n${content}\n${delimiter}\n`
    script += `matugen image '${wallpaper}' --config '${pathEsc}' --mode ${mode} --type ${Settings.data.colorSchemes.matugenSchemeType}`
    script += buildUserTemplateCommand(wallpaper, mode)

    return script + "\n"
  }

  // --------------------------------------------------------------------------------
  // Predefined Scheme Generation
  //  For predefined color schemes, we bypass matugen's generation which do not gives good results.
  //  Instead, we use 'sed' to apply a custom palette to the existing matugen templates.
  // --------------------------------------------------------------------------------
  function generateFromPredefinedScheme(schemeData) {
    if (Settings.data.general.debugMode) {
      Logger.d("AppThemeService", "Generating templates from predefined color scheme")
    }

    // Early return if no scheme data provided
    if (!schemeData) {
      Logger.warn("AppThemeService", "No scheme data provided, skipping template generation")
      return
    }

    handleTerminalThemes()

    const isDarkMode = Settings.data.colorSchemes.darkMode
    const mode = isDarkMode ? "dark" : "light"

    // Check if scheme data has dark/light modes
    if (!schemeData[mode]) {
      Logger.warn("AppThemeService", `No ${mode} mode found in scheme data, skipping template generation`)
      return
    }

    const colors = schemeData[mode]

    const matugenColors = generatePalette(colors.mPrimary, colors.mSecondary, colors.mTertiary, colors.mError, colors.mSurface, isDarkMode)

    // Add semantic palette colors if available
    const schemeName = Settings.data.colorSchemes.predefinedScheme
    const semanticPalette = getSemanticPalette(schemeName)

    if (semanticPalette && semanticPalette.palette) {
      // Create custom namespace with all original palette colors
      matugenColors.custom = {}

      Object.keys(semanticPalette.palette).forEach(colorName => {
        const colorHex = semanticPalette.palette[colorName]
        // Use the same createColorObject function to generate all 11 formats
        const hsl = hexToHSL(colorHex)
        const rgb = ColorsConvert.hexToRgb(colorHex)

        matugenColors.custom[colorName] = {
          "default": {
            "hex": colorHex,
            "hex_stripped": colorHex.replace(/^#/, ""),
            "rgb": ColorsConvert.toRgbString(colorHex),
            "rgba": ColorsConvert.toRgbaString(colorHex, 1.0),
            "red": String(rgb.r),
            "green": String(rgb.g),
            "blue": String(rgb.b),
            "alpha": "1.0",
            "hsl": ColorsConvert.toHslString(colorHex),
            "hsla": ColorsConvert.toHslaString(colorHex, 1.0),
            "hue": String(Math.round(hsl.h)),
            "saturation": String(Math.round(hsl.s)),
            "lightness": String(Math.round(hsl.l))
          }
        }
      })

      if (Settings.data.general.debugMode) {
        Logger.d("AppThemeService", `Added semantic palette: ${schemeName} with ${Object.keys(matugenColors.custom).length} colors`)
      }
    }

    const script = processAllTemplates(matugenColors, mode)

    if (Settings.data.general.debugMode) {
      Logger.d("AppThemeService", "Generated script length:", script.length, "chars")
    }

    if (script.trim().length > 0) {
      generateProcess.command = ["bash", "-lc", script]
      generateProcess.running = true
    } else {
      Logger.warn("AppThemeService", "No templates to process (empty script)")
    }
  }

  // Helper function to convert hex to HSL
  function hexToHSL(hex) {
    // Remove # if present
    hex = hex.replace("#", "")

    // Convert hex to RGB
    const r = parseInt(hex.substring(0, 2), 16) / 255
    const g = parseInt(hex.substring(2, 4), 16) / 255
    const b = parseInt(hex.substring(4, 6), 16) / 255

    const max = Math.max(r, g, b)
    const min = Math.min(r, g, b)
    let h, s, l = (max + min) / 2

    if (max === min) {
      h = s = 0 // achromatic
    } else {
      const d = max - min
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min)

      switch (max) {
        case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break
        case g: h = ((b - r) / d + 2) / 6; break
        case b: h = ((r - g) / d + 4) / 6; break
      }
    }

    return {
      h: Math.round(h * 360),
      s: Math.round(s * 100),
      l: Math.round(l * 100)
    }
  }

  function generatePalette(primaryColor, secondaryColor, tertiaryColor, errorColor, backgroundColor, outlineColor, isDarkMode) {
    // Create comprehensive color object with all 11 matugen formats
    const createColorObject = (hex, alpha) => {
      if (alpha === undefined || alpha === null) {
        alpha = 1.0
      }
      const hsl = hexToHSL(hex)
      const rgb = ColorsConvert.hexToRgb(hex)

      return {
        "default": {
          // Hex formats
          "hex": hex,
          "hex_stripped": hex.replace(/^#/, ""),

          // RGB formats
          "rgb": ColorsConvert.toRgbString(hex),
          "rgba": ColorsConvert.toRgbaString(hex, alpha),
          "red": String(rgb.r),
          "green": String(rgb.g),
          "blue": String(rgb.b),
          "alpha": String(alpha),

          // HSL formats
          "hsl": ColorsConvert.toHslString(hex),
          "hsla": ColorsConvert.toHslaString(hex, alpha),
          "hue": String(Math.round(hsl.h)),
          "saturation": String(Math.round(hsl.s)),
          "lightness": String(Math.round(hsl.l))
        }
      }
    }

    // Convenience alias for backward compatibility
    const c = createColorObject

    // Generate container colors
    const primaryContainer = ColorsConvert.generateContainerColor(primaryColor, isDarkMode)
    const secondaryContainer = ColorsConvert.generateContainerColor(secondaryColor, isDarkMode)
    const tertiaryContainer = ColorsConvert.generateContainerColor(tertiaryColor, isDarkMode)

    // Generate "on" colors (for text/icons)
    const onPrimary = ColorsConvert.generateOnColor(primaryColor, isDarkMode)
    const onSecondary = ColorsConvert.generateOnColor(secondaryColor, isDarkMode)
    const onTertiary = ColorsConvert.generateOnColor(tertiaryColor, isDarkMode)
    const onBackground = ColorsConvert.generateOnColor(backgroundColor, isDarkMode)

    const onPrimaryContainer = ColorsConvert.generateOnColor(primaryContainer, isDarkMode)
    const onSecondaryContainer = ColorsConvert.generateOnColor(secondaryContainer, isDarkMode)
    const onTertiaryContainer = ColorsConvert.generateOnColor(tertiaryContainer, isDarkMode)

    // Generate error colors (standard red-based)
    const errorContainer = ColorsConvert.generateContainerColor(errorColor, isDarkMode)
    const onError = ColorsConvert.generateOnColor(errorColor, isDarkMode)
    const onErrorContainer = ColorsConvert.generateOnColor(errorContainer, isDarkMode)

    // Surface is same as background in Material Design 3
    const surface = backgroundColor
    const onSurface = onBackground

    // Generate surface variant (slightly different tone)
    const surfaceVariant = ColorsConvert.adjustLightness(backgroundColor, isDarkMode ? 5 : -3)
    const onSurfaceVariant = ColorsConvert.generateOnColor(surfaceVariant, isDarkMode)

    // Generate surface containers (progressive elevation)
    const surfaceContainerLowest = ColorsConvert.generateSurfaceVariant(backgroundColor, 0, isDarkMode)
    const surfaceContainerLow = ColorsConvert.generateSurfaceVariant(backgroundColor, 1, isDarkMode)
    const surfaceContainer = ColorsConvert.generateSurfaceVariant(backgroundColor, 2, isDarkMode)
    const surfaceContainerHigh = ColorsConvert.generateSurfaceVariant(backgroundColor, 3, isDarkMode)
    const surfaceContainerHighest = ColorsConvert.generateSurfaceVariant(backgroundColor, 4, isDarkMode)

    // Generate outline colors (for borders/dividers)
    const outline = isDarkMode ? "#938f99" : "#79747e"
    const outlineVariant = ColorsConvert.adjustLightness(outline, isDarkMode ? -10 : 10)

    // Shadow is always very dark
    const shadow = "#000000"

    // Generate "fixed" colors for Material Design 3
    // These remain consistent across light/dark themes
    const primaryFixed = isDarkMode ? ColorsConvert.adjustLightness(primaryColor, 30) : ColorsConvert.adjustLightness(primaryColor, -10)
    const primaryFixedDim = ColorsConvert.adjustLightness(primaryFixed, isDarkMode ? -10 : -5)
    const onPrimaryFixed = ColorsConvert.generateOnColor(primaryFixed, !isDarkMode)
    const onPrimaryFixedVariant = ColorsConvert.adjustLightness(onPrimaryFixed, isDarkMode ? 10 : -10)

    const secondaryFixed = isDarkMode ? ColorsConvert.adjustLightness(secondaryColor, 30) : ColorsConvert.adjustLightness(secondaryColor, -10)
    const secondaryFixedDim = ColorsConvert.adjustLightness(secondaryFixed, isDarkMode ? -10 : -5)
    const onSecondaryFixed = ColorsConvert.generateOnColor(secondaryFixed, !isDarkMode)
    const onSecondaryFixedVariant = ColorsConvert.adjustLightness(onSecondaryFixed, isDarkMode ? 10 : -10)

    const tertiaryFixed = isDarkMode ? ColorsConvert.adjustLightness(tertiaryColor, 30) : ColorsConvert.adjustLightness(tertiaryColor, -10)
    const tertiaryFixedDim = ColorsConvert.adjustLightness(tertiaryFixed, isDarkMode ? -10 : -5)
    const onTertiaryFixed = ColorsConvert.generateOnColor(tertiaryFixed, !isDarkMode)
    const onTertiaryFixedVariant = ColorsConvert.adjustLightness(onTertiaryFixed, isDarkMode ? 10 : -10)

    // Generate additional surface variants
    const surfaceDim = ColorsConvert.adjustLightness(surface, isDarkMode ? -8 : -5)
    const surfaceBright = ColorsConvert.adjustLightness(surface, isDarkMode ? 8 : 5)

    // Generate inverse colors for high contrast scenarios
    const inverseSurface = ColorsConvert.generateOnColor(surface, !isDarkMode)
    const inverseOnSurface = surface
    const inversePrimary = isDarkMode ? ColorsConvert.adjustLightness(primaryColor, -30) : ColorsConvert.adjustLightness(primaryColor, 30)

    // Additional utility colors
    const scrim = "#000000"
    const surfaceTint = primaryColor

    return {
      "primary": c(primaryColor),
      "on_primary": c(onPrimary),
      "primary_container": c(primaryContainer),
      "on_primary_container": c(onPrimaryContainer),
      "primary_fixed": c(primaryFixed),
      "primary_fixed_dim": c(primaryFixedDim),
      "on_primary_fixed": c(onPrimaryFixed),
      "on_primary_fixed_variant": c(onPrimaryFixedVariant),
      "secondary": c(secondaryColor),
      "on_secondary": c(onSecondary),
      "secondary_container": c(secondaryContainer),
      "on_secondary_container": c(onSecondaryContainer),
      "secondary_fixed": c(secondaryFixed),
      "secondary_fixed_dim": c(secondaryFixedDim),
      "on_secondary_fixed": c(onSecondaryFixed),
      "on_secondary_fixed_variant": c(onSecondaryFixedVariant),
      "tertiary": c(tertiaryColor),
      "on_tertiary": c(onTertiary),
      "tertiary_container": c(tertiaryContainer),
      "on_tertiary_container": c(onTertiaryContainer),
      "tertiary_fixed": c(tertiaryFixed),
      "tertiary_fixed_dim": c(tertiaryFixedDim),
      "on_tertiary_fixed": c(onTertiaryFixed),
      "on_tertiary_fixed_variant": c(onTertiaryFixedVariant),
      "error": c(errorColor),
      "on_error": c(onError),
      "error_container": c(errorContainer),
      "on_error_container": c(onErrorContainer),
      "background": c(backgroundColor),
      "on_background": c(onBackground),
      "surface": c(surface),
      "on_surface": c(onSurface),
      "surface_dim": c(surfaceDim),
      "surface_bright": c(surfaceBright),
      "surface_variant": c(surfaceVariant),
      "on_surface_variant": c(onSurfaceVariant),
      "surface_container_lowest": c(surfaceContainerLowest),
      "surface_container_low": c(surfaceContainerLow),
      "surface_container": c(surfaceContainer),
      "surface_container_high": c(surfaceContainerHigh),
      "surface_container_highest": c(surfaceContainerHighest),
      "surface_tint": c(surfaceTint),
      "inverse_surface": c(inverseSurface),
      "inverse_on_surface": c(inverseOnSurface),
      "inverse_primary": c(inversePrimary),
      "outline": c(outline),
      "outline_variant": c(outlineVariant),
      "shadow": c(shadow),
      "scrim": c(scrim)
    }
  }
  function processAllTemplates(colors, mode) {
    let script = ""
    const homeDir = Quickshell.env("HOME")

    // Process built-in templates
    Object.keys(predefinedTemplateConfigs).forEach(appName => {
                                                     if (Settings.data.templates[appName]) {
                                                       script += processTemplate(appName, colors, mode, homeDir)
                                                     }
                                                   })

    // Process user templates from ~/.config/matugen/config.toml
    script += processUserTemplates(colors, mode)

    return script
  }

  function processTemplate(appName, colors, mode, homeDir) {
    const config = predefinedTemplateConfigs[appName]
    const templatePath = `${Quickshell.shellDir}/Assets/MatugenTemplates/${config.input}`
    let script = ""

    config.outputs.forEach(output => {
                             const outputPath = output.path.replace("~", homeDir)
                             const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'))

                             // For Discord clients, check if the base config directory exists
                             if (appName.startsWith("discord_")) {
                               const baseConfigDir = outputDir.replace("/themes", "")
                               script += `if [ -d "${baseConfigDir}" ]; then\n`
                               script += `  mkdir -p ${outputDir}\n`
                               script += `  cp '${templatePath}' '${outputPath}'\n`
                               script += `  ${replaceColorsInFile(outputPath, colors)}\n`
                               script += `else\n`
                               script += `  echo "Discord client ${appName} not found at ${baseConfigDir}, skipping theme generation"\n`
                               script += `fi\n`
                             } else {
                               script += `mkdir -p ${outputDir}\n`
                               script += `cp '${templatePath}' '${outputPath}'\n`
                               script += replaceColorsInFile(outputPath, colors)
                             }
                           })

    if (config.postProcess) {
      script += config.postProcess(mode)
    }

    return script
  }

  function replaceColorsInFile(filePath, colors) {
    // Replace color placeholders with all 11 matugen formats
    let script = ""

    // Helper to escape strings for sed regex
    const escapeForSed = (str) => String(str).replace(/[.*+?^${}()|[\]\\\/]/g, '\\$&')

    // Process standard MD3 colors (primary, secondary, tertiary, etc.)
    Object.keys(colors).forEach(colorKey => {
      // Skip custom namespace - it's processed separately
      if (colorKey === "custom") return

      const colorData = colors[colorKey].default

      // All 11 matugen formats
      const formats = [
        "hex", "hex_stripped", "rgb", "rgba", "hsl", "hsla",
        "red", "green", "blue", "alpha",
        "hue", "saturation", "lightness"
      ]

      formats.forEach(format => {
        if (colorData[format] !== undefined) {
          const value = escapeForSed(colorData[format])
          script += `sed -i 's/{{colors\\.${colorKey}\\.default\\.${format}}}/${value}/g' '${filePath}'\n`
        }
      })
    })

    // Process custom semantic colors (e.g., {{colors.custom.pine.default.hex}})
    if (colors.custom) {
      Object.keys(colors.custom).forEach(colorName => {
        const colorData = colors.custom[colorName].default

        const formats = [
          "hex", "hex_stripped", "rgb", "rgba", "hsl", "hsla",
          "red", "green", "blue", "alpha",
          "hue", "saturation", "lightness"
        ]

        formats.forEach(format => {
          if (colorData[format] !== undefined) {
            const value = escapeForSed(colorData[format])
            script += `sed -i 's/{{colors\\.custom\\.${colorName}\\.default\\.${format}}}/${value}/g' '${filePath}'\n`
          }
        })
      })
    }

    return script
  }

  // --------------------------------------------------------------------------------
  // User Templates - Process custom matugen templates from ~/.config/matugen/config.toml
  // --------------------------------------------------------------------------------
  function processUserTemplates(colors, mode) {
    if (!Settings.data.templates.enableUserTemplates) {
      return ""
    }

    if (Settings.data.general.debugMode) {
      Logger.d("AppThemeService", "Processing user templates from", getUserConfigPath())
    }

    const userConfigPath = getUserConfigPath()
    const matugenConfigDir = Quickshell.env("HOME") + "/.config/matugen"
    const homeDir = Quickshell.env("HOME")

    // Generate sed commands for color replacements (hex, hex_stripped, hue, saturation, lightness)
    // Note: We need {{{{ to produce {{ in Python f-string output
    let sedCommands = []
    Object.keys(colors).forEach(colorKey => {
                                  const colorData = colors[colorKey].default
                                  const escapedHex = colorData.hex.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
                                  const escapedHexStripped = colorData.hex_stripped.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
                                  const hue = colorData.hue
                                  const saturation = colorData.saturation
                                  const lightness = colorData.lightness

                                  sedCommands.push(`s/{{{{colors\\\\.${colorKey}\\\\.default\\\\.hex}}}}/${escapedHex}/g`)
                                  sedCommands.push(`s/{{{{colors\\\\.${colorKey}\\\\.default\\\\.hex_stripped}}}}/${escapedHexStripped}/g`)
                                  sedCommands.push(`s/{{{{colors\\\\.${colorKey}\\\\.default\\\\.hue}}}}/${hue}/g`)
                                  sedCommands.push(`s/{{{{colors\\\\.${colorKey}\\\\.default\\\\.saturation}}}}/${saturation}/g`)
                                  sedCommands.push(`s/{{{{colors\\\\.${colorKey}\\\\.default\\\\.lightness}}}}/${lightness}/g`)
                                })
    const sedCommandsStr = sedCommands.join(';')

    // Use Python to parse TOML and generate processing commands
    return `
# Process user templates from ${userConfigPath}
if [ -f '${userConfigPath}' ]; then
  python3 << 'PYTHON_EOF' | bash
import re
import os
import sys

config_path = '${userConfigPath}'
home = '${homeDir}'
config_dir = '${matugenConfigDir}'

try:
    with open(config_path, 'r') as f:
        content = f.read()

    # Simple TOML parsing for [templates.name] blocks
    template_pattern = re.compile(r'\\[templates\\.([^\\]]+)\\]([^\\[]*)', re.MULTILINE)

    for match in template_pattern.finditer(content):
        name = match.group(1)
        block = match.group(2)

        # Extract paths and hook (matches both single and double quotes)
        input_match = re.search(r'''input_path\\s*=\\s*["']([^"']+)["']''', block)
        output_match = re.search(r'''output_path\\s*=\\s*["']([^"']+)["']''', block)
        hook_match = re.search(r'''post_hook\\s*=\\s*["']([^"']+)["']''', block)

        if not input_match or not output_match:
            continue

        input_path = input_match.group(1)
        output_path = output_match.group(1)
        post_hook = hook_match.group(1) if hook_match else None

        # Expand ~ in paths
        input_path = input_path.replace('~', home)
        output_path = output_path.replace('~', home)

        # Resolve relative input paths relative to config dir
        if not input_path.startswith('/'):
            input_path = os.path.join(config_dir, input_path)

        # Check if template exists
        if not os.path.exists(input_path):
            print(f"# Warning: User template '{input_path}' not found, skipping", file=sys.stderr)
            continue

        # Output bash commands
        output_dir = os.path.dirname(output_path)
        print(f"mkdir -p '{output_dir}'")
        print(f"cp '{input_path}' '{output_path}'")
        print(f"sed -i '${sedCommandsStr}' '{output_path}'")

        if post_hook:
            print(post_hook)

except Exception as e:
    print(f"# Warning: Failed to parse user templates: {e}", file=sys.stderr)

PYTHON_EOF
fi
`
  }

  // --------------------------------------------------------------------------------
  // Terminal Themes
  // --------------------------------------------------------------------------------
  function handleTerminalThemes() {
    const commands = []

    Object.keys(terminalPaths).forEach(terminal => {
                                         if (Settings.data.templates[terminal]) {
                                           const outputPath = terminalPaths[terminal]
                                           const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'))
                                           const templatePath = getTerminalColorsTemplate(terminal)

                                           commands.push(`mkdir -p ${outputDir}`)
                                           commands.push(`cp -f ${templatePath} ${outputPath}`)
                                           commands.push(`${colorsApplyScript} ${terminal}`)
                                         }
                                       })

    if (commands.length > 0) {
      copyProcess.command = ["bash", "-lc", commands.join('; ')]
      copyProcess.running = true
    }
  }

  function getTerminalColorsTemplate(terminal) {
    let colorScheme = Settings.data.colorSchemes.predefinedScheme
    const mode = Settings.data.colorSchemes.darkMode ? 'dark' : 'light'

    colorScheme = schemeNameMap[colorScheme] || colorScheme
    const extension = terminal === 'kitty' ? ".conf" : ""

    return `${Quickshell.shellDir}/Assets/ColorScheme/${colorScheme}/terminal/${terminal}/${colorScheme}-${mode}${extension}`
  }

  // --------------------------------------------------------------------------------
  // User Templates
  // --------------------------------------------------------------------------------
  function buildUserTemplateCommand(input, mode) {
    if (!Settings.data.templates.enableUserTemplates) {
      return ""
    }

    const userConfigPath = getUserConfigPath()
    let script = "\n# Execute user config if it exists\n"
    script += `if [ -f '${userConfigPath}' ]; then\n`
    script += `  matugen image '${input}' --config '${userConfigPath}' --mode ${mode} --type ${Settings.data.colorSchemes.matugenSchemeType}\n`
    script += "fi"

    return script
  }

  function getUserConfigPath() {
    return (Settings.configDir + "user-templates.toml").replace(/'/g, "'\\''")
  }

  // --------------------------------------------------------------------------------
  // Processes
  // --------------------------------------------------------------------------------
  Process {
    id: generateProcess
    workingDirectory: Quickshell.shellDir
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (Settings.data.general.debugMode && this.text && this.text.trim().length > 0) {
          Logger.d("AppThemeService", "GenerateProcess stdout:", this.text)
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          Logger.d("AppThemeService", "GenerateProcess stderr:", this.text)
        }
      }
    }

    onExited: function(code) {
      if (code !== 0) {
        Logger.error("AppThemeService", "GenerateProcess exited with code:", code)
      } else if (Settings.data.general.debugMode) {
        Logger.d("AppThemeService", "Template generation completed successfully")
      }
    }
  }

  Process {
    id: copyProcess
    workingDirectory: Quickshell.shellDir
    running: false
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          Logger.d("AppThemeService", "CopyProcess stderr:", this.text)
        }
      }
    }
  }
}
