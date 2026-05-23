/** @format */

/**
 * @class ContactItem
 * @extends Component
 * @description A component that renders a single contact item in the contacts list.
 * Displays the contact's avatar, name, and phone number, and handles click interactions.
 */
class ContactItem extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} props.contact - The contact data to display
     * @param {string} props.contact.name - Contact's full name
     * @param {string} props.contact.phone - Contact's phone number
     * @param {string} props.contact.avatar - Contact's avatar text (usually initials)
     * @param {Function} [props.onClick] - Callback function when contact is clicked
     */
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
    }

    /**
     * Handle click events on the contact item
     * @param {Event} e - Click event object
     * @private
     */
    handleClick(e) {
        const { onClick, contact } = this.props;

        if (onClick) {
            onClick(contact);
        } else {
            console.warn('ContactItem: No onClick handler provided');
        }
    }

    /**
     * Render the contact item
     * @returns {HTMLElement} The rendered contact item element
     */
    render() {
        const { contact } = this.props;
        const displayName = contact.fullName || contact.name;
        const subtitleParts = [contact.phone];
        if (contact.system) subtitleParts.push('system contact');

        return this.createElement(
            'li',
            {
                className: `contact-item${contact.system ? ' system-contact' : ''}`,
                onClick: this.handleClick,
                role: 'button',
                'aria-label': `Contact ${displayName}`,
            },
            // Avatar section
            this.createElement(
                'div',
                {
                    className: 'contact-avatar',
                    'aria-hidden': 'true',
                },
                contact.avatar
            ),
            // Contact information section
            this.createElement(
                'div',
                { className: 'contact-info' },
                this.createElement('h3', {}, displayName),
                this.createElement('p', { 'aria-label': 'Phone number' }, subtitleParts.filter(Boolean).join(' - '))
            )
        );
    }
}
