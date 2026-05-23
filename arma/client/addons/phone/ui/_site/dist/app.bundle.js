
// ---- ../js/core/Component.js ----
/** @format */

/**
 * @fileoverview Core Component class that provides the foundation for all UI components
 * in the phone application. Implements a lightweight component lifecycle and virtual DOM-like
 * functionality without external dependencies.
 */

/**
 * Base Component class that handles rendering, lifecycle events, and state management.
 * Provides a React-like component interface for building UI elements.
 *
 * @class
 * @example
 * class MyComponent extends Component {
 *   constructor(props) {
 *     super(props);
 *     this.state = { count: 0 };
 *   }
 *
 *   render() {
 *     return this.createElement('div', {}, `Count: ${this.state.count}`);
 *   }
 * }
 */
class Component {
    /**
     * Creates a new Component instance.
     * @param {Object} props - Initial properties for the component
     */
    constructor(props = {}) {
        this.props = props;
        this.state = {};
        this.element = null;
        this.children = [];
        this.eventListeners = new Map();
        this.mounted = false;
        this.pendingUpdate = false;
    }

    /**
     * Updates component state and triggers a re-render.
     * State updates are batched to prevent multiple renders in the same tick.
     *
     * @param {Object} newState - Object containing state updates
     */
    setState(newState) {
        const prevState = { ...this.state };
        this.state = { ...this.state, ...newState };

        // Prevent multiple updates in the same tick
        if (!this.pendingUpdate) {
            this.pendingUpdate = true;
            setTimeout(() => {
                this.pendingUpdate = false;
                this.updateComponent(prevState);
            }, 0);
        }
    }

    /**
     * Internal method to handle component updates.
     * Manages the re-rendering process and maintains child component state.
     *
     * @private
     * @param {Object} prevState - Previous state before update
     */
    updateComponent(prevState) {
        // Call onStateChange hook
        this.onStateChange(prevState, this.state);

        // Re-render and update DOM
        if (this.element && this.element.parentNode) {
            const container = this.element.parentNode;
            const oldElement = this.element;

            // Store input states and elements before update
            const inputStates = new Map();
            oldElement.querySelectorAll('input').forEach(input => {
                inputStates.set(input, {
                    element: input,
                    value: input.value,
                    selectionStart: input.selectionStart,
                    selectionEnd: input.selectionEnd,
                    isFocused: document.activeElement === input
                });
            });

            // Store mounted state of children
            const childStates = new Map();
            this.children.forEach((child) => {
                childStates.set(child, child.mounted);
            });

            // Create new element
            const newElement = this.render();

            // Update the DOM while preserving input elements
            if (oldElement && newElement) {
                // Replace the old element with the new one
                container.replaceChild(newElement, oldElement);
                this.element = newElement;

                // Restore input elements and their states
                inputStates.forEach((state, oldInput) => {
                    const newInput = newElement.querySelector(`input[type="${oldInput.type}"]`);
                    if (newInput) {
                        // Replace the new input with the old one
                        newInput.parentNode.replaceChild(oldInput, newInput);

                        // Restore input state
                        if (state.isFocused) {
                            oldInput.focus();
                            oldInput.setSelectionRange(state.selectionStart, state.selectionEnd);
                        }
                    }
                });

                // Restore child components that were previously mounted
                this.children.forEach((child) => {
                    if (childStates.get(child)) {
                        child.mount(this.element);
                    }
                });
            }
        }
    }

    /**
     * Lifecycle method called when state changes.
     * Override in subclasses to handle state updates.
     *
     * @param {Object} prevState - Previous state
     * @param {Object} newState - New state
     */
    onStateChange(prevState, newState) {
        // Override in subclasses if needed
    }

    /**
     * Mounts the component to a DOM container.
     * Handles initial render and lifecycle methods.
     *
     * @param {HTMLElement} container - DOM element to mount component into
     * @returns {Component} The component instance
     */
    mount(container) {
        // Skip if already mounted to this container
        if (this.mounted && this.element && this.element.parentNode === container) {
            return this;
        }

        const newElement = this.render();
        if (this.element && this.element.parentNode) {
            this.element.parentNode.replaceChild(newElement, this.element);
        } else {
            container.appendChild(newElement);
        }
        this.element = newElement;

        // Call componentDidMount after mounting
        if (!this.mounted && this.componentDidMount) {
            this.componentDidMount();
        }
        this.mounted = true;
        return this;
    }

    /**
     * Creates a DOM element with specified properties and children.
     * Handles event listeners, styles, and refs.
     *
     * @param {string} tag - HTML tag name
     * @param {Object} props - Element properties and attributes
     * @param {...(string|number|Component|HTMLElement)} children - Child elements
     * @returns {HTMLElement} Created DOM element
     */
    createElement(tag, props = {}, ...children) {
        const element = document.createElement(tag);

        // Set attributes and properties
        Object.entries(props).forEach(([key, value]) => {
            if (key.startsWith('on') && typeof value === 'function') {
                const event = key.slice(2).toLowerCase();
                element.addEventListener(event, value);

                // Store event listener for cleanup
                if (!this.eventListeners.has(element)) {
                    this.eventListeners.set(element, []);
                }
                this.eventListeners.get(element).push({ event, handler: value });
            } else if (key === 'className') {
                element.className = value;
            } else if (key === 'style' && typeof value === 'object') {
                Object.assign(element.style, value);
            } else if (key === 'ref' && typeof value === 'function') {
                value(element);
            } else if (typeof value === 'boolean') {
                if (value) {
                    element.setAttribute(key, key);
                }
            } else if (value !== null && value !== undefined) {
                element.setAttribute(key, value);
            } else {
                return;
            }
        });

        // Add children
        children.flat().forEach((child) => {
            if (child === null || child === undefined) {
                return;
            }

            if (typeof child === 'string' || typeof child === 'number') {
                element.appendChild(document.createTextNode(child));
            } else if (child instanceof Component) {
                child.mount(element);
                this.children.push(child);
            } else if (child instanceof HTMLElement) {
                element.appendChild(child);
            }
        });

        return element;
    }

    /**
     * Renders the component's DOM representation.
     * Must be overridden by subclasses to define component structure.
     *
     * @returns {HTMLElement} The rendered DOM element
     */
    render() {
        // Override in subclasses
        return this.createElement('div');
    }

    /**
     * Unmounts the component and cleans up resources.
     * Removes event listeners and unmounts children.
     */
    unmount() {
        // Call componentWillUnmount before cleanup
        if (this.mounted && this.componentWillUnmount) {
            this.componentWillUnmount();
        }

        // Clean up event listeners
        this.eventListeners.forEach((listeners, element) => {
            listeners.forEach(({ event, handler }) => {
                element.removeEventListener(event, handler);
            });
        });
        this.eventListeners.clear();

        // Unmount children
        this.children.forEach((child) => {
            if (child.mounted) {
                child.unmount();
            }
        });
        this.children = [];

        // Remove from DOM
        if (this.element && this.element.parentNode) {
            this.element.parentNode.removeChild(this.element);
        }
        this.element = null;
        this.mounted = false;
    }
}


// ---- ../js/core/StateManager.js ----
/**
 * @format
 * @fileoverview State management system for the phone application. Implements a simple pub/sub pattern for managing global application state.
 */

/**
 * Initial application state containing mock data for development.
 * @type {Object}
 */
const initialAppState = {
    // Navigation state
    currentApp: 'home',
    showModal: false,

    // Contact management
    contacts: [],

    // Message management
    messages: [],

    // Server-synced data (non-UI mapped)
    // Keep raw server payloads separate to avoid breaking current UI
    rawMessages: [],
    emails: [],
    selectedEmail: null,
    showEmailComposer: false,
    selectedConversationRaw: null,

    // UI state
    selectedContact: null,
    selectedConversation: null,
    showMessageContactPicker: false,
    newMessage: '',
    currentUid: null,
    
    // Clock state
    clockMode: 'world',
    worldClocks: [],
    timers: [],
    alarms: [],
    clockSettings: { format24h: true },
    
    // Notes state
    notes: [],
    currentNote: null,
    showNoteEditor: false,

    // Calendar state
    events: [],
    currentEvent: null,
    showEventEditor: false,

    // Mobile bank state
    mobileBank: {
        account: {
            bank: 0,
            cash: 0,
            earnings: 0,
            transactions: [],
        },
        session: {
            playerName: '',
            transferTargets: [],
            uid: '',
        },
        notice: null,
        pendingAction: '',
    },
};

/**
 * Manages global application state using a publish/subscribe pattern.
 * Provides methods for accessing and updating state while notifying subscribers.
 *
 * @class
 * @example
 * const state = new StateManager({ count: 0 });
 * state.subscribe((newState, prevState) => {
 *   console.log('State changed:', newState);
 * });
 * state.setState({ count: 1 });
 */
class StateManager {
    /**
     * Creates a new StateManager instance.
     * @param {Object} initialState - Initial state object
     */
    constructor(initialState = {}) {
        /** @private */
        this.state = { ...initialState };
        /** @private */
        this.subscribers = new Set();
    }

    /**
     * Gets current state object.
     * @returns {Object} Copy of current state
     */
    getState() {
        return { ...this.state };
    }

    /**
     * Updates state and notifies subscribers.
     * @param {Object} updates - Object containing state updates
     */
    setState(updates) {
        const prevState = { ...this.state };
        this.state = { ...this.state, ...updates };
        this.notifySubscribers(prevState, this.state);
    }

    /**
     * Subscribes to state changes.
     * @param {Function} callback - Function to call when state changes
     * @returns {Function} Unsubscribe function
     */
    subscribe(callback) {
        this.subscribers.add(callback);
        return () => this.subscribers.delete(callback);
    }

    /**
     * Notifies subscribers of state changes.
     * @private
     * @param {Object} prevState - Previous state
     * @param {Object} newState - New state
     */
    notifySubscribers(prevState, newState) {
        this.subscribers.forEach((callback) => {
            callback(newState, prevState);
        });
    }
}

// Create and export global state instance
const globalState = new StateManager(initialAppState);


// ---- ../js/utils/helpers.js ----
/** @format */

/**
 * @fileoverview Utility functions for the phone application
 * Contains helper functions for common operations like debouncing,
 * ID generation, phone number formatting, and text manipulation.
 */

/**
 * Creates a debounced function that delays invoking func until after wait milliseconds have elapsed
 * @param {Function} func - The function to debounce
 * @param {number} wait - The number of milliseconds to delay
 * @returns {Function} The debounced function
 */
const debounce = (func, wait) => {
    let timeout;

    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };

        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

/**
 * Generates a unique identifier using timestamp and random number.
 *
 * @returns {string} A unique string identifier
 * @example
 * const newId = generateId(); // Returns something like "lh8d3m4k2n1"
 */
const generateId = () => {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
};

/**
 * Formats a phone number string into a standardized format.
 * Converts "11234567890" to "+1 (123) 456-7890"
 *
 * @param {string} phoneNumber - The raw phone number to format
 * @returns {string} The formatted phone number
 * @example
 * const formatted = formatPhoneNumber('11234567890'); // Returns "+1 (123) 456-7890"
 */
const formatPhoneNumber = (phoneNumber) => {
    const cleaned = phoneNumber.replace(/\D/g, '');
    const match = cleaned.match(/^(\d{1})(\d{3})(\d{3})(\d{4})$/);
    if (match) {
        return `+${match[1]} (${match[2]}) ${match[3]}-${match[4]}`;
    }
    return phoneNumber;
};

/**
 * Extracts initials from a person's name.
 * Takes first letter of first and last name, up to 2 characters.
 *
 * @param {string} name - The full name to get initials from
 * @returns {string} The initials (maximum 2 characters)
 * @example
 * const initials = getInitials('John Doe'); // Returns "JD"
 * const singleInitial = getInitials('John'); // Returns "J"
 */
const getInitials = (name) => {
    return name
        .split(' ')
        .map((word) => word.charAt(0).toUpperCase())
        .join('')
        .substring(0, 2);
};


// ---- ../js/utils/PhoneMedia.js ----
/** @format */

const PhoneMedia = (() => {
    const addonRoot = 'forge\\forge_client\\addons\\phone\\ui\\_site\\';
    const cache = new Map();

    function assetPath(...parts) {
        return `${addonRoot}${parts.join('\\')}`;
    }

    function base64Path(...parts) {
        const path = assetPath(...parts);
        return path.endsWith('.b64') ? path : `${path}.b64`;
    }

    function toBrowserPath(path) {
        return String(path || '')
            .replace(addonRoot, '')
            .replace(/\\/g, '/')
            .replace(/\.b64$/i, '');
    }

    function toDataUrl(base64Text, mimeType = 'image/png') {
        const value = String(base64Text || '').trim();
        if (!value) return '';
        return value.startsWith('data:') ? value : `data:${mimeType};base64,${value}`;
    }

    function loadImage(path) {
        const base64AssetPath = path.endsWith('.b64') ? path : `${path}.b64`;

        if (cache.has(base64AssetPath)) {
            return Promise.resolve(cache.get(base64AssetPath));
        }

        if (typeof A3API !== 'undefined' && A3API.RequestFile) {
            return A3API.RequestFile(base64AssetPath).then((base64Text) => {
                const dataUrl = toDataUrl(base64Text);
                cache.set(base64AssetPath, dataUrl);
                return dataUrl;
            });
        }

        const browserPath = toBrowserPath(base64AssetPath);
        cache.set(base64AssetPath, browserPath);
        return Promise.resolve(browserPath);
    }

    return {
        assetPath,
        base64Path,
        loadImage
    };
})();


// ---- ../js/components/StatusBar.js ----
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


// ---- ../js/components/Modal.js ----
/** @format */

/**
 * @class Modal
 * @extends Component
 * @description A reusable modal dialog component.
 * Provides an overlay with a modal dialog box containing customizable content and actions.
 * Supports keyboard interaction and click-outside-to-close behavior.
 */
class Modal extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {boolean} props.show - Whether the modal is visible
     * @param {string} [props.title='Modal'] - Title of the modal
     * @param {Array|Object} [props.children=[]] - Content to display in the modal
     * @param {Function} [props.onClose] - Callback when modal is closed
     * @param {Function} [props.onConfirm] - Callback when confirm button is clicked
     */
    constructor(props) {
        super(props);

        // Bind event handlers
        this.handleOverlayClick = this.handleOverlayClick.bind(this);
        this.handleModalClick = this.handleModalClick.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    /**
     * Handle click events on the overlay
     * @param {Event} e - Click event object
     * @private
     */
    handleOverlayClick(e) {
        if (e.target === e.currentTarget && this.props.onClose) {
            this.props.onClose();
        }
    }

    /**
     * Prevent click events from bubbling through the modal
     * @param {Event} e - Click event object
     * @private
     */
    handleModalClick(e) {
        e.stopPropagation();
    }

    /**
     * Handle keyboard events for accessibility
     * @param {KeyboardEvent} e - Keyboard event object
     * @private
     */
    handleKeyDown(e) {
        if (e.key === 'Escape' && this.props.onClose) {
            this.props.onClose();
        }
    }

    /**
     * Render the modal actions (buttons)
     * @param {Function} onClose - Close callback
     * @param {Function} onConfirm - Confirm callback
     * @param {string} confirmText - Text for confirm button
     * @param {string} cancelText - Text for cancel button
     * @returns {HTMLElement} The rendered actions element
     * @private
     */
    renderActions(onClose, onConfirm, confirmText = 'Call', cancelText = 'Cancel', extraActions = [], hideCancel = false, hideConfirm = false) {
        if (hideCancel && hideConfirm && !extraActions.length) {
            return null;
        }

        return this.createElement(
            'div',
            { className: 'modal-actions' },
            hideCancel ? null : this.createElement(
                'button',
                {
                    className: 'button secondary',
                    onClick: () => onClose?.(),
                    type: 'button',
                    'aria-label': cancelText,
                },
                cancelText
            ),
            ...extraActions.map((action) => this.createElement(
                'button',
                {
                    className: action.className || 'button secondary',
                    onClick: () => action.onClick?.(),
                    type: 'button',
                    disabled: action.disabled === true,
                    'aria-label': action.ariaLabel || action.text,
                },
                action.text
            )),
            hideConfirm ? null : this.createElement(
                'button',
                {
                    className: 'button',
                    onClick: () => onConfirm?.(),
                    type: 'button',
                    'aria-label': confirmText,
                },
                confirmText
            )
        );
    }

    /**
     * Render the modal
     * @returns {HTMLElement} The rendered modal element
     */
    render() {
        const { show, title, children = [], onClose, onConfirm, confirmText, cancelText, extraActions = [], hideCancel = false, hideConfirm = false } = this.props;

        if (!show) {
            return this.createElement('div', {
                className: 'hidden',
                style: { display: 'none' },
                'aria-hidden': 'true',
            });
        }

        // Ensure children is always an array
        const childElements = Array.isArray(children) ? children : [children];

        return this.createElement(
            'div',
            {
                className: 'modal-overlay',
                onClick: this.handleOverlayClick,
                onKeyDown: this.handleKeyDown,
                role: 'dialog',
                'aria-modal': 'true',
                'aria-labelledby': 'modal-title',
            },
            this.createElement(
                'div',
                {
                    className: 'modal',
                    onClick: this.handleModalClick,
                    role: 'document',
                    tabIndex: -1,
                },
                this.createElement(
                    'h2',
                    {
                        id: 'modal-title',
                        role: 'heading',
                        'aria-level': '2',
                    },
                    title || 'Modal'
                ),
                this.createElement(
                    'div',
                    {
                        className: 'modal-content',
                        role: 'region',
                        'aria-label': 'Modal content',
                    },
                    ...childElements.filter((child) => child != null)
                ),
                this.renderActions(onClose, onConfirm, confirmText, cancelText, extraActions, hideCancel, hideConfirm)
            )
        );
    }
}


// ---- ../js/components/NavigationBar.js ----
/** @format */

/**
 * @class NavigationBar
 * @extends Component
 * @description A navigation bar component that provides app navigation controls.
 * Handles back navigation and displays the current screen title.
 */
