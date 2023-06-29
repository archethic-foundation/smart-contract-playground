import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { loadEditor } from "./editor/editor";
import { highlightBlock } from 'highlight.js';

// add tooltips
import tippy from "tippy.js";
// add alpinejs
import Alpine from "alpinejs";

window.Alpine = Alpine;
Alpine.start();

// tooltip
tippy("[data-tippy-content]", {
  arrow: true,
});
const CUSTOM_NETWORK_KEY = "custom_network";
let Hooks = {};

Hooks.CodeViewer = {
  mounted() {
    highlightBlock(this.el);
  },

  updated() {
    highlightBlock(this.el);
  },
};

// Load the editor
Hooks.hook_LoadEditor = {
  mounted() {
    loadEditor().then(({ editor, monaco }) => {
      window.editor = editor;
      window.monaco = monaco;
      window.editor.onKeyUp(() => {
        if (this.keyUpHandler) clearTimeout(this.keyUpHandler);
        this.keyUpHandler = setTimeout(() => {
          this.pushEvent("parse", { code: window.editor.getValue() }, (reply, ref) => {
            const model = window.editor.getModel();
            if (reply.result.status == "error") {
              const lineNumber = extractLineNumber(reply.result.message);
              if (lineNumber) {
                const markers = [{
                  message: reply.result.message,
                  severity: monaco.MarkerSeverity.Error,
                  startLineNumber: lineNumber,
                  startColumn: 1,
                  endLineNumber: lineNumber,
                  endColumn: model.getLineLength(lineNumber) + 1
                }];
                window.monaco.editor.setModelMarkers(model, 'owner', markers);
              }
            } else {
              window.monaco.editor.setModelMarkers(model, 'owner', []);
            }
          });
        }, this.el.dataset.debounceValidation);
      })
    });
  }
};

// Validate the contract by sending event to live_view
Hooks.hook_ValidateContract = {
  mounted() {
    this.el.addEventListener('click', (event) => {
      this.pushEvent("parse", { code: window.editor.getValue() });
    });
  }
};

function setEndpoint(that) {
  const networkUrl = that.el.value == "custom_network" ?
    window.localStorage.getItem(CUSTOM_NETWORK_KEY) :
    that.el.value;
  that.pushEventTo(that.el, "update_endpoint", networkUrl)
}

Hooks.hook_SelectNetwork = {
  mounted() {
    this.el.addEventListener('change', (event) => {
      setEndpoint(this)
    });
    setEndpoint(this);
  }
};

Hooks.hook_UpdateOtherNetwork = {
  mounted() {
    this.el.addEventListener('keyup', (event) => {
      if (document.getElementById("selected_network").value == "custom_network") {
        window.localStorage.setItem(CUSTOM_NETWORK_KEY, this.el.value);
      }
    })
  }
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000
window.liveSocket = liveSocket;

// For the UI Theme
function data() {
  function getThemeFromLocalStorage() {
    // if user already changed the theme, use it
    if (window.localStorage.getItem("dark")) {
      return JSON.parse(window.localStorage.getItem("dark"));
    }

    // else return their preferences
    return (
      !!window.matchMedia &&
      window.matchMedia("(prefers-color-scheme: dark)").matches
    );
  }

  function setThemeToLocalStorage(value) {
    window.localStorage.setItem("dark", value);
  }

  return {
    dark: getThemeFromLocalStorage(),
    toggleTheme() {
      this.dark = !this.dark;
      setThemeToLocalStorage(this.dark);
    },
  };
}

function extractLineNumber(message) {
  const reg = new RegExp(/L(\d+)(:C(\d+))?$/g);
  const found = reg.exec(message);
  return !found ? 0 : parseInt(found[1]);
}
