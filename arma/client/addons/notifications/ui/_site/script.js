//=============================================================================
// #region ACTIONS
//=============================================================================

const NotificationActionTypes = {
    ADD_NOTIFICATION: "ADD_NOTIFICATION",
    REMOVE_NOTIFICATION: "REMOVE_NOTIFICATION",
    CLEAR_NOTIFICATIONS: "CLEAR_NOTIFICATIONS",
    UPDATE_NOTIFICATION: "UPDATE_NOTIFICATION",
};

const notificationActions = {
    addNotification: (notification) => ({
        type: NotificationActionTypes.ADD_NOTIFICATION,
        payload: {
            id: Date.now() + Math.random(),
            timestamp: Date.now(),
            type: "info",
            title: "Notification",
            message: "Default message",
            duration: 0,
            status: "showing",
            ...notification,
        },
    }),
    removeNotification: (id) => ({
        type: NotificationActionTypes.REMOVE_NOTIFICATION,
        payload: { id },
    }),
    clearNotifications: () => ({
        type: NotificationActionTypes.CLEAR_NOTIFICATIONS,
    }),
    updateNotification: (id, updates) => ({
        type: NotificationActionTypes.UPDATE_NOTIFICATION,
        payload: { id, updates },
    }),
};

//=============================================================================
// #region REDUCER
//=============================================================================

const notificationInitialState = {
    notifications: [],
    maxNotifications: 3,
};

function notificationReducer(state = notificationInitialState, action = {}) {
    switch (action.type) {
        case NotificationActionTypes.ADD_NOTIFICATION: {
            if (!action.payload) return state;
            let newNotifications = [...state.notifications];
            if (newNotifications.length >= state.maxNotifications) {
                newNotifications = newNotifications.slice(1);
            }
            return {
                ...state,
                notifications: [...newNotifications, action.payload],
            };
        }
        case NotificationActionTypes.REMOVE_NOTIFICATION: {
            if (!action.payload || !action.payload.id) return state;
            return {
                ...state,
                notifications: state.notifications.filter(
                    (n) => n.id !== action.payload.id,
                ),
            };
        }
        case NotificationActionTypes.CLEAR_NOTIFICATIONS:
            return { ...state, notifications: [] };
        case NotificationActionTypes.UPDATE_NOTIFICATION: {
            if (
                !action.payload ||
                !action.payload.id ||
                !action.payload.updates
            )
                return state;
            return {
                ...state,
                notifications: state.notifications.map((n) =>
                    n.id === action.payload.id
                        ? { ...n, ...action.payload.updates }
                        : n,
                ),
            };
        }
        default:
            return state;
    }
}

//=============================================================================
// #region STORE
//=============================================================================

class Store {
    constructor(reducer, initialState) {
        this.reducer = reducer;
        this.state = initialState;
        this.listeners = [];
    }

    getState() {
        return this.state;
    }

    dispatch(action) {
        this.state = this.reducer(this.state, action);
        this.listeners.forEach((listener) => listener(this.state));
        return action;
    }

    subscribe(listener) {
        this.listeners.push(listener);
        return () => {
            this.listeners = this.listeners.filter((l) => l !== listener);
        };
    }
}

const notificationStore = new Store(
    notificationReducer,
    notificationInitialState,
);

//=============================================================================
// #region SELECTORS
//=============================================================================

const notificationSelectors = {
    getNotifications: (state) => state.notifications,
    getMaxNotifications: (state) => state.maxNotifications,
};

//=============================================================================
// #region UI COMPONENT
//=============================================================================

class NotificationUI {
    constructor(store) {
        this.store = store;
        this.unsubscribe = null;
        this.container = document.getElementById("notification-container");
        this.renderedNotifications = new Map();
        this.dismissTimers = new Map();
    }

    init() {
        if (!this.container) {
            console.error("Notification container not found");
            return;
        }
        this.unsubscribe = this.store.subscribe((state) => this.render(state));
        this.render(this.store.getState());
    }

    destroy() {
        if (this.unsubscribe) this.unsubscribe();
        this.dismissTimers.forEach((timers) => {
            clearTimeout(timers.hideTimer);
            clearTimeout(timers.removeTimer);
            clearTimeout(timers.progressTimer);
        });
        this.dismissTimers.clear();
        this.renderedNotifications.forEach((el) => {
            if (el.parentNode) el.parentNode.removeChild(el);
        });
        this.renderedNotifications.clear();
    }

    render(state) {
        const notifications = notificationSelectors.getNotifications(state);

        // Remove notifications no longer present
        const currentIds = new Set(notifications.map((n) => n.id));
        for (const [id, el] of this.renderedNotifications.entries()) {
            if (!currentIds.has(id)) {
                this.clearDismissTimers(id);
                if (el.parentNode) el.parentNode.removeChild(el);
                this.renderedNotifications.delete(id);
            }
        }

        // Add or update notifications
        notifications.forEach((notification) => {
            if (!notification || !notification.id) return;
            if (!this.renderedNotifications.has(notification.id)) {
                this.createNotificationElement(notification);
            } else {
                this.updateNotificationElement(notification);
            }
        });
    }

    clearDismissTimers(id) {
        const timers = this.dismissTimers.get(id);
        if (!timers) return;

        clearTimeout(timers.hideTimer);
        clearTimeout(timers.removeTimer);
        clearTimeout(timers.progressTimer);
        this.dismissTimers.delete(id);
    }

