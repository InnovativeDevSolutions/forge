/**
 * @fileoverview Main entry point for the Notes application
 *
 * This module initializes the Notes app UI, including:
 * - Rendering the navigation bar with add note and search functionality
 * - Displaying the notes list
 * - Handling note creation, editing, and deletion
 * - Managing note persistence via A3API
 *
 * The notes app supports:
 * - Creating new notes
 * - Editing existing notes
 * - Deleting notes
 * - Searching through notes
 * - Auto-saving to Arma 3 profile
 */

// Initialize the notes app
function initializeNotesApp(container) {
    // Get current notes and view state from global state
    const { notes = [], currentNote = null, showNoteEditor = false } = globalState.getState();
    const appContainer = document.createElement('div');

    appContainer.className = 'app-container';
    appContainer.setAttribute('role', 'main');
    appContainer.setAttribute('aria-label', 'Notes');

    // Check if we're viewing/editing a specific note
    if (showNoteEditor || currentNote) {
        // Show note editor
        const noteEditor = new NoteEditor({
            note: currentNote,
            onSave: (savedNote) => {
                const currentNotes = globalState.getState().notes || [];
                let updatedNotes;
                
                if (savedNote.id && currentNotes.find(n => n.id === savedNote.id)) {
                    // Update existing note
                    updatedNotes = currentNotes.map(n => n.id === savedNote.id ? savedNote : n);
                } else {
                    // Add new note
                    updatedNotes = [savedNote, ...currentNotes];
                }
                
                globalState.setState({
                    notes: updatedNotes,
                    currentNote: null,
                    showNoteEditor: false
                });
                
                // Save to server
                if (typeof saveNote === 'function') {
                    saveNote(savedNote);
                }
            },
            onCancel: () => {
                globalState.setState({
                    currentNote: null,
                    showNoteEditor: false
                });
            },
            onDelete: (noteId) => {
                const currentNotes = globalState.getState().notes || [];
                const updatedNotes = currentNotes.filter(n => n.id !== noteId);
                
                globalState.setState({
                    notes: updatedNotes,
                    currentNote: null,
                    showNoteEditor: false
                });
                
                // Delete from server
                if (typeof deleteNote === 'function') {
                    deleteNote(noteId);
                }
            }
        });
        noteEditor.mount(appContainer);
    } else {
        // Show notes list
        const navBar = new NavigationBar({
            title: 'Notes',
            rightButton: {
                element: 'button',
                props: {
                    className: 'nav-button add-button',
                    onClick: () => {
                        globalState.setState({ 
                            showNoteEditor: true,
                            currentNote: null 
                        });
                    },
                    'aria-label': 'Add Note',
                    style: {
                        fontSize: '24px',
                        padding: '0 15px',
                        background: 'none',
                        border: 'none',
                        color: 'var(--accent-color)',
                        cursor: 'pointer'
                    }
                },
                content: '+'
            }
        });
        navBar.mount(appContainer);

        // Main content container
        const contentContainer = document.createElement('div');
        contentContainer.className = 'content';
        appContainer.appendChild(contentContainer);

        // Search bar
        const searchBar = new SearchBar({
            placeholder: 'Search notes...',
            onSearch: (query) => {
                // Filter notes based on search query
                const filteredNotes = notes.filter(note => 
                    note.title.toLowerCase().includes(query.toLowerCase()) ||
                    note.content.toLowerCase().includes(query.toLowerCase())
                );
                
                // Update the notes list
                const existingList = contentContainer.querySelector('.notes-list');
                if (existingList) {
                    existingList.remove();
                }
                
                const notesList = new NotesList({
                    notes: filteredNotes,
                    onNoteClick: (note) => {
                        globalState.setState({
                            currentNote: note,
                            showNoteEditor: true
                        });
                    }
                });
                notesList.mount(contentContainer);
            }
        });
        searchBar.mount(contentContainer);

        // Notes list
        const notesList = new NotesList({
            notes,
            onNoteClick: (note) => {
                globalState.setState({
                    currentNote: note,
                    showNoteEditor: true
                });
            }
        });
        notesList.mount(contentContainer);
    }

    // Mount the app container
    container.appendChild(appContainer);
}

// Make initialization function globally available
window.initializeNotesApp = initializeNotesApp;