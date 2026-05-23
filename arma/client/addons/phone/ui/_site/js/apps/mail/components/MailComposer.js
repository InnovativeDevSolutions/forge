/** @format */

class MailComposer extends Component {
    constructor(props = {}) {
        super(props);
        const contacts = this.emailableContacts(props.contacts || []);
        const defaultRecipient = contacts.length === 1 ? (contacts[0].uid || contacts[0].id || '') : '';
        this.state = {
            toUid: defaultRecipient,
            subject: '',
            body: ''
        };

        this.toRef = null;
        this.subjectRef = null;
        this.bodyRef = null;
        this.lastSendAt = 0;

        this.handleSend = this.handleSend.bind(this);
        this.syncSubject = this.syncSubject.bind(this);
        this.syncBody = this.syncBody.bind(this);
    }

    emailableContacts(contacts = []) {
        return contacts.filter((contact) => contact && contact.canEmail !== false && (contact.uid || contact.id));
    }

    readField(id, ref, fallback = '') {
        const scopedElement = this.element ? this.element.querySelector(`#${id}`) : null;
        const documentElement = typeof document !== 'undefined' ? document.getElementById(id) : null;
        const element = scopedElement || documentElement || ref;
        if (!element) return fallback;

        if (typeof element.value === 'string' && element.value.length > 0) {
            return element.value;
        }

        if (typeof element.textContent === 'string' && element.textContent.length > 0) {
            return element.textContent;
        }

        return fallback;
    }

    syncSubject(event) {
        this.state.subject = event?.target?.value || '';
    }

    syncBody(event) {
        this.state.body = event?.target?.value || '';
    }

    handleSend(event) {
        event?.preventDefault?.();
        event?.stopPropagation?.();

        const now = Date.now();
        if (now - this.lastSendAt < 500) return;

        const toUid = this.readField('phone-mail-recipient', this.toRef, this.state.toUid).trim();
        const subject = this.readField('phone-mail-subject', this.subjectRef, this.state.subject).trim() || 'No subject';
        const body = this.readField('phone-mail-body', this.bodyRef, this.state.body).trim();

        if (!toUid || !body) {
            console.warn('MailComposer: missing required email fields', {
                hasRecipient: !!toUid,
                hasSubject: subject !== 'No subject',
                hasBody: !!body,
                toUid,
                subjectLength: subject.length,
                bodyLength: body.length
            });
            return;
        }

        this.lastSendAt = now;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            console.log('MailComposer: sending email', { toUid, subjectLength: subject.length, bodyLength: body.length });
            A3API.SendAlert(JSON.stringify({
                event: 'phone::send::email',
                data: { toUid, subject, body }
            }));
        } else {
            console.warn('MailComposer: A3API.SendAlert unavailable');
        }

        globalState.setState({
            showEmailComposer: false,
            selectedEmail: null
        });
    }

    renderContactOptions() {
        const contacts = this.emailableContacts(this.props.contacts || []);

        return [
            this.createElement('option', { value: '' }, 'Select recipient'),
            ...contacts.map((contact) => this.createElement(
                'option',
                { value: contact.uid || contact.id },
                `${contact.fullName || contact.name || 'Unknown'}${contact.email ? ` (${contact.email})` : ''}`
            ))
        ];
    }

    render() {
        return this.createElement(
            'div',
            { className: 'mail-composer' },
            this.createElement('label', {},
                'To',
                this.createElement(
                    'select',
                    {
                        id: 'phone-mail-recipient',
                        name: 'phone-mail-recipient',
                        value: this.state.toUid,
                        onInput: (event) => { this.state.toUid = event.target.value; },
                        onChange: (event) => { this.state.toUid = event.target.value; },
                        ref: (element) => {
                            this.toRef = element;
                            if (element && this.state.toUid && !element.value) {
                                element.value = this.state.toUid;
                            }
                        },
                        'aria-label': 'Email recipient'
                    },
                    ...this.renderContactOptions()
                )
            ),
            this.createElement('label', {},
                'Subject',
                this.createElement('input', {
                    id: 'phone-mail-subject',
                    name: 'phone-mail-subject',
                    type: 'text',
                    value: this.state.subject,
                    onInput: this.syncSubject,
                    onChange: this.syncSubject,
                    onKeyUp: this.syncSubject,
                    ref: (element) => { this.subjectRef = element; },
                    placeholder: 'Subject'
                })
            ),
            this.createElement('label', {},
                'Message',
                this.createElement('textarea', {
                    id: 'phone-mail-body',
                    name: 'phone-mail-body',
                    value: this.state.body,
                    onInput: this.syncBody,
                    onChange: this.syncBody,
                    onKeyUp: this.syncBody,
                    ref: (element) => { this.bodyRef = element; },
                    placeholder: 'Write email body...',
                    rows: 8
                })
            ),
            this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'mail-send-button',
                    onClick: this.handleSend,
                    onMouseDown: this.handleSend
                },
                'Send'
            )
        );
    }
}
