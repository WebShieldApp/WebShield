// document.addEventListener(
//     "DOMContentLoaded",
//     function(event) { safari.extension.dispatchMessage("Hello World!"); });

/**
 * AdGuard Extension Script
 *
 * This content-script serves some assistant requests.
 */
/* global safari */
(() => {
    const isTopWindow = window.top === window;
    const isHTMLDocument = document instanceof HTMLDocument;

    const handleBlockElement = async () => {
        const assistantId = 'adguard.assistant.embedded';
        const runnerId = 'webshield.zapper.embedded.runner';

        if (!document.getElementById(assistantId)) {
            const script = document.createElement('script');
            Object.assign(script, {
                src : `${safari.extension.baseURI}assistant.embedded.js`,
                id : assistantId,
                charset : 'utf-8'
            });
            document.head.appendChild(script);
        }

        const existingRunner = document.getElementById(`${assistantId}.runner`);
        existingRunner?.remove();

        const runnerScript = document.createElement('script');
        Object.assign(runnerScript, {
            src : `${safari.extension.baseURI}zapper.runner.js`,
            id : runnerId
        });
        runnerScript.addEventListener('zapper.runner-response', (event) => {
            safari.extension.dispatchMessage('ruleResponse', event.detail);
        });
        document.head.appendChild(runnerScript);
    };

    const handleMessage = async ({name}) => {
        try {
            switch (name) {
            case 'blockElementPing':
                safari.extension.dispatchMessage('blockElementPong');
                break;
            case 'blockElement':
                await handleBlockElement();
                break;
            }
        } catch (error) {
            console.error('Error handling message:', error);
        }
    };

    if (isTopWindow) {
        document.addEventListener(
            'DOMContentLoaded',
            () => { safari.self.addEventListener('message', handleMessage); });
    }

    if (isHTMLDocument) {
        const getSubscriptionParams = (urlParams) => {
            const params = new URLSearchParams(urlParams);
            return {title : params.get('title'), url : params.get('location')};
        };

        const onLinkClicked = (event) => {
            if (event.button === 2)
                return;

            const target = event.target.closest('a');
            if (!target)
                return;

            const {protocol, host, pathname, href, search} = target;

            if ((protocol === 'http:' || protocol === 'https:') &&
                (host !== 'subscribe.adblockplus.org' || pathname !== '/')) {
                return;
            }

            if (!/^(abp|adguard):\/+subscribe\/+\?/i.test(href))
                return;

            event.preventDefault();
            event.stopPropagation();

            const urlParams =
                search ? search.slice(1) : href.slice(href.indexOf('?') + 1);
            const {title, url} =
                getSubscriptionParams(urlParams.replace(/&amp;/g, '&'));

            if (!url)
                return;

            safari.extension.dispatchMessage(
                'addFilterSubscription',
                {url : url.trim(), title : (title || url).trim()});
        };

        document.addEventListener('click', onLinkClicked);
    }
})();
