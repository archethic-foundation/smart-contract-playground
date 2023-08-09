import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { loadEditor } from "./editor/editor";
import { highlightBlock } from 'highlight.js';
import Archethic from 'archethic';


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

window.addEventListener("phx:set-code", (e) => {
  setCodeWhenAvailable(e.detail.code)
});

function setCodeWhenAvailable(code) {
  if (!window.editor)
    return setTimeout(() => { setCodeWhenAvailable(code) }, 100)

  window.editor.getModel().setValue(code)
}

// On resize, resize the editor
window.addEventListener('resize', (_e) => {
  window.dispatchEvent(new Event("phx:resize-editor"))
});

// Force the monaco editor to resize
// automaticLayout does not work for us 
// source: https://berezuzu.medium.com/resizable-monaco-editor-3e922ad54e4
window.addEventListener("phx:resize-editor", (_e) => {
  if (!window.editor) return;

  window.editor.layout({ width: 0, height: 0 });

  window.requestAnimationFrame(() => {
    $el = document.getElementById("archethic-editor")
    const rect = $el.getBoundingClientRect();
    window.editor.layout({ width: rect.width, height: rect.height });
  });
});

// Validate the contract by sending event to live_view
Hooks.hook_ValidateContract = {
  mounted() {
    this.el.addEventListener('click', (event) => {
      this.pushEvent("parse", { code: window.editor.getValue() });
    });
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
let localArchethic;
Hooks.WalletDeployment = {
  mounted() {
    const walletUrl = this.el.dataset.wallet_url;
    localArchethic = new Archethic(walletUrl);
    localArchethic.rpcWallet.onconnectionstatechange((state) => {
      this.pushEventTo(this.el, "wallet_connection_state_change", { state: state });
    })
    console.log(localArchethic.rpcWallet.connectionState)
    if(localArchethic.rpcWallet.connectionState != "WalletRPCConnection_open"){
      localArchethic.connect();
    }

    this.handleEvent("deploy_with_wallet", e => {
      const transaction = e.transaction;
      let txBuilder = localArchethic.transaction
      .new()
      .setType(transaction.type)
      .setCode(transaction.data.code)
      .setContent(transaction.data.content);
  
      transaction.data.ledger.uco.transfers.forEach(function (transfer) {
        txBuilder.addUCOTransfer(transfer.to, transfer.amount);
      });
    
      transaction.data.ledger.token.transfers.forEach(function (transfer) {
        txBuilder.addTokenTransfer(
          transfer.to,
          transfer.amount,
          transfer.token,
          transfer.tokenId
        );
      });
    
      transaction.data.recipients.forEach(function (recipient) {
        txBuilder.addRecipient(recipient);
      });
    
      transaction.data.ownerships.forEach(function (ownership) {
        txBuilder.addOwnership(ownership.secret, ownership.authorizedKeys);
      });

      localArchethic.rpcWallet.sendTransaction(txBuilder).then((sendResult) => {
        this.pushEventTo(this.el, "wallet_deployment_success", { result: sendResult });
      }).catch((sendError) => {
        this.pushEventTo(this.el, "wallet_deployment_error", { result: sendError.message });
      });
    })

  }
}