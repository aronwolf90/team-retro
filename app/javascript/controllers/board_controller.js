import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Drag & drop for cards: reorder inside a column, move between columns, or
// drop a card on top of another card to merge them (EasyRetro style).
export default class extends Controller {
  static targets = ["list"]
  static values = { moveUrl: String, mergeUrl: String, sortable: Boolean }

  connect() {
    this.placeholder = document.createElement("div")
    this.placeholder.className = "card-placeholder"
  }

  dragstart(event) {
    const card = event.target.closest(".card")
    if (!card) return
    this.dragged = card
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", card.dataset.cardId)
    requestAnimationFrame(() => card.classList.add("card--dragging"))
  }

  dragover(event) {
    if (!this.dragged) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const list = event.currentTarget
    const over = event.target.closest(".card")

    if (over && over !== this.dragged && !over.contains(this.dragged) && this.inMergeZone(event, over)) {
      this.setMergeTarget(over)
      this.placeholder.remove()
      return
    }
    this.setMergeTarget(null)

    if (!this.sortableValue) {
      // When the board is sorted by votes/date, only the column can change.
      if (!list.contains(this.placeholder) || this.placeholder.parentElement !== list) list.appendChild(this.placeholder)
      return
    }

    const cards = [...list.querySelectorAll(":scope > .card")].filter((c) => c !== this.dragged)
    const next = cards.find((c) => event.clientY < c.getBoundingClientRect().top + c.offsetHeight / 2)
    if (next) list.insertBefore(this.placeholder, next)
    else list.appendChild(this.placeholder)
  }

  dragleave(event) {
    const list = event.currentTarget
    if (list.contains(event.relatedTarget)) return
    if (this.placeholder.parentElement === list) this.placeholder.remove()
    if (this.mergeTarget && list.contains(this.mergeTarget)) this.setMergeTarget(null)
  }

  drop(event) {
    if (!this.dragged) return
    event.preventDefault()
    const list = event.currentTarget
    const card = this.dragged

    if (this.mergeTarget) {
      const target = this.mergeTarget
      this.setMergeTarget(null)
      target.classList.add("card--merging")
      card.remove()
      this.request(this.mergeUrlValue.replace(":id", card.dataset.cardId), "POST", { target_id: target.dataset.cardId })
      return
    }

    if (this.placeholder.parentElement === list) list.insertBefore(card, this.placeholder)
    else list.appendChild(card)
    this.placeholder.remove()

    const position = [...list.querySelectorAll(":scope > .card")].indexOf(card)
    this.request(this.moveUrlValue.replace(":id", card.dataset.cardId), "PATCH", { column: list.dataset.column, position })
  }

  dragend() {
    this.dragged?.classList.remove("card--dragging")
    this.dragged = null
    this.placeholder.remove()
    this.setMergeTarget(null)
  }

  // --- helpers -----------------------------------------------------------

  inMergeZone(event, card) {
    const rect = card.getBoundingClientRect()
    const y = (event.clientY - rect.top) / rect.height
    return y > 0.25 && y < 0.75
  }

  setMergeTarget(card) {
    if (this.mergeTarget === card) return
    this.mergeTarget?.classList.remove("card--merge-target")
    this.mergeTarget = card
    card?.classList.add("card--merge-target")
  }

  async request(url, method, body) {
    const token = document.querySelector("meta[name=csrf-token]")?.content
    try {
      const response = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token, Accept: "application/json" },
        body: JSON.stringify(body)
      })
      if (!response.ok) throw new Error(`Request failed: ${response.status}`)
    } catch (error) {
      console.error(error)
    } finally {
      // Sync with the server state (the broadcast refresh also does this for other tabs).
      Turbo.session.refresh(window.location.href)
    }
  }
}
