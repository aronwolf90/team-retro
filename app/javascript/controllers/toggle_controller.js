import { Controller } from "@hotwired/stimulus"

// Show/hide a panel (used for the comments under a card).
export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    const open = this.panelTarget.hidden
    this.panelTarget.hidden = !open
    this.buttonTargets.forEach((b) => b.setAttribute("aria-expanded", String(open)))
    if (open) this.panelTarget.querySelector("textarea")?.focus()
  }
}
