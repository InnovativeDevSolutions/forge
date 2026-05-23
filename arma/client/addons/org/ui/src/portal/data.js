(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const staticOrgProfile = {
        type: "Organization",
        status: "Operational",
        headquarters: "ArmA Verse",
    };

    function cloneValue(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function replaceObject(target, source) {
        Object.keys(target).forEach((key) => delete target[key]);
        Object.assign(target, cloneValue(source));
    }

    function replaceArray(target, source) {
        target.splice(0, target.length, ...cloneValue(source));
    }

    function normalizeRecord(value) {
        if (value && typeof value === "object" && !Array.isArray(value)) {
            return value;
        }

        if (Array.isArray(value)) {
            const isEntryArray = value.every(
                (entry) =>
                    Array.isArray(entry) &&
                    entry.length >= 2 &&
                    typeof entry[0] === "string",
            );

            if (isEntryArray) {
                return Object.fromEntries(value);
            }
        }

        if (typeof value === "string" && value.trim() !== "") {
            try {
                return normalizeRecord(JSON.parse(value));
            } catch (_error) {
                return value;
            }
        }

        return value;
    }

    function normalizeCollection(value) {
        const source = Array.isArray(value)
            ? value
            : value && typeof value === "object"
              ? Object.values(value)
              : [];

        return source.map(normalizeRecord).filter(Boolean);
    }

    OrgPortal.data = {
        portalData: {
            org: Object.assign(
                {
                    name: "",
                    tag: "",
                    owner: "",
                    ownerUid: "",
                    isDefault: false,
                },
                staticOrgProfile,
            ),
            funds: 0,
            reputation: 0,
            creditLines: [],
            members: [],
            pendingInvites: [],
            inviteablePlayers: [],
            fleet: [],
            assets: [],
            activity: [],
            roadmap: [
                {
                    name: "Contracts Board",
                    status: "Planned",
                    detail: "Track payouts, assignments, and claim approvals.",
                },
                {
                    name: "Diplomacy",
                    status: "Future Review",
                    detail: "Possible future module pending a full design and scope review.",
                },
                {
                    name: "Logistics Queue",
                    status: "Future Review",
                    detail: "Possible future module pending a full design and scope review.",
                },
                {
                    name: "Permissions",
                    status: "Future Review",
                    detail: "Possible future module pending a full design and scope review.",
                },
            ],
        },
        session: {
            actorName: "",
            actorUid: "",
            role: "",
            ceo: false,
        },
        applyLoginPayload(payload) {
            replaceObject(
                this.portalData.org,
                Object.assign(
                    {},
                    payload.portalData.org || {},
                    staticOrgProfile,
                ),
            );
            this.portalData.funds = payload.portalData.funds || 0;
            this.portalData.reputation = payload.portalData.reputation || 0;
            replaceArray(
                this.portalData.creditLines,
                normalizeCollection(payload.portalData.creditLines),
            );

            replaceArray(
                this.portalData.members,
                normalizeCollection(payload.portalData.members),
            );
            replaceArray(
                this.portalData.pendingInvites,
                normalizeCollection(payload.portalData.pendingInvites),
            );
            replaceArray(
                this.portalData.inviteablePlayers,
                normalizeCollection(payload.portalData.inviteablePlayers),
            );
            replaceArray(
                this.portalData.fleet,
                normalizeCollection(payload.portalData.fleet),
            );
            replaceArray(
                this.portalData.assets,
                normalizeCollection(payload.portalData.assets),
            );
            replaceArray(
                this.portalData.activity,
                normalizeCollection(payload.portalData.activity),
            );
            replaceArray(
                this.portalData.roadmap,
                normalizeCollection(payload.portalData.roadmap),
            );

            replaceObject(this.session, payload.session || {});
        },
    };
})();
