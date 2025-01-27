function isAnyParentHidden(element) {
    while (element) {
        if (window.getComputedStyle(element).display === "none") {
            return true;
        }
        element = element.parentElement;
    }
    return false;
}
