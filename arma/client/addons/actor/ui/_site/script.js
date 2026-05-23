/**
 * Interaction Menu - Modern UI Implementation
 * Uses vanilla JS with React-like patterns and Redux-like state management
 */

//=============================================================================
// #region LIBRARY - DOM Helper & State Management
//=============================================================================

// Helper to create DOM elements (React-like createElement)
function h(tag, props = {}, ...children) {
    const el = document.createElement(tag);

    if (props) {
        Object.entries(props).forEach(([key, value]) => {
            if (key.startsWith("on") && typeof value === "function") {
                el.addEventListener(key.substring(2).toLowerCase(), value);
            } else if (key === "className") {
                el.className = value;
            } else if (key === "style" && typeof value === "object") {
                Object.assign(el.style, value);
            } else {
                el.setAttribute(key, value);
            }
        });
    }

    children.forEach((child) => {
        if (typeof child === "string" || typeof child === "number") {
            el.appendChild(document.createTextNode(child));
        } else if (child instanceof Node) {
            el.appendChild(child);
        } else if (Array.isArray(child)) {
            child.forEach((c) => {
                if (c instanceof Node) el.appendChild(c);
            });
        }
    });

    return el;
}

// Simple Rendering Logic
let _rootContainer = null;
let _rootComponent = null;

function render(component, container) {
    _rootContainer = container;
    _rootComponent = component;
    _render();
}

function _render() {
    if (_rootContainer && _rootComponent) {
        _rootContainer.innerHTML = "";
        _rootContainer.appendChild(_rootComponent());
    }
}

//=============================================================================
// #region ACTIONS
//=============================================================================

const ActionTypes = {
    SET_AVAILABLE_ACTIONS: "SET_AVAILABLE_ACTIONS",
    SET_MENU_ITEMS: "SET_MENU_ITEMS",
    ADD_ACTION: "ADD_ACTION",
    REMOVE_ACTION: "REMOVE_ACTION",
    CLEAR_ACTIONS: "CLEAR_ACTIONS",
};

const actions = {
    setAvailableActions: (actionTypes) => ({
        type: ActionTypes.SET_AVAILABLE_ACTIONS,
        payload: actionTypes,
    }),

    setMenuItems: (menuItems) => ({
        type: ActionTypes.SET_MENU_ITEMS,
        payload: menuItems,
    }),

    addAction: (actionType) => ({
        type: ActionTypes.ADD_ACTION,
        payload: actionType,
    }),

    removeAction: (actionType) => ({
        type: ActionTypes.REMOVE_ACTION,
        payload: actionType,
    }),

    clearActions: () => ({
        type: ActionTypes.CLEAR_ACTIONS,
    }),
};

//=============================================================================
// #region REDUCER
//=============================================================================

const baseMenuItems = [
    {
        id: "cad",
        title: "CAD",
        description: "Access CAD (Computer Aided Dispatch)",
        action: "actor::open::cad",
    },
    {
        id: "phone",
        title: "Phone",
        description: "Access and manage your personal phone",
        action: "actor::open::phone",
    },
    {
        id: "org",
        title: "Organization",
        description: "View and manage your organization data",
        action: "actor::open::org",
    },
];

const actionDefinitions = {
    atm: {
        id: "atm",
        title: "ATM",
        description: "Access the ATM",
        action: "actor::open::atm",
    },
    bank: {
        id: "bank",
        title: "Bank",
        description: "Access your bank account and manage finances",
        action: "actor::open::bank",
    },
    cad: {
        id: "cad",
        title: "CAD",
        description: "Access the CAD",
        action: "actor::open::cad",
    },
    phone: {
        id: "phone",
        title: "Phone",
        description: "Access and manage your personal phone",
        action: "actor::open::phone",
    },
    org: {
        id: "org",
        title: "Organization",
        description: "View and manage your organization data",
        action: "actor::open::org",
    },
    store: {
        id: "store",
        title: "Store",
        description: "Browse and purchase items from the store",
        action: "actor::open::store",
    },
    device: {
        id: "device",
        title: "Device",
        description: "Manage devices and settings",
        action: "actor::open::device",
    },
    garage: {
        id: "garage",
        title: "Garage",
        description: "Access and manage your vehicle collection",
        action: "actor::open::garage",
    },
    player: {
        id: "player",
        title: "Player",
        description: "Interact with player-specific actions",
        action: "actor::open::iplayer",
    },
    store: {
        id: "store",
        title: "Store",
        description: "Browse and purchase items from the store",
        action: "actor::open::store",
    },
    va: {
        id: "va",
        title: "Arsenal",
        description: "Access your virtual arsenal",
        action: "actor::open::vlocker",
    },
    vg: {
        id: "vg",
        title: "V. Garage",
        description: "Access your virtual garage",
        action: "actor::open::vgarage",
    },
};