class NavigationBar extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {boolean} [props.showBackButton=false] - Whether to show the back button
     * @param {string} [props.title] - Title to display in the navigation bar
     * @param {Object|HTMLElement} [props.leftButton] - Optional custom button to display on the left side (overrides back button)
     * @param {Object|HTMLElement} [props.rightButton] - Optional button to display on the right side
     */
    constructor(props) {
        super(props);
        this.handleBackClick = this.handleBackClick.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    /**
     * Handle back button click event
     * @private
     */
    handleBackClick() {
        const currentState = globalState.getState();

        // Priority 1: If we're in a conversation, go back to messages list
        if (currentState.selectedConversation) {
            globalState.setState({
                selectedConversation: null,
                selectedConversationRaw: null,
            });
            return; // Exit early, don't execute the rest
        }

        if (currentState.showMessageContactPicker) {
            globalState.setState({
                showMessageContactPicker: false,
            });
            return;
        }

        if (currentState.selectedEmail || currentState.showEmailComposer) {
            globalState.setState({
                selectedEmail: null,
                showEmailComposer: false,
            });
            return;
        }

        // Priority 2: If we came from phone app, go back to phone
        if (currentState.previousApp === 'phone') {
            globalState.setState({
                currentApp: 'phone',
                previousApp: null,
            });
            return; // Exit early
        }

        // Priority 3: Default - go to home and clear everything
        globalState.setState({
            currentApp: 'home',
            previousApp: null,
            selectedConversation: null,
            selectedConversationRaw: null,
            selectedContact: null,
            showMessageContactPicker: false,
            showModal: false,
        });
    }

    /**
     * Handle keyboard events for accessibility
     * @param {KeyboardEvent} e - Keyboard event object
     * @private
     */
    handleKeyDown(e) {
        if (e.key === 'Backspace' && this.props.showBackButton) {
            this.handleBackClick();
        }
    }

    /**
     * Render the left section (custom button, back button, or spacer)
     * @returns {HTMLElement} The rendered element
     * @private
     */
    renderLeftSection() {
        const { leftButton, showBackButton } = this.props;

        // Priority 1: Custom left button
        if (leftButton) {
            if (leftButton instanceof HTMLElement) {
                return leftButton;
            }
            
            return this.createElement(
                leftButton.element || 'button',
                leftButton.props || {},
                leftButton.content
            );
        }

        // Priority 2: Default back button
        if (showBackButton) {
            return this.createElement(
                'button',
                {
                    className: 'nav-back-button',
                    onClick: this.handleBackClick,
                    'aria-label': 'Go back',
                    type: 'button',
                },
                this.createElement('img', {
                    src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="grey" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>',
                    alt: '',
                    style: 'width:24px;height:24px;padding:0;margin:0;display:block;pointer-events:none;'
                })
            );
        }

        // Priority 3: Empty spacer
        return this.createElement('div', {
            className: 'nav-spacer',
            'aria-hidden': 'true',
        });
    }

    /**
     * Render the right button section
     * @returns {HTMLElement} The rendered element
     * @private
     */
    renderRightSection() {
        const { rightButton } = this.props;

        if (!rightButton) {
            return this.createElement('div', {
                className: 'nav-spacer',
                'aria-hidden': 'true',
            });
        }

        if (rightButton instanceof HTMLElement) {
            return rightButton;
        }

        return this.createElement(
            rightButton.element || 'button',
            rightButton.props || {},
            rightButton.content
        );
    }

    /**
     * Render the navigation bar
     * @returns {HTMLElement} The rendered navigation bar element
     */
    render() {
        const { title } = this.props;

        return this.createElement(
            'nav',
            {
                className: 'navigation-bar',
                role: 'navigation',
                'aria-label': 'Main navigation',
                onKeyDown: this.handleKeyDown,
            },
            this.renderLeftSection(),
            title &&
            this.createElement(
                'h1',
                {
                    className: 'nav-title',
                    role: 'heading',
                    'aria-level': '1',
                },
                title
            ),
            this.renderRightSection()
        );
    }
}


// ---- ../js/components/HomeIndicator.js ----
/** @format */

/**
 * @class HomeIndicator
 * @extends Component
 * @description A component that renders the iPhone-style home indicator.
 * Provides navigation back to the home screen via click or swipe gestures.
 * Currently implements click handling, with swipe gesture support planned for future.
 */
class HomeIndicator extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     */
    constructor(props) {
        super(props);

        // Bind event handlers
        this.handleClick = this.handleClick.bind(this);
        this.handleSwipeUp = this.handleSwipeUp.bind(this);

        // Touch event state for future swipe implementation
        this.touchStartY = 0;
    }

    /**
     * Resets the app state and navigates to home screen
     * @private
     */
    handleClick() {
        globalState.setState({
            currentApp: 'home',
            selectedConversation: null,
            selectedConversationRaw: null,
            selectedContact: null,
            showMessageContactPicker: false,
            showModal: false,
        });
    }

    /**
     * Handles swipe up gesture
     * @param {Event} e - Touch/swipe event object
     * @private
     * @todo Implement proper swipe gesture detection
     */
    handleSwipeUp(e) {
        // Simple click handler for now, swipe gesture to be implemented
        this.handleClick();
    }

    /**
     * Render the home indicator
     * @returns {HTMLElement} The rendered home indicator element
     */
    render() {
        return this.createElement(
            'div',
            {
                className: 'home-indicator-container',
                onClick: this.handleClick,
                role: 'button',
                'aria-label': 'Return to home screen',
                tabIndex: 0,
                onKeyPress: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        this.handleClick();
                    }
                },
            },
            this.createElement('div', {
                className: 'home-indicator',
                'aria-hidden': 'true',
            })
        );
    }
}


// ---- ../js/components/SearchBar.js ----
/** @format */

/**
 * @class SearchBar
 * @extends Component
 * @description A search input component that provides debounced search functionality.
 * Includes built-in debouncing to prevent excessive search updates.
 */
class SearchBar extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {string} [props.placeholder='Search contacts...'] - Placeholder text for the search input
     * @param {Function} [props.onSearch] - Callback function when search value changes
     * @param {string} [props.value] - Initial input value
     */
    constructor(props) {
        super(props);

        // Set debounce delay
        this.DEBOUNCE_DELAY = 300; // milliseconds

        // Initialize state
        this.state = {
            searchTerm: props.value || ''
        };

        // Bind methods
        this.handleInput = debounce(this.handleInput.bind(this), this.DEBOUNCE_DELAY);
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    /**
     * Update state when props change
     * @param {Object} nextProps - Next props
     */
    componentWillReceiveProps(nextProps) {
        if (nextProps.value !== this.props.value) {
            this.setState({ searchTerm: nextProps.value });
        }
    }

    /**
     * Handle input change events
     * @param {Event} e - Input change event
     * @private
     */
    handleInputChange(e) {
        const value = e.target.value;
        this.setState({ searchTerm: value });
        this.handleInput(value);
    }

    /**
     * Debounced search handler
     * @param {string} searchTerm - Current search term
     * @private
     */
    handleInput(searchTerm) {
        const { onSearch } = this.props;
        if (onSearch) {
            onSearch(searchTerm);
        }
    }

    /**
     * Handle keyboard events
     * @param {KeyboardEvent} e - Keyboard event
     * @private
     */
    handleKeyDown(e) {
        // Clear search on Escape
        if (e.key === 'Escape') {
            this.setState({ searchTerm: '' });
            this.handleInput('');
        }
    }

    /**
     * Render the search bar
     * @returns {HTMLElement} The rendered search bar element
     */
    render() {
        const { placeholder = 'Search contacts...' } = this.props;
        const { searchTerm } = this.state;

        return this.createElement(
            'div',
            {
                className: 'search-bar',
                role: 'search',
                'aria-label': 'Search contacts',
                style: {
                    paddingBottom: '10px',
                    borderBottom: '1px solid #e9ecef',
                },
            },
            this.createElement('input', {
                type: 'search',
                placeholder,
                value: searchTerm,
                onInput: this.handleInputChange,
                onKeyDown: this.handleKeyDown,
                'aria-label': placeholder,
                style: {
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '20px',
                    fontSize: '16px',
                    outline: 'none',
                },
            })
        );
    }
}


// ---- ../js/components/Header.js ----
/** @format */

/**
 * @class Header
 * @extends Component
 * @description A component that renders a header section with a title.
 * Used for displaying page or section titles in the phone UI.
 */
class Header extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {string} [props.title='Phone UI'] - The title text to display in the header
     */
    constructor(props) {
        super(props);
    }

    /**
     * Render the header component
     * @returns {HTMLElement} The rendered header element
     */
    render() {
        const { title = 'Phone UI' } = this.props;

        return this.createElement(
            'header',
            {
                className: 'header',
                role: 'banner',
                'aria-label': 'Page header',
            },
            this.createElement(
                'h1',
                {
                    role: 'heading',
                    'aria-level': '1',
                },
                title
            )
        );
    }
}


// ---- ../js/components/HomeScreen.js ----
/** @format */

/**
 * @class HomeScreen
 * @extends Component
 * @description The main home screen component that displays the app grid.
 * Manages the display and interaction of app icons, handling navigation to different apps.
 */
class HomeScreen extends Component {
    /**
     * Cache for loaded icons
     * @static
     * @private
     */
    static iconCache = new Map();

    /**
     * @constructor
     * @param {Object} props - Component properties
     */
    constructor(props) {
        super(props);
        this.handleAppClick = this.handleAppClick.bind(this);
        this.state = {
            isDarkTheme: document.documentElement.getAttribute('data-theme') === 'dark'
        };
    }

    static iconPath(app, isDarkTheme) {
        return PhoneMedia.base64Path('images', isDarkTheme ? 'dark' : 'light', `${app.icon}.png`);
    }

    static backgroundPath(isDarkTheme) {
        return PhoneMedia.base64Path('images', 'bg', isDarkTheme ? 'bgdark_01_ca.png' : 'bglight_01_ca.png');
    }

    componentDidMount() {
        // Initial background update
        this.updateBackground();
        
        // Listen for theme changes
        document.addEventListener('themeChanged', (event) => {
            const isDarkTheme = event.detail.theme === 'dark';
            
            // Update background immediately
            const bgPath = HomeScreen.backgroundPath(isDarkTheme);

            PhoneMedia.loadImage(bgPath).then(imageContent => {
                if (this.element) {
                    this.element.style.background = `url('${imageContent}')`;
                    this.element.style.backgroundSize = 'contain';
                    this.element.style.backgroundPosition = 'center';
                }
            }).catch(error => {
                console.error(`Failed to load background image: ${bgPath}`, error);
            });

            // Update state after background change
            this.setState({ isDarkTheme });
        });
    }

    updateBackground() {
        const isDarkTheme = document.documentElement.getAttribute('data-theme') === 'dark';
        const bgPath = HomeScreen.backgroundPath(isDarkTheme);

        PhoneMedia.loadImage(bgPath).then(imageContent => {
            if (this.element) {
                this.element.style.background = `url('${imageContent}')`;
                this.element.style.backgroundSize = 'contain';
                this.element.style.backgroundPosition = 'center';
                this.element.style.backgroundRepeat = 'no-repeat';
                this.element.style.backgroundColor = isDarkTheme ? '#000000' : '#ffffff';
            } else {
                console.error('HomeScreen element not found during background update');
            }
        }).catch(error => {
            console.error(`Failed to load background image: ${bgPath}`, error);
        });
    }

    /**
     * List of available apps with their configurations
     * @type {Array<AppConfig>}
     * @private
     */
    static get apps() {
        return [
            { name: 'safari', title: 'Safari', icon: 'Safari', color: '' },
            { name: 'mail', title: 'Mail', icon: 'Mail', color: '' },
            { name: 'notes', title: 'Notes', icon: 'Notes', color: '' },
            { name: 'iCloud', title: 'iCloud', icon: 'iCloud', color: '' },
            { name: 'camera', title: 'Camera', icon: 'Camera', color: '' },
            { name: 'photos', title: 'Photos', icon: 'Photos', color: '' },
            { name: 'clock', title: 'Clock', icon: 'Clock', color: '' },
            { name: 'calendar', title: 'Calendar', icon: 'Calendar', color: '' },
            { name: 'wallet', title: 'Wallet', icon: 'Wallet', color: '' },
            { name: 'store', title: 'App Store', icon: 'AppStore', color: '' },
        ];
    }

    /**
     * List of apps to show in the dock
     * @type {Array<AppConfig>}
     * @private
     */
    static get dockApps() {
        return [
            { name: 'phone', title: '', icon: 'Phone', color: '' },
            { name: 'contacts', title: '', icon: 'Contacts', color: '' },
            { name: 'messages', title: '', icon: 'Message', color: '' },
            { name: 'settings', title: '', icon: 'Settings', color: '' },
        ];
    }

    /**
     * Handles app icon click events
     * @param {string} appName - Name of the clicked app
     * @private
     */
    handleAppClick(appName) {
        globalState.setState({ currentApp: appName });
    }

    /**
     * Renders an individual app icon
     * @param {AppConfig} app - App configuration object
     * @returns {HTMLElement} The rendered app icon element
     * @private
     */
    renderAppIcon(app) {
        const imgElement = this.createElement('img', {
            alt: app.title,
            style: { display: 'none' } // Hide initially
        });

        const isDarkTheme = document.documentElement.getAttribute('data-theme') === 'dark';
        const iconPath = HomeScreen.iconPath(app, isDarkTheme);

        // Check cache first
        if (HomeScreen.iconCache.has(iconPath)) {
            imgElement.src = HomeScreen.iconCache.get(iconPath);
            imgElement.style.display = 'block';
        } else {
            // Load the file if not in cache
            PhoneMedia.loadImage(iconPath).then(imageContent => {
                HomeScreen.iconCache.set(iconPath, imageContent);
                imgElement.src = imageContent;
                imgElement.style.display = 'block';
            }).catch(error => {
                console.error(`Failed to load icon for ${app.title}:`, error);
            });
        }

        return this.createElement(
            'div',
            {
                className: 'app-icon',
                onClick: () => this.handleAppClick(app.name),
                role: 'button',
                'aria-label': `Open ${app.title} app`,
                tabIndex: 0,
                onKeyPress: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        this.handleAppClick(app.name);
                    }
                },
            },
            this.createElement(
                'div',
                {
                    className: 'app-icon-symbol',
                    'aria-hidden': 'true',
                    style: app.color ? { background: app.color } : {}
                },
                imgElement
            ),
            this.createElement('span', { className: 'app-title' }, app.title)
        );
    }

    /**
     * Render the home screen
     * @returns {HTMLElement} The rendered home screen element
     */
    render() {
        return this.createElement(
            'div',
            {
                className: 'home-screen',
                role: 'main',
                'aria-label': 'Home screen',
            },
            this.createElement(
                'div',
                {
                    className: 'app-grid',
                    role: 'grid',
                    'aria-label': 'App grid',
                },
                ...HomeScreen.apps.map((app) => this.renderAppIcon(app))
            ),
            this.createElement(
                'div',
                {
                    className: 'dock',
                    role: 'toolbar',
                    'aria-label': 'App dock',
                },
                ...HomeScreen.dockApps.map((app) => this.renderAppIcon(app))
            )
        );
    }
}

/**
 * @typedef {Object} AppConfig
 * @property {string} name - Internal name/identifier of the app
 * @property {string} title - Display title of the app
 * @property {string} icon - Emoji icon representing the app
 * @property {string} color - Background color for the app icon (if any)
 */


// ---- ../js/apps/phone/components/Dialpad.js ----
/**
 * @format
 * @class Dialpad
 * @extends Component
 * @description A phone dialpad component providing a touch-tone keypad interface for making calls. Manages phone number input, formatting, call state, and integration with contacts.
 */

class Dialpad extends Component {
  static fieldCommanderPhoneNumber = '0160000000';

  static assetPath(...parts) {
    return PhoneMedia.base64Path('images', ...parts);
  }

  /**
   * @constructor
   * @param {Object} props - Component properties
   */
  constructor(props = {}) {
    super(props);

    this.state = {
      phoneNumber: '', // Current phone number in the dialpad
      isCallActive: false, // Whether a call is currently in progress
      callDuration: 0, // Duration of active call in seconds
    };

    // Bind event handlers
    this.handleNumberClick = this.handleNumberClick.bind(this);
    this.handleCall = this.handleCall.bind(this);
    this.handleEndCall = this.handleEndCall.bind(this);
    this.handleDelete = this.handleDelete.bind(this);
    this.handleOpenContacts = this.handleOpenContacts.bind(this);
    this.handleGlobalStateChange = this.handleGlobalStateChange.bind(this);

    this.callTimer = null;

    // Subscribe to global state changes
    globalState.subscribe(this.handleGlobalStateChange);
  }

  // -------------------------------------------------------------------------
  // Lifecycle Methods
  // -------------------------------------------------------------------------

  /**
   * @method componentDidMount
   * @description Initializes component after mounting, handling any existing phone number in global state
   */
  componentDidMount() {
    const state = globalState.getState();
    if (state.phoneNumber) {
      this.setState(
        {
          phoneNumber: this.cleanPhoneNumber(state.phoneNumber),
        },
        () => {
          globalState.setState({ phoneNumber: '' });
        }
      );
    }
  }

  /**
   * @method componentWillUnmount
   * @description Cleanup resources and subscriptions when component unmounts
   */
  componentWillUnmount() {
    if (this.callTimer) {
      clearInterval(this.callTimer);
    }
    globalState.unsubscribe(this.handleGlobalStateChange);
  }

  // -------------------------------------------------------------------------
  // Phone Number Utilities
  // -------------------------------------------------------------------------

  /**
   * @method cleanPhoneNumber
   * @description Removes all non-digit characters from a phone number
   * @param {string} number - The phone number to clean
   * @returns {string} The cleaned phone number containing only digits
   */
  cleanPhoneNumber(number) {
    if (!number) return '';
    return number.replace(/\D/g, '');
  }

