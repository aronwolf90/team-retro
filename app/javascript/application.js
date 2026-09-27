// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Live updates arrive as Turbo page morphs. Two small rules keep the UI stable:
addEventListener("turbo:before-morph-element", (event) => {
  const from = event.target
  const to = event.detail?.newElement
  if (!(from instanceof Element)) return

  // 1. Keep <details>/<dialog>/toggled panels in the state the user left them.
  if (to && from.hasAttribute("data-keep-state")) {
    if (from.open) to.setAttribute("open", ""); else to.removeAttribute("open")
    if (from.hidden) to.setAttribute("hidden", ""); else to.removeAttribute("hidden")
  }

  // 2. Never overwrite text someone is still typing (or a card being edited).
  if (to && from.hasAttribute("data-preserve-edits")) {
    const dirty = [...from.querySelectorAll("textarea, input:not([type=hidden])")].some((i) => i.value !== i.defaultValue)
    if (dirty || from.dataset.editing === "true") event.preventDefault()
  }
  if (to && from.dataset.editing === "true") event.preventDefault()
})
