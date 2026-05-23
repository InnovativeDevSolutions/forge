/**
 * @fileoverview Root application component and integration logic.
 *
 * The App class manages:
 * - Switching between different app modules (home, phone, messages, contacts, settings)
 * - Rendering the correct app UI based on global state
 * - Handling global modals (e.g., call confirmation)
 * - Integrating shared UI elements (status bar, home indicator, dynamic island)
 *
 * Each app module is initialized via its global function (e.g., window.initializePhoneApp) and mounted into the app container.
 * The placeholder app view is shown for unimplemented apps.
 *
 * This is the main entry point for the phone UI framework.
 */

/**
 * @class App
 * @extends Component
 * @description The root component that manages app switching and integration
 */
class App extends Component {
    /**
     * @constructor
     * Initializes state and subscribes to global state changes.
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            ...globalState.getState(),
            currentApp: 'home',
            showAddContactForm: false
        };

        this.unsubscribe = null;
    }

    /**
     * Subscribe to global state changes after mounting
     * @lifecycle
     */
    componentDidMount() {
        this.unsubscribe = globalState.subscribe((newState) => {
            this.setState(newState);
        });
    }

    /**
     * Clean up subscriptions before unmounting
     * @lifecycle
     */
    componentWillUnmount() {
        if (this.unsubscribe) {
            this.unsubscribe();
        }
    }

    /**
     * Render the current app based on app state
     * @returns {HTMLElement} Current app view
     * @private
     */
    renderCurrentApp() {
        const { currentApp } = this.state;
        const appContainer = this.createElement('div', { className: 'app-container' });

        switch (currentApp) {
            case 'clock':
                window.initializeClockApp(appContainer);
                break;
            case 'calendar':
                window.initializeCalendarApp(appContainer);
                break;
            case 'home':
                return new HomeScreen();
            case 'phone':
                window.initializePhoneApp(appContainer);
                break;
            case 'messages':
                window.initializeMessagesApp(appContainer);
                break;
            case 'mail':
                window.initializeMailApp(appContainer);
                break;
            case 'notes':
                window.initializeNotesApp(appContainer);
                break;
            case 'contacts':
                window.initializeContactsApp(appContainer);
                break;
            case 'settings':
                window.initializeSettingsApp(appContainer);
                break;
            case 'wallet':
                window.initializeMobileBankApp(appContainer);
                break;
            default:
                return this.renderPlaceholderApp(currentApp);
        }

        return appContainer;
    }

    /**
     * Render a placeholder for unimplemented apps
     * @param {string} appName - App name
     * @returns {HTMLElement} Placeholder app view
     * @private
     */
    renderPlaceholderApp(appName) {
        const appIcons = {
            calendar: '',
            camera: '',
            store: '',
            mail: '',
            icloud: '',
            photos: '',
            safari: '',
            wallet: ''
        };

        return this.createElement(
            'div',
            { className: 'app-container' },
            new NavigationBar({ title: appName }),
            this.createElement(
                'div',
                { className: 'content' },
                this.createElement(
                    'div',
                    {
                        style: {
                            textAlign: 'center',
                            padding: '50px 20px',
                            color: '#6c757d',
                        },
                    },
                    this.createElement('h2', { role: 'img', 'aria-label': appName }, appIcons[appName] || ''),
                    this.createElement('p', {}, `${appName} app coming soon!`)
                )
            )
        );
    }

