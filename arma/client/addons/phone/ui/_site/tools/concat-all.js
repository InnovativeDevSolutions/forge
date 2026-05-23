// concat-all.js
// Concatenate JS and CSS files into dist/app.bundle.js and dist/app.bundle.css

const fs = require('fs');
const path = require('path');

// JS files in order
const jsFiles = [
    '../js/core/Component.js',
    '../js/core/StateManager.js',
    '../js/utils/helpers.js',
    '../js/utils/PhoneMedia.js',
    '../js/components/StatusBar.js',
    '../js/components/Modal.js',
    '../js/components/NavigationBar.js',
    '../js/components/HomeIndicator.js',
    '../js/components/SearchBar.js',
    '../js/components/Header.js',
    '../js/components/HomeScreen.js',
    '../js/apps/phone/components/Dialpad.js',
    '../js/apps/phone/index.js',
    '../js/apps/messages/components/MessagesList.js',
    '../js/apps/messages/components/MessageItem.js',
    '../js/apps/messages/components/ConversationView.js',
    '../js/apps/messages/index.js',
    '../js/apps/contacts/components/ContactList.js',
    '../js/apps/contacts/components/ContactItem.js',
    '../js/apps/contacts/components/AddContactForm.js',
    '../js/apps/contacts/index.js',
    '../js/apps/mail/components/MailList.js',
    '../js/apps/mail/components/MailComposer.js',
    '../js/apps/mail/components/MailDetail.js',
    '../js/apps/mail/index.js',
    '../js/apps/notes/components/NotesList.js',
    '../js/apps/notes/components/NoteEditor.js',
    '../js/apps/notes/index.js',
    '../js/apps/clock/components/WorldClock.js',
    '../js/apps/clock/components/Stopwatch.js',
    '../js/apps/clock/components/Timer.js',
    '../js/apps/clock/components/AlarmClock.js',
    '../js/apps/clock/index.js',
    '../js/apps/settings/components/Settings.js',
    '../js/apps/settings/index.js',
    '../js/apps/calendar/components/Calendar.js',
    '../js/apps/calendar/components/EventEditor.js',
    '../js/apps/calendar/index.js',
    '../js/app.js',
    '../js/main.js',
    '../js/global.js'
];

// CSS files in order
const cssFiles = [
    '../styles/base.css',
    '../styles/main.css',
    '../styles/components/layout.css',
    '../styles/components/phone.css',
    '../styles/components/buttons.css',
    '../styles/components/modal.css',
    '../styles/components/nav-bar.css',
    '../styles/components/status-bar.css',
    '../styles/components/home.css',
    '../styles/components/contacts.css',
    '../styles/components/dialpad.css',
    '../styles/components/messages.css',
    '../styles/components/mail.css',
    '../styles/components/notes.css',
    '../styles/components/clock.css',
    '../styles/components/calendar.css',
    '../styles/components/settings.css',
    '../styles/components/loader.css'
];

const outDir = path.join(__dirname, '../dist');
if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir);
}

// Bundle JS
const jsOutFile = path.join(outDir, 'app.bundle.js');
let jsBundle = '';
jsFiles.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        jsBundle += `\n// ---- ${file} ----\n`;
        jsBundle += content + '\n';
    } else {
        console.warn(`JS file not found: ${file}`);
    }
});
fs.writeFileSync(jsOutFile, jsBundle, 'utf8');
console.log(`Bundled JS written to ${jsOutFile}`);

// Bundle CSS
const cssOutFile = path.join(outDir, 'app.bundle.css');
let cssBundle = '';
cssFiles.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        cssBundle += `\n/* ---- ${file} ---- */\n`;
        cssBundle += content + '\n';
    } else {
        console.warn(`CSS file not found: ${file}`);
    }
});
fs.writeFileSync(cssOutFile, cssBundle, 'utf8');
console.log(`Bundled CSS written to ${cssOutFile}`);
