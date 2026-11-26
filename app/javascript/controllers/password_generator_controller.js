import { Controller } from "@hotwired/stimulus"

// Without look-alike characters (0/O, 1/l/I), so the password is easy to read out and type.
const ALPHABET = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const LENGTH = 12

// Fills the password field with a random password and shows it, so it can be copied and shared.
export default class extends Controller {
  static targets = ["input"]

  generate() {
    const numbers = crypto.getRandomValues(new Uint32Array(LENGTH))
    this.inputTarget.value = Array.from(numbers, (n) => ALPHABET[n % ALPHABET.length]).join("")
    this.inputTarget.type = "text"
    this.inputTarget.focus()
    this.inputTarget.select()
  }
}
