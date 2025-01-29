import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "filename", "fileInfo", "submitButton"]
  
  connect() {
    this.hidePreview()
    this.initializeDragAndDrop()
    this.updateSubmitButton()
  }

  hidePreview() {
    this.previewTarget.classList.add("hidden")
  }

  showPreview() {
    this.previewTarget.classList.remove("hidden")
  }

  updatePreview() {
    const file = this.inputTarget.files[0]
    if (!file) {
      this.hidePreview()
      this.updateSubmitButton()
      return
    }

    this.showPreview()
    this.filenameTarget.textContent = `Selected file: ${file.name}`
    
    const fileInfo = this.fileInfoTarget
    fileInfo.innerHTML = ""
    
    // Add file details
    const details = [
      `Type: ${file.type || "text/csv"}`,
      `Size: ${this.formatFileSize(file.size)}`
    ]
    
    details.forEach(detail => {
      const li = document.createElement("li")
      li.textContent = detail
      fileInfo.appendChild(li)
    })

    // Preview CSV content
    if (file.type === "text/csv" || file.name.endsWith(".csv")) {
      this.previewCSV(file)
    }

    this.updateSubmitButton()
  }

  initializeDragAndDrop() {
    const dropZone = this.element.querySelector('.border-dashed')
    if (!dropZone) return

    // Prevent default behavior for all drag events
    dropZone.addEventListener('dragenter', this.handleDragEvent.bind(this))
    dropZone.addEventListener('dragover', this.handleDragEvent.bind(this))
    dropZone.addEventListener('dragleave', this.handleDragEvent.bind(this))
    dropZone.addEventListener('drop', this.handleDrop.bind(this))

    // Add visual feedback
    dropZone.addEventListener('dragenter', () => {
      dropZone.classList.add('border-indigo-500')
      dropZone.classList.remove('border-gray-300')
    })

    dropZone.addEventListener('dragleave', () => {
      dropZone.classList.remove('border-indigo-500')
      dropZone.classList.add('border-gray-300')
    })
  }

  handleDragEvent(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  handleDrop(e) {
    e.preventDefault()
    e.stopPropagation()

    const dropZone = e.currentTarget
    dropZone.classList.remove('border-indigo-500')
    dropZone.classList.add('border-gray-300')

    const dt = e.dataTransfer
    const file = dt.files[0]

    if (file) {
      if (!file.name.toLowerCase().endsWith('.csv')) {
        alert('Please upload a CSV file')
        return
      }

      // Create a new FileList-like object
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      
      // Set the file input's files
      this.inputTarget.files = dataTransfer.files
      
      // Trigger the preview
      this.updatePreview()
    }
  }

  updateSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      const hasFile = this.inputTarget.files && this.inputTarget.files.length > 0
      this.submitButtonTarget.disabled = !hasFile
      this.submitButtonTarget.classList.toggle('invisible', !hasFile)
    }
  }

  previewCSV(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      const content = e.target.result
      const lines = content.split("\n").slice(0, 5) // Show first 5 lines
      
      if (lines.length > 0) {
        const li = document.createElement("li")
        li.textContent = `Preview (first ${Math.min(5, lines.length)} lines):`
        this.fileInfoTarget.appendChild(li)
        
        const pre = document.createElement("pre")
        pre.className = "mt-2 p-2 bg-gray-100 rounded text-xs overflow-auto"
        pre.textContent = lines.join("\n")
        this.fileInfoTarget.appendChild(pre)
      }
    }
    reader.readAsText(file)
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }

  handleSubmit(event) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  handleSubmitComplete(event) {
    // Always reload the page after form submission
    window.location.reload()
  }

  showNotification(message, type) {
    const notificationDiv = document.createElement('div')
    notificationDiv.className = `fixed top-4 right-4 rounded-md p-4 ${
      type === 'success' ? 'bg-green-50' : 'bg-red-50'
    } shadow-lg max-w-sm z-50 transition-all duration-500 ease-in-out transform translate-y-0`
    
    notificationDiv.innerHTML = `
      <div class="flex items-center">
        <div class="flex-shrink-0">
          ${type === 'success' 
            ? `<svg class="h-5 w-5 text-green-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>`
            : `<svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>`
          }
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium ${
            type === 'success' ? 'text-green-800' : 'text-red-800'
          }">${message}</p>
        </div>
      </div>
    `
    
    document.body.appendChild(notificationDiv)
    
    // Trigger reflow to ensure the transition works
    void notificationDiv.offsetWidth
    
    // Add fade-in effect
    notificationDiv.style.opacity = '1'
    
    // Remove the notification after 5 seconds
    setTimeout(() => {
      notificationDiv.style.opacity = '0'
      notificationDiv.style.transform = 'translateY(-100%)'
      setTimeout(() => {
        document.body.removeChild(notificationDiv)
      }, 500)
    }, 5000)
  }

  resetForm() {
    this.inputTarget.value = ''
    this.hidePreview()
    this.updateSubmitButton()
  }
}
