/** @format */

/**
 * @class Modal
 * @extends Component
 * @description A reusable modal dialog component.
 * Provides an overlay with a modal dialog box containing customizable content and actions.
 * Supports keyboard interaction and click-outside-to-close behavior.
 */
class Modal extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {boolean} props.show - Whether the modal is visible
     * @param {string} [props.title='Modal'] - Title of the modal
     * @param {Array|Object} [props.children=[]] - Content to display in the modal
     * @param {Function} [props.onClose] - Callback when modal is closed
     * @param {Function} [props.onConfirm] - Callback when confirm button is clicked
     */
    constructor(props) {
        super(props);

        // Bind event handlers
        this.handleOverlayClick = this.handleOverlayClick.bind(this);
        this.handleModalClick = this.handleModalClick.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    /**
     * Handle click events on the overlay
     * @param {Event} e - Click event object
     * @private
     */
    handleOverlayClick(e) {
        if (e.target === e.currentTarget && this.props.onClose) {
            this.props.onClose();
        }
    }

    /**
     * Prevent click events from bubbling through the modal
     * @param {Event} e - Click event object
     * @private
     */
    handleModalClick(e) {
        e.stopPropagation();
    }

    /**
     * Handle keyboard events for accessibility
     * @param {KeyboardEvent} e - Keyboard event object
     * @private
     */
    handleKeyDown(e) {
        if (e.key === 'Escape' && this.props.onClose) {
            this.props.onClose();
        }
    }

    /**
     * Render the modal actions (buttons)
     * @param {Function} onClose - Close callback
     * @param {Function} onConfirm - Confirm callback
     * @param {string} confirmText - Text for confirm button
     * @param {string} cancelText - Text for cancel button
     * @returns {HTMLElement} The rendered actions element
     * @private
     */
    renderActions(onClose, onConfirm, confirmText = 'Call', cancelText = 'Cancel', extraActions = [], hideCancel = false, hideConfirm = false) {
        if (hideCancel && hideConfirm && !extraActions.length) {
            return null;
        }

        return this.createElement(
            'div',
            { className: 'modal-actions' },
            hideCancel ? null : this.createElement(
                'button',
                {
                    className: 'button secondary',
                    onClick: () => onClose?.(),
                    type: 'button',
                    'aria-label': cancelText,
                },
                cancelText
            ),
            ...extraActions.map((action) => this.createElement(
                'button',
                {
                    className: action.className || 'button secondary',
                    onClick: () => action.onClick?.(),
                    type: 'button',
                    disabled: action.disabled === true,
                    'aria-label': action.ariaLabel || action.text,
                },
                action.text
            )),
            hideConfirm ? null : this.createElement(
                'button',
                {
                    className: 'button',
                    onClick: () => onConfirm?.(),
                    type: 'button',
                    'aria-label': confirmText,
                },
                confirmText
            )
        );
    }

    /**
     * Render the modal
     * @returns {HTMLElement} The rendered modal element
     */
    render() {
        const { show, title, children = [], onClose, onConfirm, confirmText, cancelText, extraActions = [], hideCancel = false, hideConfirm = false } = this.props;

        if (!show) {
            return this.createElement('div', {
                className: 'hidden',
                style: { display: 'none' },
                'aria-hidden': 'true',
            });
        }

        // Ensure children is always an array
        const childElements = Array.isArray(children) ? children : [children];

        return this.createElement(
            'div',
            {
                className: 'modal-overlay',
                onClick: this.handleOverlayClick,
                onKeyDown: this.handleKeyDown,
                role: 'dialog',
                'aria-modal': 'true',
                'aria-labelledby': 'modal-title',
            },
            this.createElement(
                'div',
                {
                    className: 'modal',
                    onClick: this.handleModalClick,
                    role: 'document',
                    tabIndex: -1,
                },
                this.createElement(
                    'h2',
                    {
                        id: 'modal-title',
                        role: 'heading',
                        'aria-level': '2',
                    },
                    title || 'Modal'
                ),
                this.createElement(
                    'div',
                    {
                        className: 'modal-content',
                        role: 'region',
                        'aria-label': 'Modal content',
                    },
                    ...childElements.filter((child) => child != null)
                ),
                this.renderActions(onClose, onConfirm, confirmText, cancelText, extraActions, hideCancel, hideConfirm)
            )
        );
    }
}