  /**
   * @method formatPhoneNumber
   * @description Formats a phone number into a readable format
   * @param {string} number - The phone number to format
   * @returns {string} Formatted phone number as (XXX) XXX-XXXX
   */
  formatPhoneNumber(number) {
    if (!number || number.length === 0) return '';

    const cleaned = number.replace(/[^\d]/g, '');

    if (cleaned.length <= 3) {
      return cleaned;
    } else if (cleaned.length <= 6) {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3)}`;
    } else if (cleaned.length <= 10) {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
    } else {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6, 10)}`;
    }
  }

  /**
   * @method formatTime
   * @description Formats seconds into MM:SS format
   * @param {number} seconds - Number of seconds to format
   * @returns {string} Time formatted as MM:SS
   */
  formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // -------------------------------------------------------------------------
  // Event Handlers
  // -------------------------------------------------------------------------

  /**
   * @method handleGlobalStateChange
   * @description Handles changes in the global state, specifically phone number updates
   * @param {Object} newState - The new global state
   */
  handleGlobalStateChange(newState) {
    if (newState.phoneNumber) {
      const cleaned = this.cleanPhoneNumber(newState.phoneNumber);
      if (cleaned && cleaned !== this.state.phoneNumber) {
        this.setState(
          {
            phoneNumber: cleaned,
          },
          () => {
            globalState.setState({ phoneNumber: '' });
          }
        );
      }
    }
  }

  /**
   * @method handleNumberClick
   * @description Handles digit button clicks on the dialpad
   * @param {string} number - The digit that was clicked
   */
  handleNumberClick(number) {
    if (!this.state.isCallActive) {
      this.setState({
        phoneNumber: this.state.phoneNumber + number,
      });
    }
  }

  /**
   * @method handleDelete
   * @description Handles the delete button click, removing the last digit
   */
  handleDelete() {
    if (!this.state.isCallActive) {
      this.setState({
        phoneNumber: this.state.phoneNumber.slice(0, -1),
      });
    }
  }

  /**
   * @method handleCall
   * @description Initiates a phone call and starts the call timer
   */
  handleCall() {
    if (
      this.state.phoneNumber &&
      !this.state.isCallActive &&
      this.cleanPhoneNumber(this.state.phoneNumber) !== Dialpad.fieldCommanderPhoneNumber
    ) {
      this.setState({
        isCallActive: true,
        callDuration: 0,
      });

      this.callTimer = setInterval(() => {
        // Update state directly to avoid re-render during call
        this.state.callDuration = this.state.callDuration + 1;
        
        // Update only the call duration display element
        const durationElement = document.querySelector('.call-duration');
        if (durationElement) {
          durationElement.textContent = this.formatTime(this.state.callDuration);
        }
      }, 1000);
    }
  }

  /**
   * @method handleEndCall
   * @description Ends the current call and resets the dialpad state
   */
  handleEndCall() {
    if (this.callTimer) {
      clearInterval(this.callTimer);
      this.callTimer = null;
    }

    this.setState({
      isCallActive: false,
      callDuration: 0,
      phoneNumber: '',
    });
  }

  /**
   * @method handleOpenContacts
   * @description Navigates to the contacts view
   */
  handleOpenContacts() {
    globalState.setState({
      currentApp: 'contacts',
      previousApp: 'phone',
    });
  }

  // -------------------------------------------------------------------------
  // Render Methods
  // -------------------------------------------------------------------------

  /**
   * @method render
   * @description Renders the phone dialpad interface
   * @returns {Object} Virtual DOM representation of the component
   */
  render() {
    const { phoneNumber, isCallActive, callDuration } = this.state;
    const isPhoneNumberEmpty = phoneNumber.length === 0;

    const dialpadNumbers = [
      ['1', ''],
      ['2', 'ABC'],
      ['3', 'DEF'],
      ['4', 'GHI'],
      ['5', 'JKL'],
      ['6', 'MNO'],
      ['7', 'PQRS'],
      ['8', 'TUV'],
      ['9', 'WXYZ'],
      ['*', ''],
      ['0', '+'],
      ['#', ''],
    ];

    if (isCallActive) {
      return this.createElement(
        'div',
        {
          className: 'phone-dialpad call-active',
          role: 'region',
          'aria-label': 'Active call interface',
        },
        this.createElement(
          'div',
          {
            className: 'call-info',
            role: 'status',
            'aria-live': 'polite',
          },
          this.createElement('div', { className: 'call-status' }, 'Calling...'),
          this.createElement('div', { className: 'call-number' }, this.formatPhoneNumber(phoneNumber)),
          this.createElement('div', { className: 'call-duration' }, this.formatTime(callDuration))
        ),
        this.createElement(
          'div',
          { className: 'call-actions' },
          this.createElement(
            'button',
            {
              className: 'end-call-btn',
              onClick: this.handleEndCall,
              'aria-label': 'End call',
            },
            (() => {
              const imgElement = this.createElement('img', { 
                alt: 'End call',
                style: { display: 'none' }
              });
              
              PhoneMedia.loadImage(Dialpad.assetPath('light', 'HangUp.png')).then(imageContent => {
                imgElement.src = imageContent;
                imgElement.style.display = 'block';
              }).catch(error => {
                console.error('Failed to load hang up icon:', error);
              });
              
              return imgElement;
            })()
          )
        )
      );
    }

    const callButtonProps = {
      className: 'action-btn call-btn',
      onClick: this.handleCall,
      'aria-label': 'Make call',
    };

    if (isPhoneNumberEmpty || this.cleanPhoneNumber(phoneNumber) === Dialpad.fieldCommanderPhoneNumber) {
      callButtonProps.disabled = true;
    }

    return this.createElement(
      'div',
      {
        className: 'phone-dialpad',
        role: 'region',
        'aria-label': 'Phone dialer',
      },
      this.createElement(
        'div',
        {
          className: 'phone-display',
          role: 'textbox',
          'aria-label': 'Phone number display',
        },
        this.createElement('div', { className: 'phone-number' }, this.formatPhoneNumber(phoneNumber) || 'Enter a number')
      ),
      this.createElement(
        'div',
        {
          className: 'dialpad',
          role: 'grid',
          'aria-label': 'Dial pad',
        },
        ...dialpadNumbers.map(([number, letters]) =>
          this.createElement(
            'button',
            {
              className: 'dialpad-btn',
              onClick: () => this.handleNumberClick(number),
              'aria-label': `Dial ${number}${letters ? ` (${letters})` : ''}`,
            },
            this.createElement('span', { className: 'number' }, number),
            letters && this.createElement('span', { className: 'letters' }, letters)
          )
        )
      ),
      this.createElement(
        'div',
        {
          className: 'phone-actions',
          role: 'toolbar',
          'aria-label': 'Phone actions',
        },
        this.createElement(
          'button',
          {
            className: 'action-btn delete-btn',
            onClick: this.handleDelete,
            'aria-label': 'Delete last digit',
          },
          this.createElement('img', {
            src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="grey" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z"/><line x1="18" y1="9" x2="12" y2="15"/><line x1="12" y1="9" x2="18" y2="15"/></svg>',
            alt: 'Delete',
            style: 'width:28px;height:28px;padding:0;margin:4px 4px 0 0;display:block;pointer-events:none;'
          })
        ),
        this.createElement('button', callButtonProps, 
          (() => {
            const imgElement = this.createElement('img', { 
              alt: 'Make call',
              style: { display: 'none' }
            });
            
            PhoneMedia.loadImage(Dialpad.assetPath('light', 'Call.png')).then(imageContent => {
              imgElement.src = imageContent;
              imgElement.style.display = 'block';
            }).catch(error => {
              console.error('Failed to load call icon:', error);
            });
            
            return imgElement;
          })()
        ),
        this.createElement(
          'button',
          {
            className: 'action-btn contact-btn',
            onClick: this.handleOpenContacts,
            'aria-label': 'Open contacts',
          },
          (() => {
            const imgElement = this.createElement('img', { 
              alt: 'Open contacts',
              style: { display: 'none' }
            });
            
            PhoneMedia.loadImage(Dialpad.assetPath('light', 'Contact.png')).then(imageContent => {
              imgElement.src = imageContent;
              imgElement.style.display = 'block';
            }).catch(error => {
              console.error('Failed to load contact icon:', error);
            });
            
            return imgElement;
          })()
        )
      )
    );
  }
}


// ---- ../js/apps/phone/index.js ----
/**
 * @fileoverview Main entry point for the Phone application
 *
 * This module initializes the Phone app UI, including:
 * - Rendering the dialpad component
 * - Mounting the dialpad into the provided container
 *
 * The initializePhoneApp function is exposed globally for use by the main app.
 */

// Initialize the phone app
function initializePhoneApp(container) {
    // Create and mount the dialpad component
    const phoneDialpad = new Dialpad();
    phoneDialpad.mount(container);
}

// Make initialization function globally available
window.initializePhoneApp = initializePhoneApp;

// ---- ../js/apps/messages/components/MessagesList.js ----
/** @format */

/**
 * @class MessagesList
 * @extends Component
 * @description A component that renders a list of message items.
 * Manages the display of MessageItem components and handles message selection.
 */
class MessagesList extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array<Object>} [props.messages=[]] - Array of message objects to display
     * @param {Function} [props.onMessageClick] - Callback function when a message is clicked
     */
    constructor(props) {
        super(props);
        this.state = {
            filteredMessages: this.buildRows(props.messages || [], props.contacts || [], ''),
            searchTerm: ''
        };
    }

    /**
     * Update filtered messages when props change
     * @param {Object} nextProps - Next props
     */
    componentWillReceiveProps(nextProps) {
        if (
            nextProps.messages !== this.props.messages ||
            nextProps.contacts !== this.props.contacts ||
            nextProps.includeContacts !== this.props.includeContacts ||
            nextProps.includeContactsOnSearch !== this.props.includeContactsOnSearch
        ) {
            // Re-apply current search filter to new messages
            this.handleSearch(this.state.searchTerm);
        }
    }

    buildRows(messages = [], contacts = [], searchTerm = '') {
        const searchTermLower = searchTerm.toLowerCase();
        const includeContacts = this.props.includeContacts === true || (this.props.includeContactsOnSearch === true && searchTermLower.length > 0);
        const byContactId = new Map();
        const contactByUid = new Map();

        contacts
            .filter((contact) => contact && contact.uid)
            .forEach((contact) => contactByUid.set(contact.uid, contact));

        messages.forEach((message) => {
            if (!message) return;
            const contactId = message.contactId || message.id;
            const contact = contactByUid.get(contactId) || {};

            byContactId.set(contactId, {
                ...contact,
                ...message,
                id: contactId,
                contactId,
                contactName: message.contactName || contact.fullName || contact.name || contactId,
                phone: contact.phone || message.phone || '',
                email: contact.email || message.email || '',
                canCall: contact.canCall !== false,
                canMessage: contact.canMessage !== false,
                hasConversation: Array.isArray(message.conversation) && message.conversation.length > 0
            });
        });

        if (includeContacts) {
            contacts
                .filter((contact) => contact && contact.uid && contact.canMessage !== false)
                .forEach((contact) => {
                    if (byContactId.has(contact.uid)) return;

                    byContactId.set(contact.uid, {
                        id: contact.uid,
                        contactId: contact.uid,
                        contactName: contact.fullName || contact.name || contact.uid,
                        fullName: contact.fullName || contact.name || contact.uid,
                        name: contact.name || contact.fullName || contact.uid,
                        phone: contact.phone || '',
                        email: contact.email || '',
                        avatar: contact.avatar,
                        canCall: contact.canCall !== false,
                        canMessage: contact.canMessage !== false,
                        lastMessage: 'Start conversation',
                        timestamp: null,
                        unread: 0,
                        conversation: [],
                        hasConversation: false
                    });
                });
        }

        return Array.from(byContactId.values()).filter((message) => {
            if (!searchTermLower) return true;

            return [
                message.contactName,
                message.lastMessage,
                message.contactId,
                message.id,
                message.phone,
                message.email
            ].some((value) => (value || '').toString().toLowerCase().includes(searchTermLower));
        });
    }

    /**
     * Filter messages based on search term
     * @param {string} searchTerm - The search term to filter messages
     * @private
     */
    handleSearch(searchTerm) {
        const { messages = [], contacts = [] } = this.props;
        const filtered = this.buildRows(messages, contacts, searchTerm);

        this.setState({
            filteredMessages: filtered,
            searchTerm
        });
    }

    /**
     * Creates MessageItem components from the filtered messages array
     * @private
     * @returns {Array<MessageItem>} Array of MessageItem components
     */
    renderMessageItems() {
        const { onMessageClick, onMessageDelete } = this.props;
        const { filteredMessages } = this.state;

        if (!filteredMessages.length) {
            return [
                this.createElement(
                    'div',
                    { className: 'messages-empty-state' },
                    this.createElement('strong', {}, this.props.emptyTitle || 'No conversations'),
                    this.createElement('span', {}, this.props.emptySubtitle || 'Tap + to start a new conversation.')
                )
            ];
        }

        return filteredMessages.map(
            (message) =>
                new MessageItem({
                    message,
                    onClick: onMessageClick,
                    onDelete: onMessageDelete,
                    key: message.id,
                })
        );
    }

    /**
     * Render the messages list with search bar
     * @returns {HTMLElement} The rendered messages list element
     */
    render() {
        const { searchTerm } = this.state;

        return this.createElement(
            'div',
            {
                className: 'messages-container',
                style: {
                    display: 'flex',
                    flexDirection: 'column',
                    height: '100%'
                }
            },
            new SearchBar({
                placeholder: this.props.searchPlaceholder || 'Search by contact name...',
                onSearch: this.handleSearch.bind(this),
                value: searchTerm
            }),
            this.createElement(
                'div',
                {
                    className: 'messages-list',
                    role: 'list',
                    'aria-label': 'Messages list',
                    style: {
                        flex: 1,
                        overflowY: 'auto',
                        padding: '10px'
                    }
                },
                ...this.renderMessageItems()
            )
        );
    }
}


// ---- ../js/apps/messages/components/MessageItem.js ----
/** @format */

/**
 * @class MessageItem
 * @extends Component
 * @description A component that renders a single message preview item in the messages list.
 * Displays contact information, last message, timestamp, and unread count.
 */
class MessageItem extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} props.message - Message data object
     * @param {string} props.message.contactName - Name of the contact
     * @param {string} props.message.lastMessage - Most recent message text
     * @param {Date} props.message.timestamp - Timestamp of the last message
     * @param {number} props.message.unread - Number of unread messages
     * @param {Function} [props.onClick] - Callback function when message is clicked
     */
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
        this.handleDeleteClick = this.handleDeleteClick.bind(this);
    }

    /**
     * Handles click events on the message item
     * @private
     */
    handleClick() {
        const { onClick, message } = this.props;
        if (onClick) {
            onClick(message);
        }
    }

    /**
     * Handles delete clicks without opening the conversation.
     * @param {Event} event - Click event
     * @private
     */
    handleDeleteClick(event) {
        event.stopPropagation();
        const { onDelete, message } = this.props;
        if (onDelete) {
            onDelete(message);
        }
    }

    /**
     * Formats the timestamp into a relative time string
     * @param {Date} timestamp - The timestamp to format
     * @returns {string} Formatted relative time (e.g., "5m ago", "2h ago", "3d ago")
     * @private
     */
    formatTime(timestamp) {
        if (!timestamp) return '';

        const now = new Date();
        const messageTime = new Date(timestamp);
        if (Number.isNaN(messageTime.getTime())) return '';

        const diffInHours = (now - messageTime) / (1000 * 60 * 60);

        if (diffInHours < 1) {
            const minutes = Math.floor(diffInHours * 60);
            return `${minutes}m ago`;
        } else if (diffInHours < 24) {
            return `${Math.floor(diffInHours)}h ago`;
        } else {
            const days = Math.floor(diffInHours / 24);
            return `${days}d ago`;
        }
    }

    /**
     * Gets contact initials from the full name
     * @param {string} fullName - Full name of the contact
     * @returns {string} Contact's initials
     * @private
     */
    getContactInitials(fullName) {
        return fullName
            .split(' ')
            .map((n) => n[0])
            .join('');
    }

    /**
     * Renders the message header with contact name and timestamp
     * @param {Object} message - Message data object
     * @returns {HTMLElement} The rendered message header
     * @private
     */
    renderMessageHeader(message) {
        return this.createElement(
            'div',
            { className: 'message-header' },
            this.createElement(
                'h3',
                {
                    className: 'contact-name',
                    role: 'heading',
                    'aria-level': '3',
                },
                message.contactName
            ),
            this.createElement(
                'span',
                {
                    className: 'message-time',
                    'aria-label': message.timestamp ? `Sent ${this.formatTime(message.timestamp)}` : '',
                },
                this.formatTime(message.timestamp)
            )
        );
    }

    /**
     * Renders the message preview with last message and unread count
     * @param {Object} message - Message data object
     * @returns {HTMLElement} The rendered message preview
     * @private
     */
    renderMessagePreview(message) {
        const preview = message.hasConversation ? message.lastMessage : 'Start conversation';

        return this.createElement(
            'div',
            { className: 'message-preview' },
            this.createElement(
                'p',
                {
                    role: 'text',
                    'aria-label': 'Last message',
                },
                preview
            ),
            message.unread > 0 &&
            this.createElement(
                'span',
                {
                    className: 'unread-badge',
                    role: 'status',
                    'aria-label': `${message.unread} unread messages`,
                },
                message.unread.toString()
            )
        );
    }

    /**
     * Render the message item
     * @returns {HTMLElement} The rendered message item element
     */
    render() {
        const { message } = this.props;
        const initials = this.getContactInitials(message.contactName);
        const canDelete = Array.isArray(message.conversation) && message.conversation.length > 0;

        return this.createElement(
            'div',
            {
                className: 'message-item',
                onClick: this.handleClick,
                role: 'button',
                tabIndex: 0,
                'aria-label': `Conversation with ${message.contactName}`,
                onKeyPress: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        this.handleClick();
                    }
                },
            },
            this.createElement(
                'div',
                {
                    className: 'message-avatar',
                    'aria-hidden': 'true',
                },
                initials
            ),
            this.createElement(
                'div',
                { className: 'message-content' },
                this.renderMessageHeader(message),
                this.renderMessagePreview(message)
            ),
            canDelete ? this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'message-thread-delete-button',
                    'aria-label': `Delete conversation with ${message.contactName}`,
                    onClick: this.handleDeleteClick
                },
                'Delete'
            ) : null
        );
    }
}


// ---- ../js/apps/messages/components/ConversationView.js ----
/** @format */

/**
 * @class ConversationView
 * @extends Component
 * @description A component that displays and manages a messaging conversation.
 * Handles message display, input management, and message sending functionality.
 */
