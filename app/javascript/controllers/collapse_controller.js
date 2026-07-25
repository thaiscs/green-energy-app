import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "icon"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
  }

  // Fires once on connect with the default value, then on every change.
  openValueChanged() {
    this.panelTarget.hidden = !this.openValue
    this.element.classList.toggle("is-open", this.openValue)

    if (this.hasIconTarget) {
      this.iconTarget.textContent = this.openValue ? "▾" : "▸"
    }

    const trigger = this.element.querySelector("[aria-expanded]")
    if (trigger) trigger.setAttribute("aria-expanded", String(this.openValue))
  }
}
