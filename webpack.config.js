const NodePolyfillPlugin = require('node-polyfill-webpack-plugin')
const path = require('path')
const webpack = require('webpack')

module.exports = {
  mode: 'production',
  entry: [path.join(__dirname, 'srcjs', 'JBrowseR.jsx')],
  output: {
    path: path.join(__dirname, 'inst/htmlwidgets'),
    filename: 'JBrowseR.js',
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        loader: 'babel-loader',
        options: {
          presets: ['@babel/preset-env', '@babel/preset-react'],
        },
      },
    ],
  },
  resolve: {
    extensions: ['.js', '.jsx'],
  },
  externals: {
    react: 'window.React',
    'react-dom': 'window.ReactDOM',
    reactR: 'window.reactR',
  },

  stats: {
    colors: true,
  },
  plugins: [
    new NodePolyfillPlugin({
      excludeAliases: ['console'],
    }),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1,
    }),
  ],
}
