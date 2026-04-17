/** @format */

/**
 * @class HomeScreen
 * @extends Component
 * @description The main home screen component that displays the app grid.
 * Manages the display and interaction of app icons, handling navigation to different apps.
 */
class HomeScreen extends Component {
    /**
     * Cache for loaded icons
     * @static
     * @private
     */
    static iconCache = new Map();

    /**
     * @constructor
     * @param {Object} props - Component properties
     */
    constructor(props) {
        super(props);
        this.handleAppClick = this.handleAppClick.bind(this);
        this.state = {
            isDarkTheme: document.documentElement.getAttribute('data-theme') === 'dark'
        };
    }

    static iconPath(app, isDarkTheme) {
        return PhoneMedia.base64Path('images', isDarkTheme ? 'dark' : 'light', `${app.icon}.png`);
    }

    static backgroundPath(isDarkTheme) {
        return PhoneMedia.base64Path('images', 'bg', isDarkTheme ? 'bgdark_01_ca.png' : 'bglight_01_ca.png');
    }

    componentDidMount() {
        // Initial background update
        this.updateBackground();
        
        // Listen for theme changes
        document.addEventListener('themeChanged', (event) => {
            const isDarkTheme = event.detail.theme === 'dark';
            
            // Update background immediately
            const bgPath = HomeScreen.backgroundPath(isDarkTheme);

            PhoneMedia.loadImage(bgPath).then(imageContent => {
                if (this.element) {
                    this.element.style.background = `url('${imageContent}')`;
                    this.element.style.backgroundSize = 'contain';
                    this.element.style.backgroundPosition = 'center';
                }
            }).catch(error => {
                console.error(`Failed to load background image: ${bgPath}`, error);
            });

            // Update state after background change
            this.setState({ isDarkTheme });
        });
    }

    updateBackground() {
        const isDarkTheme = document.documentElement.getAttribute('data-theme') === 'dark';
        const bgPath = HomeScreen.backgroundPath(isDarkTheme);

        PhoneMedia.loadImage(bgPath).then(imageContent => {
            if (this.element) {
                this.element.style.background = `url('${imageContent}')`;
                this.element.style.backgroundSize = 'contain';
                this.element.style.backgroundPosition = 'center';
                this.element.style.backgroundRepeat = 'no-repeat';
                this.element.style.backgroundColor = isDarkTheme ? '#000000' : '#ffffff';
            } else {
                console.error('HomeScreen element not found during background update');
            }
        }).catch(error => {
            console.error(`Failed to load background image: ${bgPath}`, error);
        });
    }

    /**
     * List of available apps with their configurations
     * @type {Array<AppConfig>}
     * @private
     */
    static get apps() {
        return [
            { name: 'safari', title: 'Safari', icon: 'Safari', color: '' },
            { name: 'mail', title: 'Mail', icon: 'Mail', color: '' },
            { name: 'notes', title: 'Notes', icon: 'Notes', color: '' },
            { name: 'iCloud', title: 'iCloud', icon: 'iCloud', color: '' },
            { name: 'camera', title: 'Camera', icon: 'Camera', color: '' },
            { name: 'photos', title: 'Photos', icon: 'Photos', color: '' },
            { name: 'clock', title: 'Clock', icon: 'Clock', color: '' },
            { name: 'calendar', title: 'Calendar', icon: 'Calendar', color: '' },
            { name: 'store', title: 'App Store', icon: 'AppStore', color: '' },
        ];
    }

    /**
     * List of apps to show in the dock
     * @type {Array<AppConfig>}
     * @private
     */
    static get dockApps() {
        return [
            { name: 'phone', title: '', icon: 'Phone', color: '' },
            { name: 'contacts', title: '', icon: 'Contacts', color: '' },
            { name: 'messages', title: '', icon: 'Message', color: '' },
            { name: 'settings', title: '', icon: 'Settings', color: '' },
        ];
    }

    /**
     * Handles app icon click events
     * @param {string} appName - Name of the clicked app
     * @private
     */
    handleAppClick(appName) {
        globalState.setState({ currentApp: appName });
    }

    /**
     * Renders an individual app icon
     * @param {AppConfig} app - App configuration object
     * @returns {HTMLElement} The rendered app icon element
     * @private
     */
    renderAppIcon(app) {
        const imgElement = this.createElement('img', {
            alt: app.title,
            style: { display: 'none' } // Hide initially
        });

        const isDarkTheme = document.documentElement.getAttribute('data-theme') === 'dark';
        const iconPath = HomeScreen.iconPath(app, isDarkTheme);

        // Check cache first
        if (HomeScreen.iconCache.has(iconPath)) {
            imgElement.src = HomeScreen.iconCache.get(iconPath);
            imgElement.style.display = 'block';
        } else {
            // Load the file if not in cache
            PhoneMedia.loadImage(iconPath).then(imageContent => {
                HomeScreen.iconCache.set(iconPath, imageContent);
                imgElement.src = imageContent;
                imgElement.style.display = 'block';
            }).catch(error => {
                console.error(`Failed to load icon for ${app.title}:`, error);
            });
        }

        return this.createElement(
            'div',
            {
                className: 'app-icon',
                onClick: () => this.handleAppClick(app.name),
                role: 'button',
                'aria-label': `Open ${app.title} app`,
                tabIndex: 0,
                onKeyPress: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        this.handleAppClick(app.name);
                    }
                },
            },
            this.createElement(
                'div',
                {
                    className: 'app-icon-symbol',
                    'aria-hidden': 'true',
                    style: app.color ? { background: app.color } : {}
                },
                imgElement
            ),
            this.createElement('span', { className: 'app-title' }, app.title)
        );
    }

    /**
     * Render the home screen
     * @returns {HTMLElement} The rendered home screen element
     */
    render() {
        return this.createElement(
            'div',
            {
                className: 'home-screen',
                role: 'main',
                'aria-label': 'Home screen',
            },
            this.createElement(
                'div',
                {
                    className: 'app-grid',
                    role: 'grid',
                    'aria-label': 'App grid',
                },
                ...HomeScreen.apps.map((app) => this.renderAppIcon(app))
            ),
            this.createElement(
                'div',
                {
                    className: 'dock',
                    role: 'toolbar',
                    'aria-label': 'App dock',
                },
                ...HomeScreen.dockApps.map((app) => this.renderAppIcon(app))
            )
        );
    }
}

/**
 * @typedef {Object} AppConfig
 * @property {string} name - Internal name/identifier of the app
 * @property {string} title - Display title of the app
 * @property {string} icon - Emoji icon representing the app
 * @property {string} color - Background color for the app icon (if any)
 */
