const fs = require('fs');
const path = require('path');

class PublicService {
    constructor(publicDir) {
        this.publicDir = publicDir;
        this.indexHtmlSrc = path.join(__dirname, '..', 'index.html');
        this.indexHtmlDest = path.join(publicDir, 'index.html');
    }

    initialize() {
        this.createPublicDirectory();
        this.copyIndexHtml();
    }

    createPublicDirectory() {
        if (!fs.existsSync(this.publicDir)) {
            fs.mkdirSync(this.publicDir, { recursive: true });
            console.log('Created public directory');
        }
    }

    copyIndexHtml() {
        if (fs.existsSync(this.indexHtmlSrc) && !fs.existsSync(this.indexHtmlDest)) {
            fs.copyFileSync(this.indexHtmlSrc, this.indexHtmlDest);
            console.log('Copied index.html to public directory');
        }
    }

    getPublicDir() {
        return this.publicDir;
    }
}

module.exports = PublicService; 