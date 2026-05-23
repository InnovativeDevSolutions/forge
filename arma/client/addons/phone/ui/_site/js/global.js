/** @format */

/**
 * @fileoverview Global exports for the phone application.
 * Exposes all API functions and initialization to the global window object.
 */

/**
 * Sets the theme for the phone application
 * @param {string} theme - The theme to set ('dark' or 'light')
 */
function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);

    // Dispatch theme change event
    const themeEvent = new CustomEvent('themeChanged', {
        detail: { theme }
    });
    document.dispatchEvent(themeEvent);
}

// Debounce variables for contact requests
let lastContactRequest = 0;
const CONTACT_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests contacts from the server (Arma 3) with debouncing
 */
function requestContacts() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastContactRequest < CONTACT_REQUEST_COOLDOWN) {
        console.log('Contact request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::contacts",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastContactRequest = now;
        console.log('Requested contacts from server');
    } else {
        console.warn('A3API not available, cannot request contacts');
    }
}

/**
 * Loads contacts into the global state (called by Arma 3)
 * @param {Array} contacts - Array of contact objects from the server
 */
function loadContacts(contacts) {
    try {
        if (Array.isArray(contacts)) {
            const normalizedContacts = normalizeContacts(contacts);
            globalState.setState({
                contacts: normalizedContacts
            });
            console.log(`Loaded ${contacts.length} contacts from server:`, contacts);
        } else {
            console.warn('Invalid contacts data received:', contacts);
        }
    } catch (error) {
        console.error('Error loading contacts:', error);
    }
}

/**
 * Refresh contacts via SQF-triggered UI event
 */
function refreshContacts() {
    try {
        requestContacts();
    } catch (e) {
        console.error('Error refreshing contacts:', e);
    }
}

/**
 * Updates contacts in state (SQF -> JS bridge)
 * @param {Array} contacts
 */
function updateContacts(contacts) {
    try {
        if (Array.isArray(contacts)) {
            const normalizedContacts = normalizeContacts(contacts);
            globalState.setState({ contacts: normalizedContacts });
            // Rebuild message summaries to resolve names if raw present
            rebuildMessageSummariesFromRaw();
            console.log(`Updated contacts from server: ${contacts.length}`);
        } else {
            console.warn('updateContacts: invalid data', contacts);
        }
    } catch (e) {
        console.error('Error in updateContacts:', e);
    }
}

function normalizeContacts(contacts) {
    return contacts
        .filter(contact => contact && typeof contact === 'object')
        .map(contact => {
            const name = contact.name || contact.uid || 'Unknown Player';
            const uid = contact.uid || contact.id || '';
            return {
                ...contact,
                id: uid || contact.phone || name,
                uid,
                name,
                fullName: contact.fullName || name,
                phone: contact.phone || '',
                email: contact.email || '',
                avatar: contact.avatar || getInitials(name),
                online: Boolean(contact.online),
                system: Boolean(contact.system),
                canCall: contact.canCall !== false,
                canMessage: contact.canMessage !== false,
                canEmail: contact.canEmail !== false
            };
        });
}

// Player UID handling
function setPlayerUid(uid) {
    try {
        if (!uid || typeof uid !== 'string') {
            console.warn('setPlayerUid: invalid uid', uid);
            return;
        }
        window.__playerUid = uid;
        globalState.setState({ currentUid: uid });
        // With UID known, we can build summaries
        rebuildMessageSummariesFromRaw();
        // Optionally (re)request messages when UID is set
        requestMessages();
    } catch (e) {
        console.error('Error in setPlayerUid:', e);
    }
}

// Messages: request + update handlers

let lastMessagesRequest = 0;
const MESSAGES_REQUEST_COOLDOWN = 1000;

function requestMessages() {
    const now = Date.now();
    if (now - lastMessagesRequest < MESSAGES_REQUEST_COOLDOWN) return;
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = { event: 'phone::get::messages', data: {} };
        A3API.SendAlert(JSON.stringify(alert));
        lastMessagesRequest = now;
        console.log('Requested messages from server');
    } else {
        console.warn('A3API not available, cannot request messages');
    }
}

/**
 * Updates raw messages from server into state without breaking UI
 * @param {Array} messages
 */
