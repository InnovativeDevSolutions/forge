/**
 * Shared JavaScript for Map UI
 * Provides common utilities and state management across all UI components
 */

window.mapUIState = {
    layersPanelVisible: true,
    sidePanelElement: null,
};

window.mapUI = {
    formatGridCoordinate(value) {
        return Math.round(Number(value) || 0)
            .toString()
            .padStart(4, "0");
    },
    formatPosition(position) {
        const safePosition = Array.isArray(position) ? position : [0, 0, 0];
        return `X: ${this.formatGridCoordinate(safePosition[0])} Y: ${this.formatGridCoordinate(safePosition[1])}`;
    },
    sendEvent(event, data) {
        A3API.SendAlert(JSON.stringify({ event: event, data: data }));
    },
    updateCoordinates(x, y) {
        const coordDisplay = document.getElementById("coordsDisplay");
        if (coordDisplay) {
            coordDisplay.textContent = this.formatPosition([x, y, 0]);
        }
    },
    updateScale(scale) {
        const scaleDisplay = document.getElementById("scaleDisplay");
        if (scaleDisplay) {
            scaleDisplay.textContent = `Scale: 1:${Math.round(scale)}`;
        }
    },
    updateStatus(text) {
        const statusText = document.getElementById("statusText");
        if (statusText) {
            statusText.textContent = text;
        }
    },
};

window.updateCoordinates = window.mapUI.updateCoordinates;
window.updateScale = window.mapUI.updateScale;
window.updateStatus = window.mapUI.updateStatus;

window.ForgeBridge = window.ForgeBridge || {
    _handlers: {},
    on(event, handler) {
        this._handlers[event] = this._handlers[event] || [];
        this._handlers[event].push(handler);
    },
    ready(payload) {
        window.mapUI.sendEvent("cad::ready", payload || {});
        return true;
    },
    receive(payload) {
        if (!payload || typeof payload !== "object") {
            return;
        }

        const handlers = this._handlers[payload.event] || [];
        handlers.forEach((handler) => handler(payload.data || {}));
    },
    send(event, data) {
        window.mapUI.sendEvent(event, data || {});
        return true;
    },
    close(data) {
        window.mapUI.sendEvent("map::close", data || {});
        return true;
    },
};
