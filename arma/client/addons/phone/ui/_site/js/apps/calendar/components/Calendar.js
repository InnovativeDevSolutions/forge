/**
 * @format
 * @fileoverview Calendar component for displaying and managing calendar events
 */

class Calendar extends Component {
    constructor(props = {}) {
        super(props);

        let selectedDate = props.selectedDate;
        if (!(selectedDate instanceof Date) || isNaN(selectedDate.getTime())) {
            selectedDate = new Date();
        }

        this.state = {
            currentDate: props.selectedDate || new Date(),
            selectedDate: props.selectedDate || new Date(),
            events: props.events || [],
        };

        this.onEventClick = props.onEventClick;
        this.onDayClick = props.onDayClick;

        this.handleDayClick = this.handleDayClick.bind(this);
        this.handleEventClick = this.handleEventClick.bind(this);
    }

    /**
     * Called when the component is first mounted to the DOM.
     * Ensures the initial view is rendered.
     */
    componentDidMount() {
        this.render(); // Initial render after component is mounted
    }

    /**
     * Called when the component's state or props change.
     * Updates the component if necessary.
     */
    componentDidUpdate(prevProps, prevState) {
        // Re-render if selectedDate or events have changed significantly
        if (
            prevState.selectedDate.toDateString() !== this.state.selectedDate.toDateString() ||
            JSON.stringify(prevState.events) !== JSON.stringify(this.state.events) ||
            prevState.currentDate.toDateString() !== this.state.currentDate.toDateString()
        ) {
            this.render();
        }
    }

    render() {
        const { currentDate } = this.state;
        const year = currentDate.getFullYear();
        const month = currentDate.getMonth();

        return this.createElement(
            'div',
            { className: 'calendar-container' },

            this.createElement('div', { className: 'calendar-header' }, this.createElement('div', { className: 'calendar-title' }, `${this.getMonthName(month)} ${year}`)),

            this.createElement('div', { className: 'calendar-grid' }, this.renderWeekdays(), this.renderDays(year, month)),

            this.createElement('div', { className: 'calendar-events' }, this.renderEvents())
        );
    }

    renderWeekdays() {
        const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        return weekdays.map((day) => this.createElement('div', { className: 'calendar-weekday' }, day));
    }

    renderDays(year, month) {
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const startingDay = firstDay.getDay();
        const totalDays = lastDay.getDate();

        let days = [];

        // Previous month's days (empty placeholders or actual days if needed, currently empty for visual alignment)
        for (let i = 0; i < startingDay; i++) {
            days.push(this.createElement('div', { className: 'calendar-day other-month' }));
        }

        // Current month's days
        for (let day = 1; day <= totalDays; day++) {
            const date = new Date(year, month, day);
            const isToday = this.isToday(date);
            const isSelected = this.isSelected(date);
            const hasEvents = this.hasEvents(date);

            let classes = ['calendar-day'];
            if (isToday) classes.push('today');
            if (isSelected) classes.push('selected');
            if (hasEvents) classes.push('has-events');

            days.push(
                this.createElement(
                    'div',
                    {
                        className: classes.join(' '),
                        'data-date': date.toISOString(),
                        onClick: () => this.handleDayClick(date),
                    },
                    day
                )
            );
        }

        // Next month's days (empty placeholders for visual alignment)
        const remainingCells = 42 - days.length; // 42 = 6 rows * 7 days
        for (let i = 0; i < remainingCells; i++) {
            days.push(this.createElement('div', { className: 'calendar-day other-month' }));
        }

        return days;
    }

    renderEvents() {
        const events = this.getEventsForDate(this.state.selectedDate);
        if (!events || events.length === 0) {
            return this.createElement('div', { className: 'no-events' }, 'No events for this day');
        }

        return events.map((event) =>
            this.createElement(
                'div',
                {
                    className: 'event-item',
                    'data-event-id': event.id,
                    onClick: () => this.handleEventClick(event),
                },
                this.createElement('div', { className: 'event-dot' }),
                this.createElement('div', { className: 'event-time' }, this.formatTime(event.startTime)),
                this.createElement('div', { className: 'event-title' }, event.title)
            )
        );
    }

    handleDayClick(date) {
        this.setState({ selectedDate: date });

        if (this.onDayClick) {
            this.onDayClick(date);
        }
    }

    handleEventClick(event) {
        if (this.onEventClick) {
            this.onEventClick(event);
        }
    }

    getEventsForDate(date) {
        const dateKey = this.getDateKey(date);
        return this.state.events.filter((event) => {
            const eventStartDate = new Date(event.startTime);
            return this.getDateKey(eventStartDate) === dateKey;
        });
    }

    hasEvents(date) {
        return this.getEventsForDate(date).length > 0;
    }

    getDateKey(date) {
        return date.toISOString().split('T')[0];
    }

    isToday(date) {
        const today = new Date();
        return date.toDateString() === today.toDateString();
    }

    isSelected(date) {
        return date.toDateString() === this.state.selectedDate.toDateString();
    }

    getMonthName(month) {
        return new Date(2000, month, 1).toLocaleString('default', { month: 'long' });
    }

    formatTime(time) {
        return new Date(time).toLocaleTimeString('default', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
        });
    }
}
