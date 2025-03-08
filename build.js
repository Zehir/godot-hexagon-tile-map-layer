const fs = require('fs');
const path = require('path');
const AdmZip = require('adm-zip');

const ADDON_PATH = 'addons/hexagon_tilemaplayer';

const packageJson = JSON.parse(fs.readFileSync('./package.json', 'utf8'));

const content = `[plugin]

name="${packageJson.displayName}"
description="${packageJson.description}"
author="${packageJson.author}"
version="${packageJson.version}"
script="${packageJson.main}"
`;

const filePath = `${ADDON_PATH}/plugin.cfg`;
fs.writeFileSync(filePath, content);

console.log(`Plugin configuration file ${filePath} updated (version ${packageJson.version})`);

// Copy all .md files from root to addon directory
const mdFiles = fs.readdirSync('.').filter(file => file.endsWith('.md'));
mdFiles.forEach(file => {
    fs.copyFileSync(file, `${ADDON_PATH}/${file}`);
    console.log(`Copied ${file} to ${ADDON_PATH}/${file}`);
});

// Remove dist directory if it exists and create it
const DIST_PATH = 'dist';
if (fs.existsSync(DIST_PATH)) {
    fs.rmSync(DIST_PATH, { recursive: true });
    console.log(`Removed existing ${DIST_PATH} directory`);
}
fs.mkdirSync(DIST_PATH);
console.log(`Created ${DIST_PATH} directory`);

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
const baseArchiveName = `${packageJson.name}-${packageJson.version}`;
const fullArchiveName = `${baseArchiveName}-full`;
const addonArchiveName = `${baseArchiveName}-addon`;

// Create full archive
const fullZip = new AdmZip();
addFilesToZip(fullZip, '.', fullArchiveName, [
    'dist',
    '.git',
    'images',
    'node_modules'
]);
fullZip.writeZip(path.join(DIST_PATH, `${fullArchiveName}.zip`));

// Create addon archive
const addonZip = new AdmZip();
addFilesToZip(addonZip, ADDON_PATH, path.join(addonArchiveName, 'addons/hexagon_tilemaplayer'), [
    'example'
]);
addonZip.writeZip(path.join(DIST_PATH, `${addonArchiveName}.zip`));

console.log(`Created archives in ${DIST_PATH}:`);
console.log(`- ${fullArchiveName}.zip`);
console.log(`- ${addonArchiveName}.zip`);
