import { Controller } from "@hotwired/stimulus"

// Model substrings reported by navigator.userAgentData.getHighEntropyValues(["model"])
// for known e-ink devices. "HiBreak" confirmed against a BigMe HiBreak Pro.
const EINK_DEVICE_MODELS = ["HiBreak"]

export default class extends Controller {
  connect() {
    this.isEinkDevice = false
    this.systemThemeQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.applySystemThemeChange = this.applySystemThemeChange.bind(this)
    this.systemThemeQuery.addEventListener("change", this.applySystemThemeChange)
    this.applyTheme()
    this.detectEinkDevice().then(isEinkDevice => {
      this.isEinkDevice = isEinkDevice
      if (isEinkDevice) this.applyTheme()
    })
  }

  disconnect() {
    this.systemThemeQuery.removeEventListener("change", this.applySystemThemeChange)
  }

  applyTheme() {
    const html = document.documentElement
    const { colorScheme, lightTheme, darkTheme } = this.themeSettings()

    html.dataset.colorScheme = colorScheme
    html.dataset.lightTheme = lightTheme
    html.dataset.darkTheme = darkTheme

    if (this.isEinkDevice) {
      this.applySystemTheme("eink-light", "eink-dark")
    } else if (colorScheme === "light") {
      html.dataset.theme = lightTheme
    } else if (colorScheme === "dark") {
      html.dataset.theme = darkTheme
    } else {
      this.applySystemTheme(lightTheme, darkTheme)
    }
  }

  applySystemThemeChange() {
    this.applyTheme()
  }

  applySystemTheme(lightTheme, darkTheme) {
    const html = document.documentElement

    html.dataset.theme = this.systemThemeQuery.matches ? darkTheme : lightTheme
  }

  async detectEinkDevice() {
    if (!window.isSecureContext || !navigator.userAgentData) return false

    const { model } = await navigator.userAgentData.getHighEntropyValues(["model"])
    return EINK_DEVICE_MODELS.some(knownModel => model.includes(knownModel))
  }

  themeSettings() {
    const source = this.element.dataset

    return {
      colorScheme: source.colorScheme || "system",
      lightTheme: source.lightTheme || "solunized-light",
      darkTheme: source.darkTheme || "solunized-dark"
    }
  }
}
