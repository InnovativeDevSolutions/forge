/** @format */

/**
 * @class MessagesList
 * @extends Component
 * @description A component that renders a list of message items.
 * Manages the display of MessageItem components and handles message selection.
 */
class MessagesList extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array<Object>} [props.messages=[]] - Array of message objects to display
     * @param {Function} [props.onMessageClick] - Callback function when a message is clicked
     */
    constructor(props) {
        super(props);
        this.state = {
            filteredMessages: this.buildRows(props.messages || [], props.contacts || [], ''),
            searchTerm: ''
        };
    }

    /**
     * Update filtered messages when props change
     * @param {Object} nextProps - Next props
     */
    componentWillReceiveProps(nextProps) {
        if (
            nextProps.messages !== this.props.messages ||
            nextProps.contacts !== this.props.contacts ||
            nextProps.includeContacts !== this.props.includeContacts ||
            nextProps.includeContactsOnSearch !== this.props.includeContactsOnSearch
        ) {
            // Re-apply current search filter to new messages
            this.handleSearch(this.state.searchTerm);
        }
    }

    buildRows(messages = [], contacts = [], searchTerm = '') {
        const searchTermLower = searchTerm.toLowerCase();
        const includeContacts = this.props.includeContacts === true || (this.props.includeContactsOnSearch === true && searchTermLower.length > 0);
        const byContactId = new Map();
        const contactByUid = new Map();

        contacts
            .filter((contact) => contact && contact.uid)
            .forEach((contact) => contactByUid.set(contact.uid, contact));

        messages.forEach((message) => {
            if (!message) return;
            const contactId = message.contactId || message.id;
            const contact = contactByUid.get(contactId) || {};

            byContactId.set(contactId, {
                ...contact,
                ...message,
                id: contactId,
                contactId,
                contactName: message.contactName || contact.fullName || contact.name || contactId,
                phone: contact.phone || message.phone || '',
                email: contact.email || message.email || '',
                canCall: contact.canCall !== false,
                canMessage: contact.canMessage !== false,
                hasConversation: Array.isArray(message.conversation) && message.conversation.length > 0
            });
        });

        if (includeContacts) {
            contacts
                .filter((contact) => contact && contact.uid && contact.canMessage !== false)
                .forEach((contact) => {
                    if (byContactId.has(contact.uid)) return;

                    byContactId.set(contact.uid, {
                        id: contact.uid,
                        contactId: contact.uid,
                        contactName: contact.fullName || contact.name || contact.uid,
                        fullName: contact.fullName || contact.name || contact.uid,
                        name: contact.name || contact.fullName || contact.uid,
                        phone: contact.phone || '',
                        email: contact.email || '',
                        avatar: contact.avatar,
                        canCall: contact.canCall !== false,
                        canMessage: contact.canMessage !== false,
                        lastMessage: 'Start conversation',
                        timestamp: null,
                        unread: 0,
                        conversation: [],
                        hasConversation: false
                    });
                });
        }

        return Array.from(byContactId.values()).filter((message) => {
            if (!searchTermLower) return true;

            return [
                message.contactName,
                message.lastMessage,
                message.contactId,
                message.id,
                message.phone,
                message.email
            ].some((value) => (value || '').toString().toLowerCase().includes(searchTermLower));
        });
    }

    /**
     * Filter messages based on search term
     * @param {string} searchTerm - The search term to filter messages
     * @private
     */
    handleSearch(searchTerm) {
        const { messages = [], contacts = [] } = this.props;
        const filtered = this.buildRows(messages, contacts, searchTerm);

        this.setState({
            filteredMessages: filtered,
            searchTerm
        });
    }

    /**
     * Creates MessageItem components from the filtered messages array
     * @private
     * @returns {Array<MessageItem>} Array of MessageItem components
     */
    renderMessageItems() {
        const { onMessageClick, onMessageDelete } = this.props;
        const { filteredMessages } = this.state;

        if (!filteredMessages.length) {
            return [
                this.createElement(
                    'div',
                    { className: 'messages-empty-state' },
                    this.createElement('strong', {}, this.props.emptyTitle || 'No conversations'),
                    this.createElement('span', {}, this.props.emptySubtitle || 'Tap + to start a new conversation.')
                )
            ];
        }

        return filteredMessages.map(
            (message) =>
                new MessageItem({
                    message,
                    onClick: onMessageClick,
                    onDelete: onMessageDelete,
                    key: message.id,
                })
        );
    }

    /**
     * Render the messages list with search bar
     * @returns {HTMLElement} The rendered messages list element
     */
    render() {
        const { searchTerm } = this.state;

        return this.createElement(
            'div',
            {
                className: 'messages-container',
                style: {
                    display: 'flex',
                    flexDirection: 'column',
                    height: '100%'
                }
            },
            new SearchBar({
                placeholder: this.props.searchPlaceholder || 'Search by contact name...',
                onSearch: this.handleSearch.bind(this),
                value: searchTerm
            }),
            this.createElement(
                'div',
                {
                    className: 'messages-list',
                    role: 'list',
                    'aria-label': 'Messages list',
                    style: {
                        flex: 1,
                        overflowY: 'auto',
                        padding: '10px'
                    }
                },
                ...this.renderMessageItems()
            )
        );
    }
}
