// For Future: If we want to implement language features for DSL
export function setLanguage(monaco) {

  monaco.languages.register({
    id: 'archethicLanguage'
  });

  monaco.languages.setMonarchTokensProvider('archethicLanguage', {
    tokenizer: {
      root: [
        [/\[error.*/, "custom-error"],
        [/\[notice.*/, "custom-notice"],
        [/\[info.*/, "custom-info"],
        [/\[[a-zA-Z 0-9:]+\]/, "custom-date"],
      ],
    }
  });
};  