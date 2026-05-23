/** @format */

/**
 * @fileoverview Utility functions for the phone application
 * Contains helper functions for common operations like debouncing,
 * ID generation, phone number formatting, and text manipulation.
 */

/**
 * Creates a debounced function that delays invoking func until after wait milliseconds have elapsed
 * @param {Function} func - The function to debounce
 * @param {number} wait - The number of milliseconds to delay
 * @returns {Function} The debounced function
 */
const debounce = (func, wait) => {
    let timeout;

    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };

        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

/**
 * Generates a unique identifier using timestamp and random number.
 *
 * @returns {string} A unique string identifier
 * @example
 * const newId = generateId(); // Returns something like "lh8d3m4k2n1"
 */
const generateId = () => {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
};

/**
 * Formats a phone number string into a standardized format.
 * Converts "11234567890" to "+1 (123) 456-7890"
 *
 * @param {string} phoneNumber - The raw phone number to format
 * @returns {string} The formatted phone number
 * @example
 * const formatted = formatPhoneNumber('11234567890'); // Returns "+1 (123) 456-7890"
 */
const formatPhoneNumber = (phoneNumber) => {
    const cleaned = phoneNumber.replace(/\D/g, '');
    const match = cleaned.match(/^(\d{1})(\d{3})(\d{3})(\d{4})$/);
    if (match) {
        return `+${match[1]} (${match[2]}) ${match[3]}-${match[4]}`;
    }
    return phoneNumber;
};

/**
 * Extracts initials from a person's name.
 * Takes first letter of first and last name, up to 2 characters.
 *
 * @param {string} name - The full name to get initials from
 * @returns {string} The initials (maximum 2 characters)
 * @example
 * const initials = getInitials('John Doe'); // Returns "JD"
 * const singleInitial = getInitials('John'); // Returns "J"
 */
const getInitials = (name) => {
    return name
        .split(' ')
        .map((word) => word.charAt(0).toUpperCase())
        .join('')
        .substring(0, 2);
};
