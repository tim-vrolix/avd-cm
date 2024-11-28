const REPOSITORY_URL = process.env.REPOSITORY_URL;
const MODULE_REGISTRY = process.env.MODULE_REGISTRY;
const MODULE_TYPE = process.env.MODULE_TYPE;
const MODULE_REPOSITORY = process.env.MODULE_REPOSITORY;
const FILE_PATH = process.env.FILE_PATH || 'main.bicep';

let moduleRegistry = MODULE_REGISTRY.toLowerCase()
let moduleType = MODULE_TYPE.toLowerCase()
let moduleRepository = MODULE_REPOSITORY.toLowerCase()
let filePath = FILE_PATH.toLowerCase()

const plugins = [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    {
        changelogFile: "CHANGELOG.md",
        changelogTitle: "# Changelog",
    },
    [
        "@semantic-release/exec",
        {
            prepareCmd: `echo "Updating version in Bicep file..." && sed -i'' -e "s/metadata version = '[0-9]*\.[0-9]*\.[0-9]*'/metadata version = '\${nextRelease.version}'/g" ${FILE_PATH}`,
            publishCmd: `echo "Publishing module..." && bicep publish "${FILE_PATH}" --target "br:${moduleRegistry}/${moduleType}/${moduleRepository}:\${nextRelease.version}" --documentation-uri "${REPOSITORY_URL}/blob/\${nextRelease.gitTag}/README.md"`,
        },
    ],
    [
        "@semantic-release/git",
        {
            assets: [
                "CHANGELOG.md",
                `${FILE_PATH}`,
            ],
            message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
        },
    ],
    [
        "@semantic-release/github",
    ],
];

module.exports = {
    repositoryUrl: REPOSITORY_URL,
    branches: [
        "main",
        { name: "prerelease", prerelease: "rc" },
    ],
    ci: true,
    dryRun: false,
    plugins: plugins,
};