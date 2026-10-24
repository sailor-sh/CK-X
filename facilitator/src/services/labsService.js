const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');

const EXAMS_ROOT = path.join('assets', 'exams');

/**
 * Read and parse a JSON file.
 * @param {string} file - path of the file
 * @returns {*} the parsed value (any JSON value, including null)
 */
function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

/**
 * List the subdirectories of a directory.
 * @param {string} dir - directory to list
 * @returns {string[]} directory names, sorted
 */
function subdirectories(dir) {
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(entry => entry.isDirectory())
    .map(entry => entry.name)
    .sort();
}

/**
 * Discover the labs from the exams directory.
 *
 * <root>/<category>/category.json         {"name": "CKS - Reddit", "order": 30}   (name defaults to the directory name)
 * <root>/<category>/<exam>/config.json    "lab" (the id), "name", "description", "difficulty",
 *                                         "warmUpTimeInSeconds", "examDurationInMinutes" and the rest of the exam config
 *
 * A directory without category.json is not a category; an exam without config.json or "lab" is skipped with a warning,
 * so one broken exam does not hide the others.
 *
 * @param {string} root - directory that holds the categories (default: assets/exams under the working directory)
 * @returns {Array} labs in the shape the webapp expects, sorted by category order then exam directory
 */
function discoverLabs(root = path.join(process.cwd(), EXAMS_ROOT)) {
  const categories = [];

  for (const categoryDir of subdirectories(root)) {
    const categoryFile = path.join(root, categoryDir, 'category.json');
    if (!fs.existsSync(categoryFile)) continue;

    let category;
    try {
      category = readJson(categoryFile);
    } catch (error) {
      logger.warn(`Skipping category ${categoryDir}: invalid category.json (${error.message})`);
      continue;
    }
    if (!isPlainObject(category)) {
      logger.warn(`Skipping category ${categoryDir}: category.json is not a JSON object`);
      continue;
    }
    categories.push({ dir: categoryDir, name: category.name || categoryDir, order: category.order ?? Number.MAX_SAFE_INTEGER });
  }

  categories.sort((a, b) => a.order - b.order || a.dir.localeCompare(b.dir));

  const labs = [];
  const seen = new Set();

  for (const category of categories) {
    for (const examDir of subdirectories(path.join(root, category.dir))) {
      const configFile = path.join(root, category.dir, examDir, 'config.json');
      if (!fs.existsSync(configFile)) continue;

      let config;
      try {
        config = readJson(configFile);
      } catch (error) {
        logger.warn(`Skipping exam ${category.dir}/${examDir}: invalid config.json (${error.message})`);
        continue;
      }
      if (!isPlainObject(config)) {
        logger.warn(`Skipping exam ${category.dir}/${examDir}: config.json is not a JSON object`);
        continue;
      }
      if (typeof config.lab !== 'string' || !config.lab) {
        logger.warn(`Skipping exam ${category.dir}/${examDir}: config.json has no "lab" id`);
        continue;
      }
      if (seen.has(config.lab)) {
        logger.warn(`Skipping exam ${category.dir}/${examDir}: the lab id ${config.lab} is already used`);
        continue;
      }
      seen.add(config.lab);

      labs.push({
        id: config.lab,
        assetPath: path.posix.join('assets', 'exams', category.dir, examDir),
        name: config.name || config.lab,
        category: category.name,
        description: config.description || '',
        warmUpTimeInSeconds: config.warmUpTimeInSeconds ?? 260,
        difficulty: config.difficulty || 'Medium',
        examDurationInMinutes: config.examDurationInMinutes ?? 120,
      });
    }
  }

  return labs;
}

/**
 * Whether a parsed JSON value can carry metadata: a plain object (not null, an array or a scalar).
 * @param {*} value - parsed JSON value
 * @returns {boolean}
 */
function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

module.exports = { discoverLabs };
