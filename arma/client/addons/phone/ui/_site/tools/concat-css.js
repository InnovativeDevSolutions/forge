// concat-css.js
// Concatenate CSS files in the correct order into dist/app.bundle.css

const fs = require('fs');
const path = require('path');

// List of CSS files in order (from index.html)
const files = [
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
    '../styles/components/settings.css',
    '../styles/components/notes.css',
    '../styles/components/clock.css',
    '../styles/components/loader.css'
];

const outDir = path.join(__dirname, '../dist');
const outFile = path.join(outDir, 'app.bundle.css');

if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir);
}

let bundle = '';

files.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        bundle += `\n/* ---- ${file} ---- */\n`;
        bundle += content + '\n';
    } else {
        console.warn(`File not found: ${file}`);
    }
});

fs.writeFileSync(outFile, bundle, 'utf8');
console.log(`Bundled CSS written to ${outFile}`); 