function updateMessages(messages) {
    try {
        if (Array.isArray(messages)) {
            globalState.setState({ rawMessages: messages });
            rebuildMessageSummariesFromRaw();
            console.log(`Updated raw messages: ${messages.length}`);
        } else {
            console.warn('updateMessages: invalid data', messages);
        }
    } catch (e) {
        console.error('Error in updateMessages:', e);
    }
}

/**
 * Updates a specific message thread payload
 * @param {Array} threadMessages
 * @param {string} otherUid
 */
function updateMessageThread(threadMessages, otherUid) {
    try {
        if (!Array.isArray(threadMessages)) {
            console.warn('updateMessageThread: invalid messages', threadMessages);
            return;
        }
        const selectedConversationRaw = { otherUid, messages: threadMessages };
        globalState.setState({ selectedConversationRaw });
        // Update derived selectedConversation as well
        rebuildMessageSummariesFromRaw();
        console.log(`Updated message thread with ${otherUid}: ${threadMessages.length}`);
    } catch (e) {
        console.error('Error in updateMessageThread:', e);
    }
}

/**
 * Append a newly sent message to raw store
 * @param {Object} messageObj
 */
function updateMessageSent(messageObj) {
    try {
        const { rawMessages = [], currentUid = window.__playerUid, selectedConversation } = globalState.getState();
        const next = [...rawMessages, messageObj];
        const otherUid = messageObj.from === currentUid ? messageObj.to : messageObj.from;
        const statePatch = { rawMessages: next };
        if (selectedConversation && selectedConversation.id === otherUid) {
            statePatch.selectedConversationRaw = {
                otherUid,
                messages: next.filter(message =>
                    (message.from === currentUid && message.to === otherUid) ||
                    (message.from === otherUid && message.to === currentUid)
                )
            };
        }
        globalState.setState(statePatch);
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageSent:', e);
    }
}

/**
 * Append a newly received message to raw store
 * @param {Object} messageObj
 */
function updateMessageReceived(messageObj) {
    try {
        const { rawMessages = [], currentUid = window.__playerUid, selectedConversation } = globalState.getState();
        const next = [...rawMessages, messageObj];
        const otherUid = messageObj.from === currentUid ? messageObj.to : messageObj.from;
        const statePatch = { rawMessages: next };
        if (selectedConversation && selectedConversation.id === otherUid) {
            statePatch.selectedConversationRaw = {
                otherUid,
                messages: next.filter(message =>
                    (message.from === currentUid && message.to === otherUid) ||
                    (message.from === otherUid && message.to === currentUid)
                )
            };
        }
        globalState.setState(statePatch);
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageReceived:', e);
    }
}

/**
 * Mark message read in raw store by id
 * @param {string} messageId
 */
function updateMessageRead(messageId) {
    try {
        const { rawMessages = [] } = globalState.getState();
        const updated = rawMessages.map(m => (m && m.id === messageId ? { ...m, read: true } : m));
        globalState.setState({ rawMessages: updated });
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageRead:', e);
    }
}

/**
 * Remove a message from the local phone state after server delete succeeds
 * @param {string} messageId
 */
function updateMessageDeleted(messageId) {
    try {
        const { rawMessages = [], selectedConversationRaw = null } = globalState.getState();
        const nextRawMessages = rawMessages.filter(message => message && message.id !== messageId);
        const statePatch = { rawMessages: nextRawMessages };

        if (selectedConversationRaw && Array.isArray(selectedConversationRaw.messages)) {
            statePatch.selectedConversationRaw = {
                ...selectedConversationRaw,
                messages: selectedConversationRaw.messages.filter(message => message && message.id !== messageId)
            };
        }

        globalState.setState(statePatch);
        rebuildMessageSummariesFromRaw();
    } catch (e) {
        console.error('Error in updateMessageDeleted:', e);
    }
}

