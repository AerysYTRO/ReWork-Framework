const path = require('path');
const webpack = require('webpack');

// Încearcă să import vue-loader, dar nu obligatoriu
let vueLoaderPlugin = null;
try {
    const { VueLoaderPlugin } = require('vue-loader');
    vueLoaderPlugin = new VueLoaderPlugin();
} catch (e) {
    console.warn('Warning: vue-loader not installed, skipping Vue support');
}

module.exports = {
    mode: process.env.NODE_ENV || 'production',
    entry: {
        main: './client/init.ts'
    },
    output: {
        filename: '[name].bundle.js',
        path: path.resolve(__dirname, 'dist/client'),
        library: 'ReWorkFramework',
        libraryTarget: 'umd',
        globalObject: 'typeof self !== "undefined" ? self : this'
    },
    
    resolve: {
        extensions: ['.ts', '.tsx', '.js', '.jsx', '.json'],
        alias: {
            '@': path.resolve(__dirname, 'client/'),
            '@types': path.resolve(__dirname, 'shared/types/'),
            '@constants': path.resolve(__dirname, 'shared/constants/')
        }
    },
    
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                use: [
                    {
                        loader: 'ts-loader',
                        options: {
                            transpileOnly: true,
                            experimentalWatchApi: true
                        }
                    }
                ],
                exclude: /node_modules/
            },
            {
                test: /\.jsx?$/,
                use: 'babel-loader',
                exclude: /node_modules/
            },
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader']
            },
            {
                test: /\.vue$/,
                use: 'vue-loader'
            }
        ]
    },
    
    plugins: [
        ...(vueLoaderPlugin ? [vueLoaderPlugin] : []),
        new webpack.DefinePlugin({
            'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'production'),
            '__VERSION__': JSON.stringify(require('./package.json').version)
        })
    ],
    
    externals: {
        // Don't bundle FiveM natives
        'fivem-natives': 'fivem-natives'
    },
    
    devtool: process.env.NODE_ENV === 'production' ? false : 'source-map',
    
    performance: {
        hints: 'warning',
        maxEntrypointSize: 512000,
        maxAssetSize: 512000
    },
    
    optimization: {
        minimize: process.env.NODE_ENV === 'production',
        usedExports: true,
        sideEffects: false
    }
};
