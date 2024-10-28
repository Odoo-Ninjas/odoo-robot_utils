function waitForDisabledAndEnabled(element, enabled) {
    if (!enabled){
        return new Promise((resolve) => {
            resolve();
            return true;
        });
    }
    return new Promise((resolve) => {
        var touched_disabled = false;
        var let_pass = false;
        const observer = new MutationObserver((mutations) => {
            for (let mutation of mutations) {
                if (mutation.attributeName === 'disabled') {
                    // Check if the element is disabled
                    if (element.disabled) {
                        touched_disabled = true;
                        console.log("Element is disabled");
                        // Wait for it to be enabled again
                        const checkEnabled = () => {
                            if (!element.disabled) {
                                console.log("Element is enabled again");
                                observer.disconnect();  // Stop observing once done
                                resolve();
                            } else {
                                // If it's still disabled, check again after a short delay
                                setTimeout(checkEnabled, 100);
                            }
                        };
                        checkEnabled();  // Start checking if it's enabled again
                    }
                }
            }
        });
        // Start observing the element for attribute changes
        observer.observe(element, { attributes: true });
    });

}