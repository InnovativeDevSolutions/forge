(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const store = RegistryApp.store;

    function sendEvent(event, data) {
        if (
            typeof A3API !== "undefined" &&
            typeof A3API.SendAlert === "function"
        ) {
            A3API.SendAlert(
                JSON.stringify({
                    event,
                    data,
                }),
            );
            return true;
        }

        return false;
    }

    function getMockPayload() {
        const OrgPortal = window.OrgPortal;
        return {
            session: JSON.parse(JSON.stringify(OrgPortal.data.session)),
            portalData: JSON.parse(JSON.stringify(OrgPortal.data.portalData)),
        };
    }

    function requestLogin(credentials) {
        store.startLogin();

        const sent = sendEvent("org::login::request", credentials);
        if (sent) {
            return;
        }

        window.setTimeout(() => {
            store.completeLogin(getMockPayload());
        }, 350);
    }

    function requestCreateOrg(registration) {
        store.startCreate();

        const sent = sendEvent("org::create::request", registration);
        if (sent) {
            return;
        }

        window.setTimeout(() => {
            const orgName = String(registration.orgName || "").trim();
            if (!orgName) {
                store.failCreate("Enter an organization name.");
                return;
            }

            const payload = getMockPayload();
            payload.portalData.org.name = orgName;
            payload.portalData.org.tag = String(Date.now()).slice(-10);
            payload.portalData.org.owner =
                payload.session.actorName || "Unknown";
            payload.portalData.org.ownerUid = payload.session.actorUid || "";
            payload.portalData.org.isDefault = false;
            payload.session.role = "Leader";
            payload.session.ceo = false;
            payload.portalData.members = [
                { name: payload.session.actorName || "Unknown" },
            ];

            store.completeCreate(payload);
        }, 350);
    }

    function receive(eventOrPayload, data = {}) {
        const event =
            typeof eventOrPayload === "object" && eventOrPayload !== null
                ? eventOrPayload.event
                : eventOrPayload;
        const payloadData =
            typeof eventOrPayload === "object" && eventOrPayload !== null
                ? eventOrPayload.data || {}
                : data;

        if (event === "org::login::success") {
            store.completeLogin(payloadData);
            return;
        }

        if (event === "org::login::failure") {
            store.failLogin(payloadData.message || "Authentication failed.");
            return;
        }

        if (event === "org::create::success") {
            store.completeCreate(payloadData);
            return;
        }

        if (event === "org::create::failure") {
            store.failCreate(
                payloadData.message || "Organization registration failed.",
            );
        }
    }

    RegistryApp.bridge = {
        requestLogin,
        requestCreateOrg,
        receive,
        sendEvent,
    };

    window.OrgUIBridge = {
        requestLogin,
        requestCreateOrg,
        receive,
        receiveLoginSuccess: (data) => receive("org::login::success", data),
        receiveLoginFailure: (data) => receive("org::login::failure", data),
        receiveCreateSuccess: (data) => receive("org::create::success", data),
        receiveCreateFailure: (data) => receive("org::create::failure", data),
    };
})();