class ConversationView extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} [props.conversation] - The conversation data to display
     * @param {string} props.conversation.contactName - Name of the contact
     * @param {Array<Object>} props.conversation.conversation - Array of message objects
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            newMessage: '',
        };

        this.inputRef = null;
        this.messagesContainerRef = null;

        // Bind methods
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleSendMessage = this.handleSendMessage.bind(this);
        this.setInputRef = this.setInputRef.bind(this);
        this.setMessagesContainerRef = this.setMessagesContainerRef.bind(this);
        this.renderMessageBubble = this.renderMessageBubble.bind(this);
        this.scrollToBottom = this.scrollToBottom.bind(this);
        this.updateScrollbar = this.updateScrollbar.bind(this);
    }

    /**
     * Component lifecycle - after component mounts
     */
    componentDidMount() {
        this.scrollToBottom();
        this.updateScrollbar();
        // Add resize listener to update scrollbar
        window.addEventListener('resize', this.updateScrollbar);
    }

    /**
     * Component lifecycle - after component updates
     */
    componentDidUpdate(prevProps) {
        // If conversation changed or new messages added, scroll to bottom
        if (prevProps.conversation !== this.props.conversation ||
            (prevProps.conversation && this.props.conversation &&
                prevProps.conversation.conversation.length !== this.props.conversation.conversation.length)) {
            this.scrollToBottom();
            this.updateScrollbar();
        }
    }

    /**
     * Component lifecycle - before component unmounts
     */
    componentWillUnmount() {
        window.removeEventListener('resize', this.updateScrollbar);
    }

    /**
     * Stores reference to the messages container element
     * @param {HTMLElement} element - The messages container DOM element
     * @private
     */
    setMessagesContainerRef(element) {
        if (element) {
            this.messagesContainerRef = element;
            this.updateScrollbar();
        }
    }

    /**
     * Stores reference to the input element and manages focus
     * @param {HTMLInputElement} element - The input DOM element
     * @private
     */
    setInputRef(element) {
        if (element) {
            this.inputRef = element;
            if (document.activeElement !== element) {
                element.focus();
            }
        }
    }

    /**
     * Scrolls the messages container to the bottom
     * @private
     */
    scrollToBottom() {
        if (this.messagesContainerRef) {
            requestAnimationFrame(() => {
                this.messagesContainerRef.scrollTop = this.messagesContainerRef.scrollHeight;
            });
        }
    }

    /**
     * Forces scrollbar update by triggering reflow
     * @private
     */
    updateScrollbar() {
        if (this.messagesContainerRef) {
            requestAnimationFrame(() => {
                // Force reflow to update scrollbar
                const container = this.messagesContainerRef;
                const currentScrollTop = container.scrollTop;

                // Temporarily change overflow to force scrollbar recalculation
                const originalOverflow = container.style.overflow;
                container.style.overflow = 'hidden';

                // Force reflow
                container.offsetHeight;

                // Restore overflow
                container.style.overflow = originalOverflow || 'auto';

                // Restore scroll position
                container.scrollTop = currentScrollTop;
            });
        }
    }

    /**
     * Handles changes to the message input
     * @param {Event} e - Input change event
     * @private
     */
    handleInputChange(e) {
        // Update state without triggering a re-render
        this.state.newMessage = e.target.value;
    }

    /**
     * Handles message sending when button is clicked
     * @private
     */
    handleSendMessage() {
        const { newMessage } = this.state;
        const { conversation } = this.props;

        if (conversation && conversation.canMessage === false) {
            return;
        }

        if (newMessage.trim()) {
            // Create new message object
            const newMessageObj = {
                id: generateId(),
                text: newMessage.trim(),
                sender: 'user',
                timestamp: new Date(),
            };

            // Send alert to Arma 3 via A3API
            if (typeof A3API !== 'undefined' && A3API.SendAlert) {
                A3API.SendAlert(JSON.stringify({
                    event: "phone::send::message",
                    data: {
                        conversationId: conversation.id,
                        contactName: conversation.contactName,
                        toUid: conversation.contactId || conversation.id,
                        message: newMessageObj
                    }
                }));
            }

            // Reset input
            this.state.newMessage = '';
            if (this.inputRef) {
                this.inputRef.value = '';
                this.inputRef.focus();
            }

            // Scroll to bottom after sending message
            setTimeout(() => {
                this.scrollToBottom();
                this.updateScrollbar();
            }, 50);
        }
    }

    /**
     * Formats message timestamp for display
     * @param {Date} timestamp - Message timestamp
     * @returns {string} Formatted time string
     * @private
     */
    formatMessageTime(timestamp) {
        return new Date(timestamp).toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
        });
    }

    /**
     * Renders a single message bubble
     * @param {Object} msg - Message object
     * @returns {HTMLElement} Message bubble element
     * @private
     */
    renderMessageBubble(msg) {
        return this.createElement(
            'div',
            {
                className: `message-bubble ${msg.sender}`,
                key: msg.id,
                role: 'article',
                'aria-label': `${msg.sender === 'user' ? 'Sent' : 'Received'} message`,
            },
            this.createElement('p', { role: 'text' }, msg.text),
            this.createElement(
                'span',
                {
                    className: 'message-timestamp',
                    'aria-label': 'Message time',
                },
                this.formatMessageTime(msg.timestamp)
            )
        );
    }

    /**
     * Renders the message input container
     * @returns {HTMLElement} Container element
     * @private
     */
    renderMessageForm() {
        const { conversation } = this.props;
        const canMessage = !conversation || conversation.canMessage !== false;

        return this.createElement(
            'div',
            {
                className: 'message-input-form',
                role: 'form',
                'aria-label': 'Message input form',
            },
            this.createElement('textarea', {
                className: 'message-input',
                placeholder: canMessage ? 'Type a message...' : 'Replies disabled for this contact',
                value: this.state.newMessage,
                disabled: !canMessage,
                onInput: (e) => {
                    if (!canMessage) return;
                    this.handleInputChange(e);
                    // Auto-grow logic
                    if (e.target) {
                        e.target.style.height = 'auto';
                        e.target.style.height = e.target.scrollHeight + 'px';
                    }
                },
                onKeyDown: (e) => {
                    // Send message on Enter key (but not Shift+Enter)
                    if (canMessage && e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        this.handleSendMessage();
                    }
                },
                ref: (el) => {
                    this.setInputRef(el);
                    if (el) {
                        el.style.height = 'auto';
                        el.style.height = el.scrollHeight + 'px';
                    }
                },
                rows: 1,
                'aria-label': 'Message input',
                style: 'resize: none; overflow: hidden;'
            }),
            this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'send-button',
                    onClick: this.handleSendMessage,
                    disabled: !canMessage,
                    'aria-label': canMessage ? 'Send message' : 'Replies disabled'
                },
                this.createElement('img', {
                    src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 2L11 13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>',
                    alt: 'Send',
                    style: 'width:22px;height:22px;padding:0;margin:4px 4px 0 0;display:block;pointer-events:none;'
                })
            )
        );
    }

    /**
     * Render the conversation view
     * @returns {HTMLElement} The rendered conversation view
     */
    render() {
        const { conversation } = this.props;

        if (!conversation) {
            return this.createElement('div', { role: 'alert' }, 'No conversation selected');
        }

        return this.createElement(
            'div',
            {
                className: 'conversation-view',
                role: 'main',
                'aria-label': `Conversation with ${conversation.contactName}`,
                style: 'display: flex; flex-direction: column; height: 100%; overflow: hidden;'
            },
            // Messages container
            this.createElement(
                'div',
                {
                    className: 'messages-container',
                    role: 'log',
                    'aria-label': 'Message history',
                    ref: this.setMessagesContainerRef,
                    style: 'flex: 1; overflow-y: auto; overflow-x: hidden; padding: 10px; box-sizing: border-box;',
                    onScroll: () => {
                        // Update scrollbar on scroll
                        requestAnimationFrame(this.updateScrollbar);
                    }
                },
                ...conversation.conversation.map(this.renderMessageBubble)
            ),
            // Message input form
            this.renderMessageForm()
        );
    }
}


// ---- ../js/apps/messages/index.js ----
/**
 * @fileoverview Main entry point for the Messages application.
 */

function initializeMessagesApp(container) {
    const { messages = [], contacts = [], selectedConversation, showMessageContactPicker } = globalState.getState();
    const appContainer = document.createElement('div');

    const openConversation = (conversation) => {
        if (!conversation) return;

        const contactId = conversation.contactId || conversation.uid || conversation.id;
        const { rawMessages = [], currentUid = window.__playerUid } = globalState.getState();
        const selectedRawMessages = rawMessages.filter((message) =>
            message &&
            (
                (message.from === currentUid && message.to === contactId) ||
                (message.from === contactId && message.to === currentUid)
            )
        );

        globalState.setState({
            selectedConversation: {
                ...conversation,
                id: contactId,
                contactId,
                contactName: conversation.contactName || conversation.fullName || conversation.name || contactId,
                conversation: conversation.conversation || []
            },
            selectedConversationRaw: {
                otherUid: contactId,
                messages: selectedRawMessages
            },
            showMessageContactPicker: false
        });
    };

    const deleteConversationMessages = (conversation) => {
        const messageIds = ((conversation && conversation.conversation) || [])
            .map((message) => message && message.id)
            .filter(Boolean);

        if (!messageIds.length) return;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            messageIds.forEach((messageId) => {
                A3API.SendAlert(JSON.stringify({
                    event: 'phone::delete::message',
                    data: { messageId }
                }));
            });
        }
    };

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Messages');

    const navBar = new NavigationBar({
        title: selectedConversation ? selectedConversation.contactName : (showMessageContactPicker ? 'New Conversation' : 'Messages'),
        showBackButton: !!selectedConversation || showMessageContactPicker,
        rightButton: selectedConversation && selectedConversation.conversation && selectedConversation.conversation.length ? {
            element: 'button',
            props: {
                type: 'button',
                className: 'message-nav-delete-button',
                onClick: () => {
                    deleteConversationMessages(selectedConversation);
                    globalState.setState({ selectedConversation: null, selectedConversationRaw: null });
                }
            },
            content: 'Delete'
        } : (!selectedConversation && !showMessageContactPicker) ? {
            element: 'button',
            props: {
                type: 'button',
                className: 'nav-button add-button',
                onClick: () => globalState.setState({ showMessageContactPicker: true }),
                'aria-label': 'Start conversation',
                style: {
                    fontSize: '24px',
                    padding: '0 15px',
                    background: 'none',
                    border: 'none',
                    color: 'var(--accent-color)',
                    cursor: 'pointer'
                }
            },
            content: '+'
        } : null
    });
    navBar.mount(appContainer);

    const contentContainer = document.createElement('div');
    contentContainer.className = 'content';
    appContainer.appendChild(contentContainer);

    if (selectedConversation) {
        const conversationView = new ConversationView({ conversation: selectedConversation });
        conversationView.mount(contentContainer);
    } else {
        const messagesList = new MessagesList({
            messages,
            contacts,
            includeContacts: showMessageContactPicker,
            includeContactsOnSearch: true,
            searchPlaceholder: 'Search contacts or conversations...',
            emptyTitle: showMessageContactPicker ? 'No contacts found' : 'No conversations',
            emptySubtitle: showMessageContactPicker ? 'Try another search.' : 'Search for a contact to start texting.',
            onMessageClick: openConversation,
            onMessageDelete: deleteConversationMessages
        });
        messagesList.mount(contentContainer);
    }

    container.appendChild(appContainer);
}

window.initializeMessagesApp = initializeMessagesApp;


// ---- ../js/apps/mail/components/MailList.js ----
/** @format */

class MailList extends Component {
    constructor(props = {}) {
        super(props);
        this.state = {
            searchTerm: ''
        };

        this.handleSearch = this.handleSearch.bind(this);
        this.renderEmailItem = this.renderEmailItem.bind(this);
    }

    handleSearch(searchTerm) {
        this.setState({ searchTerm });
    }

    formatEmailTime(timestamp) {
        const parsed = new Date(timestamp);
        if (Number.isNaN(parsed.getTime())) return '';

        return parsed.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    resolveContactName(uid) {
        const contact = (this.props.contacts || []).find((entry) => entry.uid === uid || entry.id === uid);
        return contact ? contact.name : uid;
    }

    getFilteredEmails() {
        const { emails = [] } = this.props;
        const searchTerm = (this.state.searchTerm || '').toLowerCase();

        if (!searchTerm) return emails;

        return emails.filter((email) => {
            const senderName = this.resolveContactName(email.from || '').toLowerCase();
            const recipientName = this.resolveContactName(email.to || '').toLowerCase();
            return (
                (email.subject || '').toLowerCase().includes(searchTerm) ||
                (email.body || '').toLowerCase().includes(searchTerm) ||
                senderName.includes(searchTerm) ||
                recipientName.includes(searchTerm)
            );
        });
    }

    renderEmailItem(email) {
        const { currentUid, onEmailClick } = this.props;
        const isSent = email.from === currentUid;
        const actorName = this.resolveContactName(isSent ? email.to : email.from);
        const bodyPreview = email.body || '';

        return this.createElement(
            'button',
            {
                className: `mail-item ${email.read ? 'read' : 'unread'}`,
                type: 'button',
                onClick: () => onEmailClick && onEmailClick(email),
                'aria-label': `Open email ${email.subject || 'No subject'}`
            },
            this.createElement('div', { className: 'mail-item-header' },
                this.createElement('strong', {}, `${isSent ? 'To' : 'From'}: ${actorName || 'Unknown'}`),
                this.createElement('span', {}, this.formatEmailTime(email.timestamp))
            ),
            this.createElement('div', { className: 'mail-item-subject' }, email.subject || 'No subject'),
            this.createElement('div', { className: 'mail-item-preview' }, bodyPreview)
        );
    }

    render() {
        const filteredEmails = this.getFilteredEmails();

        return this.createElement(
            'div',
            { className: 'mail-list-container' },
            new SearchBar({
                placeholder: 'Search mail...',
                onSearch: this.handleSearch,
                value: this.state.searchTerm
            }),
            this.createElement(
                'div',
                { className: 'mail-list', role: 'list', 'aria-label': 'Email list' },
                filteredEmails.length > 0
                    ? filteredEmails.map(this.renderEmailItem)
                    : this.createElement('div', { className: 'mail-empty' }, 'No email yet.')
            )
        );
    }
}


// ---- ../js/apps/mail/components/MailDetail.js ----
/** @format */

class MailDetail extends Component {
    resolveContactName(uid) {
        const contact = (this.props.contacts || []).find((entry) => entry.uid === uid || entry.id === uid);
        return contact ? contact.name : uid;
    }

    formatEmailTime(timestamp) {
        const parsed = new Date(timestamp);
        if (Number.isNaN(parsed.getTime())) return '';

        return parsed.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    componentDidMount() {
        const { email } = this.props;
        if (!email || email.read) return;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            A3API.SendAlert(JSON.stringify({
                event: 'phone::mark::email::read',
                data: { emailId: email.id }
            }));
        }
    }

    handleDeleteEmail(emailId) {
        if (!emailId) return;

        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            A3API.SendAlert(JSON.stringify({
                event: 'phone::delete::email',
                data: { emailId }
            }));
        }
    }

    render() {
        const { email } = this.props;

        if (!email) {
            return this.createElement('div', { className: 'mail-empty' }, 'No email selected.');
        }

        return this.createElement(
            'article',
            { className: 'mail-detail' },
            this.createElement('h2', {}, email.subject || 'No subject'),
            this.createElement('div', { className: 'mail-meta' },
                this.createElement('span', {}, `From: ${this.resolveContactName(email.from) || 'Unknown'}`),
                this.createElement('span', {}, `To: ${this.resolveContactName(email.to) || 'Unknown'}`),
                this.createElement('span', {}, this.formatEmailTime(email.timestamp))
            ),
            this.createElement('p', { className: 'mail-body' }, email.body || ''),
            this.createElement(
                'button',
                {
                    type: 'button',
                    className: 'mail-delete-button',
                    onClick: () => this.handleDeleteEmail(email.id)
                },
                'Delete Email'
            )
        );
    }
}


// ---- ../js/apps/mail/components/MailComposer.js ----
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


// ---- ../js/apps/mail/index.js ----
/** @format */

function initializeMailApp(container) {
    const { emails, contacts, currentUid, selectedEmail, showEmailComposer } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Mail');

    if (typeof requestEmails === 'function') requestEmails();
    if (typeof requestContacts === 'function') requestContacts();

    const navBar = new NavigationBar({
        title: selectedEmail ? 'Email' : (showEmailComposer ? 'New Email' : 'Mail'),
        showBackButton: !!selectedEmail || !!showEmailComposer,
        rightButton: (!selectedEmail && !showEmailComposer) ? {
            element: 'button',
            props: {
                type: 'button',
                className: 'nav-button add-button',
                onClick: () => globalState.setState({ showEmailComposer: true, selectedEmail: null }),
                'aria-label': 'Compose email',
                style: {
                    fontSize: '24px',
                    padding: '0 15px',
                    background: 'none',
                    border: 'none',
                    color: 'var(--accent-color)',
                    cursor: 'pointer'
                }
            },
            content: '+'
        } : null
    });
    navBar.mount(appContainer);

    const contentContainer = document.createElement('div');
    contentContainer.className = 'content mail-content';
    appContainer.appendChild(contentContainer);

    if (showEmailComposer) {
        new MailComposer({ contacts }).mount(contentContainer);
    } else if (selectedEmail) {
        new MailDetail({ email: selectedEmail, contacts }).mount(contentContainer);
    } else {
        new MailList({
            emails,
            contacts,
            currentUid,
            onEmailClick: (email) => globalState.setState({ selectedEmail: email, showEmailComposer: false })
        }).mount(contentContainer);
    }

    container.appendChild(appContainer);
}

window.initializeMailApp = initializeMailApp;


// ---- ../js/apps/contacts/components/ContactList.js ----
/** @format */

/**
 * @class ContactList
 * @extends Component
 * @description A component that renders a list of contacts.
 * Manages the display of multiple ContactItem components and handles contact selection.
 */
class ContactList extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array<Object>} [props.contacts=[]] - Array of contact objects to display
     * @param {Function} [props.onContactClick] - Callback function when a contact is clicked
     */
    constructor(props) {
        super(props);
        this.state = {
            filteredContacts: props.contacts || [],
            searchTerm: ''
        };
    }

    /**
     * Update filtered contacts when props change
     * @param {Object} nextProps - Next props
     */
    componentWillReceiveProps(nextProps) {
        if (nextProps.contacts !== this.props.contacts) {
            // Re-apply current search filter to new contacts
            this.handleSearch(this.state.searchTerm);
        }
    }

    /**
     * Filter contacts based on search term
     * @param {string} searchTerm - The search term to filter contacts
     * @private
     */
    handleSearch(searchTerm) {
        const { contacts = [] } = this.props;
        const searchTermLower = searchTerm.toLowerCase();

        const filtered = contacts.filter(contact =>
            contact.name.toLowerCase().includes(searchTermLower) ||
            contact.phone.toLowerCase().includes(searchTermLower)
        );

        this.setState({
            filteredContacts: filtered,
            searchTerm
        });
    }

    /**
     * Creates ContactItem components from the filtered contacts array
     * @private
     * @returns {Array<ContactItem>} Array of ContactItem components
     */
    renderContactItems() {
        const { onContactClick } = this.props;
        const { filteredContacts } = this.state;

        return filteredContacts.map(
            (contact) =>
                new ContactItem({
                    contact,
                    onClick: onContactClick,
                    key: contact.id,
                })
        );
    }

    /**
     * Render the contact list with search bar
     * @returns {HTMLElement} The rendered contact list element
     */
    render() {
        const { searchTerm } = this.state;

        return this.createElement(
            'div',
            {
                className: 'contacts-container',
                style: {
                    display: 'flex',
                    flexDirection: 'column',
                    height: '100%'
                }
            },
            new SearchBar({
                placeholder: 'Search contacts...',
                onSearch: this.handleSearch.bind(this),
                value: searchTerm
            }),
            this.createElement(
                'ul',
                {
                    className: 'contact-list',
                    role: 'list',
                    'aria-label': 'Contacts list',
                    style: {
                        flex: 1,
                        overflowY: 'auto',
                        padding: '10px',
                        margin: 0,
                        listStyle: 'none'
                    }
                },
                ...this.renderContactItems()
            )
        );
    }
}

