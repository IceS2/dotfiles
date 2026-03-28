.pragma library

/**
 * FZF-style fuzzy scoring for search matching.
 *
 * Usage:
 *   import "fuzzy.js" as Fuzzy
 *   var result = Fuzzy.fuzzyScore("vsc", "Visual Studio Code")
 *   // result = { score: 280, matches: [0, 7, 13] }
 */

/**
 * Score how well `query` fuzzy-matches `text`.
 * @param {string} query - search string (lowercase)
 * @param {string} text  - candidate string
 * @returns {{ score: number, matches: number[] }} score=0 means no match
 */
function fuzzyScore(query, text) {
    if (!query || !text) return { score: 0, matches: [] };

    var lowerText = text.toLowerCase();
    var matches = [];
    var qi = 0;
    var prevMatchIdx = -1;
    var score = 0;

    for (var ti = 0; ti < lowerText.length && qi < query.length; ti++) {
        if (lowerText[ti] !== query[qi]) continue;

        matches.push(ti);
        score += 100; // base match

        // Start of string bonus
        if (ti === 0) score += 50;

        // Word boundary bonus (after space, dash, underscore, dot)
        if (ti > 0) {
            var prev = text[ti - 1];
            if (prev === ' ' || prev === '-' || prev === '_' || prev === '.') {
                score += 30;
            }
            // camelCase transition bonus
            var ch = text[ti];
            if (ch >= 'A' && ch <= 'Z' && prev >= 'a' && prev <= 'z') {
                score += 20;
            }
        }

        // Consecutive character bonus
        if (prevMatchIdx === ti - 1) {
            score += 50;
        } else if (prevMatchIdx >= 0) {
            // Gap penalty
            score -= (ti - prevMatchIdx - 1) * 10;
        }

        prevMatchIdx = ti;
        qi++;
    }

    // All query characters must match
    if (qi < query.length) return { score: 0, matches: [] };

    // Span penalty — prefer tighter matches
    if (matches.length > 1) {
        score -= (matches[matches.length - 1] - matches[0]) * 2;
    }

    return { score: score, matches: matches };
}

/**
 * Compute frecency score from launch history.
 * Higher = more frequently/recently used.
 * @param {number} count        - total launch count
 * @param {number} lastLaunchedMs - timestamp (ms) of last launch
 * @returns {number} frecency score
 */
function frecencyScore(count, lastLaunchedMs) {
    if (!count || count <= 0) return 0;
    var daysSince = (Date.now() - lastLaunchedMs) / 86400000;
    return count * 1000 + (1.0 / (1.0 + daysSince)) * 100;
}
