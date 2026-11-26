import { Controller } from "@hotwired/stimulus"

// A hint that stays closed in this browser once closed. data-keep-state keeps it hidden during live updates;
// a new key (e.g. other columns hidden) shows it again.
export default class extends Controller {
  static values = { key: String }

  keyValueChanged() {
    this.element.hidden = this.dismissed
  }

  dismiss() {
    this.element.hidden = true
    try { localStorage.setItem(this.keyValue, "1") } catch {}
  }

  get dismissed() {
    try { return localStorage.getItem(this.keyValue) === "1" } catch { return false }
  }
}
