(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { portalData, session } = OrgPortal.data;

    class OrgPortalGetters {
        formatCurrency(value) {
            return "$" + Number(value || 0).toLocaleString();
        }

        formatVehicleType(type) {
            if (!type) {
                return "";
            }

            return type.charAt(0).toUpperCase() + type.slice(1);
        }

        formatAssetType(type) {
            if (!type) {
                return "";
            }

            return type.charAt(0).toUpperCase() + type.slice(1);
        }

        formatDisplayName(value) {
            if (!value) {
                return "";
            }

            return String(value)
                .trim()
                .split(/\s+/)
                .map((part) => {
                    if (!part) {
                        return "";
                    }

                    return (
                        part.charAt(0).toUpperCase() +
                        part.slice(1).toLowerCase()
                    );
                })
                .join(" ");
        }

        getAssetReadiness() {
            const fleet = OrgPortal.store
                ? OrgPortal.store.getFleet()
                : portalData.fleet;
            if (fleet.length === 0) {
                return null;
            }

            const total = fleet.reduce(
                (sum, unit) => sum + (100 - parseInt(unit.damage, 10)),
                0,
            );
            return Math.round(total / fleet.length);
        }

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
            return this.isOrgOwner() && !this.isDefaultOrg();
        }

        canLeaveOrg() {
            return !this.isDefaultOrg() && !this.isOrgOwner();
        }

        getMemberName(member) {
            if (member && typeof member === "object") {
                return String(member.name || "");
            }

            return String(member || "");
        }

        getMemberUid(member) {
            if (member && typeof member === "object") {
                return String(member.uid || "");
            }

            return "";
        }

        isOwnerMember(member) {
            return (
                this.getMemberName(member).trim().toLowerCase() ===
                String(portalData.org.owner || "")
                    .trim()
                    .toLowerCase()
            );
        }

        isCurrentMember(member) {
            const memberUid = this.getMemberUid(member).trim().toLowerCase();
            const actorUid = String(session.actorUid || "")
                .trim()
                .toLowerCase();

            if (memberUid && actorUid) {
                return memberUid === actorUid;
            }

            return (
                this.getMemberName(member).trim().toLowerCase() ===
                String(session.actorName || "")
                    .trim()
                    .toLowerCase()
            );
        }

        isProtectedMember(member) {
            return this.isOwnerMember(member) || this.isCurrentMember(member);
        }
    }

    OrgPortal.getters = new OrgPortalGetters();
})();
