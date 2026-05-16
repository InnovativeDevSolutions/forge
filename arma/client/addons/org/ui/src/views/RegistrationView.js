(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h, ensureScopedStyle } = RegistryApp.runtime;
    const store = RegistryApp.store;
    const bridge = RegistryApp.bridge;
    const scopeAttr = "data-ui-registration-view";
    const scopeSelector = `[${scopeAttr}]`;
    const registrationViewCss = `
${scopeSelector} {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    align-items: center;
    width: 100%;
}

${scopeSelector} .info-panel {
    text-align: left;
    padding: 1rem;
}

${scopeSelector} .create-feature-list {
    text-align: left;
    margin-top: 1.5rem;
    list-style-type: none;
    padding: 0;
}

${scopeSelector} .create-feature-item {
    margin-bottom: 0.5rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

${scopeSelector} .create-feature-icon {
    width: 1.2rem;
    height: 1.2rem;
    flex-shrink: 0;
}

${scopeSelector} .price-tag {
    margin-top: 2rem;
    padding: 1rem;
    background: var(--bg-app);
    border-radius: var(--radius);
    border: 1px solid var(--border);
}

${scopeSelector} .price-label {
    display: block;
    font-size: 0.9rem;
    color: var(--text-muted);
}

${scopeSelector} .price-value {
    display: block;
    font-size: 2rem;
    font-weight: 700;
    color: var(--primary);
}

${scopeSelector} .form-panel {
    margin: 0;
}

${scopeSelector} .app-form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    text-align: left;
}

${scopeSelector} .app-form label {
    display: block;
    margin-bottom: 0.5rem;
    color: var(--text-muted);
    font-weight: 500;
    font-size: 0.9rem;
}

${scopeSelector} .app-form input,
${scopeSelector} .app-form select {
    width: 100%;
    padding: 0.75rem;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: var(--bg-app);
    color: var(--text-main);
    font-family: inherit;
    font-size: 1rem;
    box-sizing: border-box;
    transition: border-color 0.2s;
}

${scopeSelector} .app-form input:focus,
${scopeSelector} .app-form select:focus {
    outline: none;
    border-color: var(--primary);
    box-shadow: 0 0 0 2px rgb(59 130 246 / 0.1);
}

${scopeSelector} .form-actions {
    margin-top: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    align-items: center;
}

${scopeSelector} .submit-btn {
    width: 100%;
}

${scopeSelector} .cancel-link {
    font-size: 0.9rem;
    color: var(--text-muted);
    cursor: pointer;
    text-decoration: underline;
}

${scopeSelector} .cancel-link:hover {
    color: var(--primary);
}

${scopeSelector} .form-feedback {
    padding: 0.85rem 1rem;
    border-radius: var(--radius);
    font-size: 0.92rem;
}

${scopeSelector} .form-feedback.is-error {
    background: #fef2f2;
    border: 1px solid #fecaca;
    color: #991b1b;
}

@media (max-width: 960px) {
    ${scopeSelector} {
        grid-template-columns: 1fr;
    }
}
`;

    RegistryApp.componentFns = RegistryApp.componentFns || {};

    RegistryApp.componentFns.RegistrationView = function RegistrationView() {
        const isCreating = store.getIsCreating();
        const createError = store.getCreateError();
        ensureScopedStyle("main-registration-view", registrationViewCss);

        const handleCreate = () => {
            const data = {
                orgName: String(
                    document.getElementById("org-create-name")?.value || "",
                ).trim(),
                type: String(
                    document.getElementById("org-create-type")?.value || "",
                ),
            };

            if (!bridge || typeof bridge.requestCreateOrg !== "function") {
                store.failCreate("Registration bridge is not available.");
                return;
            }

            bridge.requestCreateOrg(data);
        };

        return h(
            "div",
            { className: "split-container", [scopeAttr]: "" },
            h(
                "div",
                { className: "info-panel" },
                h("h2", null, "Registration Details"),
                h(
                    "p",
                    null,
                    "Complete the form to add your organization to the Global Organization Registry. Registration requires at least $50,000 in personal funds.",
                ),
                h(
                    "ul",
                    { className: "create-feature-list" },
                    h(
                        "li",
                        { className: "create-feature-item" },
                        h(
                            "svg",
                            {
                                viewBox: "0 0 24 24",
                                fill: "none",
                                stroke: "#10b981",
                                "stroke-width": "2",
                                "stroke-linecap": "round",
                                "stroke-linejoin": "round",
                                className: "create-feature-icon",
                            },
                            h("path", { d: "M20 6L9 17l-5-5" }),
                        ),
                        "Official Organization Designator",
                    ),
                    h(
                        "li",
                        { className: "create-feature-item" },
                        h(
                            "svg",
                            {
                                viewBox: "0 0 24 24",
                                fill: "none",
                                stroke: "#10b981",
                                "stroke-width": "2",
                                "stroke-linecap": "round",
                                "stroke-linejoin": "round",
                                className: "create-feature-icon",
                            },
                            h("path", { d: "M20 6L9 17l-5-5" }),
                        ),
                        "Secure Comms Channel",
                    ),
                    h(
                        "li",
                        { className: "create-feature-item" },
                        h(
                            "svg",
                            {
                                viewBox: "0 0 24 24",
                                fill: "none",
                                stroke: "#10b981",
                                "stroke-width": "2",
                                "stroke-linecap": "round",
                                "stroke-linejoin": "round",
                                className: "create-feature-icon",
                            },
                            h("path", { d: "M20 6L9 17l-5-5" }),
                        ),
                        "Deployment Roster Access",
                    ),
                    h(
                        "li",
                        { className: "create-feature-item" },
                        h(
                            "svg",
                            {
                                viewBox: "0 0 24 24",
                                fill: "none",
                                stroke: "#10b981",
                                "stroke-width": "2",
                                "stroke-linecap": "round",
                                "stroke-linejoin": "round",
                                className: "create-feature-icon",
                            },
                            h("path", { d: "M20 6L9 17l-5-5" }),
                        ),
                        "After-Action Report Tools",
                    ),
                ),
                h(
                    "div",
                    { className: "price-tag" },
                    h(
                        "span",
                        { className: "price-label" },
                        "Required Registration Fee",
                    ),
                    h("span", { className: "price-value" }, "$50,000"),
                ),
            ),
            h(
                "div",
                { className: "form-panel card" },
                h("h2", null, "Organization Registration"),
                h(
                    "div",
                    { className: "app-form" },
                    h(
                        "div",
                        null,
                        h("label", null, "Organization Name"),
                        h("input", {
                            id: "org-create-name",
                            type: "text",
                            placeholder: "e.g. Task Force 141",
                        }),
                    ),
                    h(
                        "div",
                        null,
                        h("label", null, "Organization Type"),
                        h(
                            "select",
                            { id: "org-create-type" },
                            h(
                                "option",
                                { value: "infantry" },
                                "Infantry / Milsim",
                            ),
                            h("option", { value: "aviation" }, "Aviation Wing"),
                            h(
                                "option",
                                { value: "pmc" },
                                "Private Military Company",
                            ),
                            h(
                                "option",
                                { value: "support" },
                                "Logistics & Support",
                            ),
                        ),
                    ),
                    h(
                        "div",
                        { className: "form-actions" },
                        createError
                            ? h(
                                  "div",
                                  { className: "form-feedback is-error" },
                                  createError,
                              )
                            : null,
                        h(
                            "button",
                            {
                                type: "button",
                                className: "submit-btn",
                                disabled: isCreating,
                                onClick: handleCreate,
                            },
                            isCreating
                                ? "Submitting Registration..."
                                : "Submit Registration",
                        ),
                        h(
                            "span",
                            {
                                className: "cancel-link",
                                onClick: () => store.setView("home"),
                            },
                            "Cancel / Return to Main",
                        ),
                    ),
                ),
            ),
        );
    };
})();