// Transform raw message payloads into UI-friendly summary and thread structures
function rebuildMessageSummariesFromRaw() {
    try {
        const state = globalState.getState();
        const { rawMessages = [], contacts = [], currentUid = window.__playerUid, selectedConversationRaw } = state;
        if (!Array.isArray(rawMessages) || !currentUid) {
            // Nothing to do until we have both raw data and the player's UID
            return;
        }

        // Build contact lookup map by uid
        const contactByUid = new Map();
        contacts.forEach(c => { if (c && c.uid) contactByUid.set(c.uid, c); });

        // Group messages by other participant
        const threadsMap = new Map();
        for (const m of rawMessages) {
            if (!m) continue;
            const from = m.from;
            const to = m.to;
            const otherUid = from === currentUid ? to : from;
            if (!threadsMap.has(otherUid)) threadsMap.set(otherUid, []);
            threadsMap.get(otherUid).push(m);
        }

        // Helper to convert timestamp to Date
        const toJsDate = (t) => {
            if (t instanceof Date) return t;
            if (typeof t === 'number') {
                // serverTime is seconds; convert
                return new Date(t * 1000);
            }
            // Fallback parse
            const parsed = Date.parse(t);
            return isNaN(parsed) ? new Date() : new Date(parsed);
        };

        // Build UI message summaries
        const uiMessages = [];
        for (const [otherUid, arr] of threadsMap.entries()) {
            // Sort by timestamp ascending
            const sorted = [...arr].sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
            const last = sorted[sorted.length - 1];
            const contact = contactByUid.get(otherUid) || { name: otherUid, uid: otherUid };

            const conversation = sorted.map((msg, idx) => ({
                id: msg.id || idx,
                text: msg.message || msg.text || '',
                sender: msg.from === currentUid ? 'user' : 'contact',
                timestamp: toJsDate(msg.timestamp)
            }));

            uiMessages.push({
                id: otherUid,
                contactId: otherUid,
                contactName: contact.name || otherUid,
                canMessage: contact.canMessage !== false,
                lastMessage: (last && (last.message || last.text)) || '',
                timestamp: toJsDate(last && last.timestamp),
                unread: arr.filter(m => m.read === false && m.to === currentUid).length || 0,
                conversation
            });
        }

        // Sort conversations by last timestamp desc for UI list
        uiMessages.sort((a, b) => (b.timestamp?.getTime?.() || 0) - (a.timestamp?.getTime?.() || 0));

        const nextState = { messages: uiMessages };

        // If we have a selected raw thread, map it to selectedConversation too
        if (selectedConversationRaw && selectedConversationRaw.otherUid) {
            const thread = threadsMap.get(selectedConversationRaw.otherUid) || selectedConversationRaw.messages || [];
            const contact = contactByUid.get(selectedConversationRaw.otherUid) || { name: selectedConversationRaw.otherUid };
            nextState.selectedConversation = {
                id: selectedConversationRaw.otherUid,
                contactId: selectedConversationRaw.otherUid,
                contactName: contact.name,
                canMessage: contact.canMessage !== false,
                lastMessage: thread.length ? (thread[thread.length - 1].message || thread[thread.length - 1].text) : '',
                timestamp: thread.length ? toJsDate(thread[thread.length - 1].timestamp) : new Date(),
                unread: thread.filter(m => m.read === false && m.to === currentUid).length || 0,
                conversation: thread.map((msg, idx) => ({
                    id: msg.id || idx,
                    text: msg.message || msg.text || '',
                    sender: msg.from === currentUid ? 'user' : 'contact',
                    timestamp: toJsDate(msg.timestamp)
                }))
            };
        }

        globalState.setState(nextState);
    } catch (e) {
        console.error('Error rebuilding message summaries:', e);
    }
}

// Emails: request + update handlers

let lastEmailsRequest = 0;
const EMAILS_REQUEST_COOLDOWN = 1000;

function requestEmails() {
    const now = Date.now();
    if (now - lastEmailsRequest < EMAILS_REQUEST_COOLDOWN) return;
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = { event: 'phone::get::emails', data: {} };
        A3API.SendAlert(JSON.stringify(alert));
        lastEmailsRequest = now;
        console.log('Requested emails from server');
    } else {
        console.warn('A3API not available, cannot request emails');
    }
}

