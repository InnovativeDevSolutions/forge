/**
 * Player Bank App - Vanilla JS "React-like" Implementation
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

// --- 2. Bank Application Components ---

// Global State
const [getView, setView] = createSignal("login"); // 'login', 'dashboard'
const [getBalance, setBalance] = createSignal(1250000);
const [getPending, setPending] = createSignal(45250); // Mock pending earnings
const [getTransactions, setTransactions] = createSignal([
    {
        id: 1,
        type: "credit",
        desc: "Contract Payment: OP-442",
        amount: 150000,
        date: "2026-02-05",
    },
    {
        id: 2,
        type: "debit",
        desc: "Equipment Purchase: Ammunition",
        amount: -4500,
        date: "2026-02-04",
    },
    {
        id: 3,
        type: "debit",
        desc: "Vehicle Maintenance",
        amount: -1200,
        date: "2026-02-03",
    },
]);

// Header
function Header() {
    return h(
        "div",
        { className: "header" },
        h(
            "h1",
            {
                style: { cursor: "pointer" },
                onClick: () => setView("login"),
            },
            "Global Financial Network",
        ),
        h("p", null, "Secure Banking"),
    );
}

// Login View
function BankLogin() {
    const handleSubmit = (e) => {
        e.preventDefault();
        setView("dashboard");
    };

    return h(
        "div",
        { className: "card", style: { maxWidth: "400px", margin: "0 auto" } },
        h("h2", null, "Secure Access"),
        h(
            "form",
            { onSubmit: handleSubmit },
            h(
                "div",
                null,
                h("label", null, "Account ID"),
                h("input", { type: "text", placeholder: "xxxx-xxxx-xxxx" }),
            ),
            h(
                "div",
                null,
                h("label", null, "Security PIN"),
                h("input", { type: "password", placeholder: "••••" }),
            ),
            h(
                "div",
                { className: "form-actions" },
                h(
                    "button",
                    { type: "submit", style: { width: "100%" } },
                    "Authenticate",
                ),
                h(
                    "p",
                    {
                        style: {
                            fontSize: "0.8rem",
                            color: "var(--text-muted)",
                            marginTop: "1rem",
                        },
                    },
                    "Authorized Personnel Only",
                ),
            ),
        ),
    );
}

// Transaction History Helper
function TransactionHistory() {
    const transactions = getTransactions();

    return h(
        "div",
        { className: "card" },
        h(
            "h3",
            {
                style: {
                    textAlign: "left",
                    borderBottom: "1px solid var(--border)",
                    paddingBottom: "1rem",
                    marginBottom: "1rem",
                },
            },
            "Recent Transactions",
        ),
        h(
            "ul",
            { style: { listStyle: "none", padding: 0 } },
            ...transactions.map((tx) =>
                h(
                    "li",
                    {
                        style: {
                            display: "flex",
                            justifyContent: "space-between",
                            padding: "0.75rem 0",
                            borderBottom: "1px solid var(--bg-surface-hover)",
                        },
                    },
                    h(
                        "div",
                        { style: { textAlign: "left" } },
                        h("div", { style: { fontWeight: "500" } }, tx.desc),
                        h(
                            "div",
                            {
                                style: {
                                    fontSize: "0.85rem",
                                    color: "var(--text-muted)",
                                },
                            },
                            tx.date,
                        ),
                    ),
                    h(
                        "div",
                        {
                            style: {
                                fontWeight: "700",
                                color:
                                    tx.type === "credit"
                                        ? "#10b981"
                                        : "#ef4444",
                            },
                        },
                        (tx.type === "credit" ? "+" : "") +
                            "$" +
                            Math.abs(tx.amount).toLocaleString(),
                    ),
                ),
            ),
        ),
    );
}

// Transfer Form
function TransferForm() {
    const handleSubmit = (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const amount = parseFloat(formData.get("amount"));

        if (amount > 0 && amount <= getBalance()) {
            setBalance((prev) => prev - amount);
            const newTx = {
                id: Date.now(),
                type: "debit",
                desc: "Transfer to " + formData.get("recipient"),
                amount: -amount,
                date: new Date().toISOString().split("T")[0],
            };
            setTransactions((prev) => [newTx, ...prev]);
        }
    };

    return h(
        "div",
        { className: "card" },
        h("h2", null, "Wire Transfer"),
        h(
            "form",
            { onSubmit: handleSubmit },
            h(
                "div",
                null,
                h("label", null, "Recipient Name / GUID"),
                h("input", {
                    name: "recipient",
                    type: "text",
                    placeholder: "Enter Name or GUID",
                }),
            ),
            h(
                "div",
                null,
                h("label", null, "Amount"),
                h("input", {
                    name: "amount",
                    type: "number",
                    placeholder: "0.00",
                }),
            ),
            h("button", { type: "submit" }, "Send Funds"),
        ),
    );
}

// Dashboard View
function BankDashboard() {
    return h(
        "div",
        { className: "content" },
        // Top Row: Balance
        h(
            "div",
            { className: "card", style: { gridColumn: "span 2" } },
            h(
                "h2",
                {
                    style: {
                        fontSize: "1.2rem",
                        color: "var(--text-muted)",
                        textTransform: "uppercase",
                        letterSpacing: "0.05em",
                    },
                },
                "Total Balance",
            ),
            h(
                "div",
                {
                    style: {
                        fontSize: "2.8rem",
                        fontWeight: "800",
                        color: "var(--primary-hover)",
                        margin: "1rem 0",
                    },
                },
                "$" + getBalance().toLocaleString(),
            ),
            h(
                "div",
                {
                    style: {
                        textAlign: "center",
                        marginBottom: "1.5rem",
                        color: "var(--text-muted)",
                        fontSize: "1.2rem",
                    },
                },
                "Pending: ",
                h(
                    "span",
                    { style: { color: "#fbbf24", fontWeight: "bold" } },
                    "$" + getPending().toLocaleString(),
                ),
            ),
            h(
                "div",
                {
                    style: {
                        display: "flex",
                        gap: "1rem",
                        justifyContent: "center",
                    },
                },
                h(
                    "button",
                    {
                        onClick: () => {
                            const pending = getPending();
                            if (pending > 0) {
                                setBalance((prev) => prev + pending);
                                setPending(0);
                                const newTx = {
                                    id: Date.now(),
                                    type: "credit",
                                    desc: "Field Deposit",
                                    amount: pending,
                                    date: new Date()
                                        .toISOString()
                                        .split("T")[0],
                                };
                                setTransactions((prev) => [newTx, ...prev]);
                            }
                        },
                        style: {
                            opacity: getPending() > 0 ? "1" : "0.5",
                            cursor: getPending() > 0 ? "pointer" : "default",
                        },
                    },
                    "Deposit Pending",
                ),
                h(
                    "button",
                    {
                        style: {
                            background: "var(--bg-surface-hover)",
                            color: "var(--text-main)",
                            border: "1px solid var(--border)",
                        },
                    },
                    "Statement",
                ),
            ),
        ),
        // Middle Row: Transfer Form
        TransferForm(),
        // Bottom Row: History (Full Width in simplified grid, or separate)
        TransactionHistory(),
    );
}

// Footer
function Footer() {
    return h(
        "div",
        { className: "footer" },
        h(
            "div",
            { className: "wrapper" },
            h(
                "div",
                null,
                h("h3", null, "Secure Banking"),
                h(
                    "ul",
                    { style: { listStyleType: "none", padding: 0 } },
                    h("li", null, "FDIC Insured"),
                    h("li", null, "Fraud Protection"),
                    h("li", null, "24/7 Support"),
                    h("li", null, "API Access"),
                ),
            ),
            h(
                "div",
                null,
                h("h3", null, "Notices"),
                h(
                    "ul",
                    { style: { listStyleType: "none", padding: 0 } },
                    h("li", null, "Terms of Service"),
                    h("li", null, "Privacy Policy"),
                    h("li", null, "Interest Rates"),
                    h("li", null, "Report Fraud"),
                ),
            ),
        ),
    );
}

// Main App
function App() {
    const view = getView();

    let mainContent;
    if (view === "login") {
        mainContent = BankLogin();
    } else if (view === "dashboard") {
        mainContent = BankDashboard();
    }

    return h(
        "main",
        null,
        h("div", { className: "container" }, Header(), mainContent),
        Footer(),
    );
}

// Mount
const root = document.getElementById("app");
render(App, root);
