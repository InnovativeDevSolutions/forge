/** @format */

/**
 * @class AddContactForm
 * @extends Component
 * @description A form component for adding new contacts to the phone app.
 * Manages its own state for form inputs and handles contact creation.
 */
class AddContactForm extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Function} [props.onAdd] - Callback function called when a new contact is added
     */
    constructor(props) {
        super(props);

        // Initialize form state
        this.state = {
            name: '',
            phone: '',
        };

        // Create refs for input elements
        this.nameInputRef = null;
        this.phoneInputRef = null;

        // Bind methods
        this.handleAddContact = this.handleAddContact.bind(this);
        this.handleNameChange = this.handleNameChange.bind(this);
        this.handlePhoneChange = this.handlePhoneChange.bind(this);
        this.setNameInputRef = this.setNameInputRef.bind(this);
        this.setPhoneInputRef = this.setPhoneInputRef.bind(this);
    }

    /**
     * Store reference to the name input element
     * @param {HTMLInputElement} element - The input DOM element
     */
    setNameInputRef(element) {
        if (element) {
            this.nameInputRef = element;
        }
    }

    /**
     * Store reference to the phone input element
     * @param {HTMLInputElement} element - The input DOM element
     */
    setPhoneInputRef(element) {
        if (element) {
            this.phoneInputRef = element;
        }
    }

    /**
     * Handle changes to the name input
     * @param {Event} e - Input change event
     */
    handleNameChange(e) {
        // Update state directly to avoid re-render
        this.state.name = e.target.value;
    }

    /**
     * Handle changes to the phone input
     * @param {Event} e - Input change event
     */
    handlePhoneChange(e) {
        // Update state directly to avoid re-render
        this.state.phone = e.target.value;
    }

    /**
     * Handle add contact button click
     */
    handleAddContact() {
        const { name, phone } = this.state;

        if (name.trim() && phone.trim()) {
            const currentState = globalState.getState();
            const trimmedName = name.trim();
            const trimmedPhone = phone.trim();
            
            // Check if contact already exists (by name or phone)
            const contactExists = currentState.contacts.some(contact => 
                contact.name.toLowerCase() === trimmedName.toLowerCase() || 
                contact.phone === trimmedPhone
            );
            
            if (contactExists) {
                console.warn('Contact already exists with this name or phone number');
                // You could show a user-friendly message here
                return;
            }

            // Server owns the actual contact entry; name is only used for local duplicate checks.
            if (typeof A3API !== 'undefined' && A3API.SendAlert) {
                A3API.SendAlert(JSON.stringify({
                    event: "phone::add::contact::by::phone",
                    data: {
                        name: trimmedName,
                        phone: trimmedPhone
                    }
                }));
            }

            // Reset form state and input values
            this.state.name = '';
            this.state.phone = '';

            if (this.nameInputRef) {
                this.nameInputRef.value = '';
            }
            if (this.phoneInputRef) {
                this.phoneInputRef.value = '';
            }

            // Focus back on name input for quick consecutive entries
            if (this.nameInputRef) {
                this.nameInputRef.focus();
            }

            // Notify parent component if callback provided
            if (this.props.onAdd) {
                this.props.onAdd({ name: trimmedName, phone: trimmedPhone });
            }
        }
    }

    /**
     * Render the form
     * @returns {HTMLElement} The rendered form element
     */
    render() {
        return this.createElement(
            'div',
            {
                className: 'add-contact-form',
            },
            this.createElement(
                'h3',
                {
                    style: { marginBottom: '15px' },
                },
                'Add New Contact'
            ),
            this.createElement('input', {
                type: 'text',
                placeholder: 'Name',
                ref: this.setNameInputRef,
                onInput: this.handleNameChange
            }),
            this.createElement('input', {
                type: 'tel',
                placeholder: 'Phone Number',
                ref: this.setPhoneInputRef,
                onInput: this.handlePhoneChange
            }),
            this.createElement(
                'button',
                {
                    type: 'button',
                    onClick: this.handleAddContact
                },
                'Add Contact'
            )
        );
    }
}
