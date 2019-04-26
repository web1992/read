# webpack

- [webpack concepts](https://webpack.docschina.org/concepts)
- [code splitting](https://webpack.js.org/guides/code-splitting/)
- [concepts[](https://webpack.js.org/concepts)
- [loaders](https://webpack.js.org/concepts/loaders)
- [targets](https://webpack.js.org/concepts/targets)

## get start

[link→](https://webpack.js.org/guides/getting-started)

There are problems with managing JavaScript projects this way:

- It is not immediately apparent that the script depends on an external library.
- If a dependency is missing, or included in the wrong order, the application will not function properly.
- If a dependency is included but not used, the browser will be forced to download unnecessary code.

Let's use webpack to manage these scripts instead.

## Asset Management

- Loading CSS
- Loading Images
- Loading Fonts
- Loading Data
- Global Assets

## Output Management

auto generate `index.html` with `bundle.js`

- [HtmlWebpackPlugin](https://webpack.js.org/plugins/html-webpack-plugin)
- [clean-webpack-plugin](https://www.npmjs.com/package/clean-webpack-plugin)
- [WebpackManifestPlugin](https://github.com/danethurber/webpack-manifest-plugin)

## Development

- Using source maps

```js
devtool: "inline-source-map";
```

- Choosing a Development Tool

There are a couple of different options available in webpack that help you automatically compile your code whenever it changes:

- webpack's Watch Mode
- webpack-dev-server
- webpack-dev-middleware

```js
    // webpack-dev-server
    devServer: {
        contentBase: './dist'
    },
```

In most cases, you probably would want to use `webpack-dev-server`, but let's explore all of the above options.

## code splitting

There are three general approaches to code splitting available:

- **Entry Points**: Manually split code using entry configuration.
- **Prevent Duplication**: Use the SplitChunks to dedupe and split chunks.
- **Dynamic Imports**: Split code via inline function calls within modules.

## __webpack_require__