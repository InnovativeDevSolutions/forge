(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { createSignal } = window.RegistryApp.runtime;
    const { portalData } = OrgPortal.data;

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

    class OrgPortalStore {
        constructor() {
            [this.getFunds, this.setFunds] = createSignal(portalData.funds);
            [this.getReputation, this.setReputation] = createSignal(
                portalData.reputation,
            );
            [this.getMembers, this.setMembers] = createSignal([
                ...portalData.members,
            ]);
            [this.getPendingInvites, this.setPendingInvites] = createSignal([
                ...portalData.pendingInvites,
            ]);
            [this.getInviteablePlayers, this.setInviteablePlayers] =
                createSignal([...portalData.inviteablePlayers]);
            [this.getCreditLines, this.setCreditLines] = createSignal([
                ...portalData.creditLines,
            ]);
            [this.getFleet, this.setFleet] = createSignal([
                ...portalData.fleet,
            ]);
            [this.getAssets, this.setAssets] = createSignal([
                ...portalData.assets,
            ]);
            [this.getActivity, this.setActivity] = createSignal([
                ...portalData.activity,
            ]);
            [this.getTreasuryNotice, this.setTreasuryNotice] = createSignal({
                type: "",
                text: "",
            });
            [this.getModal, this.setModal] = createSignal(null);
            [this.getInviteMenuOpen, this.setInviteMenuOpen] =
                createSignal(false);
            [this.getOrgDisbanded, this.setOrgDisbanded] = createSignal(false);
        }

        hydrateFromPayload(payload) {
            const nextPortalData = payload.portalData || {};

            this.setFunds(nextPortalData.funds || 0);
            this.setReputation(nextPortalData.reputation || 0);
            this.setMembers([...normalizeCollection(nextPortalData.members)]);
            this.setPendingInvites([
                ...normalizeCollection(nextPortalData.pendingInvites),
            ]);
            this.setInviteablePlayers([
                ...normalizeCollection(nextPortalData.inviteablePlayers),
            ]);
            this.setCreditLines([
                ...normalizeCollection(nextPortalData.creditLines),
            ]);
            this.setFleet([...normalizeCollection(nextPortalData.fleet)]);
            this.setAssets([...normalizeCollection(nextPortalData.assets)]);
            this.setActivity([...normalizeCollection(nextPortalData.activity)]);
        }
    }

    OrgPortal.store = new OrgPortalStore();
})();
