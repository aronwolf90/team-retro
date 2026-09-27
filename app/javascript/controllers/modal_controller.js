import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { open: Boolean }

  connect() {
    if (this.openValue && !this.element.open) this.element.showModal()
    this.element.addEventListener("cancel", this.preventClose)
  }

  disconnect() {
    this.element.removeEventListener("cancel", this.preventClose)
  }

  open() { if (!this.element.open) this.element.showModal() }
  close() { this.element.close() }

  submitted(event) {
    if (event.detail?.success === false) return
    this.element.removeAttribute("data-modal-required")
    this.close()
  }

  // A required modal (no name yet) can't be dismissed with Escape.
  preventClose = (event) => {
    if (this.element.hasAttribute("data-modal-required")) event.preventDefault()
  }
}