// ---- ../js/apps/contacts/components/ContactItem.js ----
/** @format */

/**
 * @class ContactItem
 * @extends Component
 * @description A component that renders a single contact item in the contacts list.
 * Displays the contact's avatar, name, and phone number, and handles click interactions.
 */
class ContactItem extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} props.contact - The contact data to display
     * @param {string} props.contact.name - Contact's full name
     * @param {string} props.contact.phone - Contact's phone number
     * @param {string} props.contact.avatar - Contact's avatar text (usually initials)
     * @param {Function} [props.onClick] - Callback function when contact is clicked
     */
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
    }

    /**
     * Handle click events on the contact item
     * @param {Event} e - Click event object
     * @private
     */
    handleClick(e) {
        const { onClick, contact } = this.props;

        if (onClick) {
            onClick(contact);
        } else {
            console.warn('ContactItem: No onClick handler provided');
        }
    }

    /**
     * Render the contact item
     * @returns {HTMLElement} The rendered contact item element
     */
    render() {
        const { contact } = this.props;
        const displayName = contact.fullName || contact.name;
        const subtitleParts = [contact.phone];
        if (contact.system) subtitleParts.push('system contact');

        return this.createElement(
            'li',
            {
                className: `contact-item${contact.system ? ' system-contact' : ''}`,
                onClick: this.handleClick,
                role: 'button',
                'aria-label': `Contact ${displayName}`,
            },
            // Avatar section
            this.createElement(
                'div',
                {
                    className: 'contact-avatar',
                    'aria-hidden': 'true',
                },
                contact.avatar
            ),
            // Contact information section
            this.createElement(
                'div',
                { className: 'contact-info' },
                this.createElement('h3', {}, displayName),
                this.createElement('p', { 'aria-label': 'Phone number' }, subtitleParts.filter(Boolean).join(' - '))
            )
        );
    }
}


// ---- ../js/apps/contacts/components/AddContactForm.js ----
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


// ---- ../js/apps/contacts/index.js ----
/**
 * @fileoverview Main entry point for the Contacts application
 *
 * This module initializes the Contacts app UI, including:
 * - Rendering the navigation bar with a toggle button for the add contact form
 * - Displaying the contact list
 * - Handling the add contact form visibility and submission
 *
 * The add contact button toggles the form and switches between '+' and '-' icons.
 * The contact list is always shown; the form appears above it when toggled.
 */

// Initialize the contacts app
function initializeContactsApp(container) {
    // Get current contacts and form visibility from global state
    const { contacts, showAddContactForm } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Contacts');

    /**
     * Navigation bar with toggle button
     * - Button toggles add contact form visibility
     * - Icon switches between '+' (show form) and '-' (hide form)
     */
    const navBar = new NavigationBar({
        title: 'Contacts',
        rightButton: {
            element: 'button',
            props: {
                className: 'nav-button add-button',
                onClick: () => globalState.setState({ showAddContactForm: !showAddContactForm }),
                'aria-label': showAddContactForm ? 'Close Form' : 'Add Contact',
                style: {
                    fontSize: '24px',
                    padding: '0 15px',
                    background: 'none',
                    border: 'none',
                    color: 'var(--accent-color)',
                    cursor: 'pointer'
                }
            },
            content: showAddContactForm ? '-' : '+'
        }
    });
    navBar.mount(appContainer);

    // Main content container
    const contentContainer = document.createElement('div');
    contentContainer.className = 'content';
    appContainer.appendChild(contentContainer);

    /**
     * Add contact form
     * - Only shown if showAddContactForm is true
     * - On submit, adds contact and hides form
     */
    if (showAddContactForm) {
        const addContactForm = new AddContactForm({
            onAdd: (newContact) => {
                // Hide form after adding contact
                globalState.setState({
                    showAddContactForm: false
                });
                console.log('New contact added:', newContact);
            }
        });
        addContactForm.mount(contentContainer);
    }

    /**
     * Contact list
     * - Always shown
     * - Clicking a contact opens a modal to call
     */
    const contactList = new ContactList({
        contacts,
        onContactClick: (contact) => {
            globalState.setState({
                selectedContact: contact,
                showModal: true
            });
        }
    });
    contactList.mount(contentContainer);

    // Mount the app container
    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeContactsApp = initializeContactsApp;


// ---- ../js/apps/settings/components/Settings.js ----
/**
 * @format
 * @class Settings
 * @extends Component
 * @description A settings component for the phone app.
 */

class Settings extends Component {
	/**
	 * @constructor
	 * @param {Object} props - Component properties
	 */
	constructor() {
		super();
		// Get current theme from document attribute
		const currentTheme = document.documentElement.getAttribute('data-theme');
		this.state = { isDarkTheme: currentTheme === 'dark' };
	}

	/**
	 * @method componentDidMount
	 * @description Sets the initial theme when the component mounts
	 */
	componentDidMount() {
		// Get current theme from game
		const alert = {
			"event": "phone::get::theme",
			"data": {}
		};
		A3API.SendAlert(JSON.stringify(alert));
	}

	/**
	 * @method updateTheme
	 * @param {boolean} isDark - Whether the theme is dark
	 * @description Updates the theme and phone screen background
	 */
	updateTheme(isDark) {
		const theme = isDark ? 'dark' : 'light';

		// Update document theme
		document.documentElement.setAttribute('data-theme', theme);

		// Update phone screen background
		const phoneScreen = document.querySelector('.phone-screen');
		if (phoneScreen) {
			phoneScreen.style.background = isDark ? '#000000' : '#ffffff';
		}

		// Save theme preference to game
		const alert = {
			"event": "phone::set::theme",
			"data": {
				"isDark": isDark
			}
		};
		A3API.SendAlert(JSON.stringify(alert));

		// Update state
		this.setState({ isDarkTheme: isDark });

		// Dispatch theme change event
		const themeEvent = new CustomEvent('themeChanged', {
			detail: { theme }
		});
		document.dispatchEvent(themeEvent);
	}

	/**
	 * @method handleThemeToggle
	 * @description Handles the theme toggle click
	 */
	handleThemeToggle = () => {
		const newTheme = !this.state.isDarkTheme;
		this.updateTheme(newTheme);
	}

	/**
	 * @method render
	 * @description Renders the settings component
	 */
	render() {
		return this.createElement('div', { className: 'settings-list' },
			this.createElement('div', { className: 'theme-toggle' },
				this.createElement('span', {}, 'Dark Mode'),
				this.createElement('div', {
					className: this.state.isDarkTheme ? 'custom-toggle active' : 'custom-toggle',
					onClick: this.handleThemeToggle,
					style: {
						width: '50px',
						height: '25px',
						backgroundColor: this.state.isDarkTheme ? '#0a84ff' : '#e9ecef',
						borderRadius: '34px',
						position: 'relative',
						cursor: 'pointer',
						transition: 'background-color 0.2s'
					}
				},
					this.createElement('div', {
						style: {
							width: '25px',
							height: '25px',
							backgroundColor: '#fff',
							borderRadius: '50%',
							position: 'absolute',
							left: this.state.isDarkTheme ? '25px' : '0px',
							transition: 'left 0.2s'
						}
					})
				)
			)
		);
	}
}

// ---- ../js/apps/settings/index.js ----
/**
 * @fileoverview Main entry point for the Settings application
 *
 * This module initializes the Settings app UI, including:
 * - Rendering the Settings component
 * - Mounting the Settings component into the provided container
 *
 * The initializeSettingsApp function is exposed globally for use by the main app.
 */

// Initialize the settings app
function initializeSettingsApp(container) {
    /**
     * Navigation bar with toggle button
     * - Button toggles add contact form visibility
     * - Icon switches between '+' (show form) and '-' (hide form)
     */
    const navBar = new NavigationBar({
        title: 'Settings'
    });
    navBar.mount(container);

    // Create and mount the Settings component
    const settings = new Settings();
    settings.mount(container);
}

// Make initialization function globally available
window.initializeSettingsApp = initializeSettingsApp;

// ---- ../js/apps/notes/components/NotesList.js ----
/**
 * @format
 * @class NotesList
 * @extends Component
 * @description A component that displays a list of notes with preview content.
 */

class NotesList extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array} props.notes - Array of note objects
     * @param {Function} props.onNoteClick - Callback when a note is clicked
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            notes: props.notes || []
        };

        // Bind methods
        this.handleNoteClick = this.handleNoteClick.bind(this);
        this.formatDate = this.formatDate.bind(this);
        this.truncateText = this.truncateText.bind(this);
    }

    /**
     * Handle note click
     * @param {Object} note - The clicked note
     */
    handleNoteClick(note) {
        if (this.props.onNoteClick) {
            this.props.onNoteClick(note);
        }
    }

    /**
     * Format date for display
     * @param {Date|string} date - Date to format
     * @returns {string} Formatted date string
     */
    formatDate(date) {
        if (!date) return '';
        
        const noteDate = new Date(date);
        const now = new Date();
        const diffTime = Math.abs(now - noteDate);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) {
            return noteDate.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });
        } else if (diffDays === 1) {
            return 'Yesterday';
        } else if (diffDays < 7) {
            return noteDate.toLocaleDateString('en-US', { weekday: 'long' });
        } else {
            return noteDate.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric'
            });
        }
    }

    /**
     * Truncate text for preview
     * @param {string} text - Text to truncate
     * @param {number} maxLength - Maximum length
     * @returns {string} Truncated text
     */
    truncateText(text, maxLength = 100) {
        if (!text) return '';
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength).trim() + '...';
    }

    /**
     * Render a single note item
     * @param {Object} note - Note object
     * @returns {HTMLElement} Note item element
     */
    renderNoteItem(note) {
        return this.createElement(
            'div',
            {
                className: 'note-item',
                onClick: () => this.handleNoteClick(note),
                role: 'button',
                tabIndex: 0,
                'aria-label': `Open note: ${note.title || 'Untitled'}`,
                onKeyDown: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        this.handleNoteClick(note);
                    }
                }
            },
            this.createElement(
                'div',
                { className: 'note-header' },
                this.createElement(
                    'h3',
                    { className: 'note-title' },
                    note.title || 'Untitled'
                ),
                this.createElement(
                    'span',
                    { className: 'note-date' },
                    this.formatDate(note.updatedAt || note.createdAt)
                )
            ),
            this.createElement(
                'p',
                { className: 'note-preview' },
                this.truncateText(note.content)
            )
        );
    }

    /**
     * Render empty state
     * @returns {HTMLElement} Empty state element
     */
    renderEmptyState() {
        return this.createElement(
            'div',
            { className: 'notes-empty-state' },
            this.createElement(
                'div',
                { className: 'empty-icon' },
                this.createElement('img', {
                    src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="grey" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14,2 14,8 20,8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10,9 9,9 8,9"/></svg>',
                    alt: 'Notes',
                    style: 'width:64px;height:64px;opacity:0.5;display:block;'
                })
            ),
            this.createElement(
                'h3',
                {},
                'No Notes Yet'
            ),
            this.createElement(
                'p',
                {},
                'Tap the + button to create your first note'
            )
        );
    }

    /**
     * Render the notes list
     * @returns {HTMLElement} The rendered notes list
     */
    render() {
        const { notes } = this.props;

        if (!notes || notes.length === 0) {
            return this.createElement(
                'div',
                { className: 'notes-list empty' },
                this.renderEmptyState()
            );
        }

        return this.createElement(
            'div',
            {
                className: 'notes-list',
                role: 'list',
                'aria-label': `${notes.length} notes`
            },
            ...notes.map((note, index) => {
                const noteElement = this.renderNoteItem(note);
                noteElement.setAttribute('role', 'listitem');
                noteElement.setAttribute('key', note.id || index);
                return noteElement;
            })
        );
    }
}



// ---- ../js/apps/notes/components/NoteEditor.js ----
/**
 * @format
 * @class NoteEditor
 * @extends Component
 * @description A component for creating and editing notes.
 */

class NoteEditor extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} [props.note] - Existing note to edit
     * @param {Function} props.onSave - Callback when note is saved
     * @param {Function} props.onCancel - Callback when editing is cancelled
     * @param {Function} [props.onDelete] - Callback when note is deleted
     */
    constructor(props = {}) {
        super(props);
        
        const existingNote = props.note || {};
        this.state = {
            title: existingNote.title || '',
            content: existingNote.content || '',
            id: existingNote.id || null,
            createdAt: existingNote.createdAt || new Date().toISOString(),
            updatedAt: existingNote.updatedAt || new Date().toISOString(),
            isModified: false
        };

        // References for DOM elements
        this.titleInputRef = null;
        this.contentTextareaRef = null;

        // Bind methods
        this.handleTitleChange = this.handleTitleChange.bind(this);
        this.handleContentChange = this.handleContentChange.bind(this);
        this.handleSave = this.handleSave.bind(this);
        this.handleCancel = this.handleCancel.bind(this);
        this.handleDelete = this.handleDelete.bind(this);
        this.setTitleInputRef = this.setTitleInputRef.bind(this);
        this.setContentTextareaRef = this.setContentTextareaRef.bind(this);
        this.autoSave = this.autoSave.bind(this);

        // Auto-save timer
        this.autoSaveTimer = null;
    }

    /**
     * Component mounted - focus on title if new note
     */
    componentDidMount() {
        if (!this.state.id && this.titleInputRef) {
            this.titleInputRef.focus();
        } else if (this.contentTextareaRef) {
            this.contentTextareaRef.focus();
            // Move cursor to end
            const length = this.contentTextareaRef.value.length;
            this.contentTextareaRef.setSelectionRange(length, length);
        }
    }

    /**
     * Component will unmount - clear auto-save timer
     */
    componentWillUnmount() {
        if (this.autoSaveTimer) {
            clearTimeout(this.autoSaveTimer);
        }
    }

    /**
     * Set title input reference and manage focus
     */
    setTitleInputRef(element) {
        if (element) {
            this.titleInputRef = element;
            
            // Ensure input displays the correct content
            if (this.state.title && element.value !== this.state.title) {
                element.value = this.state.title;
            }
            
            // Maintain focus if this element was previously focused
            if (document.activeElement !== element && !this.state.id) {
                element.focus();
            }
        }
    }

    /**
     * Set content textarea reference and manage focus
     */
    setContentTextareaRef(element) {
        if (element) {
            this.contentTextareaRef = element;
            
            // Ensure textarea displays the correct content
            if (this.state.content && element.value !== this.state.content) {
                element.value = this.state.content;
                element.textContent = this.state.content;
            }
            
            // Maintain focus if this element was previously focused
            if (document.activeElement !== element && this.state.id) {
                element.focus();
                // Move cursor to end
                const length = element.value.length;
                element.setSelectionRange(length, length);
            }
        }
    }

    /**
     * Handle title input change
     */
    handleTitleChange(e) {
        // Update state directly to avoid re-render during typing
        this.state.title = e.target.value;
        this.state.isModified = true;
        this.scheduleAutoSave();
    }

    /**
     * Handle content textarea change
     */
    handleContentChange(e) {
        // Update state directly to avoid re-render during typing
        this.state.content = e.target.value;
        this.state.isModified = true;
        this.scheduleAutoSave();
    }

    /**
     * Schedule auto-save (debounced)
     */
    scheduleAutoSave() {
        if (this.autoSaveTimer) {
            clearTimeout(this.autoSaveTimer);
        }
        
        this.autoSaveTimer = setTimeout(() => {
            this.autoSave();
        }, 30000); // Auto-save after 30 seconds of inactivity
    }

    /**
     * Auto-save the note
     */
    autoSave() {
        if (this.state.isModified && (this.state.title.trim() || this.state.content.trim())) {
            this.handleSave(false); // Save without closing editor
        }
    }

    /**
     * Handle save button click
     */
    handleSave(shouldClose = true) {
        const { title, content, id, createdAt } = this.state;
        
        // Don't save empty notes
        if (!title.trim() && !content.trim()) {
            if (shouldClose) {
                this.handleCancel();
            }
            return;
        }

        const savedNote = {
            id: id || generateId(),
            title: title.trim() || 'Untitled',
            content: content.trim(),
            createdAt: createdAt,
            updatedAt: new Date().toISOString()
        };

        this.setState({
            isModified: false,
            id: savedNote.id,
            updatedAt: savedNote.updatedAt
        });

        if (this.props.onSave) {
            this.props.onSave(savedNote);
        }

        if (shouldClose) {
            // Note: The parent component will handle navigation
        }
    }

    /**
     * Handle cancel button click
     */
    handleCancel() {
        if (this.autoSaveTimer) {
            clearTimeout(this.autoSaveTimer);
        }
        
        if (this.props.onCancel) {
            this.props.onCancel();
        }
    }

    /**
     * Handle delete button click
     */
    handleDelete() {        
        if (!this.state.id) {
            console.warn('Cannot delete note: no ID present');
            return;
        }
        
        if (!this.props.onDelete) {
            console.warn('Cannot delete note: no onDelete callback provided');
            return;
        }
        
        try {
            // Show delete confirmation modal using global state
            globalState.setState({
                showDeleteModal: true,
                noteToDelete: {
                    id: this.state.id,
                    title: this.state.title || 'Untitled'
                }
            });
        } catch (error) {
            console.error('Error showing delete confirmation:', error);
        }
    }


    /**
     * Get the word count for the note
     */
    getWordCount() {
        const { content } = this.state;
        if (!content.trim()) return 0;
        return content.trim().split(/\s+/).length;
    }

    /**
     * Render the editor
     */
    render() {
        const { title, content, id, isModified } = this.state;
        const wordCount = this.getWordCount();

        return this.createElement(
            'div',
            { className: 'note-editor' },
            
            // Navigation bar
            new NavigationBar({
                title: id ? 'Edit Note' : 'New Note',
                leftButton: {
                    element: 'button',
                    props: {
                        className: 'nav-button cancel-button',
                        onClick: this.handleCancel,
                        'aria-label': 'Cancel'
                    },
                    content: 'Cancel'
                },
                rightButton: {
                    element: 'button',
                    props: {
                        className: 'nav-button save-button',
                        onClick: () => this.handleSave(true),
                        'aria-label': 'Save note'
                    },
                    content: 'Save'
                }
            }),

            // Editor content
            this.createElement(
                'div',
                { className: 'editor-content' },
                
                // Title input
                this.createElement('input', {
                    type: 'text',
                    className: 'note-title-input',
                    placeholder: 'Note title...',
                    value: title,
                    onInput: this.handleTitleChange,
                    ref: this.setTitleInputRef
                }),

                // Content textarea
                this.createElement('textarea', {
                    className: 'note-content-input',
                    placeholder: 'Start writing...',
                    value: content,
                    onInput: this.handleContentChange,
                    ref: this.setContentTextareaRef
                }),

                // Editor footer
                this.createElement(
                    'div',
                    { className: 'editor-footer' },
                    
                    // Word count and status
                    this.createElement(
                        'div',
                        { className: 'editor-status' },
                        this.createElement(
                            'span',
                            { className: 'word-count' },
                            `${wordCount} word${wordCount !== 1 ? 's' : ''}`
                        ),
                        isModified && this.createElement(
                            'span',
                            { className: 'modified-indicator' },
                            ' * Modified'
                        )
                    ),

                    // Delete button (only for existing notes)
                    id && this.createElement(
                        'button',
                        {
                            className: 'delete-button',
                            onClick: this.handleDelete,
                            'aria-label': 'Delete note'
                        },
                        'Delete'
                    )
                )
            )
        );
    }
}

