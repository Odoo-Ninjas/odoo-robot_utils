/* jshint esversion: 11 */
function highlightElementByCss(css, toggle = true) {
  const color = "#FFF9C4";
  const elements = document.querySelectorAll(css);

  for (const element of elements) {
    if (toggle) {
      element.style.backgroundColor = color;
      element.dataset.original_background_color = element.style.backgroundColor;
      element.dataset.original_border = element.style.border;
      element.style.border = "1px solid red";
    } else {
      element.style.backgroundColor = null;
      element.style.border = null;
      delete element.dataset.original_background_color;
      delete element.dataset.original_border;
    }
  }
}

function removeTooltips() {
  const el = document.getElementById("robot-tooltip");
  if (el) {
    el.remove();
  }
}

function showTooltipByCss(css, tooltipText) {
  // Find the element using XPath
  const element = document.querySelector(css);
  if (!element) {
    console.error("No element found for the provided XPath:", xpath);
    return;
  }

  // Create the tooltip element
  const tooltip = document.createElement("div");
  tooltip.textContent = tooltipText;
  tooltip.id = "robot-tooltip";
  tooltip.style.position = "absolute";
  tooltip.style.backgroundColor = "#FFF9C4";
  tooltip.style.color = "black";
  tooltip.style.padding = "5px 10px";
  tooltip.style.borderRadius = "5px";
  tooltip.style.boxShadow = "4px 4px 8px rgba(0, 0, 0, 0.3)";
  tooltip.style.zIndex = "1000";
  tooltip.style.fontSize = "12px";
  // tooltip.style.whiteSpace = 'nowrap';
  tooltip.style.maxWidth = "300px";
  tooltip.style.overflow = "hidden";
  tooltip.style.wordBreak = "break-word";

  // Append the tooltip to the document
  document.body.appendChild(tooltip);

  // Position the tooltip next to the element
  const rect = element.getBoundingClientRect();
  tooltip.style.left = `${rect.right + 10}px`;
  tooltip.style.top = `${rect.top}px`;

  // Remove the tooltip when the mouse moves away from the element
  element.addEventListener("mouseleave", () => {
    tooltip.remove();
  });
}
