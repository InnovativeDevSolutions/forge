/** @format */

/**
 * @class StatusBar
 * @extends Component
 * @description A component that displays the status bar at the top of the phone interface.
 * Shows current time, signal strength, network status, and battery indicator.
 */
class StatusBar extends Component {
    /**
     * Cache for loaded icons
     * @static
     * @private
     */
    static iconCache = new Map();

    /**
     * Time update interval in milliseconds
     * @static
     * @private
     */
    static TIME_UPDATE_INTERVAL = 1000;

    /**
     * @constructor
     * @param {Object} props - Component properties
     */
    constructor(props) {
        super(props);
        this.state = {
            currentTime: this.getCurrentTime(),
        };
        this.timerInterval = null;
    }

    /**
     * Start the timer when component mounts
     * @lifecycle
     */
    componentDidMount() {
        if (!this.timerInterval) {
            this.timerInterval = setInterval(() => {
                this.setState({ currentTime: this.getCurrentTime() });
            }, StatusBar.TIME_UPDATE_INTERVAL);
        }
    }

    /**
     * Clean up timer when component unmounts
     * @lifecycle
     */
    componentWillUnmount() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
    }

    /**
     * Get the current time in 24-hour format
     * @returns {string} Formatted time string (HH:mm)
     * @private
     */
    getCurrentTime() {
        return new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false,
        });
    }

    /**
     * Render signal strength indicator
     * @returns {HTMLElement} Signal bars element
     * @private
     */
    renderSignalBars() {
        return this.createElement(
            'div',
            {
                className: 'signal-bars',
                'aria-label': 'Signal strength indicator',
                role: 'meter',
                'aria-valuenow': '4',
                'aria-valuemin': '0',
                'aria-valuemax': '4',
            },
            Array(4)
                .fill(null)
                .map(() =>
                    this.createElement('div', {
                        className: 'bar',
                        'aria-hidden': 'true',
                    })
                )
        );
    }

    /**
     * Render battery icon
     * @returns {HTMLElement} Battery icon element
     * @private
     */
    renderBatteryIcon() {
        return this.createElement('span', {
            className: 'battery-icon',
            role: 'img',
            'aria-label': 'Battery full'
        });
    }

    /**
     * Render status indicators (network and battery)
     * @returns {HTMLElement} Status indicators element
     * @private
     */
    renderStatusIndicators() {
        return this.createElement(
            'div',
            { className: 'status-indicators' },
            this.renderSignalBars(),
            this.createElement(
                'span',
                {
                    className: 'network-battery',
                    'aria-label': 'Network: 5G, Battery: Full',
                },
                '5G',
                this.renderBatteryIcon()
            )
        );
    }

    /**
     * Render the status bar
     * @returns {HTMLElement} The rendered status bar element
     */
    render() {
        const { currentTime } = this.state;

        return this.createElement(
            'div',
            {
                className: 'status-bar',
                role: 'banner',
                'aria-label': 'Status bar',
            },
            this.createElement(
                'div',
                {
                    className: 'status-left',
                    role: 'timer',
                    'aria-label': 'Current time',
                },
                currentTime
            ),
            this.createElement('div', {
                className: 'status-center',
                'aria-hidden': 'true',
            }),
            this.createElement('div', { className: 'status-right' }, this.renderStatusIndicators())
        );
    }
}
