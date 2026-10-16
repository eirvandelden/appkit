import { Controller } from "@hotwired/stimulus"

// Fallback for browsers without Invoker Commands (command/commandfor).
export default class extends Controller {
  invoke() {
    if ("commandForElement" in HTMLButtonElement.prototype) return

    const target = document.getElementById(this.element.getAttribute("commandfor"))
    if (!target) return

    const command = this.element.getAttribute("command")
    if (command === "show-modal") target.showModal()
    else if (command === "close") target.close()
  }
}
