// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// --- Hierarchical Conversation JavaScript ---

// Scroll functionality for conversation rows
window.scrollRow = function (rowId, direction) {
  const row = document.getElementById(rowId);
  if (!row) return;
  const firstBox = row.querySelector(".comment-box");
  if (!firstBox) return;
  const gap = parseFloat(getComputedStyle(row).gap) || 16;
  const scrollAmount = firstBox.offsetWidth + gap;
  row.scrollBy({
    left: direction === "left" ? -scrollAmount : scrollAmount,
    behavior: "smooth",
  });
  setTimeout(window.updateConnectingLines, 300); // Redraw lines after scroll animation
};

// SVG Connecting Lines Functionality
window.updateConnectingLines = function updateConnectingLines() {
  const svg = document.getElementById("connection-lines");
  const mainContainer = document.getElementById("conversation-container");

  if (!svg || !mainContainer) return;

  // Clear existing lines
  svg.innerHTML = "";

  // Get elements
  const mother = document.getElementById("mother-comment");
  const children = [
    document.getElementById("child-comment-1"),
    document.getElementById("child-comment-2"),
    document.getElementById("child-comment-3"),
  ];
  const grandchildren = [
    document.getElementById("grandchild-comment-1"),
    document.getElementById("grandchild-comment-2"),
    document.getElementById("grandchild-comment-3"),
    document.getElementById("grandchild-comment-4"),
    document.getElementById("grandchild-comment-5"),
  ];

  // Draw lines from mother to children
  children.forEach((child) => {
    drawLine(mother, child, svg, mainContainer);
  });

  // Draw lines from child-2 to grandchildren
  const parentOfGrandchildren = document.getElementById("child-comment-2");
  grandchildren.forEach((grandchild) => {
    drawLine(parentOfGrandchildren, grandchild, svg, mainContainer);
  });
};

function drawLine(fromElem, toElem, svg, mainContainer) {
  if (!fromElem || !toElem || !svg || !mainContainer) return;

  const containerRect = mainContainer.getBoundingClientRect();
  const fromRect = fromElem.getBoundingClientRect();
  const toRect = toElem.getBoundingClientRect();

  // Calculate start and end points relative to the main container
  const startX = fromRect.left + fromRect.width / 2 - containerRect.left;
  const startY = fromRect.bottom - containerRect.top;
  const endX = toRect.left + toRect.width / 2 - containerRect.left;
  const endY = toRect.top - containerRect.top;

  // Create a smooth curve (cubic bezier)
  const c1Y = startY + (endY - startY) * 0.5;
  const c2Y = endY - (endY - startY) * 0.5;

  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path.setAttribute(
    "d",
    `M ${startX} ${startY} C ${startX} ${c1Y}, ${endX} ${c2Y}, ${endX} ${endY}`,
  );
  path.setAttribute("class", "connector-line");
  path.setAttribute("style", "stroke: #cbd5e1; stroke-width: 2; fill: none;");
  svg.appendChild(path);
}

// LiveView Hooks for proper integration
let Hooks = {};

Hooks.ConversationTree = {
  mounted() {
    // Initialize connection lines when the LiveView mounts
    window.updateConnectingLines();

    // Set up event listeners for window resize and row scrolling
    window.addEventListener("resize", window.updateConnectingLines);

    // Add scroll event listeners to rows
    const row2 = document.getElementById("row2");
    const row3 = document.getElementById("row3");

    if (row2) {
      row2.addEventListener("scroll", () =>
        setTimeout(window.updateConnectingLines, 150),
      );
    }
    if (row3) {
      row3.addEventListener("scroll", () =>
        setTimeout(window.updateConnectingLines, 150),
      );
    }
  },

  updated() {
    // Redraw connection lines when the LiveView updates
    setTimeout(window.updateConnectingLines, 100);
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
