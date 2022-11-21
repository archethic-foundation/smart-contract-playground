import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { loadEditor } from "./editor/editor";

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

// function myCompletions(context) {
//   let word = context.matchBefore(/\w*/)
//   if (word.from == word.to && !context.explicit) {
//     return null
//   }

//   return {
//     from: word.from,
//     options: [
//       {
//         label: "actions by transactions", type: "text", apply: `actions triggered_by: transaction do
//   # Enter your actions when you are receving a transaction
// end`, detail: "snippet"
//       },
//       {
//         label: "condition for transactions", type: "text", apply: `condition transaction: [
// ]`, detail: "snippet"
//       },
//       { label: "transaction", type: "variable", info: "Incoming transaction" }
//     ]
//   }
// }

// Hooks.ArchethicEditor = {
//   mounted() {

//     let startState = EditorState.create({
//       doc: "Hello",
//       extensions: [
//         basicSetup,
//         keymap.of(indentWithTab),
//         autocompletion({ override: [myCompletions] }),
//         EditorView.updateListener.of(v => {
//           if (v.docChanged) {
//             code = v.state.doc.toString()
//             this.pushEvent("interpret", { code: code })
//           }
//         })
//       ]
//     })

//     let view = new EditorView({
//       state: startState,
//       parent: this.el
//     })

//     view.focus()
//   }
// }

// Load the editor
Hooks.hook_LoadEditor = {
  mounted() {
    loadEditor().then(({editor, monaco}) => {
      window.editor = editor;
      window.monaco = monaco;
      window.editor.onKeyUp(() => {
        if(this.keyUpHandler) clearTimeout(this.keyUpHandler);
        this.keyUpHandler = setTimeout(() => {
          this.pushEvent("interpret", { contract: window.editor.getValue() }, (reply, ref) => {
            if(reply.result.status == "error") {
              const lineNumber = extractLineNumber(reply.result.message)
              const newDecorations = window.editor.deltaDecorations(
                this.oldDecorations || [],
                [
                  {
                    range: new window.monaco.Range(lineNumber, 1, lineNumber, 1),
                    options: {
                      isWholeLine: true,
                      className: 'ValidationErrorLine',
                      glyphMarginClassName: 'ValidationErrorMargin', 
                      hoverMessage: [
                        { value: '**ERROR**' },
                        { value:  reply.result.message}
                      ]
                    }
                  }
                ]
              );
              this.oldDecorations = newDecorations;
            } else {
              window.editor.deltaDecorations(
                this.oldDecorations || [], []
              );
              this.oldDecorations = []
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
      this.pushEvent("interpret", { contract: window.editor.getValue() });
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
  return parseInt(found[1]);
}
