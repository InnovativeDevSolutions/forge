(function () {
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    SharedLogic.createPortalPermissions = function createPortalPermissions({
        portalData,
        session,
    }) {
        class OrgPortalPermissions {
            getNormalizedRole() {
                return String(session.role || "")
                    .trim()
                    .toUpperCase();
            }

            isDefaultOrg() {
                return (
                    portalData.org.isDefault === true ||
                    String(portalData.org.tag || "")
                        .trim()
                        .toUpperCase() === "DEFAULT"
                );
            }

            isOrgOwner() {
                const ownerUid = String(
                    portalData.org.ownerUid || portalData.org.owner || "",
                )
                    .trim()
                    .toLowerCase();
                const actorUid = String(session.actorUid || "")
                    .trim()
                    .toLowerCase();

                if (ownerUid && actorUid) {
                    return actorUid === ownerUid;
                }

                return (
                    String(session.actorName || "")
                        .trim()
                        .toLowerCase() ===
                    String(portalData.org.owner || "")
                        .trim()
                        .toLowerCase()
                );
            }

            isSessionCeo() {
                return session.ceo === true;
            }

            isOrgLeaderOrCeo() {
                return (
                    this.isOrgOwner() ||
                    this.getNormalizedRole() === "LEADER" ||
                    (this.isDefaultOrg() && this.isSessionCeo())
                );
            }

            canManageMembers() {
                return this.isOrgLeaderOrCeo();
            }

            canManageTreasury() {
                return this.isOrgLeaderOrCeo();
            }

            canDisbandOrg() {
                return this.isOrgLeaderOrCeo();
            }
        }

        return new OrgPortalPermissions();
    };
})();
