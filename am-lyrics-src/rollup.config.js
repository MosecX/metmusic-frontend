import resolve from '@rollup/plugin-node-resolve'
import typescript from '@rollup/plugin-typescript'
import babel from '@rollup/plugin-babel'
import { transform } from 'lightningcss'

const PACKAGE_ROOT_PATH = process.cwd()

const commonPlugins = [
  resolve(),
  typescript({
    tsconfig: `./tsconfig.json`
  }),
  babel({
    babelrc: false,
    configFile: false,
    exclude: 'node_modules/**',
    extensions: ['.ts', '.tsx'],
    babelHelpers: 'bundled',
    plugins: [
      [
        'template-html-minifier',
        {
          modules: {
            lit: ['html', { name: 'css', encapsulation: 'style' }]
          },
          htmlMinifier: {
            collapseWhitespace: true,
            conservativeCollapse: true,
            removeComments: true,
            caseSensitive: true,
            minifyCSS: (source, type) =>
              type
                ? source
                : transform({
                    filename: 'component.css',
                    code: Buffer.from(source),
                    minify: true
                  }).code.toString()
          }
        }
      ]
    ]
  })
];

export default [
  // Build for vanilla JS
  {
    input: `${PACKAGE_ROOT_PATH}/src/am-lyrics.ts`,
    external: [/@babel\/runtime/],
    output: [
      {
        file: 'dist/src/am-lyrics.js',
        format: 'esm',
        sourcemap: true,
      },
      {
        // IIFE para el WebView de Android: los módulos ES no cargan
        // desde origin file:// (net::ERR_FAILED), así que el bundle se
        // sirve como script clásico desde assets/lyrics/.
        file: 'dist/src/am-lyrics.iife.js',
        format: 'iife',
        name: 'AmLyrics',
        sourcemap: false,
      }
    ],
    plugins: commonPlugins
  },
  // Build for React
  {
    input: `${PACKAGE_ROOT_PATH}/src/react.ts`,
    external: [/@babel\/runtime/, 'react', '@lit/react'],
    output: [
      {
        file: 'dist/src/react.js',
        format: 'esm',
        sourcemap: true,
      }
    ],
    plugins: commonPlugins
  }
]
