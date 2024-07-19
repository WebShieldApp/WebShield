//
//  t.js
//  WebShield
//
//  Created by Arjun on 2024-07-13.
//
/* global safari, ExtendedCss */
(() => {
    const logMessage = (verbose, message) => {
        verbose && console.log(`(WebShield Extra) ${message}`);
    };

    const executeScript = async (code) => {
        const executeViaTextContent = () => {
            const script = document.createElement('script');
            script.textContent = code;
            (document.head || document.documentElement).appendChild(script);
            script.remove();
            return !script.parentNode;
        };

        const executeViaBlob = () => {
            const blob = new Blob([ code ], {type : 'text/javascript'});
            const url = URL.createObjectURL(blob);
            const script = document.createElement('script');
            script.src = url;
            (document.head || document.documentElement).appendChild(script);
            URL.revokeObjectURL(url);
            script.remove();
            return !script.parentNode;
        };

        return executeViaTextContent() || executeViaBlob();
    };

    const executeScripts = async (scripts = [], verbose) => {
        logMessage(verbose, "Executing scripts...");
        const code = [
            '(function () { try {', ...scripts,
            ';document.currentScript.remove();',
            "} catch (ex) { console.error('Error executing AG js: ' + ex); } })();"
        ].join('\n');

        if (!await executeScript(code)) {
            logMessage(verbose, 'Unable to inject scripts');
        }
    };

    const applyScripts = async (scripts, verbose) => {
        if (!scripts?.length)
            return;
        logMessage(verbose, `Applying ${scripts.length} script injections...`);
        await executeScripts(scripts.reverse(), verbose);
    };

    const protectStyleElementContent = (styleEl) => {
        const MutationObserver =
            window.MutationObserver || window.WebKitMutationObserver;
        if (!MutationObserver)
            return;

        new MutationObserver((mutations) => {
            for (const m of mutations) {
                if (styleEl.getAttribute('mod') === 'inner') {
                    styleEl.removeAttribute('mod');
                    break;
                }
                styleEl.setAttribute('mod', 'inner');

                if (m.removedNodes.length > 0) {
                    styleEl.append(...m.removedNodes);
                } else if (m.oldValue) {
                    styleEl.textContent = m.oldValue;
                } else {
                    styleEl.removeAttribute('mod');
                }
            }
        }).observe(styleEl, {
            childList : true,
            characterData : true,
            subtree : true,
            characterDataOldValue : true,
        });
    };

    const applyCss = async (styleSelectors, verbose) => {
        if (!styleSelectors?.length)
            return;
        logMessage(verbose,
                   `Applying ${styleSelectors.length} CSS stylesheets...`);

        const styleElement = document.createElement('style');
        styleElement.textContent = styleSelectors.join('\n');
        (document.head || document.documentElement).appendChild(styleElement);
        protectStyleElementContent(styleElement);
    };

    const applyExtendedCss = async (extendedCss, verbose) => {
        if (!extendedCss?.length)
            return;
        logMessage(
            verbose,
            `Applying ${extendedCss.length} extended CSS stylesheets...`);

        const cssRules =
            extendedCss.filter(Boolean)
                .map(s => s.trim())
                .map(s => s.endsWith('}') ? s
                                          : `${s} {display:none!important;}`);

        new ExtendedCss({cssRules}).apply();
    };

    const applyScriptlets = async (scriptletsData, verbose) => {
        if (!scriptletsData?.length)
            return;
        logMessage(verbose, `Applying ${scriptletsData.length} scriptlets...`);

        const scriptletExecutableScripts = scriptletsData.map(s => {
            const param =
                {...JSON.parse(s), engine : "safari-extension", verbose};
            try {
                return scriptlets?.invoke(param) || '';
            } catch (e) {
                logMessage(verbose, e.message);
                return '';
            }
        });

        await executeScripts(scriptletExecutableScripts, verbose);
    };

    const applyAdvancedBlockingData = async (data, verbose) => {
        logMessage(verbose,
                   `Applying scripts and css for ${window.location.href}...`);

        await Promise.all([
            applyScripts(data.scripts, verbose),
            applyCss(data.cssInject, verbose),
            applyExtendedCss(data.cssExtended, verbose),
            applyScriptlets(data.scriptlets, verbose)
        ]);

        logMessage(verbose, 'Applying scripts and css - done');
        safari.self.removeEventListener('message', handleMessage);
    };

    const handleMessage = async ({name, message}) => {
        if (name !== 'advancedBlockingData')
            return;

        try {
            const {data, verbose, url} = message;
            const parsedData = JSON.parse(data);
            const isVerbose = JSON.parse(verbose);

            logMessage(isVerbose, "Received advancedBlockingData message...");
            logMessage(isVerbose, "Message Data:");
            console.log(parsedData)
            if (window.location.href === url) {
                await applyAdvancedBlockingData(parsedData, isVerbose);
            }
        } catch (e) {
            console.error('Error handling message:', e);
        }
    };

    if (document instanceof HTMLDocument &&
        window.location.href?.startsWith('http')) {
        safari.self.addEventListener('message', handleMessage);
        logMessage(true, "Sending getAdvancedBlockingData message...");
        safari.extension.dispatchMessage('getAdvancedBlockingData',
                                         {url : window.location.href});
    }
})();
