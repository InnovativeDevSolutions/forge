/**
 * @fileoverview Main entry point for the Phone application
 *
 * This module initializes the Phone app UI, including:
 * - Rendering the dialpad component
 * - Mounting the dialpad into the provided container
 *
 * The initializePhoneApp function is exposed globally for use by the main app.
 */

// Initialize the phone app
function initializePhoneApp(container) {
    // Create and mount the dialpad component
    const phoneDialpad = new Dialpad();
    phoneDialpad.mount(container);
}

// Make initialization function globally available
window.initializePhoneApp = initializePhoneApp;