    escapeHTML(value) {
        return String(value == null ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    normalizeType(type) {
        const supportedTypes = new Set([
            "success",
            "danger",
            "warning",
            "info",
        ]);
        return supportedTypes.has(type) ? type : "info";
    }

    formatTypeLabel(type) {
        const labels = {
            success: "Success",
            danger: "Critical",
            warning: "Warning",
            info: "Info",
        };
        return labels[this.normalizeType(type)] || labels.info;
    }

    getDurationLabel(duration) {
        if (!(duration > 0)) return "Pinned";
        const seconds = Math.max(1, Math.round(duration / 100) / 10);
        return `${seconds.toFixed(1)}s`;
    }

    getTimestampLabel(timestamp) {
        const date = new Date(timestamp || Date.now());
        const hours = String(date.getHours()).padStart(2, "0");
        const minutes = String(date.getMinutes()).padStart(2, "0");
        return `${hours}:${minutes}`;
    }

    createNotificationElement(notification) {
        const type = this.normalizeType(notification.type);
        const title = this.escapeHTML(notification.title || "Notification");
        const message = this.escapeHTML(notification.message || "No message");
        const isPersistent = !(notification.duration > 0);
        const el = document.createElement("div");
        el.className = `notification ${type}${isPersistent ? " is-persistent" : ""}`;
        el.dataset.id = notification.id;
        el.innerHTML = `
            <div class="notification-inner">
                <div class="notification-header">
                    <div class="notification-title">${title}</div>
                    <div class="notification-subtitle">Forge alert</div>
                </div>
                <div class="notification-body">
                    <div class="notification-meta">
                        <span class="notification-badge">${this.formatTypeLabel(type)}</span>
                        <span class="notification-time">${this.getTimestampLabel(notification.timestamp)}</span>
                    </div>
                    <div class="notification-message">${message}</div>
                    <div class="notification-footer">
                        <span>${isPersistent ? "Persistent signal" : "Auto-dismiss"}</span>
                        <span>${this.getDurationLabel(notification.duration)}</span>
                    </div>
                </div>
            </div>
            ${notification.duration > 0 ? '<div class="notification-progress"><div class="notification-progress-bar"></div></div>' : ""}
        `;
        this.container.appendChild(el);
        this.renderedNotifications.set(notification.id, el);
        requestAnimationFrame(() => {
            requestAnimationFrame(() => el.classList.add("show"));
        });

        // Set progress bar animation duration
        if (notification.duration > 0) {
            const progressBar = el.querySelector(".notification-progress-bar");
            if (progressBar) {
                progressBar.style.transitionDuration = `${notification.duration}ms`;
                const progressTimer = setTimeout(() => {
                    progressBar.style.transform = "scaleX(0)";
                }, 30);
                this.dismissTimers.set(notification.id, { progressTimer });
            }

            const hideTimer = setTimeout(() => {
                notificationStore.dispatch(
                    notificationActions.updateNotification(notification.id, {
                        status: "hiding",
                    }),
                );
            }, notification.duration);
            const removeTimer = setTimeout(() => {
                this.clearDismissTimers(notification.id);
                notificationStore.dispatch(
                    notificationActions.removeNotification(notification.id),
                );
            }, notification.duration + 260);

            const existingTimers =
                this.dismissTimers.get(notification.id) || {};
            this.dismissTimers.set(notification.id, {
                ...existingTimers,
                hideTimer,
                removeTimer,
            });
        }
    }

    updateNotificationElement(notification) {
        const el = this.renderedNotifications.get(notification.id);
        if (!el) return;
        if (notification.status === "hiding") {
            el.classList.add("hide");
        }
    }
}

//=============================================================================
// #region GLOBAL API & EVENT HANDLING
//=============================================================================

let notificationUI = null;
let notificationUIInitialized = false;

function notifyArmaNotificationReady() {
    if (
        window.parent &&
        window.parent !== window &&
        typeof window.parent.postMessage === "function"
    ) {
        window.parent.postMessage({ event: "notifications::ready" }, "*");
    }
    if (typeof A3API !== "undefined" && typeof A3API.SendAlert === "function") {
        A3API.SendAlert(JSON.stringify({ event: "notifications::ready" }));
    }
}

function initializeNotifications() {
    if (notificationUIInitialized) {
        console.log("Notification system already initialized, skipping...");
        return;
    }
    notificationUI = new NotificationUI(notificationStore);
    notificationUI.init();
    notificationUIInitialized = true;
    console.log("Notification system is ready!");
    notifyArmaNotificationReady();
}

// Expose global notification API
const showNotification = (type, title, message, duration) => {
    return notificationStore.dispatch(
        notificationActions.addNotification({ type, title, message, duration }),
    );
};
const clearAllNotifications = () => {
    return notificationStore.dispatch(notificationActions.clearNotifications());
};
window.showNotification = showNotification;
window.clearAllNotifications = clearAllNotifications;
window.ForgeNotifications = {
    show: showNotification,
    clear: clearAllNotifications,
};

// Listen for global notification events (for Arma/SQF or other scripts)
window.addEventListener("forge:notify", function (e) {
    if (!e || !e.detail) return;
    const { type, title, message, duration } = e.detail;
    showNotification(type, title, message, duration);
});

// Auto-initialize if DOM is already loaded when script executes
if (document.readyState !== "loading") {
    initializeNotifications();
} else {
    document.addEventListener("DOMContentLoaded", initializeNotifications, {
        once: true,
    });
}