// ---- ../js/apps/notes/index.js ----
/**
 * @fileoverview Main entry point for the Notes application
 *
 * This module initializes the Notes app UI, including:
 * - Rendering the navigation bar with add note and search functionality
 * - Displaying the notes list
 * - Handling note creation, editing, and deletion
 * - Managing note persistence via A3API
 *
 * The notes app supports:
 * - Creating new notes
 * - Editing existing notes
 * - Deleting notes
 * - Searching through notes
 * - Auto-saving to Arma 3 profile
 */

// Initialize the notes app
function initializeNotesApp(container) {
    // Get current notes and view state from global state
    const { notes = [], currentNote = null, showNoteEditor = false } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Notes');

    // Check if we're viewing/editing a specific note
    if (showNoteEditor || currentNote) {
        // Show note editor
        const noteEditor = new NoteEditor({
            note: currentNote,
            onSave: (savedNote) => {
                const currentNotes = globalState.getState().notes || [];
                let updatedNotes;
                
                if (savedNote.id && currentNotes.find(n => n.id === savedNote.id)) {
                    // Update existing note
                    updatedNotes = currentNotes.map(n => n.id === savedNote.id ? savedNote : n);
                } else {
                    // Add new note
                    updatedNotes = [savedNote, ...currentNotes];
                }
                
                globalState.setState({
                    notes: updatedNotes,
                    currentNote: null,
                    showNoteEditor: false
                });
                
                // Save to server
                if (typeof saveNote === 'function') {
                    saveNote(savedNote);
                }
            },
            onCancel: () => {
                globalState.setState({
                    currentNote: null,
                    showNoteEditor: false
                });
            },
            onDelete: (noteId) => {
                const currentNotes = globalState.getState().notes || [];
                const updatedNotes = currentNotes.filter(n => n.id !== noteId);
                
                globalState.setState({
                    notes: updatedNotes,
                    currentNote: null,
                    showNoteEditor: false
                });
                
                // Delete from server
                if (typeof deleteNote === 'function') {
                    deleteNote(noteId);
                }
            }
        });
        noteEditor.mount(appContainer);
    } else {
        // Show notes list
        const navBar = new NavigationBar({
            title: 'Notes',
            rightButton: {
                element: 'button',
                props: {
                    className: 'nav-button add-button',
                    onClick: () => {
                        globalState.setState({ 
                            showNoteEditor: true,
                            currentNote: null 
                        });
                    },
                    'aria-label': 'Add Note',
                    style: {
                        fontSize: '24px',
                        padding: '0 15px',
                        background: 'none',
                        border: 'none',
                        color: 'var(--accent-color)',
                        cursor: 'pointer'
                    }
                },
                content: '+'
            }
        });
        navBar.mount(appContainer);

        // Main content container
        const contentContainer = document.createElement('div');
        contentContainer.className = 'content';
        appContainer.appendChild(contentContainer);

        // Search bar
        const searchBar = new SearchBar({
            placeholder: 'Search notes...',
            onSearch: (query) => {
                // Filter notes based on search query
                const filteredNotes = notes.filter(note => 
                    note.title.toLowerCase().includes(query.toLowerCase()) ||
                    note.content.toLowerCase().includes(query.toLowerCase())
                );
                
                // Update the notes list
                const existingList = contentContainer.querySelector('.notes-list');
                if (existingList) {
                    existingList.remove();
                }
                
                const notesList = new NotesList({
                    notes: filteredNotes,
                    onNoteClick: (note) => {
                        globalState.setState({
                            currentNote: note,
                            showNoteEditor: true
                        });
                    }
                });
                notesList.mount(contentContainer);
            }
        });
        searchBar.mount(contentContainer);

        // Notes list
        const notesList = new NotesList({
            notes,
            onNoteClick: (note) => {
                globalState.setState({
                    currentNote: note,
                    showNoteEditor: true
                });
            }
        });
        notesList.mount(contentContainer);
    }

    // Mount the app container
    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeNotesApp = initializeNotesApp;

// ---- ../js/apps/clock/components/WorldClock.js ----
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



// ---- ../js/apps/clock/components/Stopwatch.js ----
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



// ---- ../js/apps/clock/components/Timer.js ----
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



// ---- ../js/apps/clock/components/AlarmClock.js ----
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



// ---- ../js/apps/clock/index.js ----
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

// ---- ../js/apps/calendar/components/Calendar.js ----
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


// ---- ../js/apps/calendar/components/EventEditor.js ----
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


// ---- ../js/apps/calendar/index.js ----
/**
 * @fileoverview Main entry point for the Calendar application
 *
 * This module initializes the Calendar app UI, including:
 * - Displaying the calendar view
 * - Handling event creation, editing, and deletion via EventEditor
 * - Managing event persistence via A3API
 */

/**
 * Initializes and mounts the Calendar application.
 * @param {HTMLElement} container - The DOM element to mount the app into.
 */
function initializeCalendarApp(container) {
    const { events = [], selectedDate = new Date(), showEventEditor = false, currentEvent = null } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Calendar');

    // Check if we're viewing/editing a specific event
    if (showEventEditor || currentEvent) {
        // Show event editor
        const eventEditor = new EventEditor({
            event: currentEvent,
            onSave: (savedEvent) => {
                const currentEvents = globalState.getState().events || [];
                let updatedEvents;

                if (savedEvent.id && currentEvents.find(e => e.id === savedEvent.id)) {
                    // Update existing event
                    updatedEvents = currentEvents.map(e => e.id === savedEvent.id ? savedEvent : e);
                } else {
                    // Add new event
                    updatedEvents = [savedEvent, ...currentEvents];
                }

                globalState.setState({
                    events: updatedEvents,
                    currentEvent: null,
                    showEventEditor: false
                });

                // Save to server
                if (typeof saveCalendarEvent === 'function') {
                    saveCalendarEvent(savedEvent);
                }
            },
            onCancel: () => {
                globalState.setState({
                    currentEvent: null,
                    showEventEditor: false
                });
            },
            onDelete: (eventId) => {
                const currentEvents = globalState.getState().events || [];
                const updatedEvents = currentEvents.filter(e => e.id !== eventId);

                globalState.setState({
                    events: updatedEvents,
                    currentEvent: null,
                    showEventEditor: false
                });

                // Delete from server
                if (typeof deleteCalendarEvent === 'function') {
                    deleteCalendarEvent(eventId);
                }
            }
        });
        eventEditor.mount(appContainer);
    } else {
        // Show calendar view
        const navBar = new NavigationBar({
            title: 'Calendar',
            rightButton: {
                element: 'button',
                props: {
                    className: 'nav-button add-event-button',
                    onClick: () => {
                        globalState.setState({
                            showEventEditor: true,
                            currentEvent: null
                        });
                    },
                    'aria-label': 'Add Event'
                },
                content: '+'
            }
        });
        navBar.mount(appContainer);

        const calendar = new Calendar({
            selectedDate: selectedDate,
            events: events,
            onDayClick: (date) => {
                globalState.setState({
                    selectedDate: date,
                    currentEvent: null,
                    showEventEditor: false
                });
            },
            onEventClick: (event) => {
                globalState.setState({
                    currentEvent: event,
                    showEventEditor: true
                });
            }
        });
        calendar.mount(appContainer);
    }

    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeCalendarApp = initializeCalendarApp; 

// ---- ../js/apps/wallet/index.js ----
/** @format */

let lastMobileBankRequest = 0;
let mobileBankNoticeTimer = null;
const MOBILE_BANK_REQUEST_COOLDOWN = 1000;

function defaultMobileBankState() {
    return {
        account: {
            bank: 0,
            cash: 0,
            earnings: 0,
            transactions: [],
        },
        session: {
            creditLine: {
                amountDue: 0,
                approvedAmount: 0,
                availableAmount: 0,
                outstandingPrincipal: 0,
            },
            orgName: '',
            playerName: '',
            transferTargets: [],
            uid: '',
        },
        notice: null,
        pendingAction: '',
    };
}

function getMobileBankState() {
    return {
        ...defaultMobileBankState(),
        ...(globalState.getState().mobileBank || {}),
    };
}

function setMobileBankState(patch) {
    globalState.setState({
        mobileBank: {
            ...getMobileBankState(),
            ...patch,
        },
    });
}

function formatMobileBankCurrency(value) {
    const amount = Math.floor(Number(value || 0));
    return `$${Math.max(0, amount).toLocaleString()}`;
}

function normalizeMobileBankAmount(value) {
    const amount = Math.floor(Number(value || 0));
    return Number.isFinite(amount) ? amount : 0;
}

function sendMobileBankEvent(event, data = {}) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        A3API.SendAlert(JSON.stringify({ event, data }));
        return true;
    }

    showMobileBankNotice('error', 'Bank bridge is unavailable.');
    return false;
}

function requestMobileBankRefresh(force = false) {
    const now = Date.now();
    if (!force && now - lastMobileBankRequest < MOBILE_BANK_REQUEST_COOLDOWN) {
        return false;
    }

    lastMobileBankRequest = now;
    return sendMobileBankEvent('phone::bank::refresh', {});
}

function requestMobileBankTransfer(target, amountValue) {
    const targetUid = String(target || '').trim();
    const amount = normalizeMobileBankAmount(amountValue);

    if (!targetUid) {
        showMobileBankNotice('error', 'Choose a recipient.');
        return false;
    }

    if (amount <= 0) {
        showMobileBankNotice('error', 'Enter a valid transfer amount.');
        return false;
    }

    setMobileBankState({ pendingAction: 'transfer' });
    const sent = sendMobileBankEvent('phone::bank::transfer::request', {
        amount,
        from: 'bank',
        target: targetUid,
    });

    if (!sent) {
        setMobileBankState({ pendingAction: '' });
    }

    return sent;
}

function requestMobileBankDepositEarnings() {
    const state = getMobileBankState();
    const availableEarnings = normalizeMobileBankAmount(state.account.earnings);

    if (availableEarnings <= 0) {
        showMobileBankNotice('error', 'No earnings are available to deposit.');
        return false;
    }

    setMobileBankState({ pendingAction: 'depositearnings' });
    const sent = sendMobileBankEvent('phone::bank::depositEarnings::request', {
        amount: availableEarnings,
    });

    if (!sent) {
        setMobileBankState({ pendingAction: '' });
    }

    return sent;
}

function requestMobileBankRepayCreditLine(amountValue) {
    const amount = normalizeMobileBankAmount(amountValue);
    const state = getMobileBankState();
    const amountDue = normalizeMobileBankAmount(state.session.creditLine?.amountDue);

    if (amountDue <= 0) {
        showMobileBankNotice('error', 'No credit line payment is due.');
        return false;
    }

    if (amount <= 0) {
        showMobileBankNotice('error', 'Enter a valid payment amount.');
        return false;
    }

    setMobileBankState({ pendingAction: 'repaycreditline' });
    const sent = sendMobileBankEvent('phone::bank::repayCreditLine::request', {
        amount: Math.min(amount, amountDue),
    });

    if (!sent) {
        setMobileBankState({ pendingAction: '' });
    }

    return sent;
}

function updateMobileBank(payload) {
    const current = getMobileBankState();
    setMobileBankState({
        account: {
            ...current.account,
            ...(payload && payload.account ? payload.account : {}),
        },
        session: {
            ...current.session,
            ...(payload && payload.session ? payload.session : {}),
        },
        pendingAction: '',
    });
}

function updateMobileBankAccount(accountPatch) {
    const current = getMobileBankState();
    setMobileBankState({
        account: {
            ...current.account,
            ...(accountPatch || {}),
        },
        pendingAction: '',
    });
}

function showMobileBankNotice(type, message) {
    if (!message) return;

    setMobileBankState({
        notice: {
            type: type || 'info',
            message,
        },
        pendingAction: '',
    });

    if (mobileBankNoticeTimer) {
        clearTimeout(mobileBankNoticeTimer);
    }

    mobileBankNoticeTimer = setTimeout(() => {
        setMobileBankState({ notice: null });
        mobileBankNoticeTimer = null;
    }, 3200);
}

function mobileBankTransactionRows(transactions) {
    const rows = Array.isArray(transactions) ? transactions.slice(0, 5) : [];

    if (rows.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'wallet-empty-state';
        empty.textContent = 'No recent transactions';
        return empty;
    }

    const list = document.createElement('div');
    list.className = 'wallet-transaction-list';

    rows.forEach((entry) => {
        const row = document.createElement('div');
        row.className = 'wallet-transaction-row';

        const copy = document.createElement('div');
        copy.className = 'wallet-transaction-copy';

        const title = document.createElement('span');
        title.className = 'wallet-transaction-title';
        title.textContent = entry.type || 'Transaction';

        const meta = document.createElement('span');
        meta.className = 'wallet-transaction-meta';
        meta.textContent = entry.date || 'Pending timestamp';

        const value = document.createElement('span');
        value.className = 'wallet-transaction-value';
        value.textContent = formatMobileBankCurrency(entry.amount || 0);

        copy.append(title, meta);
        row.append(copy, value);
        list.appendChild(row);
    });

    return list;
}

function initializeMobileBankApp(container) {
    const state = getMobileBankState();
    const { account, session, notice, pendingAction } = state;
    const transferTargets = Array.isArray(session.transferTargets)
        ? session.transferTargets
        : [];
    const creditLine = session.creditLine || {};
    const amountDue = normalizeMobileBankAmount(creditLine.amountDue);
    const outstandingPrincipal = normalizeMobileBankAmount(creditLine.outstandingPrincipal);

    requestMobileBankRefresh(false);

    const appContainer = document.createElement('div');
    appContainer.className = 'app-container wallet-app';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Wallet');

    const navBar = new NavigationBar({
        title: 'Wallet',
        rightButton: {
            element: 'button',
            props: {
                className: 'wallet-nav-button',
                type: 'button',
                disabled: pendingAction !== '',
                onClick: () => requestMobileBankRefresh(true),
                'aria-label': 'Refresh wallet',
            },
            content: 'Refresh',
        },
    });
    navBar.mount(appContainer);

    const content = document.createElement('div');
    content.className = 'content wallet-content';

    if (notice && notice.message) {
        const noticeElement = document.createElement('div');
        noticeElement.className = `wallet-notice wallet-notice-${notice.type || 'info'}`;
        noticeElement.textContent = notice.message;
        content.appendChild(noticeElement);
    }

    const hero = document.createElement('section');
    hero.className = 'wallet-balance-card';
    hero.innerHTML = `
        <span class="wallet-eyebrow">Available Balance</span>
        <strong class="wallet-balance">${formatMobileBankCurrency(account.bank)}</strong>
        <span class="wallet-owner">${session.playerName || 'Personal account'}</span>
    `;
    content.appendChild(hero);

    const metrics = document.createElement('section');
    metrics.className = 'wallet-metrics';
    metrics.innerHTML = `
        <div class="wallet-metric">
            <span>Cash</span>
            <strong>${formatMobileBankCurrency(account.cash)}</strong>
        </div>
        <div class="wallet-metric">
            <span>Earnings</span>
            <strong>${formatMobileBankCurrency(account.earnings)}</strong>
        </div>
    `;
    content.appendChild(metrics);

    const bankingActions = document.createElement('section');
    bankingActions.className = 'wallet-card';

    const bankingTitle = document.createElement('div');
    bankingTitle.className = 'wallet-card-title';
    bankingTitle.textContent = 'Account Actions';

    const earningsAction = document.createElement('div');
    earningsAction.className = 'wallet-action-block';

    const earningsSummary = document.createElement('div');
    earningsSummary.className = 'wallet-action-summary';
    earningsSummary.innerHTML = `
        <span>Deposit Earnings</span>
        <strong>${formatMobileBankCurrency(account.earnings)} available</strong>
        <small>Move mission earnings into your bank balance.</small>
    `;

    const earningsButton = document.createElement('button');
    earningsButton.className = 'wallet-secondary-button wallet-full-button';
    earningsButton.type = 'button';
    earningsButton.disabled = pendingAction !== '' || normalizeMobileBankAmount(account.earnings) <= 0;
    earningsButton.textContent = pendingAction === 'depositearnings' ? 'Depositing...' : 'Deposit Earnings';
    earningsButton.addEventListener('click', () => {
        requestMobileBankDepositEarnings();
    });
    earningsAction.append(earningsSummary, earningsButton);

    const creditAction = document.createElement('div');
    creditAction.className = 'wallet-action-block';

    const creditSummary = document.createElement('div');
    creditSummary.className = 'wallet-action-summary';
    creditSummary.innerHTML = `
        <span>Credit Line Payment</span>
        <strong>${formatMobileBankCurrency(amountDue)} due</strong>
        <small>${session.orgName || 'Organization'} - ${formatMobileBankCurrency(outstandingPrincipal)} outstanding</small>
    `;

    const creditControls = document.createElement('div');
    creditControls.className = 'wallet-action-controls';

    const creditAmount = document.createElement('input');
    creditAmount.className = 'wallet-input';
    creditAmount.type = 'number';
    creditAmount.min = '1';
    creditAmount.step = '1';
    creditAmount.placeholder = amountDue > 0 ? 'Payment amount' : 'No payment due';
    creditAmount.setAttribute('aria-label', 'Credit line payment amount');
    creditAmount.inputMode = 'numeric';
    creditAmount.disabled = pendingAction !== '' || amountDue <= 0;

    const creditButton = document.createElement('button');
    creditButton.className = 'wallet-secondary-button';
    creditButton.type = 'button';
    creditButton.disabled = pendingAction !== '' || amountDue <= 0;
    creditButton.textContent = pendingAction === 'repaycreditline' ? 'Paying...' : 'Pay Credit';
    creditButton.addEventListener('click', () => {
        requestMobileBankRepayCreditLine(creditAmount.value || amountDue);
    });

    creditControls.append(creditAmount, creditButton);
    creditAction.append(creditSummary, creditControls);
    bankingActions.append(bankingTitle, earningsAction, creditAction);
    content.appendChild(bankingActions);

    const transferCard = document.createElement('section');
    transferCard.className = 'wallet-card';

    const transferTitle = document.createElement('div');
    transferTitle.className = 'wallet-card-title';
    transferTitle.textContent = 'Transfer';

    const targetSelect = document.createElement('select');
    targetSelect.className = 'wallet-input';
    targetSelect.setAttribute('aria-label', 'Transfer recipient');
    targetSelect.disabled = pendingAction !== '' || transferTargets.length === 0;

    const placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = transferTargets.length === 0 ? 'No online recipients' : 'Choose recipient';
    targetSelect.appendChild(placeholder);

    transferTargets.forEach((target) => {
        const option = document.createElement('option');
        option.value = target.uid || '';
        option.textContent = target.name || target.uid || 'Player';
        targetSelect.appendChild(option);
    });

    const amountInput = document.createElement('input');
    amountInput.className = 'wallet-input';
    amountInput.type = 'number';
    amountInput.min = '1';
    amountInput.step = '1';
    amountInput.placeholder = 'Amount';
    amountInput.inputMode = 'numeric';
    amountInput.disabled = pendingAction !== '';

    const transferButton = document.createElement('button');
    transferButton.className = 'wallet-primary-button';
    transferButton.type = 'button';
    transferButton.disabled = pendingAction !== '' || transferTargets.length === 0;
    transferButton.textContent = pendingAction === 'transfer' ? 'Sending...' : 'Send Transfer';
    transferButton.addEventListener('click', () => {
        requestMobileBankTransfer(targetSelect.value, amountInput.value);
    });

    transferCard.append(transferTitle, targetSelect, amountInput, transferButton);
    content.appendChild(transferCard);

    const historyCard = document.createElement('section');
    historyCard.className = 'wallet-card';

    const historyTitle = document.createElement('div');
    historyTitle.className = 'wallet-card-title';
    historyTitle.textContent = 'Recent Activity';

    historyCard.append(historyTitle, mobileBankTransactionRows(account.transactions));
    content.appendChild(historyCard);

    appContainer.appendChild(content);
    container.appendChild(appContainer);
}

