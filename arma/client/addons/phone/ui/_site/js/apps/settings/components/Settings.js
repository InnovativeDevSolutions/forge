/**
 * @format
 * @class Settings
 * @extends Component
 * @description A settings component for the phone app.
 */

class Settings extends Component {
	/**
	 * @constructor
	 * @param {Object} props - Component properties
	 */
	constructor() {
		super();
		// Get current theme from document attribute
		const currentTheme = document.documentElement.getAttribute('data-theme');
		this.state = { isDarkTheme: currentTheme === 'dark' };
	}

	/**
	 * @method componentDidMount
	 * @description Sets the initial theme when the component mounts
	 */
	componentDidMount() {
		// Get current theme from game
		const alert = {
			"event": "phone::get::theme",
			"data": {}
		};
		A3API.SendAlert(JSON.stringify(alert));
	}

	/**
	 * @method updateTheme
	 * @param {boolean} isDark - Whether the theme is dark
	 * @description Updates the theme and phone screen background
	 */
	updateTheme(isDark) {
		const theme = isDark ? 'dark' : 'light';

		// Update document theme
		document.documentElement.setAttribute('data-theme', theme);

		// Update phone screen background
		const phoneScreen = document.querySelector('.phone-screen');
		if (phoneScreen) {
			phoneScreen.style.background = isDark ? '#000000' : '#ffffff';
		}

		// Save theme preference to game
		const alert = {
			"event": "phone::set::theme",
			"data": {
				"isDark": isDark
			}
		};
		A3API.SendAlert(JSON.stringify(alert));

		// Update state
		this.setState({ isDarkTheme: isDark });

		// Dispatch theme change event
		const themeEvent = new CustomEvent('themeChanged', {
			detail: { theme }
		});
		document.dispatchEvent(themeEvent);
	}

	/**
	 * @method handleThemeToggle
	 * @description Handles the theme toggle click
	 */
	handleThemeToggle = () => {
		const newTheme = !this.state.isDarkTheme;
		this.updateTheme(newTheme);
	}

	/**
	 * @method render
	 * @description Renders the settings component
	 */
	render() {
		return this.createElement('div', { className: 'settings-list' },
			this.createElement('div', { className: 'theme-toggle' },
				this.createElement('span', {}, 'Dark Mode'),
				this.createElement('div', {
					className: this.state.isDarkTheme ? 'custom-toggle active' : 'custom-toggle',
					onClick: this.handleThemeToggle,
					style: {
						width: '50px',
						height: '25px',
						backgroundColor: this.state.isDarkTheme ? '#0a84ff' : '#e9ecef',
						borderRadius: '34px',
						position: 'relative',
						cursor: 'pointer',
						transition: 'background-color 0.2s'
					}
				},
					this.createElement('div', {
						style: {
							width: '25px',
							height: '25px',
							backgroundColor: '#fff',
							borderRadius: '50%',
							position: 'absolute',
							left: this.state.isDarkTheme ? '25px' : '0px',
							transition: 'left 0.2s'
						}
					})
				)
			)
		);
	}
}