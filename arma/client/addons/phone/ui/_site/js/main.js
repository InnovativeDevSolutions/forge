/** @format */

/**
 * @fileoverview Main entry point for the phone application.
 * Initializes the application and mounts the root component.
 */

/**
 * Initialize and mount the phone application.
 * Sets up error boundaries and debugging tools.
 *
 * @function
 * @name initializeApp
 * @throws {Error} If app container element is not found
 */
const initializeApp = () => {
    try {
        const appContainer = document.getElementById('app');
        if (!appContainer) {
            throw new Error('App container element not found. Make sure there is an element with id="app" in the HTML.');
        }

        // Set default theme first
        document.documentElement.setAttribute('data-theme', 'dark');

        // Get theme from game using A3API
        const themeAlert = {
            "event": "phone::get::theme",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(themeAlert));

        // Request player UID for correct message mapping
        const meAlert = {
            "event": "phone::get::player",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(meAlert));

        // Request contacts from server
        const contactsAlert = {
            "event": "phone::get::contacts",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(contactsAlert));

        // Request messages from server
        const messagesAlert = {
            "event": "phone::get::messages",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(messagesAlert));

        // Request emails from server
        const emailsAlert = {
            "event": "phone::get::emails",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(emailsAlert));

        // Request notes from server
        const notesAlert = {
            "event": "phone::get::notes",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(notesAlert));

        // Request events from server
        const eventsAlert = {
            "event": "phone::get::events",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(eventsAlert));

        // Request world clocks from server
        const worldClocksAlert = {
            "event": "phone::get::clocks",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(worldClocksAlert));

        // Request alarms from server
        const alarmsAlert = {
            "event": "phone::get::alarms",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alarmsAlert));

        // Initialize phone app
        const app = new App();
        app.mount(appContainer);

        console.log('Phone app initialized successfully');
    } catch (error) {
        console.error('Failed to initialize phone app:', error);
        throw error;
    }
};
