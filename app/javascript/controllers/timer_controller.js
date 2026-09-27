import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { endsAt: String }

  connect() {
    this.retick = () => this.tick()
    document.addEventListener("turbo:morph", this.retick)
    this.start()
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.retick)
    this.stop()
  }
  endsAtValueChanged() { requestAnimationFrame(() => this.start()) }

  start() {
    this.stop()
    this.finished = false
    if (!this.endsAtValue) return
    this.tick()
    this.interval = setInterval(() => this.tick(), 500)
  }

  stop() {
    clearInterval(this.interval)
    this.interval = null
  }

  tick() {
    if (!this.hasDisplayTarget) return
    const remaining = Math.max(0, Math.round((new Date(this.endsAtValue) - Date.now()) / 1000))
    const minutes = String(Math.floor(remaining / 60)).padStart(2, "0")
    const seconds = String(remaining % 60).padStart(2, "0")
    this.displayTarget.textContent = `${minutes}:${seconds}`
    this.element.classList.toggle("timer--done", remaining === 0)
    this.element.classList.toggle("timer--running", remaining > 0)
    if (remaining === 0 && !this.finished) {
      this.finished = true
      this.beep()
    }
  }

  beep() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const oscillator = ctx.createOscillator()
      const gain = ctx.createGain()
      oscillator.connect(gain)
      gain.connect(ctx.destination)
      oscillator.frequency.value = 880
      gain.gain.setValueAtTime(0.2, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.8)
      oscillator.start()
      oscillator.stop(ctx.currentTime + 0.8)
    } catch (_) { /* audio not available */ }
  }
}
