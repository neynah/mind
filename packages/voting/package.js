Package.describe({
  name: 'voting',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore-extra'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5'
  ]);

  // Internal dependencies.
  api.use([
    'core'
  ], {unordered: true});

  api.export('VotingEngine');

  api.addFiles([
    'lib.coffee'
  ]);

  api.addFiles([
    'engine.coffee'
  ], 'server');
});
