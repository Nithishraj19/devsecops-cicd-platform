const security = require('eslint-plugin-security');

module.exports = [{
  files: ['**/*.js'],
  plugins: { security },
  languageOptions: {
    ecmaVersion: 2022,
    sourceType: 'commonjs',
    globals: {
      require: 'readonly', module: 'readonly', process: 'readonly', console: 'readonly',
      Buffer: 'readonly', setTimeout: 'readonly', URL: 'readonly', fetch: 'readonly'
    }
  },
  rules: {
    ...security.configs.recommended.rules,
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }]
  }
}];
