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

    OrgPortal.data = {
        portalData: {
            org: Object.assign(
                {
                    name: "Black Rifle Company",
                    tag: "BRC-0160566824",
                    owner: "Jacob Schmidt",
                    ownerUid: "uid-jacob-schmidt",
                    isDefault: false,
                },
                staticOrgProfile,
            ),
            funds: 482750,
            reputation: 72,
            members: [
                { name: "Jacob Schmidt" },
                { name: "Mara Velez" },
                { name: "Rylan Cross" },
                { name: "Noah Briggs" },
                { name: "Elena Price" },
                { name: "Isaac Rowe" },
                { name: "Talia Boone" },
                { name: "Cade Mercer" },
            ],
            fleet: [
                {
                    name: "UH-80 Ghost Hawk",
                    type: "helicopter",
                    status: "Ready",
                    damage: "16%",
                },
                {
                    name: "MH-9 Hummingbird",
                    type: "helicopter",
                    status: "Ready",
                    damage: "8%",
                },
                {
                    name: "M-ATV Patrol 1",
                    type: "car",
                    status: "Fielded",
                    damage: "24%",
                },
                {
                    name: "M2A1 Slammer",
                    type: "armor",
                    status: "Ready",
                    damage: "11%",
                },
                {
                    name: "RHIB Patrol Boat",
                    type: "naval",
                    status: "Repairing",
                    damage: "32%",
                },
            ],
            assets: [
                { name: "First Aid Kits", type: "items", quantity: "36" },
                { name: "MX 6.5 mm Rifles", type: "weapons", quantity: "18" },
                {
                    name: "6.5 mm Magazines",
                    type: "magazines",
                    quantity: "120",
                },
                {
                    name: "Carryall Backpacks",
                    type: "backpacks",
                    quantity: "24",
                },
            ],
            activity: [
                {
                    time: "08:20",
                    text: "Treasury cleared contractor payment for northern route escort.",
                },
                {
                    time: "07:45",
                    text: "Viper Flight completed readiness checks on all rotary assets.",
                },
                {
                    time: "07:10",
                    text: "New recruit Cade Mercer accepted into ground training roster.",
                },
                {
                    time: "06:30",
                    text: "North Depot inventory count pushed reserve ratio above target.",
                },
            ],
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
            actorName: "Jacob Schmidt",
            actorUid: "uid-jacob-schmidt",
            role: "Leader",
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
                this.portalData.members,
                payload.portalData.members || [],
            );
            replaceArray(this.portalData.fleet, payload.portalData.fleet || []);
            replaceArray(
                this.portalData.assets,
                payload.portalData.assets || [],
            );
            replaceArray(
                this.portalData.activity,
                payload.portalData.activity || [],
            );
            replaceArray(
                this.portalData.roadmap,
                payload.portalData.roadmap || [],
            );

            replaceObject(this.session, payload.session || {});
        },
    };
})();
