const { writeFileSync } = require('fs');

const caslFilePath = 'node_modules/@casl/ability/extra/package.json';

const goodFile = `
{
    "name": "@casl/ability/extra",
    "typings": "../dist/types/extra/index.d.ts",
    "main": "../dist/umd/extra/index.js",
    "module": "../dist/es5m/extra/index.js",
    "es2015": "../dist/es6c/extra/index.js"
}
`;

console.log('Running temporary CASL package.json fix!');
writeFileSync(caslFilePath, goodFile, { encoding: 'utf8', flag: 'w' });
