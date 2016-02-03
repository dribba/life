var R = require('ramda');

var excludedDirectories = ['build', 'javascript/conf'];
//+ toDirectoryFilter :: String -> RegExp
var toDirectoryFilter = function(dirName) {
  return new RegExp('.*\/' + dirName + '(?:$|\/)');
};
//+ testDir :: String -> String -> Boolean
var testDir = function(filePath){
  return R.pipe(toDirectoryFilter, R.test(R.__, filePath));
};

module.exports = function(file) {
  // True if the file is not the or inside the excluded developers
  return !R.any(testDir(file), excludedDirectories);
};
