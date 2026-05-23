(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { h } = BankApp.runtime;
    const WindowTitleBar = window.SharedUI.componentFns.WindowTitleBar;
    const store = BankApp.store;
    const actions = BankApp.actions;

    BankApp.componentFns = BankApp.componentFns || {};
    BankApp.componentFns.NoticeLayer = function NoticeLayer() {
        const notice = store.getNotice();

        if (!notice.text) {
            return null;
        }

        return h(
            "div",
            { className: "bank-notice-stack" },
            h(
                "div",
                {
                    className:
                        notice.type === "error"
                            ? "bank-notice is-error"
                            : "bank-notice is-success",
                },
                notice.text,
            ),
        );
    };

    BankApp.components = BankApp.components || {};
    BankApp.components.App = function App() {
        const mode = store.getMode();

        return h(
            "div",
            { className: mode === "atm" ? "bank-shell is-atm" : "bank-shell" },
            mode === "atm"
                ? null
                : WindowTitleBar({
                      kicker: "FORGE Finance",
                      title: "Global Banking Network",
                      onClose: () => actions.closeBank(),
                      closeLabel: "Close banking interface",
                  }),
            h("div", { id: "bank-notice-root" }),
            mode === "atm"
                ? h("div", { id: "bank-atm-root" })
                : [
                      h(
                          "div",
                          {
                              className: "bank-scroll-shell",
                              "data-preserve-scroll-id": "bank-page-scroll",
                          },
                          [
                              h(
                                  "div",
                                  { className: "bank-layout" },
                                  h("div", { id: "bank-sidebar-root" }),
                                  h(
                                      "main",
                                      { className: "bank-main" },
                                      h(
                                          "div",
                                          { className: "bank-page" },
                                          h("div", {
                                              id: "bank-page-header-root",
                                          }),
                                          h(
                                              "p",
                                              { className: "bank-page-copy" },
                                              "Manage deposits, withdrawals, transfers, and earnings sweeps from the same shared financial console.",
                                          ),
                                          h("div", {
                                              className: "bank-page-divider",
                                          }),
                                          h(
                                              "div",
                                              { className: "bank-page-body" },
                                              h("div", {
                                                  id: "bank-summary-section-root",
                                              }),
                                              h("div", {
                                                  id: "bank-action-sections-root",
                                              }),
                                              h("div", {
                                                  id: "bank-support-section-root",
                                              }),
                                              h("div", {
                                                  id: "bank-history-section-root",
                                              }),
                                          ),
                                      ),
                                  ),
                              ),
                              h("div", { id: "bank-footer-root" }),
                          ],
                      ),
                  ],
        );
    };
})();
