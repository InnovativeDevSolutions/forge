/** @format */

/**
 * @class ContactList
 * @extends Component
 * @description A component that renders a list of contacts.
 * Manages the display of multiple ContactItem components and handles contact selection.
 */
class ContactList extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array<Object>} [props.contacts=[]] - Array of contact objects to display
     * @param {Function} [props.onContactClick] - Callback function when a contact is clicked
     */
    constructor(props) {
        super(props);
        this.state = {
            filteredContacts: props.contacts || [],
            searchTerm: ''
        };
    }

    /**
     * Update filtered contacts when props change
     * @param {Object} nextProps - Next props
     */
    componentWillReceiveProps(nextProps) {
        if (nextProps.contacts !== this.props.contacts) {
            // Re-apply current search filter to new contacts
            this.handleSearch(this.state.searchTerm);
        }
    }

    /**
     * Filter contacts based on search term
     * @param {string} searchTerm - The search term to filter contacts
     * @private
     */
    handleSearch(searchTerm) {
        const { contacts = [] } = this.props;
        const searchTermLower = searchTerm.toLowerCase();

        const filtered = contacts.filter(contact =>
            contact.name.toLowerCase().includes(searchTermLower) ||
            contact.phone.toLowerCase().includes(searchTermLower)
        );

        this.setState({
            filteredContacts: filtered,
            searchTerm
        });
    }

    /**
     * Creates ContactItem components from the filtered contacts array
     * @private
     * @returns {Array<ContactItem>} Array of ContactItem components
     */
    renderContactItems() {
        const { onContactClick } = this.props;
        const { filteredContacts } = this.state;

        return filteredContacts.map(
            (contact) =>
                new ContactItem({
                    contact,
                    onClick: onContactClick,
                    key: contact.id,
                })
        );
    }

    /**
     * Render the contact list with search bar
     * @returns {HTMLElement} The rendered contact list element
     */
    render() {
        const { searchTerm } = this.state;

        return this.createElement(
            'div',
            {
                className: 'contacts-container',
                style: {
                    display: 'flex',
                    flexDirection: 'column',
                    height: '100%'
                }
            },
            new SearchBar({
                placeholder: 'Search contacts...',
                onSearch: this.handleSearch.bind(this),
                value: searchTerm
            }),
            this.createElement(
                'ul',
                {
                    className: 'contact-list',
                    role: 'list',
                    'aria-label': 'Contacts list',
                    style: {
                        flex: 1,
                        overflowY: 'auto',
                        padding: '10px',
                        margin: 0,
                        listStyle: 'none'
                    }
                },
                ...this.renderContactItems()
            )
        );
    }
}