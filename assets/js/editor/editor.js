import EditorLoader from '@monaco-editor/loader';
import { setLanguage } from './language';
import { setTheme } from './theme';


async function loadEditor() {
  let newEditor = await EditorLoader.init()
    .then(async (monaco) => {
      // Monaco Configs
      // Not necessary right now, but for future use
      await setLanguage(monaco);
      setTheme(monaco);

      // Create Monaco Instance
      const uri = window.monaco.Uri.parse("inmemory://smart-contract-elixir");
      const model = window.monaco.editor.createModel("@version 1\n", "elixir", uri);
      let editor = monaco.editor.create(document.getElementById('archethic-editor'), {
        theme: 'archethicTheme',
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
        model: model,
        automaticLayout: true
      });
      return { editor, monaco };
    });

  return newEditor;
}
export { loadEditor };