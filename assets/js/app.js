import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

window.updateConnectingLines = function updateConnectingLines() {
  const svg = document.getElementById("connection-lines");
  const mainContainer = document.getElementById("conversation-container");

  if (!svg || !mainContainer) return;
  svg.innerHTML = ""; // Clear existing lines

  // Find all comments that have a parent
  const childComments = document.querySelectorAll("[data-parent-id]");

  childComments.forEach(childEl => {
    const parentId = childEl.dataset.parentId;
    if (parentId) {
      const parentEl = document.getElementById(parentId);
      if (parentEl) {
        drawLine(parentEl, childEl, svg, mainContainer);
      }
    }
  });
};

function drawLine(fromElem, toElem, svg, mainContainer) {
  if (!fromElem || !toElem) return;

  const containerRect = mainContainer.getBoundingClientRect();
  const fromRect = fromElem.getBoundingClientRect();
  const toRect = toElem.getBoundingClientRect();

  // From the bottom-center of the parent card
  const startX = fromRect.left + fromRect.width / 2 - containerRect.left;
  const startY = fromRect.bottom - containerRect.top;

  // To the top-center of the child card
  const endX = toRect.left + toRect.width / 2 - containerRect.left;
  const endY = toRect.top - containerRect.top;

  // Create a smooth curve (cubic bezier)
  const c1Y = startY + (endY - startY) * 0.5;
  const c2Y = endY - (endY - startY) * 0.5;

  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path.setAttribute("d", `M ${startX} ${startY} C ${startX} ${c1Y}, ${endX} ${c2Y}, ${endX} ${endY}`);
  path.setAttribute("style", "stroke: #cbd5e1; stroke-width: 2; fill: none;");
  svg.appendChild(path);
}

let Hooks = {};
Hooks.ConversationTree = {
  mounted() {
    window.updateConnectingLines();
    window.addEventListener("resize", window.updateConnectingLines);
  },
  updated() {
    // A slight delay ensures the DOM has settled before redrawing
    setTimeout(window.updateConnectingLines, 50);
  }
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

liveSocket.connect();
window.liveSocket = liveSocket;