const initialState = {
    availableActions: [],
    menuItems: [...baseMenuItems],
    baseMenuItems: [...baseMenuItems],
    actionDefinitions: { ...actionDefinitions },
};

function actorReducer(state = initialState, action) {
    switch (action.type) {
        case ActionTypes.SET_AVAILABLE_ACTIONS:
            const newMenuItems = [...state.baseMenuItems];

            const actionArray = Array.isArray(action.payload)
                ? action.payload
                : [];
            actionArray.forEach((actionItem) => {
                if (Array.isArray(actionItem) && actionItem.length === 2) {
                    const [type, value] = actionItem;
                    const definition = state.actionDefinitions[type];
                    if (definition) {
                        const context =
                            value && typeof value === "object"
                                ? value
                                : { value };
                        const garageLabel =
                            context.name || context.garageType || "";
                        const title =
                            ["garage", "vg"].includes(type) && garageLabel
                                ? `${definition.title}: ${garageLabel}`
                                : definition.title;
                        newMenuItems.push({
                            ...definition,
                            title,
                            context,
                        });
                    } else {
                        console.warn(
                            `No definition found for: ${type} - ${value}`,
                        );
                    }
                } else {
                    console.warn("Invalid action format:", actionItem);
                }
            });

            return {
                ...state,
                availableActions: action.payload,
                menuItems: newMenuItems,
            };

        case ActionTypes.SET_MENU_ITEMS:
            return {
                ...state,
                menuItems: action.payload,
            };

        case ActionTypes.ADD_ACTION:
            const definition = state.actionDefinitions[action.payload];
            if (
                definition &&
                !state.menuItems.find((item) => item.id === definition.id)
            ) {
                return {
                    ...state,
                    menuItems: [...state.menuItems, definition],
                };
            }
            return state;

        case ActionTypes.REMOVE_ACTION:
            return {
                ...state,
                menuItems: state.menuItems.filter(
                    (item) => item.id !== action.payload,
                ),
            };

        case ActionTypes.CLEAR_ACTIONS:
            return {
                ...state,
                availableActions: [],
                menuItems: [...state.baseMenuItems],
            };

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
        console.log("Dispatching action:", action);
        this.state = this.reducer(this.state, action);
        this.listeners.forEach((listener) => listener(this.state));
        _render(); // Re-render on state change
    }

    subscribe(listener) {
        this.listeners.push(listener);
        return () => {
            this.listeners = this.listeners.filter((l) => l !== listener);
        };
    }
}

const store = new Store(actorReducer, initialState);

//=============================================================================
// #region SELECTORS
//=============================================================================

const selectors = {
    getMenuItems: (state) => state.menuItems,
    getAvailableActions: (state) => state.availableActions,
    getBaseMenuItems: (state) => state.baseMenuItems,
    getActionDefinitions: (state) => state.actionDefinitions,
    getMenuItemById: (state, id) =>
        state.menuItems.find((item) => item.id === id),
    getMenuItemsCount: (state) => state.menuItems.length,
};

//=============================================================================
// #region UI COMPONENTS
//=============================================================================

// Tooltip state
let tooltipEl = null;

function createTooltip() {
    if (!tooltipEl) {
        tooltipEl = h(
            "div",
            { className: "radial-tooltip" },
            h("div", { className: "tooltip-title" }),
            h("div", { className: "tooltip-description" }),
        );
        document.body.appendChild(tooltipEl);
    }
    return tooltipEl;
}

