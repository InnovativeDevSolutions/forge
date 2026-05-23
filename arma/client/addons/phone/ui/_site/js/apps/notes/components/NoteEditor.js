/**
 * @format
 * @class NoteEditor
 * @extends Component
 * @description A component for creating and editing notes.
 */

class NoteEditor extends Component {
    /**
     * @constructor
     * @param {Object} props - Component properties
     * @param {Object} [props.note] - Existing note to edit
     * @param {Function} props.onSave - Callback when note is saved
     * @param {Function} props.onCancel - Callback when editing is cancelled
     * @param {Function} [props.onDelete] - Callback when note is deleted
     */
    constructor(props = {}) {
        super(props);
        
        const existingNote = props.note || {};
        this.state = {
            title: existingNote.title || '',
            content: existingNote.content || '',
            id: existingNote.id || null,
            createdAt: existingNote.createdAt || new Date().toISOString(),
            updatedAt: existingNote.updatedAt || new Date().toISOString(),
            isModified: false
        };

        // References for DOM elements
        this.titleInputRef = null;
        this.contentTextareaRef = null;

        // Bind methods
        this.handleTitleChange = this.handleTitleChange.bind(this);
        this.handleContentChange = this.handleContentChange.bind(this);
        this.handleSave = this.handleSave.bind(this);
        this.handleCancel = this.handleCancel.bind(this);
        this.handleDelete = this.handleDelete.bind(this);
        this.setTitleInputRef = this.setTitleInputRef.bind(this);
        this.setContentTextareaRef = this.setContentTextareaRef.bind(this);
        this.autoSave = this.autoSave.bind(this);

        // Auto-save timer
        this.autoSaveTimer = null;
    }

    /**
     * Component mounted - focus on title if new note
     */
    componentDidMount() {
        if (!this.state.id && this.titleInputRef) {
            this.titleInputRef.focus();
        } else if (this.contentTextareaRef) {
            this.contentTextareaRef.focus();
            // Move cursor to end
            const length = this.contentTextareaRef.value.length;
            this.contentTextareaRef.setSelectionRange(length, length);
        }
    }

    /**
     * Component will unmount - clear auto-save timer
     */
    componentWillUnmount() {
        if (this.autoSaveTimer) {
            clearTimeout(this.autoSaveTimer);
        }
    }

    /**
     * Set title input reference and manage focus
     */
    setTitleInputRef(element) {
        if (element) {
            this.titleInputRef = element;
            
            // Ensure input displays the correct content
            if (this.state.title && element.value !== this.state.title) {
                element.value = this.state.title;
            }
            
            // Maintain focus if this element was previously focused
            if (document.activeElement !== element && !this.state.id) {
                element.focus();
            }
        }
    }

    /**
     * Set content textarea reference and manage focus
     */
    setContentTextareaRef(element) {
        if (element) {
            this.contentTextareaRef = element;
            
            // Ensure textarea displays the correct content
            if (this.state.content && element.value !== this.state.content) {
                element.value = this.state.content;
                element.textContent = this.state.content;
            }
            
            // Maintain focus if this element was previously focused
            if (document.activeElement !== element && this.state.id) {
                element.focus();
                // Move cursor to end
                const length = element.value.length;
                element.setSelectionRange(length, length);
            }
        }
    }

    /**
     * Handle title input change
     */
    handleTitleChange(e) {
        // Update state directly to avoid re-render during typing
        this.state.title = e.target.value;
        this.state.isModified = true;
        this.scheduleAutoSave();
    }

    /**
     * Handle content textarea change
     */
    handleContentChange(e) {
        // Update state directly to avoid re-render during typing
        this.state.content = e.target.value;
        this.state.isModified = true;
        this.scheduleAutoSave();
    }

    /**
     * Schedule auto-save (debounced)
     */
    scheduleAutoSave() {
        if (this.autoSaveTimer) {
            clearTimeout(this.autoSaveTimer);
        }
        
        this.autoSaveTimer = setTimeout(() => {
            this.autoSave();
        }, 30000); // Auto-save after 30 seconds of inactivity
    }

