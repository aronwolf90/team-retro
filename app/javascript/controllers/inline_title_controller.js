import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["view", "form", "input"]

  edit() {
    this.element.dataset.editing = "true"
    this.viewTarget.hidden = true
    this.formTarget.hidden = false
    this.inputTarget.value = this.inputTarget.defaultValue
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.stopEditing()
    }
  }

  commit() {
    if (this.element.dataset.editing !== "true") return
    if (this.inputTarget.value.trim() === this.inputTarget.defaultValue.trim()) {
      this.stopEditing()
    } else {
      this.formTarget.requestSubmit()
    }
  }

  saved() {
    this.stopEditing()
  }

  stopEditing() {
    delete this.element.dataset.editing
    this.formTarget.hidden = true
    this.viewTarget.hidden = false
  }
}
