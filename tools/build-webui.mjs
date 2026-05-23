import { mkdir, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { minify as minifyHtml } from "html-minifier-terser";
import { transform as transformCss } from "lightningcss";
import postcss from "postcss";
import postcssNested from "postcss-nested";
import { minify as minifyJs } from "terser";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");
const commonUiSrcDir = "arma/client/addons/common/ui/src";
const commonUiSiteDir = "arma/client/addons/common/ui/_site";
const clientAddonsDir = path.join(rootDir, "arma/client/addons");

function toRepoRelative(absolutePath) {
    return path.relative(rootDir, absolutePath).replace(/\\/g, "/");
}

function resolveFromRoot(...segments) {
    return toRepoRelative(path.join(rootDir, ...segments));
}

function resolveFromConfigDir(configDir, relativePath) {
    return toRepoRelative(path.resolve(configDir, relativePath));
}

const commonJsBundles = [
    {
        name: "Forge Web UI runtime",
        output: resolveFromRoot(commonUiSiteDir, "forge-webui.js"),
        sources: [
            "runtime.js",
            "host.js",
            "bridge.js",
            "app.js",
            "windowTitleBar.js",
            "index.js",
        ].map((relativePath) => resolveFromRoot(commonUiSrcDir, relativePath)),
    },
    {
        name: "Forge Web UI site loader",
        output: resolveFromRoot(commonUiSiteDir, "forge-site-loader.js"),
        sources: [resolveFromRoot(commonUiSrcDir, "siteLoader.js")],
    },
];
const commonFormatSourceTargets = [resolveFromRoot(commonUiSrcDir)];

function unique(values) {
    return Array.from(new Set(values));
}

async function readSource(relativePath) {
    const absolutePath = path.join(rootDir, relativePath);
    return readFile(absolutePath, "utf8");
}

async function writeBundle(outputRelativePath, content) {
    const outputPath = path.join(rootDir, outputRelativePath);
    await mkdir(path.dirname(outputPath), { recursive: true });
    await writeFile(outputPath, content, "utf8");
}

async function cleanOutputDirs(outputDirs) {
    const uniqueDirs = unique(outputDirs).filter(Boolean);

    await Promise.all(
        uniqueDirs.map(async (relativeDir) => {
            const absoluteDir = path.join(rootDir, relativeDir);
            await rm(absoluteDir, { force: true, recursive: true });
            await mkdir(absoluteDir, { recursive: true });
        }),
    );
}

async function buildJsBundle({ name, output, sources }) {
    const chunks = await Promise.all(sources.map(readSource));
    const bundleSource = chunks.join("\n\n");
    const result = await minifyJs(bundleSource, {
        compress: true,
        mangle: true,
        format: {
            comments: false,
        },
    });

    if (!result?.code) {
        throw new Error(`Failed to minify JavaScript bundle for ${name}.`);
    }

    await writeBundle(output, result.code);
    console.log(`Built ${output}`);
}

async function buildCssBundle({ name, output, sources }) {
    const chunks = await Promise.all(sources.map(readSource));
    const nestedResult = await postcss([postcssNested]).process(
        chunks.join("\n\n"),
        {
            from: undefined,
        },
    );
    const result = transformCss({
        filename: output,
        code: Buffer.from(nestedResult.css),
        minify: true,
    });

    await writeBundle(output, result.code.toString("utf8"));
    console.log(`Built ${output}`);
}

function renderSiteIndex({ title, siteConfig }) {
    const configJson = JSON.stringify(siteConfig, null, 16)
        .replace(/^/gm, " ".repeat(12))
        .trimStart();

    return `<!doctype html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>${title}</title>
        <script>
            window.ForgeSiteConfig = ${configJson};

            (function loadForgeSiteLoader() {
                const armaLoaderPath =
                    "forge\\\\forge_client\\\\addons\\\\common\\\\ui\\\\_site\\\\forge-site-loader.js";
                const browserLoaderPath =
                    "../../../common/ui/_site/forge-site-loader.js";

                function appendScript(js) {
                    const script = document.createElement("script");
                    script.text = js;
                    document.head.appendChild(script);
                }

                function requestLoader() {
                    if (
                        typeof A3API !== "undefined" &&
                        A3API &&
                        typeof A3API.RequestFile === "function"
                    ) {
                        return A3API.RequestFile(armaLoaderPath);
                    }

                    return fetch(browserLoaderPath).then((response) => {
                        if (!response.ok) {
                            throw new Error(
                                "Failed to load " + browserLoaderPath,
                            );
                        }

                        return response.text();
                    });
                }

                requestLoader()
                    .then(appendScript)
                    .catch((error) => {
                        console.error(
                            "[${siteConfig.logLabel}] Failed to load Forge site loader.",
                            error,
                        );
                    });
            })();
        </script>
    </head>

    <body>
        <div id="app"></div>
    </body>
</html>
`;
}

async function buildHtmlPage({ name, output, title, siteConfig }) {
    const html = renderSiteIndex({ title, siteConfig });
    const minifiedHtml = await minifyHtml(html, {
        collapseBooleanAttributes: true,
        collapseWhitespace: true,
        minifyCSS: true,
        minifyJS: true,
        removeComments: true,
        removeRedundantAttributes: true,
    });

    await writeBundle(output, minifiedHtml);
    console.log(`Built ${output}`);
}

async function buildHtmlTemplate({ name, output, source }) {
    const html = await readSource(source);
    const minifiedHtml = await minifyHtml(html, {
        collapseBooleanAttributes: true,
        collapseWhitespace: true,
        minifyCSS: true,
        minifyJS: true,
        removeComments: true,
        removeRedundantAttributes: true,
    });

    await writeBundle(output, minifiedHtml);
    console.log(`Built ${output}`);
}

async function pathExists(absolutePath) {
    try {
        await stat(absolutePath);
        return true;
    } catch {
        return false;
    }
}

async function runPrettier(targets) {
    const uniqueTargets = unique(targets).filter(Boolean);
    if (uniqueTargets.length === 0) {
        return;
    }

    console.log(`Formatting ${uniqueTargets.length} Web UI target(s) with Prettier`);

    await new Promise((resolve, reject) => {
        const quotedTargets = uniqueTargets.map((target) =>
            `"${String(target).replace(/"/g, '\\"')}"`,
        );
        const command = `npx prettier --write --ignore-unknown ${quotedTargets.join(" ")}`;
        const child = spawn(command, [], {
            cwd: rootDir,
            stdio: "inherit",
            shell: true,
        });

        child.on("error", reject);
        child.on("exit", (code) => {
            if (code === 0) {
                resolve();
                return;
            }

            reject(
                new Error(`Prettier failed with exit code ${code ?? "unknown"}.`),
            );
        });
    });
}

async function discoverUiConfigs() {
    const addons = await readdir(clientAddonsDir, { withFileTypes: true });
    const configPaths = [];

    for (const entry of addons) {
        if (!entry.isDirectory()) {
            continue;
        }

        const configPath = path.join(
            clientAddonsDir,
            entry.name,
            "ui",
            "ui.config.mjs",
        );

        try {
            const configStat = await stat(configPath);
            if (configStat.isFile()) {
                configPaths.push(configPath);
            }
        } catch {
            // UI config is optional per addon.
        }
    }

    configPaths.sort((left, right) => left.localeCompare(right));
    return configPaths;
}

async function loadUiConfig(absoluteConfigPath) {
    const configModule = await import(pathToFileURL(absoluteConfigPath).href);
    const config = configModule.default;

    if (!config || !config.addonName || !config.outputDir || !config.site) {
        throw new Error(
            `Invalid UI config at ${toRepoRelative(absoluteConfigPath)}.`,
        );
    }

    const configDir = path.dirname(absoluteConfigPath);
    const configRelativePath = toRepoRelative(absoluteConfigPath);
    const outputDir = resolveFromConfigDir(configDir, config.outputDir);
    const srcDirPath = path.join(configDir, "src");
    const formatSourceTargets = [configRelativePath];

    if (await pathExists(srcDirPath)) {
        formatSourceTargets.push(toRepoRelative(srcDirPath));
    }

    const jsBundles = (config.jsBundles || []).map((bundle) => ({
        name: bundle.name,
        output: resolveFromConfigDir(configDir, path.join(config.outputDir, bundle.output)),
        sources: (bundle.sources || []).map((source) =>
            resolveFromConfigDir(configDir, source),
        ),
    }));
    const cssBundles = (config.cssBundles || []).map((bundle) => ({
        name: bundle.name,
        output: resolveFromConfigDir(configDir, path.join(config.outputDir, bundle.output)),
        sources: (bundle.sources || []).map((source) =>
            resolveFromConfigDir(configDir, source),
        ),
    }));
    const htmlPages = [];
    if (config.generateIndex !== false) {
        htmlPages.push({
            kind: "generated",
            name: `${config.addonName} UI index`,
            output: resolveFromConfigDir(configDir, path.join(config.outputDir, "index.html")),
            title: config.title,
            siteConfig: {
                addonName: config.addonName,
                logLabel: config.logLabel || `${config.addonName} UI`,
                ...config.site,
            },
        });
    }

    for (const page of config.htmlTemplates || []) {
        htmlPages.push({
            kind: "template",
            name: page.name || `${config.addonName} UI template`,
            output: resolveFromConfigDir(
                configDir,
                path.join(config.outputDir, page.output),
            ),
            source: resolveFromConfigDir(configDir, page.source),
        });
    }

    return {
        outputDir,
        jsBundles,
        cssBundles,
        htmlPages,
        formatSourceTargets,
    };
}

async function collectUiBuildArtifacts() {
    const configPaths = await discoverUiConfigs();
    const uiConfigs = await Promise.all(configPaths.map(loadUiConfig));

    return {
        outputDirs: uiConfigs.map((config) => config.outputDir),
        jsBundles: uiConfigs.flatMap((config) => config.jsBundles),
        cssBundles: uiConfigs.flatMap((config) => config.cssBundles),
        htmlPages: uiConfigs.flatMap((config) => config.htmlPages),
        formatSourceTargets: uiConfigs.flatMap(
            (config) => config.formatSourceTargets,
        ),
    };
}

async function build() {
    const uiArtifacts = await collectUiBuildArtifacts();
    const commonOutputDirs = [resolveFromRoot(commonUiSiteDir)];

    await runPrettier([
        ...commonFormatSourceTargets,
        ...uiArtifacts.formatSourceTargets,
    ]);

    await cleanOutputDirs([...commonOutputDirs, ...uiArtifacts.outputDirs]);

    await Promise.all([
        ...commonJsBundles.map(buildJsBundle),
        ...uiArtifacts.jsBundles.map(buildJsBundle),
    ]);
    await Promise.all(uiArtifacts.cssBundles.map(buildCssBundle));
    await Promise.all(
        uiArtifacts.htmlPages.map((page) =>
            page.kind === "template" ? buildHtmlTemplate(page) : buildHtmlPage(page),
        ),
    );
}

build().catch((error) => {
    console.error("Failed to build Forge Web UI bundles.");
    console.error(error);
    process.exitCode = 1;
});