function normalizeEmails(emails) {
    if (!Array.isArray(emails)) return [];

    const byId = new Map();
    emails
        .filter((email) => email && typeof email === 'object')
        .forEach((email) => {
            const id = email.id || `${email.from || ''}:${email.to || ''}:${email.timestamp || ''}:${email.subject || ''}`;
            byId.set(id, {
                id,
                from: email.from || '',
                to: email.to || '',
                subject: email.subject || '',
                body: email.body || '',
                timestamp: email.timestamp || '',
                read: !!email.read
            });
        });

    return Array.from(byId.values()).sort((left, right) => {
        const leftTime = new Date(left.timestamp).getTime() || 0;
        const rightTime = new Date(right.timestamp).getTime() || 0;
        return rightTime - leftTime;
    });
}

/**
 * Replace emails in state
 * @param {Array} emails
 */
function updateEmails(emails) {
    try {
        if (Array.isArray(emails)) {
            globalState.setState({ emails: normalizeEmails(emails) });
            console.log(`Updated emails: ${emails.length}`);
        } else {
            console.warn('updateEmails: invalid data', emails);
        }
    } catch (e) {
        console.error('Error in updateEmails:', e);
    }
}

/**
 * Append a newly sent email to state
 * @param {Object} emailObj
 */
function updateEmailSent(emailObj) {
    try {
        const { emails = [] } = globalState.getState();
        globalState.setState({ emails: normalizeEmails([emailObj, ...emails]) });
    } catch (e) {
        console.error('Error in updateEmailSent:', e);
    }
}

/**
 * Append a newly received email to state
 * @param {Object} emailObj
 */
function updateEmailReceived(emailObj) {
    try {
        const { emails = [] } = globalState.getState();
        globalState.setState({ emails: normalizeEmails([emailObj, ...emails]) });
    } catch (e) {
        console.error('Error in updateEmailReceived:', e);
    }
}

/**
 * Mark email read in state by id
 * @param {string} emailId
 */
function updateEmailRead(emailId) {
    try {
        const { emails = [], selectedEmail = null } = globalState.getState();
        const updated = emails.map(e => (e && e.id === emailId ? { ...e, read: true } : e));
        globalState.setState({
            emails: updated,
            selectedEmail: selectedEmail && selectedEmail.id === emailId ? { ...selectedEmail, read: true } : selectedEmail
        });
    } catch (e) {
        console.error('Error in updateEmailRead:', e);
    }
}

/**
 * Remove an email from the local phone state after server delete succeeds
 * @param {string} emailId
 */
function updateEmailDeleted(emailId) {
    try {
        const { emails = [], selectedEmail = null } = globalState.getState();
        globalState.setState({
            emails: emails.filter(email => email && email.id !== emailId),
            selectedEmail: selectedEmail && selectedEmail.id === emailId ? null : selectedEmail
        });
    } catch (e) {
        console.error('Error in updateEmailDeleted:', e);
    }
}

// Debounce variables for notes requests
let lastNotesRequest = 0;
const NOTES_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests notes from the server (Arma 3) with debouncing
 */
function requestNotes() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastNotesRequest < NOTES_REQUEST_COOLDOWN) {
        console.log('Notes request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::notes",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastNotesRequest = now;
        console.log('Requested notes from server');
    } else {
        console.warn('A3API not available, cannot request notes');
    }
}

/**
 * Loads notes into the global state (called by Arma 3)
 * @param {Array} notes - Array of note objects from the server
 */
function loadNotes(notes) {
    try {
        if (Array.isArray(notes)) {
            // Sort notes by updated date (newest first)
            const sortedNotes = notes.sort((a, b) => {
                const dateA = new Date(a.updatedAt || a.createdAt);
                const dateB = new Date(b.updatedAt || b.createdAt);
                return dateB - dateA;
            });

            // Update global state with loaded notes
            globalState.setState({
                notes: sortedNotes
            });
            console.log(`Loaded ${notes.length} notes from server:`, notes);
        } else {
            console.warn('Invalid notes data received:', notes);
        }
    } catch (error) {
        console.error('Error loading notes:', error);
    }
}

/**
 * Saves a note to the server (Arma 3)
 * @param {Object} note - Note object to save
 */
function saveNote(note) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::note",
            "data": note
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved note to server:', note);
    } else {
        console.warn('A3API not available, cannot save note');
    }
}

/**
 * Deletes a note from the server (Arma 3)
 * @param {string} noteId - ID of the note to delete
 */
