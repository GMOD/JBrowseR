var path = require('path');

module.exports = {
    mode: 'production',
    entry: ['@babel/polyfill', path.join(__dirname, 'srcjs', 'RBrowse.jsx')],
    output: {
        path: path.join(__dirname, 'inst/htmlwidgets'),
        filename: 'RBrowse.js'
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
    devtool: ''
};
