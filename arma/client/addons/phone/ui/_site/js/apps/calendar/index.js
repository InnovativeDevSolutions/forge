/**
 * @fileoverview Main entry point for the Calendar application
 *
 * This module initializes the Calendar app UI, including:
 * - Displaying the calendar view
 * - Handling event creation, editing, and deletion via EventEditor
 * - Managing event persistence via A3API
 */

/**
 * Initializes and mounts the Calendar application.
 * @param {HTMLElement} container - The DOM element to mount the app into.
 */
function initializeCalendarApp(container) {
    const { events = [], selectedDate = new Date(), showEventEditor = false, currentEvent = null } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Calendar');

    // Check if we're viewing/editing a specific event
    if (showEventEditor || currentEvent) {
        // Show event editor
        const eventEditor = new EventEditor({
            event: currentEvent,
            onSave: (savedEvent) => {
                const currentEvents = globalState.getState().events || [];
                let updatedEvents;

                if (savedEvent.id && currentEvents.find(e => e.id === savedEvent.id)) {
                    // Update existing event
                    updatedEvents = currentEvents.map(e => e.id === savedEvent.id ? savedEvent : e);
                } else {
                    // Add new event
                    updatedEvents = [savedEvent, ...currentEvents];
                }

                globalState.setState({
                    events: updatedEvents,
                    currentEvent: null,
                    showEventEditor: false
                });

                // Save to server
                if (typeof saveCalendarEvent === 'function') {
                    saveCalendarEvent(savedEvent);
                }
            },
            onCancel: () => {
                globalState.setState({
                    currentEvent: null,
                    showEventEditor: false
                });
            },
            onDelete: (eventId) => {
                const currentEvents = globalState.getState().events || [];
                const updatedEvents = currentEvents.filter(e => e.id !== eventId);

                globalState.setState({
                    events: updatedEvents,
                    currentEvent: null,
                    showEventEditor: false
                });

                // Delete from server
                if (typeof deleteCalendarEvent === 'function') {
                    deleteCalendarEvent(eventId);
                }
            }
        });
        eventEditor.mount(appContainer);
    } else {
        // Show calendar view
        const navBar = new NavigationBar({
            title: 'Calendar',
            rightButton: {
                element: 'button',
                props: {
                    className: 'nav-button add-event-button',
                    onClick: () => {
                        globalState.setState({
                            showEventEditor: true,
                            currentEvent: null
                        });
                    },
                    'aria-label': 'Add Event'
                },
                content: '+'
            }
        });
        navBar.mount(appContainer);

        const calendar = new Calendar({
            selectedDate: selectedDate,
            events: events,
            onDayClick: (date) => {
                globalState.setState({
                    selectedDate: date,
                    currentEvent: null,
                    showEventEditor: false
                });
            },
            onEventClick: (event) => {
                globalState.setState({
                    currentEvent: event,
                    showEventEditor: true
                });
            }
        });
        calendar.mount(appContainer);
    }

    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeCalendarApp = initializeCalendarApp; 