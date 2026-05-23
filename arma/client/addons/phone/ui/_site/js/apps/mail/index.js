/** @format */

function initializeMailApp(container) {
    const { emails, contacts, currentUid, selectedEmail, showEmailComposer } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Mail');

    if (typeof requestEmails === 'function') requestEmails();
    if (typeof requestContacts === 'function') requestContacts();

    const navBar = new NavigationBar({
        title: selectedEmail ? 'Email' : (showEmailComposer ? 'New Email' : 'Mail'),
        showBackButton: !!selectedEmail || !!showEmailComposer,
        rightButton: (!selectedEmail && !showEmailComposer) ? {
            element: 'button',
            props: {
                type: 'button',
                className: 'nav-button add-button',
                onClick: () => globalState.setState({ showEmailComposer: true, selectedEmail: null }),
                'aria-label': 'Compose email',
                style: {
                    fontSize: '24px',
                    padding: '0 15px',
                    background: 'none',
                    border: 'none',
                    color: 'var(--accent-color)',
                    cursor: 'pointer'
                }
            },
            content: '+'
        } : null
    });
    navBar.mount(appContainer);

    const contentContainer = document.createElement('div');
    contentContainer.className = 'content mail-content';
    appContainer.appendChild(contentContainer);

    if (showEmailComposer) {
        new MailComposer({ contacts }).mount(contentContainer);
    } else if (selectedEmail) {
        new MailDetail({ email: selectedEmail, contacts }).mount(contentContainer);
    } else {
        new MailList({
            emails,
            contacts,
            currentUid,
            onEmailClick: (email) => globalState.setState({ selectedEmail: email, showEmailComposer: false })
        }).mount(contentContainer);
    }

    container.appendChild(appContainer);
}

window.initializeMailApp = initializeMailApp;