    /**
     * Auto-save the note
     */
    autoSave() {
        if (this.state.isModified && (this.state.title.trim() || this.state.content.trim())) {
            this.handleSave(false); // Save without closing editor
        }
    }

    /**
     * Handle save button click
     */
    handleSave(shouldClose = true) {
        const { title, content, id, createdAt } = this.state;
        
        // Don't save empty notes
        if (!title.trim() && !content.trim()) {
            if (shouldClose) {
                this.handleCancel();
            }
            return;
        }

        const savedNote = {
            id: id || generateId(),
            title: title.trim() || 'Untitled',
            content: content.trim(),
            createdAt: createdAt,
            updatedAt: new Date().toISOString()
        };

        this.setState({
            isModified: false,
            id: savedNote.id,
            updatedAt: savedNote.updatedAt
        });

        if (this.props.onSave) {
            this.props.onSave(savedNote);
        }

        if (shouldClose) {
            // Note: The parent component will handle navigation
        }
    }

    /**
     * Handle cancel button click
     */
    handleCancel() {
        if (this.autoSaveTimer) {
            clearTimeout(this.autoSaveTimer);
        }
        
        if (this.props.onCancel) {
            this.props.onCancel();
        }
    }

    /**
     * Handle delete button click
     */
    handleDelete() {        
        if (!this.state.id) {
            console.warn('Cannot delete note: no ID present');
            return;
        }
        
        if (!this.props.onDelete) {
            console.warn('Cannot delete note: no onDelete callback provided');
            return;
        }
        
        try {
            // Show delete confirmation modal using global state
            globalState.setState({
                showDeleteModal: true,
                noteToDelete: {
                    id: this.state.id,
                    title: this.state.title || 'Untitled'
                }
            });
        } catch (error) {
            console.error('Error showing delete confirmation:', error);
        }
    }


    /**
     * Get the word count for the note
     */
    getWordCount() {
        const { content } = this.state;
        if (!content.trim()) return 0;
        return content.trim().split(/\s+/).length;
    }

    /**
     * Render the editor
     */
    render() {
        const { title, content, id, isModified } = this.state;
        const wordCount = this.getWordCount();

        return this.createElement(
            'div',
            { className: 'note-editor' },
            
            // Navigation bar
            new NavigationBar({
                title: id ? 'Edit Note' : 'New Note',
                leftButton: {
                    element: 'button',
                    props: {
                        className: 'nav-button cancel-button',
                        onClick: this.handleCancel,
                        'aria-label': 'Cancel'
                    },
                    content: 'Cancel'
                },
                rightButton: {
                    element: 'button',
                    props: {
                        className: 'nav-button save-button',
                        onClick: () => this.handleSave(true),
                        'aria-label': 'Save note'
                    },
                    content: 'Save'
                }
            }),

            // Editor content
            this.createElement(
                'div',
                { className: 'editor-content' },
                
                // Title input
                this.createElement('input', {
                    type: 'text',
                    className: 'note-title-input',
                    placeholder: 'Note title...',
                    value: title,
                    onInput: this.handleTitleChange,
                    ref: this.setTitleInputRef
                }),

                // Content textarea
                this.createElement('textarea', {
                    className: 'note-content-input',
                    placeholder: 'Start writing...',
                    value: content,
                    onInput: this.handleContentChange,
                    ref: this.setContentTextareaRef
                }),

                // Editor footer
                this.createElement(
                    'div',
                    { className: 'editor-footer' },
                    
                    // Word count and status
                    this.createElement(
                        'div',
                        { className: 'editor-status' },
                        this.createElement(
                            'span',
                            { className: 'word-count' },
                            `${wordCount} word${wordCount !== 1 ? 's' : ''}`
                        ),
                        isModified && this.createElement(
                            'span',
                            { className: 'modified-indicator' },
                            ' * Modified'
                        )
                    ),

                    // Delete button (only for existing notes)
                    id && this.createElement(
                        'button',
                        {
                            className: 'delete-button',
                            onClick: this.handleDelete,
                            'aria-label': 'Delete note'
                        },
                        'Delete'
                    )
                )
            )
        );
    }
}