function deleteNote(noteId) {
    if (!noteId) {
        console.error('Cannot delete note: no ID provided');
        return;
    }

    try {
        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            const alert = {
                "event": "phone::delete::note",
                "data": { id: noteId }
            };
            A3API.SendAlert(JSON.stringify(alert));
        } else {
            console.warn('A3API not available, cannot delete note. A3API type:', typeof A3API);
            if (typeof A3API !== 'undefined') {
                console.log('A3API object:', A3API);
                console.log('A3API.SendAlert available:', !!A3API.SendAlert);
            }
        }
    } catch (error) {
        console.error('Error in deleteNote function:', error);
    }
}

// Debounce variables for events requests
let lastEventsRequest = 0;
const EVENTS_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Request events from the server (Arma 3) with debouncing
 */
function requestCalendarEvents() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastEventsRequest < EVENTS_REQUEST_COOLDOWN) {
        console.log('Events request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::events",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastNotesRequest = now;
        console.log('Requested events from server');
    } else {
        console.warn('A3API not available, cannot request events');
    }
}

/**
 * Loads calendar events into the global state (called by Arma 3)
 * @param {Array} events - Array of calendar event objects from the server
 */
function loadCalendarEvents(events) {
    try {
        if (Array.isArray(events)) {
            globalState.setState({
                events: events
            });
            console.log(`Loaded ${events.length} calendar events from server:`, events);
        } else {
            console.warn('Invalid calendar events data received:', events);
        }
    } catch (error) {
        console.error('Error loading calendar events:', error);
    }
}

/**
 * Saves a calendar event to the server (Arma 3)
 * @param {Object} event - Event object to save
 */
function saveCalendarEvent(event) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::event",
            "data": event
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved calendar event to server:', event);
    } else {
        console.warn('A3API not available, cannot save calendar event');
    }
}

/**
 * Deletes a calendar event from the server (Arma 3)
 * @param {string} eventId - ID of the event to delete
 */
function deleteCalendarEvent(eventId) {
    if (!eventId) {
        console.error('Cannot delete calendar event: no ID provided');
        return;
    }

    try {
        if (typeof A3API !== 'undefined' && A3API.SendAlert) {
            const alert = {
                "event": "phone::delete::event",
                "data": { id: eventId }
            };
            A3API.SendAlert(JSON.stringify(alert));
        } else {
            console.warn('A3API not available, cannot delete calendar event.');
        }
    } catch (error) {
        console.error('Error in deleteCalendarEvent function:', error);
    }
}

// Debounce variables for world clocks requests
let lastWorldClocksRequest = 0;
const WORLD_CLOCKS_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests world clocks from the server (Arma 3) with debouncing
 */
function requestWorldClocks() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastWorldClocksRequest < WORLD_CLOCKS_REQUEST_COOLDOWN) {
        console.log('World clocks request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::clocks",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastWorldClocksRequest = now;
        console.log('Requested world clocks from server');
    } else {
        console.warn('A3API not available, cannot request world clocks');
    }
}

/**
 * Loads world clocks into the global state (called by Arma 3)
 * @param {Array} worldClocks - Array of world clock objects from the server
 */
function loadWorldClocks(worldClocks) {
    try {
        if (Array.isArray(worldClocks)) {
            // Update global state with loaded world clocks
            globalState.setState({
                worldClocks: worldClocks
            });
            console.log(`Loaded ${worldClocks.length} world clocks from server:`, worldClocks);
        } else {
            console.warn('Invalid world clocks data received:', worldClocks);
        }
    } catch (error) {
        console.error('Error loading world clocks:', error);
    }
}

/**
 * Saves a world clock to the server (Arma 3)
 * @param {Object} worldClock - World clock object to save
 */
function saveWorldClock(worldClock) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::clock",
            "data": worldClock
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved world clock to server:', worldClock);
    } else {
        console.warn('A3API not available, cannot save world clock');
    }
}

/**
 * Deletes a world clock from the server (Arma 3)
 * @param {string} clockId - ID of the world clock to delete
 */
function deleteWorldClock(clockId) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::delete::clock",
            "data": { id: clockId }
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Deleted world clock from server:', clockId);
    } else {
        console.warn('A3API not available, cannot delete world clock');
    }
}

// Debounce variables for alarms requests
let lastAlarmsRequest = 0;
const ALARMS_REQUEST_COOLDOWN = 1000; // 1 second cooldown

