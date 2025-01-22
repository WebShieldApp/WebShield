// content.js
(() => {
    const LOG_PREFIX = '(WebShield Advanced)';
    const docHead = document.head || document.documentElement; // Cache head element

    const executeScript = (code) => {
        const script = document.createElement("script");
        script.textContent = code;
        docHead.appendChild(script);
        script.remove();
    };

    const applyScripts = (scripts, scriptletsData) => {
        if (!scripts?.length && !scriptletsData?.length)
            return;

        console.log(
            `${LOG_PREFIX} Applying ${scripts.length} script injections and ${scriptletsData.length} scriptlets...`);

        const scriptletExecutableScripts = scriptletsData.map((s) => {
            const param = {...JSON.parse(s), engine : "web-extension"};
            try {
                return scriptlets?.invoke(param) || "";
            } catch (e) {
                console.error(`${LOG_PREFIX} Error in applyScriptlets:`, e);
                return "";
            }
        });

        const combinedCode = [
            "(function () { try {",
            ...scripts.reverse(),
            ...scriptletExecutableScripts,
            "} catch (ex) { console.error('Error executing WebShield js: ' + ex); } })();",
        ].join("\n");

        executeScript(combinedCode);
    };

    const protectStyleElementContent = (styleEl) => {
        const MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
        if (!MutationObserver)
            return;

        new MutationObserver((mutations) => {
            for (const m of mutations) {
                // Mutation observer is only used for protection, so if style element is already
                // modified, then don't modify it
                if (styleEl.hasAttribute("mod")) {
                    return;
                }
                styleEl.setAttribute("mod", "true");

                if (m.removedNodes.length > 0) {
                    styleEl.append(...m.removedNodes);
                } else if (m.oldValue) {
                    styleEl.textContent = m.oldValue;
                } else {
                    styleEl.removeAttribute("mod");
                }
            }
        }).observe(styleEl, {
            childList : true,
            characterData : true,
            subtree : true,
            characterDataOldValue : true,
        });
    };

    const applyCss = (styleSelectors, extendedCss) => {
        if (!styleSelectors?.length && !extendedCss?.length)
            return;

        console.log(`${LOG_PREFIX} Applying ${styleSelectors.length} CSS stylesheets and ${
            extendedCss.length} extended CSS stylesheets...`);

        const combinedCss = [
            ...styleSelectors,
            ...extendedCss.filter(Boolean)
                .map((s) => s.trim())
                .map((s) => (s.endsWith("}") ? s : `${s} {display:none!important;}`)),
        ].join("\n");

        const styleElement = document.createElement("style");
        styleElement.textContent = combinedCss;
        docHead.appendChild(styleElement);
        protectStyleElementContent(styleElement);
    };

    const applyAdvancedBlockingData = (data) => {
        console.log(`${LOG_PREFIX} Applying scripts and css for ${window.location.href}...`);

        // These apply functions don't need to wait for each other.
        applyScripts(data.scripts, data.scriptlets);
        applyCss(data.cssInject, data.cssExtended);

        console.log(`${LOG_PREFIX} Applying scripts and css - done`);
    };

    const requestBlockingData = async () => {
        console.log(`${LOG_PREFIX} Requesting advanced blocking data...`);
        console.log(`${LOG_PREFIX} Current URL:`, window.location.href);

        try {
            const response =
                await chrome.runtime.sendMessage({action : 'getAdvancedBlockingData', url : window.location.href});

            console.log(`${LOG_PREFIX} Raw response from background:`, response);

            if (!response?.data) {
                throw new Error('Invalid response format');
            }

            console.log(`${LOG_PREFIX} Parsed data:`, response.data);
            return response;

        } catch (error) {
            console.error(`${LOG_PREFIX} Error requesting blocking data:`, error);
            throw error;
        }
    };

    const initializeAdvancedBlocking = async () => {
        if (!(document instanceof HTMLDocument) || !window.location.href?.startsWith('http')) {
            return;
        }

        try {
            const response = await requestBlockingData();

            if (!response?.data) {
                return;
            }

            await applyAdvancedBlockingData(response.data);
            console.log(`${LOG_PREFIX} Successfully processed blocking data`);

        } catch (error) {
            console.error(`${LOG_PREFIX} Failed to process blocking data:`, error);
        }
    };

    // Execute immediately
    initializeAdvancedBlocking();
})();
