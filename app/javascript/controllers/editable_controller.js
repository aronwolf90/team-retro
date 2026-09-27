import { Controller } from "@hotwired/stimulus"

// Inline card editing: swap the card text for a textarea.
export default class extends Controller {
  static targets = ["view", "form"]
  static values = { content: String }

  edit() {
    if (!this.hasFormTarget) return
    this.viewTarget.hidden = true
    this.formTarget.hidden = false
    this.viewTarget.dataset.editing = "true"
    this.formTarget.dataset.editing = "true"
    const input = this.formTarget.querySelector("textarea")
    input.value = this.contentValue
    input.focus()
    input.setSelectionRange(input.value.length, input.value.length)
  }

  cancel(event) {
    event?.preventDefault()
    this.stopEditing()
  }

  saved(event) {
    if (event.detail?.success === false) return
    this.stopEditing()
  }

  stopEditing() {
    if (!this.hasFormTarget) return
    this.formTarget.hidden = true
    this.viewTarget.hidden = false
    delete this.viewTarget.dataset.editing
    delete this.formTarget.dataset.editing
  }
}
