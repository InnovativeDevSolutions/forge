/**
 * @fileoverview Main entry point for the Messages application.
 */

function initializeMessagesApp(container) {
    const { messages = [], contacts = [], selectedConversation, showMessageContactPicker } = globalState.getState();
    const appContainer = document.createElement('div');

    const openConversation = (conversation) => {
        if (!conversation) return;

        const contactId = conversation.contactId || conversation.uid || conversation.id;
        const { rawMessages = [], currentUid = window.__playerUid } = globalState.getState();
        const selectedRawMessages = rawMessages.filter((message) =>
            message &&
            (
                (message.from === currentUid && message.to === contactId) ||
                (message.from === contactId && message.to === currentUid)
            )
        );

        globalState.setState({
            selectedConversation: {
                ...conversation,
                id: contactId,
                contactId,
                contactName: conversation.contactName || conversation.fullName || conversation.name || contactId,
                conversation: conversation.conversation || []
            },
            selectedConversationRaw: {
                otherUid: contactId,
                messages: selectedRawMessages
            },
            showMessageContactPicker: false
        });
    };

    const deleteConversationMessages = (conversation) => {
        const messageIds = ((conversation && conversation.conversation) || [])
            .map((message) => message && message.id)
            .filter(Boolean);

        if (!messageIds.length) return;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            messageIds.forEach((messageId) => {
                A3API.SendAlert(JSON.stringify({
                    event: 'phone::delete::message',
                    data: { messageId }
                }));
            });
        }
    };

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Messages');

    const navBar = new NavigationBar({
        title: selectedConversation ? selectedConversation.contactName : (showMessageContactPicker ? 'New Conversation' : 'Messages'),
        showBackButton: !!selectedConversation || showMessageContactPicker,
        rightButton: selectedConversation && selectedConversation.conversation && selectedConversation.conversation.length ? {
            element: 'button',
            props: {
                type: 'button',
                className: 'message-nav-delete-button',
                onClick: () => {
                    deleteConversationMessages(selectedConversation);
                    globalState.setState({ selectedConversation: null, selectedConversationRaw: null });
                }
            },
            content: 'Delete'
        } : (!selectedConversation && !showMessageContactPicker) ? {
            element: 'button',
            props: {
                type: 'button',
                className: 'nav-button add-button',
                onClick: () => globalState.setState({ showMessageContactPicker: true }),
                'aria-label': 'Start conversation',
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
    contentContainer.className = 'content';
    appContainer.appendChild(contentContainer);

    if (selectedConversation) {
        const conversationView = new ConversationView({ conversation: selectedConversation });
        conversationView.mount(contentContainer);
    } else {
        const messagesList = new MessagesList({
            messages,
            contacts,
            includeContacts: showMessageContactPicker,
            includeContactsOnSearch: true,
            searchPlaceholder: 'Search contacts or conversations...',
            emptyTitle: showMessageContactPicker ? 'No contacts found' : 'No conversations',
            emptySubtitle: showMessageContactPicker ? 'Try another search.' : 'Search for a contact to start texting.',
            onMessageClick: openConversation,
            onMessageDelete: deleteConversationMessages
        });
        messagesList.mount(contentContainer);
    }

    container.appendChild(appContainer);
}

window.initializeMessagesApp = initializeMessagesApp;
