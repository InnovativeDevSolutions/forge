/**
 * ATM App - Vanilla JS Kiosk Implementation
 */

// --- 1. The "Library" Logic (Reused) ---

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
            child.forEach((c) => el.appendChild(c));
        }
    });
    return el;
}

let _rootContainer = null;
let _rootComponent = null;

function render(component, container) {
    _rootContainer = container;
    _rootComponent = component;
    _render();
}

function _render() {
    _rootContainer.innerHTML = "";
    _rootContainer.appendChild(_rootComponent());
}

const createSignal = (initialValue) => {
    let _val = initialValue;
    const getValue = () => _val;
    const setValue = (newValue) => {
        _val = typeof newValue === "function" ? newValue(_val) : newValue;
        _render();
    };
    return [getValue, setValue];
};

// --- 2. ATM Application Components ---

// Global State
const [getView, setView] = createSignal("pin"); // 'pin', 'menu', 'withdraw', 'custom_withdraw', 'balance'
const [getPin, setPin] = createSignal("");
const [getCustomAmount, setCustomAmount] = createSignal(""); // For custom withdrawal
const [getBalance, setBalance] = createSignal(1250000); // Shared mockup balance
const [getMessage, setMessage] = createSignal(""); // For feedback

// Header
function Header() {
    return h(
        "div",
        { className: "header", style: { marginBottom: "2rem" } },
        h("h1", null, "ATM TERMINAL"),
        h("p", null, "Global Financial Network"),
    );
}

// PIN Entry View
function PinView() {
    const currentPin = getPin();

    const handleNumClick = (num) => {
        if (currentPin.length < 4) {
            setPin((prev) => prev + num);
        }
    };

    const handleClear = () => setPin("");
    const handleEnter = () => {
        if (currentPin.length === 4) {
            // Mock auth success
            setView("menu");
        } else {
            setMessage("Invalid PIN Length");
            setTimeout(() => setMessage(""), 2000);
        }
    };

    return h(
        "div",
        { className: "card", style: { padding: "3rem 2rem" } },
        h("h2", null, "Enter Security PIN"),
        h(
            "div",
            { className: "pin-display" },
            currentPin.replace(/./g, "•") || "----",
        ),
        h("p", { style: { color: "red", height: "1.5rem" } }, getMessage()),
        h(
            "div",
            { className: "numpad" },
            ["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((num) =>
                h("button", { onClick: () => handleNumClick(num) }, num),
            ),
            h(
                "button",
                {
                    style: { background: "#ef4444", color: "white" },
                    onClick: handleClear,
                },
                "C",
            ),
            h("button", { onClick: () => handleNumClick("0") }, "0"),
            h(
                "button",
                {
                    style: { background: "#10b981", color: "white" },
                    onClick: handleEnter,
                },
                "↵",
            ),
        ),
    );
}

// Main Menu View
function MenuView() {
    return h(
        "div",
        { className: "kiosk-content" },
        h(
            "h2",
            { style: { textAlign: "center", marginBottom: "1rem" } },
            "Select Transaction",
        ),
        h(
            "div",
            { className: "kiosk-menu-stack" },
            h(
                "button",
                { className: "kiosk-btn", onClick: () => setView("withdraw") },
                "Withdraw Cash",
            ),
            h(
                "button",
                { className: "kiosk-btn", onClick: () => setView("balance") },
                "Check Balance",
            ),
            h(
                "button",
                {
                    className: "kiosk-btn",
                    style: {
                        background: "var(--bg-surface)",
                        color: "var(--text-main)",
                        border: "1px solid var(--border)",
                    },
                    onClick: () => {
                        setPin("");
                        setView("pin");
                    },
                },
                "Cancel Transaction",
            ),
        ),
    );
}

