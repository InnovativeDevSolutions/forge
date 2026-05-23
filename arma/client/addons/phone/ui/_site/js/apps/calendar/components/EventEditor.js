/**
 * @format
 * @class EventEditor
 * @extends Component
 * @description A component for creating and editing calendar events.
 */

class EventEditor extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} [props.event] - Existing event to edit
     * @param {Function} props.onSave - Callback when event is saved
     * @param {Function} props.onCancel - Callback when editing is cancelled
     * @param {Function} [props.onDelete] - Callback when event is deleted
     */
    constructor(props = {}) {
        super(props);

        const existingEvent = props.event || {
            title: '',
            startTime: new Date(),
            endTime: new Date(new Date().getTime() + 60 * 60 * 1000),
            description: '',
        };

        this.state = {
            title: existingEvent.title || '',
            startTime: this.formatDateTimeForInput(existingEvent.startTime),
            endTime: this.formatDateTimeForInput(existingEvent.endTime),
            description: existingEvent.description || '',
            id: existingEvent.id || null,
            isModified: false,
        };

        // References for DOM elements
        this.titleInputRef = null;
        this.startTimeInputRef = null;
        this.endTimeInputRef = null;
        this.descriptionInputRef = null;

        // Bind methods
        this.handleTitleChange = this.handleTitleChange.bind(this);
        this.handleStartTimeChange = this.handleStartTimeChange.bind(this);
        this.handleEndTimeChange = this.handleEndTimeChange.bind(this);
        this.handleDescriptionChange = this.handleDescriptionChange.bind(this);
        this.handleSave = this.handleSave.bind(this);
        this.handleCancel = this.handleCancel.bind(this);
        this.handleDelete = this.handleDelete.bind(this);
        this.setTitleInputRef = this.setTitleInputRef.bind(this);
        this.setStartTimeInputRef = this.setStartTimeInputRef.bind(this);
        this.setEndTimeInputRef = this.setEndTimeInputRef.bind(this);
        this.setDescriptionInputRef = this.setDescriptionInputRef.bind(this);
    }

    /**
     * Component mounted - focus on title if new event
     */
    componentDidMount() {
        if (!this.state.id && this.titleInputRef) {
            this.titleInputRef.focus();
        }
    }

    // Ref setter methods
    setTitleInputRef(element) {
        if (element) {
            this.titleInputRef = element;
            if (this.state.title && element.value !== this.state.title) {
                element.value = this.state.title;
            }
        }
    }

    setStartTimeInputRef(element) {
        if (element) {
            this.startTimeInputRef = element;
            if (this.state.startTime && element.value !== this.state.startTime) {
                element.value = this.state.startTime;
            }
        }
    }

    setEndTimeInputRef(element) {
        if (element) {
            this.endTimeInputRef = element;
            if (this.state.endTime && element.value !== this.state.endTime) {
                element.value = this.state.endTime;
            }
        }
    }

    setDescriptionInputRef(element) {
        if (element) {
            this.descriptionInputRef = element;
            if (this.state.description && element.value !== this.state.description) {
                element.value = this.state.description;
            }
        }
    }

    // Input change handlers
    handleTitleChange(e) {
        this.state.title = e.target.value;
        this.state.isModified = true;
    }

    handleStartTimeChange(e) {
        this.state.startTime = e.target.value;
        this.state.isModified = true;
    }

    handleEndTimeChange(e) {
        this.state.endTime = e.target.value;
        this.state.isModified = true;
    }

    handleDescriptionChange(e) {
        this.state.description = e.target.value;
        this.state.isModified = true;
    }

    handleSave() {
        const { title, startTime, endTime, description, id } = this.state;

        // if (!title.trim() || !startTime || !endTime) {
        //     alert('Please fill in all required fields.');
        //     return;
        // }

        const savedEvent = {
            id: id || generateId(),
            title: title.trim(),
            startTime: new Date(startTime),
            endTime: new Date(endTime),
            description: description.trim(),
        };

        this.setState({
            isModified: false,
            id: savedEvent.id,
        });

        if (this.props.onSave) {
            this.props.onSave(savedEvent);
        }
    }

    handleCancel() {
        if (this.props.onCancel) {
            this.props.onCancel();
        }
    }

    handleDelete() {
        if (!this.state.id) {
            console.warn('Cannot delete event: no ID present');
            return;
        }

        if (!this.props.onDelete) {
            console.warn('Cannot delete event: no onDelete callback provided');
            return;
        }

        try {
            // Show delete confirmation modal using global state
            globalState.setState({
                showDeleteModal: true,
                eventToDelete: {
                    id: this.state.id,
                    title: this.state.title || 'Untitled',
                },
            });
        } catch (error) {
            console.error('Error showing delete confirmation:', error);
        }
    }

    formatDateTimeForInput(date) {
        // Make sure date is a valid Date object
        if (!(date instanceof Date) || isNaN(date.getTime())) {
            // If it's a string that looks like a date, try to parse it
            if (typeof date === 'string') {
                date = new Date(date);
            }
            // If still not valid, return current time
            if (!(date instanceof Date) || isNaN(date.getTime())) {
                date = new Date();
            }
        }
        return date.toISOString().slice(0, 16); // Format: YYYY-MM-DDTHH:mm
    }

    render() {
        const { title, startTime, endTime, description, id } = this.state;

        return this.createElement(
            'div',
            { className: 'event-editor' },

            // Navigation bar
            new NavigationBar({
                title: id ? 'Edit Event' : 'New Event',
                leftButton: {
                    element: 'button',
                    props: {
                        className: 'nav-button cancel-button',
                        onClick: this.handleCancel,
                        'aria-label': 'Cancel',
                    },
                    content: 'Cancel',
                },
                rightButton: {
                    element: 'button',
                    props: {
                        className: 'nav-button save-button',
                        onClick: this.handleSave,
                        'aria-label': 'Save event',
                    },
                    content: 'Save',
                },
            }),

            // Editor content
            this.createElement(
                'div',
                { className: 'event-form' },

                // Title input
                this.createElement('input', {
                    type: 'text',
                    className: 'event-title-input',
                    placeholder: 'Event title...',
                    value: title,
                    onInput: this.handleTitleChange,
                    ref: this.setTitleInputRef,
                    required: true,
                }),

                // Time inputs container
                this.createElement(
                    'div',
                    { className: 'time-container' },

                    // Start time input
                    this.createElement('input', {
                        type: 'datetime-local',
                        className: 'time-input',
                        value: startTime,
                        onInput: this.handleStartTimeChange,
                        ref: this.setStartTimeInputRef,
                        required: true,
                    }),

                    // End time input
                    this.createElement('input', {
                        type: 'datetime-local',
                        className: 'time-input',
                        value: endTime,
                        onInput: this.handleEndTimeChange,
                        ref: this.setEndTimeInputRef,
                        required: true,
                    })
                ),

                // Description textarea
                this.createElement('textarea', {
                    className: 'event-description-input',
                    placeholder: 'Add description...',
                    value: description,
                    onInput: this.handleDescriptionChange,
                    ref: this.setDescriptionInputRef,
                }),

                // Delete button (only for existing events)
                id &&
                this.createElement(
                    'button',
                    {
                        type: 'button',
                        className: 'delete-event-button',
                        onClick: this.handleDelete,
                    },
                    'Delete Event'
                )
            )
        );
    }
}
