import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "entry"]

  connect() {
    if (!this.hasButtonTarget) return

    this.sync()
    this.buttonTarget.hidden = false
  }

  toggleAll() {
    const open = !this.allOpen
    this.entryTargets.forEach(entry => { entry.open = open })
    this.sync()
  }

  sync() {
    const allOpen = this.allOpen
    this.buttonTarget.textContent = allOpen ? "Collapse" : "See all"
    this.buttonTarget.setAttribute("aria-expanded", String(allOpen))
  }

  get allOpen() {
    return this.entryTargets.every(entry => entry.open)
  }
}
