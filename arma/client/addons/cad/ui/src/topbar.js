window.cadTopbar = {
    mode: "operations",
    dispatchView: "board",
    currentGroup: null,
    session: {},
    init() {
        document.getElementById("btnClose").addEventListener("click", () => {
            window.mapUI.sendEvent("map::close", null);
        });

        document
            .getElementById("modeToggle")
            .addEventListener("change", (event) => {
                window.mapUI.sendEvent("cad::mode::set", {
                    mode: event.target.checked ? "dispatch" : "operations",
                });
            });

        document
            .getElementById("dispatchRefreshBtn")
            .addEventListener("click", () => {
                window.mapUI.sendEvent("cad::refresh", {});
            });

        document
            .getElementById("dispatchBoardBtn")
            .addEventListener("click", () => {
                window.mapUI.sendEvent("cad::dispatchView::set", {
                    dispatchView: "board",
                });
            });

        document
            .getElementById("dispatchMapBtn")
            .addEventListener("click", () => {
                window.mapUI.sendEvent("cad::dispatchView::set", {
                    dispatchView: "map",
                });
            });

        document
            .getElementById("operatorRoleBtn")
            .addEventListener("click", () => {
                if (!this.currentGroup) {
                    return;
                }

                window.mapUI.sendEvent("cad::groups::role", {
                    groupID: this.currentGroup.groupId || "",
                    role: document.getElementById("operatorRoleSelect").value,
                });
            });

        document
            .getElementById("operatorStatusBtn")
            .addEventListener("click", () => {
                if (!this.currentGroup) {
                    return;
                }

                window.mapUI.sendEvent("cad::groups::status", {
                    groupID: this.currentGroup.groupId || "",
                    status: document.getElementById("operatorStatusSelect")
                        .value,
                });
            });

        window.mapUI.sendEvent("cad::topbar::ready", {});
    },
    formatLocation(group) {
        const position = Array.isArray(group?.position)
            ? group.position
            : [0, 0, 0];
        return window.mapUI.formatPosition(position);
    },
    receiveState(payload) {
        this.session =
            payload && payload.session && typeof payload.session === "object"
                ? payload.session
                : {};
        this.mode =
            payload && typeof payload.mode === "string"
                ? payload.mode
                : "operations";
        this.dispatchView =
            payload && typeof payload.dispatchView === "string"
                ? payload.dispatchView
                : "board";
        this.currentGroup =
            payload &&
            payload.currentGroup &&
            typeof payload.currentGroup === "object"
                ? payload.currentGroup
                : null;

        const modeControls = document.getElementById("modeControls");
        const canDispatch = !!this.session.isDispatcher;
        const canOperateGroup =
            !!this.currentGroup &&
            (!!this.session.isLeader || !!this.session.isDispatcher);
        const operatorStrip = document.getElementById("operatorStrip");
        const operatorControls = document.getElementById("operatorControls");
        const dispatchViewControls = document.getElementById(
            "dispatchViewControls",
        );
        const dispatchRefreshBtn =
            document.getElementById("dispatchRefreshBtn");
        const dispatchBoardBtn = document.getElementById("dispatchBoardBtn");
        const dispatchMapBtn = document.getElementById("dispatchMapBtn");

        modeControls.classList.toggle("is-hidden", !canDispatch);
        dispatchViewControls.classList.toggle(
            "is-hidden",
            !canDispatch || this.mode !== "dispatch",
        );
        operatorStrip.classList.toggle(
            "is-hidden",
            this.mode !== "operations" || !this.currentGroup,
        );
        operatorControls.classList.toggle("is-hidden", !canOperateGroup);

        document.body.dataset.mode = this.mode;
        document.body.dataset.dispatcher = canDispatch ? "true" : "false";

        document.getElementById("modeToggle").checked =
            this.mode === "dispatch";
        dispatchBoardBtn.classList.toggle(
            "is-active",
            this.dispatchView === "board",
        );
        dispatchMapBtn.classList.toggle(
            "is-active",
            this.dispatchView === "map",
        );
        dispatchRefreshBtn.title =
            this.mode === "dispatch" ? "Refresh dispatch board" : "Refresh CAD";
        dispatchRefreshBtn.setAttribute(
            "aria-label",
            this.mode === "dispatch" ? "Refresh dispatch board" : "Refresh CAD",
        );

        document.getElementById("operatorGroupName").textContent = this
            .currentGroup
            ? this.currentGroup.callsign ||
              this.currentGroup.groupId ||
              "Current Group"
            : "No Group";
        document.getElementById("operatorLocation").textContent = this
            .currentGroup
            ? this.formatLocation(this.currentGroup)
            : "Unavailable";

        if (this.currentGroup) {
            document.getElementById("operatorRoleSelect").value =
                this.currentGroup.role || "infantry";
            document.getElementById("operatorStatusSelect").value =
                this.currentGroup.status || "available";
        }
    },
};

window.cadTopbar.init();
