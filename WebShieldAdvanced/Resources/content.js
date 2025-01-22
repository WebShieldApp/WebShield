// content.js
(() => {
  const LOG_PREFIX = "[WebShield Advanced]";

  /**
   * Executes code in the context of the page via new script tag and text content.
   * @param code String of scripts to be executed
   * @returns {boolean} Returns true if code was executed, otherwise returns false
   */
  const executeScriptsViaTextContent = (code) => {
    const scriptTag = document.createElement("script");
    scriptTag.setAttribute("type", "text/javascript");
    scriptTag.textContent = code;
    const parent = document.head || document.documentElement;
    parent.appendChild(scriptTag);
    if (scriptTag.parentNode) {
      scriptTag.parentNode.removeChild(scriptTag);
      return false;
    }
    return true;
  };

  /**
   * Executes code in the context of page via new script tag and blob. We use this way as fallback,
   * if we fail to inject via textContent
   * @param code String of scripts to be executed
   * @returns {boolean} Returns true if code was executed, otherwise returns false.
   */
  const executeScriptsViaBlob = (code) => {
    const blob = new Blob([code], { type: "text/javascript" });
    const url = URL.createObjectURL(blob);
    const scriptTag = document.createElement("script");
    scriptTag.src = url;
    const parent = document.head || document.documentElement;
    parent.appendChild(scriptTag);
    URL.revokeObjectURL(url);
    if (scriptTag.parentNode) {
      scriptTag.parentNode.removeChild(scriptTag);
      return false;
    }
    return true;
  };

  /**
   * Execute scripts in a page context and cleanup itself when execution completes
   * @param scripts Array of scripts to execute
   */
  const executeScripts = (scripts = []) => {
    scripts.unshift("( function () { try {");
    // we use this script detect if the script was applied,
    // if the script tag was removed, then it means that code was applied, otherwise no
    scripts.push(`;document.currentScript.remove();`);
    scripts.push(
      "} catch (ex) { console.error('Error executing WebShield (script) js: ' + ex); } })();",
    );
    const code = scripts.join("\r\n");
    if (!executeScriptsViaTextContent(code)) {
      console.log(`${LOG_PREFIX} Unable to inject via text content`);
      if (!executeScriptsViaBlob(code)) {
        console.log(`${LOG_PREFIX} Unable to inject via blob`);
      }
    }
  };

  /**
   * Applies JS injections.
   * @param scripts Array with JS scripts
   */
  const applyScripts = (scripts) => {
    if (!scripts || scripts.length === 0) {
      return;
    }

    console.log(`${LOG_PREFIX} scripts length: ${scripts.length}`);
    executeScripts(scripts.reverse());
  };

  /**
   * Protects specified style element from changes to the current document
   * Add a mutation observer, which is adds our rules again if it was removed
   *
   * @param protectStyleEl protected style element
   */
  const protectStyleElementContent = function (protectStyleEl) {
    const MutationObserver =
      window.MutationObserver || window.WebKitMutationObserver;
    if (!MutationObserver) {
      return;
    }
    /* observer, which observe protectStyleEl inner changes, without deleting styleEl */
    const innerObserver = new MutationObserver((mutations) => {
      for (let i = 0; i < mutations.length; i += 1) {
        const m = mutations[i];
        if (
          protectStyleEl.hasAttribute("mod") &&
          protectStyleEl.getAttribute("mod") === "inner"
        ) {
          protectStyleEl.removeAttribute("mod");
          break;
        }

        protectStyleEl.setAttribute("mod", "inner");
        let isProtectStyleElModified = false;

        /**
         * further, there are two mutually exclusive situations: either there were changes
         * the text of protectStyleEl, either there was removes a whole child "text"
         * element of protectStyleEl we'll process both of them
         */
        if (m.removedNodes.length > 0) {
          for (let j = 0; j < m.removedNodes.length; j += 1) {
            isProtectStyleElModified = true;
            protectStyleEl.appendChild(m.removedNodes[j]);
          }
        } else if (m.oldValue) {
          isProtectStyleElModified = true;
          protectStyleEl.textContent = m.oldValue;
        }

        if (!isProtectStyleElModified) {
          protectStyleEl.removeAttribute("mod");
        }
      }
    });

    innerObserver.observe(protectStyleEl, {
      childList: true,
      characterData: true,
      subtree: true,
      characterDataOldValue: true,
    });
  };

  /**
   * Applies css stylesheet
   * @param styleSelectors Array of stylesheets or selectors
   */
  const applyCss = (styleSelectors) => {
    if (!styleSelectors || !styleSelectors.length) {
      return;
    }

    console.log(`${LOG_PREFIX} css length: ${styleSelectors.length}`);

    const styleElement = document.createElement("style");
    styleElement.setAttribute("type", "text/css");
    (document.head || document.documentElement).appendChild(styleElement);

    for (const selector of styleSelectors.map((s) => s.trim())) {
      styleElement.sheet.insertRule(selector);
    }

    protectStyleElementContent(styleElement);
  };

  /**
   * Applies Extended Css stylesheet
   *
   * @param extendedCss Array with ExtendedCss stylesheets
   */
  const applyExtendedCss = (extendedCss) => {
    if (!extendedCss || !extendedCss.length) {
      return;
    }

    console.log(`${LOG_PREFIX} extended css length: ${extendedCss.length}`);
    const cssRules = extendedCss
      .filter((s) => s.length > 0)
      .map((s) => s.trim())
      .map((s) => {
        return s[s.length - 1] !== "}" ? `${s} {display:none!important;}` : s;
      });
    const extCss = new ExtendedCss({ cssRules });
    extCss.apply();
  };

  /**
   * Applies scriptlets
   *
   * @param scriptletsData Array with scriptlets data
   */
  const applyScriptlets = (scriptletsData) => {
    if (!scriptletsData || !scriptletsData.length) {
      return;
    }

    console.log(`${LOG_PREFIX} scriptlets length: ${scriptletsData.length}`);
    const scriptletExecutableScripts = scriptletsData.map((s) => {
      const param = JSON.parse(s);
      param.engine = "safari-extension";
      param.verbose = true;

      let code = "";
      try {
        code = scriptlets && scriptlets.invoke(param);
      } catch (e) {
        console.log(`${LOG_PREFIX}`, e.message);
      }
      return code;
    });

    executeScripts(scriptletExecutableScripts);
  };

  /**
   * Applies injected script and css
   *
   * @param data
   */
  const applyAdvancedBlockingData = (data) => {
    console.log(`Applying scripts and css..`);
    console.log(`Frame url: ${window.location.href}`);

    applyScripts(data.scripts);
    applyCss(data.cssInject);
    applyExtendedCss(data.cssExtended);
    applyScriptlets(data.scriptlets);

    console.log(`Applying scripts and css - done`);
  };

  // Simplified request handler
  const requestBlockingData = async (url) => {
    try {
      const response = await browser.runtime.sendMessage({
        action: "getAdvancedBlockingData",
        url: url,
        fromBeginning: true,
      });

      if (response?.error) throw new Error(response.error);
      if (!response?.data) throw new Error("No data received");

      return typeof response.data === "string"
        ? JSON.parse(response.data)
        : response.data;
    } catch (error) {
      console.error(`${LOG_PREFIX} Request failed:`, error);
      throw error;
    }
  };

  // Initialization
  const initializeAdvancedBlocking = async () => {
    if (!document.documentElement || !location.protocol.startsWith("http"))
      return;

    try {
      const data = await requestBlockingData(location.href);
      if (data) applyAdvancedBlockingData(data);
    } catch (error) {
      console.error(`${LOG_PREFIX} Initialization failed:`, error);
    }
  };

  // Start the process
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeAdvancedBlocking);
  } else {
    initializeAdvancedBlocking();
  }

  //
  // if (document.timeline) {
  //   document.timeline.phase.then((phase) => {
  //     if (phase === "before-paint") {
  //       initializeAdvancedBlocking();
  //     }
  //   });
  // }
  //
  // if (document.readyState === "loading") {
  //   const observer = new MutationObserver((mutations, obs) => {
  //     initializeAdvancedBlocking();
  //     obs.disconnect();
  //   });

  //   observer.observe(document, {
  //     childList: true,
  //     subtree: true,
  //   });
  // } else {
  //   initializeAdvancedBlocking();
  // }
  //
  // (function () {
  //   if (document.documentElement) {
  //     initializeAdvancedBlocking();
  //   } else {
  //     // Super early injection - before documentElement exists
  //     new MutationObserver((mutations, obs) => {
  //       if (document.documentElement) {
  //         initializeAdvancedBlocking();
  //         obs.disconnect();
  //       }
  //     }).observe(document, {
  //       childList: true,
  //     });
  //   }
  // })();
  //

  // function runAfterDOMAndCSSOM() {
  //   // Check if the document is fully ready (including CSSOM)
  //   if (document.readyState === "complete") {
  //     initializeAdvancedBlocking();
  //   } else {
  //     document.addEventListener(
  //       "readystatechange",
  //       () => {
  //         if (document.readyState === "complete") {
  //           initializeAdvancedBlocking();
  //         }
  //       },
  //       { once: true },
  //     );
  //   }
  // }

  // if (document.readyState === "loading") {
  //   document.addEventListener("DOMContentLoaded", runAfterDOMAndCSSOM);
  // } else {
  //   runAfterDOMAndCSSOM();
  // }
})();