window.initializeMobileBankApp = initializeMobileBankApp;
window.requestMobileBankRefresh = requestMobileBankRefresh;
window.updateMobileBank = updateMobileBank;
window.updateMobileBankAccount = updateMobileBankAccount;
window.showMobileBankNotice = showMobileBankNotice;


// ---- ../js/app.js ----
/**
 * @fileoverview Root application component and integration logic.
 *
 * The App class manages:
 * - Switching between different app modules (home, phone, messages, contacts, settings)
 * - Rendering the correct app UI based on global state
 * - Handling global modals (e.g., call confirmation)
 * - Integrating shared UI elements (status bar, home indicator, dynamic island)
 *
 * Each app module is initialized via its global function (e.g., window.initializePhoneApp) and mounted into the app container.
 * The placeholder app view is shown for unimplemented apps.
 *
 * This is the main entry point for the phone UI framework.
 */

/**
 * @class App
 * @extends Component
 * @description The root component that manages app switching and integration
 */
class App extends Component {
    /**
     * @constructor
     * Initializes state and subscribes to global state changes.
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            ...globalState.getState(),
            currentApp: 'home',
            showAddContactForm: false
        };

        this.unsubscribe = null;
    }

    /**
     * Subscribe to global state changes after mounting
     * @lifecycle
     */
    componentDidMount() {
        this.unsubscribe = globalState.subscribe((newState) => {
            this.setState(newState);
        });
    }

    /**
     * Clean up subscriptions before unmounting
     * @lifecycle
     */
    componentWillUnmount() {
        if (this.unsubscribe) {
            this.unsubscribe();
        }
    }

    /**
     * Render the current app based on app state
     * @returns {HTMLElement} Current app view
     * @private
     */
    renderCurrentApp() {
        const { currentApp } = this.state;
        const appContainer = this.createElement('div', { className: 'app-container' });

        switch (currentApp) {
            case 'clock':
                window.initializeClockApp(appContainer);
                break;
            case 'calendar':
                window.initializeCalendarApp(appContainer);
                break;
            case 'home':
                return new HomeScreen();
            case 'phone':
                window.initializePhoneApp(appContainer);
                break;
            case 'messages':
                window.initializeMessagesApp(appContainer);
                break;
            case 'mail':
                window.initializeMailApp(appContainer);
                break;
            case 'notes':
                window.initializeNotesApp(appContainer);
                break;
            case 'contacts':
                window.initializeContactsApp(appContainer);
                break;
            case 'settings':
                window.initializeSettingsApp(appContainer);
                break;
            case 'wallet':
                window.initializeMobileBankApp(appContainer);
                break;
            default:
                return this.renderPlaceholderApp(currentApp);
        }

        return appContainer;
    }

    /**
     * Render a placeholder for unimplemented apps
     * @param {string} appName - App name
     * @returns {HTMLElement} Placeholder app view
     * @private
     */
    renderPlaceholderApp(appName) {
        const appIcons = {
            calendar: '',
            camera: '',
            store: '',
            mail: '',
            icloud: '',
            photos: '',
            safari: '',
            wallet: ''
        };

        return this.createElement(
            'div',
            { className: 'app-container' },
            new NavigationBar({ title: appName }),
            this.createElement(
                'div',
                { className: 'content' },
                this.createElement(
                    'div',
                    {
                        style: {
                            textAlign: 'center',
                            padding: '50px 20px',
                            color: '#6c757d',
                        },
                    },
                    this.createElement('h2', { role: 'img', 'aria-label': appName }, appIcons[appName] || ''),
                    this.createElement('p', {}, `${appName} app coming soon!`)
                )
            )
        );
    }

    /**
     * Render the phone app UI, including status bar, main content, home indicator, and modals.
     * @returns {HTMLElement} The rendered phone app
     */
    render() {
        const { currentApp, selectedContact, showModal, showDeleteModal, noteToDelete, eventToDelete } = this.state;
        const openMessageThread = (contact) => {
            if (!contact || contact.canMessage === false) return;

            const contactId = contact.contactId || contact.uid || contact.id;
            if (!contactId) return;

            const { messages = [], rawMessages = [], currentUid = window.__playerUid } = globalState.getState();
            const existingConversation = messages.find((message) => (message.contactId || message.id) === contactId);
            const selectedRawMessages = rawMessages.filter((message) =>
                message &&
                (
                    (message.from === currentUid && message.to === contactId) ||
                    (message.from === contactId && message.to === currentUid)
                )
            );
            const conversation = existingConversation || {
                ...contact,
                id: contactId,
                contactId,
                contactName: contact.fullName || contact.name || contactId,
                conversation: [],
                hasConversation: false
            };

            globalState.setState({
                currentApp: 'messages',
                selectedContact: null,
                showModal: false,
                showMessageContactPicker: false,
                selectedConversation: {
                    ...conversation,
                    id: contactId,
                    contactId,
                    contactName: conversation.contactName || contact.fullName || contact.name || contactId,
                    conversation: conversation.conversation || []
                },
                selectedConversationRaw: {
                    otherUid: contactId,
                    messages: selectedRawMessages
                }
            });
        };

        return this.createElement(
            'div',
            {
                className: 'phone-container',
                role: 'application',
                'aria-label': 'Phone interface',
            },
            this.createElement(
                'div',
                {
                    className: 'phone-screen dynamic-island',
                    role: 'main',
                },
                // Dynamic Island content
                this.createElement(
                    'div',
                    {
                        className: 'dynamic-island-content',
                        'aria-hidden': 'true',
                    },
                    this.createElement('div', { className: 'speaker' }),
                    this.createElement('div', { className: 'camera' })
                ),

                // Status bar
                new StatusBar(),

                // Main app content
                this.renderCurrentApp(),

                // Home indicator (except on home screen)
                currentApp !== 'home' && new HomeIndicator(),

                // Call modal
                showModal && selectedContact && new Modal({
                    show: showModal,
                    title: selectedContact.canCall === false ? (selectedContact.fullName || selectedContact.name) : `Call ${selectedContact.fullName || selectedContact.name}?`,
                    confirmText: selectedContact.canCall === false ? 'Close' : 'Call',
                    cancelText: selectedContact.canCall === false ? 'Back' : 'Cancel',
                    hideCancel: true,
                    hideConfirm: selectedContact.canCall === false,
                    extraActions: selectedContact.canMessage === false || !(selectedContact.contactId || selectedContact.uid || selectedContact.id) ? [] : [{
                        text: 'Text',
                        ariaLabel: `Text ${selectedContact.fullName || selectedContact.name}`,
                        className: 'button secondary',
                        onClick: () => openMessageThread(selectedContact)
                    }],
                    onClose: () => globalState.setState({ showModal: false, selectedContact: null }),
                    onConfirm: () => {
                        if (selectedContact.canCall === false) {
                            globalState.setState({ showModal: false, selectedContact: null });
                            return;
                        }

                        globalState.setState({
                            phoneNumber: selectedContact.phone,
                            showModal: false,
                            selectedContact: null,
                            currentApp: 'phone'
                        });
                    },
                    children: [
                        this.createElement(
                            'p',
                            { role: 'alert' },
                            selectedContact.canCall === false
                                ? `${selectedContact.fullName || selectedContact.name} is a command broadcast contact. Incoming messages and email are available, but direct calls are disabled.`
                                : `Do you want to call ${selectedContact.fullName || selectedContact.name} at ${selectedContact.phone}?`
                        )
                    ]
                }),

                // Delete note confirmation modal
                showDeleteModal && noteToDelete && new Modal({
                    show: showDeleteModal,
                    title: `Delete "${noteToDelete.title}"?`,
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
                    onClose: () => globalState.setState({ showDeleteModal: false, noteToDelete: null }),
                    onConfirm: () => {
                        // Find the onDelete handler from the notes editor and call it
                        const currentState = globalState.getState();
                        const currentNotes = currentState.notes || [];
                        const updatedNotes = currentNotes.filter(n => n.id !== noteToDelete.id);
                        
                        globalState.setState({
                            notes: updatedNotes,
                            currentNote: null,
                            showNoteEditor: false,
                            showDeleteModal: false,
                            noteToDelete: null
                        });
                        
                        // Delete from server
                        if (typeof deleteNote === 'function') {
                            deleteNote(noteToDelete.id);
                        }
                        
                        console.log('Note deleted:', noteToDelete.id);
                    },
                    children: [this.createElement('p', { role: 'alert' }, `Are you sure you want to delete this note? This action cannot be undone.`)]
                }),

                showDeleteModal && eventToDelete && new Modal({
                    show: showDeleteModal,
                    title: `Delete "${eventToDelete.title}"?`,
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
                    onClose: () => globalState.setState({ showDeleteModal: false, eventToDelete: null }),
                    onConfirm: () => {
                        // Find the onDelete handler from the events editor and call it
                        const currentState = globalState.getState();
                        const currentEvents = currentState.events || [];
                        const updatedEvents = currentEvents.filter(n => n.id !== eventToDelete.id);
                        
                        globalState.setState({
                            events: updatedEvents,
                            currentEvent: null,
                            showEventEditor: false,
                            showDeleteModal: false,
                            eventToDelete: null
                        });
                        
                        // Delete from server
                        if (typeof deleteCalendarEvent === 'function') {
                            deleteCalendarEvent(eventToDelete.id);
                        }
                        
                        console.log('Event deleted:', eventToDelete.id);
                    },
                    children: [this.createElement('p', { role: 'alert' }, `Are you sure you want to delete this event? This action cannot be undone.`)]
                })
            )
        );
    }
}


// ---- ../js/main.js ----
/** @format */

/**
 * @fileoverview Main entry point for the phone application.
 * Initializes the application and mounts the root component.
 */

/**
 * Initialize and mount the phone application.
 * Sets up error boundaries and debugging tools.
 *
 * @function
 * @name initializeApp
 * @throws {Error} If app container element is not found
 */
const initializeApp = () => {
    try {
        const appContainer = document.getElementById('app');
        if (!appContainer) {
            throw new Error('App container element not found. Make sure there is an element with id="app" in the HTML.');
        }

        // Set default theme first
        document.documentElement.setAttribute('data-theme', 'dark');

        // Get theme from game using A3API
        const themeAlert = {
            "event": "phone::get::theme",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(themeAlert));

        // Request player UID for correct message mapping
        const meAlert = {
            "event": "phone::get::player",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(meAlert));

        // Request contacts from server
        const contactsAlert = {
            "event": "phone::get::contacts",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(contactsAlert));

        // Request messages from server
        const messagesAlert = {
            "event": "phone::get::messages",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(messagesAlert));

        // Request emails from server
        const emailsAlert = {
            "event": "phone::get::emails",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(emailsAlert));

        // Request notes from server
        const notesAlert = {
            "event": "phone::get::notes",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(notesAlert));

        // Request events from server
        const eventsAlert = {
            "event": "phone::get::events",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(eventsAlert));

        // Request world clocks from server
        const worldClocksAlert = {
            "event": "phone::get::clocks",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(worldClocksAlert));

        // Request alarms from server
        const alarmsAlert = {
            "event": "phone::get::alarms",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alarmsAlert));

        // Initialize phone app
        const app = new App();
        app.mount(appContainer);

        console.log('Phone app initialized successfully');
    } catch (error) {
        console.error('Failed to initialize phone app:', error);
        throw error;
    }
};


// ---- ../js/global.js ----
/** @format */

/**
 * @fileoverview Global exports for the phone application.
 * Exposes all API functions and initialization to the global window object.
 */

/**
 * Sets the theme for the phone application
 * @param {string} theme - The theme to set ('dark' or 'light')
 */
function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);

    // Dispatch theme change event
    const themeEvent = new CustomEvent('themeChanged', {
        detail: { theme }
    });
    document.dispatchEvent(themeEvent);
}

// Debounce variables for contact requests
let lastContactRequest = 0;
const CONTACT_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests contacts from the server (Arma 3) with debouncing
 */
function requestContacts() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastContactRequest < CONTACT_REQUEST_COOLDOWN) {
        console.log('Contact request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::contacts",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastContactRequest = now;
        console.log('Requested contacts from server');
    } else {
        console.warn('A3API not available, cannot request contacts');
    }
}

/**
 * Loads contacts into the global state (called by Arma 3)
 * @param {Array} contacts - Array of contact objects from the server
 */
function loadContacts(contacts) {
    try {
        if (Array.isArray(contacts)) {
            const normalizedContacts = normalizeContacts(contacts);
            globalState.setState({
                contacts: normalizedContacts
            });
            console.log(`Loaded ${contacts.length} contacts from server:`, contacts);
        } else {
            console.warn('Invalid contacts data received:', contacts);
        }
    } catch (error) {
        console.error('Error loading contacts:', error);
    }
}

/**
 * Refresh contacts via SQF-triggered UI event
 */
function refreshContacts() {
    try {
        requestContacts();
    } catch (e) {
        console.error('Error refreshing contacts:', e);
    }
}

/**
 * Updates contacts in state (SQF -> JS bridge)
 * @param {Array} contacts
 */
function updateContacts(contacts) {
    try {
        if (Array.isArray(contacts)) {
            const normalizedContacts = normalizeContacts(contacts);
            globalState.setState({ contacts: normalizedContacts });
            // Rebuild message summaries to resolve names if raw present
            rebuildMessageSummariesFromRaw();
            console.log(`Updated contacts from server: ${contacts.length}`);
        } else {
            console.warn('updateContacts: invalid data', contacts);
        }
    } catch (e) {
        console.error('Error in updateContacts:', e);
    }
}

function normalizeContacts(contacts) {
    return contacts
        .filter(contact => contact && typeof contact === 'object')
        .map(contact => {
            const name = contact.name || contact.uid || 'Unknown Player';
            const uid = contact.uid || contact.id || '';
            return {
                ...contact,
                id: uid || contact.phone || name,
                uid,
                name,
                fullName: contact.fullName || name,
                phone: contact.phone || '',
                email: contact.email || '',
                avatar: contact.avatar || getInitials(name),
                online: Boolean(contact.online),
                system: Boolean(contact.system),
                canCall: contact.canCall !== false,
                canMessage: contact.canMessage !== false,
                canEmail: contact.canEmail !== false
            };
        });
}

// Player UID handling
function setPlayerUid(uid) {
    try {
        if (!uid || typeof uid !== 'string') {
            console.warn('setPlayerUid: invalid uid', uid);
            return;
        }
        window.__playerUid = uid;
        globalState.setState({ currentUid: uid });
        // With UID known, we can build summaries
        rebuildMessageSummariesFromRaw();
        // Optionally (re)request messages when UID is set
        requestMessages();
    } catch (e) {
        console.error('Error in setPlayerUid:', e);
    }
}

// Messages: request + update handlers

let lastMessagesRequest = 0;
const MESSAGES_REQUEST_COOLDOWN = 1000;

function requestMessages() {
    const now = Date.now();
    if (now - lastMessagesRequest < MESSAGES_REQUEST_COOLDOWN) return;
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = { event: 'phone::get::messages', data: {} };
        A3API.SendAlert(JSON.stringify(alert));
        lastMessagesRequest = now;
        console.log('Requested messages from server');
    } else {
        console.warn('A3API not available, cannot request messages');
    }
}

/**
 * Updates raw messages from server into state without breaking UI
 * @param {Array} messages
 */
function updateMessages(messages) {
    try {
        if (Array.isArray(messages)) {
            globalState.setState({ rawMessages: messages });
            rebuildMessageSummariesFromRaw();
            console.log(`Updated raw messages: ${messages.length}`);
        } else {
            console.warn('updateMessages: invalid data', messages);
        }
    } catch (e) {
        console.error('Error in updateMessages:', e);
    }
}

/**
 * Updates a specific message thread payload
 * @param {Array} threadMessages
 * @param {string} otherUid
 */
function updateMessageThread(threadMessages, otherUid) {
    try {
        if (!Array.isArray(threadMessages)) {
            console.warn('updateMessageThread: invalid messages', threadMessages);
            return;
        }
        const selectedConversationRaw = { otherUid, messages: threadMessages };
        globalState.setState({ selectedConversationRaw });
        // Update derived selectedConversation as well
        rebuildMessageSummariesFromRaw();
        console.log(`Updated message thread with ${otherUid}: ${threadMessages.length}`);
    } catch (e) {
        console.error('Error in updateMessageThread:', e);
    }
}

/**
 * Append a newly sent message to raw store
 * @param {Object} messageObj
 */