function showTooltip(item, x, y) {
    const tooltip = createTooltip();
    tooltip.querySelector(".tooltip-title").textContent = item.title;
    tooltip.querySelector(".tooltip-description").textContent =
        item.description;
    tooltip.style.left = `${x + 15}px`;
    tooltip.style.top = `${y + 10}px`;
    tooltip.classList.add("visible");
}

function hideTooltip() {
    if (tooltipEl) {
        tooltipEl.classList.remove("visible");
    }
}

function RadialItem({ item, index, total, onClick }) {
    const menuRadius = 160;
    const itemSize = 80;

    // Calculate position in circle
    const angleStep = (2 * Math.PI) / total;
    const angle = angleStep * index - Math.PI / 2; // Start from top

    const centerX = menuRadius + itemSize / 2;
    const centerY = menuRadius + itemSize / 2;

    const x = centerX + menuRadius * Math.cos(angle) - itemSize / 2;
    const y = centerY + menuRadius * Math.sin(angle) - itemSize / 2;

    const el = h(
        "div",
        {
            className: "radial-item",
            style: {
                left: `${x}px`,
                top: `${y}px`,
            },
            onClick: () => onClick(item),
        },
        h("div", { className: "radial-item-title" }, item.title),
    );

    // Add tooltip events
    el.addEventListener("mouseenter", (e) =>
        showTooltip(item, e.clientX, e.clientY),
    );
    el.addEventListener("mousemove", (e) => {
        if (tooltipEl && tooltipEl.classList.contains("visible")) {
            tooltipEl.style.left = `${e.clientX + 15}px`;
            tooltipEl.style.top = `${e.clientY + 10}px`;
        }
    });
    el.addEventListener("mouseleave", hideTooltip);

    return el;
}

function RadialCenter({ onClose }) {
    return h(
        "div",
        {
            className: "radial-center",
            onClick: onClose,
        },
        h("div", { className: "center-label" }, "Close"),
    );
}

function RadialMenu() {
    const state = store.getState();
    const menuItems = selectors.getMenuItems(state);

    const handleItemClick = (item) => {
        console.log("Menu item clicked:", item);
        const alert = {
            event: item.action,
            data: item.context || {},
        };
        if (typeof A3API !== "undefined") {
            A3API.SendAlert(JSON.stringify(alert));
        }
    };

    const handleClose = () => {
        console.log("Close menu requested");
        const alert = {
            event: "actor::close::menu",
            data: {},
        };
        if (typeof A3API !== "undefined") {
            A3API.SendAlert(JSON.stringify(alert));
        }
    };

    if (menuItems.length === 0) {
        return h(
            "div",
            { className: "empty-state" },
            h("p", null, "No actions available"),
        );
    }

    return h(
        "div",
        { className: "radial-menu" },
        RadialCenter({ onClose: handleClose }),
        menuItems.map((item, index) =>
            RadialItem({
                item,
                index,
                total: menuItems.length,
                onClick: handleItemClick,
            }),
        ),
    );
}

function App() {
    return RadialMenu();
}

//=============================================================================
// #region DATA HANDLERS (A3API Integration)
//=============================================================================

function updateAvailableActions(actionTypes) {
    console.log("Updating available actions:", actionTypes);
    store.dispatch(actions.setAvailableActions(actionTypes));
}

function handleGetActionsResponse(data) {
    console.log("Received actions data:", data);
    store.dispatch(actions.setAvailableActions(data));
}

//=============================================================================
// #region INITIALIZATION
//=============================================================================

let initialized = false;

function initializeMenu() {
    console.log("initializeMenu() called");

    if (initialized) {
        console.log("Menu already initialized, skipping...");
        return;
    }

    const root = document.getElementById("app");
    if (root) {
        render(App, root);
        initialized = true;
        console.log("Interaction menu initialized successfully");

        // Request initial data from A3API
        if (typeof A3API !== "undefined") {
            const alert = {
                event: "actor::get::actions",
                data: {},
            };
            A3API.SendAlert(JSON.stringify(alert));
        }
    } else {
        console.error("Root element #app not found");
    }
}

// Auto-initialize based on DOM state
if (document.readyState !== "loading") {
    console.log("Script loaded after DOM ready, auto-initializing...");
    initializeMenu();
} else {
    document.addEventListener("DOMContentLoaded", () => {
        console.log("DOM loaded, initializing menu...");
        initializeMenu();
    });
}
