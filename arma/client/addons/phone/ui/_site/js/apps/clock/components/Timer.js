/**
 * @format
 * @class Timer
 * @extends Component
 * @description A countdown timer component.
 */

class Timer extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            minutes: 5,
            seconds: 0,
            totalTime: 0,
            timeLeft: 0,
            isRunning: false,
            isFinished: false
        };

        // Bind methods
        this.start = this.start.bind(this);
        this.pause = this.pause.bind(this);
        this.reset = this.reset.bind(this);
        this.setTime = this.setTime.bind(this);
        this.updateTimer = this.updateTimer.bind(this);
        this.formatTime = this.formatTime.bind(this);

        // Timer interval
        this.interval = null;
    }

    /**
     * Component will unmount - clear intervals
     */
    componentWillUnmount() {
        if (this.interval) {
            clearInterval(this.interval);
        }
    }

    /**
     * Set timer duration
     */
    setTime(minutes, seconds) {
        const totalSeconds = minutes * 60 + seconds;
        this.setState({
            minutes,
            seconds,
            totalTime: totalSeconds,
            timeLeft: totalSeconds,
            isFinished: false
        });
    }

    /**
     * Start the timer
     */
    start() {
        if (this.state.timeLeft > 0 && !this.state.isRunning) {
            this.setState({ isRunning: true });
            this.interval = setInterval(this.updateTimer, 1000);
        }
    }

    /**
     * Pause the timer
     */
    pause() {
        this.setState({ isRunning: false });
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }
    }

    /**
     * Reset the timer
     */
    reset() {
        this.setState({
            timeLeft: this.state.totalTime,
            isRunning: false,
            isFinished: false
        });
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }
    }

    /**
     * Update timer countdown
     */
    updateTimer() {
        if (this.state.timeLeft > 0) {
            // Update state directly to avoid re-render during countdown
            this.state.timeLeft = this.state.timeLeft - 1;
            
            // Update only the timer display element
            const timerDisplay = document.querySelector('.timer-time');
            if (timerDisplay) {
                timerDisplay.textContent = this.formatTime(this.state.timeLeft);
            }
        } else {
            // Timer finished - this needs a full re-render
            this.setState({
                isRunning: false,
                isFinished: true
            });
            if (this.interval) {
                clearInterval(this.interval);
                this.interval = null;
            }
        }
    }

    /**
     * Format time for display
     */
    formatTime(totalSeconds) {
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }

    /**
     * Render timer controls
     */
    renderControls() {
        const { isRunning, timeLeft, isFinished } = this.state;

        return this.createElement(
            'div',
            { className: 'timer-controls' },
            
            // Start/Pause button
            timeLeft > 0 && !isFinished && this.createElement(
                'button',
                {
                    className: `control-button ${isRunning ? 'pause-button' : 'start-button'}`,
                    onClick: isRunning ? this.pause : this.start
                },
                isRunning ? 'Pause' : 'Start'
            ),
            
            // Reset button
            (timeLeft !== this.state.totalTime || isFinished) && this.createElement(
                'button',
                {
                    className: 'control-button reset-button',
                    onClick: this.reset
                },
                'Reset'
            )
        );
    }

    /**
     * Render time setters
     */
    renderTimeSetters() {
        if (this.state.isRunning) return null;

        return this.createElement(
            'div',
            { className: 'time-setters' },
            this.createElement(
                'div',
                { className: 'time-setter' },
                this.createElement('label', {}, 'Minutes'),
                this.createElement('input', {
                    type: 'number',
                    min: '0',
                    max: '59',
                    value: this.state.minutes,
                    onChange: (e) => {
                        // Update state directly to avoid re-render during input
                        const minutes = parseInt(e.target.value) || 0;
                        this.state.minutes = minutes;
                        this.setTime(minutes, this.state.seconds);
                    }
                })
            ),
            this.createElement(
                'div',
                { className: 'time-setter' },
                this.createElement('label', {}, 'Seconds'),
                this.createElement('input', {
                    type: 'number',
                    min: '0',
                    max: '59',
                    value: this.state.seconds,
                    onChange: (e) => {
                        // Update state directly to avoid re-render during input
                        const seconds = parseInt(e.target.value) || 0;
                        this.state.seconds = seconds;
                        this.setTime(this.state.minutes, seconds);
                    }
                })
            )
        );
    }

    /**
     * Render the timer component
     */
    render() {
        const { timeLeft, isFinished } = this.state;

        return this.createElement(
            'div',
            { className: 'timer' },
            
            // Timer display
            this.createElement(
                'div',
                { className: 'timer-display' },
                this.createElement(
                    'div',
                    { 
                        className: `timer-time ${isFinished ? 'finished' : ''}`,
                        'aria-live': 'polite'
                    },
                    this.formatTime(timeLeft)
                ),
                this.createElement(
                    'div',
                    { className: 'timer-status' },
                    isFinished ? 'Time\'s up!' : 'Timer'
                )
            ),
            
            // Time setters
            this.renderTimeSetters(),
            
            // Controls
            this.renderControls()
        );
    }
}

