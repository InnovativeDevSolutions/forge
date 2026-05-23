/**
 * @format
 * @class AlarmClock
 * @extends Component
 * @description A component for managing alarms.
 */

class AlarmClock extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            showAddForm: false,
            newAlarmTime: '07:00',
            newAlarmLabel: ''
        };

        // Bind methods
        this.toggleAddForm = this.toggleAddForm.bind(this);
        this.handleAddAlarm = this.handleAddAlarm.bind(this);
        this.formatTime = this.formatTime.bind(this);
    }

    /**
     * Toggle add alarm form
     */
    toggleAddForm() {
        // Use setState for form visibility changes as they need re-render
        this.setState({ 
            showAddForm: !this.state.showAddForm,
            newAlarmTime: '07:00',
            newAlarmLabel: ''
        });
    }

    /**
     * Handle adding a new alarm
     */
    handleAddAlarm() {
        const newAlarmTime = this.state.newAlarmTime;
        const newAlarmLabel = this.state.newAlarmLabel;
        if (newAlarmTime && this.props.onAddAlarm) {
            this.props.onAddAlarm({
                time: newAlarmTime,
                label: newAlarmLabel || 'Alarm',
                enabled: true,
                days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'] // Default to weekdays
            });
            // Use setState to hide form and reset state
            this.setState({
                showAddForm: false,
                newAlarmTime: '07:00',
                newAlarmLabel: ''
            });
        }
    }

    /**
     * Format time for display
     */
    formatTime(timeString) {
        const [hours, minutes] = timeString.split(':');
        if (this.props.format24h) {
            return `${hours}:${minutes}`;
        } else {
            const hour = parseInt(hours);
            const ampm = hour >= 12 ? 'PM' : 'AM';
            const displayHour = hour % 12 || 12;
            return `${displayHour}:${minutes} ${ampm}`;
        }
    }

    /**
     * Render add alarm form
     */
    renderAddForm() {
        if (!this.state.showAddForm) return null;

        return this.createElement(
            'div',
            { className: 'add-alarm-form' },
            this.createElement('h3', {}, 'Add Alarm'),
            
            this.createElement('input', {
                type: 'time',
                value: this.state.newAlarmTime,
                onChange: (e) => {
                    // Update state directly to avoid re-render during input
                    this.state.newAlarmTime = e.target.value;
                }
            }),
            
            this.createElement('input', {
                type: 'text',
                placeholder: 'Alarm label (optional)',
                value: this.state.newAlarmLabel,
                onChange: (e) => {
                    // Update state directly to avoid re-render during input
                    this.state.newAlarmLabel = e.target.value;
                }
            }),
            
            this.createElement(
                'div',
                { className: 'form-buttons' },
                this.createElement(
                    'button',
                    { onClick: this.toggleAddForm },
                    'Cancel'
                ),
                this.createElement(
                    'button',
                    { onClick: this.handleAddAlarm },
                    'Add Alarm'
                )
            )
        );
    }

    /**
     * Render alarms list
     */
    renderAlarms() {
        const { alarms } = this.props;

        if (!alarms || alarms.length === 0) {
            return this.createElement(
                'div',
                { className: 'empty-state' },
                this.createElement('p', {}, 'No alarms set. Tap + to add one.')
            );
        }

        return this.createElement(
            'div',
            { className: 'alarms-list' },
            ...alarms.map(alarm => 
                this.createElement(
                    'div',
                    {
                        className: `alarm-item ${alarm.enabled ? 'enabled' : 'disabled'}`,
                        key: alarm.id
                    },
                    this.createElement(
                        'div',
                        { className: 'alarm-info' },
                        this.createElement(
                            'div',
                            { className: 'alarm-time' },
                            this.formatTime(alarm.time)
                        ),
                        this.createElement(
                            'div',
                            { className: 'alarm-label' },
                            alarm.label
                        ),
                        alarm.days && this.createElement(
                            'div',
                            { className: 'alarm-days' },
                            alarm.days.join(', ')
                        )
                    ),
                    this.createElement(
                        'div',
                        { className: 'alarm-controls' },
                        this.createElement(
                            'button',
                            {
                                className: 'toggle-alarm',
                                onClick: () => this.props.onToggleAlarm(alarm.id)
                            },
                            alarm.enabled ? 'On' : 'Off'
                        ),
                        this.createElement(
                            'button',
                            {
                                className: 'remove-alarm',
                                onClick: () => this.props.onRemoveAlarm(alarm.id),
                                'aria-label': 'Delete alarm'
                            },
                            'Delete'
                        )
                    )
                )
            )
        );
    }

    /**
     * Render the alarm clock component
     */
    render() {
        return this.createElement(
            'div',
            { className: 'alarm-clock' },
            
            // Add alarm button
            !this.state.showAddForm && this.createElement(
                'button',
                {
                    className: 'add-alarm-button',
                    onClick: this.toggleAddForm
                },
                '+ Add Alarm'
            ),
            
            // Add alarm form
            this.renderAddForm(),
            
            // Alarms list
            this.renderAlarms()
        );
    }
}

