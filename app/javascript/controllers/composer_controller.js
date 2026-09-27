import { Controller } from "@hotwired/stimulus"

// Textarea forms: Enter submits, Shift+Enter adds a newline; reset after success.
export default class extends Controller {
  static targets = ["input", "actions"]

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault()
      if (this.inputTarget.value.trim() !== "") this.element.requestSubmit()
    }
  }

  reset(event) {
    if (event.detail?.success === false) return
    this.element.reset()
    this.inputTarget.style.height = ""
  }
}
