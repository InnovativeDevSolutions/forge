/** @format */

let lastMobileBankRequest = 0;
let mobileBankNoticeTimer = null;
const MOBILE_BANK_REQUEST_COOLDOWN = 1000;

function defaultMobileBankState() {
    return {
        account: {
            bank: 0,
            cash: 0,
            earnings: 0,
            transactions: [],
        },
        session: {
            creditLine: {
                amountDue: 0,
                approvedAmount: 0,
                availableAmount: 0,
                outstandingPrincipal: 0,
            },
            orgName: '',
            playerName: '',
            transferTargets: [],
            uid: '',
        },
        notice: null,
        pendingAction: '',
    };
}

function getMobileBankState() {
    return {
        ...defaultMobileBankState(),
        ...(globalState.getState().mobileBank || {}),
    };
}

function setMobileBankState(patch) {
    globalState.setState({
        mobileBank: {
            ...getMobileBankState(),
            ...patch,
        },
    });
}

function formatMobileBankCurrency(value) {
    const amount = Math.floor(Number(value || 0));
    return `$${Math.max(0, amount).toLocaleString()}`;
}

function normalizeMobileBankAmount(value) {
    const amount = Math.floor(Number(value || 0));
    return Number.isFinite(amount) ? amount : 0;
}

function sendMobileBankEvent(event, data = {}) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        A3API.SendAlert(JSON.stringify({ event, data }));
        return true;
    }

    showMobileBankNotice('error', 'Bank bridge is unavailable.');
    return false;
}

function requestMobileBankRefresh(force = false) {
    const now = Date.now();
    if (!force && now - lastMobileBankRequest < MOBILE_BANK_REQUEST_COOLDOWN) {
        return false;
    }

    lastMobileBankRequest = now;
    return sendMobileBankEvent('phone::bank::refresh', {});
}

function requestMobileBankTransfer(target, amountValue) {
    const targetUid = String(target || '').trim();
    const amount = normalizeMobileBankAmount(amountValue);

    if (!targetUid) {
        showMobileBankNotice('error', 'Choose a recipient.');
        return false;
    }

    if (amount <= 0) {
        showMobileBankNotice('error', 'Enter a valid transfer amount.');
        return false;
    }

    setMobileBankState({ pendingAction: 'transfer' });
    const sent = sendMobileBankEvent('phone::bank::transfer::request', {
        amount,
        from: 'bank',
        target: targetUid,
    });

    if (!sent) {
        setMobileBankState({ pendingAction: '' });
    }

    return sent;
}

function requestMobileBankDepositEarnings() {
    const state = getMobileBankState();
    const availableEarnings = normalizeMobileBankAmount(state.account.earnings);

    if (availableEarnings <= 0) {
        showMobileBankNotice('error', 'No earnings are available to deposit.');
        return false;
    }

    setMobileBankState({ pendingAction: 'depositearnings' });
    const sent = sendMobileBankEvent('phone::bank::depositEarnings::request', {
        amount: availableEarnings,
    });

    if (!sent) {
        setMobileBankState({ pendingAction: '' });
    }

    return sent;
}

function requestMobileBankRepayCreditLine(amountValue) {
    const amount = normalizeMobileBankAmount(amountValue);
    const state = getMobileBankState();
    const amountDue = normalizeMobileBankAmount(state.session.creditLine?.amountDue);

    if (amountDue <= 0) {
        showMobileBankNotice('error', 'No credit line payment is due.');
        return false;
    }

    if (amount <= 0) {
        showMobileBankNotice('error', 'Enter a valid payment amount.');
        return false;
    }

    setMobileBankState({ pendingAction: 'repaycreditline' });
    const sent = sendMobileBankEvent('phone::bank::repayCreditLine::request', {
        amount: Math.min(amount, amountDue),
    });

    if (!sent) {
        setMobileBankState({ pendingAction: '' });
    }

    return sent;
}

function updateMobileBank(payload) {
    const current = getMobileBankState();
    setMobileBankState({
        account: {
            ...current.account,
            ...(payload && payload.account ? payload.account : {}),
        },
        session: {
            ...current.session,
            ...(payload && payload.session ? payload.session : {}),
        },
        pendingAction: '',
    });
}

function updateMobileBankAccount(accountPatch) {
    const current = getMobileBankState();
    setMobileBankState({
        account: {
            ...current.account,
            ...(accountPatch || {}),
        },
        pendingAction: '',
    });
}

