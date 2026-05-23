/** @format */

/**
 * @fileoverview Core Component class that provides the foundation for all UI components
 * in the phone application. Implements a lightweight component lifecycle and virtual DOM-like
 * functionality without external dependencies.
 */

/**
 * Base Component class that handles rendering, lifecycle events, and state management.
 * Provides a React-like component interface for building UI elements.
 *
 * @class
 * @example
 * class MyComponent extends Component {
 *   constructor(props) {
 *     super(props);
 *     this.state = { count: 0 };
 *   }
 *
 *   render() {
 *     return this.createElement('div', {}, `Count: ${this.state.count}`);
 *   }
 * }
 */
class Component {
    /**
     * Creates a new Component instance.
     * @param {Object} props - Initial properties for the component
     */
    constructor(props = {}) {
        this.props = props;
        this.state = {};
        this.element = null;
        this.children = [];
        this.eventListeners = new Map();
        this.mounted = false;
        this.pendingUpdate = false;
    }

    /**
     * Updates component state and triggers a re-render.
     * State updates are batched to prevent multiple renders in the same tick.
     *
     * @param {Object} newState - Object containing state updates
     */
    setState(newState) {
        const prevState = { ...this.state };
        this.state = { ...this.state, ...newState };

        // Prevent multiple updates in the same tick
        if (!this.pendingUpdate) {
            this.pendingUpdate = true;
            setTimeout(() => {
                this.pendingUpdate = false;
                this.updateComponent(prevState);
            }, 0);
        }
    }

    /**
     * Internal method to handle component updates.
     * Manages the re-rendering process and maintains child component state.
     *
     * @private
     * @param {Object} prevState - Previous state before update
     */
    updateComponent(prevState) {
        // Call onStateChange hook
        this.onStateChange(prevState, this.state);

        // Re-render and update DOM
        if (this.element && this.element.parentNode) {
            const container = this.element.parentNode;
            const oldElement = this.element;

            // Store input states and elements before update
            const inputStates = new Map();
            oldElement.querySelectorAll('input').forEach(input => {
                inputStates.set(input, {
                    element: input,
                    value: input.value,
                    selectionStart: input.selectionStart,
                    selectionEnd: input.selectionEnd,
                    isFocused: document.activeElement === input
                });
            });

            // Store mounted state of children
            const childStates = new Map();
            this.children.forEach((child) => {
                childStates.set(child, child.mounted);
            });

            // Create new element
            const newElement = this.render();

            // Update the DOM while preserving input elements
            if (oldElement && newElement) {
                // Replace the old element with the new one
                container.replaceChild(newElement, oldElement);
                this.element = newElement;

                // Restore input elements and their states
                inputStates.forEach((state, oldInput) => {
                    const newInput = newElement.querySelector(`input[type="${oldInput.type}"]`);
                    if (newInput) {
                        // Replace the new input with the old one
                        newInput.parentNode.replaceChild(oldInput, newInput);

                        // Restore input state
                        if (state.isFocused) {
                            oldInput.focus();
                            oldInput.setSelectionRange(state.selectionStart, state.selectionEnd);
                        }
                    }
                });

                // Restore child components that were previously mounted
                this.children.forEach((child) => {
                    if (childStates.get(child)) {
                        child.mount(this.element);
                    }
                });
            }
        }
    }

    /**
     * Lifecycle method called when state changes.
     * Override in subclasses to handle state updates.
     *
     * @param {Object} prevState - Previous state
     * @param {Object} newState - New state
     */
    onStateChange(prevState, newState) {
        // Override in subclasses if needed
    }

    /**
     * Mounts the component to a DOM container.
     * Handles initial render and lifecycle methods.
     *
     * @param {HTMLElement} container - DOM element to mount component into
     * @returns {Component} The component instance
     */
    mount(container) {
        // Skip if already mounted to this container
        if (this.mounted && this.element && this.element.parentNode === container) {
            return this;
        }

        const newElement = this.render();
        if (this.element && this.element.parentNode) {
            this.element.parentNode.replaceChild(newElement, this.element);
        } else {
            container.appendChild(newElement);
        }
        this.element = newElement;

        // Call componentDidMount after mounting
        if (!this.mounted && this.componentDidMount) {
            this.componentDidMount();
        }
        this.mounted = true;
        return this;
    }

    /**
     * Creates a DOM element with specified properties and children.
     * Handles event listeners, styles, and refs.
     *
     * @param {string} tag - HTML tag name
     * @param {Object} props - Element properties and attributes
     * @param {...(string|number|Component|HTMLElement)} children - Child elements
     * @returns {HTMLElement} Created DOM element
     */
    createElement(tag, props = {}, ...children) {
        const element = document.createElement(tag);

        // Set attributes and properties
        Object.entries(props).forEach(([key, value]) => {
            if (key.startsWith('on') && typeof value === 'function') {
                const event = key.slice(2).toLowerCase();
                element.addEventListener(event, value);

                // Store event listener for cleanup
                if (!this.eventListeners.has(element)) {
                    this.eventListeners.set(element, []);
                }
                this.eventListeners.get(element).push({ event, handler: value });
            } else if (key === 'className') {
                element.className = value;
            } else if (key === 'style' && typeof value === 'object') {
                Object.assign(element.style, value);
            } else if (key === 'ref' && typeof value === 'function') {
                value(element);
            } else if (typeof value === 'boolean') {
                if (value) {
                    element.setAttribute(key, key);
                }
            } else if (value !== null && value !== undefined) {
                element.setAttribute(key, value);
            } else {
                return;
            }
        });

        // Add children
        children.flat().forEach((child) => {
            if (child === null || child === undefined) {
                return;
            }

            if (typeof child === 'string' || typeof child === 'number') {
                element.appendChild(document.createTextNode(child));
            } else if (child instanceof Component) {
                child.mount(element);
                this.children.push(child);
            } else if (child instanceof HTMLElement) {
                element.appendChild(child);
            }
        });

        return element;
    }

    /**
     * Renders the component's DOM representation.
     * Must be overridden by subclasses to define component structure.
     *
     * @returns {HTMLElement} The rendered DOM element
     */
    render() {
        // Override in subclasses
        return this.createElement('div');
    }

    /**
     * Unmounts the component and cleans up resources.
     * Removes event listeners and unmounts children.
     */
    unmount() {
        // Call componentWillUnmount before cleanup
        if (this.mounted && this.componentWillUnmount) {
            this.componentWillUnmount();
        }

        // Clean up event listeners
        this.eventListeners.forEach((listeners, element) => {
            listeners.forEach(({ event, handler }) => {
                element.removeEventListener(event, handler);
            });
        });
        this.eventListeners.clear();

        // Unmount children
        this.children.forEach((child) => {
            if (child.mounted) {
                child.unmount();
            }
        });
        this.children = [];

        // Remove from DOM
        if (this.element && this.element.parentNode) {
            this.element.parentNode.removeChild(this.element);
        }
        this.element = null;
        this.mounted = false;
    }
}
