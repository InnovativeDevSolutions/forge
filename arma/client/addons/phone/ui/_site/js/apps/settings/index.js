/**
 * @fileoverview Main entry point for the Settings application
 *
 * This module initializes the Settings app UI, including:
 * - Rendering the Settings component
 * - Mounting the Settings component into the provided container
 *
 * The initializeSettingsApp function is exposed globally for use by the main app.
 */

// Initialize the settings app
function initializeSettingsApp(container) {
    /**
     * Navigation bar with toggle button
     * - Button toggles add contact form visibility
     * - Icon switches between '+' (show form) and '-' (hide form)
     */
    const navBar = new NavigationBar({
        title: 'Settings'
    });
    navBar.mount(container);

    // Create and mount the Settings component
    const settings = new Settings();
    settings.mount(container);
}

// Make initialization function globally available
window.initializeSettingsApp = initializeSettingsApp;