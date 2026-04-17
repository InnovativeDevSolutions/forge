/** @format */

/**
 * @class Header
 * @extends Component
 * @description A component that renders a header section with a title.
 * Used for displaying page or section titles in the phone UI.
 */
class Header extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {string} [props.title='Phone UI'] - The title text to display in the header
     */
    constructor(props) {
        super(props);
    }

    /**
     * Render the header component
     * @returns {HTMLElement} The rendered header element
     */
    render() {
        const { title = 'Phone UI' } = this.props;

        return this.createElement(
            'header',
            {
                className: 'header',
                role: 'banner',
                'aria-label': 'Page header',
            },
            this.createElement(
                'h1',
                {
                    role: 'heading',
                    'aria-level': '1',
                },
                title
            )
        );
    }
}
