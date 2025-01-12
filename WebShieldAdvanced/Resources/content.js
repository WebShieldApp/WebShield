// content.js
(() => {
    const LOG_PREFIX = '(WebShield Advanced)';

    const executeScript = async (code) => {
        const executeViaTextContent = () => {
            const script = document.createElement("script");
            script.textContent = code;
            (document.head || document.documentElement).appendChild(script);
            script.remove();
            return !script.parentNode;
        };

        const executeViaBlob = () => {
            const blob = new Blob([ code ], {type : "text/javascript"});
            const url = URL.createObjectURL(blob);
            const script = document.createElement("script");
            script.src = url;
            (document.head || document.documentElement).appendChild(script);
            URL.revokeObjectURL(url);
            script.remove();
            return !script.parentNode;
        };

        return executeViaTextContent() || executeViaBlob();
    };

    const executeScripts = async (scripts = []) => {
        console.log(`${LOG_PREFIX} Executing scripts...`);
        const code = [
            "(function () { try {",
            ...scripts,
            ";document.currentScript.remove();",
            "} catch (ex) { console.error('Error executing WebShield js: ' + ex); } })();",
        ].join("\n");

        if (!(await executeScript(code))) {
            console.log(`${LOG_PREFIX} Unable to inject scripts`);
        }
    };

    const applyScripts = async (scripts) => {
        if (!scripts?.length)
            return;
        console.log(`${LOG_PREFIX} Applying ${scripts.length} script injections...`);
        await executeScripts(scripts.reverse());
    };

    const protectStyleElementContent = (styleEl) => {
        const MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
        if (!MutationObserver)
            return;

        new MutationObserver((mutations) => {
            for (const m of mutations) {
                if (styleEl.getAttribute("mod") === "inner") {
                    styleEl.removeAttribute("mod");
                    break;
                }
                styleEl.setAttribute("mod", "inner");

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

    const applyCss = async (styleSelectors) => {
        if (!styleSelectors?.length)
            return;
        console.log(`${LOG_PREFIX} Applying ${styleSelectors.length} CSS stylesheets...`);

        const styleElement = document.createElement("style");
        styleElement.textContent = styleSelectors.join("\n");
        (document.head || document.documentElement).appendChild(styleElement);
        protectStyleElementContent(styleElement);
    };

    const applyExtendedCss = async (extendedCss) => {
        if (!extendedCss?.length)
            return;
        console.log(`${LOG_PREFIX} Applying ${extendedCss.length} extended CSS stylesheets...`);

        const cssRules = extendedCss.filter(Boolean)
                             .map((s) => s.trim())
                             .map((s) => (s.endsWith("}") ? s : `${s} {display:none!important;}`));

        new ExtendedCss({cssRules}).apply();
    };

    const applyScriptlets = async (scriptletsData) => {
        if (!scriptletsData?.length)
            return;
        console.log(`${LOG_PREFIX} Applying ${scriptletsData.length} scriptlets...`);

        const scriptletExecutableScripts = scriptletsData.map((s) => {
            const param = {...JSON.parse(s), engine : "web-extension"};
            try {
                return scriptlets?.invoke(param) || "";
            } catch (e) {
                console.error(`${LOG_PREFIX} Error in applyScriptlets:`, e);
                return "";
            }
        });

        await executeScripts(scriptletExecutableScripts);
    };

    const applyAdvancedBlockingData = async (data) => {
        console.log(`${LOG_PREFIX} Applying scripts and css for ${window.location.href}...`);

        await Promise.all([
            applyScripts(data.scripts),
            applyCss(data.cssInject),
            applyExtendedCss(data.cssExtended),
            applyScriptlets(data.scriptlets),
        ]);

        console.log(`${LOG_PREFIX} Applying scripts and css - done`);
    };

    const requestBlockingData = async () => {
        console.log(`${LOG_PREFIX} Requesting advanced blocking data...`);
        console.log(`${LOG_PREFIX} Current URL:`, window.location.href);

        try {
            const response =
                await browser.runtime.sendMessage({action : 'getAdvancedBlockingData', url : window.location.href});

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
