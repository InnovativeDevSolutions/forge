/** @format */

/**
 * @class MessageItem
 * @extends Component
 * @description A component that renders a single message preview item in the messages list.
 * Displays contact information, last message, timestamp, and unread count.
 */
class MessageItem extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} props.message - Message data object
     * @param {string} props.message.contactName - Name of the contact
     * @param {string} props.message.lastMessage - Most recent message text
     * @param {Date} props.message.timestamp - Timestamp of the last message
     * @param {number} props.message.unread - Number of unread messages
     * @param {Function} [props.onClick] - Callback function when message is clicked
     */
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
        this.handleDeleteClick = this.handleDeleteClick.bind(this);
    }

    /**
     * Handles click events on the message item
     * @private
     */
    handleClick() {
        const { onClick, message } = this.props;
        if (onClick) {
            onClick(message);
        }
    }

    /**
     * Handles delete clicks without opening the conversation.
     * @param {Event} event - Click event
     * @private
     */
    handleDeleteClick(event) {
        event.stopPropagation();
        const { onDelete, message } = this.props;
        if (onDelete) {
            onDelete(message);
        }
    }

    /**
     * Formats the timestamp into a relative time string
     * @param {Date} timestamp - The timestamp to format
     * @returns {string} Formatted relative time (e.g., "5m ago", "2h ago", "3d ago")
     * @private
     */
    formatTime(timestamp) {
        if (!timestamp) return '';

        const now = new Date();
        const messageTime = new Date(timestamp);
        if (Number.isNaN(messageTime.getTime())) return '';

        const diffInHours = (now - messageTime) / (1000 * 60 * 60);

        if (diffInHours < 1) {
            const minutes = Math.floor(diffInHours * 60);
            return `${minutes}m ago`;
        } else if (diffInHours < 24) {
            return `${Math.floor(diffInHours)}h ago`;
        } else {
            const days = Math.floor(diffInHours / 24);
            return `${days}d ago`;
        }
    }

    /**
     * Gets contact initials from the full name
     * @param {string} fullName - Full name of the contact
     * @returns {string} Contact's initials
     * @private
     */
    getContactInitials(fullName) {
        return fullName
            .split(' ')
            .map((n) => n[0])
            .join('');
    }

    /**
     * Renders the message header with contact name and timestamp
     * @param {Object} message - Message data object
     * @returns {HTMLElement} The rendered message header
     * @private
     */
    renderMessageHeader(message) {
        return this.createElement(
            'div',
            { className: 'message-header' },
            this.createElement(
                'h3',
                {
                    className: 'contact-name',
                    role: 'heading',
                    'aria-level': '3',
                },
                message.contactName
            ),
            this.createElement(
                'span',
                {
                    className: 'message-time',
                    'aria-label': message.timestamp ? `Sent ${this.formatTime(message.timestamp)}` : '',
                },
                this.formatTime(message.timestamp)
            )
        );
    }

    /**
     * Renders the message preview with last message and unread count
     * @param {Object} message - Message data object
     * @returns {HTMLElement} The rendered message preview
     * @private
     */
    renderMessagePreview(message) {
        const preview = message.hasConversation ? message.lastMessage : 'Start conversation';

        return this.createElement(
            'div',
            { className: 'message-preview' },
            this.createElement(
                'p',
                {
                    role: 'text',
                    'aria-label': 'Last message',
                },
                preview
            ),
            message.unread > 0 &&
            this.createElement(
                'span',
                {
                    className: 'unread-badge',
                    role: 'status',
                    'aria-label': `${message.unread} unread messages`,
                },
                message.unread.toString()
            )
        );
    }

    /**
     * Render the message item
     * @returns {HTMLElement} The rendered message item element
     */
    render() {
        const { message } = this.props;
        const initials = this.getContactInitials(message.contactName);
        const canDelete = Array.isArray(message.conversation) && message.conversation.length > 0;

        return this.createElement(
            'div',
            {
                className: 'message-item',
                onClick: this.handleClick,
                role: 'button',
                tabIndex: 0,
                'aria-label': `Conversation with ${message.contactName}`,
                onKeyPress: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        this.handleClick();
                    }
                },
            },
            this.createElement(
                'div',
                {
                    className: 'message-avatar',
                    'aria-hidden': 'true',
                },
                initials
            ),
            this.createElement(
                'div',
                { className: 'message-content' },
                this.renderMessageHeader(message),
                this.renderMessagePreview(message)
            ),
            canDelete ? this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'message-thread-delete-button',
                    'aria-label': `Delete conversation with ${message.contactName}`,
                    onClick: this.handleDeleteClick
                },
                'Delete'
            ) : null
        );
    }
}
