/**
 * A lazy/minimal command-line arg parser because OptionContext segfaults.
 */
using Gee;

errordomain ArgParser {
  PARSE_ERROR
}

/**
 * Convert ["-v", "-s", "asdf", "-f", "qwe"] => {("-v", null), ("-s", "adsf"), ("-f", "qwe")} 
 * Populates key of "cmd" with first arg.
 * NOTE: Currently does not support quoted parameter values.
 */
Map<string, string?> parse_args(string[] args) throws ArgParser.PARSE_ERROR {
  var argMap = new HashMap<string, string?>();

  if (args == null || args.length == 0) {
    return argMap;
  }

  string lastKey = null;
  foreach (string token in args) {
    if (!argMap.has_key("cmd")) {
      argMap.set("cmd", token);    
    } else if (isKey(token)) {
      if (lastKey != null) {
        argMap.set(lastKey, null);
      }
      lastKey = token;
    } else if (lastKey != null) {
      argMap.set(lastKey, token);
      lastKey = null;
    } else {
      throw new ArgParser.PARSE_ERROR(@"Unexpected literal: $token\n");
    }
  }

  if (lastKey != null) { // Trailing single param
    argMap.set(lastKey, null);
  }
  
  /* 
  foreach (var entry in argMap.entries) {
    stdout.printf ("%s => %s\n", entry.key, entry.value);
  }
  */

  return argMap;
}

bool isKey(string inval) {
  return inval.has_prefix("-");
}