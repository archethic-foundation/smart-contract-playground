import EditorLoader from '@monaco-editor/loader';
import { setLanguage } from './language';
import { setTheme } from './theme';


async function loadEditor() {
  let newEditor = await EditorLoader.init()
    .then((monaco) => {

      // Monaco Configs
      // Not necessary right now, but for future use
      // setLanguage(monaco);
      // setTheme(monaco);

      // Create Monaco Instance
      const uri = window.monaco.Uri.parse("inmemory://smart-contract-elixir");
      const model = window.monaco.editor.createModel("# Smart Contracts Editor for Archethic", "elixir", uri);
      let editor = monaco.editor.create(document.getElementById('archethic-editor'), {
        theme: 'vs-dark',
        fontSize: 16,
        tabSize: 2,
        lineNumbersMinChars: 3,
        minimap: {
          enabled: false,
        },
        scrollbar: {
          useShadows: false,
        },
        mouseWheelZoom: true,
        model: model
      });
      return {editor, monaco};
    });

  return newEditor;
}

export { loadEditor };