// background.js
const NATIVE_APP_ID = 'dev.arjuna.WebShield.Advanced';
const LOG_PREFIX = '(WebShield Advanced)';

// Utility functions
const logMessage = (message, ...args) => console.log(`${LOG_PREFIX} ${message}`, ...args);
const logError = (message, ...args) => console.error(`${LOG_PREFIX} ${message}`, ...args);

// Handle native messaging
const getNativeBlockingData = async (url) => {
    try {
        const response =
            await browser.runtime.sendNativeMessage(NATIVE_APP_ID, {action : 'getAdvancedBlockingData', url});

        if (!response?.data) {
            throw new Error('Invalid or empty response from native app');
        }

        return {data : JSON.parse(response.data), verbose : response.verbose};
    } catch (error) {
        logError('Native messaging error:', error);
        throw error;
    }
};

// Message handler map
const messageHandlers = {
    async getAdvancedBlockingData(message) {
        logMessage('Processing blocking data for URL:', message.url);
        return await getNativeBlockingData(message.url);
    }
};

// Main message listener
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    logMessage('Message received:', {message, sender});

    const handler = messageHandlers[message.action];
    if (!handler) {
        logError('Unknown action:', message.action);
        return false;
    }

    // Execute handler and handle response
    handler(message).then(response => sendResponse(response)).catch(error => sendResponse({error : error.message}));

    return true; // Keep message channel open for async response
});