// Withdraw View
function WithdrawView() {
    const handleWithdraw = (amount) => {
        if (getBalance() >= amount) {
            setBalance((prev) => prev - amount);
            setMessage(`Please take your cash: $${amount}`);
            setTimeout(() => {
                setMessage("");
                setView("menu");
            }, 3000);
        } else {
            setMessage("Insufficient Funds");
            setTimeout(() => setMessage(""), 2000);
        }
    };

    if (getMessage()) {
        return h(
            "div",
            {
                className: "card",
                style: { padding: "4rem", textAlign: "center" },
            },
            h("h2", { style: { color: "var(--primary)" } }, getMessage()),
        );
    }

    return h(
        "div",
        { className: "kiosk-content" },
        h(
            "h2",
            { style: { textAlign: "center", marginBottom: "1rem" } },
            "Select Amount",
        ),
        h(
            "div",
            { className: "kiosk-grid" },
            h(
                "button",
                { className: "kiosk-btn", onClick: () => handleWithdraw(20) },
                "$20",
            ),
            h(
                "button",
                { className: "kiosk-btn", onClick: () => handleWithdraw(50) },
                "$50",
            ),
            h(
                "button",
                { className: "kiosk-btn", onClick: () => handleWithdraw(100) },
                "$100",
            ),
            h(
                "button",
                {
                    className: "kiosk-btn",
                    onClick: () => {
                        setCustomAmount("");
                        setView("custom_withdraw");
                    },
                },
                "Other Amount",
            ),
            h(
                "button",
                {
                    className: "kiosk-btn",
                    style: {
                        gridColumn: "span 2",
                        background: "var(--text-muted)",
                    },
                    onClick: () => setView("menu"),
                },
                "Cancel",
            ),
        ),
    );
}

// Custom Withdraw View
function CustomWithdrawView() {
    const currentAmount = getCustomAmount();

    const handleNumClick = (num) => {
        if (currentAmount.length < 5) {
            // Limit to 5 digits for safety
            setCustomAmount((prev) => prev + num);
        }
    };

    const handleClear = () => setCustomAmount("");

    const handleEnter = () => {
        const amount = parseInt(currentAmount, 10);
        if (amount > 0) {
            if (getBalance() >= amount) {
                setBalance((prev) => prev - amount);
                setMessage(`Please take your cash: $${amount}`);
                setTimeout(() => {
                    setMessage("");
                    setView("menu");
                }, 3000);
            } else {
                setMessage("Insufficient Funds");
                setTimeout(() => setMessage(""), 2000);
            }
        } else {
            setMessage("Invalid Amount");
            setTimeout(() => setMessage(""), 2000);
        }
    };

    if (getMessage()) {
        return h(
            "div",
            {
                className: "card",
                style: { padding: "4rem", textAlign: "center" },
            },
            h("h2", { style: { color: "var(--primary)" } }, getMessage()),
        );
    }

    return h(
        "div",
        { className: "card", style: { padding: "3rem 2rem" } },
        h("h2", null, "Enter Amount"),
        h(
            "div",
            { className: "pin-display" },
            currentAmount ? `$${currentAmount}` : "$0",
        ),
        h(
            "div",
            { className: "numpad" },
            ["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((num) =>
                h("button", { onClick: () => handleNumClick(num) }, num),
            ),
            h(
                "button",
                {
                    style: { background: "#ef4444", color: "white" },
                    onClick: handleClear,
                },
                "C",
            ),
            h("button", { onClick: () => handleNumClick("0") }, "0"),
            h(
                "button",
                {
                    style: { background: "#10b981", color: "white" },
                    onClick: handleEnter,
                },
                "↵",
            ),
        ),
        h(
            "button",
            {
                style: {
                    width: "100%",
                    marginTop: "2rem",
                    padding: "1rem",
                    background: "var(--text-muted)",
                },
                onClick: () => setView("withdraw"),
            },
            "Cancel",
        ),
    );
}

// Balance View
function BalanceView() {
    return h(
        "div",
        { className: "card", style: { textAlign: "center", padding: "3rem" } },
        h("h2", { style: { color: "var(--text-muted)" } }, "Available Balance"),
        h(
            "div",
            {
                style: {
                    fontSize: "4rem",
                    fontWeight: "800",
                    margin: "2rem 0",
                    color: "var(--primary-hover)",
                },
            },
            "$" + getBalance().toLocaleString(),
        ),
        h(
            "button",
            {
                className: "kiosk-btn",
                style: { width: "100%", maxWidth: "300px", margin: "0 auto" },
                onClick: () => setView("menu"),
            },
            "Return to Menu",
        ),
    );
}

// Main App
function App() {
    const view = getView();

    let mainContent;
    if (view === "pin") {
        mainContent = PinView();
    } else if (view === "menu") {
        mainContent = MenuView();
    } else if (view === "withdraw") {
        mainContent = WithdrawView();
    } else if (view === "custom_withdraw") {
        mainContent = CustomWithdrawView();
    } else if (view === "balance") {
        mainContent = BalanceView();
    }

    return h(
        "main",
        null,
        h("div", { className: "container" }, Header(), mainContent),
    );
}

// Mount
const root = document.getElementById("app");
render(App, root);
