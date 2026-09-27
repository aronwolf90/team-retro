import { Controller } from "@hotwired/stimulus"

// Text filter for cards. Re-applied after every live morph.
export default class extends Controller {
  static targets = ["input", "card"]

  connect() {
    this.reapply = () => this.apply()
    document.addEventListener("turbo:morph", this.reapply)
    this.apply()
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.reapply)
  }

  cardTargetConnected() { this.apply() }

  apply() {
    const query = (this.hasInputTarget ? this.inputTarget.value : "").trim().toLowerCase()
    this.cardTargets.forEach((card) => {
      const text = card.querySelector(".card__content")?.textContent.toLowerCase() || ""
      card.classList.toggle("card--filtered-out", query !== "" && !text.includes(query))
    })
  }
}
