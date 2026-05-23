/**
 * @fileoverview Main entry point for the Contacts application
 *
 * This module initializes the Contacts app UI, including:
 * - Rendering the navigation bar with a toggle button for the add contact form
 * - Displaying the contact list
 * - Handling the add contact form visibility and submission
 *
 * The add contact button toggles the form and switches between '+' and '-' icons.
 * The contact list is always shown; the form appears above it when toggled.
 */

// Initialize the contacts app
function initializeContactsApp(container) {
    // Get current contacts and form visibility from global state
    const { contacts, showAddContactForm } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Contacts');

    /**
     * Navigation bar with toggle button
     * - Button toggles add contact form visibility
     * - Icon switches between '+' (show form) and '-' (hide form)
     */
    const navBar = new NavigationBar({
        title: 'Contacts',
        rightButton: {
            element: 'button',
            props: {
                className: 'nav-button add-button',
                onClick: () => globalState.setState({ showAddContactForm: !showAddContactForm }),
                'aria-label': showAddContactForm ? 'Close Form' : 'Add Contact',
                style: {
                    fontSize: '24px',
                    padding: '0 15px',
                    background: 'none',
                    border: 'none',
                    color: 'var(--accent-color)',
                    cursor: 'pointer'
                }
            },
            content: showAddContactForm ? '-' : '+'
        }
    });
    navBar.mount(appContainer);

    // Main content container
    const contentContainer = document.createElement('div');
    contentContainer.className = 'content';
    appContainer.appendChild(contentContainer);

    /**
     * Add contact form
     * - Only shown if showAddContactForm is true
     * - On submit, adds contact and hides form
     */
    if (showAddContactForm) {
        const addContactForm = new AddContactForm({
            onAdd: (newContact) => {
                // Hide form after adding contact
                globalState.setState({
                    showAddContactForm: false
                });
                console.log('New contact added:', newContact);
            }
        });
        addContactForm.mount(contentContainer);
    }

    /**
     * Contact list
     * - Always shown
     * - Clicking a contact opens a modal to call
     */
    const contactList = new ContactList({
        contacts,
        onContactClick: (contact) => {
            globalState.setState({
                selectedContact: contact,
                showModal: true
            });
        }
    });
    contactList.mount(contentContainer);

    // Mount the app container
    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeContactsApp = initializeContactsApp;
