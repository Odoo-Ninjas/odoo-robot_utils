counter_key = 'robo_counter';
function incrementCounter(value) {
    let counter = localStorage.getItem(counter_key) || 0;
    counter = parseInt(counter) + value;
	localStorage.setItem(counter_key, counter);
}

function resetCounter() {
	localStorage.setItem(counter_key, 0);
}

function getAjaxCounter() {
	return parseInt(localStorage.getItem(counter_key) || 0);
}

// (function() {
//     const originalFetch = window.fetch;
    
//     window.fetch = async function(resource, config) {
// 		incrementCounter(1);
//         const response = await originalFetch(resource, config);
// 		incrementCounter(-1);
// 		console.log(getAjaxCounter() + ' requests in progress');
//         return response;
//     };
// })();

function ignore_counter_url(url) {
	if (url.indexOf("longpolling/poll") >= 0) {
		return true;
	}
	return false;
}

(function() {
	resetCounter();
    const originalOpen = XMLHttpRequest.prototype.open;
    const originalSend = XMLHttpRequest.prototype.send;

    XMLHttpRequest.prototype.open = function(method, url) {
        this._url = url;  // Store the URL for reference
        return originalOpen.apply(this, arguments);
    };

    XMLHttpRequest.prototype.send = function(body) {
        console.log(`Intercepted request to: ${this._url}`);
        // console.log(`Request method: ${this._method}`);
		if (!ignore_counter_url(this._url)) {
			incrementCounter(1);
			console.log(getAjaxCounter() + ' requests in progress');
		}

        this.addEventListener('load', function() {
			if (!ignore_counter_url(this._url)) {
				incrementCounter(-1);
				console.log(getAjaxCounter() + ' requests in progress');
			}
        });

        return originalSend.apply(this, arguments);
    };
})();