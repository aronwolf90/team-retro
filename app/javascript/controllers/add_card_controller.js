import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "form", "input"]

  open() {
    this.triggerTarget.hidden = true
    this.formTarget.hidden = false
    this.inputTarget.focus()
  }

  close() {
    this.formTarget.reset()
    this.formTarget.hidden = true
    this.triggerTarget.hidden = false
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    } else if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault()
      if (this.inputTarget.value.trim() !== "") this.formTarget.requestSubmit()
    }
  }

  submitted(event) {
    if (event.detail?.success === false) return
    this.formTarget.reset()
    this.inputTarget.focus()
  }
}
