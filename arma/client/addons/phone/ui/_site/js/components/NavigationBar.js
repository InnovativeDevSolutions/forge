/** @format */

/**
 * @class NavigationBar
 * @extends Component
 * @description A navigation bar component that provides app navigation controls.
 * Handles back navigation and displays the current screen title.
 */
class NavigationBar extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {boolean} [props.showBackButton=false] - Whether to show the back button
     * @param {string} [props.title] - Title to display in the navigation bar
     * @param {Object|HTMLElement} [props.leftButton] - Optional custom button to display on the left side (overrides back button)
     * @param {Object|HTMLElement} [props.rightButton] - Optional button to display on the right side
     */
    constructor(props) {
        super(props);
        this.handleBackClick = this.handleBackClick.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    /**
     * Handle back button click event
     * @private
     */
    handleBackClick() {
        const currentState = globalState.getState();

        // Priority 1: If we're in a conversation, go back to messages list
        if (currentState.selectedConversation) {
            globalState.setState({
                selectedConversation: null,
                selectedConversationRaw: null,
            });
            return; // Exit early, don't execute the rest
        }

        if (currentState.showMessageContactPicker) {
            globalState.setState({
                showMessageContactPicker: false,
            });
            return;
        }

        if (currentState.selectedEmail || currentState.showEmailComposer) {
            globalState.setState({
                selectedEmail: null,
                showEmailComposer: false,
            });
            return;
        }

        // Priority 2: If we came from phone app, go back to phone
        if (currentState.previousApp === 'phone') {
            globalState.setState({
                currentApp: 'phone',
                previousApp: null,
            });
            return; // Exit early
        }

        // Priority 3: Default - go to home and clear everything
        globalState.setState({
            currentApp: 'home',
            previousApp: null,
            selectedConversation: null,
            selectedConversationRaw: null,
            selectedContact: null,
            showMessageContactPicker: false,
            showModal: false,
        });
    }

    /**
     * Handle keyboard events for accessibility
     * @param {KeyboardEvent} e - Keyboard event object
     * @private
     */
    handleKeyDown(e) {
        if (e.key === 'Backspace' && this.props.showBackButton) {
            this.handleBackClick();
        }
    }

    /**
     * Render the left section (custom button, back button, or spacer)
     * @returns {HTMLElement} The rendered element
     * @private
     */
    renderLeftSection() {
        const { leftButton, showBackButton } = this.props;

        // Priority 1: Custom left button
        if (leftButton) {
            if (leftButton instanceof HTMLElement) {
                return leftButton;
            }
            
            return this.createElement(
                leftButton.element || 'button',
                leftButton.props || {},
                leftButton.content
            );
        }

        // Priority 2: Default back button
        if (showBackButton) {
            return this.createElement(
                'button',
                {
                    className: 'nav-back-button',
                    onClick: this.handleBackClick,
                    'aria-label': 'Go back',
                    type: 'button',
                },
                this.createElement('img', {
                    src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="grey" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>',
                    alt: '',
                    style: 'width:24px;height:24px;padding:0;margin:0;display:block;pointer-events:none;'
                })
            );
        }

        // Priority 3: Empty spacer
        return this.createElement('div', {
            className: 'nav-spacer',
            'aria-hidden': 'true',
        });
    }

    /**
     * Render the right button section
     * @returns {HTMLElement} The rendered element
     * @private
     */
    renderRightSection() {
        const { rightButton } = this.props;

        if (!rightButton) {
            return this.createElement('div', {
                className: 'nav-spacer',
                'aria-hidden': 'true',
            });
        }

        if (rightButton instanceof HTMLElement) {
            return rightButton;
        }

        return this.createElement(
            rightButton.element || 'button',
            rightButton.props || {},
            rightButton.content
        );
    }

    /**
     * Render the navigation bar
     * @returns {HTMLElement} The rendered navigation bar element
     */
    render() {
        const { title } = this.props;

        return this.createElement(
            'nav',
            {
                className: 'navigation-bar',
                role: 'navigation',
                'aria-label': 'Main navigation',
                onKeyDown: this.handleKeyDown,
            },
            this.renderLeftSection(),
            title &&
            this.createElement(
                'h1',
                {
                    className: 'nav-title',
                    role: 'heading',
                    'aria-level': '1',
                },
                title
            ),
            this.renderRightSection()
        );
    }
}
