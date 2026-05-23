/**
 * @format
 * @class WorldClock
 * @extends Component
 * @description A component that displays multiple world clocks for different time zones.
 */

class WorldClock extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array} props.clocks - Array of world clock objects
     * @param {boolean} props.format24h - Whether to use 24-hour format
     * @param {Function} props.onAddClock - Callback when adding a new clock
     * @param {Function} props.onRemoveClock - Callback when removing a clock
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            currentTime: new Date(),
            showAddForm: false,
            selectedTimezone: ''
        };

        // Bind methods
        this.updateTime = this.updateTime.bind(this);
        this.toggleAddForm = this.toggleAddForm.bind(this);
        this.handleAddClock = this.handleAddClock.bind(this);
        this.handleRemoveClock = this.handleRemoveClock.bind(this);
        this.formatTime = this.formatTime.bind(this);
        this.getTimezoneTime = this.getTimezoneTime.bind(this);

        // Timer for real-time updates
        this.timeUpdateInterval = null;

        // Popular time zones
        this.popularTimezones = [
            'America/New_York',
            'America/Los_Angeles',
            'America/Chicago',
            'Europe/London',
            'Europe/Paris',
            'Europe/Berlin',
            'Asia/Tokyo',
            'Asia/Shanghai',
            'Asia/Kolkata',
            'Australia/Sydney',
            'Pacific/Auckland',
            'Africa/Cairo',
            'America/Sao_Paulo',
            'Asia/Dubai',
            'Europe/Moscow'
        ];
    }

    /**
     * Component mounted - start time updates
     */
    componentDidMount() {
        this.timeUpdateInterval = setInterval(this.updateTime, 1000);
    }

    /**
     * Component will unmount - clear intervals
     */
    componentWillUnmount() {
        if (this.timeUpdateInterval) {
            clearInterval(this.timeUpdateInterval);
        }
    }

    /**
     * Update current time
     */
    updateTime() {
        // Update state directly to avoid re-render during time updates
        this.state.currentTime = new Date();
        const currentTime = this.state.currentTime;
        
        // Update local time display
        const localTimeElement = document.querySelector('.local-time');
        if (localTimeElement) {
            const timeOptions = {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: !this.props.format24h
            };
            localTimeElement.textContent = currentTime.toLocaleTimeString('en-US', timeOptions);
        }
        
        // Update all world clock time displays
        const worldClockItems = document.querySelectorAll('.world-clock-item');
        worldClockItems.forEach((clockItem, index) => {
            const clockTimeElement = clockItem.querySelector('.clock-time');
            const clockDateElement = clockItem.querySelector('.clock-date');
            
            if (clockTimeElement && this.props.clocks && this.props.clocks[index]) {
                const timezone = this.props.clocks[index].timezone;
                
                // Update time
                try {
                    const timeOptions = {
                        timeZone: timezone,
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                        hour12: !this.props.format24h
                    };
                    clockTimeElement.textContent = currentTime.toLocaleTimeString('en-US', timeOptions);
                } catch (error) {
                    clockTimeElement.textContent = '--:--:--';
                }
                
                // Update date
                if (clockDateElement) {
                    try {
                        const dateOptions = {
                            timeZone: timezone,
                            weekday: 'short',
                            month: 'short',
                            day: 'numeric'
                        };
                        clockDateElement.textContent = currentTime.toLocaleDateString('en-US', dateOptions);
                    } catch (error) {
                        clockDateElement.textContent = 'Invalid date';
                    }
                }
            }
        });
    }

    /**
     * Toggle add clock form
     */
    toggleAddForm() {
        // Use setState for form visibility changes as they need re-render
        this.setState({ 
            showAddForm: !this.state.showAddForm,
            selectedTimezone: '' // Reset selection when toggling
        });
    }

    /**
     * Handle adding a new clock
     */
    handleAddClock() {
        const selectedTimezone = this.state.selectedTimezone;
        if (selectedTimezone && this.props.onAddClock) {
            this.props.onAddClock(selectedTimezone);
            // Use setState to hide form and reset state
            this.setState({
                showAddForm: false,
                selectedTimezone: ''
            });
        }
    }

    /**
     * Handle removing a clock
     */
    handleRemoveClock(clockId) {
        if (this.props.onRemoveClock) {
            this.props.onRemoveClock(clockId);
        }
    }

    /**
     * Get time for a specific timezone
     */
    getTimezoneTime(timezone) {
        try {
            return new Date().toLocaleString('en-US', {
                timeZone: timezone,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: !this.props.format24h
            });
        } catch (error) {
            return 'Invalid timezone';
        }
    }

    /**
     * Format time for display
     */
    formatTime(date, timezone) {
        try {
            const options = {
                timeZone: timezone,
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: !this.props.format24h
            };
            return date.toLocaleTimeString('en-US', options);
        } catch (error) {
            return '--:--:--';
        }
    }

    /**
     * Get date for timezone
     */
    getTimezoneDate(timezone) {
        try {
            return new Date().toLocaleDateString('en-US', {
                timeZone: timezone,
                weekday: 'short',
                month: 'short',
                day: 'numeric'
            });
        } catch (error) {
            return 'Invalid date';
        }
    }

    /**
     * Render local time section
     */
    renderLocalTime() {
        const { currentTime } = this.state;
        const { format24h } = this.props;
        
        const timeOptions = {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: !format24h
        };
        
        const dateOptions = {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        };

        return this.createElement(
            'div',
            { className: 'local-time-section' },
            this.createElement(
                'h2',
                { className: 'local-time-label' },
                'Local Time'
            ),
            this.createElement(
                'div',
                { className: 'local-time-display' },
                this.createElement(
                    'div',
                    { className: 'local-time' },
                    currentTime.toLocaleTimeString('en-US', timeOptions)
                ),
                this.createElement(
                    'div',
                    { className: 'local-date' },
                    currentTime.toLocaleDateString('en-US', dateOptions)
                )
            )
        );
    }

    /**
     * Render add clock form
     */
    renderAddForm() {
        if (!this.state.showAddForm) return null;

        return this.createElement(
            'div',
            { className: 'add-clock-form' },
            this.createElement(
                'h3',
                {},
                'Add World Clock'
            ),
            this.createElement(
                'select',
                {
                    className: 'timezone-select',
                    value: this.state.selectedTimezone,
                    onChange: (e) => {
                        // Update state directly to avoid re-render during selection
                        this.state.selectedTimezone = e.target.value;
                        
                        // Update button disabled state directly
                        const addButton = document.querySelector('.add-button');
                        if (addButton) {
                            addButton.disabled = !e.target.value;
                        }
                    }
                },
                this.createElement('option', { value: '' }, 'Select a timezone...'),
                ...this.popularTimezones.map(tz => 
                    this.createElement(
                        'option',
                        { value: tz, key: tz },
                        tz.replace('_', ' ').split('/').join(' - ')
                    )
                )
            ),
            this.createElement(
                'div',
                { className: 'form-buttons' },
                this.createElement(
                    'button',
                    {
                        type: 'button',
                        onClick: this.toggleAddForm,
                        className: 'cancel-button'
                    },
                    'Cancel'
                ),
                this.createElement(
                    'button',
                    {
                        type: 'button',
                        onClick: this.handleAddClock,
                        className: 'add-button',
                        disabled: !this.state.selectedTimezone
                    },
                    'Add Clock'
                )
            )
        );
    }

    /**
     * Render world clocks list
     */
    renderWorldClocks() {
        const { clocks } = this.props;
        const { currentTime } = this.state;

        if (!clocks || clocks.length === 0) {
            return this.createElement(
                'div',
                { className: 'empty-state' },
                this.createElement(
                    'p',
                    {},
                    'No world clocks added yet. Tap + to add one.'
                )
            );
        }

        return this.createElement(
            'div',
            { className: 'world-clocks-list' },
            ...clocks.map(clock => 
                this.createElement(
                    'div',
                    {
                        className: 'world-clock-item',
                        key: clock.id
                    },
                    this.createElement(
                        'div',
                        { className: 'clock-info' },
                        this.createElement(
                            'div',
                            { className: 'clock-city' },
                            clock.city
                        ),
                        this.createElement(
                            'div',
                            { className: 'clock-timezone' },
                            clock.timezone.split('/').join(' / ')
                        )
                    ),
                    this.createElement(
                        'div',
                        { className: 'clock-time-info' },
                        this.createElement(
                            'div',
                            { className: 'clock-time' },
                            this.formatTime(currentTime, clock.timezone)
                        ),
                        this.createElement(
                            'div',
                            { className: 'clock-date' },
                            this.getTimezoneDate(clock.timezone)
                        )
                    ),
                    this.createElement(
                        'button',
                        {
                            className: 'remove-clock-button',
                            onClick: () => this.handleRemoveClock(clock.id),
                            'aria-label': `Remove ${clock.city} clock`
                        },
                        'Remove'
                    )
                )
            )
        );
    }

    /**
     * Render the world clock component
     */
    render() {
        return this.createElement(
            'div',
            { className: 'world-clock' },
            
            // Local time section
            this.renderLocalTime(),
            
            // Add clock button
            !this.state.showAddForm && this.createElement(
                'button',
                {
                    className: 'add-world-clock-button',
                    onClick: this.toggleAddForm
                },
                '+ Add World Clock'
            ),
            
            // Add clock form
            this.renderAddForm(),
            
            // World clocks list
            this.renderWorldClocks()
        );
    }
}