/**
 * Requests alarms from the server (Arma 3) with debouncing
 */
function requestAlarms() {
    const now = Date.now();

    // Check if we're in cooldown period
    if (now - lastAlarmsRequest < ALARMS_REQUEST_COOLDOWN) {
        console.log('Alarms request ignored - too frequent');
        return;
    }

    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::get::alarms",
            "data": {}
        };
        A3API.SendAlert(JSON.stringify(alert));
        lastAlarmsRequest = now;
        console.log('Requested alarms from server');
    } else {
        console.warn('A3API not available, cannot request alarms');
    }
}

/**
 * Loads alarms into the global state (called by Arma 3)
 * @param {Array} alarms - Array of alarm objects from the server
 */
function loadAlarms(alarms) {
    try {
        if (Array.isArray(alarms)) {
            // Update global state with loaded alarms
            globalState.setState({
                alarms: alarms
            });
            console.log(`Loaded ${alarms.length} alarms from server:`, alarms);
        } else {
            console.warn('Invalid alarms data received:', alarms);
        }
    } catch (error) {
        console.error('Error loading alarms:', error);
    }
}

/**
 * Saves an alarm to the server (Arma 3)
 * @param {Object} alarm - Alarm object to save
 */
function saveAlarm(alarm) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::save::alarm",
            "data": alarm
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Saved alarm to server:', alarm);
    } else {
        console.warn('A3API not available, cannot save alarm');
    }
}

/**
 * Deletes an alarm from the server (Arma 3)
 * @param {string} alarmId - ID of the alarm to delete
 */
function deleteAlarm(alarmId) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::delete::alarm",
            "data": { id: alarmId }
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Deleted alarm from server:', alarmId);
    } else {
        console.warn('A3API not available, cannot delete alarm');
    }
}

/**
 * Toggles an alarm on/off on the server (Arma 3)
 * @param {string} alarmId - ID of the alarm to toggle
 */
function toggleAlarm(alarmId) {
    if (typeof A3API !== 'undefined' && A3API.SendAlert) {
        const alert = {
            "event": "phone::toggle::alarm",
            "data": { id: alarmId }
        };
        A3API.SendAlert(JSON.stringify(alert));
        console.log('Toggled alarm on server:', alarmId);
    } else {
        console.warn('A3API not available, cannot toggle alarm');
    }
}

// Handle any uncaught errors
window.addEventListener('error', (event) => {
    console.error('Uncaught error:', event.error);
});

// Export the initialization function and all API functions to global scope
window.initializeApp = initializeApp;
window.setTheme = setTheme;
window.requestContacts = requestContacts;
window.loadContacts = loadContacts;
window.refreshContacts = refreshContacts;
window.updateContacts = updateContacts;
window.setPlayerUid = setPlayerUid;
// Messages
window.requestMessages = requestMessages;
window.updateMessages = updateMessages;
window.updateMessageThread = updateMessageThread;
window.updateMessageSent = updateMessageSent;
window.updateMessageReceived = updateMessageReceived;
window.updateMessageRead = updateMessageRead;
window.updateMessageDeleted = updateMessageDeleted;
// Emails
window.requestEmails = requestEmails;
window.updateEmails = updateEmails;
window.updateEmailSent = updateEmailSent;
window.updateEmailReceived = updateEmailReceived;
window.updateEmailRead = updateEmailRead;
window.updateEmailDeleted = updateEmailDeleted;
window.requestNotes = requestNotes;
window.loadNotes = loadNotes;
window.saveNote = saveNote;
window.deleteNote = deleteNote;
window.requestCalendarEvents = requestCalendarEvents;
window.loadCalendarEvents = loadCalendarEvents;
window.saveCalendarEvent = saveCalendarEvent;
window.deleteCalendarEvent = deleteCalendarEvent;
window.requestWorldClocks = requestWorldClocks;
window.loadWorldClocks = loadWorldClocks;
window.saveWorldClock = saveWorldClock;
window.deleteWorldClock = deleteWorldClock;
window.requestAlarms = requestAlarms;
window.loadAlarms = loadAlarms;
window.saveAlarm = saveAlarm;
window.deleteAlarm = deleteAlarm;
window.toggleAlarm = toggleAlarm;
