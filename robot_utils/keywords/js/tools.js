function isAnyParentHidden(element) {
    while (element) {
        if (window.getComputedStyle(element).display === "none") {
            return true;
        }
        element = element.parentElement;
    }
    return false;
}

async function waitForClass(element, className, timeout = 5000) {
    return new Promise((resolve, reject) => {
        const observer = new MutationObserver(() => {
            if (element.classList.contains(className)) {
                observer.disconnect();
                resolve();
            }
        });

        if (element.classList.contains(className)) {
            resolve();
        }

        observer.observe(element, { attributes: true, attributeFilter: ['class'] });

        setTimeout(() => {
            observer.disconnect();
            reject(new Error(`Timeout: Element did not get class '${className}' within ${timeout}ms`));
        }, timeout);
    });
}