function updateMessageSent(messageObj) {
    try {
        const { rawMessages = [], currentUid = window.__playerUid, selectedConversation } = globalState.getState();
        const next = [...rawMessages, messageObj];
        const otherUid = messageObj.from === currentUid ? messageObj.to : messageObj.from;
        const statePatch = { rawMessages: next };
        if (selectedConversation && selectedConversation.id === otherUid) {
            statePatch.selectedConversationRaw = {
                otherUid,
                messages: next.filter(message =>
                    (message.from === currentUid && message.to === otherUid) ||
                    (message.from === otherUid && message.to === currentUid)
                )
            };
        }
        globalState.setState(statePatch);
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageSent:', e);
    }
}

/**
 * Append a newly received message to raw store
 * @param {Object} messageObj
 */
function updateMessageReceived(messageObj) {
    try {
        const { rawMessages = [], currentUid = window.__playerUid, selectedConversation } = globalState.getState();
        const next = [...rawMessages, messageObj];
        const otherUid = messageObj.from === currentUid ? messageObj.to : messageObj.from;
        const statePatch = { rawMessages: next };
        if (selectedConversation && selectedConversation.id === otherUid) {
            statePatch.selectedConversationRaw = {
                otherUid,
                messages: next.filter(message =>
                    (message.from === currentUid && message.to === otherUid) ||
                    (message.from === otherUid && message.to === currentUid)
                )
            };
        }
        globalState.setState(statePatch);
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageReceived:', e);
    }
}

/**
 * Mark message read in raw store by id
 * @param {string} messageId
 */
function updateMessageRead(messageId) {
    try {
        const { rawMessages = [] } = globalState.getState();
        const updated = rawMessages.map(m => (m && m.id === messageId ? { ...m, read: true } : m));
        globalState.setState({ rawMessages: updated });
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageRead:', e);
    }
}

/**
 * Remove a message from the local phone state after server delete succeeds
 * @param {string} messageId
 */
function updateMessageDeleted(messageId) {
    try {
        const { rawMessages = [], selectedConversationRaw = null } = globalState.getState();
        const nextRawMessages = rawMessages.filter(message => message && message.id !== messageId);
        const statePatch = { rawMessages: nextRawMessages };

        if (selectedConversationRaw && Array.isArray(selectedConversationRaw.messages)) {
            statePatch.selectedConversationRaw = {
                ...selectedConversationRaw,
                messages: selectedConversationRaw.messages.filter(message => message && message.id !== messageId)
            };
        }

        globalState.setState(statePatch);
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageDeleted:', e);
    }
}

// Transform raw message payloads into UI-friendly summary and thread structures
function rebuildMessageSummariesFromRaw() {
    try {
        const state = globalState.getState();
        const { rawMessages = [], contacts = [], currentUid = window.__playerUid, selectedConversationRaw } = state;
        if (!Array.isArray(rawMessages) || !currentUid) {
            // Nothing to do until we have both raw data and the player's UID
            return;
        }

        // Build contact lookup map by uid
        const contactByUid = new Map();
        contacts.forEach(c => { if (c && c.uid) contactByUid.set(c.uid, c); });

        // Group messages by other participant
        const threadsMap = new Map();
        for (const m of rawMessages) {
            if (!m) continue;
            const from = m.from;
            const to = m.to;
            const otherUid = from === currentUid ? to : from;
            if (!threadsMap.has(otherUid)) threadsMap.set(otherUid, []);
            threadsMap.get(otherUid).push(m);
        }

        // Helper to convert timestamp to Date
        const toJsDate = (t) => {
            if (t instanceof Date) return t;
            if (typeof t === 'number') {
                // serverTime is seconds; convert
                return new Date(t * 1000);
            }
            // Fallback parse
            const parsed = Date.parse(t);
            return isNaN(parsed) ? new Date() : new Date(parsed);
        };

        // Build UI message summaries
        const uiMessages = [];
        for (const [otherUid, arr] of threadsMap.entries()) {
            // Sort by timestamp ascending
            const sorted = [...arr].sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
            const last = sorted[sorted.length - 1];
            const contact = contactByUid.get(otherUid) || { name: otherUid, uid: otherUid };

            const conversation = sorted.map((msg, idx) => ({
                id: msg.id || idx,
                text: msg.message || msg.text || '',
                sender: msg.from === currentUid ? 'user' : 'contact',
                timestamp: toJsDate(msg.timestamp)
            }));

            uiMessages.push({
                id: otherUid,
                contactId: otherUid,
                contactName: contact.name || otherUid,
                canMessage: contact.canMessage !== false,
                lastMessage: (last && (last.message || last.text)) || '',
                timestamp: toJsDate(last && last.timestamp),
                unread: arr.filter(m => m.read === false && m.to === currentUid).length || 0,
                conversation
            });
        }

        // Sort conversations by last timestamp desc for UI list
        uiMessages.sort((a, b) => (b.timestamp?.getTime?.() || 0) - (a.timestamp?.getTime?.() || 0));

        const nextState = { messages: uiMessages };

        // If we have a selected raw thread, map it to selectedConversation too
        if (selectedConversationRaw && selectedConversationRaw.otherUid) {
            const thread = threadsMap.get(selectedConversationRaw.otherUid) || selectedConversationRaw.messages || [];
            const contact = contactByUid.get(selectedConversationRaw.otherUid) || { name: selectedConversationRaw.otherUid };
            nextState.selectedConversation = {
                id: selectedConversationRaw.otherUid,
                contactId: selectedConversationRaw.otherUid,
                contactName: contact.name,
                canMessage: contact.canMessage !== false,
                lastMessage: thread.length ? (thread[thread.length - 1].message || thread[thread.length - 1].text) : '',
                timestamp: thread.length ? toJsDate(thread[thread.length - 1].timestamp) : new Date(),
                unread: thread.filter(m => m.read === false && m.to === currentUid).length || 0,
                conversation: thread.map((msg, idx) => ({
                    id: msg.id || idx,
                    text: msg.message || msg.text || '',
                    sender: msg.from === currentUid ? 'user' : 'contact',
                    timestamp: toJsDate(msg.timestamp)
                }))
            };
        }

        globalState.setState(nextState);
    } catch (e) {
        console.error('Error rebuilding message summaries:', e);
    }
}

// Emails: request + update handlers

let lastEmailsRequest = 0;
const EMAILS_REQUEST_COOLDOWN = 1000;

function requestEmails() {
    const now = Date.now();
    if (now - lastEmailsRequest < EMAILS_REQUEST_COOLDOWN) return;
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = { event: 'phone::get::emails', data: {} };
        A3API.SendAlert(JSON.stringify(alert));
        lastEmailsRequest = now;
        console.log('Requested emails from server');
    } else {
        console.warn('A3API not available, cannot request emails');
    }
}

function normalizeEmails(emails) {
    if (!Array.isArray(emails)) return [];

    const byId = new Map();
    emails
        .filter((email) => email && typeof email === 'object')
        .forEach((email) => {
            const id = email.id || `${email.from || ''}:${email.to || ''}:${email.timestamp || ''}:${email.subject || ''}`;
            byId.set(id, {
                id,
                from: email.from || '',
                to: email.to || '',
                subject: email.subject || '',
                body: email.body || '',
                timestamp: email.timestamp || '',
                read: !!email.read
            });
        });

    return Array.from(byId.values()).sort((left, right) => {
        const leftTime = new Date(left.timestamp).getTime() || 0;
        const rightTime = new Date(right.timestamp).getTime() || 0;
        return rightTime - leftTime;
    });
}

/**
 * Replace emails in state
 * @param {Array} emails
 */
function updateEmails(emails) {
    try {
        if (Array.isArray(emails)) {
            globalState.setState({ emails: normalizeEmails(emails) });
            console.log(`Updated emails: ${emails.length}`);
        } else {
            console.warn('updateEmails: invalid data', emails);
        }
    } catch (e) {
        console.error('Error in updateEmails:', e);
    }
}

/**
 * Append a newly sent email to state
 * @param {Object} emailObj
 */
function updateEmailSent(emailObj) {
    try {
        const { emails = [] } = globalState.getState();
        globalState.setState({ emails: normalizeEmails([emailObj, ...emails]) });
    } catch (e) {
        console.error('Error in updateEmailSent:', e);
    }
}

/**
 * Append a newly received email to state
 * @param {Object} emailObj
 */
function updateEmailReceived(emailObj) {
    try {
        const { emails = [] } = globalState.getState();
        globalState.setState({ emails: normalizeEmails([emailObj, ...emails]) });
    } catch (e) {
        console.error('Error in updateEmailReceived:', e);
    }
}

/**
 * Mark email read in state by id
 * @param {string} emailId
 */
function updateEmailRead(emailId) {
    try {
        const { emails = [], selectedEmail = null } = globalState.getState();
        const updated = emails.map(e => (e && e.id === emailId ? { ...e, read: true } : e));
        globalState.setState({
            emails: updated,
            selectedEmail: selectedEmail && selectedEmail.id === emailId ? { ...selectedEmail, read: true } : selectedEmail
        });
    } catch (e) {
        console.error('Error in updateEmailRead:', e);
    }
}

/**
 * Remove an email from the local phone state after server delete succeeds
 * @param {string} emailId
 */
function updateEmailDeleted(emailId) {
    try {
        const { emails = [], selectedEmail = null } = globalState.getState();
        globalState.setState({
            emails: emails.filter(email => email && email.id !== emailId),
            selectedEmail: selectedEmail && selectedEmail.id === emailId ? null : selectedEmail
        });
    } catch (e) {
        console.error('Error in updateEmailDeleted:', e);
    }
}

// Debounce variables for notes requests
let lastNotesRequest = 0;
const NOTES_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests notes from the server (Arma 3) with debouncing
 */
function requestNotes() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastNotesRequest < NOTES_REQUEST_COOLDOWN) {
        console.log('Notes request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::notes",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastNotesRequest = now;
        console.log('Requested notes from server');
    } else {
        console.warn('A3API not available, cannot request notes');
    }
}

/**
 * Loads notes into the global state (called by Arma 3)
 * @param {Array} notes - Array of note objects from the server
 */
function loadNotes(notes) {
    try {
        if (Array.isArray(notes)) {
            // Sort notes by updated date (newest first)
            const sortedNotes = notes.sort((a, b) => {
                const dateA = new Date(a.updatedAt || a.createdAt);
                const dateB = new Date(b.updatedAt || b.createdAt);
                return dateB - dateA;
            });

            // Update global state with loaded notes
            globalState.setState({
                notes: sortedNotes
            });
            console.log(`Loaded ${notes.length} notes from server:`, notes);
        } else {
            console.warn('Invalid notes data received:', notes);
        }
    } catch (error) {
        console.error('Error loading notes:', error);
    }
}

/**
 * Saves a note to the server (Arma 3)
 * @param {Object} note - Note object to save
 */
function saveNote(note) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::note",
            "data": note
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved note to server:', note);
    } else {
        console.warn('A3API not available, cannot save note');
    }
}

/**
 * Deletes a note from the server (Arma 3)
 * @param {string} noteId - ID of the note to delete
 */
function deleteNote(noteId) {
    if (!noteId) {
        console.error('Cannot delete note: no ID provided');
        return;
    }

    try {
        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            const alert = {
                "event": "phone::delete::note",
                "data": { id: noteId }
            };
            A3API.SendAlert(JSON.stringify(alert));
        } else {
            console.warn('A3API not available, cannot delete note. A3API type:', typeof A3API);
            if (typeof A3API !== 'undefined') {
                console.log('A3API object:', A3API);
                console.log('A3API.SendAlert available:', !!A3API.SendAlert);
            }
        }
    } catch (error) {
        console.error('Error in deleteNote function:', error);
    }
}

// Debounce variables for events requests
let lastEventsRequest = 0;
const EVENTS_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Request events from the server (Arma 3) with debouncing
 */
function requestCalendarEvents() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastEventsRequest < EVENTS_REQUEST_COOLDOWN) {
        console.log('Events request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::events",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastNotesRequest = now;
        console.log('Requested events from server');
    } else {
        console.warn('A3API not available, cannot request events');
    }
}

/**
 * Loads calendar events into the global state (called by Arma 3)
 * @param {Array} events - Array of calendar event objects from the server
 */
function loadCalendarEvents(events) {
    try {
        if (Array.isArray(events)) {
            globalState.setState({
                events: events
            });
            console.log(`Loaded ${events.length} calendar events from server:`, events);
        } else {
            console.warn('Invalid calendar events data received:', events);
        }
    } catch (error) {
        console.error('Error loading calendar events:', error);
    }
}

/**
 * Saves a calendar event to the server (Arma 3)
 * @param {Object} event - Event object to save
 */
function saveCalendarEvent(event) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::event",
            "data": event
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved calendar event to server:', event);
    } else {
        console.warn('A3API not available, cannot save calendar event');
    }
}

/**
 * Deletes a calendar event from the server (Arma 3)
 * @param {string} eventId - ID of the event to delete
 */
function deleteCalendarEvent(eventId) {
    if (!eventId) {
        console.error('Cannot delete calendar event: no ID provided');
        return;
    }

    try {
        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            const alert = {
                "event": "phone::delete::event",
                "data": { id: eventId }
            };
            A3API.SendAlert(JSON.stringify(alert));
        } else {
            console.warn('A3API not available, cannot delete calendar event.');
        }
    } catch (error) {
        console.error('Error in deleteCalendarEvent function:', error);
    }
}

// Debounce variables for world clocks requests
let lastWorldClocksRequest = 0;
const WORLD_CLOCKS_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests world clocks from the server (Arma 3) with debouncing
 */
function requestWorldClocks() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastWorldClocksRequest < WORLD_CLOCKS_REQUEST_COOLDOWN) {
        console.log('World clocks request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::clocks",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastWorldClocksRequest = now;
        console.log('Requested world clocks from server');
    } else {
        console.warn('A3API not available, cannot request world clocks');
    }
}

/**
 * Loads world clocks into the global state (called by Arma 3)
 * @param {Array} worldClocks - Array of world clock objects from the server
 */
function loadWorldClocks(worldClocks) {
    try {
        if (Array.isArray(worldClocks)) {
            // Update global state with loaded world clocks
            globalState.setState({
                worldClocks: worldClocks
            });
            console.log(`Loaded ${worldClocks.length} world clocks from server:`, worldClocks);
        } else {
            console.warn('Invalid world clocks data received:', worldClocks);
        }
    } catch (error) {
        console.error('Error loading world clocks:', error);
    }
}

/**
 * Saves a world clock to the server (Arma 3)
 * @param {Object} worldClock - World clock object to save
 */
function saveWorldClock(worldClock) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::clock",
            "data": worldClock
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved world clock to server:', worldClock);
    } else {
        console.warn('A3API not available, cannot save world clock');
    }
}

/**
 * Deletes a world clock from the server (Arma 3)
 * @param {string} clockId - ID of the world clock to delete
 */
function deleteWorldClock(clockId) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::delete::clock",
            "data": { id: clockId }
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Deleted world clock from server:', clockId);
    } else {
        console.warn('A3API not available, cannot delete world clock');
    }
}

// Debounce variables for alarms requests
let lastAlarmsRequest = 0;
const ALARMS_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests alarms from the server (Arma 3) with debouncing
 */
function requestAlarms() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastAlarmsRequest < ALARMS_REQUEST_COOLDOWN) {
        console.log('Alarms request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::alarms",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastAlarmsRequest = now;
        console.log('Requested alarms from server');
    } else {
        console.warn('A3API not available, cannot request alarms');
    }
}

/**
 * Loads alarms into the global state (called by Arma 3)
 * @param {Array} alarms - Array of alarm objects from the server
 */
function loadAlarms(alarms) {
    try {
        if (Array.isArray(alarms)) {
            // Update global state with loaded alarms
            globalState.setState({
                alarms: alarms
            });
            console.log(`Loaded ${alarms.length} alarms from server:`, alarms);
        } else {
            console.warn('Invalid alarms data received:', alarms);
        }
    } catch (error) {
        console.error('Error loading alarms:', error);
    }
}

/**
 * Saves an alarm to the server (Arma 3)
 * @param {Object} alarm - Alarm object to save
 */
function saveAlarm(alarm) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::alarm",
            "data": alarm
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved alarm to server:', alarm);
    } else {
        console.warn('A3API not available, cannot save alarm');
    }
}

/**
 * Deletes an alarm from the server (Arma 3)
 * @param {string} alarmId - ID of the alarm to delete
 */
function deleteAlarm(alarmId) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::delete::alarm",
            "data": { id: alarmId }
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Deleted alarm from server:', alarmId);
    } else {
        console.warn('A3API not available, cannot delete alarm');
    }
}

/**
 * Toggles an alarm on/off on the server (Arma 3)
 * @param {string} alarmId - ID of the alarm to toggle
 */
function toggleAlarm(alarmId) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::toggle::alarm",
            "data": { id: alarmId }
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Toggled alarm on server:', alarmId);
    } else {
        console.warn('A3API not available, cannot toggle alarm');
    }
}

// Handle any uncaught errors
window.addEventListener('error', (event) => {
    console.error('Uncaught error:', event.error);
});

// Export the initialization function and all API functions to global scope
window.initializeApp = initializeApp;
window.setTheme = setTheme;
window.requestContacts = requestContacts;
window.loadContacts = loadContacts;
window.refreshContacts = refreshContacts;
window.updateContacts = updateContacts;
window.setPlayerUid = setPlayerUid;
// Messages
window.requestMessages = requestMessages;
window.updateMessages = updateMessages;
window.updateMessageThread = updateMessageThread;
window.updateMessageSent = updateMessageSent;
window.updateMessageReceived = updateMessageReceived;
window.updateMessageRead = updateMessageRead;
window.updateMessageDeleted = updateMessageDeleted;
// Emails
window.requestEmails = requestEmails;
window.updateEmails = updateEmails;
window.updateEmailSent = updateEmailSent;
window.updateEmailReceived = updateEmailReceived;
window.updateEmailRead = updateEmailRead;
window.updateEmailDeleted = updateEmailDeleted;
window.requestNotes = requestNotes;
window.loadNotes = loadNotes;
window.saveNote = saveNote;
window.deleteNote = deleteNote;
window.requestCalendarEvents = requestCalendarEvents;
window.loadCalendarEvents = loadCalendarEvents;
window.saveCalendarEvent = saveCalendarEvent;
window.deleteCalendarEvent = deleteCalendarEvent;
window.requestWorldClocks = requestWorldClocks;
window.loadWorldClocks = loadWorldClocks;
window.saveWorldClock = saveWorldClock;
window.deleteWorldClock = deleteWorldClock;
window.requestAlarms = requestAlarms;
window.loadAlarms = loadAlarms;
window.saveAlarm = saveAlarm;
window.deleteAlarm = deleteAlarm;
window.toggleAlarm = toggleAlarm;

