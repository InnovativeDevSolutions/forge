(function () {
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    SharedLogic.createPortalStore = function createPortalStore({
        createSignal,
        portalData,
    }) {
        class OrgPortalStore {
            constructor() {
                [this.getFunds, this.setFunds] = createSignal(portalData.funds);
                [this.getMembers, this.setMembers] = createSignal([
                    ...portalData.members,
                ]);
                [this.getCreditLines, this.setCreditLines] = createSignal([]);
                [this.getTreasuryNotice, this.setTreasuryNotice] = createSignal(
                    {
                        type: "",
                        text: "",
                    },
                );
                [this.getModal, this.setModal] = createSignal(null);
                [this.getOrgDisbanded, this.setOrgDisbanded] =
                    createSignal(false);
            }

            hydrateFromPayload(payload) {
                this.setFunds(payload.portalData.funds || 0);
                this.setMembers([...(payload.portalData.members || [])]);
                this.setCreditLines([]);
                this.setTreasuryNotice({ type: "", text: "" });
                this.setModal(null);
                this.setOrgDisbanded(false);
            }
        }

        return new OrgPortalStore();
    };
})();
