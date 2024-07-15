/**
 *
 */
(function() {
var node = document.currentScript;

if (window.AdguardAssistant) {
    console.log("(WebShield Ext) Stopping WebShield Assistant..");
    AdguardAssistant.close();
    console.log("(WebShield Ext) Stopping WebShield Assistant..ok");
} else {
    window.AdguardAssistant = new adguardAssistant();
}

console.log("(WebShield Ext) Starting AdGuard Assistant..");
window.AdguardAssistant.start(null, (rule) => {
    console.log("(WebShield Ext) AdGuard Assistant callback.");

    node.dispatchEvent(new CustomEvent(
        "assistant.runner-response",
        {detail : {"rule" : rule}, "bubbles" : true, "cancelable" : false}));
});
console.log("(WebShield Ext) Starting AdGuard Assistant..ok");
})();
