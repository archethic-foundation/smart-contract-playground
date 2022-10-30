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
      let editor = monaco.editor.create(document.getElementById('archethic-editor'), {
        value: '// Smart Contracts Editor for Archethic',
        language: 'elixir',
        theme: 'vs-dark',
        formatOnType: true,
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
      });

      return editor;
    });

  return newEditor;
}

export { loadEditor };