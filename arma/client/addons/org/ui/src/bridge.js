(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const store = RegistryApp.store;
    const bridge = window.ForgeWebUI.createBridge({
        closeEvent: "org::close",
        globalName: "ForgeBridge",
        readyEvent: "org::ready",
    });

    function sendEvent(event, data) {
        return bridge.send(event, data);
    }

    function requestLogin(credentials) {
        store.startLogin();

        const sent = sendEvent("org::login::request", credentials);
        if (sent) {
            return;
        }

        store.failLogin("Arma login bridge is unavailable.");
    }

    function requestCreateOrg(registration) {
        store.startCreate();

        const sent = sendEvent("org::create::request", registration);
        if (sent) {
            return;
        }

        store.failCreate("Arma registration bridge is unavailable.");
    }

    function requestDisbandOrg() {
        const sent = sendEvent("org::disband::request", {});
        if (sent) {
            return;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma disband bridge is unavailable.",
            );
        }
    }

    function requestLeaveOrg() {
        const sent = sendEvent("org::leave::request", {});
        if (sent) {
            return;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma leave bridge is unavailable.",
            );
        }
    }

    function requestCreditLine(payload) {
        const sent = sendEvent("org::credit::request", payload);
        if (sent) {
            return true;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma credit line bridge is unavailable.",
            );
        }

        return false;
    }

    function requestPayroll(payload) {
        const sent = sendEvent("org::payroll::request", payload);
        if (sent) {
            return true;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma payroll bridge is unavailable.",
            );
        }

        return false;
    }

    function requestTreasuryTransfer(payload) {
        const sent = sendEvent("org::transfer::request", payload);
        if (sent) {
            return true;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma treasury transfer bridge is unavailable.",
            );
        }

        return false;
    }

    function requestInvitePlayer(payload) {
        const sent = sendEvent("org::invite::request", payload);
        if (sent) {
            return true;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma organization invite bridge is unavailable.",
            );
        }

        return false;
    }

    function requestAcceptInvite(payload) {
        const sent = sendEvent("org::invite::accept", payload);
        if (sent) {
            return true;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma organization invite bridge is unavailable.",
            );
        }

        return false;
    }

    function requestDeclineInvite(payload) {
        const sent = sendEvent("org::invite::decline", payload);
        if (sent) {
            return true;
        }

        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                "Arma organization invite bridge is unavailable.",
            );
        }

        return false;
    }

    bridge.on("org::login::success", (payloadData) => {
        store.completeLogin(payloadData);
    });

    bridge.on("org::login::failure", (payloadData) => {
        store.failLogin(payloadData.message || "Authentication failed.");
    });

    bridge.on("org::create::success", (payloadData) => {
        store.completeCreate(payloadData);
    });

    bridge.on("org::create::failure", (payloadData) => {
        store.failCreate(
            payloadData.message || "Organization registration failed.",
        );
    });

    bridge.on("org::sync", (payloadData) => {
        if (store && typeof store.hydratePortal === "function") {
            store.hydratePortal(payloadData);
        }
    });

    bridge.on("org::credit::success", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "success",
                payloadData.message || "Credit line assigned.",
            );
        }
    });

    bridge.on("org::credit::failure", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                payloadData.message || "Unable to assign credit line.",
            );
        }
    });

    bridge.on("org::treasury::success", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "success",
                payloadData.message || "Treasury action completed.",
            );
        }
    });

    bridge.on("org::treasury::failure", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                payloadData.message || "Treasury action failed.",
            );
        }
    });

    bridge.on("org::invite::success", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "success",
                payloadData.message || "Organization invite sent.",
            );
        }
    });

    bridge.on("org::invite::failure", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                payloadData.message || "Unable to send organization invite.",
            );
        }
    });

    bridge.on("org::invite::decision::success", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "success",
                payloadData.message || "Organization invite updated.",
            );
        }
    });

    bridge.on("org::invite::decision::failure", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                payloadData.message || "Unable to update organization invite.",
            );
        }
    });

    bridge.on("org::member::creditUpdated", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (!OrgPortal || !OrgPortal.store) {
            return;
        }

        OrgPortal.store.setCreditLines((currentLines) => {
            const nextLine = {
                amount: payloadData.availableAmount || payloadData.amount || 0,
                amountDue: payloadData.amountDue || 0,
                approvedAmount:
                    payloadData.approvedAmount ||
                    payloadData.availableAmount ||
                    payloadData.amount ||
                    0,
                availableAmount:
                    payloadData.availableAmount || payloadData.amount || 0,
                interestRate: payloadData.interestRate || 0.1,
                member: payloadData.memberName || "",
                outstandingPrincipal: payloadData.outstandingPrincipal || 0,
                uid: payloadData.memberUid || "",
            };
            const matchIndex = currentLines.findIndex(
                (line) => line.uid === nextLine.uid,
            );

            if (matchIndex === -1) {
                return [...currentLines, nextLine];
            }

            return currentLines.map((line, index) =>
                index === matchIndex ? nextLine : line,
            );
        });
    });

    bridge.on("org::disband::success", () => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
            OrgPortal.store.setOrgDisbanded(true);
        }
    });

    bridge.on("org::disband::failure", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                payloadData.message || "Organization disbanding failed.",
            );
        }
    });

    bridge.on("org::leave::success", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        store.failLogin(
            payloadData.message || "You have left the organization.",
        );
        store.setView("home");
    });

    bridge.on("org::leave::failure", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        if (OrgPortal && OrgPortal.actions) {
            OrgPortal.actions.showTreasuryNotice(
                "error",
                payloadData.message || "Unable to leave the organization.",
            );
        }
    });

    bridge.on("org::portal::revoked", (payloadData) => {
        const OrgPortal = window.OrgPortal;
        if (OrgPortal && OrgPortal.store) {
            OrgPortal.store.setModal(null);
        }

        store.failLogin(
            payloadData.message ||
                "Organization access is no longer available.",
        );
        store.setView("home");
    });

    RegistryApp.bridge = {
        close: bridge.close,
        ready: bridge.ready,
        receive: bridge.receive,
        requestLogin,
        requestCreateOrg,
        requestDisbandOrg,
        requestLeaveOrg,
        requestCreditLine,
        requestPayroll,
        requestTreasuryTransfer,
        requestInvitePlayer,
        requestAcceptInvite,
        requestDeclineInvite,
        sendEvent,
    };
})();
