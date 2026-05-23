(function () {
    const SharedUI = (window.SharedUI = window.SharedUI || {});
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h, ensureScopedStyle } = RegistryApp.runtime;
    const scopeAttr = "data-ui-modal";
    const scopeSelector = `[${scopeAttr}]`;
    const modalCss = `
${scopeSelector} {
    position: fixed;
    inset: 0;
    background: rgb(15 23 42 / 0.38);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1.5rem;
    z-index: 20;
}

${scopeSelector} .app-modal-card {
    width: min(100%, 30rem);
    margin-bottom: 0;
    text-align: left;
}

${scopeSelector} .app-modal-head {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
    margin-bottom: 1rem;
}

${scopeSelector} .app-modal-title {
    margin: 0;
    color: var(--primary-hover);
    font-size: 1.45rem;
}

${scopeSelector} .app-modal-close {
    width: 2.25rem;
    height: 2.25rem;
    padding: 0;
    background: var(--bg-surface);
    color: var(--text-main);
    border: 1px solid var(--border);
    box-shadow: none;
    transform: none;
}

${scopeSelector} .app-modal-close:hover {
    background: var(--bg-surface-hover);
    color: var(--text-main);
    box-shadow: none;
    transform: none;
}

${scopeSelector} .app-modal-form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

${scopeSelector} .app-modal-form label {
    display: block;
    margin-bottom: 0.5rem;
    color: var(--text-muted);
    font-weight: 500;
    font-size: 0.9rem;
}

${scopeSelector} .app-modal-form input,
${scopeSelector} .app-modal-form select {
    width: 100%;
    padding: 0.75rem;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: var(--bg-app);
    color: var(--text-main);
    font-family: inherit;
    font-size: 1rem;
    box-sizing: border-box;
    transition: border-color 0.2s, box-shadow 0.2s;
}

${scopeSelector} .app-modal-form input:focus,
${scopeSelector} .app-modal-form select:focus {
    outline: none;
    border-color: var(--primary);
    box-shadow: 0 0 0 2px rgb(71 85 105 / 0.12);
}

${scopeSelector} .app-modal-form input:disabled,
${scopeSelector} .app-modal-form select:disabled {
    background: #f1f5f9;
    color: var(--text-muted);
    cursor: not-allowed;
}

${scopeSelector} .app-modal-actions {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 0.75rem;
    margin-top: 0.5rem;
}

${scopeSelector} .app-modal-actions button + button,
${scopeSelector} .app-modal-danger-actions button + button {
    margin-left: 0;
}

${scopeSelector} .app-modal-danger {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    gap: 1rem;
    padding: 1rem;
    border: 1px solid #fecaca;
    border-radius: var(--radius);
    background: #fff1f2;
    align-items: flex-start;
}

${scopeSelector} .app-modal-danger p {
    margin: 0;
    color: var(--text-main);
}

${scopeSelector} .app-modal-danger-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
}

@media (max-width: 960px) {
    ${scopeSelector} .app-modal-head,
    ${scopeSelector} .app-modal-danger {
        flex-direction: column;
        align-items: flex-start;
    }
}
`;

    SharedUI.componentFns = SharedUI.componentFns || {};

    SharedUI.componentFns.Modal = function Modal({
        title = "",
        body = null,
        onClose = null,
    }) {
        ensureScopedStyle("shared-modal", modalCss);

        return h(
            "div",
            {
                className: "app-modal-backdrop",
                [scopeAttr]: "",
                onClick: (e) => {
                    if (e.target === e.currentTarget && onClose) {
                        onClose();
                    }
                },
            },
            h(
                "div",
                { className: "card app-modal-card" },
                h(
                    "div",
                    { className: "app-modal-head" },
                    h(
                        "div",
                        null,
                        h("h2", { className: "app-modal-title" }, title),
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "app-modal-close",
                            onClick: onClose,
                            "aria-label": "Close dialog",
                        },
                        "x",
                    ),
                ),
                body,
            ),
        );
    };
})();
