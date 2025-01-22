// background.js
const NATIVE_APP_ID = 'dev.arjuna.WebShield.Advanced';
const LOG_PREFIX = '(WebShield Advanced)';
const CACHE_EXPIRATION_TIME = 60 * 60 * 1000; // 1 hour in milliseconds

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

// Get data from cache
const getCachedBlockingData = async (url) => {
    const data = await browser.storage.local.get(url);
    if (data[url] && (Date.now() - data[url].timestamp < CACHE_EXPIRATION_TIME)) {
        logMessage('Returning cached data for:', url);
        return data[url].cachedData;
    }
    return null;
};

// Store data in cache
const setCachedBlockingData = async (url, data) => {
    await browser.storage.local.set({[url] : {cachedData : data, timestamp : Date.now()}});
    logMessage('Cached data for:', url);
};

// Message handler map
const messageHandlers = {
    getAdvancedBlockingData : async (message, sendResponse) => {
        const url = message.url;
        logMessage('Processing blocking data for URL:', url);

        // Check cache first
        const cachedData = await getCachedBlockingData(url);
        if (cachedData) {
            sendResponse(cachedData);
            return;
        }

        // Get data from native app
        try {
            const data = await getNativeBlockingData(url);
            // Cache the data
            await setCachedBlockingData(url, data);
            sendResponse(data);
        } catch (error) {
            logError('Error fetching blocking data:', error);
            sendResponse({error : error.message});
        }
    }
};

// Main message listener
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    logMessage('Message received:', {message, sender});

    const handler = messageHandlers[message.action];
    if (handler) {
        // Execute handler and handle response
        handler(message, sendResponse);
    } else {
        logError('Unknown action:', message.action);
    }

    return true; // Keep message channel open for async response
});