function showMobileBankNotice(type, message) {
    if (!message) return;

    setMobileBankState({
        notice: {
            type: type || 'info',
            message,
        },
        pendingAction: '',
    });

    if (mobileBankNoticeTimer) {
        clearTimeout(mobileBankNoticeTimer);
    }

    mobileBankNoticeTimer = setTimeout(() => {
        setMobileBankState({ notice: null });
        mobileBankNoticeTimer = null;
    }, 3200);
}

function mobileBankTransactionRows(transactions) {
    const rows = Array.isArray(transactions) ? transactions.slice(0, 5) : [];

    if (rows.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'wallet-empty-state';
        empty.textContent = 'No recent transactions';
        return empty;
    }

    const list = document.createElement('div');
    list.className = 'wallet-transaction-list';

    rows.forEach((entry) => {
        const row = document.createElement('div');
        row.className = 'wallet-transaction-row';

        const copy = document.createElement('div');
        copy.className = 'wallet-transaction-copy';

        const title = document.createElement('span');
        title.className = 'wallet-transaction-title';
        title.textContent = entry.type || 'Transaction';

        const meta = document.createElement('span');
        meta.className = 'wallet-transaction-meta';
        meta.textContent = entry.date || 'Pending timestamp';

        const value = document.createElement('span');
        value.className = 'wallet-transaction-value';
        value.textContent = formatMobileBankCurrency(entry.amount || 0);

        copy.append(title, meta);
        row.append(copy, value);
        list.appendChild(row);
    });

    return list;
}

