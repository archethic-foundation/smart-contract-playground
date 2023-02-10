export async function setLanguage(monaco) {

  // we are actually extending the elixir language provided by Monaco
    const monarchObject = {
      tokenizer: {
        root: [
          { include: 'customArchethic' },
        ],
        customArchethic : [
          [
            /\b(hash|regex_match\?|regex_extract|json_extract|set_type|add_uco_transfer|add_token_transfer|set_content|set_code|add_ownership|add_recipient)\b/,
            [
              'keyword.archethicFunction',
            ]
          ],
          [
            /\b(condition|actions)\b/,
            [
              'keyword.archethicDeclaration',
            ]
          ],
        ],
      },
    }

    await updateLanguage(monarchObject);
  
    monaco.languages.registerCompletionItemProvider('elixir', {
      provideCompletionItems: () => {
        var suggestions = [
          {
            label: 'actionstriggered_by_interval',
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: ['actions triggered_by: interval, at: "${1:cron-style}" do', '\t', 'end'].join('\n'),
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            documentation: 'Actions triggered on the given interval (cron-style)'
          },
          {
            label: 'actions_triggered_by_datetime',
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: ['actions triggered_by: datetime, at: ${1:timestamp} do', '\t', 'end'].join('\n'),
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            documentation: 'Actions triggered at the given timestamp'
          },
          {
            label: 'add_uco_transfer',
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: 'add_uco_transfer to: ${1:recipient-address}, amount: ${2:amount}',
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            documentation: 'Adds a UCO transfer'
          },
          {
            label: 'add_token_transfer',
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: 'add_token_transfer to: ${1:recipient-address}, token_address: ${2:token-address}, amount: ${3:amount}',
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            documentation: 'Adds a token transfer'
          },
          {
            label: 'add_ownership',
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: 'add_ownership secret: "${1:secret}", secret_key: "${1:secret-key}", authorized_public_key: ["${1:authorized_public_key}"]',
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            documentation: 'Adds an ownership'
          },
          {
            label: 'add_recipient',
            kind: monaco.languages.CompletionItemKind.Snippet,
            insertText: 'add_recipient "${1:recipient-address}"',
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            documentation: 'Adds a recipient'
          },
        ];
        return { suggestions: suggestions };
      }
    });
};

async function updateLanguage(monarchObject) {
  const allLangs = monaco.languages.getLanguages();
  const { conf, language: elixirLang } = await allLangs.find(({ id }) => id === 'elixir').loader();
  for (let key in monarchObject) {
      const value = monarchObject[key];
      if (key === 'tokenizer') {
          for (let category in value) {
              const tokenDefs = value[category];
              if (!elixirLang.tokenizer.hasOwnProperty(category)) {
                  elixirLang.tokenizer[category] = [];
              }
              if (Array.isArray(tokenDefs)) {
                  elixirLang.tokenizer[category].unshift.apply(elixirLang.tokenizer[category], tokenDefs)
              }
          }
      } else if (Array.isArray(value)) {
          if (!elixirLang.hasOwnProperty(key)) {
              elixirLang[key] = [];
          }
          elixirLang[key].unshift.apply(elixirLang[key], value)
      }
  }
}
