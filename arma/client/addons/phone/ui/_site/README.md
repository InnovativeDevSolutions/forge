# Phone UI Framework

A lightweight, component-based framework for building phone-like user interfaces in the browser. This framework provides a React-like development experience without external dependencies, making it perfect for creating mobile-first web applications.

## Features

- Component-based architecture (React-like API)
- Virtual DOM-like rendering system
- Built-in global and local state management
- Modular, maintainable CSS structure
- Mobile-first, accessible design (ARIA roles/labels)
- No external dependencies
- Easy production bundling (JS & CSS)

## Getting Started

1. Clone the repository
2. **On Windows, run the provided script to build and start the local server:**
   ```powershell
   ./start.ps1
   ```
   This will automatically build the JS and CSS bundles and open the app in your browser at [http://localhost:8000](http://localhost:8000).

3. **On Linux/macOS, run the provided shell script:**
   ```sh
   chmod +x start.sh
   ./start.sh
   ```
   This will automatically build the JS and CSS bundles and open the app in your browser at [http://localhost:8000](http://localhost:8000).

4. If you prefer, you can run the build manually with `node tools/concat-all.js` and start a local server (e.g., `python3 -m http.server`).

> **Note:** The app will not work unless you run the build script. Always re-run the build script if you add, remove, or change any JS or CSS files.

## Project Structure

```
├── index.html              # Main entry point
├── dist/                   # Production bundles (auto-generated)
│   ├── app.bundle.js
│   └── app.bundle.css
├── styles/                 # CSS files
│   ├── base.css
│   ├── main.css
│   └── components/         # Component-specific styles
├── js/                     # JavaScript files
│   ├── core/               # Core framework (Component, StateManager)
│   ├── components/         # Shared UI components
│   ├── apps/               # App modules (phone, messages, contacts, settings)
│   ├── utils/              # Utility functions (scriptLoader, helpers)
│   ├── app.js              # Main app integration/root
│   └── main.js             # App initialization
├── tools/                  # Build and utility scripts
│   ├── concat-js.js
│   ├── concat-css.js
│   └── concat-all.js
├── start.ps1               # Windows script to build and start local server
├── start.sh                # Linux/macOS script to build and start local server
└── images/                 # Image assets
```

## App Structure

- **Main App (`App` class in `js/app.js`)**: Handles app switching, global modals, and integration.
- **Apps (`js/apps/`)**: Each app (Phone, Messages, Contacts, Settings) has its own entry point (`index.js`) and components.
- **Components (`js/components/` and app subfolders)**: Reusable UI elements (NavigationBar, Modal, StatusBar, etc.).
- **State Management (`js/core/StateManager.js`)**: Global state via `globalState`, plus local state in components.
- **Utilities (`js/utils/`)**: Script loader, helpers, etc.

## Creating Components

Components are created by extending the base `Component` class:

```javascript
class MyComponent extends Component {
  constructor(props) {
    super(props);
    this.state = { /* ... */ };
  }
  render() {
    return this.createElement('div', { className: 'my-component' }, 'Hello World');
  }
}
```

### Component Lifecycle
- `constructor(props)`: Initialize component
- `render()`: Define component structure
- `componentDidMount()`: Called after mount
- `componentWillUnmount()`: Called before unmount
- `onStateChange(prevState, newState)`: On state change

### State Management
- Local: `this.setState({ ... })`
- Global: `globalState.setState({ ... })`, `globalState.subscribe(cb)`

## Creating Elements

Use `createElement` to create DOM elements:

```javascript
this.createElement('div', { className: 'container', onClick: ... }, 'Content');
```

## Styling

- Base styles: `base.css`, `main.css`
- Component styles: `styles/components/`
- For all environments, use the bundled `dist/app.bundle.css`

## Available Components

- `StatusBar`, `NavigationBar`, `Modal`, `HomeScreen`, `HomeIndicator`, `Header`, `SearchBar`
- App-specific: `ContactList`, `ContactItem`, `AddContactForm`, `MessagesList`, `MessageItem`, `ConversationView`, `Dialpad`, `Settings`

## Scripts

- `tools/concat-js.js`: Bundles all JS files into `dist/app.bundle.js`
- `tools/concat-css.js`: Bundles all CSS files into `dist/app.bundle.css`
- `tools/concat-all.js`: Bundles both JS and CSS (**required for all environments**)
- `start.ps1`: Builds and starts a local server on Windows
- `start.sh`: Builds and starts a local server on Linux/macOS

## How to Add a New App

1. Create a new folder in `js/apps/yourapp/` with an `index.js` and any components.
2. Add your app's entry point to the bundler scripts and (if needed) to the app switch logic in `js/app.js`.
3. Add styles in `styles/components/yourapp.css` and include in the CSS bundle list.
4. **Re-run the build script after any changes.**

## Best Practices

1. Keep components small and focused
2. Use state management for global data
3. Follow the component lifecycle
4. Use modular CSS for styling
5. Handle cleanup in `componentWillUnmount`
6. Use ARIA roles/labels for accessibility

## Development & Production

- **Always run the build script (`node tools/concat-all.js`, `./start.ps1`, or `./start.sh`) before starting or deploying the app.**
- The app will not work unless all JS and CSS are bundled.
- If you encounter issues, re-run the build script to ensure all files are up to date.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License. 