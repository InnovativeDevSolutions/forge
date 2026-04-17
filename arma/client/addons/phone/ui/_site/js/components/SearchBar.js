/** @format */

/**
 * @class SearchBar
 * @extends Component
 * @description A search input component that provides debounced search functionality.
 * Includes built-in debouncing to prevent excessive search updates.
 */
class SearchBar extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {string} [props.placeholder='Search contacts...'] - Placeholder text for the search input
     * @param {Function} [props.onSearch] - Callback function when search value changes
     * @param {string} [props.value] - Initial input value
     */
    constructor(props) {
        super(props);

        // Set debounce delay
        this.DEBOUNCE_DELAY = 300; // milliseconds

        // Initialize state
        this.state = {
            searchTerm: props.value || ''
        };

        // Bind methods
        this.handleInput = debounce(this.handleInput.bind(this), this.DEBOUNCE_DELAY);
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    /**
     * Update state when props change
     * @param {Object} nextProps - Next props
     */
    componentWillReceiveProps(nextProps) {
        if (nextProps.value !== this.props.value) {
            this.setState({ searchTerm: nextProps.value });
        }
    }

    /**
     * Handle input change events
     * @param {Event} e - Input change event
     * @private
     */
    handleInputChange(e) {
        const value = e.target.value;
        this.setState({ searchTerm: value });
        this.handleInput(value);
    }

    /**
     * Debounced search handler
     * @param {string} searchTerm - Current search term
     * @private
     */
    handleInput(searchTerm) {
        const { onSearch } = this.props;
        if (onSearch) {
            onSearch(searchTerm);
        }
    }

    /**
     * Handle keyboard events
     * @param {KeyboardEvent} e - Keyboard event
     * @private
     */
    handleKeyDown(e) {
        // Clear search on Escape
        if (e.key === 'Escape') {
            this.setState({ searchTerm: '' });
            this.handleInput('');
        }
    }

    /**
     * Render the search bar
     * @returns {HTMLElement} The rendered search bar element
     */
    render() {
        const { placeholder = 'Search contacts...' } = this.props;
        const { searchTerm } = this.state;

        return this.createElement(
            'div',
            {
                className: 'search-bar',
                role: 'search',
                'aria-label': 'Search contacts',
                style: {
                    paddingBottom: '10px',
                    borderBottom: '1px solid #e9ecef',
                },
            },
            this.createElement('input', {
                type: 'search',
                placeholder,
                value: searchTerm,
                onInput: this.handleInputChange,
                onKeyDown: this.handleKeyDown,
                'aria-label': placeholder,
                style: {
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '20px',
                    fontSize: '16px',
                    outline: 'none',
                },
            })
        );
    }
}