    /**
     * Render the phone app UI, including status bar, main content, home indicator, and modals.
     * @returns {HTMLElement} The rendered phone app
     */
    render() {
        const { currentApp, selectedContact, showModal, showDeleteModal, noteToDelete, eventToDelete } = this.state;
        const openMessageThread = (contact) => {
            if (!contact || contact.canMessage === false) return;

            const contactId = contact.contactId || contact.uid || contact.id;
            if (!contactId) return;

            const { messages = [], rawMessages = [], currentUid = window.__playerUid } = globalState.getState();
            const existingConversation = messages.find((message) => (message.contactId || message.id) === contactId);
            const selectedRawMessages = rawMessages.filter((message) =>
                message &&
                (
                    (message.from === currentUid && message.to === contactId) ||
                    (message.from === contactId && message.to === currentUid)
                )
            );
            const conversation = existingConversation || {
                ...contact,
                id: contactId,
                contactId,
                contactName: contact.fullName || contact.name || contactId,
                conversation: [],
                hasConversation: false
            };

            globalState.setState({
                currentApp: 'messages',
                selectedContact: null,
                showModal: false,
                showMessageContactPicker: false,
                selectedConversation: {
                    ...conversation,
                    id: contactId,
                    contactId,
                    contactName: conversation.contactName || contact.fullName || contact.name || contactId,
                    conversation: conversation.conversation || []
                },
                selectedConversationRaw: {
                    otherUid: contactId,
                    messages: selectedRawMessages
                }
            });
        };

        return this.createElement(
            'div',
            {
                className: 'phone-container',
                role: 'application',
                'aria-label': 'Phone interface',
            },
            this.createElement(
                'div',
                {
                    className: 'phone-screen dynamic-island',
                    role: 'main',
                },
                // Dynamic Island content
                this.createElement(
                    'div',
                    {
                        className: 'dynamic-island-content',
                        'aria-hidden': 'true',
                    },
                    this.createElement('div', { className: 'speaker' }),
                    this.createElement('div', { className: 'camera' })
                ),

                // Status bar
                new StatusBar(),

                // Main app content
                this.renderCurrentApp(),

                // Home indicator (except on home screen)
                currentApp !== 'home' && new HomeIndicator(),

                // Call modal
                showModal && selectedContact && new Modal({
                    show: showModal,
                    title: selectedContact.canCall === false ? (selectedContact.fullName || selectedContact.name) : `Call ${selectedContact.fullName || selectedContact.name}?`,
                    confirmText: selectedContact.canCall === false ? 'Close' : 'Call',
                    cancelText: selectedContact.canCall === false ? 'Back' : 'Cancel',
                    hideCancel: true,
                    hideConfirm: selectedContact.canCall === false,
                    extraActions: selectedContact.canMessage === false || !(selectedContact.contactId || selectedContact.uid || selectedContact.id) ? [] : [{
                        text: 'Text',
                        ariaLabel: `Text ${selectedContact.fullName || selectedContact.name}`,
                        className: 'button secondary',
                        onClick: () => openMessageThread(selectedContact)
                    }],
                    onClose: () => globalState.setState({ showModal: false, selectedContact: null }),
                    onConfirm: () => {
                        if (selectedContact.canCall === false) {
                            globalState.setState({ showModal: false, selectedContact: null });
                            return;
                        }

                        globalState.setState({
                            phoneNumber: selectedContact.phone,
                            showModal: false,
                            selectedContact: null,
                            currentApp: 'phone'
                        });
                    },
                    children: [
                        this.createElement(
                            'p',
                            { role: 'alert' },
                            selectedContact.canCall === false
                                ? `${selectedContact.fullName || selectedContact.name} is a command broadcast contact. Incoming messages and email are available, but direct calls are disabled.`
                                : `Do you want to call ${selectedContact.fullName || selectedContact.name} at ${selectedContact.phone}?`
                        )
                    ]
                }),

                // Delete note confirmation modal
                showDeleteModal && noteToDelete && new Modal({
                    show: showDeleteModal,
                    title: `Delete "${noteToDelete.title}"?`,
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
                    onClose: () => globalState.setState({ showDeleteModal: false, noteToDelete: null }),
                    onConfirm: () => {
                        // Find the onDelete handler from the notes editor and call it
                        const currentState = globalState.getState();
                        const currentNotes = currentState.notes || [];
                        const updatedNotes = currentNotes.filter(n => n.id !== noteToDelete.id);
                        
                        globalState.setState({
                            notes: updatedNotes,
                            currentNote: null,
                            showNoteEditor: false,
                            showDeleteModal: false,
                            noteToDelete: null
                        });
                        
                        // Delete from server
                        if (typeof deleteNote === 'function') {
                            deleteNote(noteToDelete.id);
                        }
                        
                        console.log('Note deleted:', noteToDelete.id);
                    },
                    children: [this.createElement('p', { role: 'alert' }, `Are you sure you want to delete this note? This action cannot be undone.`)]
                }),

                showDeleteModal && eventToDelete && new Modal({
                    show: showDeleteModal,
                    title: `Delete "${eventToDelete.title}"?`,
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
                    onClose: () => globalState.setState({ showDeleteModal: false, eventToDelete: null }),
                    onConfirm: () => {
                        // Find the onDelete handler from the events editor and call it
                        const currentState = globalState.getState();
                        const currentEvents = currentState.events || [];
                        const updatedEvents = currentEvents.filter(n => n.id !== eventToDelete.id);
                        
                        globalState.setState({
                            events: updatedEvents,
                            currentEvent: null,
                            showEventEditor: false,
                            showDeleteModal: false,
                            eventToDelete: null
                        });
                        
                        // Delete from server
                        if (typeof deleteCalendarEvent === 'function') {
                            deleteCalendarEvent(eventToDelete.id);
                        }
                        
                        console.log('Event deleted:', eventToDelete.id);
                    },
                    children: [this.createElement('p', { role: 'alert' }, `Are you sure you want to delete this event? This action cannot be undone.`)]
                })
            )
        );
    }
}
