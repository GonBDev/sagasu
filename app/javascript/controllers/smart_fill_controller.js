import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["projectForm", "submit", "status"]

  async fill(event) {
    event.preventDefault()
    if (this.submitTarget.disabled) return

    const form = event.currentTarget
    this.submitTarget.disabled = true
    this.statusTarget.textContent = "Reading the pasted text…"

    try {
      const response = await fetch(form.action, {
        method: "POST",
        headers: { Accept: "application/json" },
        body: new FormData(form)
      })
      const result = await response.json()
      if (!response.ok) {
        this.statusTarget.textContent = result.error
        return
      }

      const count = this.fillEmptyFields(result.fields)
      this.statusTarget.textContent = count > 0
        ? `Filled ${count} ${count === 1 ? "field" : "fields"}. Review the details before saving.`
        : "No matching details were found for the empty fields."
    } catch {
      this.statusTarget.textContent = "Smart Fill couldn’t complete the request. Try again."
    } finally {
      this.submitTarget.disabled = false
    }
  }

  fillEmptyFields(fields) {
    let count = 0
    for (const [name, value] of Object.entries(fields)) {
      const input = this.projectFormTarget.elements.namedItem(`project[${name}]`)
      if (!input || input.value.trim() !== "") continue

      input.value = value
      if (input.value !== "") count++
    }
    return count
  }
}
