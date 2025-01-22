// background.js
const NATIVE_APP_ID = "dev.arjuna.WebShield.Advanced";
const LOG_PREFIX = "[WebShield Advanced]";
const CHUNK_TIMEOUT = 30000; // 30 seconds

const log = {
  info: (msg, ...args) => console.log(`${LOG_PREFIX} ${msg}`, ...args),
  error: (msg, ...args) => console.error(`${LOG_PREFIX} ${msg}`, ...args),
};

// Active chunk accumulators
const chunkAccumulators = new Map();
// Unified message handler
browser.runtime.onMessage.addListener((message, sender) => {
  if (message.action === "getAdvancedBlockingData") {
    return handleBlockingRequest(message, sender);
  }
  return false;
});

async function handleBlockingRequest(message, sender) {
  const { url, fromBeginning } = message;
  const accumulatorKey = `${sender.tab.id}-${url}`;

  try {
    // Initialize accumulator if starting fresh
    if (fromBeginning) {
      chunkAccumulators.set(accumulatorKey, {
        data: "",
        timeout: setTimeout(
          () => cleanupAccumulator(accumulatorKey),
          CHUNK_TIMEOUT,
        ),
      });
    }

    const response = await browser.runtime.sendNativeMessage(NATIVE_APP_ID, {
      action: "getAdvancedBlockingData",
      url: url,
      fromBeginning: fromBeginning,
    });

    if (response.error) throw new Error(response.error);

    return processResponse(response, accumulatorKey);
  } catch (error) {
    cleanupAccumulator(accumulatorKey);
    log.error("Request failed:", error);
    return { error: error.message };
  }
}

function processResponse(response, accumulatorKey) {
  const accumulator = chunkAccumulators.get(accumulatorKey);

  if (!response.chunked) {
    return validateAndParse(response);
  }

  if (accumulator) {
    accumulator.data += response.data;

    if (!response.more) {
      const finalData = accumulator.data;
      cleanupAccumulator(accumulatorKey);
      return validateAndParse({ data: finalData });
    }
  }

  // Return empty response to keep channel open
  return { __chunked: true };
}

function validateAndParse(response) {
  if (!response.data) throw new Error("Empty response from native host");

  try {
    return {
      data: JSON.parse(response.data),
      verbose: response.verbose,
    };
  } catch (e) {
    throw new Error(`JSON parse error: ${e.message}`);
  }
}

function cleanupAccumulator(key) {
  const accumulator = chunkAccumulators.get(key);
  if (accumulator) {
    clearTimeout(accumulator.timeout);
    chunkAccumulators.delete(key);
  }
}
