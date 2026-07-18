import { Controller } from "@hotwired/stimulus"

// Button-triggered only: never auto-subscribes on page load.
export default class extends Controller {
  async subscribe() {
    if (Notification.permission === "denied") return

    if (Notification.permission !== "granted") {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") return
    }

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.#applicationServerKey,
    })

    await this.#post(subscription.toJSON())
  }

  async unsubscribe() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    if (!subscription) return

    await subscription.unsubscribe()
    await this.#destroy(subscription.endpoint)
  }

  async #post(subscriptionJSON) {
    await fetch(this.#endpointUrl, {
      method: "POST",
      headers: this.#jsonHeaders,
      body: JSON.stringify(subscriptionJSON),
    })
  }

  async #destroy(endpoint) {
    await fetch(this.#endpointUrl, {
      method: "DELETE",
      headers: this.#jsonHeaders,
      body: JSON.stringify({ endpoint }),
    })
  }

  get #jsonHeaders() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
    }
  }

  get #endpointUrl() {
    return "/push_subscription"
  }

  // pushManager.subscribe requires a BufferSource, not the raw base64 string.
  get #applicationServerKey() {
    const base64 = document.querySelector('meta[name="appkit-vapid-public-key"]').content
    const padded = (base64 + "=".repeat((4 - (base64.length % 4)) % 4)).replace(/-/g, "+").replace(/_/g, "/")
    const raw = window.atob(padded)
    return Uint8Array.from([...raw].map((char) => char.charCodeAt(0)))
  }
}
