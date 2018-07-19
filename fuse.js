const { FuseBox, CSSPlugin, QuantumPlugin, WebIndexPlugin } = require('fuse-box');
const { src, task, context } = require('fuse-box/sparky');
const { ElmPlugin } = require('fuse-box-elm-plugin');
const { join } = require('path');
const express = require('express');
const { info } = console;

const OUT_DIR = join(__dirname, 'dist');
const TEMPLATE = join(__dirname, 'src/index.html');
const TITLE = 'Elm SPA starter';
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

context(
  class {
    compileClient() {
      return FuseBox.init({
        homeDir: 'src',
        output: `${OUT_DIR}/$name.js`,
        log: false,
        sourceMaps: !IS_PRODUCTION,
        target: 'browser@es5',
        cache: !IS_PRODUCTION,
        allowSyntheticDefaultImports: true,
        alias: { '@': '~' },
        plugins: [
          [CSSPlugin()],
          ElmPlugin(IS_PRODUCTION ? {} : { warn: true, debug: true }),
          WebIndexPlugin({
            template: TEMPLATE,
            title: TITLE
          }),
          IS_PRODUCTION &&
            QuantumPlugin({
              bakeApiIntoBundle: 'app',
              uglify: true,
              treeshake: true,
              css: true
            })
        ]
      });
    }
  }
);

/* INDIVIDUAL BUILD TASKS USED IN VARIOUS BUILD TASK CHAINS */

task('client-prod-build', async context => {
  context.isProduction = true;

  const fuse = context.compileClient();
  fuse.bundle('app').instructions('!> index.ts');

  await fuse.run();
});

task('client-dev-build', async context => {
  const fuse = context.compileClient();

  fuse.dev({ root: false }, server => {
    const app = server.httpServer.app;
    app.use(express.static(`${OUT_DIR}/css-sourcemaps/`));
    app.use(express.static(OUT_DIR));
    app.get('*', (_, res) => {
      res.sendFile(join(OUT_DIR, 'index.html'));
    });
  });

  fuse
    .bundle('app')
    .hmr({ reload: true })
    .watch()
    .instructions('> index.ts');

  await fuse.run();
});

/* TASKS TO CLEAN OUT OLD FILES BEFORE COMPILATION */
task('client-clean', () => src(`${OUT_DIR}/*`).clean(OUT_DIR));

/* MAIN BUILD TASK CHAINS */
task('dev', ['client-clean', 'client-dev-build'], () =>
  info('The front end assets have been bundled. GET TO WORK!')
);

task('prod', ['client-clean', 'client-prod-build'], () =>
  info('The front end assets are optimized, bundled, and ready for production.')
);