function initializeMobileBankApp(container) {
    const state = getMobileBankState();
    const { account, session, notice, pendingAction } = state;
    const transferTargets = Array.isArray(session.transferTargets)
        ? session.transferTargets
        : [];
    const creditLine = session.creditLine || {};
    const amountDue = normalizeMobileBankAmount(creditLine.amountDue);
    const outstandingPrincipal = normalizeMobileBankAmount(creditLine.outstandingPrincipal);

    requestMobileBankRefresh(false);

    const appContainer = document.createElement('div');
    appContainer.className = 'app-container wallet-app';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Wallet');

    const navBar = new NavigationBar({
        title: 'Wallet',
        rightButton: {
            element: 'button',
            props: {
                className: 'wallet-nav-button',
                type: 'button',
                disabled: pendingAction !== '',
                onClick: () => requestMobileBankRefresh(true),
                'aria-label': 'Refresh wallet',
            },
            content: 'Refresh',
        },
    });
    navBar.mount(appContainer);

    const content = document.createElement('div');
    content.className = 'content wallet-content';

    if (notice && notice.message) {
        const noticeElement = document.createElement('div');
        noticeElement.className = `wallet-notice wallet-notice-${notice.type || 'info'}`;
        noticeElement.textContent = notice.message;
        content.appendChild(noticeElement);
    }

    const hero = document.createElement('section');
    hero.className = 'wallet-balance-card';
    hero.innerHTML = `
        <span class="wallet-eyebrow">Available Balance</span>
        <strong class="wallet-balance">${formatMobileBankCurrency(account.bank)}</strong>
        <span class="wallet-owner">${session.playerName || 'Personal account'}</span>
    `;
    content.appendChild(hero);

    const metrics = document.createElement('section');
    metrics.className = 'wallet-metrics';
    metrics.innerHTML = `
        <div class="wallet-metric">
            <span>Cash</span>
            <strong>${formatMobileBankCurrency(account.cash)}</strong>
        </div>
        <div class="wallet-metric">
            <span>Earnings</span>
            <strong>${formatMobileBankCurrency(account.earnings)}</strong>
        </div>
    `;
    content.appendChild(metrics);

    const bankingActions = document.createElement('section');
    bankingActions.className = 'wallet-card';

    const bankingTitle = document.createElement('div');
    bankingTitle.className = 'wallet-card-title';
    bankingTitle.textContent = 'Account Actions';

    const earningsAction = document.createElement('div');
    earningsAction.className = 'wallet-action-block';

    const earningsSummary = document.createElement('div');
    earningsSummary.className = 'wallet-action-summary';
    earningsSummary.innerHTML = `
        <span>Deposit Earnings</span>
        <strong>${formatMobileBankCurrency(account.earnings)} available</strong>
        <small>Move mission earnings into your bank balance.</small>
    `;

    const earningsButton = document.createElement('button');
    earningsButton.className = 'wallet-secondary-button wallet-full-button';
    earningsButton.type = 'button';
    earningsButton.disabled = pendingAction !== '' || normalizeMobileBankAmount(account.earnings) <= 0;
    earningsButton.textContent = pendingAction === 'depositearnings' ? 'Depositing...' : 'Deposit Earnings';
    earningsButton.addEventListener('click', () => {
        requestMobileBankDepositEarnings();
    });
    earningsAction.append(earningsSummary, earningsButton);

    const creditAction = document.createElement('div');
    creditAction.className = 'wallet-action-block';

    const creditSummary = document.createElement('div');
    creditSummary.className = 'wallet-action-summary';
    creditSummary.innerHTML = `
        <span>Credit Line Payment</span>
        <strong>${formatMobileBankCurrency(amountDue)} due</strong>
        <small>${session.orgName || 'Organization'} - ${formatMobileBankCurrency(outstandingPrincipal)} outstanding</small>
    `;

    const creditControls = document.createElement('div');
    creditControls.className = 'wallet-action-controls';

    const creditAmount = document.createElement('input');
    creditAmount.className = 'wallet-input';
    creditAmount.type = 'number';
    creditAmount.min = '1';
    creditAmount.step = '1';
    creditAmount.placeholder = amountDue > 0 ? 'Payment amount' : 'No payment due';
    creditAmount.setAttribute('aria-label', 'Credit line payment amount');
    creditAmount.inputMode = 'numeric';
    creditAmount.disabled = pendingAction !== '' || amountDue <= 0;

    const creditButton = document.createElement('button');
    creditButton.className = 'wallet-secondary-button';
    creditButton.type = 'button';
    creditButton.disabled = pendingAction !== '' || amountDue <= 0;
    creditButton.textContent = pendingAction === 'repaycreditline' ? 'Paying...' : 'Pay Credit';
    creditButton.addEventListener('click', () => {
        requestMobileBankRepayCreditLine(creditAmount.value || amountDue);
    });

    creditControls.append(creditAmount, creditButton);
    creditAction.append(creditSummary, creditControls);
    bankingActions.append(bankingTitle, earningsAction, creditAction);
    content.appendChild(bankingActions);

    const transferCard = document.createElement('section');
    transferCard.className = 'wallet-card';

    const transferTitle = document.createElement('div');
    transferTitle.className = 'wallet-card-title';
    transferTitle.textContent = 'Transfer';

    const targetSelect = document.createElement('select');
    targetSelect.className = 'wallet-input';
    targetSelect.setAttribute('aria-label', 'Transfer recipient');
    targetSelect.disabled = pendingAction !== '' || transferTargets.length === 0;

    const placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = transferTargets.length === 0 ? 'No online recipients' : 'Choose recipient';
    targetSelect.appendChild(placeholder);

    transferTargets.forEach((target) => {
        const option = document.createElement('option');
        option.value = target.uid || '';
        option.textContent = target.name || target.uid || 'Player';
        targetSelect.appendChild(option);
    });

    const amountInput = document.createElement('input');
    amountInput.className = 'wallet-input';
    amountInput.type = 'number';
    amountInput.min = '1';
    amountInput.step = '1';
    amountInput.placeholder = 'Amount';
    amountInput.inputMode = 'numeric';
    amountInput.disabled = pendingAction !== '';

    const transferButton = document.createElement('button');
    transferButton.className = 'wallet-primary-button';
    transferButton.type = 'button';
    transferButton.disabled = pendingAction !== '' || transferTargets.length === 0;
    transferButton.textContent = pendingAction === 'transfer' ? 'Sending...' : 'Send Transfer';
    transferButton.addEventListener('click', () => {
        requestMobileBankTransfer(targetSelect.value, amountInput.value);
    });

    transferCard.append(transferTitle, targetSelect, amountInput, transferButton);
    content.appendChild(transferCard);

    const historyCard = document.createElement('section');
    historyCard.className = 'wallet-card';

    const historyTitle = document.createElement('div');
    historyTitle.className = 'wallet-card-title';
    historyTitle.textContent = 'Recent Activity';

    historyCard.append(historyTitle, mobileBankTransactionRows(account.transactions));
    content.appendChild(historyCard);

    appContainer.appendChild(content);
    container.appendChild(appContainer);
}

window.initializeMobileBankApp = initializeMobileBankApp;
window.requestMobileBankRefresh = requestMobileBankRefresh;
window.updateMobileBank = updateMobileBank;
window.updateMobileBankAccount = updateMobileBankAccount;
window.showMobileBankNotice = showMobileBankNotice;
