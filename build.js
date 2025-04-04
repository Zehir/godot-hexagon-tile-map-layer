const fs = require('fs');
const path = require('path');
const AdmZip = require('adm-zip');

const ADDON_PATH = 'addons/hexagon_tilemaplayer';
const REPO_URL = 'https://github.com/Zehir/godot-hexagon-tile-map-layer';

const category_ids = {
    "2D Tools": "1",
    "3D Tools": "2",
    "Shaders": "3",
    "Materials": "4",
    "Tools": "5",
    "Scripts": "6",
    "Misc": "7",
}

const packageJson = JSON.parse(fs.readFileSync('./package.json', 'utf8'));

// Remove dist directory if it exists and create it
const DIST_PATH = 'dist';
if (fs.existsSync(DIST_PATH)) {
    fs.rmSync(DIST_PATH, { recursive: true });
    console.log(`Removed existing ${DIST_PATH} directory`);
}
fs.mkdirSync(DIST_PATH);
console.log(`Created ${DIST_PATH} directory`);

// Create .gdignore file in dist directory
fs.writeFileSync(path.join(DIST_PATH, '.gdignore'), '');
console.log('Created .gdignore file in dist directory');

// Function to add files recursively to zip
function addFilesToZip(zip, sourceDir, zipPath = '', excludes = []) {
    const files = fs.readdirSync(sourceDir);
    files.forEach(file => {
        const filePath = path.join(sourceDir, file);
        const zipFilePath = path.join(zipPath, file);

        // Skip if path matches any exclude pattern
        if (excludes.some(pattern => filePath.includes(pattern))) {
            return;
        }

        if (fs.statSync(filePath).isDirectory()) {
            addFilesToZip(zip, filePath, zipFilePath, excludes);
        } else {
            zip.addLocalFile(filePath, path.dirname(zipFilePath));
        }
    });
}

// Create archives
const addonArchiveName = `${packageJson.name}-${packageJson.version}`;

// Create addon archive
const addonZip = new AdmZip();
addFilesToZip(addonZip, ADDON_PATH, path.join(addonArchiveName, ADDON_PATH));
addonZip.writeZip(path.join(DIST_PATH, `${addonArchiveName}.zip`));

console.log(`Created archives in ${DIST_PATH}:`);
console.log(`- ${addonArchiveName}.zip`);

const download_url = `${REPO_URL}/releases/download/v${packageJson.version}/${addonArchiveName}.zip`;

// Function to parse README and extract description
function getDescriptionFromReadme() {
    const readmeContent = fs.readFileSync('README.md', 'utf8');
    let description = '';
    let searchStart = 0;

    // Find all text blocks between description markers
    while (true) {
        const descriptionStart = readmeContent.indexOf('<!-- description_start -->', searchStart);
        if (descriptionStart === -1) break;

        const contentStart = descriptionStart + '<!-- description_start -->'.length;
        const descriptionEnd = readmeContent.indexOf('<!-- description_end -->', contentStart);

        if (descriptionEnd === -1) break;

        // Extract the text between the markers
        let blockText = readmeContent.substring(contentStart, descriptionEnd).trim();

        blockText = blockText.replaceAll("A\\*", 'A*');

        // Remove Markdown links - format [text](url) - keep only the text part
        blockText = blockText.replaceAll(/\[([^\]]+)\]\([^)]+\)/g, '$1');

        // Remove HTML links - format <url>
        blockText = blockText.replaceAll(/<https?:\/\/[^>]+>/g, '');

        // Add this block to the combined description
        if (description && blockText) {
            description += '\n\n';
        }
        description += blockText;

        // Move search position to continue looking for more blocks
        searchStart = descriptionEnd + '<!-- description_end -->'.length;
    }

    // If we found description blocks, return them
    if (description) {
        return description;
    }

}

const image_url = (name) => `${REPO_URL.replace('github.com', 'raw.githubusercontent.com')}/main/images/${name}.png`;

// Create asset template
const assetTemplate = {
    "title": packageJson.displayName,
    "description": getDescriptionFromReadme(),
    "category_id": category_ids[packageJson.category],
    "godot_version": packageJson.godotVersion,
    "version_string": packageJson.version,
    "cost": packageJson.license,
    "download_provider": "Custom",
    "download_commit": download_url,
    "download_url": download_url,
    "browse_url": REPO_URL,
    "issues_url": `${REPO_URL}/issues`,
    "icon_url": image_url("hexagon_tilemaplayer"),
    "previews": [
        {
            "preview_id": "1",
            "type": "image",
            "link": image_url("cube_linedraw"),
        },
    ],
};

// Write asset template to dist
fs.writeFileSync(
    path.join(DIST_PATH, 'asset-template.json.hb'),
    JSON.stringify(assetTemplate, null, 2)
);
console.log('Created asset template file in dist directory');
