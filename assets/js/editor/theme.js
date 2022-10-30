// For Future: To implement theme for the DSL
export function setTheme(monaco) {

  // Define a new theme that constains only rules that match this language
  monaco.editor.defineTheme('archethicTheme', {
    base: 'vs-dark',
    inherit: true,
    rules: [],
    colors: {
      'editor.foreground': ''
    }
  });
};