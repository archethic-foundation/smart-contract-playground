import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import EditorLoader from "@monaco-editor/loader";

// add tooltips
import tippy from "tippy.js";
// add alpinejs
import Alpine from "alpinejs";

window.Alpine = Alpine;
Alpine.start();

EditorLoader.init().then((monaco) => {
  monaco.editor.create(document.getElementById("archethic-editor"), {
    value: "// Smart Contracts Editor for Archethic",
    language: "typescript",
    theme: "vs-dark",
    formatOnType: false,
    fontSize: 16,
    tabSize: 2,
    lineNumbersMinChars: 3,
    minimap: {
      enabled: true,
    },
    scrollbar: {
      useShadows: false,
    },
    mouseWheelZoom: true,
  });
});

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

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
console.log(csrfToken);

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
