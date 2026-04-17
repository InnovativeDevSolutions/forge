/** @format */

/**
 * @class ConversationView
 * @extends Component
 * @description A component that displays and manages a messaging conversation.
 * Handles message display, input management, and message sending functionality.
 */
class ConversationView extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} [props.conversation] - The conversation data to display
     * @param {string} props.conversation.contactName - Name of the contact
     * @param {Array<Object>} props.conversation.conversation - Array of message objects
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            newMessage: '',
        };

        this.inputRef = null;
        this.messagesContainerRef = null;

        // Bind methods
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleSendMessage = this.handleSendMessage.bind(this);
        this.setInputRef = this.setInputRef.bind(this);
        this.setMessagesContainerRef = this.setMessagesContainerRef.bind(this);
        this.renderMessageBubble = this.renderMessageBubble.bind(this);
        this.scrollToBottom = this.scrollToBottom.bind(this);
        this.updateScrollbar = this.updateScrollbar.bind(this);
    }

    /**
     * Component lifecycle - after component mounts
     */
    componentDidMount() {
        this.scrollToBottom();
        this.updateScrollbar();
        // Add resize listener to update scrollbar
        window.addEventListener('resize', this.updateScrollbar);
    }

    /**
     * Component lifecycle - after component updates
     */
    componentDidUpdate(prevProps) {
        // If conversation changed or new messages added, scroll to bottom
        if (prevProps.conversation !== this.props.conversation ||
            (prevProps.conversation && this.props.conversation &&
                prevProps.conversation.conversation.length !== this.props.conversation.conversation.length)) {
            this.scrollToBottom();
            this.updateScrollbar();
        }
    }

    /**
     * Component lifecycle - before component unmounts
     */
    componentWillUnmount() {
        window.removeEventListener('resize', this.updateScrollbar);
    }

    /**
     * Stores reference to the messages container element
     * @param {HTMLElement} element - The messages container DOM element
     * @private
     */
    setMessagesContainerRef(element) {
        if (element) {
            this.messagesContainerRef = element;
            this.updateScrollbar();
        }
    }

    /**
     * Stores reference to the input element and manages focus
     * @param {HTMLInputElement} element - The input DOM element
     * @private
     */
    setInputRef(element) {
        if (element) {
            this.inputRef = element;
            if (document.activeElement !== element) {
                element.focus();
            }
        }
    }

    /**
     * Scrolls the messages container to the bottom
     * @private
     */
    scrollToBottom() {
        if (this.messagesContainerRef) {
            requestAnimationFrame(() => {
                this.messagesContainerRef.scrollTop = this.messagesContainerRef.scrollHeight;
            });
        }
    }

    /**
     * Forces scrollbar update by triggering reflow
     * @private
     */
    updateScrollbar() {
        if (this.messagesContainerRef) {
            requestAnimationFrame(() => {
                // Force reflow to update scrollbar
                const container = this.messagesContainerRef;
                const currentScrollTop = container.scrollTop;

                // Temporarily change overflow to force scrollbar recalculation
                const originalOverflow = container.style.overflow;
                container.style.overflow = 'hidden';

                // Force reflow
                container.offsetHeight;

                // Restore overflow
                container.style.overflow = originalOverflow || 'auto';

                // Restore scroll position
                container.scrollTop = currentScrollTop;
            });
        }
    }

    /**
     * Handles changes to the message input
     * @param {Event} e - Input change event
     * @private
     */
    handleInputChange(e) {
        // Update state without triggering a re-render
        this.state.newMessage = e.target.value;
    }

    /**
     * Handles message sending when button is clicked
     * @private
     */
    handleSendMessage() {
        const { newMessage } = this.state;
        const { conversation } = this.props;

        if (conversation && conversation.canMessage === false) {
            return;
        }

        if (newMessage.trim()) {
            // Create new message object
            const newMessageObj = {
                id: generateId(),
                text: newMessage.trim(),
                sender: 'user',
                timestamp: new Date(),
            };

            // Send alert to Arma 3 via A3API
            if (typeof A3API !== 'undefined' && A3API.SendAlert) {
                A3API.SendAlert(JSON.stringify({
                    event: "phone::send::message",
                    data: {
                        conversationId: conversation.id,
                        contactName: conversation.contactName,
                        toUid: conversation.contactId || conversation.id,
                        message: newMessageObj
                    }
                }));
            }

            // Reset input
            this.state.newMessage = '';
            if (this.inputRef) {
                this.inputRef.value = '';
                this.inputRef.focus();
            }

            // Scroll to bottom after sending message
            setTimeout(() => {
                this.scrollToBottom();
                this.updateScrollbar();
            }, 50);
        }
    }

    /**
     * Formats message timestamp for display
     * @param {Date} timestamp - Message timestamp
     * @returns {string} Formatted time string
     * @private
     */
    formatMessageTime(timestamp) {
        return new Date(timestamp).toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
        });
    }

    /**
     * Renders a single message bubble
     * @param {Object} msg - Message object
     * @returns {HTMLElement} Message bubble element
     * @private
     */
    renderMessageBubble(msg) {
        return this.createElement(
            'div',
            {
                className: `message-bubble ${msg.sender}`,
                key: msg.id,
                role: 'article',
                'aria-label': `${msg.sender === 'user' ? 'Sent' : 'Received'} message`,
            },
            this.createElement('p', { role: 'text' }, msg.text),
            this.createElement(
                'span',
                {
                    className: 'message-timestamp',
                    'aria-label': 'Message time',
                },
                this.formatMessageTime(msg.timestamp)
            )
        );
    }

    /**
     * Renders the message input container
     * @returns {HTMLElement} Container element
     * @private
     */
    renderMessageForm() {
        const { conversation } = this.props;
        const canMessage = !conversation || conversation.canMessage !== false;

        return this.createElement(
            'div',
            {
                className: 'message-input-form',
                role: 'form',
                'aria-label': 'Message input form',
            },
            this.createElement('textarea', {
                className: 'message-input',
                placeholder: canMessage ? 'Type a message...' : 'Replies disabled for this contact',
                value: this.state.newMessage,
                disabled: !canMessage,
                onInput: (e) => {
                    if (!canMessage) return;
                    this.handleInputChange(e);
                    // Auto-grow logic
                    if (e.target) {
                        e.target.style.height = 'auto';
                        e.target.style.height = e.target.scrollHeight + 'px';
                    }
                },
                onKeyDown: (e) => {
                    // Send message on Enter key (but not Shift+Enter)
                    if (canMessage && e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        this.handleSendMessage();
                    }
                },
                ref: (el) => {
                    this.setInputRef(el);
                    if (el) {
                        el.style.height = 'auto';
                        el.style.height = el.scrollHeight + 'px';
                    }
                },
                rows: 1,
                'aria-label': 'Message input',
                style: 'resize: none; overflow: hidden;'
            }),
            this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'send-button',
                    onClick: this.handleSendMessage,
                    disabled: !canMessage,
                    'aria-label': canMessage ? 'Send message' : 'Replies disabled'
                },
                this.createElement('img', {
                    src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 2L11 13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>',
                    alt: 'Send',
                    style: 'width:22px;height:22px;padding:0;margin:4px 4px 0 0;display:block;pointer-events:none;'
                })
            )
        );
    }

    /**
     * Render the conversation view
     * @returns {HTMLElement} The rendered conversation view
     */
    render() {
        const { conversation } = this.props;

        if (!conversation) {
            return this.createElement('div', { role: 'alert' }, 'No conversation selected');
        }

        return this.createElement(
            'div',
            {
                className: 'conversation-view',
                role: 'main',
                'aria-label': `Conversation with ${conversation.contactName}`,
                style: 'display: flex; flex-direction: column; height: 100%; overflow: hidden;'
            },
            // Messages container
            this.createElement(
                'div',
                {
                    className: 'messages-container',
                    role: 'log',
                    'aria-label': 'Message history',
                    ref: this.setMessagesContainerRef,
                    style: 'flex: 1; overflow-y: auto; overflow-x: hidden; padding: 10px; box-sizing: border-box;',
                    onScroll: () => {
                        // Update scrollbar on scroll
                        requestAnimationFrame(this.updateScrollbar);
                    }
                },
                ...conversation.conversation.map(this.renderMessageBubble)
            ),
            // Message input form
            this.renderMessageForm()
        );
    }
}
