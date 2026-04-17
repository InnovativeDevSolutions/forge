/** @format */

class MailList extends Component {
    constructor(props = {}) {
        super(props);
        this.state = {
            searchTerm: ''
        };

        this.handleSearch = this.handleSearch.bind(this);
        this.renderEmailItem = this.renderEmailItem.bind(this);
    }

    handleSearch(searchTerm) {
        this.setState({ searchTerm });
    }

    formatEmailTime(timestamp) {
        const parsed = new Date(timestamp);
        if (Number.isNaN(parsed.getTime())) return '';

        return parsed.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    resolveContactName(uid) {
        const contact = (this.props.contacts || []).find((entry) => entry.uid === uid || entry.id === uid);
        return contact ? contact.name : uid;
    }

    getFilteredEmails() {
        const { emails = [] } = this.props;
        const searchTerm = (this.state.searchTerm || '').toLowerCase();

        if (!searchTerm) return emails;

        return emails.filter((email) => {
            const senderName = this.resolveContactName(email.from || '').toLowerCase();
            const recipientName = this.resolveContactName(email.to || '').toLowerCase();
            return (
                (email.subject || '').toLowerCase().includes(searchTerm) ||
                (email.body || '').toLowerCase().includes(searchTerm) ||
                senderName.includes(searchTerm) ||
                recipientName.includes(searchTerm)
            );
        });
    }

    renderEmailItem(email) {
        const { currentUid, onEmailClick } = this.props;
        const isSent = email.from === currentUid;
        const actorName = this.resolveContactName(isSent ? email.to : email.from);
        const bodyPreview = email.body || '';

        return this.createElement(
            'button',
            {
                className: `mail-item ${email.read ? 'read' : 'unread'}`,
                type: 'button',
                onClick: () => onEmailClick && onEmailClick(email),
                'aria-label': `Open email ${email.subject || 'No subject'}`
            },
            this.createElement('div', { className: 'mail-item-header' },
                this.createElement('strong', {}, `${isSent ? 'To' : 'From'}: ${actorName || 'Unknown'}`),
                this.createElement('span', {}, this.formatEmailTime(email.timestamp))
            ),
            this.createElement('div', { className: 'mail-item-subject' }, email.subject || 'No subject'),
            this.createElement('div', { className: 'mail-item-preview' }, bodyPreview)
        );
    }

    render() {
        const filteredEmails = this.getFilteredEmails();

        return this.createElement(
            'div',
            { className: 'mail-list-container' },
            new SearchBar({
                placeholder: 'Search mail...',
                onSearch: this.handleSearch,
                value: this.state.searchTerm
            }),
            this.createElement(
                'div',
                { className: 'mail-list', role: 'list', 'aria-label': 'Email list' },
                filteredEmails.length > 0
                    ? filteredEmails.map(this.renderEmailItem)
                    : this.createElement('div', { className: 'mail-empty' }, 'No email yet.')
            )
        );
    }
}
