function highlightElementByXPath(xpath, toggle=true) {
	const color = 'red';
    const elements = document.evaluate(
        xpath,
        document,
        null,
        XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,
        null
    );

    for (let i = 0; i < elements.snapshotLength; i++) {
        const element = elements.snapshotItem(i);
		if (toggle) {
			element.style.backgroundColor = color;
		}
		else {
			element.style.backgroundColor = null;
		}
    }
}

function showTooltipByXPath(xpath, tooltipText) {
    // Find the element using XPath
    const result = document.evaluate(
        xpath,
        document,
        null,
        XPathResult.FIRST_ORDERED_NODE_TYPE,
        null
    );

    const element = result.singleNodeValue;

    if (!element) {
        console.error('No element found for the provided XPath:', xpath);
        return;
    }

    // Create the tooltip element
    const tooltip = document.createElement('div');
    tooltip.textContent = tooltipText;
    tooltip.style.position = 'absolute';
    tooltip.style.backgroundColor = '#333';
    tooltip.style.color = '#fff';
    tooltip.style.padding = '5px 10px';
    tooltip.style.borderRadius = '5px';
    tooltip.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.2)';
    tooltip.style.zIndex = '1000';
    tooltip.style.fontSize = '12px';
    tooltip.style.whiteSpace = 'nowrap';

    // Append the tooltip to the document
    document.body.appendChild(tooltip);

    // Position the tooltip next to the element
    const rect = element.getBoundingClientRect();
    tooltip.style.left = `${rect.right + 10}px`;
    tooltip.style.top = `${rect.top}px`;

    // Remove the tooltip when the mouse moves away from the element
    element.addEventListener('mouseleave', () => {
        tooltip.remove();
    });
}

