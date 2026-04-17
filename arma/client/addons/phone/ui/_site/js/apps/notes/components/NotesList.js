/**
 * @format
 * @class NotesList
 * @extends Component
 * @description A component that displays a list of notes with preview content.
 */

class NotesList extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Array} props.notes - Array of note objects
     * @param {Function} props.onNoteClick - Callback when a note is clicked
     */
    constructor(props = {}) {
        super(props);
        this.state = {
            notes: props.notes || []
        };

        // Bind methods
        this.handleNoteClick = this.handleNoteClick.bind(this);
        this.formatDate = this.formatDate.bind(this);
        this.truncateText = this.truncateText.bind(this);
    }

    /**
     * Handle note click
     * @param {Object} note - The clicked note
     */
    handleNoteClick(note) {
        if (this.props.onNoteClick) {
            this.props.onNoteClick(note);
        }
    }

    /**
     * Format date for display
     * @param {Date|string} date - Date to format
     * @returns {string} Formatted date string
     */
    formatDate(date) {
        if (!date) return '';
        
        const noteDate = new Date(date);
        const now = new Date();
        const diffTime = Math.abs(now - noteDate);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) {
            return noteDate.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });
        } else if (diffDays === 1) {
            return 'Yesterday';
        } else if (diffDays < 7) {
            return noteDate.toLocaleDateString('en-US', { weekday: 'long' });
        } else {
            return noteDate.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric'
            });
        }
    }

    /**
     * Truncate text for preview
     * @param {string} text - Text to truncate
     * @param {number} maxLength - Maximum length
     * @returns {string} Truncated text
     */
    truncateText(text, maxLength = 100) {
        if (!text) return '';
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength).trim() + '...';
    }

    /**
     * Render a single note item
     * @param {Object} note - Note object
     * @returns {HTMLElement} Note item element
     */
    renderNoteItem(note) {
        return this.createElement(
            'div',
            {
                className: 'note-item',
                onClick: () => this.handleNoteClick(note),
                role: 'button',
                tabIndex: 0,
                'aria-label': `Open note: ${note.title || 'Untitled'}`,
                onKeyDown: (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        this.handleNoteClick(note);
                    }
                }
            },
            this.createElement(
                'div',
                { className: 'note-header' },
                this.createElement(
                    'h3',
                    { className: 'note-title' },
                    note.title || 'Untitled'
                ),
                this.createElement(
                    'span',
                    { className: 'note-date' },
                    this.formatDate(note.updatedAt || note.createdAt)
                )
            ),
            this.createElement(
                'p',
                { className: 'note-preview' },
                this.truncateText(note.content)
            )
        );
    }

    /**
     * Render empty state
     * @returns {HTMLElement} Empty state element
     */
    renderEmptyState() {
        return this.createElement(
            'div',
            { className: 'notes-empty-state' },
            this.createElement(
                'div',
                { className: 'empty-icon' },
                this.createElement('img', {
                    src: 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="grey" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14,2 14,8 20,8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10,9 9,9 8,9"/></svg>',
                    alt: 'Notes',
                    style: 'width:64px;height:64px;opacity:0.5;display:block;'
                })
            ),
            this.createElement(
                'h3',
                {},
                'No Notes Yet'
            ),
            this.createElement(
                'p',
                {},
                'Tap the + button to create your first note'
            )
        );
    }

    /**
     * Render the notes list
     * @returns {HTMLElement} The rendered notes list
     */
    render() {
        const { notes } = this.props;

        if (!notes || notes.length === 0) {
            return this.createElement(
                'div',
                { className: 'notes-list empty' },
                this.renderEmptyState()
            );
        }

        return this.createElement(
            'div',
            {
                className: 'notes-list',
                role: 'list',
                'aria-label': `${notes.length} notes`
            },
            ...notes.map((note, index) => {
                const noteElement = this.renderNoteItem(note);
                noteElement.setAttribute('role', 'listitem');
                noteElement.setAttribute('key', note.id || index);
                return noteElement;
            })
        );
    }
}

