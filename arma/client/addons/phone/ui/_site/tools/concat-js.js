// concat-js.js
// Concatenate JS files in the correct order into dist/app.bundle.js

const fs = require('fs');
const path = require('path');

// List of JS files in order (from index.html)
const files = [
    // Core Framework
    '../js/core/Component.js',
    '../js/core/StateManager.js',

    // Utils
    '../js/utils/helpers.js',

    // Shared Components
    '../js/components/StatusBar.js',
    '../js/components/Modal.js',
    '../js/components/NavigationBar.js',
    '../js/components/HomeIndicator.js',
    '../js/components/SearchBar.js',
    '../js/components/Header.js',

    // App Components
    '../js/components/HomeScreen.js',

    // Phone App
    '../js/apps/phone/components/Dialpad.js',
    '../js/apps/phone/index.js',

    // Messages App
    '../js/apps/messages/components/MessagesList.js',
    '../js/apps/messages/components/MessageItem.js',
    '../js/apps/messages/components/ConversationView.js',
    '../js/apps/messages/index.js',

    // Contacts App
    '../js/apps/contacts/components/ContactList.js',
    '../js/apps/contacts/components/ContactItem.js',
    '../js/apps/contacts/components/AddContactForm.js',
    '../js/apps/contacts/index.js',

    // Settings App
    '../js/apps/settings/components/Settings.js',
    '../js/apps/settings/index.js',

    // Notes App
    '../js/apps/notes/components/NotesList.js',
    '../js/apps/notes/components/NoteEditor.js',
    '../js/apps/notes/index.js',

    // Clock App
    '../js/apps/clock/components/WorldClock.js',
    '../js/apps/clock/components/Stopwatch.js',
    '../js/apps/clock/components/Timer.js',
    '../js/apps/clock/components/AlarmClock.js',
    '../js/apps/clock/index.js',


    // Main App
    '../js/app.js',
    '../js/main.js',
    '../js/global.js'
];

const outDir = path.join(__dirname, '../dist');
const outFile = path.join(outDir, 'app.bundle.js');

if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir);
}

let bundle = '';

files.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        bundle += `\n// ---- ${file} ----\n`;
        bundle += content + '\n';
    } else {
        console.warn(`File not found: ${file}`);
    }
});

fs.writeFileSync(outFile, bundle, 'utf8');
console.log(`Bundled JS written to ${outFile}`);