/**
 * @format
 * @class Stopwatch
 * @extends Component
 * @description A component that provides stopwatch functionality with lap timing.
 */

class Stopwatch extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {boolean} props.format24h - Whether to use 24-hour format
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            time: 0, // Time in milliseconds
            isRunning: false,
            lapTimes: [],
            startTime: null
        };

        // Bind methods
        this.start = this.start.bind(this);
        this.stop = this.stop.bind(this);
        this.reset = this.reset.bind(this);
        this.lap = this.lap.bind(this);
        this.updateTime = this.updateTime.bind(this);
        this.formatTime = this.formatTime.bind(this);

        // Timer for updates
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
     * Start the stopwatch
     */
    start() {
        if (!this.state.isRunning) {
            const startTime = Date.now() - this.state.time;
            this.setState({
                isRunning: true,
                startTime: startTime
            });
            
            this.interval = setInterval(this.updateTime, 10); // Update every 10ms for precision
        }
    }

    /**
     * Stop the stopwatch
     */
    stop() {
        if (this.state.isRunning) {
            this.setState({ isRunning: false });
            if (this.interval) {
                clearInterval(this.interval);
                this.interval = null;
            }
        }
    }

    /**
     * Reset the stopwatch
     */
    reset() {
        this.setState({
            time: 0,
            isRunning: false,
            lapTimes: [],
            startTime: null
        });
        
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }
    }

    /**
     * Record a lap time
     */
    lap() {
        if (this.state.isRunning) {
            const currentTime = this.state.time;
            const previousLapTime = this.state.lapTimes.length > 0 
                ? this.state.lapTimes[this.state.lapTimes.length - 1].totalTime
                : 0;
            
            const lapTime = {
                id: generateId(),
                lapNumber: this.state.lapTimes.length + 1,
                lapTime: currentTime - previousLapTime,
                totalTime: currentTime,
                timestamp: new Date().toISOString()
            };
            
            this.setState({
                lapTimes: [...this.state.lapTimes, lapTime]
            });
        }
    }

    /**
     * Update the current time
     */
    updateTime() {
        if (this.state.isRunning && this.state.startTime) {
            const currentTime = Date.now() - this.state.startTime;
            // Update state directly to avoid re-render during stopwatch running
            this.state.time = currentTime;
            
            // Update only the stopwatch time display element
            const stopwatchDisplay = document.querySelector('.stopwatch-time');
            if (stopwatchDisplay) {
                stopwatchDisplay.textContent = this.formatTime(currentTime);
            }
        }
    }

    /**
     * Format time for display (HH:MM:SS.mmm)
     */
    formatTime(milliseconds) {
        const totalSeconds = Math.floor(milliseconds / 1000);
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        const ms = Math.floor((milliseconds % 1000) / 10); // Show centiseconds
        
        return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}.${ms.toString().padStart(2, '0')}`;
    }

    /**
     * Get the fastest and slowest lap times
     */
    getLapStats() {
        if (this.state.lapTimes.length === 0) return null;
        
        const lapTimes = this.state.lapTimes.map(lap => lap.lapTime);
        const fastest = Math.min(...lapTimes);
        const slowest = Math.max(...lapTimes);
        
        return {
            fastest: this.state.lapTimes.find(lap => lap.lapTime === fastest),
            slowest: this.state.lapTimes.find(lap => lap.lapTime === slowest)
        };
    }

    /**
     * Render the main stopwatch display
     */
    renderStopwatchDisplay() {
        const { time, isRunning } = this.state;
        
        return this.createElement(
            'div',
            { className: 'stopwatch-display' },
            this.createElement(
                'div',
                { 
                    className: `stopwatch-time ${isRunning ? 'running' : 'stopped'}`,
                    'aria-live': 'polite',
                    'aria-label': 'Stopwatch time'
                },
                this.formatTime(time)
            ),
            this.createElement(
                'div',
                { className: 'stopwatch-status' },
                isRunning ? 'Running' : (time > 0 ? 'Stopped' : 'Ready')
            )
        );
    }

    /**
     * Render control buttons
     */
    renderControls() {
        const { isRunning, time } = this.state;
        
        return this.createElement(
            'div',
            { className: 'stopwatch-controls' },
            
            // Start/Stop button
            this.createElement(
                'button',
                {
                    className: `control-button ${isRunning ? 'stop-button' : 'start-button'}`,
                    onClick: isRunning ? this.stop : this.start,
                    'aria-label': isRunning ? 'Stop stopwatch' : 'Start stopwatch'
                },
                isRunning ? 'Stop' : 'Start'
            ),
            
            // Lap button (only when running)
            isRunning && this.createElement(
                'button',
                {
                    className: 'control-button lap-button',
                    onClick: this.lap,
                    'aria-label': 'Record lap time'
                },
                'Lap'
            ),
            
            // Reset button (only when stopped and time > 0)
            !isRunning && time > 0 && this.createElement(
                'button',
                {
                    className: 'control-button reset-button',
                    onClick: this.reset,
                    'aria-label': 'Reset stopwatch'
                },
                'Reset'
            )
        );
    }

    /**
     * Render lap times list
     */
    renderLapTimes() {
        const { lapTimes } = this.state;
        
        if (lapTimes.length === 0) {
            return null;
        }
        
        const stats = this.getLapStats();
        
        return this.createElement(
            'div',
            { className: 'lap-times-section' },
            this.createElement(
                'h3',
                { className: 'lap-times-title' },
                'Lap Times'
            ),
            
            // Lap times list
            this.createElement(
                'div',
                { className: 'lap-times-list' },
                ...lapTimes.slice().reverse().map(lap => {
                    const isFastest = stats && lap.id === stats.fastest.id;
                    const isSlowest = stats && lap.id === stats.slowest.id && lapTimes.length > 1;
                    
                    return this.createElement(
                        'div',
                        {
                            className: `lap-time-item ${
                                isFastest ? 'fastest' : isSlowest ? 'slowest' : ''
                            }`,
                            key: lap.id
                        },
                        this.createElement(
                            'div',
                            { className: 'lap-number' },
                            `Lap ${lap.lapNumber}`
                        ),
                        this.createElement(
                            'div',
                            { className: 'lap-time' },
                            this.formatTime(lap.lapTime)
                        ),
                        this.createElement(
                            'div',
                            { className: 'total-time' },
                            this.formatTime(lap.totalTime)
                        ),
                        (isFastest || isSlowest) && this.createElement(
                            'div',
                            { className: 'lap-indicator' },
                            isFastest ? 'Fastest' : 'Slowest'
                        )
                    );
                })
            )
        );
    }

    /**
     * Render the stopwatch component
     */
    render() {
        return this.createElement(
            'div',
            { className: 'stopwatch' },
            
            // Main stopwatch display
            this.renderStopwatchDisplay(),
            
            // Control buttons
            this.renderControls(),
            
            // Lap times
            this.renderLapTimes()
        );
    }
}

