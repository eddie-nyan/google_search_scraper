import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-hide flash messages after 5 seconds
    setTimeout(() => {
      this.element.style.opacity = '0'
      this.element.style.transform = 'translateY(-100%)'
      setTimeout(() => {
        this.element.remove()
      }, 500)
    }, 5000)
  }
} 