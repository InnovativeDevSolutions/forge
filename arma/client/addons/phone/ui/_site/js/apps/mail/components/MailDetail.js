/** @format */

class MailDetail extends Component {
    resolveContactName(uid) {
        const contact = (this.props.contacts || []).find((entry) => entry.uid === uid || entry.id === uid);
        return contact ? contact.name : uid;
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

    componentDidMount() {
        const { email } = this.props;
        if (!email || email.read) return;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            A3API.SendAlert(JSON.stringify({
                event: 'phone::mark::email::read',
                data: { emailId: email.id }
            }));
        }
    }

    handleDeleteEmail(emailId) {
        if (!emailId) return;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            A3API.SendAlert(JSON.stringify({
                event: 'phone::delete::email',
                data: { emailId }
            }));
        }
    }

    render() {
        const { email } = this.props;

        if (!email) {
            return this.createElement('div', { className: 'mail-empty' }, 'No email selected.');
        }

        return this.createElement(
            'article',
            { className: 'mail-detail' },
            this.createElement('h2', {}, email.subject || 'No subject'),
            this.createElement('div', { className: 'mail-meta' },
                this.createElement('span', {}, `From: ${this.resolveContactName(email.from) || 'Unknown'}`),
                this.createElement('span', {}, `To: ${this.resolveContactName(email.to) || 'Unknown'}`),
                this.createElement('span', {}, this.formatEmailTime(email.timestamp))
            ),
            this.createElement('p', { className: 'mail-body' }, email.body || ''),
            this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'mail-delete-button',
                    onClick: () => this.handleDeleteEmail(email.id)
                },
                'Delete Email'
            )
        );
    }
}
