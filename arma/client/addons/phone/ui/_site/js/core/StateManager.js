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
