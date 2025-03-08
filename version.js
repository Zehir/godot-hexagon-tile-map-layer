const fs = require('fs');

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
