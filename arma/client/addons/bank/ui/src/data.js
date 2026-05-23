(function () {
    const BankApp = (window.BankApp = window.BankApp || {});

    const defaultSession = {
        atmAuthorized: false,
        creditLine: {
            amountDue: 0,
            approvedAmount: 0,
            availableAmount: 0,
            interestRate: 0.1,
            outstandingPrincipal: 0,
        },
        mode: "bank",
        orgFunds: 0,
        orgName: "",
        playerName: "",
        transferTargets: [],
        uid: "",
    };

    const defaultAccount = {
        bank: 0,
        cash: 0,
        earnings: 0,
        transactions: [],
    };

    function cloneValue(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function replaceObject(target, source) {
        Object.keys(target).forEach((key) => delete target[key]);
        Object.assign(target, cloneValue(source));
    }

    BankApp.data = {
        account: Object.assign({}, defaultAccount),
        session: Object.assign({}, defaultSession),
        applyAccountPatch(patch) {
            const nextAccount = Object.assign({}, this.account, patch || {});
            replaceObject(
                this.account,
                Object.assign({}, defaultAccount, nextAccount),
            );
        },
        applyHydratePayload(payload) {
            replaceObject(
                this.session,
                Object.assign({}, defaultSession, payload?.session || {}),
            );
            replaceObject(
                this.account,
                Object.assign({}, defaultAccount, payload?.account || {}),
            );
        },
    };
})();
