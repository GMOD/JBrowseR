var path = require('path');
var CompressionPlugin = require("compression-webpack-plugin");

module.exports = {
    mode: 'production',
    entry: ['@babel/polyfill', path.join(__dirname, 'srcjs', 'JBrowseR.jsx')],
    output: {
        path: path.join(__dirname, 'inst/htmlwidgets'),
        filename: 'JBrowseR.js'
    },
    module: {
        rules: [
            {
                test: /\.jsx?$/,
                loader: 'babel-loader',
                options: {
                    presets: ['@babel/preset-env', '@babel/preset-react']
                }
            }
        ]
    },
    resolve: {
        extensions: ['.js', '.jsx'],
    },
    externals: {
        'react': 'window.React',
        'react-dom': 'window.ReactDOM',
        'reactR': 'window.reactR'
    },
    stats: {
        colors: true
    },
    // can toggle source map back on during development
    // devtool: 'source-map'
    devtool: '',
    // This makes the bundle go from 2.88 MB -> 984 KB
    // but currently breaks htmlwidgets
    // plugins: [new CompressionPlugin({
    //     deleteOriginalAssets: true
    // })],
};
