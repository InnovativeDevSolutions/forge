/**
 * @fileoverview Main entry point for the Clock application
 *
 * This module initializes the Clock app UI, including:
 * - Multiple clock modes (World Clock, Stopwatch, Timer, Alarm)
 * - Tab-based navigation between different clock features
 * - Real-time updates and time synchronization
 * - Persistent settings and preferences
 *
 * The clock app supports:
 * - World clocks for different time zones
 * - Stopwatch with lap times
 * - Countdown timers
 * - Alarm management
 * - 12/24 hour format switching
 */

// Initialize the clock app
function initializeClockApp(container) {
    // Get current clock state from global state
    const {
        clockMode = 'world',
        worldClocks = [],
        timers = [],
        alarms = [],
        clockSettings = { format24h: true }
    } = globalState.getState();

    const appContainer = document.createElement('div');
    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Clock');

    // Navigation bar with mode switching
    const navBar = new NavigationBar({
        title: 'Clock',
        leftButton: {
            element: 'button',
            props: {
                className: 'nav-button settings-button',
                onClick: () => {
                    // Toggle 12/24 hour format
                    const newFormat = !clockSettings.format24h;
                    globalState.setState({
                        clockSettings: { ...clockSettings, format24h: newFormat }
                    });
                },
                'aria-label': 'Toggle time format'
            },
            content: clockSettings.format24h ? '24h' : '12h'
        }
    });
    navBar.mount(appContainer);

    // Tab navigation
    const tabContainer = document.createElement('div');
    tabContainer.className = 'clock-tabs';

    const tabs = [
        { id: 'world', label: 'World Clock' },
        { id: 'stopwatch', label: 'Stopwatch' },
        { id: 'timer', label: 'Timer' },
        { id: 'alarm', label: 'Alarm' }
    ];

    tabs.forEach(tab => {
        const tabButton = document.createElement('button');
        tabButton.className = `clock-tab ${clockMode === tab.id ? 'active' : ''}`;
        tabButton.textContent = tab.label;
        tabButton.setAttribute('aria-label', tab.label);
        tabButton.onclick = () => {
            globalState.setState({ clockMode: tab.id });
        };
        tabContainer.appendChild(tabButton);
    });

    appContainer.appendChild(tabContainer);

    // Main content container
    const contentContainer = document.createElement('div');
    contentContainer.className = 'clock-content';
    appContainer.appendChild(contentContainer);

    // Render appropriate clock mode
    switch (clockMode) {
        case 'world':
            const worldClock = new WorldClock({
                clocks: worldClocks,
                format24h: clockSettings.format24h,
                onAddClock: (timezone) => {
                    const newClock = {
                        id: generateId(),
                        timezone: timezone,
                        city: timezone.split('/').pop().replace('_', ' '),
                        addedAt: new Date().toISOString()
                    };

                    // Save to server
                    if (typeof saveWorldClock === 'function') {
                        saveWorldClock(newClock);
                    }

                    globalState.setState({
                        worldClocks: [...worldClocks, newClock]
                    });
                },
                onRemoveClock: (clockId) => {
                    // Delete from server
                    if (typeof deleteWorldClock === 'function') {
                        deleteWorldClock(clockId);
                    }

                    globalState.setState({
                        worldClocks: worldClocks.filter(c => c.id !== clockId)
                    });
                }
            });
            worldClock.mount(contentContainer);
            break;

        case 'stopwatch':
            const stopwatch = new Stopwatch({
                format24h: clockSettings.format24h
            });
            stopwatch.mount(contentContainer);
            break;

        case 'timer':
            const timer = new Timer({
                timers: timers,
                onAddTimer: (timerData) => {
                    const newTimer = {
                        id: generateId(),
                        ...timerData,
                        createdAt: new Date().toISOString()
                    };
                    globalState.setState({
                        timers: [...timers, newTimer]
                    });
                },
                onRemoveTimer: (timerId) => {
                    globalState.setState({
                        timers: timers.filter(t => t.id !== timerId)
                    });
                }
            });
            timer.mount(contentContainer);
            break;

        case 'alarm':
            const alarm = new AlarmClock({
                alarms: alarms,
                format24h: clockSettings.format24h,
                onAddAlarm: (alarmData) => {
                    const newAlarm = {
                        id: generateId(),
                        ...alarmData,
                        createdAt: new Date().toISOString()
                    };

                    // Save to server
                    if (typeof saveAlarm === 'function') {
                        saveAlarm(newAlarm);
                    }

                    globalState.setState({
                        alarms: [...alarms, newAlarm]
                    });
                },
                onRemoveAlarm: (alarmId) => {
                    // Delete from server
                    if (typeof deleteAlarm === 'function') {
                        deleteAlarm(alarmId);
                    }

                    globalState.setState({
                        alarms: alarms.filter(a => a.id !== alarmId)
                    });
                },
                onToggleAlarm: (alarmId) => {
                    // Toggle on server
                    if (typeof toggleAlarm === 'function') {
                        toggleAlarm(alarmId);
                    }

                    globalState.setState({
                        alarms: alarms.map(a =>
                            a.id === alarmId ? { ...a, enabled: !a.enabled } : a
                        )
                    });
                }
            });
            alarm.mount(contentContainer);
            break;
    }

    // Mount the app container
    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeClockApp = initializeClockApp;