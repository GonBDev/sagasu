import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "chip", "status"]

  connect() {
    this.sync()
  }

  choose({ params: { unit } }) {
    this.fieldTarget.value = unit
    this.sync()
    this.statusTarget.textContent = `Unit of measure set to ${unit}.`
  }

  sync() {
    this.chipTargets.forEach(chip => {
      chip.setAttribute("aria-pressed", String(chip.dataset.unitSuggestionsUnitParam === this.fieldTarget.value))
    })
  }
}
